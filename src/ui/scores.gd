extends Control
## The ten best Classic runs: the score, how far down the haus each got,
## its best combo and when. Under them, the best Rush and today's best
## Daily Haus.


func _ready() -> void:
	UI.screen_root(self)
	add_child(Backdrop.new())
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	add_child(column)
	column.add_child(UI.label("HIGH SCORES", 6, UI.ACCENT))
	column.add_child(_gap(20))
	if Game.high_scores.is_empty():
		column.add_child(UI.label("NOTHING YET.\nGO BREAK SOMETHING!", 3, UI.DIM))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 34)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(grid)
	for i in Game.high_scores.size():
		var entry: Dictionary = Game.high_scores[i]
		var color := UI.GOLD if i == 0 else UI.INK
		grid.add_child(UI.label("%d." % (i + 1), 3, UI.DIM, HORIZONTAL_ALIGNMENT_RIGHT))
		grid.add_child(UI.label(Hud._format(int(entry["score"])), 3, color, HORIZONTAL_ALIGNMENT_RIGHT))
		grid.add_child(UI.label(Floors.label(int(entry.get("level", 0))), 3, color))
		grid.add_child(UI.label("x%d" % int(entry.get("combo", 0)), 2, UI.DIM, HORIZONTAL_ALIGNMENT_LEFT))
	column.add_child(_gap(20))
	var others := HBoxContainer.new()
	others.alignment = BoxContainer.ALIGNMENT_CENTER
	others.add_theme_constant_override("separation", 60)
	column.add_child(others)
	for mode: String in [Modes.RUSH, Modes.DAILY]:
		var box := VBoxContainer.new()
		var title := Modes.name_of(mode).to_upper()
		if mode == Modes.DAILY:
			title += " TODAY"
		box.add_child(UI.label(title, 2, UI.ACCENT))
		var best := Game.mode_best(mode)
		box.add_child(UI.label(Hud._format(best) if best > 0 else "-", 4, UI.INK))
		others.add_child(box)
	column.add_child(_gap(20))
	var back := UI.button("BACK", go_back)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(back)
	column.add_child(UI.label("GAMES PLAYED %d" % Game.games_played, 2, UI.DIM))
	back.grab_focus.call_deferred()


func _gap(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		go_back()


func go_back() -> void:
	Game.goto("title")
