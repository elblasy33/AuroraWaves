#!/usr/bin/env python3
"""Prepare the files of a Flathub submission (or of an update to the Flathub repository).

    packaging/flatpak/make-flathub-submission.py v0.1.1 OUTDIR

Copies the manifest and the files it includes into OUTDIR, with the app built from the given
git tag of github.com/elblasy33/AuroraWaves (pinned to its commit) instead of the local tree.
"""
import os
import shutil
import subprocess
import sys

import yaml

HERE = os.path.dirname(os.path.abspath(__file__))
APP_ID = "io.github.elblasy33.AuroraWaves"
REPO = "https://github.com/elblasy33/AuroraWaves.git"
FILES = ["mpv.yaml", "yt-dlp-js.yaml", "python3-requirements.json", "lua5.1"]


def main(tag, outdir):
    commit = subprocess.run(["git", "-C", HERE, "rev-list", "-n", "1", tag], check=True,
                            capture_output=True, text=True).stdout.strip()
    with open(os.path.join(HERE, APP_ID + ".yml"), encoding="utf-8") as f:
        text = f.read()
    manifest = yaml.safe_load(text)
    for mod in manifest["modules"]:
        if isinstance(mod, dict) and mod.get("name") == "aurora-waves":
            mod["sources"] = [{"type": "git", "url": REPO, "tag": tag, "commit": commit,
                               "x-checker-data": {"type": "git", "tag-pattern": r"^v([\d.]+)$"}}]
    os.makedirs(outdir, exist_ok=True)
    header = "".join(l for l in text.splitlines(True) if l.startswith("#") and "flatpak-builder" not in l
                     and "local" not in l)
    with open(os.path.join(outdir, APP_ID + ".yml"), "w", encoding="utf-8") as f:
        f.write(header + yaml.safe_dump(manifest, sort_keys=False, allow_unicode=True, width=120))
    for name in FILES:
        src = os.path.join(HERE, name)
        dst = os.path.join(outdir, name)
        if os.path.isdir(src):
            shutil.copytree(src, dst, dirs_exist_ok=True)
        else:
            shutil.copy2(src, dst)
    with open(os.path.join(outdir, "flathub.json"), "w") as f:
        f.write('{\n    "only-arches": ["x86_64"]\n}\n')    # mpv's deno module is x86_64 + aarch64; built and tested on x86_64
    print("%s at %s (%s) -> %s" % (APP_ID, tag, commit[:12], outdir))


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
