extends MeshInstance3D

@export var target: Node3D
@export var snap_size: float = 10.0


func _process(_delta: float) -> void:
	if not target:
		return

	global_position.x = snapped(
		target.global_position.x,
		snap_size
	)

	global_position.z = snapped(
		target.global_position.z,
		snap_size
	)