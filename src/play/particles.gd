class_name Particles
extends RefCounted
## Every bit of debris, spark, ember and puff of smoke on the board, kept in
## packed arrays (there can be a thousand at once on a phone) and drawn by
## the board's view. Like everything on the board each has a height, `z`,
## and a shadow under it; chunks fall, bounce and settle, the rest fade.

enum Kind {
	CHUNK,  ## A piece of a block: thrown up, falls, bounces, lies there a moment.
	SPARK,  ## Flies straight and slows, no gravity.
	EMBER,  ## Rises and flickers.
	SMOKE,  ## Rises, swells and fades.
	SHARD,  ## A glinting splinter of ice or glass: like a chunk, but spins.
}

const MAX := 1400
const GRAVITY := 1500.0

var count := 0
var pos := PackedVector2Array()
var vel := PackedVector2Array()
var z := PackedFloat32Array()
var vz := PackedFloat32Array()
var life := PackedFloat32Array()
var max_life := PackedFloat32Array()
var size := PackedFloat32Array()
var color := PackedColorArray()
var kind := PackedByteArray()


func _init() -> void:
	pos.resize(MAX)
	vel.resize(MAX)
	z.resize(MAX)
	vz.resize(MAX)
	life.resize(MAX)
	max_life.resize(MAX)
	size.resize(MAX)
	color.resize(MAX)
	kind.resize(MAX)


func add(k: Kind, p: Vector2, v: Vector2, height: float, v_up: float, lifetime: float, s: float, c: Color) -> void:
	var i := count
	if count >= MAX:
		# Full: the oldest-looking one (the first) makes way.
		i = randi() % MAX
	else:
		count += 1
	pos[i] = p
	vel[i] = v
	z[i] = height
	vz[i] = v_up
	life[i] = lifetime
	max_life[i] = lifetime
	size[i] = s
	color[i] = c
	kind[i] = k


func clear() -> void:
	count = 0


## A block breaking: chunks of its colour thrown up and out, and a few sparks.
func burst(center: Vector2, c: Color, amount: int, power := 1.0, height := 8.0) -> void:
	for i in amount:
		var angle := randf() * TAU
		var speed := randf_range(60.0, 260.0) * power
		var tint := c.darkened(randf() * 0.35) if randf() < 0.7 else c.lightened(0.3)
		add(Kind.CHUNK, center + Vector2(randf_range(-16, 16), randf_range(-8, 8)), Vector2.from_angle(angle) * speed,
			height, randf_range(250.0, 600.0) * power, randf_range(0.8, 1.6), Balance.PX * randf_range(1.0, 2.0), tint)
	for i in amount / 2:
		var angle := randf() * TAU
		add(Kind.SPARK, center, Vector2.from_angle(angle) * randf_range(200.0, 500.0) * power, height + 4.0, 0.0,
			randf_range(0.15, 0.35), Balance.PX * randf_range(0.75, 1.25), c.lightened(0.6))


## Little bits off a ball's hit, flying back the way it came (the original game's).
func spray(at: Vector2, dir: Vector2, c: Color, amount: int, height := 8.0) -> void:
	for i in amount:
		var d := dir.rotated(randf_range(-0.6, 0.6))
		add(Kind.SPARK, at, d * randf_range(150.0, 330.0), height, 0.0, randf_range(0.12, 0.3),
			Balance.PX * randf_range(0.6, 1.1), c.lightened(randf() * 0.5))


func embers(at: Vector2, amount: int, height := 8.0) -> void:
	for i in amount:
		var c := Color(randf_range(0.85, 1.0), randf_range(0.2, 0.85), 0.05) if randf() > 0.1 else Color(0.25, 0.22, 0.22)
		add(Kind.EMBER, at + Vector2(randf_range(-14, 14), randf_range(-6, 6)), Vector2(randf_range(-30, 30), randf_range(-20, 10)),
			height, randf_range(40.0, 110.0), randf_range(0.3, 0.7), Balance.PX * randf_range(0.8, 1.6), c)


func smoke(at: Vector2, amount: int, height := 6.0, c := Color(0.55, 0.5, 0.55, 0.7)) -> void:
	for i in amount:
		add(Kind.SMOKE, at + Vector2(randf_range(-10, 10), randf_range(-6, 6)), Vector2(randf_range(-25, 25), randf_range(-25, 5)),
			height, randf_range(20.0, 60.0), randf_range(0.5, 1.1), Balance.PX * randf_range(1.5, 3.0), c)


func shards(center: Vector2, c: Color, amount: int, power := 1.0) -> void:
	for i in amount:
		var angle := randf() * TAU
		add(Kind.SHARD, center, Vector2.from_angle(angle) * randf_range(80.0, 300.0) * power, 8.0,
			randf_range(250.0, 550.0) * power, randf_range(0.6, 1.2), Balance.PX * randf_range(0.8, 1.6), c)


func update(delta: float, bounds: Rect2) -> void:
	var i := 0
	while i < count:
		life[i] -= delta
		if life[i] <= 0.0:
			_remove(i)
			continue
		var k := kind[i]
		var p := pos[i] + vel[i] * delta
		match k:
			Kind.CHUNK, Kind.SHARD:
				vz[i] -= GRAVITY * delta
				z[i] += vz[i] * delta
				if z[i] <= 0.0:
					z[i] = 0.0
					if absf(vz[i]) > 80.0:
						vz[i] = -vz[i] * 0.35
						vel[i] *= 0.6
					else:
						vz[i] = 0.0
						vel[i] *= pow(0.02, delta)
				# The walls stop them.
				if p.x < bounds.position.x or p.x > bounds.end.x:
					vel[i].x = -vel[i].x * 0.5
					p.x = clampf(p.x, bounds.position.x, bounds.end.x)
				if p.y < bounds.position.y:
					vel[i].y = -vel[i].y * 0.5
					p.y = bounds.position.y
			Kind.SPARK:
				vel[i] *= pow(0.004, delta)
			Kind.EMBER:
				z[i] += vz[i] * delta
				vel[i] *= pow(0.3, delta)
			Kind.SMOKE:
				z[i] += vz[i] * delta
				vel[i] *= pow(0.2, delta)
				size[i] += delta * Balance.PX * 2.0
		pos[i] = p
		i += 1


func _remove(i: int) -> void:
	count -= 1
	if i == count:
		return
	pos[i] = pos[count]
	vel[i] = vel[count]
	z[i] = z[count]
	vz[i] = vz[count]
	life[i] = life[count]
	max_life[i] = max_life[count]
	size[i] = size[count]
	color[i] = color[count]
	kind[i] = kind[count]


## Shadows first (under everything that stands on the board), then the particles themselves.
func draw_shadows(canvas: CanvasItem, shadow: Color) -> void:
	for i in count:
		var k := kind[i]
		if k == Kind.SPARK or k == Kind.SMOKE or k == Kind.EMBER:
			continue
		var s := size[i]
		var off := Vector2(1.0, 1.0) * (Balance.PX + z[i] * 0.35)
		canvas.draw_rect(Rect2(pos[i] + off - Vector2(s, s) * 0.5, Vector2(s, s)), shadow)


func draw(canvas: CanvasItem) -> void:
	for i in count:
		var t := life[i] / max_life[i]
		var s := size[i]
		var c := color[i]
		var p := pos[i] - Vector2(0, z[i])
		match kind[i]:
			Kind.CHUNK:
				if t < 0.25:
					s *= t / 0.25
				canvas.draw_rect(Rect2(p - Vector2(s, s) * 0.5, Vector2(s, s)), c)
			Kind.SHARD:
				var glint := c.lerp(Color.WHITE, 0.5 + 0.5 * sin(life[i] * 30.0 + i))
				canvas.draw_rect(Rect2(p - Vector2(s, s * 0.5) * 0.5, Vector2(s, s * 0.5)), glint)
			Kind.SPARK:
				c.a *= minf(t * 2.0, 1.0)
				var tail := vel[i] * 0.02
				canvas.draw_line(p, p - tail, c, s)
			Kind.EMBER:
				c.a *= t
				var flick := s * (0.7 + 0.3 * sin(life[i] * 40.0 + i))
				canvas.draw_rect(Rect2(p - Vector2(flick, flick) * 0.5, Vector2(flick, flick)), c)
			Kind.SMOKE:
				c.a *= t * t
				canvas.draw_rect(Rect2(p - Vector2(s, s) * 0.5, Vector2(s, s)), c)
