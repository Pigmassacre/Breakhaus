class_name GameOver
extends CanvasLayer
## The wall got through: the score counting up, how far down the haus you
## got, the best combo and blocks broken, a new best if it was one, and
## again or back to the title.

var _board: Board
var _place := -1
var _score_label: Label
var _again: Button
var _title := ""


func _init(board: Board, place: int, title := "THE HAUS\nWINS") -> void:
	layer = 20
	_board = board
	_place = place
	_title = title


func _ready() -> void:
	var root := Control.new()
	UI.screen_root(root)
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.02, 0.06, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	UI.centered(root, box)
	var title := UI.label(_title, 8, Color("ff4f6a"))
	box.add_child(title)
	box.add_child(_gap(10))
	var mode := Modes.name_of(Game.mode).to_upper()
	if Game.mode == Modes.DAILY:
		mode += " - " + String(_board.twist.get("name", "")).to_upper()
	box.add_child(UI.label(mode + " SCORE" if Game.mode != Modes.CLASSIC else "SCORE", 2, UI.DIM))
	_score_label = UI.label("0", 7, UI.INK)
	box.add_child(_score_label)
	var best_text := "NEW BEST!" if _place == 0 else ("#%d ON THE TABLE" % (_place + 1) if _place > 0 else "")
	if Game.mode == Modes.DAILY and _place == 0:
		best_text = "TODAY'S BEST!"
	var best := UI.label(best_text, 3, UI.GOLD)
	box.add_child(best)
	box.add_child(_gap(10))
	var reached := "Reached " + Floors.long_label(_board.level)
	box.add_child(UI.label(reached.to_upper(), 3, UI.INK))
	box.add_child(UI.label("BEST COMBO %d    BLOCKS %d" % [_board.best_combo, _board.blocks_broken], 2, UI.DIM))
	box.add_child(_gap(24))
	_again = UI.button("PLAY AGAIN", func() -> void: Game.goto("play"))
	var title_button := UI.button("TITLE", func() -> void: Game.goto("title"))
	for b: Button in [_again, title_button]:
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(b)
	UI.link_focus([_again, title_button])
	UI.pop_in(title, 0.0, 0.5)
	# The score counts up, ticking, and lands with a thump (a fanfare for a new best).
	var t := create_tween()
	t.tween_interval(0.4)
	t.tween_method(_count, 0, _board.score, clampf(_board.score / 4000.0, 0.6, 2.0)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_callback(func() -> void:
		Audio.play("best" if _place == 0 else "drop", 0.0)
		_score_label.pivot_offset = _score_label.size * 0.5
		_score_label.scale = Vector2(1.3, 1.3)
		_score_label.create_tween().tween_property(_score_label, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if _place == 0:
			UI.pop_in(best))
	best.modulate.a = 0.0 if _place == 0 else 1.0
	_again.grab_focus.call_deferred()


var _last_tick := 0


func _count(v: int) -> void:
	_score_label.text = Hud._format(v)
	if v - _last_tick > maxi(_board.score / 30, 1):
		_last_tick = v
		Audio.play("tick", -10.0, 1.0 + float(v) / maxf(_board.score, 1.0) * 0.6)


func _gap(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func go_back() -> void:
	Game.goto("title")
