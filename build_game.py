#!/usr/bin/env python3
"""Builds Breakhaus for every export preset (Windows, Linux, Web and
Android) into builds/<preset>/, with the engine's notices and the credits
beside it.

    ./build_game.sh                 every preset whose export template is installed
    ./build_game.sh Web Linux       just the ones named (an error if one can't be built)
    ./build_game.sh --zip           and a zip of each, builds/Breakhaus-<preset>-<commit>.zip

Uses the stock editor in the Godot folder next to the repository (or next to
the checkout this worktree is of), or the one GODOT=/path/to/godot names,
which exports with its own installed templates (Editor > Manage Export
Templates). Android also needs the Android SDK and a JDK set in the
editor's settings (Editor Settings > Export > Android): an editor that
rewrites its settings can leave the JDK's blank, so it is filled in from
JAVA_HOME or the newest JDK in ~/.local/share/jdk when it is. And the keystore
to sign it with in GODOT_ANDROID_KEYSTORE_RELEASE_PATH, _USER and
_PASSWORD; without those it is signed with the editor's debug key
(DEBUG_KEYSTORE), to try out but not to publish. Either way it is the
release template, the only one this needs.
"""
import os
import re
import shutil
import subprocess
import sys

GODOT_VERSION = "4.7.2.stable"
if sys.platform == "win32":
    GODOT_EXE = "Godot_v4.7.2-stable_win64.exe"
    TEMPLATES = os.path.join(os.environ.get("APPDATA", ""), "Godot", "export_templates", GODOT_VERSION)
    DEBUG_KEYSTORE = os.path.join(os.environ.get("APPDATA", ""), "Godot", "keystores", "debug.keystore")
    EDITOR_SETTINGS = os.path.join(os.environ.get("APPDATA", ""), "Godot", "editor_settings-4.7.tres")
elif sys.platform == "darwin":
    GODOT_EXE = "Godot.app/Contents/MacOS/Godot"
    TEMPLATES = os.path.expanduser(f"~/Library/Application Support/Godot/export_templates/{GODOT_VERSION}")
    DEBUG_KEYSTORE = os.path.expanduser("~/Library/Application Support/Godot/keystores/debug.keystore")
    EDITOR_SETTINGS = os.path.expanduser("~/Library/Application Support/Godot/editor_settings-4.7.tres")
else:
    GODOT_EXE = "Godot_v4.7.2-stable_linux.x86_64"
    TEMPLATES = os.path.expanduser(f"~/.local/share/godot/export_templates/{GODOT_VERSION}")
    DEBUG_KEYSTORE = os.path.expanduser("~/.local/share/godot/keystores/debug.keystore")
    EDITOR_SETTINGS = os.path.expanduser("~/.config/godot/editor_settings-4.7.tres")

# The template file each platform's release export needs.
TEMPLATE_FOR = {
    "Windows Desktop": "windows_release_x86_64.exe",
    "Linux": "linux_release.x86_64",
    "Web": "web_nothreads_release.zip",
    "Android": "android_release.apk",
}

script_dir = os.path.dirname(os.path.abspath(__file__))
# GODOT overrides; otherwise beside the repository, or beside the checkout this worktree is of.
godot_path = os.environ.get("GODOT") or os.path.join(os.path.dirname(script_dir), "Godot", GODOT_EXE)
folder = script_dir
while not os.environ.get("GODOT") and folder != os.path.dirname(folder):
    folder = os.path.dirname(folder)
    if os.path.isfile(os.path.join(folder, "Godot", GODOT_EXE)):
        godot_path = os.path.join(folder, "Godot", GODOT_EXE)
        break


def find_jdk():
    """JAVA_HOME, or the newest JDK unpacked in ~/.local/share/jdk, or None."""
    home = os.environ.get("JAVA_HOME")
    if home and os.path.isdir(home):
        return home
    jdks = os.path.expanduser("~/.local/share/jdk")
    if os.path.isdir(jdks):
        found = sorted(d for d in os.listdir(jdks) if os.path.isfile(os.path.join(jdks, d, "bin", "java")))
        if found:
            return os.path.join(jdks, found[-1])
    return None


def ensure_java_sdk_path():
    """Puts a JDK in the editor's settings for the Android export, if its path there is blank."""
    if not os.path.isfile(EDITOR_SETTINGS):
        return
    with open(EDITOR_SETTINGS, encoding="utf-8") as f:
        text = f.read()
    if re.search(r'^export/android/java_sdk_path = "[^"]+"$', text, re.MULTILINE):
        return
    jdk = find_jdk()
    if not jdk:
        print("Error: no JDK set for Android (Editor Settings > Export > Android > Java SDK Path), "
            "and none in JAVA_HOME or ~/.local/share/jdk", file=sys.stderr)
        sys.exit(1)
    line = f'export/android/java_sdk_path = "{jdk}"'
    if re.search(r'^export/android/java_sdk_path = .*$', text, re.MULTILINE):
        text = re.sub(r'^export/android/java_sdk_path = .*$', line, text, flags=re.MULTILINE)
    else:
        text = text.rstrip("\n") + "\n" + line + "\n"
    with open(EDITOR_SETTINGS, "w", encoding="utf-8") as f:
        f.write(text)
    print(f"The editor's Java SDK path was blank: set it to {jdk}.")


def run(args, what, env=None):
    result = subprocess.run(args, cwd=script_dir, env=env)
    if result.returncode != 0:
        print(f"{what} failed with error code {result.returncode}", file=sys.stderr)
        sys.exit(result.returncode)


with open(os.path.join(script_dir, "export_presets.cfg"), encoding="utf-8") as presets_file:
    presets_text = presets_file.read()
all_presets = re.findall(r'^name="(.+)"$', presets_text, re.MULTILINE)
export_paths = dict(zip(all_presets, re.findall(r'^export_path="(.+)"$', presets_text, re.MULTILINE)))
platforms = dict(zip(all_presets, re.findall(r'^platform="(.+)"$', presets_text, re.MULTILINE)))

args = sys.argv[1:]
make_zips = "--zip" in args
named = [arg for arg in args if arg != "--zip"]
by_lower_name = {preset.lower(): preset for preset in all_presets}
unknown = [name for name in named if name.lower() not in by_lower_name]
if unknown:
    print(f"Error: unknown preset {', '.join(unknown)}. Valid presets: {', '.join(all_presets)}", file=sys.stderr)
    sys.exit(1)
presets = [by_lower_name[name.lower()] for name in named] or all_presets
if not os.path.isfile(godot_path):
    print(f"Error: Godot executable not found at {godot_path}", file=sys.stderr)
    sys.exit(1)

# A preset without its template can't be built: named, that's an error; in "every preset", it is left out.
missing = [p for p in presets if not os.path.isfile(os.path.join(TEMPLATES, TEMPLATE_FOR[platforms[p]]))]
if missing and named:
    for p in missing:
        print(f"Error: no {TEMPLATE_FOR[platforms[p]]} in {TEMPLATES} for {p} "
            "(install the export templates: Editor > Manage Export Templates)", file=sys.stderr)
    sys.exit(1)
for p in missing:
    print(f"Skipping {p}: its export template ({TEMPLATE_FOR[platforms[p]]}) isn't installed.")
presets = [p for p in presets if p not in missing]
if not presets:
    print("Error: nothing to build.", file=sys.stderr)
    sys.exit(1)

print(f"Building {', '.join(presets)}...")
# An export lets scripts through that do not compile, so they are checked
# first, after an import has brought the global class names up to date.
run([godot_path, "--headless", "--path", ".", "--import"], "Import")
run([godot_path, "--headless", "--path", ".", "--script", "tools/check_gdscript.gd"], "Script check")
# The Windows icon, drawn from icon.svg, so the two never differ.
run([godot_path, "--headless", "--path", ".", "--script", "tools/make_icon.gd"], "Making icon.ico")

# The builds live inside the project: Godot is to leave them alone.
os.makedirs(os.path.join(script_dir, "builds"), exist_ok=True)
open(os.path.join(script_dir, "builds", ".gdignore"), "w").close()
commit = subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=script_dir, capture_output=True, text=True).stdout.strip()
commit_file = os.path.join(script_dir, "commit.txt")
for preset in presets:
    build_dir = os.path.join(script_dir, os.path.dirname(export_paths[preset]))
    if os.path.isdir(build_dir):
        shutil.rmtree(build_dir)
    os.makedirs(build_dir, exist_ok=True)
    env = None
    if platforms[preset] == "Android":
        ensure_java_sdk_path()
    if platforms[preset] == "Android" and not os.environ.get("GODOT_ANDROID_KEYSTORE_RELEASE_PATH"):
        print("No release keystore (GODOT_ANDROID_KEYSTORE_RELEASE_PATH): Android is signed with the debug key.")
        if not os.path.isfile(DEBUG_KEYSTORE):
            print(f"Error: no debug keystore at {DEBUG_KEYSTORE} (the editor makes one once it has a JDK)", file=sys.stderr)
            sys.exit(1)
        env = dict(os.environ, GODOT_ANDROID_KEYSTORE_RELEASE_PATH=DEBUG_KEYSTORE,
            GODOT_ANDROID_KEYSTORE_RELEASE_USER="androiddebugkey", GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="android")
    print(f"Exporting {preset}...")
    # The commit, for the title's version (Game.version_text): a build has no
    # git to ask. The presets' include filters take it in.
    with open(commit_file, "w", encoding="utf-8") as f:
        f.write(commit + "\n")
    try:
        run([godot_path, "--headless", "--path", ".", "--export-release", preset], f"Export for {preset}", env)
    finally:
        os.remove(commit_file)
    if not os.path.isfile(os.path.join(script_dir, export_paths[preset])):
        print(f"Export for {preset} made no {export_paths[preset]}", file=sys.stderr)
        sys.exit(1)
    # The notices for the third-party code in the engine, and the game's credits, ship next to it.
    run([godot_path, "--headless", "--path", ".", "--script", "tools/write_godot_copyright.gd", "--",
        os.path.join(build_dir, "GODOT_COPYRIGHT.txt")], f"Writing the engine notices for {preset}")
    shutil.copyfile(os.path.join(script_dir, "CREDITS.txt"), os.path.join(build_dir, "CREDITS.txt"))
    for licence in ("Bungee-OFL.txt", "Rubik-OFL.txt"):
        shutil.copyfile(os.path.join(script_dir, "assets", "fonts", licence), os.path.join(build_dir, licence))
    if make_zips:
        archive = os.path.join(script_dir, "builds", f"Breakhaus-{preset}-{commit or 'unknown'}")
        shutil.make_archive(archive, "zip", build_dir)
        print(f"Zipped {os.path.relpath(archive, script_dir)}.zip")
print("Build completed successfully!")
