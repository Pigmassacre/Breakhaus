class_name BlockArt
## How a block looks, drawn in art pixels: a coloured top with a lit edge
## and a shaded one, its front face below, and what marks its kind (rivets
## and a sheen on steel, the stripe and fuse on TNT, a rainbow in a prize,
## a glint on gold, spots of moss, studs on the tough ones), with cracks as
## it wears, frost and fire over it. The board draws every block with this,
## and How to play its examples.

const PX := Balance.PX


## Draws block `b` into `canvas`, its footprint's top left at `p` (already lifted by its height).
static func draw(canvas: CanvasItem, b: Block, p: Vector2, clock: float) -> void:
	var bw := Balance.BLOCK_W
	var depth := Balance.BLOCK_DEPTH
	var c := b.shade()
	var top := Rect2(p.x, p.y - depth, bw, Balance.ROW_H)
	var front := Rect2(p.x, p.y + Balance.ROW_H - depth, bw, depth)
	# The front face (only seen where nothing stands in front of it), then the top.
	canvas.draw_rect(front, c.darkened(0.5))
	canvas.draw_rect(Rect2(front.position.x, front.end.y - PX, bw, PX), c.darkened(0.7))
	canvas.draw_rect(top, c)
	canvas.draw_rect(Rect2(top.position, Vector2(bw, PX)), c.lightened(0.4))
	canvas.draw_rect(Rect2(top.position + Vector2(0, PX), Vector2(PX, Balance.ROW_H - PX)), c.lightened(0.15))
	canvas.draw_rect(Rect2(top.end.x - PX, top.position.y + PX, PX, Balance.ROW_H - PX), c.darkened(0.18))
	_kind(canvas, b, top, c, clock)
	if b.hp < b.max_hp and b.kind != Block.Kind.STEEL:
		_cracks(canvas, b, top, c.darkened(0.6))
	if b.frozen:
		_frost(canvas, b, top)
	if b.burning > 0.0:
		var flame := Color(1.0, 0.45 + 0.3 * sin(clock * 25.0 + b.col), 0.1, 0.45)
		canvas.draw_rect(top, flame)


static func _kind(canvas: CanvasItem, b: Block, top: Rect2, c: Color, clock: float) -> void:
	var o := top.position
	match b.kind:
		Block.Kind.STEEL:
			# Rivets, cracks as it gives, and a sheen that runs across every so often.
			var rivet := c.darkened(0.45)
			for x in [PX, Balance.BLOCK_W - PX * 2.0]:
				canvas.draw_rect(Rect2(o + Vector2(x, PX * 2.0), Vector2(PX, PX)), rivet)
			var sweep := fmod(clock * 0.6 + b.col * 0.07 + b.row * 0.03, 2.0) * Balance.BLOCK_W * 2.0
			for i in 2:
				var x := snappedf(sweep - Balance.BLOCK_W * 0.5, PX) + i * PX * 2.0
				if x >= 0.0 and x < Balance.BLOCK_W - PX:
					canvas.draw_rect(Rect2(o + Vector2(x, PX), Vector2(PX, Balance.ROW_H - PX * 2.0)), Color(1, 1, 1, 0.45 - i * 0.2))
			if b.hp < b.max_hp:
				var dark := c.darkened(0.6)
				var worn := b.max_hp - b.hp
				for i in worn:
					canvas.draw_rect(Rect2(o + Vector2(PX * (3 + i * 2), PX * (2 + i % 3)), Vector2(PX, PX)), dark)
		Block.Kind.TNT:
			canvas.draw_rect(Rect2(o + Vector2(0, PX * 2.0), Vector2(Balance.BLOCK_W, PX * 2.0)), Color("2b1010"))
			for i in 3:
				canvas.draw_rect(Rect2(o + Vector2(PX * (2 + i * 3), PX * 2.0), Vector2(PX * 2.0, PX)), Color("ffd23d"))
			# The fuse, flickering.
			if fmod(clock * 6.0 + b.col, 1.0) < 0.5:
				canvas.draw_rect(Rect2(o + Vector2(Balance.BLOCK_W - PX * 3.0, -PX), Vector2(PX, PX)), Color("ffd23d"))
		Block.Kind.PRIZE:
			# A rainbow that moves through it, and a sparkle.
			var hue := fmod(clock * 0.5 + b.col * 0.08 + b.row * 0.05, 1.0)
			canvas.draw_rect(Rect2(o + Vector2(PX, PX), Vector2(Balance.BLOCK_W - PX * 2.0, Balance.ROW_H - PX * 2.0)), Color.from_hsv(hue, 0.55, 1.0))
			canvas.draw_rect(Rect2(o + Vector2(PX * 5.0, PX * 2.0), Vector2(PX * 2.0, PX * 2.0)), Color.WHITE)
		Block.Kind.GOLD:
			var glint := int(fmod(clock * 8.0 + b.col * 3.0, 24.0))
			if glint < 10:
				canvas.draw_rect(Rect2(o + Vector2(PX * (1 + glint), PX), Vector2(PX, PX)), Color.WHITE)
			canvas.draw_rect(Rect2(o + Vector2(PX * 4.0, PX * 2.0), Vector2(PX * 4.0, PX * 2.0)), c.darkened(0.25))
		Block.Kind.MOSS:
			var spot := c.darkened(0.35)
			for i in 3:
				var sx := float((b.col * 7 + b.row * 3 + i * 5) % 10 + 1)
				canvas.draw_rect(Rect2(o + Vector2(PX * sx, PX * (1 + i % 3)), Vector2(PX, PX)), spot)
			canvas.draw_rect(Rect2(o + Vector2(PX * 2.0, Balance.ROW_H), Vector2(PX, PX)), c.darkened(0.2))
		Block.Kind.NORMAL:
			if b.max_hp >= 2:
				# Tougher blocks are studded: a stud for every hit beyond the first.
				for i in b.max_hp - 1:
					canvas.draw_rect(Rect2(o + Vector2(PX * (4 + i * 3), PX * 2.0), Vector2(PX * 2.0, PX * 2.0)), c.darkened(0.3))


static func _cracks(canvas: CanvasItem, b: Block, top: Rect2, dark: Color) -> void:
	var o := top.position
	var seed := (b.col * 13 + b.row * 7) % 5
	var steps := (b.max_hp - b.hp) * 4
	var x := PX * (3 + seed)
	var y := 0.0
	for i in steps:
		canvas.draw_rect(Rect2(o + Vector2(x, y), Vector2(PX, PX)), dark)
		y += PX
		x += PX * (1 if (i + seed) % 3 != 0 else -1)
		if y >= Balance.ROW_H:
			y = PX
			x = PX * (8 - seed)


static func _frost(canvas: CanvasItem, b: Block, top: Rect2) -> void:
	var o := top.position
	var ice := Color(0.85, 0.97, 1.0, 0.9)
	canvas.draw_rect(Rect2(o, Vector2(Balance.BLOCK_W, PX)), ice)
	var s := (b.col * 5 + b.row * 3) % 7
	canvas.draw_rect(Rect2(o + Vector2(PX * (2 + s), PX * 2.0), Vector2(PX, PX)), ice)
	canvas.draw_rect(Rect2(o + Vector2(PX * (1 + s), PX * 3.0), Vector2(PX * 3.0, PX)), Color(1, 1, 1, 0.5))
