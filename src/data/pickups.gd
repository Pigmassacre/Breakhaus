class_name Pickups
## What a pickup can be: its icon (from the original game's sprites, or
## drawn for the new ones), its name and blurb for the HUD and How to play,
## and how rare it is: the common ones are mixed blessings, the uncommon
## ones help, and the rare ones (the strongest) hardly ever turn up.

enum Kind { MULTI, FIRE, FROST, ZAP, WIDE, NARROW, OVERDRIVE, ROCKET, SHIELD }
enum Rarity { COMMON, UNCOMMON, RARE }

## How often a pickup of each rarity turns up, against the others.
const RARITY_WEIGHT := {Rarity.COMMON: 12.0, Rarity.UNCOMMON: 5.0, Rarity.RARE: 1.5}
const RARITY_NAME := {Rarity.COMMON: "Common", Rarity.UNCOMMON: "Uncommon", Rarity.RARE: "Rare"}

const INFO := {
	Kind.MULTI: {"name": "Multiball", "sprite": "multiball", "color": Color("ff3dff"), "rarity": Rarity.UNCOMMON,
		"blurb": "Every ball splits in three."},
	Kind.FIRE: {"name": "Fireball", "sprite": "fire", "color": Color("ff7a1a"), "rarity": Rarity.RARE,
		"blurb": "Balls burn straight through blocks and set them alight."},
	Kind.FROST: {"name": "Deep Freeze", "sprite": "frost", "color": Color("3dc8ff"), "rarity": Rarity.RARE,
		"blurb": "Stops the wall coming down, and every block shatters in one hit."},
	Kind.ZAP: {"name": "Zap", "sprite": "electricity", "color": Color("fff23d"), "rarity": Rarity.UNCOMMON,
		"blurb": "Every hit arcs lightning to the blocks nearby."},
	Kind.WIDE: {"name": "Wide Paddle", "sprite": "enlarger", "color": Color("3dff6e"), "rarity": Rarity.COMMON,
		"blurb": "A bigger paddle for a while."},
	Kind.NARROW: {"name": "Shrink", "sprite": "reducer", "color": Color("ff5a3d"), "rarity": Rarity.COMMON, "bad": true,
		"blurb": "A smaller paddle for a while. Dodge it!"},
	Kind.OVERDRIVE: {"name": "Overdrive", "sprite": "doublespeed", "color": Color("3dffb1"), "rarity": Rarity.COMMON,
		"blurb": "Faster balls, double points."},
	Kind.ROCKET: {"name": "Rockets", "sprite": "rocket", "color": Color("ff4545"), "rarity": Rarity.UNCOMMON,
		"blurb": "The paddle fires rockets."},
	Kind.SHIELD: {"name": "Shield", "sprite": "", "color": Color("6ad8ff"), "rarity": Rarity.RARE,
		"blurb": "A barrier under the paddle: no misses."},
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
	var o := at - size * 0.5
	canvas.draw_rect(Rect2(o, Vector2(8, 7) * scale), color)
	canvas.draw_rect(Rect2(o + Vector2(1, 7) * scale, Vector2(6, 1) * scale), color)
	canvas.draw_rect(Rect2(o + Vector2(2, 8) * scale, Vector2(4, 1) * scale), color)


## Draws the pickup's icon into `canvas`, its footprint's centre at `at`, `scale` art pixels to one of its own.
static func draw_icon(canvas: CanvasItem, kind: Kind, at: Vector2, scale: float, modulate := Color.WHITE) -> void:
	var tex := texture(kind)
	var size := Vector2(8, 9) * scale
	if tex:
		canvas.draw_texture_rect(tex, Rect2(at - size * 0.5, size), false, modulate)
		return
	# The shield has no sprite in the original: a little blue crest, drawn in the same style.
	var px := scale
	var o := at - size * 0.5
	var dark := Color("08304a") * modulate
	var mid := Color("2a9fd6") * modulate
	var light := Color("9fe8ff") * modulate
	canvas.draw_rect(Rect2(o + Vector2(0, 0), Vector2(8, 7) * px), dark)
	canvas.draw_rect(Rect2(o + Vector2(1, 7) * px, Vector2(6, 1) * px), dark)
	canvas.draw_rect(Rect2(o + Vector2(2, 8) * px, Vector2(4, 1) * px), dark)
	canvas.draw_rect(Rect2(o + Vector2(1, 1) * px, Vector2(6, 5) * px), mid)
	canvas.draw_rect(Rect2(o + Vector2(2, 6) * px, Vector2(4, 1) * px), mid)
	canvas.draw_rect(Rect2(o + Vector2(2, 2) * px, Vector2(2, 3) * px), light)
	canvas.draw_rect(Rect2(o + Vector2(3, 7) * px, Vector2(2, 1) * px), mid)
