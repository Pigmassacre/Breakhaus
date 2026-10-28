class_name Block
extends RefCounted
## One block on the board's grid. The board keeps them in a grid of cells
## and draws them all itself; this is just what each one is and how it is
## doing.

enum Kind {
	NORMAL,  ## One to three hits.
	STEEL,  ## Five hits, and fire won't take.
	TNT,  ## Goes off when it breaks, taking its neighbours with it.
	PRIZE,  ## Always lets a pickup go.
	GOLD,  ## A pile of points.
	MOSS,  ## Grows into an empty cell beside it every time the wall comes down.
}

var kind := Kind.NORMAL
var hp := 1
var max_hp := 1
var color := Color.WHITE
var col := 0
var row := 0
## How high it is off the board (it rains in from high up, and hops when something lands nearby).
var z := 0.0
var z_velocity := 0.0
## Raining in from the sky at the start (it can't be hit until it lands).
var raining := false
## A hop to come: in this many seconds, this hard (the ripple from a hit nearby).
var hop_delay := 0.0
var hop_power := 0.0
## Drawn this far below its row while it slides down a row (from ROW_H to 0).
var slide := 0.0
## White flash on a hit, 1 to 0.
var flash := 0.0
## Sideways shake, for a hit and the rumble before a wave.
var shake := 0.0
## Seconds of fire left (0: not burning), and to the next burn.
var burning := 0.0
var burn_tick := 0.0
var frozen := false
var carries_pickup := false
var dead := false


static func kind_color(kind: Kind, base: Color) -> Color:
	match kind:
		Kind.STEEL:
			return Color("a7b3c2")
		Kind.TNT:
			return Color("e0302a")
		Kind.GOLD:
			return Color("ffc933")
		Kind.MOSS:
			return Color("4fae3a")
		Kind.PRIZE:
			return Color("ffffff")
	return base


func setup(data: Dictionary, c: int, r: int) -> Block:
	kind = data["kind"]
	hp = data["hp"]
	max_hp = hp
	color = data["color"]
	col = c
	row = r
	carries_pickup = kind == Kind.PRIZE
	return self


## Where it is on the board (its footprint's top left).
func position() -> Vector2:
	return Vector2(col * Balance.BLOCK_W, row * Balance.ROW_H - slide)


func rect() -> Rect2:
	return Rect2(position(), Vector2(Balance.BLOCK_W, Balance.ROW_H))


func center() -> Vector2:
	return position() + Vector2(Balance.BLOCK_W, Balance.ROW_H) * 0.5


## Its colour now: darker as it is worn down, white as it flashes.
func shade() -> Color:
	var c := color
	if kind == Kind.NORMAL and max_hp > 1:
		c = c.darkened(0.42 * float(hp - 1) / float(max_hp - 1))
	if frozen:
		c = c.lerp(Color("bfeaff"), 0.65)
	return c.lerp(Color.WHITE, flash)
