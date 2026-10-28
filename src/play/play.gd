extends Node
## The game: the board in the middle of the rays, the HUD round it, and
## everything that makes a hit feel like one (the shake, the hitstop, the
## flash and the shock wave, the music heating up). Reads the controls and
## drives the paddle with them, runs a floor from its blocks raining in to
## its collapse, and the game from the top floor to the end.
##
## Controls: the mouse moves the paddle to where it is; keys and sticks
## drive it; a finger drags it (from anywhere, so it doesn't cover the
## ball). A click, a press of smash or a touch smashes (or launches).

const POST_SHADER := preload("res://src/fx/post.gdshader")

var level := 0
var board: Board
var hud: Hud
var backdrop: Backdrop
var world: Node2D
var post: ShaderMaterial

var _trauma := 0.0
## A zoom in on a big hit, springing back (0 to 1).
var _punch := 0.0
var _hitstop := 0.0
var _kb_speed := 0.0
var _mouse_active := false
var _overlay: CanvasLayer
var _flash_tween: Tween
var _shock_tween: Tween
var _over := false
var _paused := false
## Rush: the time left on the clock, and the last whole second of it (for the tick in the last ten).
var rush_left := 0.0
## Falling on to a new floor: 0 while it is far below (small, dark, not yet there), 1 landed.
var _arrive := 1.0
## Where the board goes, and its zoom, once it has landed (set by the layout).
var _board_at := Vector2.ZERO
var _board_zoom := 1.0
var _rush_second := 0


func setup(args: Dictionary) -> void:
	level = args.get("floor", 0)


func _ready() -> void:
	backdrop = Backdrop.new()
	var back_layer := CanvasLayer.new()
	back_layer.layer = -10
	back_layer.add_child(backdrop)
	add_child(back_layer)
	world = Node2D.new()
	add_child(world)
	board = Board.new()
	world.add_child(board)
	match Game.mode:
		Modes.DAILY:
			board.row_rng.seed = Modes.daily_seed(Modes.today())
			board.twist = Modes.daily_twist(Modes.today())
		Modes.RUSH:
			board.wave_scale = Modes.RUSH_WAVE
			rush_left = Modes.RUSH_TIME
	var post_layer := CanvasLayer.new()
	post_layer.layer = 5
	var post_rect := ColorRect.new()
	post_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	post_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post = ShaderMaterial.new()
	post.shader = POST_SHADER
	post_rect.material = post
	post_layer.add_child(post_rect)
	add_child(post_layer)
	hud = Hud.new()
	add_child(hud)
	hud.set_board(board)
	hud.pause_pressed.connect(pause)
	hud.quake_pressed.connect(_quake)
	board.shake.connect(add_shake)
	board.hitstop.connect(_on_hitstop)
	board.flashed.connect(flash)
	board.shocked.connect(shock)
	board.missed.connect(func() -> void: hud.show_message("MISS", Color("ff5a5a"), 0.3))
	board.combo_ended.connect(func(c: int) -> void: hud.show_message("%d COMBO!" % c, UI.GOLD, 0.5))
	board.quake_ready.connect(func() -> void: hud.show_message("QUAKE READY!", Color("ffb03b"), 0.5))
	board.floor_cleared.connect(_on_floor_cleared)
	board.missed.connect(Game.buzz.bind(60))
	board.hitstop.connect(func(seconds: float) -> void:
		if seconds >= Balance.HITSTOP_BIG:
			Game.buzz(35))
	board.overrun.connect(func(_b: Block) -> void: _game_over("THE HAUS\nWINS"))
	board.swept.connect(func() -> void:
		if Game.mode == Modes.RUSH:
			_add_time(Modes.RUSH_SWEEP_BONUS))
	board.launched.connect(func() -> void:
		Audio.play("go", -4.0)
		if level == 0:
			Game.seen_help = true
			Game.save())
	get_viewport().size_changed.connect(_layout)
	_layout()
	_start_floor(level)
	# `--clear-at=5`: the floor is cleared after that many seconds, for testing what comes after.
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--clear-at="):
			await get_tree().create_timer(float(arg.trim_prefix("--clear-at="))).timeout
			board.state = Board.State.CLEARED
			board.floor_cleared.emit()
		# `--drop=laser,shield`: those pickups hang over the board (to see them); `--give=` the same,
		# caught at once (to try them).
		elif arg.begins_with("--drop=") or arg.begins_with("--give="):
			await get_tree().create_timer(1.6).timeout
			var names := arg.substr(7).split(",")
			for i in names.size():
				var kind: int = Pickups.Kind.get(names[i].to_upper(), -1)
				if kind < 0:
					continue
				var p := {"kind": kind, "pos": Vector2(Balance.BOARD_W * (i + 1) / (names.size() + 1), Balance.BOARD_H * 0.55), "t": 0.0}
				board.pickups.append(p)
				if arg.begins_with("--give="):
					board._collect(p)
		# `--all-effects`: every pickup with a timer running at once (for the HUD's badges).
		elif arg == "--all-effects":
			await get_tree().create_timer(1.0).timeout
			for kind: Pickups.Kind in Pickups.INFO:
				if kind not in [Pickups.Kind.MULTI, Pickups.Kind.NARROW, Pickups.Kind.BARRAGE]:
					board.effects[kind] = 30.0
		# `--sweep-at=5`: every block is broken after that many seconds, for a clean sweep.
		elif arg.begins_with("--sweep-at="):
			await get_tree().create_timer(float(arg.trim_prefix("--sweep-at="))).timeout
			for b in board.blocks():
				board._break(b)


func _start_floor(n: int) -> void:
	level = n
	board.start_floor(n)
	var t := Floors.theme(n)
	backdrop.set_theme_colors(t, 1.0)
	Audio.play_music(t["music"], 1.5)
	Audio.muffle(0.0)
	hud.floor_card(n)
	hud.refresh()


## The fall on to floor `n`: it comes up out of the dark below, small and dim, growing faster and
## faster as it nears, the dust streaming up past it; then it lands with a thump, a shock and a
## puff of dust round the walls, and its blocks rain in.
func _fall_to_floor(n: int) -> void:
	level = n
	board.start_floor(n)
	# Held still (its blocks up out of sight, the paddle too) until it has landed.
	board.process_mode = Node.PROCESS_MODE_DISABLED
	board.arriving = true
	var t := Floors.theme(n)
	backdrop.set_theme_colors(t, 1.2)
	Audio.play_music(t["music"], 1.5)
	Audio.muffle(0.0)
	Audio.play("collapse", -6.0, 0.6)
	var fall := create_tween()
	fall.tween_method(_set_arrive, 0.0, 1.0, 1.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	fall.parallel().tween_property(backdrop, "rise_speed", 6.0, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await fall.finished
	if _over or not is_inside_tree():
		return
	# Landed.
	add_shake(14.0)
	shock(Vector2(Balance.BOARD_W * 0.5, Balance.BOARD_H * 0.6), 0.8)
	flash(t["light"], 0.2)
	Audio.play("boom", -2.0, 0.55)
	Audio.play("drop", 0.0, 0.7)
	Game.buzz(80)
	for i in 28:
		# Dust puffing out along the walls and the bottom.
		var side := i % 3
		var at := Vector2(randf() * Balance.BOARD_W, Balance.BOARD_H - Balance.PX * 2.0)
		if side < 2:
			at = Vector2(Balance.PX * 2.0 if side == 0 else Balance.BOARD_W - Balance.PX * 2.0, randf() * Balance.BOARD_H)
		board.particles.smoke(at, 1, 4.0, Color(t["light"], 0.5))
	board.arriving = false
	board.process_mode = Node.PROCESS_MODE_INHERIT
	hud.floor_card(n)
	hud.refresh()


func _set_arrive(v: float) -> void:
	_arrive = v
	_place_board()


## The board where the layout put it, or, while it is falling into place, smaller, lower and darker.
func _place_board() -> void:
	var size := Vector2(Balance.BOARD_W, Balance.BOARD_H) * _board_zoom
	var grow := lerpf(0.3, 1.0, _arrive)
	var center := _board_at + size * 0.5 + Vector2(0, (1.0 - _arrive) * size.y * 0.25)
	board.scale = Vector2.ONE * _board_zoom * grow
	board.position = center - size * 0.5 * grow
	var light := lerpf(0.2, 1.0, _arrive)
	board.modulate = Color(light, light, light, clampf(_arrive * 3.0, 0.0, 1.0)) if _arrive < 1.0 else Color.WHITE


func _layout() -> void:
	var view := get_viewport().get_visible_rect().size
	var frame := Vector2(Balance.BOARD_W + Balance.WALL * 2.0, Balance.BOARD_H + Balance.WALL + Balance.BLOCK_DEPTH)
	var zoom: float
	var at: Vector2
	if view.x > view.y * 1.05:
		# Wide: the board as tall as the screen allows, the HUD beside it.
		var above := 50.0
		var below := 110.0
		zoom = clampf((view.y - above - below) / frame.y, 0.8, 2.0)
		at = Vector2(roundf((view.x - Balance.BOARD_W * zoom) * 0.5), roundf(above + (Balance.WALL + Balance.BLOCK_DEPTH) * zoom))
	else:
		# Tall: the HUD over the board; the board as big as the width allows, if there is height to spare.
		var above := 200.0
		var below := 180.0
		zoom = clampf(minf((view.x - 24.0) / frame.x, (view.y - above - below) / Balance.BOARD_H), 0.6, 1.4)
		var spare := maxf(view.y - above - below - Balance.BOARD_H * zoom, 0.0)
		at = Vector2(roundf((view.x - Balance.BOARD_W * zoom) * 0.5), roundf(above + spare * 0.5))
	_board_at = at
	_board_zoom = zoom
	_place_board()
	backdrop.center = at + Vector2(Balance.BOARD_W * 0.5, Balance.BOARD_H * 0.4) * zoom
	hud.layout(Rect2(at, Vector2(Balance.BOARD_W, Balance.BOARD_H) * zoom), zoom)


# --- controls -----------------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if _over or _paused:
		return
	if event.is_action_pressed("pause"):
		pause()
		return
	if event.is_action_pressed("smash"):
		board.smash()
	if event.is_action_pressed("quake"):
		_quake()
	if event is InputEventScreenTouch and event.pressed:
		board.smash()
	elif event is InputEventScreenDrag:
		var gain: float = Balance.TOUCH_GAIN * float(Game.settings["touch_gain"])
		board.paddle_target = clampf(board.paddle_target + event.relative.x * gain / board.scale.x, 0.0, Balance.BOARD_W)
		_mouse_active = false
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION and event.pressed:
		_mouse_active = true
		if event.button_index == MOUSE_BUTTON_LEFT:
			board.smash()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_quake()
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		_mouse_active = true


func _quake() -> void:
	if board.use_quake():
		Game.buzz(150)


func _process(delta: float) -> void:
	_drive_paddle(delta)
	if Game.mode == Modes.RUSH and not _over and (board.state == Board.State.PLAY or board.state == Board.State.SERVE):
		_tick_rush(delta)
	if Game.autoplay_lazy:
		board.launch()
		board.paddle_target = 0.0
	if Game.autoplay and not _over:
		board.autopilot()
		if randf() < 0.02:
			board.smash()
		if board.quake_charged() and board.danger() > 0.5:
			_quake()
	_update_shake(delta)
	if _hitstop > 0.0:
		_hitstop -= delta
		if _hitstop <= 0.0:
			board.process_mode = Node.PROCESS_MODE_INHERIT
	var danger := board.danger()
	backdrop.danger = danger
	# The rays turn faster with the combo.
	backdrop.speed = lerpf(backdrop.speed, 0.08 + minf(board.combo, 40) * 0.02 + (0.8 if board.fever > 0.0 else 0.0), minf(delta * 2.0, 1.0))
	backdrop.fever = move_toward(backdrop.fever, 1.0 if board.fever > 0.0 else 0.0, delta * 3.0)
	post.set_shader_parameter("vignette", danger * danger * 0.6 if not _over else 0.0)
	var combo_heat := clampf(board.combo / 30.0, 0.0, 1.0)
	Audio.heat = 0.0 if _over else maxf(maxf(danger, combo_heat), 0.5 if board.effects.size() >= 2 else 0.0)
	if board.fever > 0.0 and not _over:
		Audio.heat = 1.0
	_update_cursor()


func _drive_paddle(delta: float) -> void:
	var axis := Input.get_axis("move_left", "move_right")
	if absf(axis) > 0.0:
		_mouse_active = false
		var target_speed := axis * Balance.PADDLE_SPEED
		_kb_speed = move_toward(_kb_speed, target_speed, Balance.PADDLE_ACCEL * delta)
		# Starting from where the paddle is, so it never runs ahead of itself.
		if absf(board.paddle_target - board.paddle_x) > Balance.BLOCK_W:
			board.paddle_target = board.paddle_x
		board.paddle_target = clampf(board.paddle_target + _kb_speed * delta, 0.0, Balance.BOARD_W)
	else:
		_kb_speed = 0.0
	if _mouse_active and Inputs.device == Inputs.Device.MOUSE:
		var mouse := board.get_local_mouse_position()
		board.paddle_target = clampf(mouse.x, 0.0, Balance.BOARD_W)


func _update_cursor() -> void:
	var playing := not _over and not _paused and board.state != Board.State.CLEARED
	var want := Input.MOUSE_MODE_HIDDEN if playing and Inputs.device == Inputs.Device.MOUSE else Input.MOUSE_MODE_VISIBLE
	if Input.mouse_mode != want:
		Input.mouse_mode = want


# --- feel ---------------------------------------------------------------------------------------

func add_shake(amount: float) -> void:
	_trauma = minf(_trauma + amount / 22.0, 1.0)
	if amount >= 7.0:
		_punch = minf(_punch + amount / 20.0, 1.0)


func _update_shake(delta: float) -> void:
	_trauma = maxf(_trauma - delta * 1.8, 0.0)
	_punch = move_toward(_punch, 0.0, delta * 4.0)
	var power := _trauma * _trauma * Game.shake_amount()
	# The punch zooms in round the middle of the board.
	var zoom := 1.0 + _punch * _punch * 0.035 * Game.shake_amount()
	var center := board.position + Vector2(Balance.BOARD_W, Balance.BOARD_H) * 0.5 * board.scale.x
	world.scale = Vector2(zoom, zoom)
	world.position = center - center * zoom + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * power * 24.0
	world.rotation = randf_range(-1, 1) * power * 0.012
	post.set_shader_parameter("aberration", power * 0.004)


func _on_hitstop(seconds: float) -> void:
	_hitstop = maxf(_hitstop, seconds)
	board.process_mode = Node.PROCESS_MODE_DISABLED


func flash(color: Color, amount: float) -> void:
	if not Game.flashes():
		amount *= 0.25
	if _flash_tween:
		_flash_tween.kill()
	post.set_shader_parameter("flash_color", color)
	_flash_tween = create_tween()
	_flash_tween.tween_method(func(v: float) -> void: post.set_shader_parameter("flash", v), amount, 0.0, 0.3)


## A shock wave rippling out over the screen from `at` (on the board).
func shock(at: Vector2, strength: float) -> void:
	var view := get_viewport().get_visible_rect().size
	var screen_at := (world.position + (board.position + at * board.scale.x) * world.scale.x) / view
	post.set_shader_parameter("shock_center", screen_at)
	if _shock_tween:
		_shock_tween.kill()
	_shock_tween = create_tween().set_parallel()
	_shock_tween.tween_method(func(v: float) -> void: post.set_shader_parameter("shock_radius", v), 0.0, 1.4, 0.7)
	_shock_tween.tween_method(func(v: float) -> void: post.set_shader_parameter("shock_strength", v), strength, 0.0, 0.7)


# --- floors -------------------------------------------------------------------------------------

func _on_floor_cleared() -> void:
	var demolished := level == Balance.FLOORS - 1
	Audio.play("cleared", 0.0)
	backdrop.bloom(1.0, 1.5)
	flash(Color.WHITE, 0.5)
	if demolished:
		hud.show_message("HAUS\nDEMOLISHED!", UI.GOLD, 2.2)
		if not Game.autoplay and not Game.autoplay_lazy:
			Game.demolished += 1
			Game.save()
	else:
		hud.show_message("FLOOR\nCLEARED!", Color("3dffb1"), 1.2)
	if Game.mode == Modes.RUSH:
		_add_time(Modes.RUSH_FLOOR_BONUS)
	await get_tree().create_timer(2.6 if demolished else 1.8).timeout
	if _over:
		return
	# Down through the floor: the glass cracks from the middle out and falls away, then the next one drops in.
	Audio.play("collapse", 0.0)
	add_shake(12.0)
	board.balls.clear()
	var crack := create_tween()
	crack.tween_property(board, "shatter", 0.5, 0.45).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	crack.tween_callback(func() -> void:
		for i in 40:
			var at := Vector2(randf() * Balance.BOARD_W, randf() * Balance.BOARD_H)
			board.particles.shards(at, board.theme["light"], 1, 1.4)
		add_shake(20.0)
		shock(Vector2(Balance.BOARD_W * 0.5, Balance.BOARD_H * 0.5), 1.0)
		Audio.play("boom", 0.0, 0.6))
	crack.tween_property(board, "shatter", 1.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# What is left of it fades as it falls, and the dust starts rushing past: you are falling too.
	crack.parallel().tween_property(board, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	crack.parallel().tween_property(backdrop, "rise_speed", 240.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await crack.finished
	if _over:
		return
	_fall_to_floor(level + 1)


# --- rush ---------------------------------------------------------------------------------------

func _tick_rush(delta: float) -> void:
	rush_left = maxf(rush_left - delta, 0.0)
	hud.rush_left = rush_left
	var second := ceili(rush_left)
	if second != _rush_second:
		_rush_second = second
		if second <= 10 and second > 0:
			Audio.play("tick", -2.0, 1.0 + (10 - second) * 0.05)
			hud.punch_clock()
	if rush_left <= 0.0:
		board.state = Board.State.OVER
		_game_over("TIME'S\nUP!")


func _add_time(seconds: float) -> void:
	rush_left += seconds
	hud.rush_left = rush_left
	hud.time_bonus(seconds)


## The end, the wall through or the clock run out: `title` is what the game over says.
func _game_over(title: String) -> void:
	if _over:
		return
	_over = true
	Game.buzz(250)
	Audio.play("game_over", 0.0)
	Audio.muffle(1.0, 1.5)
	Audio.heat = 0.0
	add_shake(16.0)
	flash(Color("ff2a2a"), 0.5)
	# Slow motion, the colour draining out (the original's grayscale), and the wall crumbles.
	Engine.time_scale = 0.3
	var gray := create_tween().set_ignore_time_scale()
	gray.tween_method(func(v: float) -> void: post.set_shader_parameter("gray", v), 0.0, 1.0, 1.2)
	var bricks := board.blocks()
	bricks.sort_custom(func(a: Block, b: Block) -> bool: return a.row > b.row)
	await get_tree().create_timer(0.6, true, false, true).timeout
	Engine.time_scale = 1.0
	var i := 0
	for b in bricks:
		if not is_inside_tree():
			return
		board._break(b, false)
		i += 1
		if i % 6 == 0:
			Audio.play("break", -8.0, randf_range(0.7, 0.9))
			await get_tree().process_frame
	var place := Game.add_score(board.score, level, board.best_combo, Game.mode)
	await get_tree().create_timer(0.6).timeout
	_show_overlay(GameOver.new(board, place, title))


# --- pausing ------------------------------------------------------------------------------------

func pause() -> void:
	if _over or _paused or board.state == Board.State.CLEARED:
		return
	_paused = true
	get_tree().paused = true
	Audio.play("pause", -2.0)
	Audio.muffle(0.7)
	var menu := PauseMenu.new()
	menu.resumed.connect(resume)
	_show_overlay(menu)


func resume() -> void:
	_paused = false
	get_tree().paused = false
	Audio.muffle(0.0)
	if _overlay:
		_overlay.queue_free()
		_overlay = null


func _show_overlay(layer: CanvasLayer) -> void:
	if _overlay:
		_overlay.queue_free()
	_overlay = layer
	add_child.call_deferred(layer)


func go_back() -> void:
	if _overlay and _overlay.has_method("go_back"):
		_overlay.go_back()
	elif not _over:
		pause()


func _notification(what: int) -> void:
	# The window losing focus (another app on the phone, alt-tab) pauses the game.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if board and board.state == Board.State.PLAY and not Game.autoplay and not Game.autoplay_lazy:
			pause()


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Engine.time_scale = 1.0
	Audio.muffle(0.0)
