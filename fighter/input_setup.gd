class_name InputSetup
extends RefCounted

# Physical key ашигласан тул keyboard-iin kheleer solikhod ajillana
const BINDINGS := {
	1: {
		"left": KEY_A, "right": KEY_D, "up": KEY_W, "down": KEY_S,
		"style": KEY_F, "skill1": KEY_R, "skill2": KEY_T, "skill3": KEY_Y,
		"mobility": KEY_G
	},
	2: {
		"left": KEY_LEFT, "right": KEY_RIGHT, "up": KEY_UP, "down": KEY_DOWN,
		"style": KEY_COMMA, "skill1": KEY_PERIOD, "skill2": KEY_SLASH, "skill3": KEY_SEMICOLON,
		"mobility": KEY_ENTER,
	},
}


static func action(player_id: int, key_name: String) -> StringName:
	return StringName("p%d_%s" % [player_id, key_name])


static func register() -> void:
	for player_id in BINDINGS:
		var keys: Dictionary = BINDINGS[player_id]
		for key_name in keys:
			var action_name := action(player_id, key_name)
			if InputMap.has_action(action_name):
				InputMap.erase_action(action_name)
			InputMap.add_action(action_name)
			var ev := InputEventKey.new()
			ev.physical_keycode = int(keys[key_name]) as Key
			InputMap.action_add_event(action_name, ev)
