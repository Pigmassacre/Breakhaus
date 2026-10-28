class_name Pixels
## Effects drawn in whole art pixels on the board's own grid, so that a ring,
## a spark or a bolt is made of the same size of pixel as the blocks and
## sprites round it. Sprites still move smoothly between pixels; their
## effects snap to the grid. Every size here is in art pixels (PX board
## units each).

const PX := Balance.PX


## The grid cell `at` is in (its top left corner, in board units).
static func snap(at: Vector2) -> Vector2:
	return (at / PX).floor() * PX


## A square `size` pixels across (at least one) round `center`, on the grid.
static func square(canvas: CanvasItem, center: Vector2, size: int, color: Color) -> void:
	size = maxi(size, 1)
	canvas.draw_rect(Rect2(snap(center - Vector2.ONE * (size * PX * 0.5) + Vector2.ONE * PX * 0.5), Vector2.ONE * size * PX), color)


## A rectangle `w` by `h` pixels round `center`, on the grid.
static func rect(canvas: CanvasItem, center: Vector2, w: int, h: int, color: Color) -> void:
	var size := Vector2(maxi(w, 1), maxi(h, 1)) * PX
	canvas.draw_rect(Rect2(snap(center - size * 0.5 + Vector2.ONE * PX * 0.5), size), color)


## A ring `radius` pixels out from `center` and `width` pixels thick: every cell whose middle is in it.
static func ring(canvas: CanvasItem, center: Vector2, radius: float, width: int, color: Color) -> void:
	# Centred on a grid corner, so the ring comes out the same all the way round.
	var c := (center / PX).round()
	var reach := ceili(radius) + 1
	var inner := radius - width
	for y in range(-reach, reach):
		for x in range(-reach, reach):
			var d := Vector2(x + 0.5, y + 0.5).length()
			if d <= radius and d > inner:
				canvas.draw_rect(Rect2((c + Vector2(x, y)) * PX, Vector2(PX, PX)), color)


## A line of pixels from `a` to `b`, `width` thick. Cells already in `drawn` (Vector2i keys) are skipped,
## so a see-through polyline doesn't darken where its pieces meet; pass one Dictionary for a whole line.
static func line(canvas: CanvasItem, a: Vector2, b: Vector2, color: Color, width := 1, drawn := {}) -> void:
	var from := (a / PX).floor()
	var to := (b / PX).floor()
	var steps := maxi(int(maxf(absf(to.x - from.x), absf(to.y - from.y))), 1)
	var half := (width - 1) / 2
	for i in steps + 1:
		var cell := Vector2i(from.lerp(to, float(i) / steps).round())
		for oy in range(-half, width - half):
			for ox in range(-half, width - half):
				var at := cell + Vector2i(ox, oy)
				if drawn.has(at):
					continue
				drawn[at] = true
				canvas.draw_rect(Rect2(Vector2(at) * PX, Vector2(PX, PX)), color)
