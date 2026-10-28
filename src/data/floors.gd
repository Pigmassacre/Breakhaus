class_name Floors
## The haus, floor by floor: how each one looks (its theme, for the board's
## floor shader, the rays behind and the blocks) and the rows of blocks it
## throws at you. A run starts on the top floor and breaks its way down;
## past the ground floor come the basements, darker and harder, for ever.

## The board's floor pattern (floor.gdshader's `pattern`).
enum Pattern { GLASS, TILES, PLANKS, MARBLE, GRID }

const THEMES := [
	{
		"name": "Penthouse", "pattern": Pattern.GLASS, "music": "pump",
		"floor": Color("b0208f"), "light": Color("f07ad8"), "ray_a": Color("2a0f33"), "ray_b": Color("3d1849"),
		"blocks": [Color("ff4fa3"), Color("ff8a3d"), Color("ffd23d"), Color("46d9ff"), Color("8a5cff")],
	},
	{
		"name": "Offices", "pattern": Pattern.GRID, "music": "zinger",
		"floor": Color("1d6f7a"), "light": Color("5fe0d2"), "ray_a": Color("0b2229"), "ray_b": Color("12343d"),
		"blocks": [Color("ffe066"), Color("f25f5c"), Color("70c1b3"), Color("ffffff"), Color("247ba0")],
	},
	{
		"name": "Disco", "pattern": Pattern.TILES, "music": "synth_rock",
		"floor": Color("3a1670"), "light": Color("ff4fd8"), "ray_a": Color("12062b"), "ray_b": Color("251049"),
		"blocks": [Color("ff3df2"), Color("3dfcff"), Color("fffc3d"), Color("ff6b3d"), Color("7dff3d")],
	},
	{
		"name": "Library", "pattern": Pattern.PLANKS, "music": "pump",
		"floor": Color("6b3b1f"), "light": Color("d9a066"), "ray_a": Color("24140b"), "ray_b": Color("362012"),
		"blocks": [Color("c0392b"), Color("27ae60"), Color("2e86de"), Color("f1c40f"), Color("e8e0c8")],
	},
	{
		"name": "Kitchen", "pattern": Pattern.TILES, "music": "zinger",
		"floor": Color("c9c2b8"), "light": Color("ffffff"), "ray_a": Color("2b1717"), "ray_b": Color("3f2121"),
		"blocks": [Color("e63946"), Color("f4a261"), Color("2a9d8f"), Color("e9c46a"), Color("457b9d")],
	},
	{
		"name": "Greenhouse", "pattern": Pattern.GLASS, "music": "synth_rock",
		"floor": Color("2f8f3a"), "light": Color("b8f27a"), "ray_a": Color("0d2410"), "ray_b": Color("16361a"),
		"blocks": [Color("ff6fa8"), Color("ffd166"), Color("f8f8f8"), Color("ef476f"), Color("9b5de5")],
	},
	{
		"name": "Arcade", "pattern": Pattern.GRID, "music": "pump",
		"floor": Color("141a5c"), "light": Color("3d6bff"), "ray_a": Color("070a24"), "ray_b": Color("0e1440"),
		"blocks": [Color("ff2e63"), Color("08f7fe"), Color("fe53bb"), Color("f5d300"), Color("09fbd3")],
	},
	{
		"name": "Lobby", "pattern": Pattern.MARBLE, "music": "zinger",
		"floor": Color("d8cfc0"), "light": Color("fff6e0"), "ray_a": Color("2b2416"), "ray_b": Color("403622"),
		"blocks": [Color("b8860b"), Color("8b1e3f"), Color("1f4e5f"), Color("e0b84c"), Color("5c3c92")],
	},
]

## The basements: the same look on every one, darker as they go.
const BASEMENT := {
	"name": "Basement", "pattern": Pattern.TILES, "music": "synth_rock",
	"floor": Color("4a4a52"), "light": Color("8f8f9c"), "ray_a": Color("140808"), "ray_b": Color("261010"),
	"blocks": [Color("d64545"), Color("e88a2e"), Color("9e9e9e"), Color("5f8f4f"), Color("c9c9c9")],
}


static func theme(level: int) -> Dictionary:
	if level < THEMES.size() and level < Balance.FLOORS:
		return THEMES[level]
	var t: Dictionary = BASEMENT.duplicate()
	var depth := level - Balance.FLOORS
	t["floor"] = (t["floor"] as Color).darkened(minf(depth * 0.06, 0.4))
	t["music"] = ["synth_rock", "pump", "zinger"][depth % 3]
	return t


## "8F" on the top floor, down to "1F", then "B1", "B2" ...
static func label(level: int) -> String:
	if level < Balance.FLOORS:
		return "%dF" % (Balance.FLOORS - level)
	return "B%d" % (level - Balance.FLOORS + 1)


static func long_label(level: int) -> String:
	if level < Balance.FLOORS:
		return "%s - %s" % [label(level), theme(level)["name"]]
	return "Basement %d" % (level - Balance.FLOORS + 1)


static func wave_time(level: int) -> float:
	return maxf(Balance.WAVE_TIME - level * Balance.WAVE_TIME_STEP, Balance.WAVE_TIME_MIN)


static func start_rows(level: int) -> int:
	return mini(Balance.START_ROWS + level / 2, Balance.START_ROWS_MAX)


static func queue_rows(level: int) -> int:
	return mini(Balance.QUEUE_ROWS + level, Balance.QUEUE_ROWS_MAX)


## A row of blocks for `floor`: COLS entries, each null (a gap) or
## {"kind": Block.Kind, "hp": int, "color": Color}. `n` is the row's number
## on the floor, for its stripe of colour.
static func make_row(rng: RandomNumberGenerator, level: int, n: int) -> Array:
	var t := theme(level)
	var palette: Array = t["blocks"]
	var color: Color = palette[(n / 2) % palette.size()]
	var row := []
	row.resize(Balance.COLS)
	var shape := _shape(rng, level)
	for x in Balance.COLS:
		if not shape[x]:
			continue
		row[x] = _block(rng, level, color)
	return row


static func _shape(rng: RandomNumberGenerator, level: int) -> Array:
	var cols := Balance.COLS
	var shape := []
	shape.resize(cols)
	shape.fill(true)
	var roll := rng.randf()
	if level == 0 and roll < 0.55:
		return shape
	if roll < 0.3:
		pass
	elif roll < 0.45:
		# Checkers, offset by the row.
		var odd := rng.randi() % 2
		for x in cols:
			shape[x] = (x + odd) % 2 == 0 or rng.randf() < 0.25
	elif roll < 0.6:
		# Pillars: pairs on, pairs off.
		var offset := rng.randi() % 4
		for x in cols:
			shape[x] = ((x + offset) / 2) % 2 == 0
	elif roll < 0.72:
		# A hole in the middle, or at the edges.
		var w := rng.randi_range(2, 4)
		var middle := rng.randf() < 0.5
		for x in cols:
			var edge := mini(x, cols - 1 - x)
			shape[x] = (edge >= w) if not middle else (edge < cols / 2 - w / 2)
	else:
		# Scattered gaps.
		for x in cols:
			shape[x] = rng.randf() > 0.18 + minf(level * 0.01, 0.1)
	var count := shape.count(true)
	if count < 4:
		shape.fill(true)
	return shape


static func _block(rng: RandomNumberGenerator, level: int, color: Color) -> Dictionary:
	var deep := level - Balance.FLOORS
	var r := rng.randf()
	var steel := 0.0 if level < 2 else minf(0.02 + (level - 2) * 0.012, 0.11)
	var tnt := 0.0 if level < 1 else 0.045
	var moss := 0.0 if level < 4 else minf(0.025 + (level - 4) * 0.01, 0.07)
	var prize := 0.05
	var gold := 0.02
	var tough := minf(0.06 + level * 0.045, 0.4)
	var acc := 0.0
	for pick: Array in [[Block.Kind.STEEL, steel], [Block.Kind.TNT, tnt], [Block.Kind.MOSS, moss],
			[Block.Kind.PRIZE, prize], [Block.Kind.GOLD, gold]]:
		acc += pick[1]
		if r < acc:
			var kind: int = pick[0]
			return {"kind": kind, "hp": Balance.STEEL_HP if kind == Block.Kind.STEEL else 1, "color": Block.kind_color(kind, color)}
	acc += tough
	if r < acc:
		var hp := 2
		if level >= 3 and rng.randf() < 0.3 + maxf(deep, 0) * 0.05:
			hp = 3
		return {"kind": Block.Kind.NORMAL, "hp": hp, "color": color}
	return {"kind": Block.Kind.NORMAL, "hp": 1, "color": color}
