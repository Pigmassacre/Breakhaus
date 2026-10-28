class_name Tower
extends Control
## The haus, beside the board when the screen is wide enough: its floors
## stacked from the top floor to the ground and the basements under it,
## the ones you have broken through in rubble, the one you are on lit up
## and blinking, and the dark ones still to come below.

const PX := Balance.PX
const FLOOR_H := 15.0 * PX
const WIDTH := 34.0 * PX

var level := 0
var clock := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	clock += delta
	queue_redraw()


func _draw() -> void:
	# The basements shown: down to two below where you are.
	var basements := maxi(level - Balance.FLOORS + 3, 2)
	var total := Balance.FLOORS + basements
	var ground_y := Balance.FLOORS * FLOOR_H + PX * 6.0
	# Scrolls down with you once you are under the ground.
	var scroll := maxf(level - Balance.FLOORS - 1, 0) * FLOOR_H
	var top := PX * 8.0 - scroll
	var x := (size.x - WIDTH) * 0.5
	# The roof, a sign on it, and the sky.
	if top > -PX * 8.0:
		draw_rect(Rect2(x - PX * 2.0, top - PX * 3.0, WIDTH + PX * 4.0, PX * 3.0), Color("6b2a63"))
		draw_rect(Rect2(x + PX * 6.0, top - PX * 8.0, PX * 2.0, PX * 5.0), Color("6b2a63"))
		draw_rect(Rect2(x + WIDTH - PX * 10.0, top - PX * 7.0, PX * 6.0, PX * 4.0), Color("ff4fa3") if fmod(clock, 1.0) < 0.7 else Color("6b2a63"))
	for i in total:
		var y := top + i * FLOOR_H + (PX * 6.0 if i >= Balance.FLOORS else 0.0)
		if y > size.y or y + FLOOR_H < 0.0:
			continue
		var t := Floors.theme(i)
		var r := Rect2(x, y, WIDTH, FLOOR_H - PX)
		if i < level:
			_rubble(r, i)
		elif i == level:
			var lit: Color = t["floor"]
			draw_rect(r.grow(PX), Color.WHITE if fmod(clock, 0.6) < 0.4 else lit.lightened(0.4))
			draw_rect(r, lit)
			_windows(r, t["light"], true)
		else:
			draw_rect(r, (t["ray_b"] as Color).lightened(0.1))
			_windows(r, (t["ray_b"] as Color).lightened(0.25), false)
		# The floor's name beside it.
		var font := UI.font()
		var color := UI.INK if i == level else (UI.DIM if i > level else Color("6b5a6b"))
		draw_string(font, Vector2(x - PX * 13.0, y + FLOOR_H * 0.7), Floors.label(i), HORIZONTAL_ALIGNMENT_RIGHT,
			PX * 11.0, UI.FONT_PX * 2, color)
	# The ground.
	var gy := top + ground_y - PX * 6.0
	if gy > -PX * 4.0 and gy < size.y:
		draw_rect(Rect2(0, gy + PX, size.x, PX * 4.0), Color("3a2a1a"))
		draw_rect(Rect2(0, gy, size.x, PX), Color("5fae3a"))


func _windows(r: Rect2, color: Color, lit: bool) -> void:
	var wx := r.position.x + PX * 3.0
	while wx + PX * 4.0 < r.end.x:
		var on := lit or hash(int(wx) * 7 + int(r.position.y)) % 3 == 0
		draw_rect(Rect2(wx, r.position.y + PX * 4.0, PX * 4.0, PX * 5.0), color if on else color.darkened(0.5))
		wx += PX * 7.0


func _rubble(r: Rect2, i: int) -> void:
	draw_rect(Rect2(r.position.x, r.end.y - PX * 3.0, r.size.x, PX * 3.0), Color("2a1d2a"))
	var bx := r.position.x
	var n := 0
	while bx < r.end.x - PX * 3.0:
		var h := float(hash(i * 31 + n) % 5 + 1)
		draw_rect(Rect2(bx, r.end.y - PX * (3.0 + h), PX * 3.0, PX * h), Color("3d2a3d").lightened(0.05 * (n % 3)))
		bx += PX * 3.0
		n += 1
