extends Marker3D

@export var player: Player
@export var rotation_speed: float = 5.0


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	var direction := player.global_position - global_position
	direction.y = 0.0

	if direction.length_squared() <= 0.0001:
		return

	var target_y_rotation := atan2(direction.x, direction.z)

	global_rotation.y = lerp_angle(
		global_rotation.y,
		target_y_rotation,
		rotation_speed * delta
	)