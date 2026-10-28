class_name PerkPick
extends CanvasLayer
## Between floors: three perks to pick from, one a card, each with its
## icon, what it does and how many of it you have. The cards only take a
## press once they have popped in, so a smash still held from the floor
## can't pick one by accident.

signal chosen(id: String)

const ARM_TIME := 0.7

var _offer: Array[String] = []
var _owned := {}
var _cards: Array[Button] = []
var _armed := false
var _done := false


func _init(offer: Array[String], owned: Dictionary) -> void:
	layer = 20
	_offer = offer
	_owned = owned


func _ready() -> void:
	var root := Control.new()
	UI.screen_root(root)
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.02, 0.06, 0.75)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	dim.modulate.a = 0.0
	dim.create_tween().tween_property(dim, "modulate:a", 1.0, 0.25)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 18)
	UI.centered(root, column)
	var title := UI.label("PICK A PERK", 6, UI.ACCENT)
	column.add_child(title)
	column.add_child(UI.label("It lasts the rest of the run.", 2, UI.DIM))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 12)
	column.add_child(gap)
	for id in _offer:
		var card := _card(id)
		column.add_child(card)
		_cards.append(card)
	UI.link_focus(_cards)
	UI.pop_in(title)
	for i in _cards.size():
		UI.pop_in(_cards[i], 0.15 + i * 0.08)
	Audio.play("fanfare", -6.0, 1.1)
	if not _cards.is_empty():
		_cards[0].grab_focus.call_deferred()
	await get_tree().create_timer(ARM_TIME).timeout
	_armed = true
	# The game playing itself picks the first.
	if Game.autoplay or Game.autoplay_lazy:
		await get_tree().create_timer(0.6).timeout
		_pick(_offer[0])


func _card(id: String) -> Button:
	var perk := Perks.info(id)
	var b := UI.button("", func() -> void: _pick(id), 620.0)
	b.custom_minimum_size.y = 132.0
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# The icon on a round patch of its colour, in whole pixels.
	var icon := Control.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.position = Vector2(22, 22)
	icon.size = Vector2(88, 88)
	icon.draw.connect(func() -> void:
		UI.draw_round(icon, Rect2(Vector2.ZERO, icon.size), Color(perk["color"], 0.25), 44.0)
		Perks.draw_icon(icon, id, icon.size * 0.5, 8.0))
	b.add_child(icon)
	var have := int(_owned.get(id, 0))
	var name := UI.label(String(perk["name"]).to_upper(), 3, perk["color"], HORIZONTAL_ALIGNMENT_LEFT)
	name.position = Vector2(132, 18)
	name.size = Vector2(340, 40)
	var blurb := UI.label(perk["blurb"], 2, UI.INK, HORIZONTAL_ALIGNMENT_LEFT)
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.position = Vector2(132, 62)
	blurb.size = Vector2(460, 56)
	# How many you'll have: a pip for each it can go to, the new one lit.
	var level := UI.label("NEW" if have == 0 else "%d / %d" % [have + 1, perk["max"]], 2, UI.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	level.position = Vector2(440, 20)
	level.size = Vector2(156, 32)
	for l: Label in [name, blurb, level]:
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(l)
	# On the hot pink of the focus, the name and the count go white.
	b.focus_entered.connect(func() -> void:
		name.add_theme_color_override("font_color", UI.INK)
		level.add_theme_color_override("font_color", UI.INK))
	b.focus_exited.connect(func() -> void:
		name.add_theme_color_override("font_color", perk["color"])
		level.add_theme_color_override("font_color", UI.GOLD))
	return b


func _pick(id: String) -> void:
	if not _armed or _done:
		return
	_done = true
	Audio.play("pickup", -2.0, 1.1)
	var card := _cards[_offer.find(id)]
	UI.springy(card).kick()
	for other in _cards:
		if other != card:
			other.create_tween().tween_property(other, "modulate:a", 0.0, 0.2)
	await get_tree().create_timer(0.35).timeout
	chosen.emit(id)


func go_back() -> void:
	pass
