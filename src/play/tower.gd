class_name Tower
extends Control
## The haus, beside the board when the screen is wide enough, drawn flat
## like the rest of the HUD: its floors stacked from the top floor to the
## ground and the basements under it, the ones you have broken through
## gone to rubble, the one you are on lit up with a marker bobbing beside
## it, and the dark ones still to come below.

const FLOOR_H := 54.0
const GAP := 6.0
const WIDTH := 132.0
const RADIUS := 10.0

var level := 0
var clock := 0.0
## The marker eases from floor to floor rather than jumping.
var _marker_y := -1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	clock += delta
	queue_redraw()


func _draw() -> void:
	# The basements shown: down to two below where you are.
	var basements := maxi(level - Balance.FLOORS + 3, 2)
	var total := Balance.FLOORS + basements
	# Scrolls down with you once you are under the ground.
	var scroll := maxf(level - Balance.FLOORS - 1, 0) * (FLOOR_H + GAP)
	var top := 44.0 - scroll
	var x := size.x - WIDTH - 50.0
	var font := UI.body_font()
	var font_size := UI.font_size(2)
	# The roof, its mast and the light on top.
	if top > -40.0:
		UI.draw_round(self, Rect2(x - 10.0, top - 22.0, WIDTH + 20.0, 16.0), Color("6b2a63"), 8.0)
		UI.draw_round(self, Rect2(x + 24.0, top - 52.0, 6.0, 34.0), Color("6b2a63"), 3.0)
		var on := fmod(clock, 1.0) < 0.6
		if on:
			draw_circle(Vector2(x + 27.0, top - 54.0), 12.0, Color(UI.ACCENT, 0.3), true, -1.0, true)
		draw_circle(Vector2(x + 27.0, top - 54.0), 6.0, UI.ACCENT if on else Color("6b2a63"), true, -1.0, true)
	var ground_y := 0.0
	for i in total:
		var y := top + i * (FLOOR_H + GAP) + (24.0 if i >= Balance.FLOORS else 0.0)
		if i == Balance.FLOORS:
			ground_y = y - 15.0
		if y > size.y or y + FLOOR_H < 0.0:
			continue
		var t := Floors.theme(i)
		var r := Rect2(x, y, WIDTH, FLOOR_H)
		if i < level:
			_rubble(r, i)
		elif i == level:
			var lit: Color = t["floor"]
			var pulse := 0.5 + 0.5 * sin(clock * 6.0)
			UI.draw_round(self, r.grow(4.0 + pulse * 3.0), Color(UI.INK, 0.5 + pulse * 0.4), RADIUS + 4.0)
			UI.draw_round(self, r, lit.lightened(0.1), RADIUS)
			_windows(r, Color(t["light"]).lightened(0.3), true)
			if _marker_y < 0.0:
				_marker_y = y
			_marker_y = lerpf(_marker_y, y, 0.12)
		else:
			UI.draw_round(self, r, Color(t["ray_b"]).lightened(0.12), RADIUS)
			_windows(r, Color(t["ray_b"]).lightened(0.28), false)
		# The floor's name beside it.
		var color := UI.INK if i == level else (UI.DIM if i > level else Color("6b5a6b"))
		draw_string(font, Vector2(x - 120.0, y + FLOOR_H * 0.5 + font_size * 0.35), Floors.label(i),
			HORIZONTAL_ALIGNMENT_RIGHT, 92.0, font_size, color)
	# You are here: a pink arrow bobbing beside your floor.
	if _marker_y >= 0.0:
		var my := _marker_y + FLOOR_H * 0.5
		var mx := x + WIDTH + 18.0 + sin(clock * 5.0) * 5.0
		draw_colored_polygon(PackedVector2Array([Vector2(mx, my), Vector2(mx + 22.0, my - 15.0), Vector2(mx + 22.0, my + 15.0)]), UI.ACCENT)
	# The ground.
	if ground_y > -10.0 and ground_y < size.y:
		UI.draw_round(self, Rect2(x - 40.0, ground_y, WIDTH + 80.0, 10.0), Color("5fae3a"))


func _windows(r: Rect2, color: Color, lit: bool) -> void:
	var count := 4
	var w := 18.0
	var gap := (r.size.x - count * w) / (count + 1)
	for n in count:
		var wx := r.position.x + gap + n * (w + gap)
		var on := lit or hash(n * 7 + int(r.position.y)) % 3 == 0
		UI.draw_round(self, Rect2(wx, r.position.y + 14.0, w, r.size.y - 28.0), color if on else color.darkened(0.45), 5.0)


func _rubble(r: Rect2, i: int) -> void:
	UI.draw_round(self, Rect2(r.position.x, r.end.y - 14.0, r.size.x, 14.0), Color("2a1d2a"), 6.0)
	var bx := r.position.x + 6.0
	var n := 0
	while bx < r.end.x - 16.0:
		var h := 8.0 + float(hash(i * 31 + n) % 4) * 6.0
		var lean := float(hash(i * 17 + n) % 7 - 3) * 2.0
		var c := Color("3d2a3d").lightened(0.06 * (n % 3))
		draw_colored_polygon(PackedVector2Array([Vector2(bx, r.end.y - 10.0), Vector2(bx + 22.0, r.end.y - 10.0),
			Vector2(bx + 11.0 + lean, r.end.y - 10.0 - h)]), c)
		bx += 18.0
		n += 1
