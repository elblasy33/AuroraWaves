#!/bin/sh
# Runs inside ubuntu:22.04 (see build.sh). Produces dist/Aurora_Waves-<version>-x86_64.AppImage
set -eu
export DEBIAN_FRONTEND=noninteractive APPIMAGE_EXTRACT_AND_RUN=1
VERSION=$(sed -n 's/^version = "\(.*\)"/\1/p' pyproject.toml)
PY=3.12.16+20261110
WORK=/tmp/build
APPDIR=$WORK/AppDir

# leftovers of older builds that ran pip inside /src as root
rm -rf /src/build /src/*.egg-info

echo "== tools and libraries"
apt-get update -qq
apt-get install -y -qq --no-install-recommends ca-certificates curl file patchelf binutils \
    gcc pkg-config meson ninja-build libgirepository1.0-dev libglib2.0-dev gir1.2-glib-2.0 \
    libcairo2-dev \
    mpv desktop-file-utils libfuse2 squashfs-tools \
    libxcb-cursor0 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-render-util0 libxcb-xkb1 \
    libxkbcommon-x11-0 libxcb-shape0 libxcb-xinerama0 libxcb-randr0 libxcb-render0 libxcb-shm0 \
    libxcb-sync1 libxcb-xfixes0 libxcb-xinput0 libxcb-glx0 libxcb-util1 >/dev/null

mkdir -p $WORK && cd $WORK
curl -sSfL -o linuxdeploy https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
curl -sSfL -o appimagetool https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x linuxdeploy appimagetool

echo "== python (relocatable build) and the app"
mkdir -p $APPDIR/usr
curl -sSfL "https://github.com/astral-sh/python-build-standalone/releases/download/${PY#*+}/cpython-${PY}-x86_64-unknown-linux-gnu-install_only.tar.gz" \
    | tar -xz -C $APPDIR/usr
P=$APPDIR/usr/python/bin/python3
$P -m pip install -q --disable-pip-version-check --root-user-action=ignore --upgrade pip
# PyGObject 3.50 is the last one for girepository-1.0 (Ubuntu 22.04's GLib)
$P -m pip install -q --disable-pip-version-check --root-user-action=ignore PySide6-Essentials ytmusicapi yt-dlp \
    "PyGObject<3.51" -Csetup-args=-Dpycairo=disabled
# build the app from a copy: pip writes build/ and *.egg-info next to the sources
mkdir -p $WORK/src
tar -C /src --exclude=.venv --exclude=dist --exclude=build --exclude=.git -cf - . | tar -C $WORK/src -xf -
$P -m pip install -q --disable-pip-version-check --root-user-action=ignore --no-deps $WORK/src
# trim: tests and caches
find $APPDIR/usr/python -name __pycache__ -prune -exec rm -rf {} +
rm -rf $APPDIR/usr/python/lib/python3.12/test $APPDIR/usr/python/lib/python3.12/idlelib

echo "== mpv with its libraries"
./linuxdeploy --appdir $APPDIR --executable /usr/bin/mpv >/dev/null
# GLib introspection for MPRIS (gi)
mkdir -p $APPDIR/usr/lib/girepository-1.0
for t in GLib-2.0 GObject-2.0 Gio-2.0 GModule-2.0; do
    cp /usr/lib/x86_64-linux-gnu/girepository-1.0/$t.typelib $APPDIR/usr/lib/girepository-1.0/
done
cp -L /usr/lib/x86_64-linux-gnu/libgirepository-1.0.so.1 $APPDIR/usr/lib/
# gi finds its GLib in the AppImage by itself (no LD_LIBRARY_PATH: that would leak into every
# program the app starts, like the browser, and break it with our older libraries)
patchelf --set-rpath '$ORIGIN/../../../../../lib' $APPDIR/usr/python/lib/python3.12/site-packages/gi/_gi*.so

# Qt's X11 platform plugin needs small xcb helper libraries that a fresh Ubuntu 22.04 (or another
# distribution) may lack (libxcb-cursor0 above all). They go next to Qt's own libraries, which Qt
# finds through its $ORIGIN RUNPATH: nothing leaks into other programs.
QTLIB=$APPDIR/usr/python/lib/python3.12/site-packages/PySide6/Qt/lib
# every xcb helper the X11 plugin links to, and what those link to (libxcb.so.1 itself is on any X11
# system); found from the libraries themselves rather than from a hand-kept list
need() { readelf -d "$1" | sed -n 's/.*NEEDED.*\[\(.*\)\]/\1/p' | grep -E '^lib(xcb-|xkbcommon-x11)' || true; }
todo="$(need $QTLIB/libQt6XcbQpa.so.6) $(need $QTLIB/../plugins/platforms/libqxcb.so)"
seen=" "
while [ -n "$(echo $todo)" ]; do
    set -- $todo; l=$1; shift; todo="$*"
    case "$seen" in *" $l "*) continue ;; esac
    seen="$seen$l "
    [ -e $QTLIB/$l ] && continue
    cp -L /usr/lib/x86_64-linux-gnu/$l $QTLIB/
    patchelf --set-rpath '$ORIGIN' $QTLIB/$l
    todo="$todo $(need $QTLIB/$l)"
done
echo "bundled xcb helpers:$seen"

echo "== desktop integration"
ID=io.github.elblasy33.AuroraWaves
install -Dm644 /src/data/$ID.desktop $APPDIR/$ID.desktop
install -Dm644 /src/data/$ID.desktop $APPDIR/usr/share/applications/$ID.desktop
install -Dm644 /src/data/$ID.metainfo.xml $APPDIR/usr/share/metainfo/$ID.appdata.xml
install -Dm644 /src/data/icons/hicolor/scalable/apps/$ID.svg $APPDIR/usr/share/icons/hicolor/scalable/apps/$ID.svg
install -Dm644 /src/data/icons/hicolor/256x256/apps/$ID.png $APPDIR/usr/share/icons/hicolor/256x256/apps/$ID.png
cp /src/data/icons/hicolor/256x256/apps/$ID.png $APPDIR/$ID.png      # .DirIcon must be a PNG
ln -sf $ID.png $APPDIR/.DirIcon
cat > $APPDIR/AppRun <<'RUN'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
export PATH="$HERE/usr/bin:$PATH"                    # the bundled mpv
export GI_TYPELIB_PATH="$HERE/usr/lib/girepository-1.0"
unset PYTHONHOME PYTHONPATH
exec "$HERE/usr/python/bin/python3" -s -m aurorawaves "$@"
RUN
chmod +x $APPDIR/AppRun

echo "== AppImage"
OUT=/src/dist/Aurora_Waves-$VERSION-x86_64.AppImage
cd /src/dist
ARCH=x86_64 $WORK/appimagetool --no-appstream \
    -u "gh-releases-zsync|elblasy33|AuroraWaves|latest|Aurora_Waves-*x86_64.AppImage.zsync" \
    $APPDIR $OUT >/dev/null
chown "$HOST_UID:$HOST_GID" /src/dist /src/dist/* 2>/dev/null || true
echo "built $OUT"
