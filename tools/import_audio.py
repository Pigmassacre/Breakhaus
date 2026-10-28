#!/usr/bin/env python3
"""Builds the game's sounds and music (assets/audio/*.ogg) from the sound
libraries kept next to the repo (../Assets by default) and the original
libGDX game's own sounds (assets/audio/original/): picks, trims, levels and
converts each one to Ogg Vorbis.

    python3 tools/import_audio.py [--assets ../Assets] [--only hit,boom]

Each entry of SOUNDS is a game sound: one recipe makes name.ogg, several
make name_1.ogg, name_2.ogg ... for the game to pick from at random. A
recipe is a source (a glob under the assets folder, or under the repo when
it starts with "res:"; the first match is used) and what to do with it:

    start, end   seconds to keep of the source
    length       at most this long (faded out at the end)
    fade         the fade-out at the end, in seconds (default 0.03)
    gain         dB, after the loudest peak is brought to -1 dBFS

Each entry of MUSIC is a track made of Ovani's three layers (Intensity 1,
Intensity 2 and Main: the same piece, sparse to full) as name_1.ogg,
name_2.ogg and name_3.ogg, each looped seamlessly: the reverb tail past the
loop point is folded back over the start. The game plays the layers
together and moves between them with how hot the game is (Audio.music_heat).
Needs ffmpeg.
"""

import argparse
import glob
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
OUT = os.path.join(REPO, "assets", "audio")

CASUAL = "Sound/Casual & Mobile Sound FX Pack Vol. 1/**"
RETRO = "Sound/Retro Gaming Sound FX Pack/Retro/16 Bit/**"
RETRO8 = "Sound/Retro Gaming Sound FX Pack/Retro/8 bit/**"
ELECTRONIC = "Sound/Electronic Music Pack Vol. 5/Electronic Vol 5 Music Pack"
EIGHTIES = "Sound/80s Music Pack/80s Music Pack"

SOUNDS = {
    # --- the ball ---------------------------------------------------------------------------------
    # The original game's own bounce, for the walls.
    "wall": {"src": "res:assets/audio/original/ball.ogg", "gain": -4.0},
    "paddle": [{"src": f"{CASUAL}/Plonk.wav", "length": 0.35}, {"src": f"{CASUAL}/Bouncy Select.wav", "length": 0.35}],
    "smash": [{"src": f"{CASUAL}/Whack Smack A.wav", "length": 0.6}, {"src": f"{CASUAL}/Whack Smack B.wav", "length": 0.6}],
    "miss": {"src": f"{CASUAL}/Uh Oh Button.wav", "length": 0.8},
    # --- blocks -----------------------------------------------------------------------------------
    "chip": [{"src": f"{RETRO}/Block Wood 00{n}.wav", "length": 0.3, "gain": -3.0} for n in (1, 2, 3, 4)],
    "clang": [{"src": f"{RETRO}/Blocking Armor 00{n}.wav", "length": 0.4, "gain": -3.0} for n in (1, 2, 3, 4)],
    "break": {"src": "res:assets/audio/original/block_destroyed.ogg", "gain": -2.0},
    # Rising with the combo: A1 to A5, then B1 to B5.
    "combo": [{"src": f"{CASUAL}/Combo and Break {s}{n}.wav", "length": 0.8} for s in "AB" for n in range(1, 6)],
    "boom": [{"src": f"{RETRO}/Boom Short 00{n}.wav", "length": 0.9} for n in (1, 2, 3, 4, 5)],
    "quake": {"src": f"{RETRO}/Massive Boom.wav", "length": 2.5, "fade": 0.8},
    "drop": [{"src": f"{RETRO}/Big Footsteps 00{n}.wav", "length": 0.4, "gain": -2.0} for n in (1, 2, 3, 4)],
    "coin": {"src": f"{CASUAL}/Looting.wav", "length": 0.8},
    "freeze": {"src": f"{CASUAL}/Casual Glass.wav", "length": 0.9},
    "zap": [{"src": f"{RETRO}/Magic Attack 00{n}.wav", "length": 0.6} for n in (1, 2, 3)],
    "burn": {"src": f"{RETRO}/Fire Start.wav", "length": 0.8},
    "grow": {"src": f"{RETRO}/Glow Short.wav", "length": 0.6, "gain": -4.0},
    # --- pickups ----------------------------------------------------------------------------------
    "pickup": [{"src": f"{CASUAL}/Power Up Grab {c}.wav", "length": 1.0} for c in "ABC"],
    "pickup_bad": {"src": f"{CASUAL}/Power Down.wav", "length": 1.0},
    "release": {"src": f"{CASUAL}/Something Mysterious Unlock.wav", "length": 0.9, "gain": -5.0},
    "rocket": {"src": f"{RETRO}/Missile Released.wav", "length": 0.6, "gain": -3.0},
    "shield": {"src": f"{RETRO}/Force Field Start.wav", "length": 1.0},
    "shield_hit": [{"src": f"{RETRO}/Blocking Move 00{n}.wav", "length": 0.4} for n in (1, 2, 3)],
    "charged": {"src": f"{RETRO}/Charge-Up.wav", "length": 1.2},
    # --- the game ---------------------------------------------------------------------------------
    "countdown": {"src": f"{RETRO8}/Jump 001.wav", "length": 0.3, "gain": -4.0},
    "go": {"src": f"{CASUAL}/Game Start.wav", "length": 1.5},
    "danger": {"src": f"{CASUAL}/Casual Danger Alert.wav", "length": 1.4, "gain": -3.0},
    "cleared": {"src": f"{CASUAL}/Big Win.wav", "length": 3.0, "fade": 0.6},
    "collapse": [{"src": f"{RETRO}/Boom Long 00{n}.wav", "length": 2.0, "fade": 0.6} for n in (1, 2)],
    "game_over": {"src": f"{CASUAL}/Game Over Long.wav", "length": 4.0, "fade": 0.8},
    "best": {"src": f"{CASUAL}/Achievement.wav", "length": 2.5, "fade": 0.5},
    "fanfare": {"src": f"{RETRO}/Fanfare.wav", "length": 2.5, "fade": 0.5},
    # --- menus ------------------------------------------------------------------------------------
    "tick": {"src": f"{CASUAL}/Selection Quick.wav", "length": 0.25, "gain": -4.0},
    "accept": {"src": "res:assets/audio/original/select.ogg"},
    "back": {"src": f"{CASUAL}/No Button.wav", "length": 0.5, "gain": -3.0},
    "pause": {"src": f"{CASUAL}/Soft Button.wav", "length": 0.5},
    "splash": {"src": "res:assets/audio/original/activate.ogg"},
}

MUSIC = {
    "title": f"{ELECTRONIC}/Midnight Cruise*",
    "pump": f"{ELECTRONIC}/Pump*",
    "zinger": f"{ELECTRONIC}/Zinger*",
    "synth_rock": f"{EIGHTIES}/Synth Rock Station*",
}


def find(assets: str, pattern: str) -> str:
    if pattern.startswith("res:"):
        path = os.path.join(REPO, pattern[4:])
        if not os.path.isfile(path):
            raise SystemExit(f"Not found: {path}")
        return path
    matches = sorted(glob.glob(os.path.join(assets, pattern), recursive=True))
    matches = [m for m in matches if "__MACOSX" not in m]
    if not matches:
        raise SystemExit(f"Not found: {pattern}")
    return matches[0]


def peak_db(path: str, filters: str) -> float:
    result = subprocess.run(["ffmpeg", "-hide_banner", "-i", path, "-af", filters + ",volumedetect", "-f", "null", "-"],
        capture_output=True, text=True)
    match = re.search(r"max_volume: (-?[\d.]+) dB", result.stderr)
    return float(match.group(1)) if match else 0.0


def make_sound(assets: str, recipe: dict, out: str) -> None:
    src = find(assets, recipe["src"])
    filters = ["aformat=channel_layouts=mono"]
    start, end = recipe.get("start"), recipe.get("end")
    if start is not None or end is not None:
        filters.append(f"atrim=start={start or 0}" + (f":end={end}" if end is not None else "") + ",asetpts=PTS-STARTPTS")
    # Trims the silence a library leaves in front of a hit, so it lands on the frame.
    filters.append("silenceremove=start_periods=1:start_threshold=-50dB")
    length = recipe.get("length")
    fade = recipe.get("fade", 0.03)
    if length:
        filters.append(f"atrim=end={length},afade=t=out:st={max(length - fade, 0)}:d={fade}")
    chain = ",".join(filters)
    gain = -1.0 - peak_db(src, chain) + recipe.get("gain", 0.0)
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", src, "-af", f"{chain},volume={gain:.2f}dB",
        "-ar", "44100", "-c:a", "libvorbis", "-q:a", "4", out], check=True)


def make_music(assets: str, folder_glob: str, name: str) -> None:
    folder = find(assets, folder_glob)
    tail = float(re.search(r"RT ([\d.]+)", folder).group(1))
    for i, layer in enumerate(["Intensity 1", "Intensity 2", "Main"]):
        src = glob.glob(os.path.join(glob.escape(folder), f"* {layer}.wav"))[0]
        duration = float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", src],
            capture_output=True, text=True).stdout)
        loop = duration - tail
        graph = (f"[0]atrim=0:{loop},asetpts=PTS-STARTPTS[body];"
            f"[0]atrim={loop},asetpts=PTS-STARTPTS[tail];"
            "[body][tail]amix=inputs=2:duration=first:normalize=0[out]")
        out = os.path.join(OUT, f"music_{name}_{i + 1}.ogg")
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", src, "-filter_complex", graph, "-map", "[out]",
            "-ar", "44100", "-c:a", "libvorbis", "-q:a", "3", out], check=True)
        print(f"  {os.path.basename(out)} ({loop:.1f} s)")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--assets", default=os.path.join(REPO, "..", "Assets"))
    parser.add_argument("--only", default="", help="comma-separated names to make (sounds or music)")
    args = parser.parse_args()
    only = set(filter(None, args.only.split(",")))
    os.makedirs(OUT, exist_ok=True)
    for name, recipes in SOUNDS.items():
        if only and name not in only:
            continue
        if isinstance(recipes, dict):
            make_sound(args.assets, recipes, os.path.join(OUT, f"{name}.ogg"))
        else:
            for i, recipe in enumerate(recipes):
                make_sound(args.assets, recipe, os.path.join(OUT, f"{name}_{i + 1}.ogg"))
        print(name)
    for name, folder in MUSIC.items():
        if only and name not in only:
            continue
        print(f"music {name}")
        make_music(args.assets, folder, name)


if __name__ == "__main__":
    sys.exit(main())
