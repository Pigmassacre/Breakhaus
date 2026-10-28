extends Control
## How to play, in three pages: the rules and the controls, the blocks and
## the tricks, and the pickups (each with its real block or icon beside it).
## Left and right (or the arrows on screen) turn the pages.

const PAGES := 3

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
	for page: Control in [_rules(), _blocks(), _pickups()]:
		page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		holder.add_child(page)
		_pages.append(page)
	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 20)
	column.add_child(nav)
	var prev := UI.button("<", func() -> void: _turn(-1), 90)
	_page_label = UI.label("", 2, UI.DIM)
	_page_label.custom_minimum_size = Vector2(90, 0)
	var next := UI.button(">", func() -> void: _turn(1), 90)
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
	box.add_child(_text("THE WALL OF BLOCKS COMES DOWN A ROW AT A TIME. IF IT CROSSES THE RED LINE, THE HAUS WINS."))
	box.add_child(_text("EVERY BLOCK YOU BREAK HOLDS IT BACK A LITTLE. LET THE BALL PAST YOUR PADDLE AND IT GAINS ON YOU.", 2, UI.DIM))
	box.add_child(_text("CLEAR A FLOOR TO CRASH DOWN TO THE NEXT. EIGHT FLOORS TO THE GROUND... THEN THE BASEMENTS.", 2, UI.DIM))
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
	box.add_child(_text("SMASH JUST AS THE BALL MEETS THE PADDLE: IT FLIES OFF FAST AND PLOUGHS THROUGH THREE BLOCKS.", 2, UI.GOLD))
	return box


func _blocks() -> Control:
	var box := _page_box("BLOCKS")
	var kinds := [
		[Block.Kind.NORMAL, 1, "ONE HIT."],
		[Block.Kind.NORMAL, 3, "STUDDED: A HIT FOR EVERY STUD, AND ONE MORE."],
		[Block.Kind.STEEL, Balance.STEEL_HP, "STEEL: FIVE HITS, AND IT WON'T BURN."],
		[Block.Kind.TNT, 1, "TNT: TAKES ITS NEIGHBOURS WITH IT."],
		[Block.Kind.PRIZE, 1, "PRIZE: ALWAYS HOLDS A PICKUP."],
		[Block.Kind.GOLD, 1, "GOLD: A PILE OF POINTS."],
		[Block.Kind.MOSS, 1, "MOSS: GROWS EVERY TIME THE WALL COMES DOWN."],
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
	box.add_child(_text("COMBO: BREAK BLOCKS QUICKLY ONE AFTER ANOTHER TO MULTIPLY YOUR POINTS.", 2, UI.GOLD))
	box.add_child(_text("QUAKE: BREAKING BLOCKS CHARGES IT. SET IT OFF TO BRING DOWN THE BOTTOM THREE ROWS.", 2, Color("ffb03b")))
	return box


func _pickups() -> Control:
	var box := _page_box("PICKUPS")
	box.add_child(_text("PRIZE BLOCKS (AND NOW AND THEN ANY BLOCK) LET ONE GO. CATCH IT WITH THE PADDLE OR HIT IT WITH A BALL.", 2, UI.DIM))
	box.add_child(_gap(6))
	for kind: Pickups.Kind in Pickups.INFO:
		var info := Pickups.info(kind)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 20)
		var sample := _Sample.new()
		sample.pickup = kind
		sample.help = self
		sample.custom_minimum_size = Vector2(60, 44)
		row.add_child(sample)
		var l := UI.label("%s: %s" % [String(info["name"]).to_upper(), String(info["blurb"]).to_upper()], 2,
			Color("ff7a6a") if info.get("bad", false) else UI.INK, HORIZONTAL_ALIGNMENT_LEFT)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(580, 0)
		row.add_child(l)
		box.add_child(row)
	return box


## A block or a pickup, drawn as on the board.
class _Sample extends Control:
	var block: Block
	var pickup := -1
	var help: Control

	func _init() -> void:
		custom_minimum_size = Vector2(Balance.BLOCK_W + 8, Balance.ROW_H + Balance.BLOCK_DEPTH + 8)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var clock: float = help._clock if help else 0.0
		if block:
			draw_rect(Rect2(Vector2(6 + Balance.PX * 1.5, 4 + Balance.BLOCK_DEPTH + Balance.PX * 1.5), Vector2(Balance.BLOCK_W, Balance.ROW_H)), Color(0, 0, 0, 0.35))
			BlockArt.draw(self, block, Vector2(4, 4 + Balance.BLOCK_DEPTH), clock)
		elif pickup >= 0:
			Pickups.draw_icon(self, pickup, size * 0.5 - Vector2(0, sin(clock * 5.0) * 3.0), Balance.PX)
