#!/usr/bin/env python3
"""Pushes the builds in builds/ to Breakhaus's itch.io page with butler, each
export preset to its own channel (Windows to windows, Linux to linux, Web
to html5, Android to android).

    ./upload_to_itchio.sh               every preset that has been built
    ./upload_to_itchio.sh Web Linux     just the ones named
    ./upload_to_itchio.sh --dry-run     shows what the page has and what would go up, pushes nothing
    ./upload_to_itchio.sh --status      just shows what the page has (a build just pushed is "queued" until itch.io has processed it)

Build first with ./build_game.sh. Every build named is checked before
anything is pushed, so a missing one can't leave a half-released version.
The version is config/version in project.godot. Uses the butler for the
host in butler-linux-amd64/ or butler-windows-amd64/ beside the repo, or
the copies next to GoreDash's (found from the checkout or any folder above
it, so worktrees work too), or one on the PATH.
"""
import argparse
import datetime
import re
import shutil
import subprocess
import sys
from pathlib import Path

ITCH_PROJECT = "pigmassacre/breakhaus"
# Without the saved key butler falls back to its own login (butler login).
CREDENTIALS = Path.home() / ".config" / "itch" / "butler_olofkarlsson_creds"
# itch.io's channel for each preset; the web build is played in the browser from html5.
CHANNELS = {"Windows": "windows", "Linux": "linux", "Web": "html5", "Android": "android"}

BUTLER_BY_HOST = {
    "win32": ("butler-windows-amd64", "butler.exe"),
    "linux": ("butler-linux-amd64", "butler"),
}

repo_root = Path(__file__).resolve().parent


def fail(message):
    print(f"Error: {message}", file=sys.stderr)
    sys.exit(1)


def find_butler() -> Path:
    if sys.platform not in BUTLER_BY_HOST:
        fail(f"no butler for {sys.platform}")
    folder, exe = BUTLER_BY_HOST[sys.platform]
    if (repo_root / folder / exe).exists():
        return repo_root / folder / exe
    # GoreDash's, from any folder above, so a worktree finds it too.
    for base in repo_root.parents:
        if (base / "goredash" / folder / exe).exists():
            return base / "goredash" / folder / exe
    on_path = shutil.which(exe)
    if on_path:
        return Path(on_path)
    fail(f"{folder}/{exe} not found beside the repo or GoreDash, nor on the PATH")


def main():
    presets_text = (repo_root / "export_presets.cfg").read_text(encoding="utf-8")
    all_presets = re.findall(r'^name="(.+)"$', presets_text, re.MULTILINE)
    export_paths = dict(zip(all_presets, re.findall(r'^export_path="(.+)"$', presets_text, re.MULTILINE)))

    parser = argparse.ArgumentParser(description="Push Breakhaus's builds to itch.io.")
    parser.add_argument("presets", nargs="*", metavar="preset",
                        help=f"{' and/or '.join(all_presets)} (default: every one built)")
    parser.add_argument("--dry-run", action="store_true",
                        help="show what the page has and what would go up, without pushing")
    parser.add_argument("--status", action="store_true",
                        help="just show what the page has, builds still processing included")
    args = parser.parse_args()

    by_lower_name = {preset.lower(): preset for preset in all_presets}
    unknown = [name for name in args.presets if name.lower() not in by_lower_name]
    if unknown:
        parser.error(f"unknown preset {', '.join(unknown)} (choose from {', '.join(all_presets)})")
    presets = list(dict.fromkeys(by_lower_name[name.lower()] for name in args.presets))

    butler_exe = find_butler()
    butler_dir = butler_exe.parent
    # butler on its own signs in with its own login, which may be another
    # account: itch.io then calls the page an "invalid game".
    identity = ["--identity", str(CREDENTIALS)] if CREDENTIALS.exists() else []

    if args.status:
        sys.exit(subprocess.run([str(butler_exe), "status", ITCH_PROJECT] + identity, cwd=butler_dir).returncode)

    match = re.search(r'^config/version="(.+)"$', (repo_root / "project.godot").read_text(encoding="utf-8"), re.MULTILINE)
    if not match:
        fail("no config/version in project.godot")
    version = match.group(1)

    # Every preset named must be built; with none named, every one that is built goes.
    if presets:
        missing = [export_paths[p] for p in presets if not (repo_root / export_paths[p]).exists()]
        if missing:
            fail(f"no build at {', '.join(missing)} (run ./build_game.sh first)")
    else:
        presets = [p for p in all_presets if (repo_root / export_paths[p]).exists()]
        if not presets:
            fail("nothing built (run ./build_game.sh first)")

    # What the page has now; it also stops a wrong key or page before anything is pushed.
    print(f"{ITCH_PROJECT} now:", flush=True)
    if subprocess.run([str(butler_exe), "status", ITCH_PROJECT] + identity, cwd=butler_dir).returncode != 0:
        fail(f"butler can't reach {ITCH_PROJECT}")

    print(f"\nPushing version {version}:")
    for preset in presets:
        built = datetime.datetime.fromtimestamp((repo_root / export_paths[preset]).stat().st_mtime)
        print(f"  {preset}: {Path(export_paths[preset]).parent}/ to {CHANNELS[preset]}, built {built:%Y-%m-%d %H:%M}")

    for preset in presets:
        cmd = [
            str(butler_exe), "push",
            str(repo_root / Path(export_paths[preset]).parent),
            f"{ITCH_PROJECT}:{CHANNELS[preset]}",
            "--userversion", version,
            # A Linux build made on Windows has lost its executable bit.
            "--fix-permissions",
            "--if-changed",
        ] + identity
        if args.dry_run:
            cmd.append("--dry-run")

        print(f"\n=== Pushing {preset} ===", flush=True)
        result = subprocess.run(cmd, cwd=butler_dir)
        if result.returncode != 0:
            print(f"Pushing {preset} failed.", file=sys.stderr)
            sys.exit(result.returncode)

    print("\nDry run done, nothing was pushed." if args.dry_run else
          "\nDone. ./upload_to_itchio.sh --status shows when itch.io has processed it (queued until then).")


if __name__ == "__main__":
    main()
