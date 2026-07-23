extends Node3D

@export var mouse_sensitivity: float = 0.003
@export var minimum_pitch: float = deg_to_rad(-50.0)
@export var maximum_pitch: float = deg_to_rad(35.0)

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x * mouse_sensitivity
		rotation.x -= event.relative.y * mouse_sensitivity
		rotation.x = clamp(
			rotation.x,
			minimum_pitch,
			maximum_pitch
		)

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE