extends Area3D

@export var upward_force: float = 12.0
@export var forward_force: float = 0.0

@export_category("Movement")
@export var movement_enabled: bool = false
@export var end_point: Marker3D
@export_range(0.1, 20.0, 0.1) var movement_duration: float = 2.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var starting_position: Vector3
var destination_position: Vector3
var movement_time: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	starting_position = global_position

	if is_instance_valid(end_point):
		destination_position = end_point.global_position
	else:
		destination_position = starting_position

		if movement_enabled:
			push_warning("Movement is enabled, but no end point is assigned.")


func _physics_process(delta: float) -> void:
	if not movement_enabled or not is_instance_valid(end_point):
		return

	movement_time += delta

	# Goes from 0 → 1 → 0, slowing smoothly at both ends.
	var progress := (
		1.0 - cos(PI * movement_time / movement_duration)
	) * 0.5

	global_position = starting_position.lerp(
		destination_position,
		progress
	)


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		var player := body as Player
		player.apply_upward_force(upward_force)
		if forward_force > 0.0:
			player.apply_camera_forward_force(forward_force)
		animation_player.play("hit")
