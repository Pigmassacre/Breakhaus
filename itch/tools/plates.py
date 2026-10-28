#!/usr/bin/env python3
"""Renders the store page's pictures from the game itself (src/debug/key_art.gd):
the plates (the play screen without its HUD, each framed for its piece), the
logo, the haus and the page's words, all on a fixed 60 fps clock, so the same
arguments give the same picture.

    python3 itch/tools/plates.py              all of them
    python3 itch/tools/plates.py cover logo   just those

Writes itch/build/plates/<name>.png (itch/build is not kept in git: run this
again to get them back). Uses the stock editor in the Godot folder beside the
repository (or $GODOT).
"""
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "itch", "build", "plates")

# The floor the page is in: its glass, its blocks and its rays' colours (Floors.THEMES, from 0 at the top).
FLOOR = ["--floor=0"]

# Each one: the key art scene and its arguments. Board places are in board
# units (576 wide, 864 tall; the paddle at y 800), --board= is the board's
# middle on the picture and its zoom.
PLATES = {
    # The cover: an empty board, its bottom two thirds, the logo laid over
    # it where the wall would be (compose/cover.html), a smashed ball
    # flying up at it off the paddle.
    "cover": ["--scene=keyart", "--size=1260x1000", "--rays=630,260", "--board=630,296,1.75", "--empty",
              "--smash=250,780,14@5.6", "--at=5.8", "--seed=2"] + FLOOR,
    # The banner: rays round the logo on the left, the board on the right,
    # the wall come half way down, a rare pickup hanging under it and a
    # smashed ball on its way up.
    "banner": ["--scene=keyart", "--size=1920x640", "--rays=520,300", "--board=1450,318,1.25", "--wall=0.4",
               "--drop=fire@380,470", "--smash=200,700,22@5.55", "--at=5.75", "--seed=4"] + FLOOR,
    # Behind the game's frame (960x640 on the page) until it runs: the play
    # screen as it will be in that frame, without the HUD, the wall a third
    # of the way down and the ball in play (the autoplay's).
    "embed": ["--scene=keyart", "--size=1920x1280", "--board=960,612,1.27", "--wall=0.3",
              "--drop=multi@410,560", "--at=6.5", "--seed=5"] + FLOOR,
    # The side art: the rays out from behind the page's column, their hub up
    # where the banner is; in the right-hand band (about 700 px right of the
    # middle) pickups hanging in their columns of light, off a bare board.
    "background": ["--scene=keyart", "--size=3440x1440", "--rays=1720,380", "--board=2370,450,3", "--bare", "--empty",
                   "--drop=fire@262,400 multi@322,470 wide@266,540", "--at=4.2", "--seed=1"] + FLOOR,
    # For the left-hand band: the HUD's haus, the third floor down lit up.
    "haus": ["--scene=haus", "--scale=2.5", "--floor=2", "--at=1"],
    # The logo, landed, on transparent.
    "logo": ["--scene=logo", "--square=40", "--at=2.5"],
}

# The page's words in the UI's lettering (UI.label: Bungee, with its drop):
# each is its text, size in pixels and colour.
WORDS = {
    "tagline": ("BRING THE HAUS DOWN", 56, "ffd23d"),
    "heading_features": ("FEATURES", 72, "ffd23d"),
    "heading_controls": ("CONTROLS", 72, "ffd23d"),
    "heading_credits": ("CREDITS", 72, "ffd23d"),
    # The controls card's actions.
    "move": ("MOVE", 64, "fff4fb"),
    "smash": ("SMASH", 64, "fff4fb"),
    "quake": ("QUAKE", 64, "fff4fb"),
    "pause": ("PAUSE", 64, "fff4fb"),
}
for name, (text, size, colour) in WORDS.items():
    PLATES["words_" + name] = ["--scene=words", "--text=" + text, "--size=%d" % size, "--color=" + colour]


def godot() -> str:
    if os.environ.get("GODOT"):
        return os.environ["GODOT"]
    name = "Godot_v4.7.2-stable_win64.exe" if sys.platform == "win32" else "Godot_v4.7.2-stable_linux.x86_64"
    # Beside the repository, or beside the checkout this worktree is of.
    folder = ROOT
    while folder != os.path.dirname(folder):
        folder = os.path.dirname(folder)
        path = os.path.join(folder, "Godot", name)
        if os.path.exists(path):
            return path
    sys.exit("No Godot editor found beside the repository: set $GODOT")


def render(names: list) -> bool:
    """Renders the plates named, in parallel, saying which it made; returns whether all of them were."""
    os.makedirs(OUT, exist_ok=True)
    jobs = []
    for name in names:
        out = os.path.join(OUT, name + ".png")
        if os.path.exists(out):
            os.remove(out)
        command = [godot(), "--path", ROOT, "--fixed-fps", "60", "--audio-driver", "Dummy",
                   "--resolution", "480x270", "--", "--out=" + out] + PLATES[name]
        jobs.append((name, out, subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)))
    made = True
    for name, out, job in jobs:
        log, _ = job.communicate()
        if job.returncode != 0 or not os.path.exists(out):
            made = False
            print(f"{name}: failed\n{log}", file=sys.stderr)
        else:
            print(f"{name}: {os.path.relpath(out, ROOT)}")
    return made


def main() -> None:
    names = [a for a in sys.argv[1:] if not a.startswith("--")] or list(PLATES)
    unknown = [n for n in names if n not in PLATES]
    if unknown:
        sys.exit("No such plate: %s (there are: %s)" % (", ".join(unknown), ", ".join(PLATES)))
    sys.exit(0 if render(names) else 1)


if __name__ == "__main__":
    main()
