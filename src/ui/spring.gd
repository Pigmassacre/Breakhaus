class_name Spring
extends Node
## A bit of life for a control (UI.springy puts one in every button, slider
## and switch): it swells and breathes while it has the focus or the
## pointer, leans toward the pointer over it, squashes when pressed and
## boings back when let go, and wobbles when its value changes. Three damped
## springs (size, squash and lean), run on real time so slow motion and
## pause don't stiffen them.

const STIFFNESS := 420.0
const DAMPING := 15.0
const STEP := 1.0 / 240.0

var target: Control
## How big it gets while it has the focus or the pointer, and how far it leans toward the pointer (radians).
var hot_scale := 1.08
var lean := 0.07

var _size := 1.0
var _size_v := 0.0
var _squash := 0.0
var _squash_v := 0.0
var _tilt := 0.0
var _tilt_v := 0.0
var _hovered := false
var _down := false
var _wait := 0.0
var _last := 0
var _clock := randf() * 10.0
var _last_kick := 0


func _init(control: Control) -> void:
	target = control


func _ready() -> void:
	target.mouse_entered.connect(func() -> void: _hovered = true)
	target.mouse_exited.connect(func() -> void: _hovered = false)
	target.focus_entered.connect(func() -> void:
		_size_v += 3.5
		_squash_v += 2.0
		_tilt_v += randf_range(-1.0, 1.0) * 1.6)
	if target is BaseButton:
		var b := target as BaseButton
		b.button_down.connect(func() -> void:
			_down = true
			# Flattened as it goes down, and stretched tall as it comes back up.
			_squash_v += 5.0)
		b.button_up.connect(func() -> void:
			_down = false
			_squash_v -= 4.0
			_size_v += 2.5)
		b.toggled.connect(func(_on: bool) -> void: kick())
	if target is Range:
		(target as Range).value_changed.connect(func(_v: float) -> void: kick())
	_last = Time.get_ticks_usec()


## A little wobble, as when something changes.
func kick(amount := 1.0) -> void:
	# Not more than one every few frames, so dragging a slider doesn't shake it to bits.
	var now := Time.get_ticks_msec()
	if now - _last_kick < 60:
		return
	_last_kick = now
	_squash_v += 3.0 * amount
	_size_v += 1.5 * amount


## Pops in from nothing after `delay`, overshooting on the way.
func pop(delay := 0.0) -> void:
	_wait = maxf(delay, 0.001)
	_size = 0.0
	_size_v = 0.0
	target.modulate.a = 0.0
	target.scale = Vector2.ZERO


func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var dt := minf((now - _last) / 1000000.0, 0.05)
	_last = now
	if _wait > 0.0:
		_wait -= dt
		if _wait <= 0.0:
			target.create_tween().tween_property(target, "modulate:a", 1.0, 0.15)
			_size_v = 4.0
		else:
			return
	_clock += dt
	var hot := (_hovered or target.has_focus()) and not _is_disabled()
	var size_goal := 1.0
	if _down:
		size_goal = 0.94
	elif hot:
		size_goal = hot_scale + 0.012 * sin(_clock * 5.0)
	var tilt_goal := 0.0
	if _hovered and target.size.x > 0.0:
		var across := target.get_local_mouse_position().x / target.size.x * 2.0 - 1.0
		tilt_goal = clampf(across, -1.0, 1.0) * lean
	while dt > 0.0:
		var h := minf(dt, STEP)
		dt -= h
		_size_v += (STIFFNESS * (size_goal - _size) - DAMPING * _size_v) * h
		_size += _size_v * h
		_squash_v += (STIFFNESS * -_squash - DAMPING * _squash_v) * h
		_squash += _squash_v * h
		_tilt_v += (STIFFNESS * 0.6 * (tilt_goal - _tilt) - DAMPING * _tilt_v) * h
		_tilt += _tilt_v * h
	var q := clampf(_squash, -0.25, 0.25)
	target.pivot_offset = target.size * 0.5
	target.scale = Vector2(_size * (1.0 + q), _size * (1.0 - q))
	target.rotation = _tilt


func _is_disabled() -> bool:
	return target is BaseButton and (target as BaseButton).disabled
