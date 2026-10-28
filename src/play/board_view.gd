extends Node2D
## Draws the board: the walls round it, then shadows, blocks, pickups, the
## paddle, the balls and every particle, in that order, all in art pixels
## (PX units each) like the original's 4x sprites. The glass under it all is
## a shader (floor.gdshader) on a rect behind this, fed from here.

const PX := Balance.PX
const SHADOW := Color(0.0, 0.0, 0.0, 0.32)
const FLOOR_SHADER := preload("res://src/play/floor.gdshader")
const MAX_RIPPLES := 8
const MAX_LIGHTS := 8

var board: Board
var floor_rect: ColorRect
var _material: ShaderMaterial


func _ready() -> void:
	floor_rect = ColorRect.new()
	floor_rect.size = Vector2(Balance.BOARD_W, Balance.BOARD_H)
	floor_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_material = ShaderMaterial.new()
	_material.shader = FLOOR_SHADER
	floor_rect.material = _material
	floor_rect.show_behind_parent = true
	add_child(floor_rect)
	_material.set_shader_parameter("size", floor_rect.size)
	_material.set_shader_parameter("px", PX)
	_material.set_shader_parameter("death_y", Balance.DEATH_ROW * Balance.ROW_H)


func _process(_delta: float) -> void:
	if board.theme.is_empty():
		return
	var t := board.theme
	_material.set_shader_parameter("base", t["floor"])
	_material.set_shader_parameter("light", t["light"])
	_material.set_shader_parameter("pattern", int(t["pattern"]))
	_material.set_shader_parameter("clock", board.clock)
	_material.set_shader_parameter("danger", board.danger() if board.state != Board.State.CLEARED else 0.0)
	_material.set_shader_parameter("frost", clampf(board.effect(Pickups.Kind.FROST), 0.0, 1.0))
	_material.set_shader_parameter("fire", clampf(board.effect(Pickups.Kind.FIRE), 0.0, 1.0))
	_material.set_shader_parameter("shatter", board.shatter)
	var ripples := PackedVector4Array()
	for r: Dictionary in board.ripples.slice(-MAX_RIPPLES):
		ripples.append(Vector4(r["pos"].x, r["pos"].y, r["t"], r["strength"]))
	_material.set_shader_parameter("ripple_count", ripples.size())
	ripples.resize(MAX_RIPPLES)
	_material.set_shader_parameter("ripples", ripples)
	var lights := PackedVector2Array()
	for ball in board.balls.slice(0, MAX_LIGHTS):
		lights.append(ball.pos)
	_material.set_shader_parameter("light_count", lights.size())
	lights.resize(MAX_LIGHTS)
	_material.set_shader_parameter("lights", lights)


func _draw() -> void:
	if board.theme.is_empty():
		return
	_draw_walls()
	if board.effect(Pickups.Kind.SHIELD) > 0.0 or board.shield_flash > 0.0:
		_draw_shield()
	_draw_shadows()
	_draw_blocks()
	_draw_pickups()
	_draw_paddle()
	_draw_balls()
	_draw_rockets()
	board.particles.draw(self)
	_draw_bolts()


# --- the frame round the board ------------------------------------------------------------------

func _draw_walls() -> void:
	var t := board.theme
	var w := Balance.WALL
	var bw := Balance.BOARD_W
	var bh := Balance.BOARD_H
	var top: Color = (t["ray_b"] as Color).lightened(0.35)
	var face: Color = (t["ray_b"] as Color).lightened(0.12)
	var edge: Color = (t["light"] as Color)
	# The back wall (its face towards you, under the top lip), then the sides, all a block high.
	draw_rect(Rect2(-w, -w - Balance.BLOCK_DEPTH, bw + w * 2, w), top)
	draw_rect(Rect2(0, -Balance.BLOCK_DEPTH, bw, Balance.BLOCK_DEPTH), face.darkened(0.3))
	draw_rect(Rect2(-w, -w - Balance.BLOCK_DEPTH, bw + w * 2, PX), edge.lightened(0.3))
	for side in [-w, bw]:
		draw_rect(Rect2(side, -Balance.BLOCK_DEPTH - w, w, bh + w + Balance.BLOCK_DEPTH), top)
		draw_rect(Rect2(side + (w - PX if side < 0 else 0.0), -Balance.BLOCK_DEPTH, PX, bh + Balance.BLOCK_DEPTH), edge.lightened(0.2))
		draw_rect(Rect2(side, bh, w, Balance.BLOCK_DEPTH), face.darkened(0.2))
	# The open bottom: the floor's edge, and the drop.
	draw_rect(Rect2(-w, bh, bw + w * 2, PX), face.darkened(0.5))


func _draw_shield() -> void:
	var a := clampf(board.effect(Pickups.Kind.SHIELD), 0.0, 1.0)
	# Blinks as it runs out.
	if board.effect(Pickups.Kind.SHIELD) < 2.5 and fmod(board.clock, 0.25) < 0.1:
		a *= 0.3
	a = maxf(a, board.shield_flash)
	var y := Balance.BOARD_H - PX * 2.0
	var c := Color("6ad8ff")
	for i in 3:
		var glow := c
		glow.a = (0.5 - i * 0.15) * a
		draw_rect(Rect2(0, y - i * PX, Balance.BOARD_W, PX * (1 + i * 2)), glow)
	var bright := Color.WHITE.lerp(c, 0.3)
	bright.a = a
	var x := 0.0
	while x < Balance.BOARD_W:
		var wobble := sin(board.clock * 8.0 + x * 0.05) * PX * 0.5
		draw_rect(Rect2(x, y + wobble, PX * 3.0, PX), bright)
		x += PX * 4.0


# --- shadows ------------------------------------------------------------------------------------

## Light from the top left: everything casts down and to the right, further the higher it is.
func _shadow_offset(z: float) -> Vector2:
	z = minf(z, PX * 12.0)
	return Vector2(PX * 1.5 + z * 0.3, PX * 1.5 + z * 0.45)


func _draw_shadows() -> void:
	for b: Block in board.grid:
		if b == null:
			continue
		var p := b.position() + _shadow_offset(b.z + Balance.BLOCK_DEPTH * 0.5)
		var shadow := SHADOW
		if b.raining:
			# High up it's a faint, small smudge; it firms up as it falls.
			shadow.a *= clampf(1.0 - b.z / 900.0, 0.1, 1.0)
		draw_rect(Rect2(p, Vector2(Balance.BLOCK_W, Balance.ROW_H)), shadow)
	var pr := board.paddle_rect()
	var pz := board.paddle_z + _paddle_hop() + Balance.PADDLE_DEPTH
	draw_rect(Rect2(pr.position + _shadow_offset(pz), pr.size), SHADOW)
	for ball in board.balls:
		var s := Balance.BALL_R * 2.0
		var at := ball.pos + _shadow_offset(ball.z + PX * 3.0) - Vector2(s, s) * 0.5
		draw_rect(Rect2(at + Vector2(PX, 0), Vector2(s - PX * 2.0, s)), SHADOW)
		draw_rect(Rect2(at + Vector2(0, PX), Vector2(s, s - PX * 2.0)), SHADOW)
	for p: Dictionary in board.pickups:
		var size := Vector2(8, 7) * PX
		draw_rect(Rect2(p["pos"] + _shadow_offset(_pickup_z(p)) - size * 0.5, size), SHADOW)
	board.particles.draw_shadows(self, SHADOW)


# --- blocks -------------------------------------------------------------------------------------

func _draw_blocks() -> void:
	for b: Block in board.grid:
		if b:
			BlockArt.draw(self, b, b.position() + Vector2(b.shake, -b.z), board.clock)


# --- pickups ------------------------------------------------------------------------------------

func _pickup_z(p: Dictionary) -> float:
	return PX * 3.0 + (sin(p["t"] * 5.0) * 0.5 + 0.5) * PX * 3.0


func _draw_pickups() -> void:
	for p: Dictionary in board.pickups:
		var kind: Pickups.Kind = p["kind"]
		var info := Pickups.info(kind)
		var at: Vector2 = p["pos"] - Vector2(0, _pickup_z(p))
		var c: Color = info["color"]
		# A ring pulsing out of it, red for the bad ones.
		var pulse := fmod(p["t"] * 1.5, 1.0)
		var ring := c if not info.get("bad", false) else Color("ff2020")
		ring.a = (1.0 - pulse) * 0.8
		draw_arc(at, PX * (5.0 + pulse * 5.0), 0.0, TAU, 16, ring, PX * 0.75)
		var pop := clampf(p["t"] * 5.0, 0.0, 1.0)
		Pickups.draw_icon(self, kind, at, PX * (0.4 + 0.6 * pop) * (1.0 + 0.08 * sin(p["t"] * 10.0)))


# --- the paddle ---------------------------------------------------------------------------------

func _paddle_hop() -> float:
	if board.smash_time <= 0.0:
		return 0.0
	var t := 1.0 - board.smash_time / Balance.SMASH_TIME
	return sin(t * PI) * Balance.SMASH_HOP


func _draw_paddle() -> void:
	var r := board.paddle_rect()
	var squash := board.paddle_squash
	var w := r.size.x * (1.0 + squash * 0.08)
	var h := Balance.PADDLE_H * (1.0 - squash * 0.25)
	var depth := Balance.PADDLE_DEPTH
	var z := board.paddle_z + _paddle_hop() + PX * 2.0
	var x := board.paddle_x - w * 0.5
	var y := r.end.y - h - depth - z
	var body := Color("e8e8f0").lerp(Color.WHITE, board.paddle_flash)
	var accent: Color = board.theme["blocks"][0]
	if board.effect(Pickups.Kind.ROCKET) > 0.0:
		accent = Color("ff4545")
	elif board.effect(Pickups.Kind.FIRE) > 0.0:
		accent = Color("ff7a1a")
	if board.smash_time > 0.0:
		body = body.lerp(Color("fff23d"), 0.6)
	var dark := Color("26262e")
	# Outline, front face, top, then the ends in the floor's colour and a shine along the top.
	draw_rect(Rect2(x - PX, y - PX, w + PX * 2.0, h + depth + PX * 2.0), dark)
	draw_rect(Rect2(x, y + h, w, depth), body.darkened(0.45))
	draw_rect(Rect2(x, y, w, h), body)
	draw_rect(Rect2(x, y, PX * 3.0, h + depth), accent)
	draw_rect(Rect2(x + w - PX * 3.0, y, PX * 3.0, h + depth), accent)
	draw_rect(Rect2(x, y + h, PX * 3.0, depth), accent.darkened(0.4))
	draw_rect(Rect2(x + w - PX * 3.0, y + h, PX * 3.0, depth), accent.darkened(0.4))
	draw_rect(Rect2(x + PX * 3.0, y + PX, w - PX * 6.0, PX), Color(1, 1, 1, 0.8))
	# A ball about to land: the top lights up, the cue to smash.
	var window := board.smash_window()
	if window > 0.0 and board.smash_cooldown <= 0.0:
		var cue := Color("fff23d")
		cue.a = window * 0.9
		draw_rect(Rect2(x - PX, y - PX * 2.0, w + PX * 2.0, PX), cue)
	if board.quake_charged():
		# Charged with a quake: it hums.
		var hum := Color("ffb03b")
		hum.a = 0.35 + 0.25 * sin(board.clock * 10.0)
		draw_rect(Rect2(x - PX * 2.0, y - PX * 2.0, w + PX * 4.0, h + depth + PX * 4.0), hum, false, PX)


# --- balls --------------------------------------------------------------------------------------

func _ball_color(ball: Ball) -> Color:
	var c := Color.WHITE
	if board.fever > 0.0:
		c = Color.from_hsv(fmod(board.clock * 1.5, 1.0), 0.6, 1.0)
	elif board.effect(Pickups.Kind.FIRE) > 0.0:
		c = Color("ffb03b").lerp(Color("ff4a1a"), 0.5 + 0.5 * sin(board.clock * 20.0))
	elif ball.smashed:
		c = Color("fff23d")
	elif board.effect(Pickups.Kind.OVERDRIVE) > 0.0:
		c = Color("3dffb1")
	elif board.effect(Pickups.Kind.ZAP) > 0.0:
		c = Color("fff8a0")
	return c.lerp(Color.WHITE, ball.flash)


func _draw_balls() -> void:
	var lift := PX * 3.0
	for ball in board.balls:
		var c := _ball_color(ball)
		# The trail: squares shrinking and fading behind it.
		var n := ball.trail.size()
		for i in n:
			var t := float(i + 1) / (n + 1)
			var s := Balance.BALL_R * 2.0 * t * 0.8
			var tc := c
			if board.fever > 0.0:
				# A rainbow streaming out behind.
				tc = Color.from_hsv(fmod(board.clock * 1.5 + (n - i) * 0.07, 1.0), 0.8, 1.0)
			tc.a = t * (0.5 if not ball.smashed and board.fever <= 0.0 else 0.8)
			draw_rect(Rect2(ball.trail[i] - Vector2(0, lift + ball.z) - Vector2(s, s) * 0.5, Vector2(s, s)), tc)
		var at := ball.pos - Vector2(0, lift + ball.z)
		# Squashed along the way it was hit, without turning the pixels.
		var turn := Transform2D(ball.squash_angle, Vector2.ZERO)
		var squash := turn * Transform2D.IDENTITY.scaled(Vector2(ball.squash, 1.0 / ball.squash)) * turn.affine_inverse()
		squash.origin = at
		draw_set_transform_matrix(squash)
		# The original's ball: six art pixels round, with a dark rim and a shine.
		var dark := Color("26262e")
		draw_rect(Rect2(-2 * PX, -3 * PX, 4 * PX, 6 * PX), dark)
		draw_rect(Rect2(-3 * PX, -2 * PX, 6 * PX, 4 * PX), dark)
		draw_rect(Rect2(-2 * PX, -2 * PX, 4 * PX, 4 * PX), c)
		draw_rect(Rect2(-1 * PX, -3 * PX + PX, 2 * PX, PX), c)
		draw_set_transform(at, 0.0, Vector2.ONE)
		draw_rect(Rect2(-2 * PX, -2 * PX + PX * 3.0, 4 * PX, PX), c.darkened(0.3))
		draw_rect(Rect2(-PX, -PX - PX * 0.0, PX, PX), Color.WHITE)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_rockets() -> void:
	for rocket: Dictionary in board.rockets:
		var p: Vector2 = rocket["pos"] - Vector2(0, PX * 4.0)
		draw_rect(Rect2(p + Vector2(-PX, -PX * 3.0), Vector2(PX * 2.0, PX * 5.0)), Color("e8e8f0"))
		draw_rect(Rect2(p + Vector2(-PX, -PX * 3.0), Vector2(PX * 2.0, PX)), Color("ff4545"))
		draw_rect(Rect2(p + Vector2(-PX * 2.0, PX), Vector2(PX * 4.0, PX)), Color("ff4545"))
		var flame := Color("ffd23d") if fmod(board.clock * 30.0, 1.0) < 0.5 else Color("ff7a1a")
		draw_rect(Rect2(p + Vector2(-PX * 0.5, PX * 2.0), Vector2(PX, PX * 2.0)), flame)


func _draw_bolts() -> void:
	for bolt: Dictionary in board.bolts:
		var a: float = 1.0 - bolt["t"] / 0.25
		var glow := Color("fff23d")
		glow.a = a * 0.4
		var core := Color(1, 1, 0.85, a)
		var points: PackedVector2Array = bolt["points"]
		var lifted := PackedVector2Array()
		for p in points:
			lifted.append(p - Vector2(0, Balance.BLOCK_DEPTH))
		draw_polyline(lifted, glow, PX * 2.5)
		draw_polyline(lifted, core, PX * 0.75)
