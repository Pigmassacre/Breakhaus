extends Control
## Pigmassacre's pig, put together tile by tile (splash.gdshader), held a
## moment, then on to the title. Any press skips it.

const HOLD := 2.6

var _material := ShaderMaterial.new()
var _time := 0.0
var _leaving := false


func _ready() -> void:
	UI.screen_root(self)
	var bg := ColorRect.new()
	bg.color = Color("242424")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 30)
	add_child(column)
	var pig := TextureRect.new()
	pig.texture = load("res://assets/logo/pigmassacre.png")
	pig.custom_minimum_size = Vector2(500, 500)
	pig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pig.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pig.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_material.shader = preload("res://src/ui/splash.gdshader")
	pig.material = _material
	column.add_child(pig)
	var name_label := UI.label("PIGMASSACRE", 5, Color("ff8fa8"))
	name_label.modulate.a = 0.0
	column.add_child(name_label)
	var t := create_tween()
	t.tween_interval(1.0)
	t.tween_callback(func() -> void: Audio.play("splash", -2.0))
	t.tween_property(name_label, "modulate:a", 1.0, 0.4)


func _process(delta: float) -> void:
	_time += delta
	_material.set_shader_parameter("progress", clampf(_time / 1.1, 0.0, 1.0))
	if _time > HOLD:
		_leave()


func _input(event: InputEvent) -> void:
	if _time > 0.3 and (event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch \
			or event is InputEventJoypadButton) and event.is_pressed():
		_leave()


func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	Game.goto("title")
