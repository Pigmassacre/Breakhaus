#!/usr/bin/env python3
"""Lays the page's images out as itch.io would and shoots it, to judge them
together before uploading anything.

    python3 preview.py itch/theme.json [--out=DIR]

theme.json (paths relative to it) says what the theme editor will be set
to, and fills the page:

  {"title": "...", "byline": "A downloadable game for Windows and Linux",
   "short_description": "...", "cover": "out/cover.png",
   "banner": {"image": "out/banner.png", "align": "center"},
   "background": {"image": "out/background.jpg", "repeat": "no-repeat",
                  "align": "center", "fixed": true},
   "fonts": {"body": "Ubuntu Sans", "headers": "Ubuntu Sans", "size": "large"},
   "colors": {"bg": "#...", "bg2": "#...", "bg2_alpha": 1.0, "text": "#...",
              "link": "#...", "button": "#...", "button_text": "#...", "headers": "#..."},
   "screenshots": "sidebar" | "hidden",
   "embed": {"width": 960, "height": 540, "background": "out/embed.png"},
   "description": "description.html"}

Leave out what the page won't have (no banner: the title is shown; no
embed: a downloadable game; "repeat" is repeat, repeat-x, repeat-y or
no-repeat). The mock
page follows itch.io's own game page rules (game.css): a 960 px column
centred over the background with the banner across its top, a 367 px
screenshot sidebar, the column 600 px wide under 1000 px and edge to edge
under 600 px, and the page's buttons floating top right over the background.

Writes into DIR (default: build/preview beside theme.json) page.html and:
  page_1920x1080.png, page_1366x768.png, page_2560x1440.png  desktops
  page_1920x1080_scrolled.png                                 900 px down
  page_800x1100.png, page_390x844.png                         tablet, phone
  cover_listing.png   the cover in a browse grid (315x250, light and dark),
                      at 110x87, and fitted 2:1 as in shared links
"""
import html
import json
import os
import re
import sys

from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from shoot import shoot  # noqa: E402

SIZES = [(1920, 1080, 0), (1366, 768, 0), (2560, 1440, 0), (1920, 1080, 900), (800, 1100, 0), (390, 844, 0)]
TEXT_SIZES = {"small": 11, "medium": 13, "large": 16, "very_large": 19}


def rgba(hex_colour: str, alpha: float) -> str:
    h = hex_colour.lstrip("#")
    return "rgba(%d, %d, %d, %g)" % (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), alpha)


def page(theme: dict, base: str, out_dir: str) -> str:
    def url(path: str) -> str:
        return "file://" + os.path.abspath(os.path.join(base, path))

    c = theme["colors"]
    fonts = theme.get("fonts", {})
    bg = theme.get("background") or {}
    banner = theme.get("banner") or {}
    description = ""
    if theme.get("description"):
        description = open(os.path.join(base, theme["description"]), encoding="utf-8").read()
        # Its images, from beside theme.json.
        description = re.sub(r'src="(?!https?:|file:|data:)([^"]+)"', lambda m: 'src="%s"' % url(m.group(1)), description)
    sidebar = theme.get("screenshots", "sidebar") == "sidebar"
    font = fonts.get("body", "Lato")
    header_font = fonts.get("headers", font)
    background = ""
    if bg.get("image"):
        position = {"left": "0", "center": "50%", "right": "100%"}[bg.get("align", "center")]
        background = "background-image: url('%s'); background-repeat: %s; background-position: %s 0;%s" % (
            url(bg["image"]), bg.get("repeat", "repeat"), position,
            " background-attachment: fixed;" if bg.get("fixed") else "")
    if banner.get("image"):
        header = '<div class="header" style="text-align: %s"><img src="%s"></div>' % (banner.get("align", "center"), url(banner["image"]))
    else:
        header = '<div class="header"><h1>%s</h1></div>' % html.escape(theme.get("title", ""))
    embed = theme.get("embed")
    frame = ""
    if embed:
        frame = ('<div class="game_frame" style="width: %dpx; height: %dpx; %s"><span class="button run">Run game</span></div>'
                 % (embed.get("width", 960), embed.get("height", 540),
                    "background: url('%s') 50%% 50%% no-repeat;" % url(embed["background"]) if embed.get("background") else ""))
    shots = "".join('<div class="shot">screenshot %d</div>' % (i + 1) for i in range(4)) if sidebar else ""
    tools = "".join('<span class="tool">%s</span>' % t for t in
                    ["View all by you", "Follow you", "Add To Collection", "Related games"])
    return """<!doctype html>
<html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=%(font_query)s&display=block">
<style>
html, body { margin: 0; }
body { font-family: '%(font)s', Lato, sans-serif; }
.wrapper { background-color: %(bg)s; %(background)s min-height: 100vh; }
.inner_column { width: 960px; max-width: 960px; margin: 0 auto; position: relative; padding-bottom: 40px; overflow: hidden;
  background: %(bg2)s; color: %(text)s; font-size: %(text_size)dpx; line-height: 1.5; }
.inner_column a { color: %(link)s; }
.inner_column h1, .inner_column h2, .inner_column h3 { font-family: '%(header_font)s', '%(font)s', sans-serif; font-weight: 900; color: %(headers)s; }
.inner_column h2 { margin: 1.6em 0 0.8em; }
.header { overflow: hidden; font-size: 0; }
.header img { display: inline-block; max-width: 100%%; }
.header h1 { font-size: 32px; margin: 20px 20px 0; }
.header_buy_row p { margin: 20px 20px 0; }
.direct_download_row { margin: 10px 20px 20px; }
.button { display: inline-block; background: %(button)s; color: %(button_text)s; font-weight: bold; font-size: 14px;
  line-height: 33px; height: 35px; padding: 0 14px; border-radius: 3px; box-sizing: border-box; border: 1px solid rgba(0,0,0,0.1); }
.game_frame { max-width: 100%%; margin: 0 auto; background-color: rgba(127,127,127,0.25); display: flex;
  align-items: center; justify-content: center; }
.button.run { height: 46px; line-height: 44px; font-size: 18px; padding: 0 22px; }
.columns { display: flex; justify-content: center; margin-top: 20px; }
.left_col { flex: 1; width: 0; min-width: 0; }
.right_col { width: 367px; }
.formatted_description { margin: 0 20px 40px; }
.formatted_description img { max-width: 100%%; }
.shot { width: 347px; height: 195px; margin: 0 20px 10px 0; background: rgba(127,127,127,0.25); color: rgba(127,127,127,0.9);
  font: 14px sans-serif; display: flex; align-items: center; justify-content: center; }
.user_tools { position: fixed; top: 10px; right: 10px; display: flex; flex-direction: column; align-items: flex-end; gap: 6px; z-index: 5; }
.tool { background: rgba(0,0,0,0.55); color: #fff; font: bold 12px sans-serif; padding: 4px 9px; border-radius: 3px; }
@media (max-width: 1000px) {
  .wrapper { padding: 0 20px; }
  .inner_column { max-width: 600px; width: auto; padding-bottom: 0; }
  .game_frame { max-width: 100%%; margin: 0 auto; background-color: rgba(127,127,127,0.25); display: flex;
  align-items: center; justify-content: center; }
.button.run { height: 46px; line-height: 44px; font-size: 18px; padding: 0 22px; }
.columns { display: flex; flex-direction: column-reverse; margin: 0; }
  .left_col, .right_col { width: auto; }
  .right_col { white-space: nowrap; overflow: hidden; }
  .shot { display: inline-flex; height: 200px; width: 356px; margin: 0 0 20px; }
  .user_tools { display: none; }
}
@media (max-width: 600px) { .wrapper { padding: 0; } }
</style></head>
<body><div class="user_tools">%(tools)s</div>
<div class="wrapper"><div class="inner_column">
%(header)s
%(frame)s
<div class="header_buy_row"><p>%(byline)s</p><div class="direct_download_row"><span class="button">Download Now</span>
&nbsp; <span style="opacity: 0.6">Name your own price</span></div></div>
<div class="columns"><div class="left_col"><div class="formatted_description">%(description)s</div></div>
%(right)s</div>
</div></div>
<script>const s = new URLSearchParams(location.search).get('scroll'); if (s) window.scrollTo(0, +s);</script>
</body></html>
""" % {
        "font_query": "&family=".join(sorted({f.replace(" ", "+") + ":wght@400;700;900" if f != "Bungee" else f
                                               for f in (font, header_font)})),
        "font": font, "header_font": header_font, "bg": c["bg"], "background": background,
        "bg2": rgba(c["bg2"], c.get("bg2_alpha", 1.0)), "text": c["text"], "link": c["link"],
        "headers": c.get("headers", c["text"]), "button": c.get("button", c["link"]),
        "button_text": c.get("button_text", "#ffffff"),
        "text_size": TEXT_SIZES.get(fonts.get("size", "large"), 16), "header": header, "frame": frame, "tools": tools,
        "byline": html.escape(theme.get("byline", "A downloadable game")), "description": description,
        "right": '<div class="right_col">%s</div>' % shots if sidebar else "",
    }


def cover_listing(cover_path: str, title: str, tagline: str, out: str) -> None:
    """The cover where people meet it: in a grid of others on itch.io's light
    and dark browse pages, as a small thumbnail, and in a shared link."""
    cover = Image.open(cover_path).convert("RGB")
    card = cover.resize((315, 250), Image.LANCZOS)
    small = cover.resize((110, 87), Image.LANCZOS)
    # Shared links (twitter:image) get it fitted into 508x254, the sides
    # filled with a blur of it; og:image is the cover as uploaded.
    band = cover.resize((508, 254)).filter(ImageFilter.GaussianBlur(12)).point(lambda v: v * 0.6)
    fitted = cover.resize((round(cover.width * 254 / cover.height), 254), Image.LANCZOS)
    band.paste(fitted, ((508 - fitted.width) // 2, 0))
    sheet = Image.new("RGB", (3 * 335 + 20, 2 * 330 + 300), "#ffffff")
    draw = ImageDraw.Draw(sheet)
    for row, (back, fore, sub) in enumerate([("#ffffff", "#222222", "#888888"), ("#1d1d1d", "#eeeeee", "#999999")]):
        y = row * 330
        draw.rectangle((0, y, sheet.width, y + 330), fill=back)
        for col in range(3):
            x = 20 + col * 335
            if col == 1:
                sheet.paste(card, (x, y + 20))
                draw.text((x, y + 278), title, fill=fore)
                draw.text((x, y + 296), tagline[:56], fill=sub)
            else:
                # The covers it sits among: plain, so it is judged against
                # how loud a listing is, not against other art.
                draw.rectangle((x, y + 20, x + 315, y + 270), fill="#7a7a8c" if col == 0 else "#a8b0a0")
                draw.text((x, y + 278), "Another game", fill=fore)
    y = 2 * 330
    draw.rectangle((0, y, sheet.width, sheet.height), fill="#2b2d31")
    sheet.paste(small, (20, y + 20))
    draw.text((20, y + 115), "110x87", fill="#cccccc")
    sheet.paste(band, (160, y + 20))
    draw.text((160, y + 280), "shared link (508x254)", fill="#cccccc")
    sheet.save(out)


def main() -> None:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if len(args) != 1:
        sys.exit(__doc__)
    theme_path = os.path.abspath(args[0])
    base = os.path.dirname(theme_path)
    out_dir = os.path.join(base, "build", "preview")
    for flag in sys.argv[1:]:
        if flag.startswith("--out="):
            out_dir = os.path.abspath(flag.split("=", 1)[1])
    theme = json.load(open(theme_path, encoding="utf-8"))
    os.makedirs(out_dir, exist_ok=True)
    page_path = os.path.join(out_dir, "page.html")
    with open(page_path, "w", encoding="utf-8") as f:
        f.write(page(theme, base, out_dir))
    for w, h, scroll in SIZES:
        name = "page_%dx%d%s.png" % (w, h, "_scrolled" if scroll else "")
        target = page_path + ("?scroll=%d" % scroll if scroll else "")
        shoot(target, os.path.join(out_dir, name), w, h, scale=1)
        print(os.path.join(out_dir, name))
    if theme.get("cover"):
        out = os.path.join(out_dir, "cover_listing.png")
        cover_listing(os.path.join(base, theme["cover"]), theme.get("title", ""), theme.get("short_description", ""), out)
        print(out)


if __name__ == "__main__":
    main()
