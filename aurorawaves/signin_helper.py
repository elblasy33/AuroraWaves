#!/usr/bin/env python3
"""Aurora Waves — sign in to YouTube Music from outside the sandbox.

The Snap and Flatpak builds cannot read the browser's cookies, so this small script does it for
them. Run it with the system Python (not inside the app):

    python3 /snap/aurora-waves/current/lib/python3.12/site-packages/aurorawaves/signin_helper.py

It reads the YouTube session of a browser you are signed in to (the same thing the AppImage and
local builds do on their own) and hands it to the app through a private file in the app's data
folder (mode 600). Nothing is sent anywhere. Options:

    --browser chrome|chromium|brave|edge|vivaldi|opera|firefox   use this browser only
    --keep        stay running and renew the session every 10 minutes (Chrome rotates it)
    --autostart   renew it automatically after every login (adds a desktop autostart entry)
    --no-autostart  remove that entry
    --uninstall   remove everything this script added

The first run also registers the aurora-waves-signin: link, so afterwards the app's sign-in button
runs this script through the desktop (the app itself cannot start programs outside its sandbox).
"""
import argparse
import json
import os
import sys
import time

HOME = os.path.expanduser("~")
HERE = os.path.dirname(os.path.abspath(__file__))
IMPORT_NAME = "ytm-import.json"
REFRESH_SECS = 10 * 60
UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) "
      "Chrome/140.0.0.0 Safari/537.36")

# where each build keeps its data
TARGETS = {
    "snap": os.path.join(HOME, "snap/aurora-waves/current/.local/share/aurora-waves"),
    "flatpak": os.path.join(HOME, ".var/app/io.github.elblasy33.AuroraWaves/data/aurora-waves"),
}
BROWSERS = {
    "chrome": ["~/.config/google-chrome"],
    "brave": ["~/.config/BraveSoftware/Brave-Browser"],
    "edge": ["~/.config/microsoft-edge"],
    "chromium": ["~/.config/chromium", "~/snap/chromium/common/chromium"],
    "vivaldi": ["~/.config/vivaldi"],
    "opera": ["~/.config/opera"],
    "firefox": ["~/.mozilla/firefox", "~/snap/firefox/common/.mozilla/firefox",
                "~/.var/app/org.mozilla.firefox/.mozilla/firefox"],
}
AUTOSTART = os.path.join(os.environ.get("XDG_CONFIG_HOME") or os.path.join(HOME, ".config"),
                         "autostart", "aurora-waves-signin.desktop")
APPS = os.path.join(os.environ.get("XDG_DATA_HOME") or os.path.join(HOME, ".local/share"), "applications")
SCHEME = "aurora-waves-signin"
HANDLER = os.path.join(APPS, SCHEME + ".desktop")
MARKER = "signin-helper.json"           # tells the app that its sign-in button can call us
ERROR_NAME = "ytm-import-error.json"

AR = os.environ.get("LANG", "").startswith("ar")


def say(ar, en):
    print(ar if AR else en, flush=True)


def load_ytdlp():
    """yt-dlp from the system, else the copy inside the app (pure Python, any Python 3.9+)."""
    try:
        import yt_dlp.cookies  # noqa: F401
        return
    except ImportError:
        pass
    for extra in (os.path.dirname(HERE),                                  # the app's site-packages
                  os.path.join(HOME, ".local/share/aurora-waves/pylib")):  # the Plasma widget's copy
        if os.path.isdir(os.path.join(extra, "yt_dlp")):
            sys.path.append(extra)
            try:
                import yt_dlp.cookies  # noqa: F401
                return
            except ImportError:
                sys.path.remove(extra)
    say("لم أجد yt-dlp. ثبّته:  sudo apt install yt-dlp", "yt-dlp not found. Install it: sudo apt install yt-dlp")
    sys.exit(2)


def installed_browsers():
    out = []
    for name, dirs in BROWSERS.items():
        if any(os.path.isdir(os.path.expanduser(d)) for d in dirs):
            out.append(name)
    return out


def read_session(browser):
    from yt_dlp.cookies import extract_cookies_from_browser

    class Quiet:
        def debug(self, *a, **k): pass
        def info(self, *a, **k): pass
        def warning(self, *a, **k): pass
        def error(self, *a, **k): pass

    jar = extract_cookies_from_browser(browser, logger=Quiet())
    cookies = {}
    for c in jar:
        if c.domain.lstrip(".").endswith("youtube.com") and c.value:
            cookies[c.name] = c.value
    if not ({"SAPISID", "__Secure-3PAPISID"} & set(cookies)):
        return None
    cookies.setdefault("__Secure-3PAPISID", cookies.get("SAPISID", ""))
    return {
        "cookie": "; ".join("%s=%s" % kv for kv in cookies.items()),
        "x-goog-authuser": "0",
        "authorization": "SAPISIDHASH 0_0",
        "user-agent": UA,
        "accept": "*/*",
        "content-type": "application/json",
        "origin": "https://music.youtube.com",
        "x-origin": "https://music.youtube.com",
    }


def find_session(only=None, verbose=True):
    for browser in [only] if only else installed_browsers():
        try:
            headers = read_session(browser)
        except Exception as e:
            if verbose:
                say("  %s: تعذّرت القراءة (%s)" % (browser, e), "  %s: could not read it (%s)" % (browser, e))
            continue
        if headers:
            return browser, headers
        if verbose:
            say("  %s: غير مسجّل في يوتيوب" % browser, "  %s: not signed in to YouTube" % browser)
    return None, None


def hand_over(browser, headers):
    done = []
    for name, folder in TARGETS.items():
        if not os.path.isdir(os.path.dirname(os.path.dirname(folder))):    # that build isn't installed
            continue
        os.makedirs(folder, exist_ok=True)
        path = os.path.join(folder, IMPORT_NAME)
        tmp = path + ".tmp"
        fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump({"browser": browser, "headers": headers, "time": int(time.time())}, f)
        os.replace(tmp, path)
        try:
            os.unlink(os.path.join(folder, ERROR_NAME))
        except OSError:
            pass
        done.append(name)
    return done


def installed_targets():
    return [t for t in TARGETS.values() if os.path.isdir(os.path.dirname(os.path.dirname(t)))]


def report_error(code):
    """Started from the app's button there is no terminal: tell the app what went wrong."""
    for folder in installed_targets():
        os.makedirs(folder, exist_ok=True)
        with open(os.path.join(folder, ERROR_NAME), "w") as f:
            json.dump({"error": code, "time": int(time.time())}, f)


def install_handler():
    """Register aurora-waves-signin: so the sandboxed app can ask the desktop to run us."""
    import subprocess
    os.makedirs(APPS, exist_ok=True)
    with open(HANDLER, "w") as f:
        f.write("[Desktop Entry]\nType=Application\nName=Aurora Waves sign-in\n"
                "Comment=Signs Aurora Waves in to YouTube Music with your browser's session\n"
                "Exec=python3 %s --from-app %%u\nMimeType=x-scheme-handler/%s;\n"
                "NoDisplay=true\nTerminal=false\n" % (os.path.abspath(__file__), SCHEME))
    for cmd in (["xdg-mime", "default", os.path.basename(HANDLER), "x-scheme-handler/" + SCHEME],
                ["update-desktop-database", APPS]):
        try:
            subprocess.run(cmd, capture_output=True, timeout=20)
        except (OSError, subprocess.SubprocessError):
            pass
    for folder in installed_targets():
        os.makedirs(folder, exist_ok=True)
        with open(os.path.join(folder, MARKER), "w") as f:
            json.dump({"scheme": SCHEME, "path": os.path.abspath(__file__)}, f)


def remove_handler():
    for path in [HANDLER] + [os.path.join(t, MARKER) for t in TARGETS.values()]:
        try:
            os.unlink(path)
        except OSError:
            pass


def set_autostart(on):
    if not on:
        try:
            os.unlink(AUTOSTART)
        except OSError:
            pass
        return
    os.makedirs(os.path.dirname(AUTOSTART), exist_ok=True)
    with open(AUTOSTART, "w") as f:
        f.write("[Desktop Entry]\nType=Application\nName=Aurora Waves sign-in\n"
                "Comment=Keeps the YouTube Music session of Aurora Waves fresh\n"
                "Exec=python3 %s --keep\nNoDisplay=true\nX-GNOME-Autostart-enabled=true\n"
                % os.path.abspath(__file__))


def main():
    p = argparse.ArgumentParser(description="Sign Aurora Waves (Snap / Flatpak) in to YouTube Music.")
    p.add_argument("--browser", choices=sorted(BROWSERS))
    p.add_argument("--keep", action="store_true")
    p.add_argument("--autostart", action="store_true")
    p.add_argument("--no-autostart", action="store_true")
    p.add_argument("--from-app", nargs="?", const="", metavar="URL", help=argparse.SUPPRESS)
    p.add_argument("--uninstall", action="store_true", help="remove the sign-in button support and autostart")
    a = p.parse_args()

    if a.uninstall:
        set_autostart(False)
        remove_handler()
        say("أُزيل كل شيء أضافه هذا السكريبت.", "Everything this script added was removed.")
        return 0
    if a.from_app is not None:                 # the app's sign-in button, through the desktop
        load_ytdlp()
        browser, headers = find_session(a.browser, verbose=False)
        if headers:
            hand_over(browser, headers)
            return 0
        report_error("not-signed-in")
        return 1

    if a.no_autostart:
        set_autostart(False)
        say("أُزيل التشغيل التلقائي.", "Autostart entry removed.")
        return 0
    load_ytdlp()
    if not any(os.path.isdir(os.path.dirname(os.path.dirname(t))) for t in TARGETS.values()):
        say("Aurora Waves (Snap أو Flatpak) غير مثبّت. شغّله مرة واحدة أولاً.",
            "Aurora Waves (Snap or Flatpak) is not installed. Open it once first.")
        return 1

    say("أبحث عن متصفح مسجّل في يوتيوب…", "Looking for a browser signed in to YouTube…")
    browser, headers = find_session(a.browser)
    if not headers:
        say("لم أجد حساباً. افتح music.youtube.com في متصفحك وسجّل الدخول، ثم أعد تشغيل هذا الأمر.",
            "No account found. Sign in at music.youtube.com in your browser, then run this again.")
        return 1
    to = hand_over(browser, headers)
    install_handler()
    say("تم: أُرسلت جلسة %s إلى التطبيق (%s). ارجع للتطبيق، سيظهر حسابك خلال ثوانٍ."
        % (browser, ", ".join(to)),
        "Done: the %s session was handed to the app (%s). Back in the app, your account shows up "
        "in a few seconds." % (browser, ", ".join(to)))

    say("من الآن يكفي زر «الدخول من المتصفح» داخل التطبيق، بدون الطرفية.",
        "From now on the app's “Sign in from browser” button is enough, no terminal needed.")
    if a.autostart:
        set_autostart(True)
        say("سيُجدَّد الدخول تلقائياً بعد كل تشغيل للجهاز.", "The session will be renewed after every login.")
        a.keep = True
    if a.keep:
        say("يعمل في الخلفية ويجدّد الجلسة كل 10 دقائق (Ctrl+C للإيقاف).",
            "Renewing the session every 10 minutes (Ctrl+C to stop).")
        while True:
            time.sleep(REFRESH_SECS)
            b, h = find_session(browser, verbose=False)
            if h:
                hand_over(b, h)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(0)
