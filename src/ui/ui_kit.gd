class_name UI
## The look of every menu: the original game's chunky bitmap font (AddLG,
## nine pixels high, drawn at whole multiples of that), labels with a hard
## drop shadow, and blocky buttons that light up when focused, whether by
## mouse, keys, pad or finger.

const FONT_PATH := "res://assets/fonts/addlg.fnt"
## The font's own height; every size is a whole multiple of it.
const FONT_PX := 9

const INK := Color("fff4fb")
const DIM := Color("c9a3c4")
const ACCENT := Color("ff4fa3")
const GOLD := Color("ffd23d")
const PANEL := Color("1d0b24")
const SHADOW := Color("0d0510")

static var _font: FontFile
static var _theme: Theme


static func font() -> FontFile:
	if _font == null:
		_font = load(FONT_PATH) as FontFile
		_font.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	return _font


## A label `scale` times the font's own size.
static func label(text: String, scale := 3, color := INK, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	style_label(l, scale, color)
	return l


static func style_label(l: Label, scale: int, color := INK) -> void:
	l.add_theme_font_override("font", font())
	l.add_theme_font_size_override("font_size", FONT_PX * scale)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", SHADOW)
	l.add_theme_constant_override("shadow_offset_x", maxi(scale / 2, 1) * 2)
	l.add_theme_constant_override("shadow_offset_y", maxi(scale / 2, 1) * 2)
	l.add_theme_constant_override("line_spacing", scale * 3)


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = font()
	t.default_font_size = FONT_PX * 3
	t.set_stylebox("normal", "Button", _box(PANEL, Color("6b2a63")))
	t.set_stylebox("hover", "Button", _box(Color("3d1849"), ACCENT))
	t.set_stylebox("focus", "Button", _box(Color("3d1849"), ACCENT, true))
	t.set_stylebox("pressed", "Button", _box(ACCENT.darkened(0.3), GOLD))
	t.set_stylebox("disabled", "Button", _box(PANEL, Color("3a2a3a")))
	t.set_stylebox("hover_pressed", "Button", _box(ACCENT.darkened(0.3), GOLD))
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_focus_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color("6b5a6b"))
	t.set_color("font_shadow_color", "Button", SHADOW)
	t.set_constant("shadow_offset_x", "Button", 2)
	t.set_constant("shadow_offset_y", "Button", 2)
	t.set_color("font_color", "Label", INK)
	t.set_stylebox("panel", "PanelContainer", _box(Color(PANEL, 0.94), Color("6b2a63")))
	t.set_stylebox("panel", "Panel", _box(Color(PANEL, 0.94), Color("6b2a63")))
	# Sliders: a chunky track, a square grabber.
	var track := StyleBoxFlat.new()
	track.bg_color = Color("3d1849")
	track.content_margin_top = 6
	track.content_margin_bottom = 6
	t.set_stylebox("slider", "HSlider", track)
	var fill := StyleBoxFlat.new()
	fill.bg_color = ACCENT
	fill.content_margin_top = 6
	fill.content_margin_bottom = 6
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	t.set_icon("grabber", "HSlider", _square(24, INK))
	t.set_icon("grabber_highlight", "HSlider", _square(24, GOLD))
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = GOLD
	focus.set_border_width_all(4)
	focus.set_expand_margin_all(6)
	t.set_stylebox("focus", "HSlider", focus)
	t.set_stylebox("focus", "CheckButton", focus)
	t.set_stylebox("normal", "CheckButton", StyleBoxEmpty.new())
	t.set_stylebox("hover", "CheckButton", StyleBoxEmpty.new())
	t.set_stylebox("pressed", "CheckButton", StyleBoxEmpty.new())
	t.set_stylebox("hover_pressed", "CheckButton", StyleBoxEmpty.new())
	t.set_icon("checked", "CheckButton", _toggle(true))
	t.set_icon("unchecked", "CheckButton", _toggle(false))
	t.set_color("font_color", "CheckButton", INK)
	t.set_color("font_hover_color", "CheckButton", Color.WHITE)
	t.set_color("font_focus_color", "CheckButton", Color.WHITE)
	t.set_color("font_pressed_color", "CheckButton", Color.WHITE)
	t.set_color("font_hover_pressed_color", "CheckButton", Color.WHITE)
	_theme = t
	return t


static func _box(bg: Color, border: Color, thick := false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(6 if thick else 4)
	box.content_margin_left = 24
	box.content_margin_right = 24
	box.content_margin_top = 14
	box.content_margin_bottom = 14
	box.shadow_color = SHADOW
	box.shadow_offset = Vector2(6, 6)
	box.shadow_size = 0
	box.anti_aliasing = false
	return box


static func _square(size: int, color: Color) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(SHADOW)
	image.fill_rect(Rect2i(4, 4, size - 8, size - 8), color)
	return ImageTexture.create_from_image(image)


## A switch: a dark track with a block at the off end, or pink with it at the on end.
static func _toggle(on: bool) -> ImageTexture:
	var image := Image.create(64, 32, false, Image.FORMAT_RGBA8)
	image.fill(SHADOW)
	image.fill_rect(Rect2i(4, 4, 56, 24), ACCENT if on else Color("3d1849"))
	image.fill_rect(Rect2i(36 if on else 8, 8, 20, 16), INK)
	return ImageTexture.create_from_image(image)


## A button that ticks when it gets the focus, goes "select" when pressed, and takes the focus when the mouse comes over it.
static func button(text: String, on_press: Callable, min_width := 360.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_width, 0)
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_entered.connect(func() -> void:
		if not b.has_focus() and not b.disabled:
			b.grab_focus())
	b.focus_entered.connect(func() -> void: Audio.play("tick", -6.0, randf_range(0.97, 1.05)))
	b.pressed.connect(func() -> void:
		Audio.play("accept", -2.0)
		on_press.call())
	return b


## A full-screen control for a screen to build on.
static func screen_root(node: Control) -> void:
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	node.theme = theme()


## Puts `child` in the middle of `parent`, whatever size either turns out to be.
static func centered(parent: Control, child: Control) -> CenterContainer:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(center)
	center.add_child(child)
	return center


## Lays the buttons in `box` out so up and down go between them, round from the last to the first.
static func link_focus(buttons: Array) -> void:
	var live := buttons.filter(func(b: Control) -> bool: return b.visible)
	for i in live.size():
		var b: Control = live[i]
		b.focus_neighbor_top = b.get_path_to(live[(i - 1 + live.size()) % live.size()])
		b.focus_neighbor_bottom = b.get_path_to(live[(i + 1) % live.size()])
		b.focus_neighbor_left = b.get_path()
		b.focus_neighbor_right = b.get_path()


## Pops `node` in: from small and see-through to full size, with a little overshoot.
static func pop_in(node: CanvasItem, delay := 0.0, seconds := 0.35) -> void:
	node.modulate.a = 0.0
	if node is Control:
		(node as Control).pivot_offset = (node as Control).size * 0.5
	node.scale = Vector2(0.6, 0.6)
	var t := node.create_tween().set_parallel()
	t.tween_property(node, "modulate:a", 1.0, seconds * 0.6).set_delay(delay)
	t.tween_property(node, "scale", Vector2.ONE, seconds).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
