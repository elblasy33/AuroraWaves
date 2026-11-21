"""Application start-up: one instance, the QML window, tray icon and the in-app player."""
import os
import sys

from . import APP_ID, APP_NAME, VERSION

QML_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "qml")
ICON = os.path.join(os.path.dirname(os.path.abspath(__file__)), "assets", "aurora-waves.svg")


def main():
    # our own glass controls: the same look on every desktop
    os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")

    from PySide6.QtCore import QTimer, QUrl
    from PySide6.QtGui import QIcon
    from PySide6.QtNetwork import QLocalServer, QLocalSocket
    from PySide6.QtQml import QQmlApplicationEngine
    from PySide6.QtWidgets import QApplication, QMenu, QSystemTrayIcon

    QApplication.setApplicationName("aurora-waves")
    QApplication.setApplicationDisplayName(APP_NAME)
    QApplication.setApplicationVersion(VERSION)
    QApplication.setOrganizationName("aurora-waves")
    QApplication.setDesktopFileName(APP_ID)
    app = QApplication(sys.argv)
    app.setWindowIcon(QIcon(ICON))
    app.setQuitOnLastWindowClosed(False)          # the window may live on in the tray

    # screenshot mode runs isolated: beside a running instance, without taking its MPRIS name
    shot = os.environ.get("AURORA_SHOT")

    # ---- single instance: a second launch just raises the first window
    key = "aurora-waves-" + str(os.getuid()) + ("-shot" if shot else "")
    probe = QLocalSocket()
    probe.connectToServer(key)
    if not shot and probe.waitForConnected(300):
        probe.write(b"raise")
        probe.waitForBytesWritten(300)
        return 0
    QLocalServer.removeServer(key)
    server = QLocalServer()
    server.listen(key)

    # Qt's controls look icons up by name: give them the bundled set, colored for the theme
    from . import icons, paths
    import json
    try:
        theme = json.load(open(os.path.join(paths.CONFIG, "settings.json"))).get("theme", "system")
    except (OSError, ValueError):
        theme = "dark"
    light = theme == "light" or (theme == "system" and app.styleHints().colorScheme().name != "Dark")
    icons.install_theme(os.path.join(paths.CACHE, "icons"), "#1b1d2c" if light else "#f2f3fa",
                        QIcon.themeName())

    from .backend import Backend
    from .icons import IconProvider
    from .player import Player

    holder = {}

    def raise_window():
        backend.raiseRequested.emit()

    if shot:
        from .core import radiod
        radiod.MPV_SOCK += ".shot"
    player = Player(on_raise=raise_window, on_quit=app.quit, mpris=not shot)
    player.enable_mpris(True)
    backend = Backend(player)
    holder["backend"] = backend
    server.newConnection.connect(lambda: (server.nextPendingConnection(), raise_window()))

    # ---- tray icon: play/pause, next, show, quit
    if QSystemTrayIcon.isSystemTrayAvailable():
        tray = QSystemTrayIcon(QIcon(ICON))
        tray.setToolTip(APP_NAME)
        menu = QMenu()
        for name, label in (("toggle", "⏯"), ("next", "⏭"), ("show", APP_NAME), ("quit", "✕")):
            act = menu.addAction(label)
            act.triggered.connect(lambda _=False, n=name: backend.trayAction.emit(n))
        tray.setContextMenu(menu)
        tray.activated.connect(lambda reason: backend.trayAction.emit("show")
                               if reason == QSystemTrayIcon.ActivationReason.Trigger else None)
        tray.show()
        holder["tray"], holder["menu"] = tray, menu
        backend.tray_available = True
        actions = menu.actions()

        def labels(texts):
            for act, text in zip(actions, texts):
                act.setText(text)
        backend.tray_labels_hook = labels
        backend.tray_message_hook = lambda title, text: tray.showMessage(title, text, QIcon(ICON), 6000)

    engine = QQmlApplicationEngine()
    engine.addImageProvider("icons", IconProvider())
    engine.rootContext().setContextProperty("Backend", backend)
    engine.load(QUrl.fromLocalFile(os.path.join(QML_DIR, "Main.qml")))
    if not engine.rootObjects():
        return 1

    # the player's state machine (reconnects, end of queue) runs on a steady tick
    ticker = QTimer()
    ticker.timeout.connect(player.evaluate)
    ticker.start(1000)

    # development / store screenshots: AURORA_SHOT=/path.png [AURORA_PAGE=youtube] [AURORA_SIZE=WxH] [AURORA_SHOT_MS=6000]
    if shot:
        root = engine.rootObjects()[0]
        if os.environ.get("AURORA_PAGE"):
            root.setProperty("page", os.environ["AURORA_PAGE"])
        if os.environ.get("AURORA_YT_VIEW") == "account":       # screenshot of the account page
            from PySide6.QtCore import QMetaObject, QObject
            QTimer.singleShot(2500, lambda: QMetaObject.invokeMethod(root.findChild(QObject, "ytPage"), "showAccount"))
        if os.environ.get("AURORA_SIZE"):
            w, h = (int(x) for x in os.environ["AURORA_SIZE"].lower().split("x"))
            root.resize(w, h)

        def grab():
            root.grabWindow().save(shot)
            app.quit()
        QTimer.singleShot(int(os.environ.get("AURORA_SHOT_MS", "6000")), grab)

    app.aboutToQuit.connect(player.shutdown)
    code = app.exec()
    # A directory or YouTube request may still be running on the thread pool; Python would wait
    # for it before exiting (minutes on a slow network). Settings are already saved (Main.qml
    # saves them on aboutToQuit) and mpv is stopped, so leave now.
    sys.stdout.flush()
    os._exit(code)
