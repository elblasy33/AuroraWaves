# Packaging

| Store | File | Build |
|---|---|---|
| Flathub | `flatpak/io.github.elblasy33.AuroraWaves.yml` (+ `mpv.yaml`, `yt-dlp.yaml`) | `flatpak-builder --user --install --force-clean build packaging/flatpak/io.github.elblasy33.AuroraWaves.yml` |
| Snap Store | `snap/snapcraft.yaml` (copy to `snap/` at the project root) | `snapcraft pack` |
| AppImage | `appimage/AppImageBuilder.yml` | `appimage-builder --recipe packaging/appimage/AppImageBuilder.yml` |

**Status: first drafts, not built yet.** Each needs its toolchain (flatpak-builder with the KDE
SDK 6.11 and the PySide BaseApp, snapcraft, appimage-builder) and a test build before submission.

Notes for reviewers:
- The YouTube Music sign-in reads the browser session the user already has. Inside Flatpak and Snap
  that needs read access to the browser profile and the keyring, which the manifests do not grant
  by default: the manual sign-in (pasted request headers) works everywhere.
- `--filesystem=xdg-config/plasma-org.kde.plasma.desktop-appletsrc:ro` is only for importing the
  stations of the Aurora Waves Plasma widget; it can be dropped.
