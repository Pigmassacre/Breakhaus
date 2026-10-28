class_name Backdrop
extends ColorRect
## The rays turning behind everything (sunrays.gdshader), filling the
## screen whatever its shape, in the colours of the floor being played.

## Where the rays turn round; until something sets it, the middle of the screen.
var center := Vector2(-1.0, -1.0)
var danger := 0.0
var speed := 0.08
## 0 to 1: the rays gone rainbow (Fever).
var fever := 0.0
## How fast the dust drifts up, in art pixels a second (fast while falling between floors).
var rise_speed := 6.0
var _rise := 0.0
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
	_rise = fmod(_rise + delta * rise_speed, 4096.0 * 64.0)
	_material.set_shader_parameter("size", size)
	_material.set_shader_parameter("center", center if center.x >= 0.0 else size * 0.5)
	_material.set_shader_parameter("turn", _turn)
	_material.set_shader_parameter("clock", _clock)
	_material.set_shader_parameter("danger", danger)
	_material.set_shader_parameter("fever", fever)
	_material.set_shader_parameter("rise", _rise)


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
	# A kick round; whoever owns it eases the speed back.
	speed = 1.5
