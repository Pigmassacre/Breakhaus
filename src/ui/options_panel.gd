class_name OptionsPanel
extends VBoxContainer
## The settings, as a column of rows: the volumes, the shake, the flashes,
## full screen (not on a phone), and a Back button. On the title's Options
## screen and in the pause menu alike.

signal closed

var _first: Control
var _focusables: Array = []


func _ready() -> void:
	add_theme_constant_override("separation", 22)
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(UI.label("OPTIONS", 6, UI.ACCENT))
	_slider("MUSIC", "music")
	_slider("SOUNDS", "sounds")
	_slider("SCREEN SHAKE", "shake")
	_toggle("FLASHES", "flashes")
	if Game.can_fullscreen():
		_toggle("FULL SCREEN", "fullscreen")
	var back := UI.button("BACK", func() -> void: closed.emit())
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(back)
	_focusables.append(back)
	UI.link_focus(_focusables)
	_first = _focusables[0]


func focus_first() -> void:
	_first.grab_focus()


func _row(title: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	var l := UI.label(title, 3, UI.INK, HORIZONTAL_ALIGNMENT_RIGHT)
	l.custom_minimum_size = Vector2(300, 0)
	row.add_child(l)
	add_child(row)
	return row


## The row's name lights up pink and bounces while its control has the focus.
func _light(row: HBoxContainer, control: Control) -> void:
	var l := row.get_child(0) as Label
	control.focus_entered.connect(func() -> void:
		l.add_theme_color_override("font_color", UI.ACCENT)
		l.pivot_offset = Vector2(l.size.x, l.size.y * 0.5)
		l.scale = Vector2(1.25, 1.25)
		l.create_tween().tween_property(l, "scale", Vector2.ONE * 1.08, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT))
	control.focus_exited.connect(func() -> void:
		l.add_theme_color_override("font_color", UI.INK)
		l.create_tween().tween_property(l, "scale", Vector2.ONE, 0.15))


func _slider(title: String, key: String, low := 0.0, high := 1.0) -> void:
	var row := _row(title)
	var s := HSlider.new()
	s.min_value = low
	s.max_value = high
	s.step = (high - low) / 10.0
	s.value = float(Game.settings[key])
	s.custom_minimum_size = Vector2(280, 40)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.focus_mode = Control.FOCUS_ALL
	s.value_changed.connect(func(v: float) -> void:
		Game.set_setting(key, v)
		Audio.play("tick", -4.0, 0.8 + v / high * 0.5))
	s.mouse_entered.connect(s.grab_focus)
	UI.springy(s).hot_scale = 1.04
	_light(row, s)
	row.add_child(s)
	_focusables.append(s)


func _toggle(title: String, key: String) -> void:
	var row := _row(title)
	var c := CheckButton.new()
	c.button_pressed = bool(Game.settings[key])
	c.custom_minimum_size = Vector2(280, 40)
	c.focus_mode = Control.FOCUS_ALL
	c.toggled.connect(func(on: bool) -> void:
		Game.set_setting(key, on)
		Audio.play("accept", -4.0))
	c.mouse_entered.connect(c.grab_focus)
	UI.springy(c)
	_light(row, c)
	row.add_child(c)
	_focusables.append(c)
