extends Node3D

@export var visual: Node3D
@export var follow_speed: float = 4.0


func _process(delta: float) -> void:
	if not is_instance_valid(visual):
		return

	var weight: float = 1.0 - exp(-follow_speed * delta)

	global_rotation.y = lerp_angle(
		global_rotation.y,
		visual.global_rotation.y,
		weight
	)
