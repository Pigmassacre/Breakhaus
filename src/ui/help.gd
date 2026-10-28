extends Control
## How to play, in four pages: the rules and the controls, the blocks and
## the tricks, the pickups, and the rare ones on a showcase of their own
## (each with its real block or icon beside it, the pickups framed in the
## colours of their rarity).
## Left and right (or the arrows on screen) turn the pages.

const PAGES := 4

var _page := 0
var _pages: Array[Control] = []
var _page_label: Label
var _clock := 0.0


func _ready() -> void:
	UI.screen_root(self)
	add_child(Backdrop.new())
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 16)
	add_child(column)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(680, 960)
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(holder)
	for page: Control in [_rules(), _blocks(), _pickups(), _rares()]:
		page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		holder.add_child(page)
		_pages.append(page)
	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 20)
	column.add_child(nav)
	var prev := UI.button("◀", func() -> void: _turn(-1), 90)
	_page_label = UI.label("", 2, UI.DIM)
	_page_label.custom_minimum_size = Vector2(90, 0)
	var next := UI.button("▶", func() -> void: _turn(1), 90)
	var back := UI.button("BACK", go_back, 200)
	for c: Control in [prev, _page_label, next, back]:
		nav.add_child(c)
	for b: Button in [prev, next, back]:
		b.focus_neighbor_top = b.get_path()
		b.focus_neighbor_bottom = b.get_path()
	prev.focus_neighbor_left = back.get_path()
	back.focus_neighbor_right = prev.get_path()
	_show()
	next.grab_focus.call_deferred()


func _process(delta: float) -> void:
	_clock += delta


func _turn(by: int) -> void:
	_page = (_page + by + PAGES) % PAGES
	_show()


func _show() -> void:
	for i in _pages.size():
		_pages[i].visible = i == _page
	_page_label.text = "%d/%d" % [_page + 1, PAGES]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		go_back()


func go_back() -> void:
	Audio.play("back", -2.0)
	Game.goto("title")


func _page_box(title: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	box.add_child(UI.label(title, 5, UI.ACCENT))
	box.add_child(_gap(8))
	return box


func _text(text: String, scale := 2, color := UI.INK) -> Label:
	var l := UI.label(text, scale, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(660, 0)
	return l


func _gap(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _rules() -> Control:
	var box := _page_box("HOW TO PLAY")
	box.add_child(_text("The wall of blocks comes down a row at a time, like clockwork. If it crosses the red line, the haus wins."))
	box.add_child(_text("Keep the bottom rows broken to keep it off the line. Let the ball past your paddle and the wall gains on you.", 2, UI.DIM))
	box.add_child(_text("Clear a floor to crash down to the next. Eight floors to the ground... then the basements.", 2, UI.DIM))
	box.add_child(_gap(16))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var rows := [
		["", "KEYS", "MOUSE", "PAD", "TOUCH"],
		["MOVE", "ARROWS/AD", "MOVE", "STICK", "DRAG"],
		["SMASH", "SPACE", "CLICK", "A / RT", "TAP"],
		["QUAKE", "SHIFT", "R-CLICK", "Y / LT", "BUTTON"],
		["PAUSE", "ESC", "ESC", "START", "II"],
	]
	for r in rows.size():
		for c in rows[r].size():
			var color := UI.ACCENT if r == 0 or c == 0 else UI.INK
			grid.add_child(UI.label(rows[r][c], 2, color, HORIZONTAL_ALIGNMENT_LEFT if c == 0 else HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(grid)
	box.add_child(_gap(16))
	box.add_child(_text("Smash just as the ball meets the paddle: it flies off fast and ploughs through three blocks.", 2, UI.GOLD))
	return box


func _blocks() -> Control:
	var box := _page_box("BLOCKS")
	var kinds := [
		[Block.Kind.NORMAL, 1, "One hit."],
		[Block.Kind.NORMAL, 3, "Studded: a hit for every stud, and one more."],
		[Block.Kind.STEEL, Balance.STEEL_HP, "Steel: five hits, and it won't burn."],
		[Block.Kind.TNT, 1, "TNT: takes its neighbours with it."],
		[Block.Kind.PRIZE, 1, "Prize: always holds a pickup."],
		[Block.Kind.GOLD, 1, "Gold: a pile of points."],
		[Block.Kind.MOSS, 1, "Moss: grows every time the wall comes down."],
	]
	for k: Array in kinds:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 20)
		var sample := _Sample.new()
		sample.block = Block.new().setup({"kind": k[0], "hp": k[1], "color": Block.kind_color(k[0], Color("ff4fa3"))}, 0, 0)
		sample.help = self
		row.add_child(sample)
		var l := UI.label(k[2], 2, UI.INK, HORIZONTAL_ALIGNMENT_LEFT)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(560, 0)
		row.add_child(l)
		box.add_child(row)
	box.add_child(_gap(10))
	box.add_child(_text("Combo: break blocks quickly one after another to multiply your points. Hit x8 and Fever sets in: the ball ploughs through everything. Sweep the board clean for a big bonus, and six more rows.", 2, UI.GOLD))
	box.add_child(_text("Quake: breaking blocks charges it. Set it off to bring down the bottom three rows.", 2, Color("ffb03b")))
	return box


func _pickups() -> Control:
	var box := _page_box("PICKUPS")
	box.add_theme_constant_override("separation", 10)
	box.add_child(_text("Prize blocks (and once in a while any block) let one go. Catch it with the paddle or hit it with a ball.", 2, UI.DIM))
	box.add_child(_gap(4))
	for rarity: Pickups.Rarity in [Pickups.Rarity.COMMON, Pickups.Rarity.UNCOMMON]:
		for kind: Pickups.Kind in Pickups.INFO:
			if Pickups.rarity(kind) == rarity:
				box.add_child(PickupCard.new(kind))
		box.add_child(_gap(6))
	return box


## The rare ones, each on a showcase card, and how rare.
func _rares() -> Control:
	var box := _page_box("RARE PICKUPS")
	(box.get_child(0) as Label).add_theme_color_override("font_color", Pickups.RARITY_COLOR[Pickups.Rarity.RARE])
	box.add_theme_constant_override("separation", 22)
	var total := 0.0
	var rare := 0.0
	for kind: Pickups.Kind in Pickups.INFO:
		total += Pickups.RARITY_WEIGHT[Pickups.rarity(kind)]
		if Pickups.rarity(kind) == Pickups.Rarity.RARE:
			rare += Pickups.RARITY_WEIGHT[Pickups.Rarity.RARE]
	box.add_child(_text("About one pickup in %d is rare: the strongest of them all. When one drops, a gold beam marks it. Don't let it fall!" % roundi(total / rare), 2, UI.DIM))
	for kind: Pickups.Kind in Pickups.INFO:
		if Pickups.rarity(kind) == Pickups.Rarity.RARE:
			box.add_child(PickupCard.new(kind, true))
	return box


## A block, drawn as on the board.
class _Sample extends Control:
	var block: Block
	var help: Control

	func _init() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		custom_minimum_size = Vector2(Balance.BLOCK_W + 8, Balance.ROW_H + Balance.BLOCK_DEPTH + 8)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var clock: float = help._clock if help else 0.0
		if block:
			draw_rect(Rect2(Vector2(6 + Balance.PX * 1.5, 4 + Balance.BLOCK_DEPTH + Balance.PX * 1.5), Vector2(Balance.BLOCK_W, Balance.ROW_H)), Color(0, 0, 0, 0.35))
			BlockArt.draw(self, block, Vector2(4, 4 + Balance.BLOCK_DEPTH), clock)
