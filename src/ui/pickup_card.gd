class_name PickupCard
extends Control
## A pickup in How to play: its icon in a frame of its rarity's colour, its
## name, a tag with the rarity in stars, and what it does. The rarer, the
## louder: an uncommon one's frame glows; a rare one turns a sunburst
## behind its icon, sends a shine over its tag and twinkles. `big` is the
## rare page's showcase size.

const WIDTH := 660.0

var kind: Pickups.Kind
var big := false
var _clock := randf() * 10.0
var _icon: Control
var _tile := 56.0


func _init(pickup: Pickups.Kind, showcase := false) -> void:
	kind = pickup
	big = showcase


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tile = 104.0 if big else 60.0
	var info := Pickups.info(kind)
	var rarity := Pickups.rarity(kind)
	custom_minimum_size = Vector2(WIDTH, _tile + (8.0 if big else 6.0))
	var text_x := _tile + 22.0
	var title := UI.label(String(info["name"]).to_upper(), 3 if big else 2, Pickups.RARITY_COLOR[rarity].lerp(UI.INK, 0.35) if rarity != Pickups.Rarity.COMMON else UI.INK, HORIZONTAL_ALIGNMENT_LEFT)
	if info.get("bad", false):
		title.add_theme_color_override("font_color", Color("ff7a6a"))
	title.position = Vector2(text_x, 0.0 if big else -2.0)
	title.size = Vector2(WIDTH - text_x - 150.0, 40.0 if big else 28.0)
	add_child(title)
	var blurb := UI.label(info["blurb"], 1, UI.DIM, HORIZONTAL_ALIGNMENT_LEFT)
	blurb.add_theme_font_size_override("font_size", 19 if big else 17)
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	blurb.position = Vector2(text_x, 44.0 if big else 26.0)
	blurb.size = Vector2(WIDTH - text_x, _tile)
	add_child(blurb)
	# The pixel-art icon on a layer of its own, filtered sharp.
	_icon = Control.new()
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_icon.size = Vector2(_tile, _tile)
	_icon.draw.connect(_draw_icon)
	add_child(_icon)


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()
	_icon.queue_redraw()


func _draw() -> void:
	var rarity := Pickups.rarity(kind)
	var color: Color = Pickups.RARITY_COLOR[rarity]
	var frame := Rect2(0, 0, _tile, _tile)
	var pulse := 0.5 + 0.5 * sin(_clock * 3.0)
	match rarity:
		Pickups.Rarity.UNCOMMON:
			UI.draw_round(self, frame.grow(3.0 + pulse * 3.0), Color(color, 0.18 + pulse * 0.12), 18.0)
		Pickups.Rarity.RARE:
			UI.draw_round(self, frame.grow(5.0 + pulse * 5.0), Color(color, 0.22 + pulse * 0.18), 22.0)
	UI.draw_round(self, frame, color if rarity != Pickups.Rarity.COMMON else Color(color, 0.5), 14.0)
	UI.draw_round(self, frame.grow(-4.0), Color("1d0b24"), 11.0)
	# A rare one's sunburst, turning behind the icon.
	if rarity == Pickups.Rarity.RARE:
		var c := frame.get_center()
		var reach := _tile * 0.46
		for i in 10:
			var a := _clock * 0.8 + i * TAU / 10.0
			var ray := PackedVector2Array([c, c + Vector2.from_angle(a - 0.13) * reach, c + Vector2.from_angle(a + 0.13) * reach])
			draw_colored_polygon(ray, Color(color, 0.22))
		draw_circle(c, _tile * 0.3, Color(color, 0.12), true, -1.0, true)
	_draw_tag(rarity, color)
	if rarity == Pickups.Rarity.RARE:
		_draw_sparkles(frame, color)


## The rarity's tag, top right: a pill in its colour with a star for each step of rarity and its name;
## a rare one has a shine running over it.
func _draw_tag(rarity: Pickups.Rarity, color: Color) -> void:
	var font := UI.body_font()
	var text: String = String(Pickups.RARITY_NAME[rarity]).to_upper()
	var font_size := 15
	var stars := int(rarity) + 1
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + stars * 16.0 + 26.0
	var pill := Rect2(WIDTH - w, 2.0 if big else 0.0, w, 24.0)
	var fill := color if rarity != Pickups.Rarity.COMMON else Color("4a3a55")
	UI.draw_round(self, pill, fill)
	var ink := Color("1d0b24") if rarity != Pickups.Rarity.COMMON else UI.INK
	for i in stars:
		_star(pill.position + Vector2(16.0 + i * 16.0, 12.0), 7.0, ink)
	draw_string(font, pill.position + Vector2(10.0 + stars * 16.0, 17.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink)
	if rarity == Pickups.Rarity.RARE:
		# The shine: a slanted band of light sweeping across every couple of seconds.
		var sweep := fmod(_clock * 0.6, 1.0) * (pill.size.x + 60.0) - 30.0
		var x0 := clampf(pill.position.x + sweep - 8.0, pill.position.x + 6.0, pill.end.x - 6.0)
		var x1 := clampf(pill.position.x + sweep + 8.0, pill.position.x + 6.0, pill.end.x - 6.0)
		if x1 - x0 > 1.0:
			draw_colored_polygon(PackedVector2Array([
				Vector2(x0 + 5.0, pill.position.y), Vector2(x1 + 5.0, pill.position.y),
				Vector2(x1 - 5.0, pill.end.y), Vector2(x0 - 5.0, pill.end.y)]), Color(1, 1, 1, 0.45))


## Four-pointed sparkles twinkling at the frame's corners, each in its own time.
func _draw_sparkles(frame: Rect2, color: Color) -> void:
	var spots := [frame.position + Vector2(-4, -4), Vector2(frame.end.x + 4, frame.position.y + 10),
		frame.end + Vector2(2, 2), Vector2(frame.position.x - 2, frame.end.y - 12)]
	for i in spots.size():
		var t := 0.5 + 0.5 * sin(_clock * 4.0 + i * 1.9)
		var r := 3.0 + t * 6.0
		var at: Vector2 = spots[i]
		var glint := Color(Color.WHITE.lerp(color, 0.4), t)
		draw_colored_polygon(PackedVector2Array([at + Vector2(0, -r), at + Vector2(r * 0.25, 0), at + Vector2(0, r), at + Vector2(-r * 0.25, 0)]), glint)
		draw_colored_polygon(PackedVector2Array([at + Vector2(-r, 0), at + Vector2(0, r * 0.25), at + Vector2(r, 0), at + Vector2(0, -r * 0.25)]), glint)


func _star(at: Vector2, r: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 10:
		points.append(at + Vector2.from_angle(-PI * 0.5 + i * PI / 5.0) * (r if i % 2 == 0 else r * 0.45))
	draw_colored_polygon(points, color)


## The icon in whole pixels (four screen pixels to one of its own, eight on the showcase), bobbing.
func _draw_icon() -> void:
	var scale := 8.0 if big else 4.0
	var bob := roundf(sin(_clock * 3.0) * 2.0) * (scale / 4.0)
	Pickups.draw_icon(_icon, kind, Vector2(_tile * 0.5, _tile * 0.5 + bob), scale)
