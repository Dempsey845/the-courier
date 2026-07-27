class_name Buoyancy
extends StaticBody3D

@export var water: MeshInstance3D
@export var height_offset: float = 0.1
@export var follow_speed: float = 11.0

@export var wave_strength: float = 0.225
@export var wave_scale: float = 0.5
@export var wave_speed: float = 1.2

func _process(delta: float) -> void:
	if not is_instance_valid(water):
		return

	var local_position: Vector3 = water.to_local(global_position)
	var target_height: float = get_wave_height(
		Vector2(local_position.x, local_position.z)
	)

	# Convert the displaced local surface position back into world space.
	var target_world_position: Vector3 = water.to_global(
		Vector3(
			local_position.x,
			target_height + height_offset,
			local_position.z
		)
	)

	global_position.y = lerpf(
		global_position.y,
		target_world_position.y,
		1.0 - exp(-follow_speed * delta)
	)


func get_wave_height(pos: Vector2) -> float:
	var shader_time : float = Time.get_ticks_msec() / 1000.0
	var scaled_position : Vector2 = pos * wave_scale

	var first_wave: float = sin(
		scaled_position.x * 1.15
		+ scaled_position.y * 0.45
		+ shader_time * wave_speed
	)

	var second_wave: float = sin(
		scaled_position.x * -0.55
		+ scaled_position.y * 1.35
		- shader_time * wave_speed * 0.7
	)

	var third_wave: float = sin(
		scaled_position.x * 1.8
		+ scaled_position.y * -1.1
		+ shader_time * wave_speed * 0.45
	)

	return (
		first_wave * 0.5
		+ second_wave * 0.3
		+ third_wave * 0.2
	) * wave_strength