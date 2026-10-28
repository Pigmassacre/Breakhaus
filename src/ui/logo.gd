class_name Logo
extends Control
## BREAKHAUS in blocks: each letter built of little blocks from a 4 by 5
## grid, raining in from the sky one after another (as the original game's
## blocks did), hopping in a ripple when the pointer passes over them or
## something is chosen, and every few seconds on their own.

const LETTERS := {
	"B": ["###.", "#..#", "###.", "#..#", "###."],
	"R": ["###.", "#..#", "###.", "#.#.", "#..#"],
	"E": ["####", "#...", "###.", "#...", "####"],
	"A": [".##.", "#..#", "####", "#..#", "#..#"],
	"K": ["#..#", "#.#.", "##..", "#.#.", "#..#"],
	"H": ["#..#", "#..#", "####", "#..#", "#..#"],
	"U": ["#..#", "#..#", "#..#", "#..#", ".##."],
	"S": [".###", "#...", ".##.", "...#", "###."],
}
const LINES := ["BREAK", "HAUS"]
const CELL := Vector2(26, 14)
const DEPTH := 7.0
const LINE_GAP := 30.0
const COLORS := [Color("ff4fa3"), Color("ff8a3d"), Color("ffd23d"), Color("46d9ff"), Color("8a5cff")]

## {"home": Vector2, "z", "vz", "delay", "power", "color", "flash"}
var _blocks: Array = []
var _clock := 0.0
var _next_wave := 3.0
var _landed := 0
## Set before it is added: the blocks are already in place, with a ripple through them instead of the rain.
var settled := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var widest := 0
	for line: String in LINES:
		widest = maxi(widest, line.length() * 5 - 1)
	custom_minimum_size = Vector2(widest * CELL.x, LINES.size() * 5 * CELL.y + LINE_GAP + DEPTH)
	var delay := 0.2
	var letter_index := 0
	for li in LINES.size():
		var line: String = LINES[li]
		var cols := line.length() * 5 - 1
		var x0 := (widest - cols) * 0.5 * CELL.x
		var y0 := li * (5 * CELL.y + LINE_GAP) + DEPTH
		for i in line.length():
			var rows: Array = LETTERS[line[i]]
			var color: Color = COLORS[letter_index % COLORS.size()]
			letter_index += 1
			for r in 5:
				for c in 4:
					if rows[r][c] != "#":
						continue
					_blocks.append({"home": Vector2(x0 + (i * 5 + c) * CELL.x, y0 + r * CELL.y), "z": 700.0 + randf() * 300.0,
						"vz": 0.0, "delay": delay + randf() * 0.1, "power": 0.0, "color": color.darkened(r * 0.04), "flash": 0.0,
						"raining": true})
			delay += 0.07
	if settled:
		for b: Dictionary in _blocks:
			b["z"] = 0.0
			b["delay"] = 0.0
			b["raining"] = false
		ripple(Vector2(custom_minimum_size.x * 0.5, custom_minimum_size.y), 0.6)


func _process(delta: float) -> void:
	_clock += delta
	for b: Dictionary in _blocks:
		if b["delay"] > 0.0:
			b["delay"] -= delta
			if b["delay"] <= 0.0 and not b["raining"]:
				b["vz"] = maxf(b["vz"], b["power"])
			continue
		b["vz"] -= (4200.0 if b["raining"] else 2200.0) * delta
		b["z"] += b["vz"] * delta
		if b["z"] <= 0.0:
			b["z"] = 0.0
			if b["raining"]:
				b["raining"] = false
				b["flash"] = 1.0
				b["vz"] = 120.0
				_landed += 1
				if _landed % 4 == 0:
					Audio.play("chip", -16.0, randf_range(0.9, 1.3))
			else:
				b["vz"] = 0.0
		b["flash"] = maxf(b["flash"] - delta * 4.0, 0.0)
	_next_wave -= delta
	if _next_wave <= 0.0:
		_next_wave = randf_range(3.0, 5.0)
		var b: Dictionary = _blocks[randi() % _blocks.size()]
		ripple(b["home"] + CELL * 0.5, 0.7)
	queue_redraw()


func _input(event: InputEvent) -> void:
	var at := Vector2.INF
	if event is InputEventMouseMotion:
		at = get_local_mouse_position()
	elif event is InputEventScreenDrag or event is InputEventScreenTouch:
		at = get_global_transform_with_canvas().affine_inverse() * event.position
	if at == Vector2.INF:
		return
	for b: Dictionary in _blocks:
		if b["z"] <= 1.0 and not b["raining"] and Rect2(b["home"], CELL).grow(4).has_point(at):
			b["vz"] = 260.0
			b["flash"] = 0.6


## A ripple out from `at`: the nearest hop first and highest.
func ripple(at: Vector2, strength := 1.0) -> void:
	for b: Dictionary in _blocks:
		if b["raining"]:
			continue
		var d: float = (b["home"] + CELL * 0.5).distance_to(at)
		b["power"] = maxf(320.0 * strength - d * 0.35, 60.0)
		b["delay"] = d / 900.0 + 0.001


func _draw() -> void:
	# Shadows first, then the blocks, back rows first so their fronts are hidden by the rows before them.
	for b: Dictionary in _blocks:
		var z: float = minf(b["z"], 60.0)
		var a := 0.35 * clampf(1.0 - b["z"] / 700.0, 0.15, 1.0)
		draw_rect(Rect2(b["home"] + Vector2(5 + z * 0.3, 5 + z * 0.45), CELL), Color(0, 0, 0, a))
	for b: Dictionary in _blocks:
		var p: Vector2 = b["home"] - Vector2(0, b["z"])
		var c: Color = (b["color"] as Color).lerp(Color.WHITE, b["flash"])
		draw_rect(Rect2(p.x, p.y + CELL.y - DEPTH, CELL.x, DEPTH), c.darkened(0.5))
		draw_rect(Rect2(p.x, p.y - DEPTH, CELL.x, CELL.y), c)
		draw_rect(Rect2(p.x, p.y - DEPTH, CELL.x, 3), c.lightened(0.4))
		draw_rect(Rect2(p.x + CELL.x - 3, p.y - DEPTH + 3, 3, CELL.y - 3), c.darkened(0.2))
