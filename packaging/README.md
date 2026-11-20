# Packaging

| Store | File | Build |
|---|---|---|
| Flathub | `flatpak/io.github.elblasy33.AuroraWaves.yml` (+ `mpv.yaml`, `yt-dlp.yaml`) | `flatpak-builder --user --install --force-clean build packaging/flatpak/io.github.elblasy33.AuroraWaves.yml` |
| Snap Store | `snap/snapcraft.yaml` (copy to `snap/` at the project root) | `snapcraft pack` |
| AppImage | `appimage/build.sh` (+ `in-container.sh`) | `packaging/appimage/build.sh` (Docker, Ubuntu 22.04 base) |

**AppImage: builds and works** (radio, YouTube Music, MPRIS with its own GLib, bundled mpv and
yt-dlp; runs on glibc ≥ 2.35). Flatpak and Snap: first drafts, not built yet.

Notes for reviewers:
- The YouTube Music sign-in reads the browser session the user already has. Inside Flatpak and Snap
  that needs read access to the browser profile and the keyring, which the manifests do not grant
  by default: the manual sign-in (pasted request headers) works everywhere.
- `--filesystem=xdg-config/plasma-org.kde.plasma.desktop-appletsrc:ro` is only for importing the
  stations of the Aurora Waves Plasma widget; it can be dropped.
