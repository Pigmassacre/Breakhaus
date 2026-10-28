extends Control
## The Locker: the paddle skins and ball trails, each on a tile with its
## look on it, locked until its challenge is done. The focused tile says
## what it is and what unlocks it; pressing an unlocked one puts it on.

const TILE := Vector2(150, 96)
const LOCK := [
	"..kkk..",
	".k...k.",
	".k...k.",
	"kkkkkkk",
	"kyyyyyk",
	"kyykyyk",
	"kyyyyyk",
	"kkkkkkk",
]

var _info: Label
var _tiles: Array[Button] = []
var _clock := 0.0


func _ready() -> void:
	UI.screen_root(self)
	add_child(Backdrop.new())
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	UI.centered(self, column)
	column.add_child(UI.label("LOCKER", 6, UI.ACCENT))
	var done := Game.challenges_done.size()
	column.add_child(UI.label("%d / %d CHALLENGES DONE" % [done, Challenges.LIST.size()], 2, UI.GOLD))
	column.add_child(_heading("PADDLES"))
	column.add_child(_grid("paddle", Cosmetics.PADDLES.keys()))
	column.add_child(_heading("TRAILS"))
	column.add_child(_grid("trail", Cosmetics.TRAILS.keys()))
	_info = UI.label("", 2, UI.INK)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.custom_minimum_size = Vector2(640, 96)
	_info.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	column.add_child(_info)
	var back := UI.button("BACK", go_back)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(back)
	back.focus_neighbor_top = back.get_path_to(_tiles[_tiles.size() - 1])
	for i in range(_tiles.size() - 4, _tiles.size()):
		_tiles[i].focus_neighbor_bottom = _tiles[i].get_path_to(back)
	for i in _tiles.size():
		UI.pop_in(_tiles[i], i * 0.02)
	_tiles[0].grab_focus.call_deferred()


func _process(delta: float) -> void:
	_clock += delta


func _heading(text: String) -> Label:
	var l := UI.label(text, 3, UI.DIM)
	l.custom_minimum_size = Vector2(0, 40)
	l.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	return l


func _grid(kind: String, looks: Array) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for look: String in looks:
		var tile := UI.button("", func() -> void: _wear(kind, look), TILE.x)
		tile.custom_minimum_size = TILE
		var art := Control.new()
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		art.size = TILE
		art.draw.connect(func() -> void: _draw_tile(art, kind, look))
		art.set_process(true)
		tile.add_child(art)
		var redraw := Timer.new()
		redraw.wait_time = 1.0 / 30.0
		redraw.autostart = true
		redraw.timeout.connect(art.queue_redraw)
		tile.add_child(redraw)
		tile.focus_entered.connect(func() -> void: _describe(kind, look))
		grid.add_child(tile)
		_tiles.append(tile)
	return grid


func _draw_tile(art: Control, kind: String, look: String) -> void:
	var c := TILE * 0.5
	if kind == "paddle":
		var skin: Dictionary = Cosmetics.PADDLES[look]
		Cosmetics.draw_paddle(art, Rect2(c.x - 52.0, c.y - 8.0, 104.0, 16.0), 8.0, skin["body"], skin.get("accent", UI.ACCENT), look, _clock, 4.0)
	else:
		# A ball curving up the tile with its trail behind it.
		var n := 9
		for i in n:
			var t := float(i + 1) / (n + 1)
			var p := Vector2(lerpf(18.0, TILE.x - 34.0, t), c.y + 24.0 - sin(t * PI * 0.9) * 34.0 + 10.0 * t)
			var s := roundf(t * 3.0) * 4.0
			var col := Cosmetics.trail_color(look, i, n, _clock, Color(1, 1, 1))
			art.draw_rect(Rect2((p - Vector2(s, s) * 0.5).snapped(Vector2(4, 4)), Vector2(s, s)), Color(col, t * 0.8))
		var b := Vector2(TILE.x - 30.0, c.y + 6.0).snapped(Vector2(4, 4))
		art.draw_rect(Rect2(b + Vector2(-8, -12), Vector2(16, 24)), Color("26262e"))
		art.draw_rect(Rect2(b + Vector2(-12, -8), Vector2(24, 16)), Color("26262e"))
		art.draw_rect(Rect2(b + Vector2(-8, -8), Vector2(16, 16)), Color.WHITE)
		art.draw_rect(Rect2(b + Vector2(-8, 4), Vector2(16, 4)), Color("c0c0c8"))
	if not Game.owns(kind, look):
		# Locked: dimmed, with a padlock in the corner.
		UI.draw_round(art, Rect2(Vector2(6, 6), TILE - Vector2(12, 20)), Color(0.08, 0.03, 0.1, 0.5), 12.0)
		var o := Vector2(TILE.x - 34.0, 10.0)
		for y in LOCK.size():
			for x in LOCK[y].length():
				var ch: String = LOCK[y][x]
				if ch != ".":
					art.draw_rect(Rect2(o + Vector2(x, y) * 3.0, Vector2(3, 3)), UI.GOLD if ch == "y" else Color("26262e"))
	elif _wearing(kind) == look:
		# What you have on: a gold tick in the corner.
		art.draw_circle(Vector2(TILE.x - 22.0, 20.0), 12.0, UI.GOLD, true, -1.0, true)
		art.draw_polyline(PackedVector2Array([Vector2(TILE.x - 28.0, 20.0), Vector2(TILE.x - 23.0, 25.0), Vector2(TILE.x - 15.0, 15.0)]), Color("1d0b24"), 3.0, true)


func _wearing(kind: String) -> String:
	return Game.paddle_skin if kind == "paddle" else Game.trail


func _describe(kind: String, look: String) -> void:
	var name: String = (Cosmetics.PADDLES if kind == "paddle" else Cosmetics.TRAILS)[look]["name"]
	var what := "%s %s" % [name.to_upper(), "PADDLE" if kind == "paddle" else "TRAIL"]
	if not Game.owns(kind, look):
		var c := Challenges.unlocking(kind, look)
		_info.text = "%s\nLocked. %s: %s" % [what, c["name"], c["goal"]]
		_info.add_theme_color_override("font_color", UI.DIM)
	elif _wearing(kind) == look:
		_info.text = "%s\nYou're using this one." % what
		_info.add_theme_color_override("font_color", UI.GOLD)
	else:
		_info.text = "%s\nPress to use it." % what
		_info.add_theme_color_override("font_color", UI.INK)


func _wear(kind: String, look: String) -> void:
	if not Game.owns(kind, look):
		Audio.play("pickup_bad", -6.0)
		return
	if kind == "paddle":
		Game.paddle_skin = look
	else:
		Game.trail = look
	Game.save()
	_describe(kind, look)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		go_back()


func go_back() -> void:
	Audio.play("back", -2.0)
	Game.goto("title")
