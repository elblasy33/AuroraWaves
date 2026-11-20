"""Playback for the desktop app: the widget's engine (core/radiod.py) running inside the app.

radiod's Daemon owns one mpv process, keeps the playback state machine (auto-reconnect for
expiring stream links, queues for YouTube Music, pause/seek for files) and publishes MPRIS.
Here it runs in the app's own event loop (Qt drives GLib's main context on Linux) instead of as a
background service, under the app's own names so it never collides with the Plasma widget.
"""
import os

from gi.repository import GLib

from . import APP_ID, APP_NAME, paths
from .core import radiod, ytmusic

radiod.CTL_SOCK = os.path.join(paths.RUN, "aurora-waves-app.sock")        # unused in-app
radiod.MPV_SOCK = os.path.join(paths.RUN, "aurora-waves-app-mpv.sock")
radiod.BUS_NAME = "org.mpris.MediaPlayer2.AuroraWaves"
radiod.APP_NAME = APP_NAME
radiod.DESKTOP_ID = APP_ID
radiod.YTDLP_WRAPPER = ytmusic.YTDLP_WRAPPER
radiod.install_desktop_entry = lambda: None        # the app ships a real .desktop file


class Player(radiod.Daemon):
    """radiod.Daemon plus what a windowed app adds: MPRIS Raise/Quit act on the window."""

    def __init__(self, on_raise=None, on_quit=None):
        super().__init__()
        self.on_raise = on_raise
        self.on_quit = on_quit
        self.app_name = APP_NAME

    def mpris_props(self, iface):
        props = super().mpris_props(iface)
        if iface == "org.mpris.MediaPlayer2":
            props["CanRaise"] = GLib.Variant("b", self.on_raise is not None)
        return props

    def _method(self, conn, sender, path, iface, method, params, inv):
        if iface == "org.mpris.MediaPlayer2" and method == "Raise" and self.on_raise:
            self.on_raise()
            inv.return_value(None)
            return
        if iface == "org.mpris.MediaPlayer2" and method == "Quit" and self.on_quit:
            self.stop()
            self.on_quit()
            inv.return_value(None)
            return
        super()._method(conn, sender, path, iface, method, params, inv)

    def shutdown(self):
        self.stop()
        self.enable_mpris(False)
