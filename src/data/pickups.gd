class_name Pickups
## What a pickup can be: its icon (from the original game's sprites, or
## drawn for the new ones), its name and blurb for the HUD and How to play,
## and how rare it is: the common ones are mixed blessings, the uncommon
## ones help, and the rare ones (the strongest) hardly ever turn up.

enum Kind { MULTI, FIRE, FROST, ZAP, WIDE, NARROW, OVERDRIVE, ROCKET, SHIELD, BARRAGE, LASER, MAGNET, BLAST, HASTE }
enum Rarity { COMMON, UNCOMMON, RARE }

## How often a pickup of each rarity turns up, against the others.
const RARITY_WEIGHT := {Rarity.COMMON: 12.0, Rarity.UNCOMMON: 5.0, Rarity.RARE: 1.5}
const RARITY_NAME := {Rarity.COMMON: "Common", Rarity.UNCOMMON: "Uncommon", Rarity.RARE: "Rare"}
## Each rarity's colour: the loot beam over a pickup, its tag and frame in How to play.
const RARITY_COLOR := {Rarity.COMMON: Color("c9c3d6"), Rarity.UNCOMMON: Color("3dffc8"), Rarity.RARE: Color("ffd23d")}

const INFO := {
	Kind.MULTI: {"name": "Multiball", "sprite": "multiball", "color": Color("ff3dff"), "rarity": Rarity.UNCOMMON,
		"blurb": "Splits every ball into three."},
	Kind.FIRE: {"name": "Fireball", "sprite": "fire", "color": Color("ff7a1a"), "rarity": Rarity.RARE,
		"blurb": "Burns straight through blocks."},
	Kind.FROST: {"name": "Deep Freeze", "sprite": "frost", "color": Color("3dc8ff"), "rarity": Rarity.RARE,
		"blurb": "Freezes the wall. Blocks break in one hit."},
	Kind.ZAP: {"name": "Zap", "sprite": "electricity", "color": Color("fff23d"), "rarity": Rarity.UNCOMMON,
		"blurb": "Hits chain lightning to nearby blocks."},
	Kind.WIDE: {"name": "Wide Paddle", "sprite": "enlarger", "color": Color("3dff6e"), "rarity": Rarity.COMMON,
		"blurb": "Bigger paddle."},
	Kind.NARROW: {"name": "Shrink", "sprite": "reducer", "color": Color("ff5a3d"), "rarity": Rarity.COMMON, "bad": true,
		"blurb": "Tiny paddle. Avoid it!"},
	Kind.OVERDRIVE: {"name": "Overdrive", "sprite": "doublespeed", "color": Color("3dffb1"), "rarity": Rarity.COMMON,
		"blurb": "Faster ball, double points."},
	Kind.ROCKET: {"name": "Rockets", "sprite": "rocket", "color": Color("ff4545"), "rarity": Rarity.UNCOMMON,
		"blurb": "Your paddle shoots rockets."},
	Kind.SHIELD: {"name": "Shield", "sprite": "", "color": Color("6ad8ff"), "rarity": Rarity.RARE,
		"blurb": "A safety net. No misses."},
	Kind.BARRAGE: {"name": "Rocket Barrage", "sprite": "", "color": Color("ff9a3d"), "rarity": Rarity.UNCOMMON,
		"blurb": "Fires 14 rockets across the wall."},
	Kind.LASER: {"name": "Laser", "sprite": "", "color": Color("ff4f6a"), "rarity": Rarity.RARE,
		"blurb": "Burns through anything. Even steel."},
	Kind.MAGNET: {"name": "Magnet", "sprite": "", "color": Color("d0d0e0"), "rarity": Rarity.UNCOMMON,
		"blurb": "Sticky paddle. Smash to let go."},
	Kind.BLAST: {"name": "Blast Ball", "sprite": "", "color": Color("ffb03b"), "rarity": Rarity.UNCOMMON,
		"blurb": "Every hit explodes."},
	Kind.HASTE: {"name": "Hurry Up", "sprite": "", "color": Color("ff3d6e"), "rarity": Rarity.UNCOMMON, "bad": true,
		"blurb": "The wall drops twice as fast. Avoid it!"},
}

## The pickups with no sprite in the original, drawn in its style: rows of art pixels, each letter a
## colour from the icon's palette ("." is see-through), 8 by 9 like the sprites.
const ICONS := {
	Kind.SHIELD: {"palette": {"d": Color("08304a"), "m": Color("2a9fd6"), "l": Color("9fe8ff")}, "rows": [
		"dddddddd",
		"dmmmmmmd",
		"dmllmmmd",
		"dmllmmmd",
		"dmllmmmd",
		"dmmmmmmd",
		"ddmmmmdd",
		".ddmmdd.",
		"..dddd..",
	]},
	Kind.BARRAGE: {"palette": {"k": Color("2b1010"), "r": Color("ff4545"), "w": Color("e8e8f0"), "y": Color("ffd23d")}, "rows": [
		"...rr...",
		"rr.ww...",
		"ww.ww.rr",
		"ww.ww.ww",
		"ww.kk.ww",
		"kk.yy.ww",
		"yy....kk",
		"......yy",
		"........",
	]},
	Kind.LASER: {"palette": {"k": Color("1a1420"), "r": Color("ff4f6a"), "w": Color("fff0f4"), "g": Color("9a9ab0"), "d": Color("55556a")}, "rows": [
		"...ww...",
		"..rwwr..",
		"..rwwr..",
		"..rwwr..",
		".krwwrk.",
		"kggggggk",
		"kgdggdgk",
		"kkkkkkkk",
		"........",
	]},
	Kind.MAGNET: {"palette": {"k": Color("1a1420"), "r": Color("ff3d4f"), "w": Color("e8e8f0")}, "rows": [
		"kkkkkkkk",
		"krrrrrrk",
		"krkkkkrk",
		"krk..krk",
		"krk..krk",
		"kwk..kwk",
		"kwk..kwk",
		"kkk..kkk",
		"........",
	]},
	Kind.BLAST: {"palette": {"k": Color("0d0d14"), "b": Color("3a3a50"), "w": Color("b0b0c8"), "y": Color("ffd23d"), "o": Color("ff7a1a")}, "rows": [
		".....y.o",
		"....k.y.",
		"..kkkk..",
		".kbbbbk.",
		"kbwbbbbk",
		"kbwbbbbk",
		"kbbbbbbk",
		".kbbbbk.",
		"..kkkk..",
	]},
	Kind.HASTE: {"palette": {"k": Color("2b1018"), "w": Color("fff4fb"), "r": Color("ff3d6e")}, "rows": [
		"..kkkk..",
		".kwwwwk.",
		"kwwrwwwk",
		"kwwrwwwk",
		"kwwrrrwk",
		"kwwwwwwk",
		".kwwwwk.",
		"..kkkk..",
		"........",
	]},
}

static var _textures := {}


static func info(kind: Kind) -> Dictionary:
	return INFO[kind]


static func texture(kind: Kind) -> Texture2D:
	var sprite: String = INFO[kind]["sprite"]
	if sprite == "":
		return null
	if not _textures.has(sprite):
		var tex := load("res://assets/sprites/%s.png" % sprite) as Texture2D
		# The frost sprite is three frames stacked; the first will do.
		if sprite == "frost":
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(0, 0, 8, 9)
			tex = atlas
		_textures[sprite] = tex
	return _textures[sprite]


static func rarity(kind: Kind) -> Rarity:
	return INFO[kind]["rarity"]


static func pick(rng: RandomNumberGenerator) -> Kind:
	var total := 0.0
	for kind: Kind in INFO:
		total += RARITY_WEIGHT[rarity(kind)]
	var roll := rng.randf() * total
	for kind: Kind in INFO:
		roll -= RARITY_WEIGHT[rarity(kind)]
		if roll < 0.0:
			return kind
	return Kind.WIDE


## The icon's shadow: its own outline filled with `color` (one flat layer, so it doesn't darken where
## the icon's parts overlap).
static func draw_shadow(canvas: CanvasItem, kind: Kind, at: Vector2, scale: float, color: Color) -> void:
	var tex := texture(kind)
	var size := Vector2(8, 9) * scale
	if tex:
		canvas.draw_texture_rect(tex, Rect2(at - size * 0.5, size), false, Color(0, 0, 0, color.a))
		return
	_draw_rows(canvas, kind, at - size * 0.5, scale, color, true)


## Draws the pickup's icon into `canvas`, its footprint's centre at `at`, `scale` art pixels to one of its own.
static func draw_icon(canvas: CanvasItem, kind: Kind, at: Vector2, scale: float, modulate := Color.WHITE) -> void:
	var tex := texture(kind)
	var size := Vector2(8, 9) * scale
	if tex:
		canvas.draw_texture_rect(tex, Rect2(at - size * 0.5, size), false, modulate)
		return
	_draw_rows(canvas, kind, at - size * 0.5, scale, modulate, false)


## One of ICONS, a pixel at a time from `o`; or, `flat`, every pixel of it in `color` (its shadow).
static func _draw_rows(canvas: CanvasItem, kind: Kind, o: Vector2, scale: float, color: Color, flat: bool) -> void:
	var icon: Dictionary = ICONS[kind]
	var palette: Dictionary = icon["palette"]
	var rows: Array = icon["rows"]
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			if ch == ".":
				continue
			canvas.draw_rect(Rect2(o + Vector2(x, y) * scale, Vector2(scale, scale)), color if flat else palette[ch] * color)
