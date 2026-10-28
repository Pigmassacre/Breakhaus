extends Node
## The root: shows one screen at a time (the splash, the title, the game,
## the menus), with a curtain of squares between them.
##
## Run with `-- --screen=play` (or any screen's name) to start there, and
## `-- --floor=3` to start the game on that floor (from 0, the top). For
## testing without playing: `--autoplay` has the game play itself (and
## `--autoplay=lazy` just launches the ball and lets the wall win),
## `--short-floors` makes every floor one row, `--clear-at=5` clears the
## floor after five seconds, and
## `--shots=1.5,4,9` saves a screenshot to shots/ at each of those seconds
## and quits after the last (`--size=720x1280` sizes the window first).
## `--mode=rush` (or daily, or classic) picks the mode,
## `--drop=laser,shield` hangs those pickups over the board and `--give=` catches them,
## `--all-effects` sets every timed pickup going at once, `--sweep-at=5` breaks every block after five seconds (a clean sweep), and
## `--mouse=1.5:800:400,2:800:460` moves the pointer to those window
## coordinates at those seconds (`:click` on the end presses there).

const SCREENS := {
	"splash": "res://src/ui/splash.gd",
	"title": "res://src/ui/title.gd",
	"play": "res://src/play/play.gd",
	"options": "res://src/ui/options.gd",
	"help": "res://src/ui/help.gd",
	"scores": "res://src/ui/scores.gd",
}

var screen: Node
var screen_name := ""
var _curtain: ColorRect
var _curtain_material := ShaderMaterial.new()
var _busy := false


func _ready() -> void:
	Game.main = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.min_size = Vector2i(360, 480)
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_curtain = ColorRect.new()
	_curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_curtain_material.shader = preload("res://src/fx/curtain.gdshader")
	_curtain.material = _curtain_material
	layer.add_child(_curtain)
	_set_curtain(0.0)
	# The splash is skipped for now (it is to be redone); `--screen=splash` still shows it.
	var first := "title"
	var args := {}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screen="):
			first = arg.trim_prefix("--screen=")
		elif arg.begins_with("--floor="):
			args["floor"] = int(arg.trim_prefix("--floor="))
		elif arg == "--autoplay":
			Game.autoplay = true
		elif arg == "--autoplay=lazy":
			Game.autoplay_lazy = true
		elif arg.begins_with("--mode="):
			Game.mode = arg.trim_prefix("--mode=")
		elif arg == "--short-floors":
			Game.short_floors = true
		elif arg.begins_with("--size="):
			var wh := arg.trim_prefix("--size=").split("x")
			get_window().size = Vector2i(int(wh[0]), int(wh[1]))
		elif arg.begins_with("--mouse="):
			for step in arg.trim_prefix("--mouse=").split(","):
				_mouse_at(step.split(":"))
		elif arg.begins_with("--shots="):
			_take_shots(Array(arg.trim_prefix("--shots=").split(",")).map(func(t: String) -> float: return float(t)))
	show_screen(first, args)


func _take_shots(times: Array) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots"))
	# Kept out of the editor's imports (and so out of the builds).
	FileAccess.open("res://shots/.gdignore", FileAccess.WRITE)
	var start := Time.get_ticks_msec()
	for t: float in times:
		while (Time.get_ticks_msec() - start) / 1000.0 < t:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var path := "res://shots/%s_%05.1f.png" % [screen_name, t]
		get_viewport().get_texture().get_image().save_png(path)
		print("Saved ", path)
	get_tree().quit()


## One step of `--mouse=`: [seconds, x, y] or [seconds, x, y, "click"].
func _mouse_at(step: PackedStringArray) -> void:
	await get_tree().create_timer(float(step[0])).timeout
	var at := Vector2(float(step[1]), float(step[2]))
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	Input.parse_input_event(motion)
	if step.size() > 3 and step[3] == "click":
		for down: bool in [true, false]:
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = down
			click.position = at
			click.global_position = at
			Input.parse_input_event(click)
			await get_tree().create_timer(0.08).timeout


func _set_curtain(progress: float) -> void:
	_curtain_material.set_shader_parameter("progress", progress)
	_curtain_material.set_shader_parameter("size", _curtain.size)
	_curtain.visible = progress > 0.0


func show_screen(which: String, args := {}) -> void:
	if _busy:
		return
	_busy = true
	get_tree().paused = false
	Engine.time_scale = 1.0
	if screen:
		var close := create_tween()
		close.tween_method(_set_curtain, 0.0, 1.0, 0.3)
		await close.finished
		screen.queue_free()
		await get_tree().process_frame
	# Where it came from, for the title to know whether to make an entrance.
	args["from"] = screen_name
	screen_name = which
	screen = (load(SCREENS[which]) as GDScript).new()
	screen.process_mode = Node.PROCESS_MODE_PAUSABLE
	if screen.has_method("setup"):
		screen.setup(args)
	add_child(screen)
	move_child(screen, 0)
	var open := create_tween()
	open.tween_method(_set_curtain, 1.0 if _curtain.visible else 0.0, 0.0, 0.35)
	_busy = false


func _notification(what: int) -> void:
	# Android's back button: the screen handles it as a cancel.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and screen and screen.has_method("go_back"):
		screen.go_back()
