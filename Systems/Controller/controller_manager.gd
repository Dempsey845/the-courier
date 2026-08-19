extends Node

enum ControllerType {
	UNKNOWN,
	XBOX,
	PLAYSTATION,
}

enum InputKey
{
    CTRL,
    E,
	TAB,
    PS_CIRCLE,
    PS_SQUARE,
    PS_CROSS,
	PS_R3,
    XBOX_A,
    XBOX_B,
    XBOX_X,
	XBOX_RS
}

enum InputAction {
    Interact,
	CameraSwitch
}

var input_action_keys: Dictionary[InputAction, Dictionary] = {
    InputAction.Interact: {
        ControllerType.XBOX: InputKey.XBOX_X,
		ControllerType.PLAYSTATION: InputKey.PS_SQUARE,
		ControllerType.UNKNOWN: InputKey.E
    },
	InputAction.CameraSwitch: {
		ControllerType.XBOX: InputKey.XBOX_RS,
		ControllerType.PLAYSTATION: InputKey.PS_R3,
		ControllerType.UNKNOWN: InputKey.TAB
	}
}

var input_icons: Dictionary[InputAction, Dictionary] = {
    InputAction.Interact: {
        ControllerType.XBOX: preload("uid://bdqbvlloeu6b0"), # xbox_x.png
		ControllerType.PLAYSTATION: preload("uid://dvrs2lty4tn63"), # ps_square.png
		ControllerType.UNKNOWN: preload("uid://esthnx0fvqrm") # key_e.png
    },
	InputAction.CameraSwitch: {
		ControllerType.XBOX: preload("uid://bfbg1cgy11uvl"), # xbox_rs.png
		ControllerType.PLAYSTATION: preload("uid://b6prk568fit8w"), # ps_r3.png
		ControllerType.UNKNOWN: preload("uid://cukskmmjmmkp5") # key_tab.png
	}
}

var action_icons: Dictionary[InputAction, Texture] = {
	InputAction.CameraSwitch: preload("res://icon.svg")
}

var input_actions: Dictionary[ControllerManager.InputAction, String] = {
	ControllerManager.InputAction.Interact: "interact",
	ControllerManager.InputAction.CameraSwitch: "camera_switch"
}

signal input_device_changed(using_controller: bool, controller_type: ControllerType)

var using_controller: bool = false

func refresh() -> ControllerType:
	var connected_joypads: Array[int] = Input.get_connected_joypads()
	var start_controller_type: ControllerType = (
		ControllerType.UNKNOWN
	)

	if not connected_joypads.is_empty():
		start_controller_type = get_controller_type(
			connected_joypads[0]
		)

		_set_using_controller(true, connected_joypads[0])

	return start_controller_type

func get_controller_type(device_id: int) -> ControllerType:
	var controller_name: String = Input.get_joy_name(device_id).to_lower()

	if (
		"xbox" in controller_name
		or "xinput" in controller_name
	):
		return ControllerType.XBOX

	if (
		"playstation" in controller_name
		or "dualshock" in controller_name
		or "dualsense" in controller_name
		or "ps4" in controller_name
		or "ps5" in controller_name
	):
		return ControllerType.PLAYSTATION

	return ControllerType.UNKNOWN

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		_set_using_controller(true, event.device)

	elif event is InputEventJoypadMotion:
		# Ignore tiny stick drift.
		if absf(event.axis_value) > 0.2:
			_set_using_controller(true, event.device)

	elif event is InputEventKey or event is InputEventMouseButton:
		_set_using_controller(false, event.device)

	elif event is InputEventMouseMotion:
		# Ignore tiny accidental mouse movements.
		if event.relative.length() > 2.0:
			_set_using_controller(false, event.device)


func _set_using_controller(value: bool, device_id: int) -> void:
	if using_controller == value:
		return

	using_controller = value
	input_device_changed.emit(using_controller, get_controller_type(device_id))

	print(get_controller_type(device_id))