class_name Logo
extends Control
## BREAKHAUS in blocks: each letter drawn on a 4 by 5 grid, every square of
## it built of two by two little blocks, raining in from the sky one after
## another (as the original game's blocks did), hopping in a ripple when the
## pointer passes over them or something is chosen, and every few seconds on
## their own. It is as big as the screen's width allows, and builds itself
## again (already landed) when that changes.

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
## Blocks to a square of a letter, each way.
const SPLIT := 2
const COLORS := [Color("ff4fa3"), Color("ff8a3d"), Color("ffd23d"), Color("46d9ff"), Color("8a5cff")]

## {"home": Vector2, "z", "vz", "delay", "power", "color", "flash"}
var _blocks: Array = []
var _clock := 0.0
var _next_wave := 3.0
var _landed := 0
## One block, and how far its front reaches down below its top.
var _cell := Vector2(13, 12)
var _depth := 6.0
## Set before it is added: the blocks are already in place, with a ripple through them instead of the rain.
var settled := false
## Set before it is added: the size of a square of a letter, in place of fitting it to the screen (the key art's).
var square := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	get_viewport().size_changed.connect(func() -> void:
		if _fit() != _cell:
			settled = true
			_build())


## A block's size for the screen: a square of a letter as wide as the screen leaves room for, within reason.
func _fit() -> Vector2:
	if square > 0.0:
		return Vector2(square, roundf(square * 0.9)) / SPLIT
	var widest := 0
	for line: String in LINES:
		widest = maxi(widest, line.length() * 5 - 1)
	var square := clampf(floorf((get_viewport_rect().size.x - 64.0) / widest / SPLIT) * SPLIT, 16.0, 40.0)
	return Vector2(square, roundf(square * 0.9)) / SPLIT


func _build() -> void:
	_cell = _fit()
	_depth = roundf(_cell.y * 0.5)
	_blocks.clear()
	var square := _cell * SPLIT
	var line_gap := roundf(square.y * 1.2)
	var widest := 0
	for line: String in LINES:
		widest = maxi(widest, line.length() * 5 - 1)
	custom_minimum_size = Vector2(widest * square.x, LINES.size() * 5 * square.y + line_gap + _depth)
	var delay := 0.2
	var letter_index := 0
	for li in LINES.size():
		var line: String = LINES[li]
		var cols := line.length() * 5 - 1
		var x0 := (widest - cols) * 0.5 * square.x
		var y0 := li * (5 * square.y + line_gap) + _depth
		for i in line.length():
			var rows: Array = LETTERS[line[i]]
			var color: Color = COLORS[letter_index % COLORS.size()]
			letter_index += 1
			for r in 5:
				for c in 4:
					if rows[r][c] != "#":
						continue
					for sy in SPLIT:
						for sx in SPLIT:
							var at := Vector2((i * 5 + c) * SPLIT + sx, r * SPLIT + sy)
							_blocks.append({"home": Vector2(x0, y0) + at * _cell, "z": 700.0 + randf() * 300.0, "vz": 0.0,
								"delay": delay + randf() * 0.14, "power": 0.0, "color": color.darkened(at.y * 0.02), "flash": 0.0,
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
				if _landed % 12 == 0:
					Audio.play("chip", -16.0, randf_range(0.9, 1.3))
			else:
				b["vz"] = 0.0
		b["flash"] = maxf(b["flash"] - delta * 4.0, 0.0)
	_next_wave -= delta
	if _next_wave <= 0.0:
		_next_wave = randf_range(3.0, 5.0)
		var b: Dictionary = _blocks[randi() % _blocks.size()]
		ripple(b["home"] + _cell * 0.5, 0.7)
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
		if b["z"] <= 1.0 and not b["raining"] and Rect2(b["home"], _cell).grow(2).has_point(at):
			b["vz"] = 260.0
			b["flash"] = 0.6


## A ripple out from `at`: the nearest hop first and highest.
func ripple(at: Vector2, strength := 1.0) -> void:
	for b: Dictionary in _blocks:
		if b["raining"]:
			continue
		var d: float = (b["home"] + _cell * 0.5).distance_to(at)
		b["power"] = maxf(320.0 * strength - d * 0.35, 60.0)
		b["delay"] = d / 900.0 + 0.001


func _draw() -> void:
	# Shadows first, then the blocks, back rows first so their fronts are hidden by the rows before them.
	var drop := _cell.y * 0.4
	for b: Dictionary in _blocks:
		var z: float = minf(b["z"], 60.0)
		var a := 0.35 * clampf(1.0 - b["z"] / 700.0, 0.15, 1.0)
		draw_rect(Rect2(b["home"] + Vector2(drop + z * 0.3, drop + z * 0.45), _cell), Color(0, 0, 0, a))
	var shine := maxf(roundf(_cell.y * 0.2), 2.0)
	var shade := maxf(roundf(_cell.x * 0.18), 2.0)
	for b: Dictionary in _blocks:
		var p: Vector2 = b["home"] - Vector2(0, b["z"])
		var c: Color = (b["color"] as Color).lerp(Color.WHITE, b["flash"])
		draw_rect(Rect2(p.x, p.y + _cell.y - _depth, _cell.x, _depth), c.darkened(0.5))
		draw_rect(Rect2(p.x, p.y - _depth, _cell.x, _cell.y), c)
		draw_rect(Rect2(p.x, p.y - _depth, _cell.x, shine), c.lightened(0.4))
		draw_rect(Rect2(p.x + _cell.x - shade, p.y - _depth + shine, shade, _cell.y - shine), c.darkened(0.2))
