class_name Hud
extends CanvasLayer
## What's going on, around the board: the floor and how much of it is left
## (top left), the score (top right), the combo (between them), the wave
## bar along the top of the board, the pickups running and the quake meter
## under it. Points fly off broken blocks to the score (the original
## game's), and the big words (SMASH!, MULTIBALL!) punch in over the board.
## On a touch screen there are pause and quake buttons too.

signal pause_pressed
signal quake_pressed

var board: Board
## The board's rect on screen, set by the game as the screen changes shape, and how much it is zoomed.
var board_rect := Rect2()
var zoom := 1.0
## Laid out for a wide screen: the HUD beside the board, not over it.
var wide := false
## Where the icons of the pickups running go.
var _effects_at := Vector2.ZERO

var _floor_label: Label
var _floor_name: Label
var _rows_label: Label
var _score_label: Label
var _best_label: Label
var _combo_label: Label
var _combo_mult: Label
var _message: Label
var _prompt: Label
var _help: Label
var _quake_label: Label
var _bars: Control
var _popups: Control
var _pause_button: Button
var _quake_button: Button
var _tower: Tower
var _shown_score := 0.0
var _combo_shown := 0
var _message_tween: Tween


func _init() -> void:
	layer = 10


func _ready() -> void:
	var root := Control.new()
	UI.screen_root(root)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_bars = Control.new()
	_bars.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bars.draw.connect(_draw_bars)
	root.add_child(_bars)
	_floor_label = UI.label("8F", 6, UI.INK, HORIZONTAL_ALIGNMENT_LEFT)
	_floor_name = UI.label("", 2, UI.DIM, HORIZONTAL_ALIGNMENT_LEFT)
	_rows_label = UI.label("", 2, UI.DIM, HORIZONTAL_ALIGNMENT_LEFT)
	_score_label = UI.label("0", 5, UI.INK, HORIZONTAL_ALIGNMENT_RIGHT)
	_best_label = UI.label("", 2, UI.DIM, HORIZONTAL_ALIGNMENT_RIGHT)
	_combo_label = UI.label("", 4, UI.GOLD)
	_combo_mult = UI.label("", 2, UI.GOLD)
	_quake_label = UI.label("", 2, UI.DIM)
	for l: Label in [_floor_label, _floor_name, _rows_label, _score_label, _best_label, _combo_label, _combo_mult, _quake_label]:
		root.add_child(l)
	_tower = Tower.new()
	root.add_child(_tower)
	_popups = Control.new()
	_popups.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_popups)
	_message = UI.label("", 7, UI.INK)
	_message.modulate.a = 0.0
	root.add_child(_message)
	_prompt = UI.label("", 3, UI.INK)
	root.add_child(_prompt)
	_help = UI.label("", 2, UI.DIM)
	root.add_child(_help)
	_pause_button = _touch_button("II", func() -> void: pause_pressed.emit())
	_quake_button = _touch_button("QUAKE", func() -> void: quake_pressed.emit())
	root.add_child(_pause_button)
	root.add_child(_quake_button)
	Inputs.device_changed.connect(func(_d: Inputs.Device) -> void: _update_prompt())
	_update_prompt()


func _touch_button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", UI.FONT_PX * 3)
	b.pressed.connect(on_press)
	return b


func set_board(b: Board) -> void:
	board = b
	board.scored.connect(_on_scored)
	board.combo_changed.connect(_on_combo)
	board.message.connect(show_message)
	board.launched.connect(_update_prompt)
	_shown_score = board.score


## Puts everything in its place round the board's rect on screen (the board drawn `zoom` times its size).
## On a wide screen the floor and the haus go to the left of the board and the score to its right;
## on a tall one they go over it.
func layout(rect: Rect2, zoom: float) -> void:
	board_rect = rect
	self.zoom = zoom
	var view := get_viewport().get_visible_rect().size
	var top := rect.position.y - (Balance.WALL + Balance.BLOCK_DEPTH) * zoom
	var x0 := rect.position.x - Balance.WALL * zoom
	var x1 := rect.end.x + Balance.WALL * zoom
	var width := x1 - x0
	wide = view.x > view.y * 1.05
	var align_left := HORIZONTAL_ALIGNMENT_LEFT
	var align_right := HORIZONTAL_ALIGNMENT_RIGHT
	if wide:
		var column := minf(x0 - 60.0, 520.0)
		_place(_floor_label, Rect2(x0 - 40 - column, top + 10, column, 60))
		_place(_floor_name, Rect2(x0 - 40 - column, top + 76, column, 24))
		_place(_rows_label, Rect2(x0 - 40 - column, top + 104, column, 24))
		_place(_score_label, Rect2(x1 + 40, top + 14, column, 50))
		_place(_best_label, Rect2(x1 + 40, top + 76, column, 24))
		_effects_at = Vector2(x1 + 40, top + 120)
		for l: Label in [_floor_label, _floor_name, _rows_label]:
			l.horizontal_alignment = align_right
		for l: Label in [_score_label, _best_label]:
			l.horizontal_alignment = align_left
		_tower.visible = column >= Tower.WIDTH + 140.0
		_place(_tower, Rect2(x0 - 40 - column, top + 150, column, rect.end.y - top - 150))
	else:
		_place(_floor_label, Rect2(x0, top - 150, width * 0.4, 60))
		_place(_floor_name, Rect2(x0, top - 88, width * 0.6, 24))
		_place(_rows_label, Rect2(x0, top - 62, width * 0.6, 24))
		_place(_score_label, Rect2(x0 + width * 0.35, top - 146, width * 0.65, 50))
		_place(_best_label, Rect2(x0 + width * 0.4, top - 88, width * 0.6, 24))
		_effects_at = Vector2(rect.position.x, top - Balance.PX * 18.0)
		for l: Label in [_floor_label, _floor_name, _rows_label]:
			l.horizontal_alignment = align_left
		for l: Label in [_score_label, _best_label]:
			l.horizontal_alignment = align_right
		_tower.visible = false
	var at := func(board_y: float) -> float: return rect.position.y + board_y * zoom
	_place(_combo_label, Rect2(rect.get_center().x - 120, at.call(30.0), 240, 40))
	_place(_combo_mult, Rect2(rect.get_center().x - 120, at.call(72.0), 240, 24))
	_place(_message, Rect2(rect.position.x - 60, at.call(Balance.BOARD_H * 0.36), rect.size.x + 120, 70))
	_place(_prompt, Rect2(rect.position.x - 60, at.call(Balance.PADDLE_Y - 130), rect.size.x + 120, 40))
	_place(_help, Rect2(rect.position.x - 60, at.call(Balance.PADDLE_Y - 330), rect.size.x + 120, 130))
	var quake_y := rect.end.y + (Balance.BLOCK_DEPTH + Balance.PX * 6.0) * zoom
	_place(_quake_label, Rect2(x0, quake_y + Balance.PX * 6.0 * zoom, width, 24))
	_place(_pause_button, Rect2(view.x - 100, 16, 84, 64) if wide or top < 260 else Rect2(x1 - 84, top - 210, 84, 64))
	_place(_quake_button, Rect2(x1 - 210, quake_y + 70, 210, 72))
	_popups.size = view
	_bars.queue_redraw()


func _place(c: Control, r: Rect2) -> void:
	c.position = r.position
	c.size = r.size
	c.pivot_offset = r.size * 0.5


func _process(delta: float) -> void:
	if board == null:
		return
	# The score counts up to what it is, quicker the further behind it is.
	_shown_score = move_toward(_shown_score, board.score, maxf(absf(board.score - _shown_score) * 6.0, 60.0) * delta)
	_score_label.text = _format(int(_shown_score))
	var best := maxi(Game.best_score(), board.score)
	_best_label.text = ("BEST " + _format(best)) if best > 0 else ""
	_floor_label.text = Floors.label(board.level)
	_tower.level = board.level
	_floor_name.text = String(board.theme.get("name", "")).to_upper()
	var rows := board.rows_queued
	_rows_label.text = ("%d ROWS TO GO" % rows) if rows > 0 else "LAST ROWS!"
	_rows_label.add_theme_color_override("font_color", UI.DIM if rows > 0 else UI.GOLD)
	var touch := Inputs.device == Inputs.Device.TOUCH
	_pause_button.visible = touch
	_quake_button.visible = touch and board.quake_charged()
	if board.quake_charged():
		var pulse := 0.6 + 0.4 * sin(board.clock * 8.0)
		_quake_label.text = "QUAKE READY - " + Inputs.prompt("quake").to_upper()
		_quake_label.add_theme_color_override("font_color", Color("ffb03b").lerp(Color.WHITE, pulse * 0.4))
	else:
		_quake_label.text = "QUAKE"
		_quake_label.add_theme_color_override("font_color", UI.DIM)
	if board.state == Board.State.SERVE:
		_prompt.modulate.a = 0.6 + 0.4 * sin(board.clock * 5.0)
	_bars.queue_redraw()


func _update_prompt() -> void:
	if board == null or board.state != Board.State.SERVE and board.state != Board.State.INTRO:
		_prompt.text = ""
		_help.text = ""
		return
	_prompt.text = Inputs.prompt("smash").to_upper() + " TO LAUNCH"
	# The controls, on the first floor of the game.
	if board.level == 0 or not Game.seen_help:
		_help.text = "%s: MOVE\n%s: SMASH (TIME IT!)\n%s: QUAKE (WHEN CHARGED)" % [
			Inputs.prompt("move").to_upper(), Inputs.prompt("smash").to_upper(), Inputs.prompt("quake").to_upper()]
	else:
		_help.text = ""


func refresh() -> void:
	_update_prompt()


static func _format(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out


# --- the bars -----------------------------------------------------------------------------------

func _draw_bars() -> void:
	if board == null or board_rect.size == Vector2.ZERO:
		return
	var px := Balance.PX
	var r := board_rect
	# The wave bar, along the top: fills as the wall gets ready to come down.
	var bar := Rect2(r.position.x, r.position.y - (Balance.WALL + Balance.BLOCK_DEPTH + px * 5.0) * zoom, r.size.x, px * 3.0 * zoom)
	_bars.draw_rect(bar.grow(px), UI.SHADOW)
	var fill := clampf(board.wave_timer / board.wave_time, 0.0, 1.0)
	var c := Color("ff4fa3").lerp(Color("ff2a2a"), fill)
	if board.effect(Pickups.Kind.FROST) > 0.0:
		c = Color("9fe8ff")
	elif fill > 0.85 and fmod(board.clock, 0.2) < 0.1:
		c = Color.WHITE
	_bars.draw_rect(Rect2(bar.position, Vector2(bar.size.x * fill, bar.size.y)), c)
	# Notches, one per second.
	var seconds := int(board.wave_time)
	for i in range(1, seconds):
		_bars.draw_rect(Rect2(bar.position.x + bar.size.x * i / board.wave_time, bar.position.y, px * 0.5, bar.size.y), Color(0, 0, 0, 0.4))
	# The quake meter, under the board.
	var q := Rect2(r.position.x, r.end.y + (Balance.BLOCK_DEPTH + px * 6.0) * zoom, r.size.x, px * 4.0 * zoom)
	_bars.draw_rect(q.grow(px), UI.SHADOW)
	var charge := board.quake / Balance.QUAKE_CHARGE
	var qc := Color("ffb03b")
	if board.quake_charged():
		qc = qc.lerp(Color.WHITE, 0.5 + 0.5 * sin(board.clock * 10.0))
	_bars.draw_rect(Rect2(q.position, Vector2(q.size.x * charge, q.size.y)), qc)
	# The pickups running: their icons along the top of the board, each with a bar for the time left.
	var x := _effects_at.x
	var y := _effects_at.y
	for kind: Pickups.Kind in board.effects:
		var left: float = board.effects[kind]
		var full := _duration(kind)
		var at := Vector2(x + px * 5.0, y + px * 5.0)
		if left > 2.0 or fmod(left, 0.3) < 0.18:
			Pickups.draw_icon(_bars, kind, at, px)
		_bars.draw_rect(Rect2(x + px, y + px * 11.0, px * 8.0, px), UI.SHADOW)
		_bars.draw_rect(Rect2(x + px, y + px * 11.0, px * 8.0 * clampf(left / full, 0.0, 1.0), px), Pickups.info(kind)["color"])
		x += px * 11.0
	# Over the board, the icons take the place of the floor's name and rows.
	_rows_label.visible = wide or board.effects.is_empty()
	_floor_name.visible = wide or board.effects.is_empty()


static func _duration(kind: Pickups.Kind) -> float:
	match kind:
		Pickups.Kind.FIRE:
			return Balance.FIRE_TIME
		Pickups.Kind.FROST:
			return Balance.FROST_TIME
		Pickups.Kind.ZAP:
			return Balance.ZAP_TIME
		Pickups.Kind.WIDE:
			return Balance.WIDE_TIME
		Pickups.Kind.NARROW:
			return Balance.NARROW_TIME
		Pickups.Kind.OVERDRIVE:
			return Balance.OVERDRIVE_TIME
		Pickups.Kind.ROCKET:
			return Balance.ROCKET_TIME
		Pickups.Kind.SHIELD:
			return Balance.SHIELD_TIME
	return 10.0


# --- popups and messages ------------------------------------------------------------------------

func _on_scored(points: int, at: Vector2) -> void:
	var start := board_rect.position + (at - Vector2(0, Balance.BLOCK_DEPTH)) * zoom
	var big := points >= 200
	var l := UI.label(str(points), 3 if big else 2, UI.GOLD if big else UI.INK)
	l.size = Vector2(160, 30)
	l.position = start - l.size * 0.5
	l.pivot_offset = l.size * 0.5
	_popups.add_child(l)
	# Up a little, a beat, then off to the score (the original game's).
	var target := _score_label.position + Vector2(_score_label.size.x - 80, 10)
	var t := l.create_tween()
	t.tween_property(l, "position:y", l.position.y - 36, 0.25).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	t.tween_interval(0.15)
	t.tween_property(l, "position", target, 0.45).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(l, "scale", Vector2(0.6, 0.6), 0.45)
	t.tween_callback(func() -> void:
		_score_label.scale = Vector2(1.12, 1.12)
		_score_label.create_tween().tween_property(_score_label, "scale", Vector2.ONE, 0.15)
		l.queue_free())


func _on_combo(combo: int, mult: int) -> void:
	if combo < 2:
		if _combo_shown >= 2:
			var t := _combo_label.create_tween().set_parallel()
			t.tween_property(_combo_label, "modulate:a", 0.0, 0.3)
			t.tween_property(_combo_mult, "modulate:a", 0.0, 0.3)
		_combo_shown = combo
		return
	_combo_shown = combo
	_combo_label.text = "%d COMBO" % combo
	_combo_mult.text = "x%d" % mult
	_combo_label.modulate.a = 1.0
	_combo_mult.modulate.a = 1.0
	var heat := clampf(combo / 40.0, 0.0, 1.0)
	_combo_label.add_theme_color_override("font_color", UI.GOLD.lerp(Color("ff3d3d"), heat))
	_combo_label.scale = Vector2(1.35, 1.35) + Vector2.ONE * heat * 0.3
	_combo_label.rotation = randf_range(-0.08, 0.08)
	var t := _combo_label.create_tween().set_parallel()
	t.tween_property(_combo_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_combo_label, "rotation", 0.0, 0.25)


## The big words over the board, punched in and faded out.
func show_message(text: String, color := UI.INK, hold := 0.6, scale := 7) -> void:
	if _message_tween:
		_message_tween.kill()
	_message.text = text
	_message.add_theme_font_size_override("font_size", UI.FONT_PX * scale)
	_message.add_theme_color_override("font_color", color)
	_message.modulate.a = 1.0
	_message.scale = Vector2(2.2, 2.2)
	_message.rotation = randf_range(-0.06, 0.06)
	_message_tween = _message.create_tween()
	_message_tween.tween_property(_message, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_message_tween.tween_interval(hold)
	_message_tween.tween_property(_message, "modulate:a", 0.0, 0.3)


## A card for a new floor: its number big, its name under it.
func floor_card(level: int) -> void:
	var title := Floors.label(level)
	var sub: String = Floors.theme(level)["name"] if level < Balance.FLOORS else "Deeper..."
	show_message("%s\n%s" % [title, sub.to_upper()], UI.INK, 1.4, 6)
