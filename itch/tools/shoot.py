#!/usr/bin/env python3
"""Shoots an HTML page to a PNG at an exact size with headless Chrome.

    python3 shoot.py page.html out.png 960x320 [--scale=2] [--transparent]

The page is laid out at WIDTHxHEIGHT CSS pixels and shot at --scale times
that (960x320 at 2 gives a 1920x640 PNG). --transparent keeps the page's
own transparency (give body no background). Chrome runs with a throwaway
profile, so a Chrome already open is left alone. Finds Chrome or Chromium
on the PATH, in the usual places, or at $CHROME.
"""
import os
import shutil
import subprocess
import sys
import tempfile

CANDIDATES = [
    "google-chrome", "google-chrome-stable", "chromium", "chromium-browser", "chrome",
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
]


def chrome() -> str:
    if os.environ.get("CHROME"):
        return os.environ["CHROME"]
    for candidate in CANDIDATES:
        found = shutil.which(candidate) or (candidate if os.path.isfile(candidate) else None)
        if found:
            return found
    sys.exit("No Chrome or Chromium found: set $CHROME")


def shoot(html: str, out: str, width: int, height: int, scale: float = 2, transparent: bool = False) -> None:
    out = os.path.abspath(out)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    if os.path.exists(out):
        os.remove(out)
    with tempfile.TemporaryDirectory() as profile:
        command = [
            chrome(), "--headless=new", "--no-first-run", "--no-default-browser-check",
            "--user-data-dir=" + profile, "--hide-scrollbars", "--allow-file-access-from-files",
            "--force-device-scale-factor=%g" % scale, "--window-size=%d,%d" % (width, height),
            # Time for fonts and images to settle before the shot.
            "--virtual-time-budget=4000", "--screenshot=" + out,
        ]
        if transparent:
            command.append("--default-background-color=00000000")
        command.append("file://" + os.path.abspath(html))
        subprocess.run(command, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=120)
    if not os.path.exists(out):
        sys.exit(f"Chrome made no screenshot of {html}")


def main() -> None:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    flags = [a for a in sys.argv[1:] if a.startswith("--")]
    if len(args) != 3:
        sys.exit(__doc__)
    width, height = (int(n) for n in args[2].lower().split("x"))
    scale = 2.0
    for flag in flags:
        if flag.startswith("--scale="):
            scale = float(flag.split("=", 1)[1])
    shoot(args[0], args[1], width, height, scale, "--transparent" in flags)
    print(args[1])


if __name__ == "__main__":
    main()
