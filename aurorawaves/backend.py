"""The bridge QML talks to (context property `Backend`).

Long jobs (directory search, YouTube Music, audio checks) run on a thread pool and answer through a
JS callback with a JSON string, exactly like the widget's process bridge did, so the ported pages
keep their `runSources(cmd, arg, cb)` / `runYt(...)` calls. Playback requests go straight to the
in-app player and return its status at once.
"""
import json
import os
import shutil
from concurrent.futures import ThreadPoolExecutor

from PySide6.QtCore import Property, QObject, QUrl, Signal, Slot
from PySide6.QtGui import QDesktopServices
from PySide6.QtQml import QJSValue

from . import APP_ID, APP_NAME, VERSION, icons, paths
from .core import radioctl, sources, ytmusic

MODULES = {"sources": sources, "yt": ytmusic}


class Backend(QObject):
    _finished = Signal(int, str)
    raiseRequested = Signal()
    trayAction = Signal(str)

    def __init__(self, player, parent=None):
        super().__init__(parent)
        self.player = player
        self._pool = ThreadPoolExecutor(max_workers=8)
        self._callbacks = {}
        self._next = 0
        self._finished.connect(self._deliver)
        self.tray_available = False
        self._art = os.path.join(paths.CACHE, "art")
        os.makedirs(self._art, exist_ok=True)

    # ---------------------------------------------------------------- async jobs
    @Slot(str, str, str, QJSValue)
    def run(self, module, cmd, arg, callback):
        """module: "sources" | "yt". The callback receives the JSON reply as a string."""
        self._next += 1
        job_id = self._next
        self._callbacks[job_id] = callback
        mod = MODULES.get(module)

        def work():
            try:
                result = mod.dispatch(cmd, arg) if mod else {"error": "unknown module"}
            except Exception as e:                      # never lose a callback
                result = {"error": str(e)}
            self._finished.emit(job_id, json.dumps(result, ensure_ascii=False))

        self._pool.submit(work)

    @Slot(int, str)
    def _deliver(self, job_id, out):
        cb = self._callbacks.pop(job_id, None)
        if cb is not None and cb.isCallable():
            cb.call([QJSValue(out)])

    # ---------------------------------------------------------------- playback
    @Slot(str, result=str)
    def send(self, request):
        """One player request (same JSON the widget sent to radiod); returns the status JSON."""
        try:
            reply = self.player.handle(json.loads(request or "{}"))
        except Exception as e:
            reply = {"daemon": True, "error": str(e)}
        return json.dumps(reply, ensure_ascii=False)

    @Slot()
    def tick(self):
        self.player.evaluate()

    # ---------------------------------------------------------------- files
    @Slot(str, result=str)
    def readConfig(self, name):
        try:
            with open(os.path.join(paths.CONFIG, os.path.basename(name)), encoding="utf-8") as f:
                return f.read()
        except OSError:
            return ""

    @Slot(str, str, result=bool)
    def writeConfig(self, name, text):
        path = os.path.join(paths.CONFIG, os.path.basename(name))
        try:
            with open(path + ".tmp", "w", encoding="utf-8") as f:
                f.write(text)
            os.replace(path + ".tmp", path)          # never leave a half-written file
            return True
        except OSError:
            return False

    @Slot(str, result=str)
    def parsePlaylist(self, url):
        try:
            return json.dumps(radioctl.parse_playlist(url), ensure_ascii=False)
        except OSError:
            return "[]"

    # ---------------------------------------------------------------- import from the widget
    @staticmethod
    def _widget_stations():
        """Stations of the Aurora Waves Plasma widget, read from Plasma's applet config."""
        import configparser
        cfg = os.path.join(os.path.dirname(paths.CONFIG), "plasma-org.kde.plasma.desktop-appletsrc")
        cp = configparser.RawConfigParser(strict=False, interpolation=None)
        cp.optionxform = str
        try:
            with open(cfg, encoding="utf-8") as f:
                cp.read_string(f.read())
        except (OSError, configparser.Error):
            return []
        found, seen = [], set()
        for sec in cp.sections():
            if cp.get(sec, "plugin", fallback="") != "com.github.elblasy33.auroraradio":
                continue
            try:
                for st in json.loads(cp.get(sec + "][Configuration][General", "stations", fallback="[]")):
                    if st.get("url") and st["url"] not in seen:
                        seen.add(st["url"])
                        found.append(st)
            except ValueError:
                pass
        return found

    @Property(int, constant=True)
    def widgetStationCount(self):
        return len(self._widget_stations())

    @Slot(result=str)
    def widgetStations(self):
        """The widget's stations, with their saved logos copied into the app's own folder."""
        out = []
        for st in self._widget_stations():
            logo = st.get("logo") or ""
            if logo.startswith("file://") and "/aurora-radio/" in logo:
                try:
                    st["logo"] = sources.fetch_logo(logo) or ""
                except Exception:
                    st["logo"] = ""
            out.append(st)
        return json.dumps(out, ensure_ascii=False)

    @Slot(str)
    def openUrl(self, url):
        QDesktopServices.openUrl(QUrl(url))

    # ---------------------------------------------------------------- facts
    @Property(str, constant=True)
    def artDir(self):
        return self._art

    @Property(str, constant=True)
    def version(self):
        return VERSION

    @Property(str, constant=True)
    def appId(self):
        return APP_ID

    @Property(str, constant=True)
    def appName(self):
        return APP_NAME

    @Property(bool, constant=True)
    def trayAvailable(self):
        return self.tray_available

    @Property(bool, constant=True)
    def hasMpv(self):
        return shutil.which("mpv") is not None

    @Property("QStringList", constant=True)
    def iconNames(self):
        return icons.bundled_names()
