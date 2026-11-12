extends RefCounted
## Registers keyboard bindings for the shared gameplay actions.
## Touch buttons trigger the same actions via Input.action_press().

static func ensure() -> void:
	var map := {
		"pump": [KEY_SPACE],
		"grab": [KEY_E, KEY_ENTER],
		"flip_back": [KEY_A, KEY_LEFT],
		"flip_front": [KEY_D, KEY_RIGHT],
		"tuck": [KEY_S, KEY_DOWN],
		"extend": [KEY_W, KEY_UP],
		"twist": [KEY_Q],
		"restart": [KEY_R],
		"pause": [KEY_ESCAPE, KEY_P],
	}
	for action in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for k in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
