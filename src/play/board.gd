class_name Board
extends Node2D
## The playing field: the grid of blocks, the paddle, the balls, the pickups
## and everything they do to each other. Its origin is the field's top left
## corner, inside the walls; it is BOARD_W by BOARD_H, y down.
##
## Everything here has a height, z, on top of where it stands on the board,
## and casts a shadow (the original game's fake 3D): blocks rain in from
## high up, hop when something lands near them, and chunks of them bounce.
##
## It runs the game but leaves the telling of it (the HUD, the shake, the
## sounds of a floor ending) to whoever owns it, through its signals.

signal scored(points: int, at: Vector2)
signal combo_changed(combo: int, multiplier: int)
signal combo_ended(combo: int)
signal fever_started
signal synergy_started(id: String)
signal swept
signal missed
signal shake(amount: float)
signal hitstop(seconds: float)
signal flashed(color: Color, amount: float)
signal shocked(at: Vector2, strength: float)
signal message(text: String, color: Color)
signal picked_up(kind: Pickups.Kind)
signal launched
signal wave_came
signal quake_ready
signal quake_drained(amount: float)
signal floor_cleared
signal saved
signal smash_landed
## The block that cleared the board just broke, at `at`: the floor's last (`big`), or a clean sweep's.
signal final_blow(at: Vector2, big: bool)
signal overrun(block: Block)

enum State { INTRO, SERVE, PLAY, CLEARED, OVER }

const W := Balance.BOARD_W
const H := Balance.BOARD_H
const COLS := Balance.COLS
const ROWS := Balance.ROWS

var state := State.INTRO
var level := 0
var theme := {}
var rng := RandomNumberGenerator.new()
## The rows come from their own generator, so a seeded one (the Daily Haus) gives everyone the same
## rows however differently they play.
var row_rng := RandomNumberGenerator.new()
## The day's twist (Modes.TWISTS) or nothing, and the waves sped up or slowed down by the mode.
var twist := {}
var wave_scale := 1.0

## The blocks, COLS by ROWS, row by row from the top: a Block or null.
var grid: Array = []
var balls: Array[Ball] = []
var particles := Particles.new()
## Pickups falling: {"kind", "pos", "t"}.
var pickups: Array = []
## Rockets flying up: {"pos", "t"}.
var rockets: Array = []
## Lightning, for a moment: {"points": PackedVector2Array, "t"}.
var bolts: Array = []
## Blasts waiting to go off (TNT in a chain): {"col", "row", "t"}.
var blasts: Array = []
## A fuse's blast along its row, for a moment: {"row", "t"}.
var beams: Array = []
## Rings on the glass: {"pos", "t", "strength"} (the floor shader draws them).
var ripples: Array = []
## The quake's blocks, waiting their turn to go: {"block", "t"}.
var _quake_blocks: Array = []

# The paddle: its middle, how wide it is (and is becoming), how fast it is going.
var paddle_x := W * 0.5
var paddle_w := Balance.PADDLE_W
var paddle_target_w := Balance.PADDLE_W
var paddle_vx := 0.0
var paddle_z := 0.0
var paddle_flash := 0.0
var paddle_squash := 0.0
## Seconds left of a smash hop, and before the next one.
var smash_time := 0.0
var smash_cooldown := 0.0
## How long this run's smash hop lasts (the Sweet Spot perk stretches it).
var smash_length := Balance.SMASH_TIME
## Where the controls want the paddle (set every frame by whoever drives it).
var paddle_target := W * 0.5

# The wall coming down.
var wave_time := Balance.WAVE_TIME
var wave_timer := 0.0
var rows_queued := 0
var rows_made := 0
var lowest_row := -1

# Score and combo.
var score := 0
var combo := 0
var combo_timer := 0.0
## Seconds of Fever left, and whether this combo has had its Fever.
var fever := 0.0
var _fever_spent := false
var best_combo := 0
var blocks_broken := 0
var quake := 0.0
## This floor's misses and smashes landed (for the challenges).
var misses := 0
var smashes := 0

## Seconds left of each pickup that lasts (Pickups.Kind -> seconds).
var effects := {}
## The synergies running now (Pickups.SYNERGIES' ids), to tell when a new one starts.
var _synergies_on := {}
## The run's perks (Perks.INFO's ids -> how many), and whether this floor's Safety Net has gone.
var perks := {}
var _net_used := false
var rocket_timer := 0.0
## Rocket Barrage: rockets still to go, and the time to the next.
var barrage_left := 0
var barrage_timer := 0.0
## Laser: where its beam ends (the bottom of the block it is burning, or the top), -1 when off.
var laser_end := -1.0
## Mega Laser's beams beside the middle one: where each ends (-1: none), left then right.
var laser_sides := [-1.0, -1.0]
var _laser_tick := 0.0
var _laser_hum := 0.0
var shield_flash := 0.0
## The game's own clock, for anything that pulses.
var clock := 0.0
## A demo board plays itself and never ends (the title's).
var demo := false
## The floor breaking up under it all after it is cleared, 0 to 1 (the floor shader's).
var shatter := 0.0
## Falling into place on a new floor: what is still up in the air (blocks to rain in, the paddle and
## ball to drop) isn't drawn until it has landed.
var arriving := false

var _view: Node2D


func _ready() -> void:
	rng.randomize()
	row_rng.randomize()
	grid.resize(COLS * ROWS)
	_view = preload("res://src/play/board_view.gd").new()
	_view.board = self
	# Drawn even while the board is held still (a hitstop, a fall between floors).
	_view.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_view)


# --- the grid -----------------------------------------------------------------------------------

func at(col: int, row: int) -> Block:
	if col < 0 or col >= COLS or row < 0 or row >= ROWS:
		return null
	return grid[row * COLS + col]


func put(col: int, row: int, block: Block) -> void:
	grid[row * COLS + col] = block


func blocks() -> Array[Block]:
	var out: Array[Block] = []
	for b: Block in grid:
		if b:
			out.append(b)
	return out


func block_count() -> int:
	var n := 0
	for b in grid:
		if b:
			n += 1
	return n


func multiplier() -> int:
	return mini(1 + combo / Balance.COMBO_STEP, Balance.COMBO_MULT_MAX)


func effect(kind: Pickups.Kind) -> float:
	return effects.get(kind, 0.0)


func perk(id: String) -> int:
	return perks.get(id, 0)


func add_perk(id: String) -> void:
	perks[id] = perk(id) + 1
	smash_length = Balance.SMASH_TIME * (1.0 + 0.5 * perk("sweet_spot"))
	paddle_target_w = _paddle_size()


## The paddle's width with the pickups running (wider or narrower) and the Wide Load perk.
func _paddle_size() -> float:
	var w := Balance.PADDLE_W
	if effect(Pickups.Kind.WIDE) > 0.0:
		w = Balance.PADDLE_W_WIDE
	elif effect(Pickups.Kind.NARROW) > 0.0:
		w = Balance.PADDLE_W_NARROW
	return w * (1.0 + 0.15 * perk("wide_load"))


func quake_charged() -> bool:
	return quake >= Balance.QUAKE_CHARGE


## How close the wall is to the line: 0 safe, 1 one row off.
func danger() -> float:
	if lowest_row < 0:
		return 0.0
	var rows_left := Balance.DEATH_ROW - 1 - lowest_row
	return clampf(1.0 - float(rows_left) / Balance.DANGER_ROWS, 0.0, 1.0)


func rows_left() -> int:
	return Balance.DEATH_ROW - 1 - lowest_row if lowest_row >= 0 else Balance.DEATH_ROW


# --- floors -------------------------------------------------------------------------------------

## Sets up floor `n`: its blocks raining in, the paddle and a ball dropping on to it.
func start_floor(n: int) -> void:
	level = n
	theme = Floors.theme(n)
	wave_time = Floors.wave_time(n) * wave_scale * float(twist.get("wave", 1.0)) * (1.0 + 0.12 * perk("slow_wall"))
	_net_used = false
	misses = 0
	smashes = 0
	wave_timer = 0.0
	grid.fill(null)
	balls.clear()
	pickups.clear()
	rockets.clear()
	blasts.clear()
	beams.clear()
	bolts.clear()
	_quake_blocks.clear()
	effects.clear()
	_synergies_on.clear()
	paddle_target_w = _paddle_size()
	shatter = 0.0
	rows_made = 0
	var start := Floors.start_rows(n)
	rows_queued = Floors.queue_rows(n)
	if Game.short_floors:
		start = 1
		rows_queued = 0
	# The top rows left empty to start with, so the first waves have room.
	_rain_rows(start, 2, 900.0)
	_find_lowest()
	paddle_z = 900.0
	var ball := Ball.new()
	ball.held = true
	ball.z = 1100.0
	balls.append(ball)
	state = State.INTRO
	_view.queue_redraw()


## Drops `count` new rows of the floor's in from high up, the lowest at row `top + count - 1`, the bottom one landing first.
func _rain_rows(count: int, top: int, height: float) -> void:
	var delay := 0.15
	for r in range(count - 1, -1, -1):
		var row := Floors.make_row(row_rng, level, rows_made, twist)
		rows_made += 1
		for c in COLS:
			if row[c] == null:
				continue
			var b := Block.new().setup(row[c], c, top + r)
			b.z = height + rng.randf() * 200.0
			b.hop_delay = delay + rng.randf() * 0.12
			b.raining = true
			if effect(Pickups.Kind.FROST) > 0.0:
				b.frozen = true
			put(c, top + r, b)
		delay += 0.09


## The intro done: the ball sits on the paddle until launched.
func serve() -> void:
	state = State.SERVE


func launch() -> void:
	if state != State.SERVE:
		return
	for b in balls:
		if b.held:
			b.held = false
			b.speed = Balance.BALL_SPEED
			b.set_direction(Vector2(clampf(paddle_vx * 0.0006, -0.5, 0.5), -1.0))
	state = State.PLAY
	# Triple Trouble: every serve splits in three.
	if int(twist.get("balls", 1)) > 1:
		_split_balls()
	# Extra Ball: a spare goes up beside it.
	if perk("extra_ball") > 0 and balls.size() < Balance.MAX_BALLS:
		var spare := Ball.new()
		spare.pos = balls[0].pos
		spare.speed = Balance.BALL_SPEED
		spare.set_direction(balls[0].direction().rotated(0.5))
		spare.fix_angle()
		balls.append(spare)
	launched.emit()


# --- the paddle ---------------------------------------------------------------------------------

func paddle_rect() -> Rect2:
	return Rect2(paddle_x - paddle_w * 0.5, Balance.PADDLE_Y, paddle_w, Balance.PADDLE_H)


## How soon a ball lands on the paddle: 1 if it is about to (now is the time to smash), down to 0.
func smash_window() -> float:
	var best := 0.0
	for ball in balls:
		if ball.held or ball.vel.y <= 0.0 or ball.pos.y > Balance.PADDLE_Y:
			continue
		if absf(ball.pos.x - paddle_x) > paddle_w * 0.5 + Balance.BALL_R * 2.0:
			continue
		var speed := ball.vel.y * (Balance.OVERDRIVE_SPEED if effect(Pickups.Kind.OVERDRIVE) > 0.0 else 1.0)
		var eta := (Balance.PADDLE_Y - Balance.BALL_R - ball.pos.y) / speed
		best = maxf(best, 1.0 - clampf(eta / (smash_length * 1.6), 0.0, 1.0))
	return best


func smash() -> void:
	if state == State.SERVE:
		launch()
		return
	if state != State.PLAY:
		return
	# A Magnet's catch is let go on a smash.
	var let_go := false
	for ball in balls:
		if ball.held:
			_release(ball)
			let_go = true
	if let_go or smash_cooldown > 0.0:
		return
	smash_time = smash_length
	smash_cooldown = Balance.SMASH_COOLDOWN


func _update_paddle(delta: float) -> void:
	var half := paddle_w * 0.5
	var target := clampf(paddle_target, half, W - half)
	var before := paddle_x
	paddle_x = lerpf(paddle_x, target, 1.0 - exp(-Balance.PADDLE_FOLLOW * delta))
	paddle_vx = (paddle_x - before) / maxf(delta, 0.0001)
	paddle_w = move_toward(paddle_w, paddle_target_w, delta * 300.0)
	paddle_x = clampf(paddle_x, paddle_w * 0.5, W - paddle_w * 0.5)
	smash_time = maxf(smash_time - delta, 0.0)
	smash_cooldown = maxf(smash_cooldown - delta, 0.0)
	paddle_flash = maxf(paddle_flash - delta * 4.0, 0.0)
	paddle_squash = move_toward(paddle_squash, 0.0, delta * 6.0)
	if paddle_z > 0.0 and state != State.INTRO:
		paddle_z = 0.0
	# Rockets, two at a time from its ends.
	if effect(Pickups.Kind.ROCKET) > 0.0 and state == State.PLAY:
		rocket_timer -= delta
		if rocket_timer <= 0.0:
			rocket_timer = Balance.ROCKET_RATE
			for side in [-1.0, 1.0]:
				rockets.append({"pos": Vector2(paddle_x + side * (half - Balance.PX * 3.0), Balance.PADDLE_Y - Balance.PX * 2.0), "t": 0.0})
			Audio.play("rocket", -6.0, rng.randf_range(0.9, 1.1))
	if state == State.PLAY:
		_update_barrage(delta)
	if effect(Pickups.Kind.LASER) > 0.0 and state == State.PLAY:
		_update_laser(delta)
	else:
		laser_end = -1.0
		laser_sides = [-1.0, -1.0]
	# Pickups it catches.
	var catch := paddle_rect().grow(Balance.PX * 2.0)
	for p: Dictionary in pickups.duplicate():
		if catch.has_point(p["pos"]):
			_collect(p)


# --- the game loop ------------------------------------------------------------------------------

func _process(delta: float) -> void:
	clock += delta
	_update_paddle(delta)
	_update_blocks(delta)
	if state == State.PLAY:
		_update_waves(delta)
		_update_effects(delta)
		combo_timer -= delta
		if combo > 0 and combo_timer <= 0.0:
			_end_combo()
		fever = maxf(fever - delta, 0.0)
	if state == State.PLAY or state == State.SERVE or state == State.INTRO:
		_update_balls(delta)
	_update_pickups(delta)
	_update_rockets(delta)
	_update_blasts(delta)
	particles.update(delta, Rect2(0, 0, W, H))
	for bolt: Dictionary in bolts.duplicate():
		bolt["t"] += delta
		if bolt["t"] > 0.25:
			bolts.erase(bolt)
	for beam: Dictionary in beams.duplicate():
		beam["t"] += delta
		if beam["t"] > 0.35:
			beams.erase(beam)
	for ripple: Dictionary in ripples.duplicate():
		ripple["t"] += delta
		if ripple["t"] > 1.6:
			ripples.erase(ripple)
	shield_flash = maxf(shield_flash - delta * 3.0, 0.0)
	_view.queue_redraw()


func _update_blocks(delta: float) -> void:
	var rumble := state == State.PLAY and wave_timer > wave_time - Balance.WAVE_RUMBLE and rows_left() <= Balance.DANGER_ROWS + 2 \
		and effect(Pickups.Kind.FROST) <= 0.0
	var landed := 0
	for b: Block in grid:
		if b == null:
			continue
		if b.hop_delay > 0.0:
			b.hop_delay -= delta
			if b.hop_delay <= 0.0 and not b.raining:
				b.z_velocity = maxf(b.z_velocity, b.hop_power)
		if b.hop_delay <= 0.0:
			if b.raining:
				b.z_velocity -= 5200.0 * delta
			elif b.z > 0.0 or b.z_velocity != 0.0:
				b.z_velocity -= 2600.0 * delta
			b.z += b.z_velocity * delta
			if b.z <= 0.0:
				if b.raining:
					b.raining = false
					landed += 1
					b.z_velocity = 140.0
					b.flash = 0.6
				else:
					b.z_velocity = 0.0
				b.z = maxf(b.z, 0.0)
		b.slide = move_toward(b.slide, 0.0, delta * Balance.ROW_H * 5.0)
		b.flash = maxf(b.flash - delta * 5.0, 0.0)
		b.bump = maxf(b.bump - delta * 5.0, 0.0)
		if b.kind == Block.Kind.COIN and not b.raining and state == State.PLAY:
			b.age += delta
		if b.fuse >= 0.0 and state == State.PLAY:
			_tick_fuse(b, delta)
		b.shake = (rng.randf_range(-1.0, 1.0) * Balance.PX * 0.5) if rumble else move_toward(b.shake, 0.0, delta * 40.0)
		if b.burning > 0.0:
			_burn(b, delta)
	if landed > 0:
		Audio.play("chip", -14.0 + minf(landed, 6), rng.randf_range(0.8, 1.2))
	if state == State.INTRO:
		var settled := true
		for b: Block in grid:
			if b and (b.raining or b.hop_delay > 0.0):
				settled = false
				break
		if paddle_z > 0.0:
			paddle_z = maxf(paddle_z - delta * 2400.0, 0.0)
			if paddle_z == 0.0:
				paddle_squash = 1.0
				Audio.play("drop", -6.0)
				shake.emit(4.0)
		if settled and paddle_z <= 0.0 and balls.size() > 0 and balls[0].z <= 0.0:
			serve()


func _update_waves(delta: float) -> void:
	if effect(Pickups.Kind.FROST) > 0.0:
		return
	wave_timer += delta * (Balance.HASTE_SPEED if effect(Pickups.Kind.HASTE) > 0.0 else 1.0)
	if wave_timer >= wave_time:
		wave_timer = 0.0
		_wave()


## The wall comes down a row, and a new row (if the floor has any left) drops in at the top.
func _wave() -> void:
	_grow_moss()
	for r in range(ROWS - 1, -1, -1):
		for c in COLS:
			var b := at(c, r)
			if b == null:
				continue
			put(c, r, null)
			if r + 1 >= ROWS:
				continue
			b.row = r + 1
			b.slide = Balance.ROW_H
			put(c, r + 1, b)
	if rows_queued > 0:
		_new_row()
	_find_lowest()
	# A ball the wall came down on is pushed out under it.
	for ball in balls:
		var cell := _cell_of(ball.pos)
		var b := at(cell.x, cell.y)
		if b:
			ball.pos.y = (b.row + 1) * Balance.ROW_H + Balance.BALL_R + 1.0
			if ball.vel.y < 0.0:
				ball.vel.y = -ball.vel.y
	Audio.play("drop", -2.0, rng.randf_range(0.85, 1.0))
	shake.emit(3.0)
	wave_came.emit()
	if lowest_row >= Balance.DEATH_ROW and not demo:
		_overrun()
		return
	if demo and lowest_row >= Balance.DEATH_ROW - 2:
		# The title's board never loses: it clears a few rows off the bottom instead.
		for c in COLS:
			for r in range(lowest_row - 3, lowest_row + 1):
				if at(c, r):
					_break(at(c, r), false)
	if rows_left() <= Balance.CRITICAL_ROWS and not demo:
		Audio.play("danger", -2.0)
		message.emit("DANGER!", Color("ff3d3d"))


func _new_row() -> void:
	var row := Floors.make_row(row_rng, level, rows_made, twist)
	rows_made += 1
	rows_queued -= 1
	for c in COLS:
		if row[c] == null:
			continue
		var b := Block.new().setup(row[c], c, 0)
		b.z = 600.0 + rng.randf() * 120.0
		b.raining = true
		b.hop_delay = rng.randf() * 0.15
		if effect(Pickups.Kind.FROST) > 0.0:
			b.frozen = true
		put(c, 0, b)


func _grow_moss() -> void:
	var grown: Array[Vector2i] = []
	for b in blocks():
		if b.kind != Block.Kind.MOSS or rng.randf() > 0.5:
			continue
		var dirs := [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(0, -1)]
		dirs.shuffle()
		for d: Vector2i in dirs:
			var c := b.col + d.x
			var r := b.row + d.y
			if c >= 0 and c < COLS and r >= 0 and r < ROWS and at(c, r) == null and not grown.has(Vector2i(c, r)):
				grown.append(Vector2i(c, r))
				break
	for cell in grown:
		var nb := Block.new().setup({"kind": Block.Kind.MOSS, "hp": 1, "color": Block.kind_color(Block.Kind.MOSS, Color.WHITE)}, cell.x, cell.y)
		nb.z = 30.0
		nb.flash = 1.0
		put(cell.x, cell.y, nb)
	if not grown.is_empty():
		Audio.play("grow", -6.0, rng.randf_range(0.9, 1.1))


func _find_lowest() -> void:
	lowest_row = -1
	for r in range(ROWS - 1, -1, -1):
		for c in COLS:
			if at(c, r):
				lowest_row = r
				return


func _overrun() -> void:
	state = State.OVER
	var culprit: Block = null
	for c in COLS:
		if at(c, lowest_row):
			culprit = at(c, lowest_row)
			break
	overrun.emit(culprit)


func _update_effects(delta: float) -> void:
	for kind: Pickups.Kind in effects.keys():
		effects[kind] -= delta
		if effects[kind] <= 0.0:
			effects.erase(kind)
			_effect_ended(kind)
	# A synergy starting is an event of its own.
	for s: Dictionary in Pickups.SYNERGIES:
		var on := synergy(s["id"])
		if on and not _synergies_on.has(s["id"]):
			_synergies_on[s["id"]] = true
			message.emit(String(s["name"]).to_upper() + "!", s["color"])
			Audio.play("fanfare", -4.0, 1.2)
			Audio.play("charged", -6.0, 1.5)
			flashed.emit(s["color"], 0.25)
			shocked.emit(paddle_rect().get_center(), 0.5)
			hitstop.emit(Balance.HITSTOP_BIG)
			particles.spray(paddle_rect().get_center(), Vector2.UP, s["color"], 24, 12.0)
			synergy_started.emit(s["id"])
		elif not on:
			_synergies_on.erase(s["id"])


## Whether synergy `id` is running: both its pickups are (Cluster Bombs: Blast Ball, and three balls).
func synergy(id: String) -> bool:
	for s: Dictionary in Pickups.SYNERGIES:
		if s["id"] != id:
			continue
		if effect(s["a"]) <= 0.0:
			return false
		if s["b"] == Pickups.Kind.MULTI:
			return balls.size() >= 3
		return effect(s["b"]) > 0.0
	return false


## The synergies running now, as Pickups.SYNERGIES has them.
func active_synergies() -> Array:
	return Pickups.SYNERGIES.filter(func(s: Dictionary) -> bool: return _synergies_on.has(s["id"]))


func _effect_ended(kind: Pickups.Kind) -> void:
	match kind:
		Pickups.Kind.WIDE, Pickups.Kind.NARROW:
			paddle_target_w = _paddle_size()
		Pickups.Kind.FROST:
			for b in blocks():
				if b.frozen:
					b.frozen = false
					b.flash = 0.5
		Pickups.Kind.MAGNET:
			for ball in balls:
				if ball.held and state == State.PLAY:
					_release(ball)
		Pickups.Kind.OVERDRIVE:
			for ball in balls:
				ball.speed = minf(ball.speed, Balance.BALL_SPEED_MAX)
				ball.set_direction(ball.direction())


# --- balls --------------------------------------------------------------------------------------

func _update_balls(delta: float) -> void:
	for ball in balls.duplicate():
		ball.flash = maxf(ball.flash - delta * 5.0, 0.0)
		ball.squash = move_toward(ball.squash, 1.0, delta * 5.0)
		if ball.z > 0.0:
			ball.z = maxf(ball.z - delta * 1500.0, 0.0)
		if ball.held:
			ball.pos = Vector2(paddle_x + ball.held_offset, Balance.PADDLE_Y - Balance.BALL_R - 1.0)
			if state == State.PLAY:
				ball.hold_time -= delta
				if ball.hold_time <= 0.0:
					_release(ball)
			continue
		_move_ball(ball, delta)
		if ball.trail.size() == 0 or ball.trail[ball.trail.size() - 1].distance_to(ball.pos) > Balance.PX * 2.0:
			ball.trail.append(ball.pos)
			if ball.trail.size() > 10:
				ball.trail.remove_at(0)
		if effect(Pickups.Kind.FIRE) > 0.0 and rng.randf() < 0.6:
			particles.embers(ball.pos, 1, 10.0)
	for i in range(balls.size() - 1, -1, -1):
		if balls[i].dead:
			balls.remove_at(i)


func _move_ball(ball: Ball, delta: float) -> void:
	var speed := ball.speed * (Balance.OVERDRIVE_SPEED if effect(Pickups.Kind.OVERDRIVE) > 0.0 else 1.0)
	var distance := speed * delta
	var steps := maxi(1, ceili(distance / Balance.BALL_STEP))
	var step := distance / steps
	ball.idle += delta
	ball.portal_cd = maxf(ball.portal_cd - delta, 0.0)
	if ball.spin != 0.0:
		ball.vel = ball.vel.rotated(ball.spin * delta)
		ball.spin *= exp(-Balance.SPIN_DECAY * delta)
		if absf(ball.spin) < 0.05:
			ball.spin = 0.0
		ball.fix_angle()
	for i in steps:
		ball.pos += ball.direction() * step
		_collide_walls(ball)
		if ball.dead:
			return
		_collide_paddle(ball)
		_collide_blocks(ball)
		_collide_pickups(ball)
		_collide_balls(ball)
	# A ball that has gone a long while without meeting anything is nudged off its line.
	if ball.idle > 6.0:
		ball.idle = 0.0
		ball.set_direction(ball.direction().rotated(rng.randf_range(-0.3, 0.3)))
		ball.fix_angle()


func _collide_walls(ball: Ball) -> bool:
	var r := Balance.BALL_R
	var hit := false
	if ball.pos.x < r:
		ball.pos.x = r
		ball.vel.x = absf(ball.vel.x)
		hit = true
	elif ball.pos.x > W - r:
		ball.pos.x = W - r
		ball.vel.x = -absf(ball.vel.x)
		hit = true
	if ball.pos.y < r:
		ball.pos.y = r
		ball.vel.y = absf(ball.vel.y)
		hit = true
	elif ball.pos.y > H - r:
		ball.pos.y = H - r
		ball.vel.y = -absf(ball.vel.y)
		_bottom(ball)
		return true
	if hit:
		ball.spin *= -0.7
		ball.fix_angle()
		_ball_hit(ball, ball.direction(), 0.6)
		Audio.play("wall", -8.0, rng.randf_range(0.95, 1.1))
	return hit


## A ball at the bottom: off the shield, or gone (if there are others) or a miss, either way draining
## the quake.
func _bottom(ball: Ball) -> void:
	if effect(Pickups.Kind.SHIELD) > 0.0 or demo:
		shield_flash = 1.0
		ball.fix_angle()
		_ball_hit(ball, Vector2.UP, 0.8)
		Audio.play("shield_hit", -4.0, rng.randf_range(0.95, 1.1))
		ripples.append({"pos": ball.pos, "t": 0.0, "strength": 0.6})
		if synergy("tesla"):
			_tesla(ball.pos)
		return
	# Safety Net: the floor's first miss bounces back off the bottom.
	if perk("safety_net") > 0 and not _net_used and balls.size() == 1:
		_net_used = true
		shield_flash = 1.0
		ball.fix_angle()
		_ball_hit(ball, Vector2.UP, 1.0)
		Audio.play("shield", -2.0, 1.2)
		ripples.append({"pos": ball.pos, "t": 0.0, "strength": 1.0})
		message.emit("SAVED!", Color("6ad8ff"))
		saved.emit()
		return
	if quake > 0.0:
		quake_drained.emit(minf(quake, Balance.QUAKE_MISS))
		quake = maxf(quake - Balance.QUAKE_MISS, 0.0)
	if balls.size() > 1:
		ball.dead = true
		particles.burst(ball.pos, Color.WHITE, 8, 0.6)
		Audio.play("break", -6.0, 0.6)
		return
	# The last ball: a miss. The ball comes back slower, the combo is gone and the wall gains.
	ball.speed = Balance.BALL_SPEED
	ball.smashed = false
	ball.pierce = 0
	ball.spin = 0.0
	ball.fix_angle()
	particles.burst(ball.pos, Color("ff3d3d"), 10, 0.7)
	ripples.append({"pos": ball.pos, "t": 0.0, "strength": 1.0})
	if combo > 0:
		_end_combo()
	wave_timer = minf(wave_timer + wave_time * Balance.MISS_PUSH, wave_time - 0.3)
	misses += 1
	Audio.play("miss", -2.0)
	shake.emit(6.0)
	flashed.emit(Color("ff2a2a"), 0.25)
	missed.emit()


func _collide_paddle(ball: Ball) -> void:
	if paddle_z > 0.0:
		return
	var rect := paddle_rect()
	var r := Balance.BALL_R
	var closest := Vector2(clampf(ball.pos.x, rect.position.x, rect.end.x), clampf(ball.pos.y, rect.position.y, rect.end.y))
	if ball.pos.distance_squared_to(closest) > r * r:
		return
	if ball.pos.y > rect.get_center().y:
		_paddle_underside(ball, rect)
		return
	if ball.vel.y <= 0.0:
		return
	# Where on the paddle it landed decides the angle, and the paddle's own speed bends it.
	var offset := clampf((ball.pos.x - paddle_x) / (paddle_w * 0.5), -1.0, 1.0)
	# A touch of chance, so a ball can't settle into the same path for ever.
	var angle := offset * Balance.PADDLE_MAX_ANGLE + paddle_vx * Balance.PADDLE_ENGLISH + rng.randf_range(-0.05, 0.05)
	angle = clampf(angle, -Balance.PADDLE_MAX_ANGLE * 1.1, Balance.PADDLE_MAX_ANGLE * 1.1)
	ball.pos.y = rect.position.y - r - 0.5
	ball.idle = 0.0
	var smashed := smash_time > 0.0
	if smashed:
		ball.speed = Balance.SMASH_SPEED
		ball.pierce = Balance.SMASH_PIERCE
		ball.smashed = true
		smash_time = 0.0
		Audio.play("smash", 0.0, rng.randf_range(0.95, 1.05))
		hitstop.emit(Balance.HITSTOP_BIG)
		shake.emit(7.0)
		shocked.emit(ball.pos, 0.5)
		message.emit("SMASH!", Color("fff23d"))
		smashes += 1
		smash_landed.emit()
		particles.spray(ball.pos, Vector2.UP, Color("fff23d"), 14)
	else:
		ball.speed = minf(ball.speed + Balance.BALL_SPEED_PADDLE, Balance.BALL_SPEED_MAX)
		ball.smashed = false
		Audio.play("paddle", -4.0, 0.9 + (ball.speed - Balance.BALL_SPEED) / Balance.BALL_SPEED_MAX * 0.4)
	ball.set_direction(Vector2.UP.rotated(angle))
	ball.fix_angle()
	# Spin: the paddle's own speed sets the ball turning the way the paddle went.
	ball.spin = clampf(paddle_vx * Balance.SPIN_FROM_PADDLE, -Balance.SPIN_MAX, Balance.SPIN_MAX)
	if absf(ball.spin) > Balance.SPIN_MAX * 0.6:
		Audio.play("release", -10.0, 1.6)
	paddle_flash = 1.0
	paddle_squash = 1.0 if smashed else 0.6
	_ball_hit(ball, ball.direction(), 1.0)
	# The Magnet catches it (not a smash, which goes straight off).
	if effect(Pickups.Kind.MAGNET) > 0.0 and not smashed:
		ball.held = true
		ball.held_offset = clampf(ball.pos.x - paddle_x, -paddle_w * 0.5, paddle_w * 0.5)
		ball.hold_time = Balance.MAGNET_HOLD
		Audio.play("shield_hit", -8.0, 1.4)


## A ball meeting the paddle from below (back up off the bottom under it, or the paddle run over it):
## knocked back down and out towards the nearer end, so a ball let under the paddle costs another
## miss instead of coming up through it for free. One met side on is knocked out sideways.
func _paddle_underside(ball: Ball, rect: Rect2) -> void:
	var r := Balance.BALL_R
	var side := signf(ball.pos.x - paddle_x)
	if side == 0.0:
		side = -1.0 if rng.randf() < 0.5 else 1.0
	if ball.pos.x < rect.position.x or ball.pos.x > rect.end.x:
		ball.pos.x = rect.end.x + r + 0.5 if side > 0.0 else rect.position.x - r - 0.5
		ball.vel.x = absf(ball.vel.x) * side
	else:
		ball.pos.y = rect.end.y + r + 0.5
		ball.set_direction(Vector2(side * cos(Balance.PADDLE_UNDER_ANGLE), sin(Balance.PADDLE_UNDER_ANGLE)))
	ball.fix_angle()
	paddle_flash = 0.5
	paddle_squash = 0.4
	_ball_hit(ball, ball.direction(), 0.6)
	Audio.play("paddle", -6.0, 0.7)


func _collide_blocks(ball: Ball) -> void:
	var r := Balance.BALL_R
	var c0 := floori((ball.pos.x - r) / Balance.BLOCK_W)
	var c1 := floori((ball.pos.x + r) / Balance.BLOCK_W)
	var r0 := floori((ball.pos.y - r) / Balance.ROW_H)
	var r1 := floori((ball.pos.y + r) / Balance.ROW_H)
	var best: Block = null
	var best_depth := 0.0
	var best_normal := Vector2.ZERO
	for row in range(r0, r1 + 1):
		for col in range(c0, c1 + 1):
			var b := at(col, row)
			if b == null or b.raining:
				continue
			var rect := Rect2(col * Balance.BLOCK_W, row * Balance.ROW_H, Balance.BLOCK_W, Balance.ROW_H)
			var closest := Vector2(clampf(ball.pos.x, rect.position.x, rect.end.x), clampf(ball.pos.y, rect.position.y, rect.end.y))
			var d := ball.pos - closest
			var dist := d.length()
			if dist >= r:
				continue
			var normal: Vector2
			if dist < 0.001:
				# Inside it: out the nearest side.
				var left := ball.pos.x - rect.position.x
				var right := rect.end.x - ball.pos.x
				var top := ball.pos.y - rect.position.y
				var bottom := rect.end.y - ball.pos.y
				var least := minf(minf(left, right), minf(top, bottom))
				normal = Vector2.LEFT if least == left else Vector2.RIGHT if least == right else Vector2.UP if least == top else Vector2.DOWN
			else:
				normal = d / dist
				# On a corner that has a block beside it, it's really that side's face.
				if absf(normal.x) > 0.01 and absf(normal.y) > 0.01:
					var side_x := at(col + int(signf(normal.x)), row) != null
					var side_y := at(col, row + int(signf(normal.y))) != null
					if side_x and not side_y:
						normal = Vector2(0, signf(normal.y))
					elif side_y and not side_x:
						normal = Vector2(signf(normal.x), 0)
			var depth := r - dist
			if best == null or depth > best_depth:
				best = b
				best_depth = depth
				best_normal = normal
	if best == null:
		return
	ball.idle = 0.0
	if best.kind == Block.Kind.PORTAL:
		if ball.portal_cd > 0.0:
			return
		var partner := _partner(best)
		if partner:
			_warp(ball, best, partner)
			return
	var fire := effect(Pickups.Kind.FIRE) > 0.0
	# Fire and Fever both go straight through all but steel (and bumpers, which always kick back).
	var hot := (fire or fever > 0.0) and best.kind != Block.Kind.STEEL and best.kind != Block.Kind.BUMPER
	var damage := (2 if (fire or fever > 0.0 or ball.smashed) else 1) + perk("heavy_ball")
	var breaks := best.frozen or best.hp <= damage or hot
	var through := (breaks and (ball.pierce > 0 or hot)) or best.kind == Block.Kind.ICE
	if best.kind == Block.Kind.BUMPER:
		through = false
		# Off its middle, like a round pinball bumper, and faster.
		var away := (ball.pos - best.center()).normalized()
		best_normal = Vector2(away.x, away.y * 2.0).normalized()
		ball.speed = minf(ball.speed + Balance.BUMPER_KICK, Balance.BALL_SPEED_MAX)
		var out := ball.vel.bounce(best_normal) if ball.vel.dot(best_normal) < 0.0 else ball.vel
		ball.vel = out.normalized().lerp(best_normal, 0.5).normalized() * ball.speed
		ball.spin *= -0.7
		ball.pos += best_normal * (best_depth + 0.5)
		ball.fix_angle()
	elif not through:
		if ball.vel.dot(best_normal) < 0.0:
			ball.vel = ball.vel.bounce(best_normal)
			ball.spin *= -0.7
		ball.pos += best_normal * (best_depth + 0.5)
		ball.fix_angle()
	elif ball.pierce > 0:
		ball.pierce -= 1
	if fire and best.kind != Block.Kind.STEEL:
		best.burning = maxf(best.burning, 2.0)
	_hit_block(best, damage, ball)
	_ball_hit(ball, best_normal if not through else ball.direction(), 0.8)
	if effect(Pickups.Kind.ZAP) > 0.0:
		_zap(best.center())
	if effect(Pickups.Kind.BLAST) > 0.0:
		_blast(best.col, best.row)


func _collide_pickups(ball: Ball) -> void:
	for p: Dictionary in pickups.duplicate():
		if ball.pos.distance_to(p["pos"]) < Balance.BALL_R + Balance.PICKUP_SIZE * 0.5:
			_collect(p)


## Balls glance off one another.
func _collide_balls(ball: Ball) -> void:
	for other in balls:
		if other == ball or other.held or other.dead:
			continue
		var d := ball.pos - other.pos
		var min_d := Balance.BALL_R * 2.0
		if d.length_squared() >= min_d * min_d or d == Vector2.ZERO:
			continue
		var n := d.normalized()
		ball.pos = other.pos + n * min_d
		if ball.vel.dot(n) < 0.0:
			ball.vel = ball.vel.bounce(n)
		if other.vel.dot(-n) < 0.0:
			other.vel = other.vel.bounce(-n)
		ball.fix_angle()
		other.fix_angle()


## The ball's own reaction to any hit: a flash, a squash, a little spray.
func _ball_hit(ball: Ball, normal: Vector2, strength: float) -> void:
	ball.flash = 1.0
	ball.squash = 1.0 - 0.35 * strength
	ball.squash_angle = normal.angle()
	particles.spray(ball.pos, normal, Color.WHITE, int(3 * strength) + 1, 8.0)


# --- blocks breaking ----------------------------------------------------------------------------

func _hit_block(b: Block, damage: int, ball: Ball = null) -> void:
	if b.dead:
		return
	b.flash = 1.0
	b.shake = Balance.PX * 1.5
	if b.kind == Block.Kind.FUSE and not b.frozen:
		# The first hit lights it (a blast's, with a short fuse); a ball meeting it lit sets it off.
		if b.fuse < 0.0:
			b.fuse = Balance.FUSE_TIME if ball else Balance.FUSE_CHAIN
			Audio.play("burn", -4.0, 1.4)
			return
		if ball == null:
			b.fuse = minf(b.fuse, Balance.FUSE_CHAIN)
			return
		b.hp = 0
	if b.kind == Block.Kind.BUMPER:
		b.bump = 1.0
		Audio.play("shield_hit", -4.0, rng.randf_range(1.5, 1.8))
		_add_score(Balance.SCORE_BUMP, b.center())
	if b.frozen:
		b.hp = 0
	else:
		b.hp -= damage
	# The ripple: blocks nearby hop, the nearest highest and first (the original game's).
	var power := 0.4 + (ball.speed / Balance.BALL_SPEED_MAX * 0.6 if ball else 0.6)
	_ripple(b.center(), Balance.BLOCK_W * (2.5 + power * 2.0), 260.0 * power)
	if b.hp <= 0:
		_break(b)
	else:
		Audio.play("clang" if b.kind == Block.Kind.STEEL else "chip", -4.0, rng.randf_range(0.9, 1.15))
		particles.burst(b.center(), b.color, 3, 0.5)


func _ripple(center: Vector2, reach: float, power: float) -> void:
	for b: Block in grid:
		if b == null or b.raining:
			continue
		var d := b.center().distance_to(center)
		if d > reach:
			continue
		var p := power * (1.0 - d / reach)
		if p > b.hop_power or b.hop_delay <= 0.0:
			b.hop_power = p
			b.hop_delay = d / 1400.0 + 0.001


## Takes a block off the board, with everything that goes with it. `scores` is false for the title's tidying.
func _break(b: Block, scores := true) -> void:
	if b.dead:
		return
	b.dead = true
	put(b.col, b.row, null)
	var center := b.center()
	var shaded := b.color
	if b.frozen:
		particles.shards(center, Color("bfeaff"), 10)
		Audio.play("freeze", -6.0, rng.randf_range(1.0, 1.3))
	particles.burst(center, shaded, 12 if b.kind != Block.Kind.STEEL else 18, 1.0)
	ripples.append({"pos": center, "t": 0.0, "strength": 0.35})
	if not scores:
		return
	blocks_broken += 1
	combo += 1
	combo_timer = Balance.COMBO_TIME * (1.0 + 0.5 * perk("long_fuse"))
	best_combo = maxi(best_combo, combo)
	combo_changed.emit(combo, multiplier())
	# Rising with the combo: the original's break, and a note higher each time.
	Audio.play("break", -6.0, rng.randf_range(0.95, 1.05))
	Audio.play_take("combo", mini(combo - 1, Audio.takes("combo") - 1), -7.0 + minf(combo * 0.2, 3.0))
	if multiplier() == Balance.COMBO_MULT_MAX and not _fever_spent and not demo:
		_start_fever()
	elif combo > 0 and combo % 10 == 0:
		message.emit("%d COMBO!" % combo, Color("fff23d"))
		Audio.play("fanfare", -6.0)
	var points := Balance.SCORE_BLOCK * b.max_hp
	if b.kind == Block.Kind.GOLD:
		points = Balance.SCORE_GOLD * (1 + perk("gold_digger"))
		Audio.play("coin", -2.0)
		particles.spray(center, Vector2.UP, Color("ffe066"), 16, 10.0)
	elif b.kind == Block.Kind.COIN:
		points = b.coin_value() * (1 + perk("gold_digger"))
		Audio.play("coin", -2.0, 0.8 + float(points) / Balance.COIN_MAX * 0.6)
		particles.spray(center, Vector2.UP, Color("ffd23d"), 6 + points / 50, 10.0)
	elif b.kind == Block.Kind.ICE:
		# The crack runs on into the ice touching it.
		Audio.play("freeze", -8.0, rng.randf_range(1.2, 1.5))
		particles.shards(center, Color("dff6ff"), 6)
		for d: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
			var n := at(b.col + d.x, b.row + d.y)
			if n and n.kind == Block.Kind.ICE and not n.dead:
				_quake_blocks.append({"block": n, "t": 0.06})
	elif b.kind == Block.Kind.FUSE:
		_row_blast(b.row)
	_add_score(points, center)
	var was_charged := quake_charged()
	quake = minf(quake + (1.0 + combo * 0.04) * (1.0 + 0.4 * perk("quick_quake")), Balance.QUAKE_CHARGE)
	if quake_charged() and not was_charged:
		quake_ready.emit()
		Audio.play("charged", -2.0)
	hitstop.emit(Balance.HITSTOP_BREAK if combo < 12 else Balance.HITSTOP_BREAK * 1.6)
	shake.emit(1.5 + minf(combo * 0.1, 2.5))
	if b.carries_pickup or rng.randf() < Balance.DROP_CHANCE * float(twist.get("drop", 1.0)) * (1.0 + 0.5 * perk("lucky")):
		_drop_pickup(center)
	if b.kind == Block.Kind.TNT:
		blasts.append({"col": b.col, "row": b.row, "t": 0.08})
	_find_lowest()
	_check_cleared(center)


func _add_score(points: int, at_pos: Vector2) -> void:
	var mult := multiplier() * (1.0 + level * Balance.SCORE_FLOOR_MULT)
	if effect(Pickups.Kind.OVERDRIVE) > 0.0:
		mult *= 2.0
	if fever > 0.0:
		mult *= 2.0
	mult *= float(twist.get("score", 1.0))
	var total := int(round(points * mult))
	score += total
	scored.emit(total, at_pos)


func _end_combo() -> void:
	if combo >= 10:
		combo_ended.emit(combo)
	combo = 0
	fever = 0.0
	_fever_spent = false
	combo_changed.emit(0, 1)


## Every ball in play splits in three.
func _split_balls() -> void:
	var new_balls: Array[Ball] = []
	for ball in balls:
		if ball.held:
			continue
		for side in [-1.0, 1.0]:
			if balls.size() + new_balls.size() >= Balance.MAX_BALLS:
				break
			var b := Ball.new()
			b.pos = ball.pos
			b.speed = ball.speed
			b.set_direction(ball.direction().rotated(side * 0.45))
			b.fix_angle()
			b.flash = 1.0
			new_balls.append(b)
	balls.append_array(new_balls)


func _start_fever() -> void:
	fever = Balance.FEVER_TIME + 4.0 * perk("hot_streak")
	_fever_spent = true
	message.emit("FEVER!", Color("ff3dff"))
	Audio.play("fanfare", -2.0)
	Audio.play("charged", -4.0, 1.3)
	hitstop.emit(Balance.HITSTOP_BIG)
	shake.emit(8.0)
	flashed.emit(Color("ff8af0"), 0.3)
	fever_started.emit()


func _check_cleared(at_pos := Vector2(W * 0.5, H * 0.35)) -> void:
	if state != State.PLAY or block_count() > 0:
		return
	if not demo:
		final_blow.emit(at_pos, rows_queued <= 0)
	if rows_queued > 0:
		# Swept clean with more to come: a big bonus, and the next rows all rain in at once.
		_add_score(Balance.SCORE_SWEEP, Vector2(W * 0.5, H * 0.35))
		message.emit("CLEAN SWEEP!", Color("3dffb1"))
		swept.emit()
		Audio.play("fanfare", -2.0)
		hitstop.emit(Balance.HITSTOP_BIG)
		shake.emit(6.0)
		rows_queued = maxi(rows_queued - Balance.SWEEP_ROWS, 0)
		_rain_rows(Balance.SWEEP_ROWS, 0, 700.0)
		wave_timer = 0.0
		_find_lowest()
		return
	if demo:
		start_floor(level)
		serve()
		launch()
		return
	state = State.CLEARED
	_add_score(Balance.SCORE_FLOOR, Vector2(W * 0.5, H * 0.35))
	for ball in balls:
		ball.vel = Vector2.ZERO
	floor_cleared.emit()


func _update_blasts(delta: float) -> void:
	for blast: Dictionary in blasts.duplicate():
		blast["t"] -= delta
		if blast["t"] > 0.0:
			continue
		blasts.erase(blast)
		_explode(blast["col"], blast["row"])


## A fuse going off: a blast the length of its row, everything in it taking a beating.
func _row_blast(row: int) -> void:
	for c in COLS:
		var b := at(c, row)
		if b:
			_hit_block(b, 3)
	# Big Bang: the rows either side take a knock too.
	if perk("big_bang") > 0:
		for r in [row - 1, row + 1]:
			for c in COLS:
				var b := at(c, r)
				if b:
					_hit_block(b, 1)
	var y := (row + 0.5) * Balance.ROW_H
	beams.append({"row": row, "t": 0.0})
	for i in 8:
		particles.burst(Vector2((i + 0.5) * W / 8.0, y), Color("ff6a3d"), 4, 1.0, 10.0)
	particles.smoke(Vector2(W * 0.5, y), 6, 10.0)
	Audio.play("boom", 0.0, 0.8)
	Audio.play("zap", -4.0, 0.6)
	shake.emit(9.0)
	hitstop.emit(Balance.HITSTOP_BIG)
	flashed.emit(Color("ffb08a"), 0.2)


func _tick_fuse(b: Block, delta: float) -> void:
	var before := b.fuse
	b.fuse -= delta
	# A tick every quarter second, the sparks flying.
	if floori(before * 4.0) != floori(b.fuse * 4.0):
		Audio.play("tick", -8.0, 1.6)
		b.flash = 0.6
	if rng.randf() < 0.5:
		particles.embers(b.center() + Vector2(Balance.BLOCK_W * 0.35, -Balance.BLOCK_DEPTH - Balance.PX), 1, 6.0)
	if b.fuse <= 0.0:
		b.fuse = -1.0
		_break(b)


## The other portal of `b`'s pair, if it's there to come out of.
func _partner(b: Block) -> Block:
	for o: Block in grid:
		if o and o != b and o.kind == Block.Kind.PORTAL and o.link == b.link and not o.raining and not o.dead:
			return o
	return null


## Through the portal: out of its pair, going the same way, both portals worn a little.
func _warp(ball: Ball, into: Block, out: Block) -> void:
	var dir := ball.direction()
	var half := Vector2(Balance.BLOCK_W, Balance.ROW_H) * 0.5 + Vector2.ONE * (Balance.BALL_R + 1.0)
	var t := minf(half.x / maxf(absf(dir.x), 0.001), half.y / maxf(absf(dir.y), 0.001))
	var from := ball.pos
	ball.pos = out.center() + dir * t
	ball.portal_cd = 0.3
	ball.trail.clear()
	ball.flash = 1.0
	var c := into.portal_color()
	bolts.append({"points": PackedVector2Array([into.center(), out.center()]), "t": 0.0, "color": c})
	particles.burst(from, c, 8, 0.8)
	particles.burst(ball.pos, c, 8, 0.8)
	ripples.append({"pos": out.center(), "t": 0.0, "strength": 0.5})
	Audio.play("zap", -6.0, 0.7)
	_hit_block(into, 1, ball)
	_hit_block(out, 1, ball)


## TNT going off: everything around it takes a beating (and other TNT goes off in its turn).
func _explode(col: int, row: int) -> void:
	var center := Vector2((col + 0.5) * Balance.BLOCK_W, (row + 0.5) * Balance.ROW_H)
	var reach := Balance.TNT_RADIUS + perk("big_bang")
	for r in range(row - reach - 1, row + reach + 2):
		for c in range(col - reach, col + reach + 1):
			var b := at(c, r)
			if b:
				_hit_block(b, 3)
	particles.burst(center, Color("ffb03b"), 26, 1.6, 12.0)
	particles.embers(center, 16, 12.0)
	particles.smoke(center, 10, 8.0)
	_ripple(center, Balance.BLOCK_W * 5.0, 520.0)
	ripples.append({"pos": center, "t": 0.0, "strength": 1.0})
	Audio.play("boom", 0.0, rng.randf_range(0.9, 1.1))
	shake.emit(10.0)
	hitstop.emit(Balance.HITSTOP_BIG)
	shocked.emit(center, 0.6)
	flashed.emit(Color("ffd08a"), 0.2)


func _burn(b: Block, delta: float) -> void:
	b.burning -= delta
	b.burn_tick -= delta
	if rng.randf() < 0.35:
		particles.embers(b.center() - Vector2(0, Balance.BLOCK_DEPTH), 1, 6.0)
	if b.burn_tick <= 0.0:
		b.burn_tick = Balance.BURN_TICK
		if rng.randf() < Balance.BURN_SPREAD:
			var dirs := [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(0, -1)]
			var d: Vector2i = dirs[rng.randi() % dirs.size()]
			var n := at(b.col + d.x, b.row + d.y)
			if n and n.kind != Block.Kind.STEEL and n.burning <= 0.0:
				n.burning = 2.0
				n.burn_tick = Balance.BURN_TICK
				Audio.play("burn", -12.0, rng.randf_range(0.9, 1.2))
		_hit_block(b, 1)


## Tesla Fence: lightning up off the shield into the lowest blocks of the wall.
func _tesla(from: Vector2) -> void:
	var lowest: Array = []
	for b in blocks():
		if not b.raining:
			lowest.append(b)
	lowest.sort_custom(func(a: Block, b: Block) -> bool: return a.row > b.row)
	for i in mini(3, lowest.size()):
		var target: Block = lowest[rng.randi() % mini(8, lowest.size())]
		bolts.append({"points": _bolt_points(from, target.center()), "t": 0.0})
		_hit_block(target, 1)
	Audio.play("zap", -4.0, rng.randf_range(0.8, 1.0))


## Lightning from `from` to the nearest few blocks.
func _zap(from: Vector2) -> void:
	var targets: Array = []
	for b in blocks():
		var d := b.center().distance_to(from)
		if d > 1.0 and d < Balance.ZAP_REACH:
			targets.append([d, b])
	targets.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	# Plasma: twice the arcs, pink, and they set what they hit alight.
	var plasma := synergy("plasma")
	for i in mini(Balance.ZAP_ARCS * (2 if plasma else 1), targets.size()):
		var target: Block = targets[i][1]
		bolts.append({"points": _bolt_points(from, target.center()), "t": 0.0, "color": Color("ff6af0") if plasma else Color("fff23d")})
		if plasma and target.kind != Block.Kind.STEEL:
			target.burning = maxf(target.burning, 2.0)
		_hit_block(target, 1)
	if not targets.is_empty():
		Audio.play("zap", -8.0, rng.randf_range(0.9, 1.2))


func _bolt_points(a: Vector2, b: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array([a])
	var segments := maxi(3, int(a.distance_to(b) / (Balance.PX * 4.0)))
	var normal := (b - a).normalized().orthogonal()
	for i in range(1, segments):
		var t := float(i) / segments
		points.append(a.lerp(b, t) + normal * rng.randf_range(-1.0, 1.0) * Balance.PX * 3.0)
	points.append(b)
	return points


# --- the quake ----------------------------------------------------------------------------------

## Brings down the bottom rows of the wall, all at once.
func use_quake() -> bool:
	if not quake_charged() or state != State.PLAY:
		return false
	quake = 0.0
	var rows: Array[int] = []
	for r in range(ROWS - 1, -1, -1):
		for c in COLS:
			if at(c, r):
				rows.append(r)
				break
		if rows.size() >= Balance.QUAKE_ROWS:
			break
	# Bottom row first, a beat between rows, each block a little apart.
	for i in rows.size():
		for c in COLS:
			var b := at(c, rows[i])
			if b:
				b.frozen = true
				_quake_blocks.append({"block": b, "t": i * 0.12 + rng.randf() * 0.08})
	wave_timer = 0.0
	Audio.play("quake", 0.0)
	shake.emit(18.0)
	shocked.emit(Vector2(W * 0.5, H), 1.0)
	flashed.emit(Color.WHITE, 0.35)
	hitstop.emit(0.1)
	message.emit("QUAKE!", Color("ffb03b"))
	for b in blocks():
		b.hop_power = 700.0
		b.hop_delay = 0.01 + (H - b.center().y) / 2500.0
	return true


func _update_quake_blocks(delta: float) -> void:
	for q: Dictionary in _quake_blocks.duplicate():
		q["t"] -= delta
		if q["t"] <= 0.0:
			_quake_blocks.erase(q)
			var b: Block = q["block"]
			if not b.dead:
				b.frozen = false
				_break(b)
				particles.smoke(b.center(), 3)


# --- pickups ------------------------------------------------------------------------------------

func _drop_pickup(at_pos: Vector2) -> void:
	var kind := Pickups.pick(rng, 1.0 + perk("rare_taste"))
	pickups.append({"kind": kind, "pos": at_pos, "t": 0.0})
	Audio.play("release", -6.0)
	# A rare one is an event: a chime, a gold flash and a shout.
	if Pickups.rarity(kind) == Pickups.Rarity.RARE:
		Audio.play("best", -4.0, 1.2)
		flashed.emit(Pickups.RARITY_COLOR[Pickups.Rarity.RARE], 0.15)
		message.emit("RARE DROP!", Pickups.RARITY_COLOR[Pickups.Rarity.RARE])
		particles.spray(at_pos, Vector2.UP, Pickups.RARITY_COLOR[Pickups.Rarity.RARE], 16, 10.0)
	elif Pickups.rarity(kind) == Pickups.Rarity.UNCOMMON:
		Audio.play("coin", -10.0, 1.3)


func _update_pickups(delta: float) -> void:
	_update_quake_blocks(delta)
	for p: Dictionary in pickups.duplicate():
		p["t"] += delta
		# A moment hanging where it came out, then it drifts down.
		if p["t"] > 0.4 and state == State.PLAY:
			p["pos"].y += Balance.PICKUP_FALL * delta
		if p["pos"].y > H + Balance.PICKUP_SIZE:
			pickups.erase(p)


func _collect(p: Dictionary) -> void:
	if not pickups.has(p):
		return
	pickups.erase(p)
	var kind: Pickups.Kind = p["kind"]
	var info := Pickups.info(kind)
	Audio.play("pickup_bad" if info.get("bad", false) else "pickup", -2.0)
	particles.spray(p["pos"], Vector2.UP, info["color"], 14, 10.0)
	ripples.append({"pos": p["pos"], "t": 0.0, "strength": 0.8})
	message.emit(String(info["name"]).to_upper() + ("" if info.get("bad", false) else "!"), info["color"])
	flashed.emit(info["color"], 0.12)
	if Pickups.rarity(kind) == Pickups.Rarity.RARE:
		# Caught a rare one: a fanfare and a burst of gold.
		Audio.play("fanfare", -4.0)
		particles.spray(p["pos"], Vector2.UP, Pickups.RARITY_COLOR[Pickups.Rarity.RARE], 24, 12.0)
		shocked.emit(p["pos"], 0.5)
		hitstop.emit(Balance.HITSTOP_BIG)
	match kind:
		Pickups.Kind.MULTI:
			_split_balls()
		Pickups.Kind.FIRE:
			effects[kind] = Balance.FIRE_TIME
			Audio.play("burn", -4.0)
		Pickups.Kind.FROST:
			effects[kind] = Balance.FROST_TIME
			Audio.play("freeze", 0.0)
			for b in blocks():
				b.frozen = true
				b.burning = 0.0
		Pickups.Kind.ZAP:
			effects[kind] = Balance.ZAP_TIME
		Pickups.Kind.WIDE:
			effects.erase(Pickups.Kind.NARROW)
			effects[kind] = Balance.WIDE_TIME
			paddle_target_w = _paddle_size()
		Pickups.Kind.NARROW:
			effects.erase(Pickups.Kind.WIDE)
			effects[kind] = Balance.NARROW_TIME
			paddle_target_w = _paddle_size()
		Pickups.Kind.OVERDRIVE:
			effects[kind] = Balance.OVERDRIVE_TIME
		Pickups.Kind.ROCKET:
			effects[kind] = Balance.ROCKET_TIME
			rocket_timer = 0.0
		Pickups.Kind.SHIELD:
			effects[kind] = Balance.SHIELD_TIME
			Audio.play("shield", -2.0)
		Pickups.Kind.BARRAGE:
			barrage_left += Balance.BARRAGE_ROCKETS
			barrage_timer = 0.15
		Pickups.Kind.LASER:
			effects[kind] = Balance.LASER_TIME
			_laser_tick = 0.0
			Audio.play("charged", -2.0, 0.7)
		Pickups.Kind.MAGNET:
			effects[kind] = Balance.MAGNET_TIME
		Pickups.Kind.BLAST:
			effects[kind] = Balance.BLAST_TIME
			Audio.play("boom", -8.0, 1.4)
		Pickups.Kind.HASTE:
			effects[kind] = Balance.HASTE_TIME
			Audio.play("danger", -4.0, 1.2)
	# Long Haul: the good ones last longer.
	if effects.has(kind) and not info.get("bad", false):
		effects[kind] *= 1.0 + 0.3 * perk("long_haul")
	picked_up.emit(kind)


func _update_rockets(delta: float) -> void:
	for rocket: Dictionary in rockets.duplicate():
		rocket["t"] += delta
		rocket["pos"].y -= Balance.ROCKET_SPEED * delta * minf(rocket["t"] * 4.0 + 0.3, 1.0)
		# A barrage's rocket swings over to its own column as it climbs.
		if rocket.has("to_x"):
			rocket["pos"].x = lerpf(rocket["from_x"], rocket["to_x"], smoothstep(0.0, 1.0, minf(rocket["t"] * 3.0, 1.0)))
		if rng.randf() < 0.7:
			particles.smoke(rocket["pos"] + Vector2(0, Balance.PX * 3.0), 1, 6.0, Color(0.8, 0.75, 0.7, 0.5))
		var cell := _cell_of(rocket["pos"])
		var b := at(cell.x, cell.y)
		if b == null and rocket["pos"].y > 0.0:
			continue
		rockets.erase(rocket)
		var center: Vector2 = rocket["pos"]
		if b:
			# Napalm: everything it hits catches fire.
			if synergy("napalm"):
				for c in range(cell.x - 1, cell.x + 2):
					var n := at(c, cell.y)
					if n and n.kind != Block.Kind.STEEL:
						n.burning = maxf(n.burning, 2.5)
				particles.embers(center, 8, 10.0)
			_hit_block(b, 2)
			# Ice Shards: a frozen chunk of the row shatters with it.
			var reach := 3 if synergy("ice_shards") else 1
			for c in range(cell.x - reach, cell.x + reach + 1):
				var n := at(c, cell.y)
				if n and c != cell.x:
					_hit_block(n, 1)
			if reach > 1:
				particles.shards(center, Color("dff6ff"), 10)
		particles.burst(center, Color("ffb03b"), 8, 0.8)
		particles.smoke(center, 4)
		Audio.play("boom", -10.0, rng.randf_range(1.2, 1.5))
		shake.emit(2.0)
		if rocket.has("to_x") and b:
			_blast(cell.x, cell.y)


## Lets a ball off the Magnet, at the angle its place on the paddle gives it.
func _release(ball: Ball) -> void:
	ball.held = false
	var offset := clampf(ball.held_offset / (paddle_w * 0.5), -1.0, 1.0)
	ball.set_direction(Vector2.UP.rotated(offset * Balance.PADDLE_MAX_ANGLE))
	ball.fix_angle()
	ball.idle = 0.0
	paddle_squash = 0.6
	Audio.play("release", -4.0)


## A small blast round a block (Blast Ball, a barrage's rockets): every neighbour takes a hit.
func _blast(col: int, row: int) -> void:
	var center := Vector2((col + 0.5) * Balance.BLOCK_W, (row + 0.5) * Balance.ROW_H)
	# Cluster Bombs: twice as far.
	var reach := 2 if synergy("cluster") else 1
	for r in range(row - reach, row + reach + 1):
		for c in range(col - reach, col + reach + 1):
			var b := at(c, r)
			if b and (c != col or r != row):
				_hit_block(b, 1)
	particles.burst(center, Color("ff8a3d"), 10, 1.0, 10.0)
	particles.smoke(center, 3, 8.0)
	ripples.append({"pos": center, "t": 0.0, "strength": 0.5})
	Audio.play("boom", -8.0, rng.randf_range(1.1, 1.4))
	shake.emit(3.0)


## The barrage, a rocket at a time from either end of the paddle, each to a column with blocks in it.
func _update_barrage(delta: float) -> void:
	if barrage_left <= 0:
		return
	barrage_timer -= delta
	if barrage_timer > 0.0:
		return
	barrage_timer = Balance.BARRAGE_GAP
	barrage_left -= 1
	var columns: Array[int] = []
	for c in COLS:
		for r in ROWS:
			if at(c, r) and not at(c, r).raining:
				columns.append(c)
				break
	var to := float(columns[rng.randi() % columns.size()] if not columns.is_empty() else rng.randi() % COLS)
	var side := -1.0 if barrage_left % 2 == 0 else 1.0
	var from := paddle_x + side * (paddle_w * 0.5 - Balance.PX * 3.0)
	rockets.append({"pos": Vector2(from, Balance.PADDLE_Y - Balance.PX * 2.0), "t": 0.0,
		"from_x": from, "to_x": (to + 0.5) * Balance.BLOCK_W})
	Audio.play("rocket", -8.0, rng.randf_range(1.0, 1.3))
	shake.emit(1.0)


## Where the laser comes out of the paddle: its middle, sliding out towards the end it is moving to near
## the walls, so that the beam reaches the outermost columns too.
func laser_x() -> float:
	var half := paddle_w * 0.5
	var reach := Balance.BLOCK_W * 0.5
	if W - half * 2.0 <= 0.0:
		return paddle_x
	return remap(paddle_x, half, W - half, reach, W - reach)


## The lowest block in column `col` (what a beam up it meets first), or null.
func _lowest_in(col: int) -> Block:
	for r in range(ROWS - 1, -1, -1):
		var b := at(col, r)
		if b and not b.raining:
			return b
	return null


## The laser: a beam straight up from the paddle, burning into the first block it meets (Mega Laser:
## and one up each column beside it).
func _update_laser(delta: float) -> void:
	var col := clampi(floori(laser_x() / Balance.BLOCK_W), 0, COLS - 1)
	var target := _lowest_in(col)
	laser_end = (target.row + 1) * Balance.ROW_H if target else 0.0
	var mega := synergy("mega_laser")
	var side_targets: Array = []
	for i in 2:
		var side_col := col + (-1 if i == 0 else 1)
		var side: Block = _lowest_in(side_col) if mega and side_col >= 0 and side_col < COLS else null
		laser_sides[i] = ((side.row + 1) * Balance.ROW_H if side else 0.0) if mega and side_col >= 0 and side_col < COLS else -1.0
		if side:
			side_targets.append(side)
	var hit := Vector2(laser_x(), laser_end)
	if rng.randf() < 0.5:
		particles.spray(hit, Vector2.DOWN, Color("ffb0c8"), 1, 6.0)
	_laser_hum -= delta
	if _laser_hum <= 0.0:
		_laser_hum = 0.22
		Audio.play("zap", -14.0, rng.randf_range(1.4, 1.7))
	_laser_tick -= delta
	if _laser_tick > 0.0 or target == null:
		return
	_laser_tick = Balance.LASER_TICK
	for side: Block in side_targets:
		_hit_block(side, 1)
	_hit_block(target, 1)
	particles.spray(hit, Vector2.DOWN, Color("ff4f6a"), 3, 6.0)


func _cell_of(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / Balance.BLOCK_W), floori(p.y / Balance.ROW_H))


# --- the title's board --------------------------------------------------------------------------

## Moves the paddle for a board that plays itself: under the lowest ball coming down, aiming a little.
func autopilot() -> void:
	var lowest: Ball = null
	for ball in balls:
		if ball.vel.y > 0.0 and (lowest == null or ball.pos.y > lowest.pos.y):
			lowest = ball
	if lowest == null and not balls.is_empty():
		lowest = balls[0]
	if lowest == null:
		return
	var aim := sin(clock * 0.7) * paddle_w * 0.3
	paddle_target = lowest.pos.x + aim
	if state == State.SERVE:
		launch()
