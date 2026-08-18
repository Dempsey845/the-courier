class_name FrogBossVisual
extends Node3D

signal attack_finished

@export_category("Spin")
@export var spin_duration: float = 6.0
@export_range(0.0, 1.0) var initial_spin_speed: float = 0.15
@export_range(0.05, 0.9) var spin_ramp_fraction: float = 0.3

@export_category("Charge")
@export var puff_scale_multiplier: float = 1.2

@export var puff_up_duration: float = 1.2
@export var puff_down_duration: float = 0.5

@export_category("Galaxy Charge")
@export var frog_mesh: MeshInstance3D

@export_category("Tongue")
@export var tongue_mesh: MeshInstance3D
@export var tongue_extend_duration: float = 3.0
@export var tongue_retract_duration: float = 0.5
@onready var tongue_hitbox: Hitbox = $TongueHitbox

var tongue_material: ShaderMaterial
var dissolve_material: ShaderMaterial

@onready var animation_tree: AnimationTree = $AnimationTree

var original_scale: Vector3
var attacking: bool = false
var dead: bool = false
var spin_tween: Tween
var affected_galaxy_materials: Array[ShaderMaterial]

func _ready() -> void:
	original_scale = scale

	tongue_material = (
		tongue_mesh.get_active_material(0)
		as ShaderMaterial
	)

	if is_instance_valid(tongue_material):
		tongue_material.set_shader_parameter(
			"extension",
			0.0
		)
		
	tongue_hitbox.hit_hurtbox.connect(_on_tongue_hitbox_hit_hurtbox)

	dissolve_material = frog_mesh.material_overlay

	affected_galaxy_materials.append(frog_mesh.get_surface_override_material(1))
	affected_galaxy_materials.append(frog_mesh.get_surface_override_material(6))

func rotate_towards_position(
	target_position: Vector3,
	speed: float,
	delta: float
) -> void:
	var target_local_y: float = _get_local_angle_to(
		target_position
	)

	rotation.y = lerp_angle(
		rotation.y,
		target_local_y,
		speed * delta
	)

func start_attack(
	spin_left: bool,
	target: Node3D
) -> void:
	if dead or attacking:
		return

	if not is_instance_valid(target):
		return

	attacking = true

	await _puff_up()
	_puff_down()
	tongue_hitbox.active = true
	tongue_hitbox.force_hit_update()

	await _extend_tongue()

	await _spin_towards_target(
		spin_left,
		target
	)

	tongue_hitbox.active = false

	await _retract_tongue()

	attacking = false
	attack_finished.emit()


func start_straight_tongue_attack(
	target_position: Vector3
) -> void:
	if dead or attacking:
		return

	attacking = true

	_face_target(target_position)

	await _puff_up()
	_puff_down()

	tongue_hitbox.active = true
	tongue_hitbox.force_hit_update()

	await _extend_tongue()

	await _retract_tongue()

	tongue_hitbox.active = false

	attacking = false
	attack_finished.emit()

func die() -> void:
	if dead:
		return

	dead = true
	attacking = false

	if is_instance_valid(spin_tween):
		spin_tween.kill()
		spin_tween = null

	tongue_hitbox.active = false

	if is_instance_valid(tongue_material):
		tongue_material.set_shader_parameter(
			"extension",
			0.0
		)

	animation_tree.set("parameters/DeathOneShot/request", 
		AnimationNodeOneShot.OneShotRequest.ONE_SHOT_REQUEST_FIRE)

	_start_dissolve()

func _puff_up() -> void:
	var target_scale: Vector3 = Vector3(
		original_scale.x * puff_scale_multiplier,
		original_scale.y,
		original_scale.z * puff_scale_multiplier
	)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		self,
		"scale",
		target_scale,
		puff_up_duration
	)

	await tween.finished


func _puff_down() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		self,
		"scale",
		original_scale,
		puff_down_duration
	)

	await tween.finished


func _spin_towards_target(
	spin_left: bool,
	target: Node3D
) -> void:
	if dead or not is_instance_valid(target):
		return

	var starting_rotation: float = rotation.y
	var spin_direction: float = 1.0 if spin_left else -1.0

	spin_tween = create_tween()
	spin_tween.set_trans(Tween.TRANS_LINEAR)

	spin_tween.tween_method(
		func(linear_progress: float) -> void:
			if dead or not is_instance_valid(target):
				return

			var spin_progress := _get_accelerated_spin_progress(
				linear_progress
			)

			var target_local_y: float = _get_local_angle_to(
				target.global_position
			)

			var target_correction: float = wrapf(
				target_local_y - starting_rotation,
				-PI,
				PI
			)

			rotation.y = (
				starting_rotation
				+ spin_direction * TAU * spin_progress
				+ target_correction * spin_progress
			),
		0.0,
		1.0,
		spin_duration
	)

	await spin_tween.finished

	if dead:
		return

	spin_tween = null

	if is_instance_valid(target):
		rotation.y = _get_local_angle_to(
			target.global_position
		)

	rotation.y = wrapf(rotation.y, -PI, PI)

func _get_accelerated_spin_progress(
	linear_progress: float
) -> float:
	var ramp: float = clampf(
		spin_ramp_fraction,
		0.001,
		0.999
	)

	var starting_speed: float = clampf(
		initial_spin_speed,
		0.0,
		1.0
	)

	var distance: float

	if linear_progress < ramp:
		var ramp_progress: float = linear_progress / ramp

		distance = (
			starting_speed * linear_progress
			+ (1.0 - starting_speed)
			* ramp
			* ramp_progress
			* ramp_progress
			* 0.5
		)
	else:
		var ramp_distance: float = (
			ramp * (starting_speed + 1.0) * 0.5
		)

		distance = (
			ramp_distance
			+ linear_progress
			- ramp
		)

	var total_distance: float = (
		1.0
		- ramp * (1.0 - starting_speed) * 0.5
	)

	return distance / total_distance

func _get_local_angle_to(
	target_position: Vector3
) -> float:
	var direction: Vector3 = target_position - global_position
	direction.y = 0.0

	if direction.length_squared() <= 0.001:
		return rotation.y

	var target_global_y: float = atan2(
		direction.x,
		direction.z
	)

	var parent_global_y: float = 0.0
	var parent_3d: Node3D = get_parent_node_3d()

	if is_instance_valid(parent_3d):
		parent_global_y = parent_3d.global_rotation.y

	return wrapf(
		target_global_y - parent_global_y,
		-PI,
		PI
	)

func _extend_tongue() -> void:
	if not is_instance_valid(tongue_material):
		return

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		tongue_material,
		"shader_parameter/extension",
		1.0,
		tongue_extend_duration
	)

	await tween.finished

func _retract_tongue() -> void:
	if not is_instance_valid(tongue_material):
		return

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(
		tongue_material,
		"shader_parameter/extension",
		0.0,
		tongue_retract_duration
	)

	await tween.finished

func _face_target(target_position: Vector3) -> void:
	var direction: Vector3 = target_position - global_position
	direction.y = 0.0

	if direction.length_squared() <= 0.001:
		return

	var target_global_angle: float = atan2(
		direction.x,
		direction.z
	)

	var parent_global_y: float = 0.0

	if is_instance_valid(get_parent_node_3d()):
		parent_global_y = get_parent_node_3d().global_rotation.y

	rotation.y = target_global_angle - parent_global_y

func _on_tongue_hitbox_hit_hurtbox(hurtbox: Hurtbox):
	if hurtbox.get_parent() is not Player:
		return

	var player: Player = hurtbox.get_parent()

	player.apply_upward_force(16.0)
	player.apply_directional_force(global_basis.z, 8.0)

func hit():
	const DISSOLVE_DURATION: float = 1.0

	dissolve_material.set_shader_parameter(
		"progress",
		0.0
	)

	var tween := create_tween()

	tween.tween_property(
		dissolve_material,
		"shader_parameter/progress",
		1.0,
		DISSOLVE_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT
	)

func _start_dissolve() -> void:
	await get_tree().create_timer(0.3).timeout

	const DISSOLVE_DURATION: float = 2.0

	dissolve_material.set_shader_parameter(
		"progress",
		0.0
	)

	var tween := create_tween()

	tween.tween_property(
		dissolve_material,
		"shader_parameter/progress",
		1.0,
		DISSOLVE_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_IN_OUT
	)

	await tween.finished

	await get_tree().create_timer(3.0).timeout
	frog_mesh.hide()

	

func _charge_galaxy_effect() -> void:
	if affected_galaxy_materials.is_empty():
		return

	animation_tree.set("parameters/OpenMouthOneShot/request", 
		AnimationNodeOneShot.OneShotRequest.ONE_SHOT_REQUEST_FIRE)

	var tween := create_tween()

	# Animate from 0 to 1.
	tween.set_parallel(true)

	for material: ShaderMaterial in affected_galaxy_materials:
		if not is_instance_valid(material):
			continue

		material.set_shader_parameter("progress", 0.0)

		tween.tween_property(
			material,
			"shader_parameter/progress",
			1.0,
			1.0
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	await tween.finished

	# Hold at full strength.
	await get_tree().create_timer(0.3).timeout

	# Animate from 1 to 0.
	tween = create_tween()
	tween.set_parallel(true)

	for material: ShaderMaterial in affected_galaxy_materials:
		if not is_instance_valid(material):
			continue

		tween.tween_property(
			material,
			"shader_parameter/progress",
			0.0,
			1.0
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await tween.finished

	attack_finished.emit()
