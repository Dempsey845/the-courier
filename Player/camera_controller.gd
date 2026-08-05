extends Node3D

@export_category("Mouse Look")
@export var mouse_sensitivity: float = 0.003

@export_category("Controller Look")
@export var controller_sensitivity: float = 2.5
@export_range(0.0, 1.0, 0.01) var controller_deadzone: float = 0.15

@export_category("Camera Limits")
@export var minimum_pitch: float = deg_to_rad(-50.0)
@export var maximum_pitch: float = deg_to_rad(35.0)


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	_handle_controller_look(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_camera(
			event.relative.x * mouse_sensitivity,
			event.relative.y * mouse_sensitivity
		)

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _handle_controller_look(delta: float) -> void:
	var look_input := Input.get_vector(
		"camera_look_left",
		"camera_look_right",
		"camera_look_up",
		"camera_look_down",
		controller_deadzone
	)

	if look_input == Vector2.ZERO:
		return

	rotate_camera(
		look_input.x * controller_sensitivity * delta,
		look_input.y * controller_sensitivity * delta
	)


func rotate_camera(yaw_amount: float, pitch_amount: float) -> void:
	rotation.y -= yaw_amount
	rotation.x -= pitch_amount
	rotation.x = clamp(rotation.x, minimum_pitch, maximum_pitch)
