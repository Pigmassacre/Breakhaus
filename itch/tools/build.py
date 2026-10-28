#!/usr/bin/env python3
"""Builds the itch.io page's images into itch/out/ from the pages in
itch/compose/ (each laid out at the size itch.io shows it) and the pictures
the game draws (tools/plates.py, run first).

    python3 itch/tools/build.py               every piece
    python3 itch/tools/build.py banner cover  just those

Shoots each page with headless Chrome (tools/shoot.py) at twice its size
(the background at its own: itch.io never scales it), and writes what
itch.io takes: PNG, or JPEG for the big background, each checked against
itch.io's limits.
"""
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from shoot import shoot  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
COMPOSE = os.path.join(ROOT, "itch", "compose")
BUILD = os.path.join(ROOT, "itch", "build")
OUT = os.path.join(ROOT, "itch", "out")

# Each piece: its page (with ?text= for a heading), its size in CSS pixels
# as itch.io shows it, how much bigger it is shot, the file it becomes, the
# size that file is (None: as shot), and whether it keeps its transparency.
PIECES = {
    # Across the top of the column, 960 wide: shot at 2x for sharp screens.
    "banner": ("banner.html", (960, 320), 2, "banner.png", None, False),
    # In every listing at 315x250 (and 630x500 on sharp screens).
    "cover": ("cover.html", (630, 500), 2, "cover.png", (630, 500), False),
    # Behind the game's frame until it runs, at its own size like the background: shot at 2x and halved,
    # which keeps the logo's blocks whole.
    "embed": ("embed.html", (960, 640), 2, "embed.png", (960, 640), False),
    # Behind the page, at its own size.
    "background": ("background.html", (3440, 1440), 1, "background.jpg", None, False),
    # In the page's text, which is 920 wide on a page played in the browser (no screenshot sidebar).
    "controls": ("controls.html", (920, 372), 2, "controls.png", None, True),
}
# Headings for the page's text, each its own image (heading.html?text=...).
HEADINGS = ["Features", "Controls", "Credits"]
for heading in HEADINGS:
    PIECES["heading_" + heading.lower()] = (
        "heading.html?text=" + heading, (920, 56), 2, "heading_%s.png" % heading.lower(), None, True)

# itch.io takes images up to 3 MB.
LIMIT = 3 * 1024 * 1024


def build(name: str) -> None:
    page, (w, h), scale, out_name, final, transparent = PIECES[name]
    shot = os.path.join(BUILD, "shots", name + ".png")
    shoot(os.path.join(COMPOSE, page), shot, w, h, scale, transparent)
    image = Image.open(shot).convert("RGBA" if transparent else "RGB")
    if final and image.size != final:
        image = image.resize(final, Image.LANCZOS)
    out = os.path.join(OUT, out_name)
    if out.endswith(".jpg"):
        image.save(out, quality=90, optimize=True, progressive=True)
    else:
        image.save(out, optimize=True)
    size = os.path.getsize(out)
    print("%-18s %s  %dx%d  %.2f MB%s" % (name, os.path.relpath(out, ROOT), image.width, image.height,
                                          size / 1048576, "  TOO BIG for itch.io" if size > LIMIT else ""))


def main() -> None:
    names = sys.argv[1:] or list(PIECES)
    unknown = [n for n in names if n not in PIECES]
    if unknown:
        sys.exit("No such piece: %s (there are: %s)" % (", ".join(unknown), ", ".join(PIECES)))
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(BUILD, exist_ok=True)
    for name in names:
        build(name)


if __name__ == "__main__":
    main()
