extends Control
## The options, from the title: the settings panel over the rays.

var _panel: OptionsPanel


func _ready() -> void:
	UI.screen_root(self)
	add_child(Backdrop.new())
	_panel = OptionsPanel.new()
	_panel.closed.connect(func() -> void: Game.goto("title"))
	add_child(_panel)
	_panel.focus_first.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		go_back()


func go_back() -> void:
	Audio.play("back", -2.0)
	Game.goto("title")
