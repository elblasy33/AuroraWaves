#!/bin/sh
# Run from the source tree (development): ./run.sh
cd "$(dirname "$0")"
[ -d .venv ] || { python3 -m venv --system-site-packages .venv && .venv/bin/pip install -q PySide6-Essentials ytmusicapi yt-dlp; }
exec .venv/bin/python -m aurorawaves "$@"
