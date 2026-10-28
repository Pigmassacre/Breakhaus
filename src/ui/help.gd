extends Control
## How to play, page by page: the rules and the controls, the blocks, the
## tricks, the pickups, and the rare ones on a showcase of their own (each
## with its real block or icon beside it, the pickups framed in the colours
## of their rarity).
## Left and right (or the arrows on screen) turn the pages.

const PAGES := 6

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
	for page: Control in [_rules(), _blocks(), _tricks(), _pickups(), _rares(), _synergies()]:
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
	box.add_child(_text("The wall drops a row at a time. If it reaches the red line, it's game over."))
	box.add_child(_text("Keep breaking the bottom rows. Every miss brings the wall closer.", 2, UI.DIM))
	box.add_child(_text("Clear a floor to drop to the next one and pick a perk. Eight floors, then the basements. Bosses wait at the bottom of the Lobby and every fourth basement.", 2, UI.DIM))
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
	return box


func _blocks() -> Control:
	var box := _page_box("BLOCKS")
	var kinds := [
		[Block.Kind.NORMAL, 1, "One hit."],
		[Block.Kind.NORMAL, 3, "Studded: one hit per stud, plus one."],
		[Block.Kind.STEEL, Balance.STEEL_HP, "Steel: five hits. Fireproof."],
		[Block.Kind.TNT, 1, "TNT: blows up its neighbors."],
		[Block.Kind.PRIZE, 1, "Prize: always drops a pickup."],
		[Block.Kind.GOLD, 1, "Gold: lots of points."],
		[Block.Kind.MOSS, 1, "Moss: spreads every time the wall drops."],
		[Block.Kind.BUMPER, Balance.BUMPER_HP, "Bumper: kicks the ball back faster."],
		[Block.Kind.PORTAL, 2, "Portal: in one, out the other."],
		[Block.Kind.ICE, 1, "Ice: shatters, and so does all the ice touching it."],
		[Block.Kind.FUSE, 1, "Fuse: hit to light it. Then it blows up its whole row."],
		[Block.Kind.COIN, 1, "Coin: worth more the sooner you break it."],
	]
	box.add_theme_constant_override("separation", 8)
	for k: Array in kinds:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 20)
		var sample := _Sample.new()
		sample.block = Block.new().setup({"kind": k[0], "hp": k[1], "color": Block.kind_color(k[0], Color("ff4fa3")), "link": 3}, 0, 0)
		sample.help = self
		row.add_child(sample)
		var l := UI.label(k[2], 2, UI.INK, HORIZONTAL_ALIGNMENT_LEFT)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(560, 0)
		row.add_child(l)
		box.add_child(row)
	return box


func _tricks() -> Control:
	var box := _page_box("TRICKS")
	box.add_theme_constant_override("separation", 22)
	box.add_child(_text("Smash right as the ball hits your paddle to send it flying through three blocks.", 2, Color("fff23d")))
	box.add_child(_text("Move the paddle as the ball hits it to put spin on the ball. The faster you move, the more it curves.", 2, UI.INK))
	box.add_child(_text("Break blocks in quick succession to build a combo. Reach x8 to trigger Fever and smash through everything.", 2, UI.GOLD))
	box.add_child(_text("Clear the whole board for a big bonus (and six new rows).", 2, Color("3dffb1")))
	box.add_child(_text("Breaking blocks charges your Quake; every miss drains it. Use it to wipe out the bottom three rows.", 2, Color("ffb03b")))
	return box


func _pickups() -> Control:
	var box := _page_box("PICKUPS")
	box.add_theme_constant_override("separation", 10)
	box.add_child(_text("Prize blocks drop pickups, and other blocks sometimes do too. Catch them with your paddle or hit them with the ball.", 2, UI.DIM))
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
	box.add_child(_text("Only about 1 in %d pickups is rare. Look for the gold beam, and don't let it fall!" % roundi(total / rare), 2, UI.DIM))
	for kind: Pickups.Kind in Pickups.INFO:
		if Pickups.rarity(kind) == Pickups.Rarity.RARE:
			box.add_child(PickupCard.new(kind, true))
	return box


## Two pickups at once that make something more, each with both icons.
func _synergies() -> Control:
	var box := _page_box("SYNERGIES")
	box.add_theme_constant_override("separation", 18)
	box.add_child(_text("Some pickups work together. Get both going at once:", 2, UI.DIM))
	for s: Dictionary in Pickups.SYNERGIES:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		var icons := Control.new()
		icons.custom_minimum_size = Vector2(130, 56)
		icons.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icons.draw.connect(func() -> void:
			Pickups.draw_icon(icons, s["a"], Vector2(28, 28), 4.0)
			Pickups.draw_icon(icons, s["b"], Vector2(100, 28), 4.0)
			icons.draw_rect(Rect2(56, 26, 16, 4), UI.DIM)
			icons.draw_rect(Rect2(62, 20, 4, 16), UI.DIM))
		row.add_child(icons)
		var words := VBoxContainer.new()
		words.add_theme_constant_override("separation", 0)
		words.add_child(UI.label(String(s["name"]).to_upper(), 3, s["color"], HORIZONTAL_ALIGNMENT_LEFT))
		var blurb := UI.label(s["blurb"], 1, UI.INK, HORIZONTAL_ALIGNMENT_LEFT)
		blurb.add_theme_font_size_override("font_size", 17)
		blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		blurb.custom_minimum_size = Vector2(500, 0)
		words.add_child(blurb)
		row.add_child(words)
		box.add_child(row)
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
