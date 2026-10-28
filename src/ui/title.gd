extends Control
## The title: the logo raining in over the rays, and the menu under it
## (Play, How to play, High scores, Options, and Quit where there is
## something to quit to). The best score and the version along the bottom.

var _logo: Logo
var _buttons: Array = []
var _backdrop: Backdrop
var _menu: VBoxContainer


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
	_logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(_logo)
	var tagline := UI.label("BREAK THE HAUS BEFORE IT BREAKS YOU", 2, UI.DIM)
	column.add_child(tagline)
	column.add_child(_gap(36))
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 16)
	_menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(_menu)
	_buttons = [
		UI.button("PLAY", func() -> void: _go("play")),
		UI.button("HOW TO PLAY", func() -> void: _go("help")),
		UI.button("HIGH SCORES", func() -> void: _go("scores")),
		UI.button("OPTIONS", func() -> void: _go("options")),
	]
	if Game.can_quit():
		_buttons.append(UI.button("QUIT", func() -> void: get_tree().quit()))
	for i in _buttons.size():
		var b: Button = _buttons[i]
		_menu.add_child(b)
		b.focus_entered.connect(func() -> void: _logo.ripple(Vector2(_logo.size.x * (0.2 + 0.6 * randf()), _logo.size.y), 0.5))
	UI.link_focus(_buttons)
	column.add_child(_gap(30))
	var best := Game.best_score()
	var stats := ("BEST %s" % Hud._format(best)) if best > 0 else ""
	if Game.demolished > 0:
		stats += "    HAUS DEMOLISHED x%d" % Game.demolished
	column.add_child(UI.label(stats, 2, UI.GOLD))
	var version := UI.label(Game.version_text().to_upper(), 1, UI.DIM, HORIZONTAL_ALIGNMENT_LEFT)
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	version.position += Vector2(20, -36)
	add_child(version)
	var credit := UI.label("A GAME BY PIGMASSACRE", 1, UI.DIM, HORIZONTAL_ALIGNMENT_RIGHT)
	credit.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	credit.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	credit.position += Vector2(-20, -36)
	add_child(credit)
	for i in _buttons.size():
		UI.pop_in(_buttons[i], 1.0 + i * 0.08)
	tagline.modulate.a = 0.0
	create_tween().tween_property(tagline, "modulate:a", 1.0, 0.6).set_delay(1.4)
	Audio.play_music("title", 1.0)
	Audio.heat = 0.5
	Audio.muffle(0.0)
	(_buttons[0] as Button).grab_focus.call_deferred()
	resized.connect(_place_rays)
	_place_rays.call_deferred()


func _place_rays() -> void:
	_backdrop.center = _logo.global_position + _logo.size * 0.5


func _go(screen: String) -> void:
	_logo.ripple(_logo.size * 0.5, 1.2)
	Game.goto(screen)


func _gap(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func go_back() -> void:
	if Game.can_quit():
		get_tree().quit()
