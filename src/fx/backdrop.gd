class_name Backdrop
extends ColorRect
## The rays turning behind everything (sunrays.gdshader), filling the
## screen whatever its shape, in the colours of the floor being played.

var center := Vector2(360, 500)
var danger := 0.0
var speed := 0.08
var _turn := 0.0
var _clock := 0.0
var _material := ShaderMaterial.new()
var _colors_tween: Tween


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_material.shader = preload("res://src/fx/sunrays.gdshader")
	material = _material
	set_theme_colors(Floors.theme(0), 0.0)


func _process(delta: float) -> void:
	_clock += delta
	_turn += delta * speed
	_material.set_shader_parameter("size", size)
	_material.set_shader_parameter("center", center)
	_material.set_shader_parameter("turn", _turn)
	_material.set_shader_parameter("clock", _clock)
	_material.set_shader_parameter("danger", danger)


## Fades over to a floor's colours.
func set_theme_colors(t: Dictionary, seconds := 1.0) -> void:
	if _colors_tween:
		_colors_tween.kill()
	if seconds <= 0.0:
		_material.set_shader_parameter("ray_a", t["ray_a"])
		_material.set_shader_parameter("ray_b", t["ray_b"])
		return
	_colors_tween = create_tween().set_parallel()
	_colors_tween.tween_method(func(c: Color) -> void: _material.set_shader_parameter("ray_a", c),
		_material.get_shader_parameter("ray_a"), t["ray_a"], seconds)
	_colors_tween.tween_method(func(c: Color) -> void: _material.set_shader_parameter("ray_b", c),
		_material.get_shader_parameter("ray_b"), t["ray_b"], seconds)


## A burst of light (a floor cleared), fading over `seconds`.
func bloom(amount := 1.0, seconds := 1.2) -> void:
	var t := create_tween()
	t.tween_method(func(v: float) -> void: _material.set_shader_parameter("bloom", v), amount, 0.0, seconds) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	speed = 1.5
	create_tween().tween_property(self, "speed", 0.08, seconds * 1.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
