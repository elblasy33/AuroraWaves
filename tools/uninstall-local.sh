#!/bin/sh
# Remove what install-local.sh added (your stations and settings stay unless you pass --purge).
APP_ID=io.github.elblasy33.AuroraWaves
DATA=${XDG_DATA_HOME:-$HOME/.local/share}
rm -f "$HOME/.local/bin/aurora-waves" "$DATA/applications/$APP_ID.desktop" \
      "$DATA/icons/hicolor/scalable/apps/$APP_ID.svg" "$DATA/metainfo/$APP_ID.metainfo.xml"
if [ "$1" = "--purge" ]; then
    rm -rf "$DATA/aurora-waves" "${XDG_CONFIG_HOME:-$HOME/.config}/aurora-waves" "${XDG_CACHE_HOME:-$HOME/.cache}/aurora-waves"
fi
update-desktop-database -q "$DATA/applications" 2>/dev/null || true
command -v kbuildsycoca6 >/dev/null && kbuildsycoca6 >/dev/null 2>&1 || true
echo "✓ Aurora Waves removed."
