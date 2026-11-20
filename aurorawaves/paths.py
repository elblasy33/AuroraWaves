"""Where the app keeps its files (its own folders: never shared with the Plasma widget)."""
import os

_home = os.path.expanduser("~")
DATA = os.path.join(os.environ.get("XDG_DATA_HOME") or os.path.join(_home, ".local/share"), "aurora-waves")
CONFIG = os.path.join(os.environ.get("XDG_CONFIG_HOME") or os.path.join(_home, ".config"), "aurora-waves")
CACHE = os.path.join(os.environ.get("XDG_CACHE_HOME") or os.path.join(_home, ".cache"), "aurora-waves")
RUN = os.environ.get("XDG_RUNTIME_DIR") or "/tmp"

for _d in (DATA, CONFIG, CACHE):
    os.makedirs(_d, exist_ok=True)
