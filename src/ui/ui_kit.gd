class_name UI
## The look of every menu and of the HUD: flat and HD over the pixel-art
## game. Big words in Bangers, small ones in Ubuntu Bold, both as MSDF fonts
## so they stay sharp however they are scaled; rounded flat buttons with a
## darker lip under them that they press down into; and a Spring on every
## button, slider and switch so they grow, lean and boing as the cursor,
## the keys or a finger get to them.

const DISPLAY_PATH := "res://assets/fonts/Bangers-Regular.ttf"
## The variable Ubuntu, set to bold.
const BODY_PATH := "res://assets/fonts/Ubuntu.ttf"
const BODY_WEIGHT := 700

const INK := Color("fff4fb")
const DIM := Color("c9a3c4")
const ACCENT := Color("ff4fa3")
const GOLD := Color("ffd23d")
const PANEL := Color("2a1235")
const SHADOW := Color("0d0510")
## A button at rest, and its lip.
const BUTTON := Color("43204f")
const BUTTON_LIP := Color("1f0b29")
const RADIUS := 18
const LIP := 8

static var _display: FontFile
static var _body: FontVariation
static var _theme: Theme
static var _round_box: StyleBoxFlat


static func display_font() -> FontFile:
	if _display == null:
		_display = load(DISPLAY_PATH) as FontFile
	return _display


static func body_font() -> Font:
	if _body == null:
		_body = FontVariation.new()
		_body.base_font = load(BODY_PATH) as FontFile
		_body.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): BODY_WEIGHT}
	return _body


## Big text (scale 3 and up) is Bangers, small text Ubuntu.
static func font_for(scale: int) -> Font:
	return display_font() if scale >= 3 else body_font()


## The size in pixels of text at `scale` (the steps the old bitmap font came in).
static func font_size(scale: int) -> int:
	return scale * 13 if scale >= 3 else 8 + scale * 7


## A label at `scale`: 1 and 2 for small print, 3 for buttons, up to 8 for the biggest words.
static func label(text: String, scale := 3, color := INK, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	style_label(l, scale, color)
	return l


static func style_label(l: Label, scale: int, color := INK) -> void:
	l.add_theme_font_override("font", font_for(scale))
	l.add_theme_font_size_override("font_size", font_size(scale))
	l.add_theme_color_override("font_color", color)
	# A flat drop straight down, darker the bigger the words.
	l.add_theme_color_override("font_shadow_color", Color(SHADOW, 0.55 if scale < 3 else 0.8))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", maxi(scale, 2))
	l.add_theme_constant_override("line_spacing", -scale * 2 if scale >= 3 else 2)


## Words over the busy board: a thick dark outline as well.
static func outline(l: Label, width := 10) -> void:
	l.add_theme_color_override("font_outline_color", SHADOW)
	l.add_theme_constant_override("outline_size", width)


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = body_font()
	t.default_font_size = font_size(2)
	t.set_font("font", "Button", display_font())
	t.set_font_size("font_size", "Button", font_size(3))
	t.set_stylebox("normal", "Button", _button_box(BUTTON, BUTTON_LIP))
	t.set_stylebox("hover", "Button", _button_box(BUTTON.lightened(0.12), BUTTON_LIP))
	t.set_stylebox("pressed", "Button", _button_box(ACCENT.darkened(0.15), ACCENT.darkened(0.55), true))
	t.set_stylebox("hover_pressed", "Button", _button_box(ACCENT.darkened(0.15), ACCENT.darkened(0.55), true))
	t.set_stylebox("disabled", "Button", _button_box(BUTTON.darkened(0.3), BUTTON_LIP))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_focus_color", "Button", INK)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_hover_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color("6b5a6b"))
	t.set_color("font_shadow_color", "Button", Color(SHADOW, 0.6))
	t.set_constant("shadow_offset_x", "Button", 0)
	t.set_constant("shadow_offset_y", "Button", 3)
	# The button with the focus: hot pink, its lip deeper.
	t.set_type_variation("HotButton", "Button")
	t.set_stylebox("normal", "HotButton", _button_box(ACCENT, ACCENT.darkened(0.45)))
	t.set_stylebox("hover", "HotButton", _button_box(ACCENT.lightened(0.1), ACCENT.darkened(0.45)))
	t.set_color("font_color", "HotButton", Color.WHITE)
	t.set_color("font_focus_color", "HotButton", Color.WHITE)
	t.set_color("font_hover_color", "HotButton", Color.WHITE)
	t.set_color("font_color", "Label", INK)
	t.set_stylebox("panel", "PanelContainer", _flat(Color(PANEL, 0.94), 28))
	t.set_stylebox("panel", "Panel", _flat(Color(PANEL, 0.94), 28))
	# Sliders: a fat rounded track, filled pink up to a round knob.
	var track := _flat(BUTTON.lightened(0.06), 10)
	track.content_margin_top = 8
	track.content_margin_bottom = 8
	t.set_stylebox("slider", "HSlider", track)
	var fill := _flat(ACCENT, 10)
	fill.content_margin_top = 8
	fill.content_margin_bottom = 8
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", _flat(ACCENT.lightened(0.15), 10))
	t.set_icon("grabber", "HSlider", _knob(40, INK))
	t.set_icon("grabber_highlight", "HSlider", _knob(40, GOLD))
	var focus := _flat(Color.TRANSPARENT, 22)
	focus.draw_center = false
	focus.border_color = GOLD
	focus.set_border_width_all(4)
	focus.set_expand_margin_all(10)
	t.set_stylebox("focus", "HSlider", focus)
	t.set_stylebox("focus", "CheckButton", focus)
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		t.set_stylebox(state, "CheckButton", StyleBoxEmpty.new())
	t.set_icon("checked", "CheckButton", _switch(true))
	t.set_icon("unchecked", "CheckButton", _switch(false))
	t.set_color("font_color", "CheckButton", INK)
	t.set_color("font_hover_color", "CheckButton", Color.WHITE)
	t.set_color("font_focus_color", "CheckButton", Color.WHITE)
	t.set_color("font_pressed_color", "CheckButton", Color.WHITE)
	t.set_color("font_hover_pressed_color", "CheckButton", Color.WHITE)
	_theme = t
	return t


## Draws a flat rounded rect on `canvas` (round at the ends, unless `radius` says otherwise).
static func draw_round(canvas: CanvasItem, rect: Rect2, color: Color, radius := -1.0) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	if _round_box == null:
		_round_box = _flat(Color.WHITE)
	var most := minf(rect.size.x, rect.size.y) * 0.5
	_round_box.bg_color = color
	_round_box.set_corner_radius_all(int(most if radius < 0.0 else minf(radius, most)))
	canvas.draw_style_box(_round_box, rect)


## A flat rounded box, smooth at the edges.
static func _flat(bg: Color, radius := RADIUS) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.set_corner_radius_all(radius)
	box.corner_detail = 12
	box.anti_aliasing = true
	return box


## A button's face with its lip under it; `down` is pressed into the lip, the face lower and the lip thin.
static func _button_box(face: Color, lip: Color, down := false) -> StyleBoxFlat:
	var box := _flat(face)
	box.border_color = lip
	box.border_width_bottom = 2 if down else LIP
	box.content_margin_left = 32
	box.content_margin_right = 32
	box.content_margin_top = 14 + (LIP - 2 if down else 0)
	box.content_margin_bottom = 12
	if down:
		box.expand_margin_top = -(LIP - 2)
	return box


## A round knob, anti-aliased, with a darker rim.
static func _knob(size: int, color: Color) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size, size) * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			var outer := clampf(size * 0.5 - 1.0 - d, 0.0, 1.0)
			var inner := clampf(size * 0.5 - 6.0 - d, 0.0, 1.0)
			var col := BUTTON_LIP.lerp(color, inner)
			image.set_pixel(x, y, Color(col, outer))
	return ImageTexture.create_from_image(image)


## A switch: a pill, pink with the knob at the right end when on, dark with it at the left when off.
static func _switch(on: bool) -> ImageTexture:
	var w := 80
	var h := 42
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var r := h * 0.5
	var knob := Vector2(w - r if on else r, r)
	var track := ACCENT if on else BUTTON_LIP
	for y in h:
		for x in w:
			var p := Vector2(x + 0.5, y + 0.5)
			# Distance outside the pill (a rounded segment), and from the knob.
			var along := Vector2(clampf(p.x, r, w - r), r)
			var pill := clampf(r - p.distance_to(along), 0.0, 1.0)
			var k := clampf(r - 5.0 - p.distance_to(knob), 0.0, 1.0)
			image.set_pixel(x, y, Color(track.lerp(INK, k), pill))
	return ImageTexture.create_from_image(image)


## A button that ticks when it gets the focus, goes "select" when pressed, takes the focus when the
## mouse comes over it, turns hot pink while it has the focus, and has a Spring in it.
static func button(text: String, on_press: Callable, min_width := 360.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_width, 0)
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_entered.connect(func() -> void:
		if not b.has_focus() and not b.disabled:
			b.grab_focus())
	b.focus_entered.connect(func() -> void:
		b.theme_type_variation = &"HotButton"
		Audio.play("tick", -6.0, randf_range(0.97, 1.05)))
	b.focus_exited.connect(func() -> void: b.theme_type_variation = &"")
	b.pressed.connect(func() -> void:
		Audio.play("accept", -2.0)
		on_press.call())
	springy(b)
	return b


## Gives `c` a Spring (once), and returns it.
static func springy(c: Control) -> Spring:
	for child in c.get_children():
		if child is Spring:
			return child
	var s := Spring.new(c)
	c.add_child(s)
	return s


## A full-screen control for a screen to build on; smooth filtering, since the UI is drawn HD.
static func screen_root(node: Control) -> void:
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	node.theme = theme()
	node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


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


## Pops `node` in: from nothing to full size with a boing. A control with a Spring springs in on it.
static func pop_in(node: CanvasItem, delay := 0.0, seconds := 0.35) -> void:
	if node is Control:
		for child in node.get_children():
			if child is Spring:
				(child as Spring).pop(delay)
				return
		(node as Control).pivot_offset = (node as Control).size * 0.5
	node.modulate.a = 0.0
	node.scale = Vector2(0.6, 0.6)
	var t := node.create_tween().set_parallel()
	t.tween_property(node, "modulate:a", 1.0, seconds * 0.6).set_delay(delay)
	t.tween_property(node, "scale", Vector2.ONE, seconds).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
