class_name Cosmetics
## The looks you unlock with challenges: paddle skins and ball trails, and
## how to draw them. "classic" of each is there from the start.

const PADDLES := {
	"classic": {"name": "Classic", "body": Color("e8e8f0")},
	"hazard": {"name": "Hazard", "body": Color("ffd23d"), "accent": Color("26262e"), "pattern": "stripes"},
	"mint": {"name": "Mint", "body": Color("bff8e0"), "accent": Color("3dffb1")},
	"chrome": {"name": "Chrome", "body": Color("c8d4e4"), "accent": Color("7a8aa0"), "pattern": "shine"},
	"neon": {"name": "Neon", "body": Color("1c1c2a"), "accent": Color("08f7fe"), "pattern": "glow"},
	"gold": {"name": "Gold", "body": Color("ffc933"), "accent": Color("b8860b"), "pattern": "shine"},
	"obsidian": {"name": "Obsidian", "body": Color("2a2030"), "accent": Color("ff3d3d"), "pattern": "glow"},
	"royal": {"name": "Royal", "body": Color("8a5cff"), "accent": Color("ffd23d"), "pattern": "stripes"},
}

const TRAILS := {
	"classic": {"name": "Classic"},
	"gold": {"name": "Gold", "colors": [Color("ffd23d"), Color("ff9a3d")]},
	"rainbow": {"name": "Rainbow", "rainbow": true},
	"mint": {"name": "Mint", "colors": [Color("3dffb1"), Color("46d9ff")]},
	"plasma": {"name": "Plasma", "colors": [Color("ff6af0"), Color("46d9ff")]},
	"fire": {"name": "Fire", "colors": [Color("ffe066"), Color("ff3d1a")]},
	"lightning": {"name": "Lightning", "colors": [Color("ffffff"), Color("fff23d")], "flicker": true},
	"sunset": {"name": "Sunset", "colors": [Color("ffb03b"), Color("ff3d8a")]},
}


## A paddle `rect` (its top face) with a front `depth` deep under it, in `px`-sized art pixels:
## the outline, the front, the top, the ends in `accent`, the shine, and the skin's pattern.
static func draw_paddle(canvas: CanvasItem, rect: Rect2, depth: float, body: Color, accent: Color, skin: String, clock: float, px: float) -> void:
	var pattern: String = PADDLES.get(skin, PADDLES["classic"]).get("pattern", "")
	var x := rect.position.x
	var y := rect.position.y
	var w := rect.size.x
	var h := rect.size.y
	if pattern == "glow":
		var glow := Color(accent, 0.25 + 0.15 * sin(clock * 6.0))
		canvas.draw_rect(Rect2(x - px * 2.0, y - px * 2.0, w + px * 4.0, h + depth + px * 4.0), glow)
	canvas.draw_rect(Rect2(x - px, y - px, w + px * 2.0, h + depth + px * 2.0), Color("26262e"))
	canvas.draw_rect(Rect2(x, y + h, w, depth), body.darkened(0.45))
	canvas.draw_rect(Rect2(x, y, w, h), body)
	if pattern == "stripes":
		# Diagonal stripes across the top, a pixel at a time.
		var stripe := Color(accent, 0.85)
		var rows := int(h / px)
		var step := px * 4.0
		var sx := px * 3.0
		while sx < w - px * 3.0:
			for r in rows:
				var cx := sx + r * px
				if cx + px * 2.0 <= w - px * 3.0:
					canvas.draw_rect(Rect2(x + cx, y + r * px, px * 2.0, px), stripe)
			sx += step
	canvas.draw_rect(Rect2(x, y, px * 3.0, h + depth), accent)
	canvas.draw_rect(Rect2(x + w - px * 3.0, y, px * 3.0, h + depth), accent)
	canvas.draw_rect(Rect2(x, y + h, px * 3.0, depth), accent.darkened(0.4))
	canvas.draw_rect(Rect2(x + w - px * 3.0, y + h, px * 3.0, depth), accent.darkened(0.4))
	canvas.draw_rect(Rect2(x + px * 3.0, y + px, w - px * 6.0, px), Color(1, 1, 1, 0.8 if pattern != "glow" else 0.35))
	if pattern == "shine":
		# A glint running along it every couple of seconds.
		var run := fmod(clock * 0.7, 1.6) * w
		var gx := snappedf(run, px)
		if gx < w - px * 5.0:
			canvas.draw_rect(Rect2(x + px * 3.0 + gx, y, px, h), Color(1, 1, 1, 0.7))
			canvas.draw_rect(Rect2(x + px * 4.0 + gx, y, px, h), Color(1, 1, 1, 0.35))


## The colour of trail square `i` of `n` (the newest last) for trail `id`, or `fallback` for the classic one.
static func trail_color(id: String, i: int, n: int, clock: float, fallback: Color) -> Color:
	var trail: Dictionary = TRAILS.get(id, TRAILS["classic"])
	var t := float(i + 1) / (n + 1)
	if trail.get("rainbow", false):
		return Color.from_hsv(fmod(clock * 0.8 + (n - i) * 0.09, 1.0), 0.7, 1.0)
	if not trail.has("colors"):
		return fallback
	var colors: Array = trail["colors"]
	var c: Color = (colors[1] as Color).lerp(colors[0], t)
	if trail.get("flicker", false) and fmod(clock * 30.0 + i, 2.0) < 1.0:
		c = c.lightened(0.5)
	return c
