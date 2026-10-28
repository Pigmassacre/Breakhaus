class_name Boss
extends RefCounted
## A boss, at the top of the board once a boss floor's own rows are gone:
## the wall still comes down under it, a new row from under it every wave,
## until it is beaten. Three of them:
##
## - The Vault: a steel door with three bolts along its foot, two of them
##   open at a time; only an open one can be hurt. Now and then it
##   slams, and the wall comes down a row.
## - The Crane: a wrecking ball swinging across the top, hurt by every hit,
##   swinging faster as it weakens; now and then it dips and shakes blocks
##   loose into the wall.
## - The Heart: a heart in a nest of moss that grows back; break through to
##   hit it. Now and then it turns blocks in the wall to moss.
##
## It lives in the rows above `rows()` (the board keeps its wall below them),
## and draws itself in art pixels on the board's grid.

const PX := Balance.PX
const W := Balance.BOARD_W
const VAULT := Rect2(96, 0, 384, 136)
const VAULT_SLOTS := [168.0, 288.0, 408.0]
const CRANE_PIVOT := Vector2(W * 0.5, -100.0)
const CRANE_LENGTH := 196.0
const CRANE_R := 36.0
const HEART_AT := Vector2(W * 0.5, 80.0)
const HEART_R := 30.0
## The heart's cells in the grid (moss doesn't grow there): columns 5-6, rows 1-4.
const HEART_CELLS := Rect2i(5, 1, 2, 4)
const HEART := [
	"..XXX.....XXX..",
	".XXXXX...XXXXX.",
	"XXXXXXX.XXXXXXX",
	"XXXXXXXXXXXXXXX",
	"XXXXXXXXXXXXXXX",
	"XXXXXXXXXXXXXXX",
	".XXXXXXXXXXXXX.",
	"..XXXXXXXXXXX..",
	"...XXXXXXXXX...",
	"....XXXXXXX....",
	".....XXXXX.....",
	"......XXX......",
	".......X.......",
]
const NAMES := {"vault": "The Vault", "crane": "The Crane", "heart": "The Heart"}

var kind := "vault"
var board: Board
var hp := 10
var max_hp := 10
var dead := false
## Seconds since it arrived; how far it still has to drop in (1 to 0); a hit's flash and shake.
var t := 0.0
var enter := 1.0
var flash := 0.0
var shake := 0.0
## Seconds to its next move against you.
var attack := 6.0
## The crane's dip (0 to 1, and back) and its swing.
var dip := 0.0
var swing := 0.0


func _init(which: String, on: Board, level: int) -> void:
	kind = which
	board = on
	var base: int = {"vault": 6, "crane": 16, "heart": 12}[kind]
	max_hp = base + maxi(level - Balance.FLOORS, 0) / 2
	hp = max_hp


func title() -> String:
	return NAMES[kind]


## The rows it takes up: the wall stays below them.
func rows() -> int:
	return 6


func update(delta: float) -> void:
	t += delta
	enter = maxf(enter - delta / 1.2, 0.0)
	flash = maxf(flash - delta * 4.0, 0.0)
	shake = move_toward(shake, 0.0, delta * 40.0)
	if enter > 0.0 or dead:
		return
	match kind:
		"crane":
			# Faster as it weakens.
			var rage := 1.0 + (1.0 - float(hp) / max_hp) * 0.8
			swing += delta * 1.1 * rage
			if dip > 0.0:
				dip = maxf(dip - delta * 1.6, 0.0)
		"heart":
			if fmod(t, 3.5) < delta:
				_regrow()
	attack -= delta
	if attack <= 0.0:
		attack = {"vault": 9.0, "crane": 8.0, "heart": 8.0}[kind]
		_attack()


## The shut bolt of the vault (its index): one at a time, round and round, the other two open.
func shut_slot() -> int:
	return int(fmod(t, 6.0) / 2.0)


func crane_ball() -> Vector2:
	var a := sin(swing) * 0.85
	return CRANE_PIVOT + Vector2(sin(a), cos(a)) * (CRANE_LENGTH + dip * 70.0)


## A ball meeting it: {"normal", "weak"} (weak: it hurts), or {} for a miss.
func collide(pos: Vector2, r: float) -> Dictionary:
	if enter > 0.0 or dead:
		return {}
	match kind:
		"vault":
			var closest := Vector2(clampf(pos.x, VAULT.position.x, VAULT.end.x), clampf(pos.y, VAULT.position.y, VAULT.end.y))
			var d := pos - closest
			if d.length() >= r:
				return {}
			var normal := d.normalized() if d.length() > 0.01 else Vector2.DOWN
			var weak := false
			for i in VAULT_SLOTS.size():
				if i != shut_slot() and absf(closest.x - VAULT_SLOTS[i]) < 36.0 and closest.y > VAULT.end.y - 4.0:
					weak = true
			return {"normal": normal, "weak": weak, "depth": r - d.length()}
		"crane":
			var c := crane_ball()
			var d := pos - c
			if d.length() >= r + CRANE_R:
				return {}
			return {"normal": d.normalized(), "weak": true, "depth": r + CRANE_R - d.length()}
		"heart":
			var d := pos - HEART_AT
			if d.length() >= r + HEART_R:
				return {}
			return {"normal": d.normalized(), "weak": true, "depth": r + HEART_R - d.length()}
	return {}


func hurt(damage: int) -> void:
	hp = maxi(hp - damage, 0)
	flash = 1.0
	shake = PX * 2.0
	if kind == "crane":
		swing += 0.4


func _attack() -> void:
	match kind:
		"vault":
			# A slam that brings the wall down a row.
			board.boss_slam()
			Audio.play("clang", 0.0, 0.6)
		"crane":
			dip = 1.0
			board.boss_drop(4, Block.Kind.NORMAL)
			board.shake.emit(10.0)
			Audio.play("boom", -2.0, 0.6)
		"heart":
			# Spores: blocks in the wall turn to moss.
			var turned := 0
			for b in board.blocks():
				if b.kind == Block.Kind.NORMAL and b.row >= rows() and board.rng.randf() < 0.15 and turned < 4:
					b.kind = Block.Kind.MOSS
					b.color = Block.kind_color(Block.Kind.MOSS, b.color)
					b.flash = 1.0
					turned += 1
			Audio.play("grow", 0.0, 0.8)
	board.message.emit({"vault": "SLAM!", "crane": "LOOK OUT!", "heart": "SPORES!"}[kind], Color("ff3d3d"))


## The heart's moss growing back round it, a few cells a time.
func _regrow() -> void:
	var grown := 0
	for r in range(0, rows()):
		for c in range(3, 9):
			if grown >= 3 or board.at(c, r) != null or HEART_CELLS.has_point(Vector2i(c, r)):
				continue
			if board.rng.randf() < 0.4:
				board.boss_moss(c, r)
				grown += 1
	if grown > 0:
		Audio.play("grow", -6.0, 1.2)


## Its first moss, all round the heart.
func setup_board() -> void:
	if kind == "heart":
		for r in range(0, rows()):
			for c in range(3, 9):
				if not HEART_CELLS.has_point(Vector2i(c, r)):
					board.boss_moss(c, r)


# --- drawing ------------------------------------------------------------------------------------

func draw(canvas: CanvasItem, clock: float) -> void:
	var lift := Vector2(shake * (1.0 if fmod(clock * 40.0, 2.0) < 1.0 else -1.0), -enter * 400.0)
	var hot := flash
	match kind:
		"vault":
			_draw_vault(canvas, lift, hot)
		"crane":
			_draw_crane(canvas, lift, hot)
		"heart":
			_draw_heart(canvas, lift, hot, clock)


func _draw_vault(canvas: CanvasItem, lift: Vector2, hot: float) -> void:
	var r := Rect2(VAULT.position + lift, VAULT.size)
	var steel := Color("8a96a8").lerp(Color.WHITE, hot * 0.7)
	canvas.draw_rect(Rect2(r.position + Vector2(PX * 2.0, PX * 2.0), r.size), Color(0, 0, 0, 0.35))
	canvas.draw_rect(r.grow(PX), Color("26262e"))
	canvas.draw_rect(r, steel)
	canvas.draw_rect(Rect2(r.position, Vector2(r.size.x, PX)), steel.lightened(0.35))
	canvas.draw_rect(Rect2(r.position + Vector2(0, r.size.y - PX * 2.0), Vector2(r.size.x, PX * 2.0)), steel.darkened(0.35))
	# Panels and rivets.
	for i in range(1, 4):
		canvas.draw_rect(Rect2(r.position + Vector2(r.size.x * i / 4.0, PX * 2.0), Vector2(PX, r.size.y - PX * 8.0)), steel.darkened(0.2))
	var x := r.position.x + PX * 2.0
	while x < r.end.x - PX * 2.0:
		canvas.draw_rect(Rect2(x, r.position.y + PX * 2.0, PX, PX), steel.darkened(0.45))
		x += PX * 6.0
	# The wheel, turning.
	var hub := Pixels.snap(r.get_center() - Vector2(0, PX * 4.0))
	Pixels.ring(canvas, hub, 7.0, 2, steel.darkened(0.5))
	for i in 3:
		var a := t * 0.8 + i * TAU / 3.0
		Pixels.line(canvas, hub, hub + Vector2.from_angle(a) * PX * 6.0, steel.darkened(0.5), 1)
	Pixels.square(canvas, hub + Vector2(PX, PX) * 0.5, 2, Color("ffd23d"))
	# The bolts: shut, steel; open, a gold glow in a black slot.
	for i in VAULT_SLOTS.size():
		var sx: float = VAULT_SLOTS[i] + lift.x
		var slot := Rect2(sx - PX * 6.0, r.end.y - PX * 5.0, PX * 12.0, PX * 5.0)
		if i != shut_slot():
			canvas.draw_rect(slot.grow(PX), Color("ffd23d"))
			canvas.draw_rect(slot, Color("1a1008"))
			var glow := 0.5 + 0.5 * sin(t * 12.0)
			canvas.draw_rect(Rect2(slot.position + Vector2(PX * 2.0, PX * 2.0), Vector2(slot.size.x - PX * 4.0, PX * 2.0)), Color(Color("ffd23d"), 0.5 + glow * 0.5))
		else:
			canvas.draw_rect(slot, steel.darkened(0.4))
			for k in 3:
				canvas.draw_rect(Rect2(slot.position + Vector2(PX * (2 + k * 3), PX), Vector2(PX * 2.0, PX * 3.0)), steel.lightened(0.15))


func _draw_crane(canvas: CanvasItem, lift: Vector2, hot: float) -> void:
	# The girder across the top, the cable and the ball.
	var girder := Color("ffb03b")
	canvas.draw_rect(Rect2(Vector2(0, PX) + lift, Vector2(W, PX * 3.0)), girder.darkened(0.3))
	var x := 0.0
	while x < W:
		canvas.draw_rect(Rect2(Vector2(x, PX) + lift, Vector2(PX, PX * 3.0)), Color("26262e"))
		x += PX * 6.0
	var ball := crane_ball() + lift
	var top := Vector2(CRANE_PIVOT.x, PX * 3.0) + lift
	var from := CRANE_PIVOT + lift
	# Only the part of the cable on the board.
	var along := (top.y - from.y) / maxf(ball.y - from.y, 1.0)
	Pixels.line(canvas, from.lerp(ball, clampf(along, 0.0, 1.0)), ball, Color("3a3a48"), 2)
	_disc(canvas, ball + Vector2(PX * 3.0, PX * 4.0), CRANE_R / PX, Color(0, 0, 0, 0.3), true)
	_disc(canvas, ball, CRANE_R / PX, Color("4a4a5a").lerp(Color.WHITE, hot * 0.7), false)
	# The shackle on top.
	canvas.draw_rect(Rect2(Pixels.snap(ball - Vector2(PX * 2.0, CRANE_R + PX * 2.0)), Vector2(PX * 4.0, PX * 3.0)), Color("26262e"))


func _draw_heart(canvas: CanvasItem, lift: Vector2, hot: float, clock: float) -> void:
	var beat := maxf(sin(clock * 6.0), 0.0)
	var o := Pixels.snap(HEART_AT + lift - Vector2(15, 13) * PX * 0.5)
	var red := Color("e0303a").lerp(Color("ff6a7a"), beat * 0.5).lerp(Color.WHITE, hot * 0.7)
	# A glow round it on the beat, a pixel out.
	if beat > 0.6:
		for y in HEART.size():
			for x in HEART[y].length():
				if HEART[y][x] == "X":
					canvas.draw_rect(Rect2(o + Vector2(x - 1, y - 1) * PX, Vector2(PX * 3.0, PX * 3.0)), Color(Color("ff3d6e"), (beat - 0.6) * 0.5))
	for y in HEART.size():
		for x in HEART[y].length():
			if HEART[y][x] != "X":
				continue
			var c := red
			if y >= 9 or x >= 12:
				c = red.darkened(0.25)
			elif y <= 2 and x <= 4:
				c = red.lightened(0.35)
			canvas.draw_rect(Rect2(o + Vector2(x, y) * PX, Vector2(PX, PX)), c)
	canvas.draw_rect(Rect2(o + Vector2(3, 2) * PX, Vector2(PX * 2.0, PX)), Color(1, 1, 1, 0.8))


## A round thing in art pixels, `r` of them across from the middle, lit from the top left (or `flat`).
func _disc(canvas: CanvasItem, center: Vector2, r: float, base: Color, flat: bool) -> void:
	var c := (center / PX).round()
	var reach := ceili(r)
	var light := Vector2(-0.6, -0.8)
	for y in range(-reach, reach):
		for x in range(-reach, reach):
			var p := Vector2(x + 0.5, y + 0.5)
			var d := p.length()
			if d > r:
				continue
			var col := base
			if not flat:
				var shade := p.normalized().dot(light) * (d / r)
				col = base.lightened(maxf(shade, 0.0) * 0.5).darkened(maxf(-shade, 0.0) * 0.4)
				if d > r - 1.0:
					col = Color("26262e")
			canvas.draw_rect(Rect2((c + Vector2(x, y)) * PX, Vector2(PX, PX)), col)
