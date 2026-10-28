class_name Ball
extends RefCounted
## A ball: where it is, where it's going, and what it carries.

var pos := Vector2.ZERO
var vel := Vector2.ZERO
var speed := Balance.BALL_SPEED
## Height off the board; it bounces in from the sky at the start of a floor.
var z := 0.0
## Riding on the paddle, waiting to be launched, at this offset from its middle.
var held := false
var held_offset := 0.0
## Stuck to a Magnet paddle: let go when this runs out.
var hold_time := 0.0
## Blocks it will still go straight through (a smash, or fire).
var pierce := 0
## A smashed ball glows until it next meets the paddle.
var smashed := false
var flash := 0.0
## Squash and stretch: 1 is round; set on a hit and springs back.
var squash := 1.0
var squash_angle := 0.0
## Where it has been, for the trail.
var trail: PackedVector2Array = []
var dead := false
## Seconds since it last touched the paddle or a block (to nudge a ball stuck between walls).
var idle := 0.0


func direction() -> Vector2:
	return vel.normalized() if vel != Vector2.ZERO else Vector2.UP


func set_direction(dir: Vector2) -> void:
	vel = dir.normalized() * speed


## Keeps it off the flat: never closer to horizontal than BALL_MIN_ANGLE.
func fix_angle() -> void:
	var dir := direction()
	var min_y := sin(Balance.BALL_MIN_ANGLE)
	if absf(dir.y) < min_y:
		dir.y = min_y * (signf(dir.y) if dir.y != 0.0 else -1.0)
		dir.x = signf(dir.x) * sqrt(1.0 - dir.y * dir.y) if dir.x != 0.0 else sqrt(1.0 - dir.y * dir.y)
	vel = dir.normalized() * speed
