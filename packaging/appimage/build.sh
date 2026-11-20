#!/bin/sh
# Build the AppImage inside Ubuntu 22.04 (glibc 2.35), so it runs on distributions from 2022 on.
#   packaging/appimage/build.sh            -> dist/Aurora_Waves-<version>-x86_64.AppImage
# Needs Docker. The same script runs in CI for releases.
set -e
cd "$(dirname "$0")/../.."
mkdir -p dist
docker run --rm -v "$PWD":/src -w /src -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
    ubuntu:22.04 sh packaging/appimage/in-container.sh
ls -lh dist/*.AppImage
