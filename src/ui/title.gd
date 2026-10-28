extends Control
## The title: the logo raining in over the rays, and the menu under it
## (Play, How to play, High scores, Locker, Options, and Quit where there is
## something to quit to). Play swaps the menu for the modes, each described
## (and its best) as it gets the focus. The best score and the version
## along the bottom.

var _logo: Logo
var _buttons: Array = []
var _backdrop: Backdrop
var _menu: VBoxContainer
var _modes: VBoxContainer
var _mode_buttons: Array = []
var _stats: Label
var _blurb: Label
## Back from one of its own menus (how to play, high scores, options): no entrance, it is all there already.
var _quick := false
var _from := ""


func setup(args: Dictionary) -> void:
	_from = String(args.get("from", ""))
	_quick = _from in ["help", "scores", "locker", "options"]


func _ready() -> void:
	UI.screen_root(self)
	_backdrop = Backdrop.new()
	add_child(_backdrop)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 18)
	add_child(column)
	_logo = Logo.new()
	_logo.settled = _quick
	_logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(_logo)
	var tagline := UI.label("BRING THE HAUS DOWN", 2, UI.DIM)
	column.add_child(tagline)
	column.add_child(_gap(36))
	# The menu and the modes take turns in one slot, as big as the bigger of them, so that swapping
	# them (or anything changing under them) never moves a button.
	var menu_slot := CenterContainer.new()
	column.add_child(menu_slot)
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 16)
	menu_slot.add_child(_menu)
	_buttons = [
		UI.button("PLAY", _show_modes),
		UI.button("HOW TO PLAY", func() -> void: _go("help")),
		UI.button("HIGH SCORES", func() -> void: _go("scores")),
		UI.button("LOCKER", func() -> void: _go("locker")),
		UI.button("OPTIONS", func() -> void: _go("options")),
	]
	if Game.can_quit():
		_buttons.append(UI.button("QUIT", func() -> void: get_tree().quit()))
	for i in _buttons.size():
		var b: Button = _buttons[i]
		_menu.add_child(b)
		b.focus_entered.connect(func() -> void: _logo.ripple(Vector2(_logo.size.x * (0.2 + 0.6 * randf()), _logo.size.y), 0.5))
	UI.link_focus(_buttons)
	_modes = VBoxContainer.new()
	_modes.add_theme_constant_override("separation", 16)
	_modes.visible = false
	menu_slot.add_child(_modes)
	for mode: String in Modes.ALL:
		var b := UI.button(Modes.name_of(mode).to_upper(), func() -> void:
			Game.mode = mode
			_go("play"))
		b.focus_entered.connect(func() -> void:
			_describe(mode)
			_logo.ripple(Vector2(_logo.size.x * (0.2 + 0.6 * randf()), _logo.size.y), 0.5))
		_modes.add_child(b)
		_mode_buttons.append(b)
	var back := UI.button("BACK", _hide_modes)
	back.focus_entered.connect(func() -> void: _blurb.text = "")
	_modes.add_child(back)
	_mode_buttons.append(back)
	UI.link_focus(_mode_buttons)
	column.add_child(_gap(30))
	var best := Game.best_score()
	var stats := ("BEST %s" % Hud._format(best)) if best > 0 else ""
	if Game.demolished > 0:
		stats += "    HAUS DEMOLISHED x%d" % Game.demolished
	# The stats and a mode's description share a slot of a fixed size too, room for five lines.
	var text_slot := Control.new()
	text_slot.custom_minimum_size = Vector2(640, 130)
	text_slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	text_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(text_slot)
	_stats = UI.label(stats, 2, UI.GOLD)
	_blurb = UI.label("", 2, UI.INK)
	_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_blurb.visible = false
	for l: Label in [_stats, _blurb]:
		l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		text_slot.add_child(l)
	_fit_slot.call_deferred(menu_slot)
	var version := UI.label(Game.version_text().to_upper(), 1, UI.DIM, HORIZONTAL_ALIGNMENT_LEFT)
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	version.position += Vector2(20, -36)
	add_child(version)
	var credit := UI.label("A GAME BY PIGMASSACRE", 1, UI.DIM, HORIZONTAL_ALIGNMENT_RIGHT)
	credit.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	credit.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	credit.position += Vector2(-20, -36)
	add_child(credit)
	if not _quick:
		for i in _buttons.size():
			UI.pop_in(_buttons[i], 1.0 + i * 0.08)
		tagline.modulate.a = 0.0
		create_tween().tween_property(tagline, "modulate:a", 1.0, 0.6).set_delay(1.4)
	Audio.play_music("title", 1.0)
	Audio.heat = 0.5
	Audio.muffle(0.0)
	# Back from a menu, the focus goes back to its button.
	var back_to := ["play", "help", "scores", "locker", "options"].find(_from)
	(_buttons[maxi(back_to, 0)] as Button).grab_focus.call_deferred()
	resized.connect(_place_rays)
	_place_rays.call_deferred()


func _place_rays() -> void:
	_backdrop.center = _logo.global_position + _logo.size * 0.5


func _go(screen: String) -> void:
	_logo.ripple(_logo.size * 0.5, 1.2)
	Game.goto(screen)


## The menu slot as big as the bigger of the menu and the modes.
func _fit_slot(slot: Control) -> void:
	var a := _menu.get_combined_minimum_size()
	var b := _modes.get_combined_minimum_size()
	slot.custom_minimum_size = Vector2(maxf(a.x, b.x), maxf(a.y, b.y))


func _show_modes() -> void:
	_menu.visible = false
	_modes.visible = true
	_stats.visible = false
	_blurb.visible = true
	for i in _mode_buttons.size():
		UI.pop_in(_mode_buttons[i], i * 0.04)
	(_mode_buttons[maxi(Modes.ALL.find(Game.mode), 0)] as Button).grab_focus()


func _hide_modes() -> void:
	_modes.visible = false
	_menu.visible = true
	_stats.visible = true
	_blurb.visible = false
	for i in _buttons.size():
		UI.pop_in(_buttons[i], i * 0.04)
	(_buttons[0] as Button).grab_focus()


## What a mode is, and its best.
func _describe(mode: String) -> void:
	var text: String = Modes.INFO[mode]["blurb"]
	if mode == Modes.DAILY:
		var twist := Modes.daily_twist(Modes.today())
		text += "\nToday: %s. %s" % [twist["name"], twist["blurb"]]
	var best := Game.mode_best(mode)
	if best > 0:
		text += "\n%s %s" % ["Best today" if mode == Modes.DAILY else "Best", Hud._format(best)]
	_blurb.text = text
	_blurb.scale = Vector2(0.96, 0.96)
	_blurb.pivot_offset = _blurb.size * 0.5
	_blurb.create_tween().tween_property(_blurb, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _modes.visible:
		get_viewport().set_input_as_handled()
		Audio.play("back", -2.0)
		_hide_modes()


func _gap(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func go_back() -> void:
	if _modes.visible:
		_hide_modes()
	elif Game.can_quit():
		get_tree().quit()
