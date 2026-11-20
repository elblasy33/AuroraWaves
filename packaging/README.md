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

## Flathub

Not submitted. Flathub's [Generative AI policy](https://docs.flathub.org/docs/for-app-authors/requirements#generative-ai-policy)
requires the manifest of a submission to be written by a person (no AI-generated or AI-assisted
content, even when disclosed), the submission and the review replies to be done by a person, and
any AI-generated material in the application to be disclosed. The manifest in `flatpak/` was
written with an AI assistant: it builds the `.flatpak` bundle published on this project's GitHub
Releases and must not be used for a Flathub submission.

## CI

| Workflow | What it does |
|---|---|
| `AppImage` | builds the AppImage in Ubuntu 22.04 (on tags, or by hand for any ref) |
| `Flatpak` | builds the `.flatpak` bundle with Flathub's builder action |
| `Flatpak test` | installs the bundle and checks libraries, radio playback, yt-dlp and the window |
| `Flathub lint` | Flathub's linter on the manifest |

