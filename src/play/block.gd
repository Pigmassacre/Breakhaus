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
	BUMPER,  ## Kicks the ball off it faster, pinball style; three hits.
	PORTAL,  ## One of a pair: a ball going into it comes out of the other. Two goes.
	ICE,  ## The ball goes straight through, and the crack runs into every ice block touching it.
	FUSE,  ## A hit lights it; a moment later it blasts its whole row. A second hit sets it off at once.
	COIN,  ## Worth a lot when it lands, less every second after.
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
## A portal's pair: the other portal with the same number.
var link := 0
## A lit fuse: seconds to go (below 0: not lit).
var fuse := -1.0
## A coin block: seconds since it landed.
var age := 0.0
## A bumper's kick, 1 to 0, for its flash and swell.
var bump := 0.0


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
		Kind.BUMPER:
			return Color("6a2c8f")
		Kind.PORTAL:
			return Color("2a1a4a")
		Kind.ICE:
			return Color("a8e4ff")
		Kind.FUSE:
			return Color("4a4a5a")
		Kind.COIN:
			return Color("3a2a1a")
	return base


func setup(data: Dictionary, c: int, r: int) -> Block:
	kind = data["kind"]
	hp = data["hp"]
	max_hp = hp
	color = data["color"]
	col = c
	row = r
	carries_pickup = kind == Kind.PRIZE
	link = data.get("link", 0)
	return self


## A portal pair's own colour, so that you can see which goes with which.
func portal_color() -> Color:
	return Color.from_hsv(fmod(link * 0.37 + 0.55, 1.0), 0.65, 1.0)


## What a coin block is worth now: a lot at first, draining away.
func coin_value() -> int:
	return int(lerpf(Balance.COIN_MAX, Balance.COIN_MIN, clampf(age / Balance.COIN_DRAIN, 0.0, 1.0)))


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
