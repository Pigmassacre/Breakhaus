extends Node
## Sets up the input actions in code, so they live in one readable place,
## and keeps track of what the player last played with (keys, mouse, pad or
## touch), so the prompts can name the right button.

enum Device { KEYBOARD, MOUSE, PAD, TOUCH }

signal device_changed(device: Device)

const KEYS := {
	"move_left": [KEY_LEFT, KEY_A],
	"move_right": [KEY_RIGHT, KEY_D],
	"smash": [KEY_SPACE, KEY_UP, KEY_W, KEY_Z],
	"quake": [KEY_SHIFT, KEY_E, KEY_X],
	"pause": [KEY_ESCAPE, KEY_P],
}

const BUTTONS := {
	"move_left": [JOY_BUTTON_DPAD_LEFT],
	"move_right": [JOY_BUTTON_DPAD_RIGHT],
	"smash": [JOY_BUTTON_A, JOY_BUTTON_RIGHT_SHOULDER],
	"quake": [JOY_BUTTON_Y, JOY_BUTTON_X, JOY_BUTTON_LEFT_SHOULDER],
	"pause": [JOY_BUTTON_START, JOY_BUTTON_BACK],
}

## Action: [axis, direction]
const AXES := {
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
	"smash": [JOY_AXIS_TRIGGER_RIGHT, 1.0],
	"quake": [JOY_AXIS_TRIGGER_LEFT, 1.0],
}

var device := Device.KEYBOARD
## The pad's prompts: Xbox's letters, or PlayStation's shapes.
var playstation := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for action: String in KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
		for key: Key in KEYS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
		for button: JoyButton in BUTTONS.get(action, []):
			var press := InputEventJoypadButton.new()
			press.button_index = button
			InputMap.action_add_event(action, press)
		if AXES.has(action):
			var motion := InputEventJoypadMotion.new()
			motion.axis = AXES[action][0]
			motion.axis_value = AXES[action][1]
			InputMap.action_add_event(action, motion)
	InputMap.action_set_deadzone("move_left", 0.18)
	InputMap.action_set_deadzone("move_right", 0.18)
	InputMap.action_set_deadzone("smash", 0.5)
	InputMap.action_set_deadzone("quake", 0.5)
	# The menus answer to a pad too: confirm, back, and moving about.
	_pad_ui("ui_accept", [JOY_BUTTON_A])
	_pad_ui("ui_cancel", [JOY_BUTTON_B])
	_pad_ui("ui_up", [JOY_BUTTON_DPAD_UP], JOY_AXIS_LEFT_Y, -1.0)
	_pad_ui("ui_down", [JOY_BUTTON_DPAD_DOWN], JOY_AXIS_LEFT_Y, 1.0)
	_pad_ui("ui_left", [JOY_BUTTON_DPAD_LEFT], JOY_AXIS_LEFT_X, -1.0)
	_pad_ui("ui_right", [JOY_BUTTON_DPAD_RIGHT], JOY_AXIS_LEFT_X, 1.0)
	if DisplayServer.is_touchscreen_available() and OS.has_feature("mobile"):
		device = Device.TOUCH


## Adds pad buttons (and a stick direction) to a UI action that lacks them.
func _pad_ui(action: String, buttons: Array, axis := -1, direction := 0.0) -> void:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			return
	for button: JoyButton in buttons:
		var press := InputEventJoypadButton.new()
		press.button_index = button
		InputMap.action_add_event(action, press)
	if axis >= 0:
		var motion := InputEventJoypadMotion.new()
		motion.axis = axis
		motion.axis_value = direction
		InputMap.action_add_event(action, motion)


func _input(event: InputEvent) -> void:
	var now := device
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		now = Device.TOUCH
	elif event is InputEventMouseButton or (event is InputEventMouseMotion and event.relative.length() > 2.0):
		# A finger on the glass makes mouse events too; those don't count.
		if event.device != InputEvent.DEVICE_ID_EMULATION:
			now = Device.MOUSE
	elif event is InputEventKey:
		now = Device.KEYBOARD
	elif event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5):
		now = Device.PAD
		var pad_name := Input.get_joy_name(event.device).to_lower()
		playstation = pad_name.contains("ps") or pad_name.contains("dualsense") or pad_name.contains("dualshock") \
			or pad_name.contains("playstation") or pad_name.contains("sony")
	if now != device:
		device = now
		device_changed.emit(device)


## What to press for `action`, on what the player is playing with now.
func prompt(action: String) -> String:
	match device:
		Device.TOUCH:
			return {"smash": "Tap", "quake": "Quake", "pause": "Pause", "move": "Drag"}.get(action, "Tap")
		Device.PAD:
			if playstation:
				return {"smash": "Cross", "quake": "Triangle", "pause": "Options", "move": "Stick"}.get(action, "Cross")
			return {"smash": "A", "quake": "Y", "pause": "Start", "move": "Stick"}.get(action, "A")
		Device.MOUSE:
			return {"smash": "Click", "quake": "Right click", "pause": "Esc", "move": "Mouse"}.get(action, "Click")
	return {"smash": "Space", "quake": "Shift", "pause": "Esc", "move": "Arrows"}.get(action, "Space")
