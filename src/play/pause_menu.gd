class_name PauseMenu
extends CanvasLayer
## Paused: carry on, start again, the options, or back to the title.

signal resumed

var _root: Control
var _menu: VBoxContainer
var _options: OptionsPanel


func _init() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_root = Control.new()
	UI.screen_root(_root)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.02, 0.06, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	_menu = VBoxContainer.new()
	_menu.alignment = BoxContainer.ALIGNMENT_CENTER
	_menu.add_theme_constant_override("separation", 20)
	UI.centered(_root, _menu)
	_menu.add_child(UI.label("PAUSED", 7, UI.ACCENT))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	_menu.add_child(spacer)
	var buttons := [
		UI.button("RESUME", func() -> void: resumed.emit()),
		UI.button("RESTART", func() -> void: Game.goto("play")),
		UI.button("OPTIONS", _show_options),
		UI.button("QUIT TO TITLE", func() -> void: Game.goto("title")),
	]
	for b: Button in buttons:
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_menu.add_child(b)
	UI.link_focus(buttons)
	UI.pop_in(_menu)
	buttons[0].grab_focus.call_deferred()


func _show_options() -> void:
	_menu.visible = false
	_options = OptionsPanel.new()
	_options.closed.connect(_hide_options)
	UI.centered(_root, _options)
	_options.focus_first.call_deferred()


func _hide_options() -> void:
	_options.get_parent().queue_free()
	_options = null
	_menu.visible = true
	(_menu.get_child(4) as Button).grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		go_back()


func go_back() -> void:
	Audio.play("back", -2.0)
	if _options:
		_hide_options()
	else:
		resumed.emit()
