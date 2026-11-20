#!/bin/sh
# Install Aurora Waves for the current user (no root): app menu entry, icon and `aurora-waves` command.
# Runs from this source tree's .venv, so `git pull && tools/install-local.sh` updates it.
set -e
cd "$(dirname "$0")/.."
SRC=$(pwd)
APP_ID=io.github.elblasy33.AuroraWaves
DATA=${XDG_DATA_HOME:-$HOME/.local/share}
BIN=$HOME/.local/bin

command -v mpv >/dev/null || echo "⚠ mpv is not installed: sudo apt install mpv"
python3 -c "import gi" 2>/dev/null || echo "⚠ python3-gi is not installed: sudo apt install python3-gi"

[ -d .venv ] || python3 -m venv --system-site-packages .venv
.venv/bin/pip install -q --disable-pip-version-check PySide6-Essentials ytmusicapi
.venv/bin/pip install -q --disable-pip-version-check --upgrade --ignore-installed --no-deps yt-dlp
.venv/bin/pip install -q --disable-pip-version-check --no-deps -e .

mkdir -p "$BIN" "$DATA/applications" "$DATA/icons/hicolor/scalable/apps" "$DATA/metainfo"
ln -sf "$SRC/.venv/bin/aurora-waves" "$BIN/aurora-waves"
install -m644 data/icons/hicolor/scalable/apps/$APP_ID.svg "$DATA/icons/hicolor/scalable/apps/"
install -Dm644 data/icons/hicolor/256x256/apps/$APP_ID.png "$DATA/icons/hicolor/256x256/apps/$APP_ID.png"
install -m644 data/$APP_ID.metainfo.xml "$DATA/metainfo/"
# absolute Exec: works even when ~/.local/bin is not on the launcher's PATH
sed "s|^Exec=aurora-waves|Exec=$SRC/.venv/bin/aurora-waves|" data/$APP_ID.desktop > "$DATA/applications/$APP_ID.desktop"

update-desktop-database -q "$DATA/applications" 2>/dev/null || true
gtk-update-icon-cache -q -t "$DATA/icons/hicolor" 2>/dev/null || true
command -v kbuildsycoca6 >/dev/null && kbuildsycoca6 >/dev/null 2>&1 || true
echo "✓ Aurora Waves installed. Open it from the app menu, or run: aurora-waves"
