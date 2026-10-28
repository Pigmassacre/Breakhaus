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
	_draw_laser()
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
		# A pixel up or down, never part of one.
		var wobble := roundf(sin(board.clock * 8.0 + x * 0.05) * 0.75) * PX
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
		if board.arriving:
			break
		var s := Balance.BALL_R * 2.0
		var at := ball.pos + _shadow_offset(ball.z + PX * 3.0) - Vector2(s, s) * 0.5
		draw_rect(Rect2(at + Vector2(PX, 0), Vector2(s - PX * 2.0, s)), SHADOW)
		draw_rect(Rect2(at + Vector2(0, PX), Vector2(s, s - PX * 2.0)), SHADOW)
	for p: Dictionary in board.pickups:
		Pickups.draw_shadow(self, p["kind"], p["pos"] + _shadow_offset(_pickup_z(p)), _pickup_scale(p), SHADOW)
	board.particles.draw_shadows(self, SHADOW)


# --- blocks -------------------------------------------------------------------------------------

func _draw_blocks() -> void:
	for b: Block in board.grid:
		if b and not (board.arriving and b.raining):
			BlockArt.draw(self, b, b.position() + Vector2(b.shake, -b.z), board.clock)


# --- pickups ------------------------------------------------------------------------------------

func _pickup_z(p: Dictionary) -> float:
	return PX * 3.0 + (sin(p["t"] * 5.0) * 0.5 + 0.5) * PX * 3.0


## The pickup's size: always one art pixel to one of its own (the ring round it does the pulsing).
func _pickup_scale(_p: Dictionary) -> float:
	return PX


func _draw_pickups() -> void:
	for p: Dictionary in board.pickups:
		var kind: Pickups.Kind = p["kind"]
		var info := Pickups.info(kind)
		var at: Vector2 = p["pos"] - Vector2(0, _pickup_z(p))
		var c: Color = info["color"]
		_draw_loot_beam(p, at)
		# A ring pulsing out of it, red for the bad ones.
		var pulse := fmod(p["t"] * 1.5, 1.0)
		var ring := c if not info.get("bad", false) else Color("ff2020")
		ring.a = (1.0 - pulse) * 0.8
		Pixels.ring(self, at, 5.0 + pulse * 5.0, 1, ring)
		# A rare one has a gold ring as well, out of step with the first.
		if Pickups.rarity(kind) == Pickups.Rarity.RARE:
			var late := fmod(p["t"] * 1.5 + 0.5, 1.0)
			Pixels.ring(self, at, 5.0 + late * 5.0, 1, Color(UI.GOLD, (1.0 - late) * 0.9))
		Pickups.draw_icon(self, kind, at, _pickup_scale(p))
		# Sparkles round a rare one, a pixel each, going round.
		if Pickups.rarity(kind) == Pickups.Rarity.RARE:
			for i in 3:
				var a: float = p["t"] * 3.0 + i * TAU / 3.0
				var twinkle := 0.5 + 0.5 * sin(p["t"] * 12.0 + i * 2.0)
				Pixels.square(self, at + Vector2(cos(a) * PX * 8.0, sin(a) * PX * 5.0), 1, Color(Color.WHITE.lerp(UI.GOLD, twinkle), twinkle))


## The loot beam: a column of light up out of an uncommon (teal) or rare (gold) pickup, in bands that
## climb it and fade out at the top; a rare one's is taller, wider and brighter.
func _draw_loot_beam(p: Dictionary, at: Vector2) -> void:
	var rarity := Pickups.rarity(p["kind"])
	if rarity == Pickups.Rarity.COMMON:
		return
	var color: Color = Pickups.RARITY_COLOR[rarity]
	var rare := rarity == Pickups.Rarity.RARE
	var height := (34 if rare else 20)
	var grow := clampf(p["t"] * 4.0, 0.0, 1.0)
	var base := Pixels.snap(at)
	for i in int(height * grow):
		var t := float(i) / height
		var band := 0.6 + 0.4 * sin(p["t"] * 10.0 - i * 0.6)
		var a := (1.0 - t) * band * (0.95 if rare else 0.75)
		var y := base.y - (i + 1) * PX
		draw_rect(Rect2(base.x - PX, y, PX * 3.0, PX), Color(color, a * 0.5))
		draw_rect(Rect2(base.x, y, PX, PX), Color(color.lerp(Color.WHITE, 0.6), a))
		if rare:
			draw_rect(Rect2(base.x - PX * 2.0, y, PX * 5.0, PX), Color(color, a * 0.2))


## The laser: a beam of whole pixels straight up from the paddle to what it is burning,
## a white core in a red glow, flickering, and a flare where it meets the block.
func _draw_laser() -> void:
	if board.laser_end < 0.0:
		return
	var x := Pixels.snap(Vector2(board.laser_x(), 0.0)).x
	var top := snappedf(board.laser_end, PX)
	var bottom := snappedf(Balance.PADDLE_Y - board.paddle_z - _paddle_hop(), PX)
	if bottom <= top:
		return
	var flicker := 0.75 + 0.25 * sin(board.clock * 70.0)
	var red := Color("ff4f6a")
	draw_rect(Rect2(x - PX * 2.0, top, PX * 5.0, bottom - top), Color(red, 0.18 * flicker))
	draw_rect(Rect2(x - PX, top, PX * 3.0, bottom - top), Color(red, 0.6 * flicker))
	draw_rect(Rect2(x, top, PX, bottom - top), Color(1.0, 0.94, 0.96))
	Pixels.ring(self, Vector2(x + PX * 0.5, top), 2.0 + flicker * 1.5, 1, Color(Color.WHITE, 0.8))
	Pixels.square(self, Vector2(x + PX * 0.5, top), 3, Color(red.lerp(Color.WHITE, 0.6), flicker))


# --- the paddle ---------------------------------------------------------------------------------

func _paddle_hop() -> float:
	if board.smash_time <= 0.0:
		return 0.0
	var t := 1.0 - board.smash_time / Balance.SMASH_TIME
	return sin(t * PI) * Balance.SMASH_HOP


func _draw_paddle() -> void:
	if board.arriving:
		return
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
		if board.arriving:
			break
		var c := _ball_color(ball)
		# The trail: squares shrinking and fading behind it.
		var n := ball.trail.size()
		for i in n:
			var t := float(i + 1) / (n + 1)
			var s := roundi(Balance.BALL_R * 2.0 * t * 0.8 / PX)
			var tc := c
			if board.fever > 0.0:
				# A rainbow streaming out behind.
				tc = Color.from_hsv(fmod(board.clock * 1.5 + (n - i) * 0.07, 1.0), 0.8, 1.0)
			tc.a = t * (0.5 if not ball.smashed and board.fever <= 0.0 else 0.8)
			Pixels.square(self, ball.trail[i] - Vector2(0, lift + ball.z), s, tc)
		_draw_ball(ball, ball.pos - Vector2(0, lift + ball.z), c)


## The original's ball: six art pixels round, with a dark rim, a shine and a shaded bottom. Just hit,
## it squashes the pixel-art way, into a shape of its own (8 by 4 off a floor or ceiling, 4 by 8 off
## a wall) rather than by stretching its pixels.
func _draw_ball(ball: Ball, at: Vector2, c: Color) -> void:
	var dark := Color("26262e")
	var shape := 0
	if ball.squash < 0.85:
		var n := Vector2.from_angle(ball.squash_angle)
		shape = 1 if absf(n.y) >= absf(n.x) else 2
	# Each: the rim as two crossed rects, the inside, the shaded row and the shine, in pixels from the middle.
	var parts: Array = [
		[Rect2(-2, -3, 4, 6), Rect2(-3, -2, 6, 4), Rect2(-2, -2, 4, 4), Rect2(-2, 1, 4, 1), Rect2(-1, -1, 1, 1)],
		[Rect2(-3, -2, 6, 4), Rect2(-4, -1, 8, 2), Rect2(-3, -1, 6, 2), Rect2(-3, 0, 6, 1), Rect2(-2, -1, 1, 1)],
		[Rect2(-2, -3, 4, 6), Rect2(-1, -4, 2, 8), Rect2(-1, -3, 2, 6), Rect2(-1, 2, 2, 1), Rect2(-1, -2, 1, 1)],
	][shape]
	var colors := [dark, dark, c, c.darkened(0.3), Color.WHITE]
	for i in parts.size():
		var r: Rect2 = parts[i]
		draw_rect(Rect2(at + r.position * PX, r.size * PX), colors[i])


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
		var glow_drawn := {}
		var core_drawn := {}
		for i in lifted.size() - 1:
			Pixels.line(self, lifted[i], lifted[i + 1], glow, 3, glow_drawn)
		for i in lifted.size() - 1:
			Pixels.line(self, lifted[i], lifted[i + 1], core, 1, core_drawn)
