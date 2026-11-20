"""Icons for QML: image://icons/<name>?<color>

Freedesktop names used by the interface (media-playback-start, edit-find...) map to the bundled
Lucide set, recolored on the fly, so the app looks the same on every desktop. Names that are not
bundled (browser logos, user-picked icons) come from the system icon theme.
"""
import os

from PySide6.QtCore import QByteArray, QSize, Qt
from PySide6.QtGui import QColor, QIcon, QImage, QPainter
from PySide6.QtQuick import QQuickImageProvider
from PySide6.QtSvg import QSvgRenderer

ICON_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "assets", "icons")

ALIASES = {
    "audio-volume-muted": "volume-x", "audio-volume-low": "volume", "audio-volume-medium": "volume-1",
    "audio-volume-high": "volume-2", "audio-x-generic": "music", "bookmark-new": "bookmark-plus",
    "checkmark": "check", "color-picker": "pipette", "configure": "settings", "dialog-cancel": "x",
    "dialog-error": "circle-alert", "dialog-information": "info", "dialog-ok": "check",
    "dialog-ok-apply": "check-check", "dialog-warning": "triangle-alert", "document-edit": "pencil",
    "document-import": "file-down", "document-open": "file", "done": "check", "edit-copy": "copy",
    "edit-delete": "trash-2", "edit-find": "search", "edit-reset": "rotate-ccw", "emblem-favorite": "heart",
    "folder-important": "folder-heart", "folder-music": "folder-open", "go-down": "chevron-down",
    "go-up": "chevron-up", "go-next": "chevron-right", "go-previous": "chevron-left", "insert-link": "link",
    "insert-image": "image", "list-add": "plus", "media-playback-start": "play", "media-playback-pause": "pause",
    "media-playback-stop": "square", "media-playlist-append": "list-plus", "media-playlist-play": "list-music",
    "media-playlist-shuffle": "shuffle", "media-playlist-repeat": "repeat", "media-skip-backward": "skip-back",
    "media-skip-forward": "skip-forward", "music-note-16th": "music", "network-disconnect": "wifi-off",
    "network-wireless": "radio", "overflow-menu": "ellipsis-vertical", "path": "route", "playlist": "list-music",
    "preferences-desktop-icons": "shapes", "system-log-out": "log-out", "tools-wizard": "wand-sparkles",
    "view-history": "history", "view-media-playlist": "list-music", "view-refresh": "refresh-cw",
    "view-sort-ascending-name": "arrow-down-a-z", "view-sort-descending": "arrow-down-wide-narrow",
    "draw-text": "type", "image-missing": "image-off", "internet-web-browser": "globe", "go-home": "house",
    "home": "house", "library": "library-big", "lyrics": "mic-vocal", "window-close": "x",
}


def svg_path(name):
    base = ALIASES.get(name, name)
    p = os.path.join(ICON_DIR, base + ".svg")
    return p if os.path.isfile(p) else None


def bundled_names():
    return sorted(f[:-4] for f in os.listdir(ICON_DIR) if f.endswith(".svg"))


class IconProvider(QQuickImageProvider):
    def __init__(self):
        super().__init__(QQuickImageProvider.ImageType.Image)
        self._svg = {}

    def requestImage(self, ident, size, requested):
        name, _, color = ident.partition("?")
        w = requested.width() if requested.width() > 0 else 24
        h = requested.height() if requested.height() > 0 else w
        img = QImage(w, h, QImage.Format.Format_ARGB32_Premultiplied)
        img.fill(Qt.GlobalColor.transparent)
        path = svg_path(name)
        if path:
            if path not in self._svg:
                with open(path, encoding="utf-8") as f:
                    self._svg[path] = f.read()
            col = QColor(color) if color else QColor("white")
            data = self._svg[path].replace("currentColor", col.name(QColor.NameFormat.HexRgb))
            r = QSvgRenderer(QByteArray(data.encode()))
            p = QPainter(img)
            p.setRenderHint(QPainter.RenderHint.Antialiasing)
            if col.alphaF() < 1:
                p.setOpacity(col.alphaF())
            r.render(p)
            p.end()
        else:
            icon = QIcon.fromTheme(name)
            if not icon.isNull():
                pm = icon.pixmap(QSize(w, h))
                img = pm.toImage()
        if size is not None:
            size.setWidth(img.width())
            size.setHeight(img.height())
        return img


def install_theme(base_dir, color, inherits):
    """Write an icon theme of the bundled set, recolored, so Qt's own controls (ToolButton,
    MenuItem: icon.name) find every name the interface uses on any desktop. Unknown names fall
    back to the system theme (browser logos and the like)."""
    from PySide6.QtGui import QIcon

    name = "aurora-waves-" + color.lstrip("#")
    root = os.path.join(base_dir, name)
    actions = os.path.join(root, "scalable", "actions")
    os.makedirs(actions, exist_ok=True)
    wanted = {n: n for n in bundled_names()}
    wanted.update({alias: target for alias, target in ALIASES.items() if svg_path(alias)})
    for fname, target in wanted.items():
        dest = os.path.join(actions, fname + ".svg")
        if os.path.exists(dest):
            continue
        with open(os.path.join(ICON_DIR, target + ".svg"), encoding="utf-8") as f:
            data = f.read().replace("currentColor", color)
        with open(dest, "w", encoding="utf-8") as f:
            f.write(data)
    with open(os.path.join(root, "index.theme"), "w") as f:
        f.write("[Icon Theme]\nName=%s\nInherits=%s\nDirectories=scalable/actions\n\n"
                "[scalable/actions]\nSize=24\nMinSize=8\nMaxSize=512\nType=Scalable\nContext=Actions\n"
                % (name, ",".join(x for x in (inherits, "breeze", "Adwaita", "hicolor") if x)))
    QIcon.setThemeSearchPaths([base_dir] + [p for p in QIcon.themeSearchPaths() if p != base_dir])
    QIcon.setFallbackThemeName(inherits or "hicolor")
    QIcon.setThemeName(name)
    return name

