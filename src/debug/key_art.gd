extends Node
## Pictures for the store page (itch/tools/plates.py), drawn by the game
## itself without its UI, off screen at any size, at a set moment on a fixed
## clock (run with `--fixed-fps 60`), so the same arguments give the same
## picture.
##
## `--scene=keyart --size=WxH --out=x.png`: the play screen, the HUD hidden.
##   `--at=3` the second it is saved at, `--burst=8` that many frames from
##   there (x_00.png, x_01.png, ...) to pick the moment from; `--seed=1`;
##   `--floor=2` the floor (its colours, its blocks), `--fever` in Fever;
##   `--bare` just what is on it (no floor or walls); `--empty` no blocks on it (for the logo to be the wall);
##   `--board=x,y,zoom` the board's middle on the picture and its zoom
##   (`--no-board` for none), `--rays=x,y` where the rays turn round
##   (`--no-rays`: transparent); `--wall=0.5` how far down the wall has
##   come (0 to 1); `--smash=x,y,degrees@t` a smashed ball sent off from
##   there (on the board) at that second, the paddle hopping under it;
##   `--drop=fireball@x,y` a pickup hanging there (on the board).
## `--scene=logo --square=40 --out=x.png`: the logo (Logo.gd), landed, a
##   square of a letter that many pixels; `--at=` as above.
## `--scene=words --text=... --size=64 --color=ffffff --out=x.png`: a line of
##   the UI's lettering (UI.label: Bungee with its drop), `--outline=10` as
##   over the board.
## `--scene=haus --scale=3 --floor=2 --out=x.png`: the HUD's haus (Tower).
## Everything but keyart is cropped to what it draws, on transparent.

var _view := SubViewport.new()
var _args := {}
var _play: Node
var _at := 3.0
var _clock := 0.0
var _burst := 1
var _saved := 0
var _crop := true
var _events: Array = []


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		var kv := arg.trim_prefix("--").split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else ""
	seed(int(_args.get("seed", "1")))
	_at = float(_args.get("at", "3"))
	_burst = int(_args.get("burst", "1"))
	Game.settings["shake"] = 0.0
	_view.transparent_bg = true
	# Crisp art pixels, as the game's own window draws them (a SubViewport doesn't take the project's filter).
	_view.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_view)
	# To watch it in the window.
	var watch := TextureRect.new()
	watch.texture = _view.get_texture()
	watch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	watch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	watch.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(watch)
	match _args.get("scene", "keyart"):
		"keyart":
			_crop = false
			_keyart()
		"logo":
			_logo()
		"words":
			_words()
		"haus":
			_haus()
	_events.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])


func _keyart() -> void:
	_view.size = _vec2i(_args.get("size", "1920x1080"), "x")
	Game.autoplay = true
	var level := int(_args.get("floor", "0"))
	_play = (load("res://src/play/play.gd") as GDScript).new()
	_play.setup({"floor": level})
	_view.add_child(_play)
	_play.hud.visible = false
	# The floor again, from the seed, so its rows are the same every time.
	var board: Board = _play.board
	board.rng.seed = int(_args.get("seed", "1"))
	board.row_rng.seed = int(_args.get("seed", "1"))
	_play._start_floor(level)
	if _args.has("no-rays"):
		_play.backdrop.visible = false
		# The screen's effects too, which would fill in the transparency.
		for layer in _play.get_children():
			if layer is CanvasLayer and layer.layer == 5:
				layer.visible = false
	if _args.has("no-board"):
		_play.world.visible = false
	if _args.has("board"):
		var b := _floats(_args["board"])
		_play._board_zoom = b[2]
		_play._board_at = (Vector2(b[0], b[1]) - Vector2(Balance.BOARD_W, Balance.BOARD_H) * 0.5 * b[2]).round()
		_play._place_board()
	_play.backdrop.center = _vec2(_args["rays"]) if _args.has("rays") else Vector2(_view.size) * 0.5
	if _args.has("bare"):
		board._view.bare = true
		board._view.floor_rect.visible = false
		board.balls.clear()
	if _args.has("empty"):
		board.grid.fill(null)
		board.rows_queued = 0
		board.wave_time = 1.0e9
		board._find_lowest()
	if _args.has("wall"):
		_events.append([1.0, _bring_wall_down.bind(float(_args["wall"]))])
	if _args.has("fever"):
		_events.append([1.5, func() -> void:
			board._start_fever()
			board.combo = Balance.COMBO_STEP * Balance.COMBO_MULT_MAX])
	if _args.has("smash"):
		var parts: PackedStringArray = _args["smash"].split("@")
		_events.append([float(parts[1]), _smash.bind(_floats(parts[0]))])
	if _args.has("drop"):
		_events.append([_at - 1.0, _drop.bind(_args["drop"])])


## The wall moved down to `amount` of the way to the line, as if the waves had come.
func _bring_wall_down(amount: float) -> void:
	var board: Board = _play.board
	var rows := int(roundf((Balance.DEATH_ROW - 2 - board.lowest_row) * amount))
	for i in rows:
		board._wave()


func _smash(s: Array) -> void:
	var board: Board = _play.board
	board.balls.clear()
	var ball := Ball.new()
	ball.pos = Vector2(s[0], s[1])
	ball.speed = Balance.SMASH_SPEED
	ball.pierce = Balance.SMASH_PIERCE
	ball.smashed = true
	ball.set_direction(Vector2.UP.rotated(deg_to_rad(s[2])))
	board.balls.append(ball)
	board.state = Board.State.PLAY
	board.paddle_x = ball.pos.x
	board.paddle_target = ball.pos.x
	board.paddle_squash = 1.0
	board.paddle_flash = 1.0
	board.particles.spray(ball.pos, Vector2.UP, Color("fff23d"), 14)


func _drop(what: String) -> void:
	var board: Board = _play.board
	for one in what.split(" "):
		var parts := one.split("@")
		var kind: int = Pickups.Kind.get(parts[0].to_upper(), -1)
		if kind >= 0:
			board.pickups.append({"kind": kind, "pos": _vec2(parts[1]), "t": 0.0})


func _logo() -> void:
	var logo := Logo.new()
	logo.settled = true
	logo.square = float(_args.get("square", "40"))
	logo.position = Vector2(64, 64)
	_view.add_child(logo)
	_view.size = Vector2i(logo.custom_minimum_size) + Vector2i(128, 128)


func _words() -> void:
	var size := int(_args.get("size", "64"))
	var l := UI.label(_args.get("text", "BREAKHAUS"), 8, Color(_args.get("color", "fff4fb")))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_constant_override("shadow_offset_y", maxi(roundi(size / 11.0), 2))
	if _args.has("outline"):
		UI.outline(l, int(_args["outline"]))
	l.position = Vector2(64, 64)
	_view.add_child(l)
	_view.size = Vector2i(l.get_combined_minimum_size()) + Vector2i(128, 128)


func _haus() -> void:
	var tower := Tower.new()
	tower.level = int(_args.get("floor", "0"))
	var scale := float(_args.get("scale", "3"))
	tower.size = Vector2(240, 760)
	tower.scale = Vector2.ONE * scale
	tower.position = Vector2(0, 80) * scale
	_view.add_child(tower)
	_view.size = Vector2i((tower.size + Vector2(0, 120)) * scale)


func _process(delta: float) -> void:
	_clock += delta
	while not _events.is_empty() and _clock >= _events[0][0]:
		var event: Array = _events.pop_front()
		event[1].call()
	if _clock >= _at and _saved < _burst:
		_save()


func _save() -> void:
	var index := _saved
	_saved += 1
	await RenderingServer.frame_post_draw
	var image := _view.get_texture().get_image()
	if _crop:
		image = image.get_region(image.get_used_rect())
	var out: String = _args.get("out", "res://shots/keyart.png")
	if _burst > 1:
		out = out.get_basename() + "_%02d.png" % index
	image.save_png(out)
	print("Saved ", out)
	if index == _burst - 1:
		get_tree().quit()


static func _vec2i(text: String, sep := ",") -> Vector2i:
	var p := text.split(sep)
	return Vector2i(int(p[0]), int(p[1]))


static func _vec2(text: String) -> Vector2:
	var p := text.split(",")
	return Vector2(float(p[0]), float(p[1]))


static func _floats(text: String) -> Array:
	return Array(text.split(",")).map(func(t: String) -> float: return float(t))
