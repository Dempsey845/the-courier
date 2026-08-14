class_name FrogBossVisual
extends Node3D

signal attack_finished

@export_category("Spin")
@export var spin_duration: float = 3.0

@export_category("Charge")
@export var puff_scale_multiplier: float = 1.25
@export var puff_up_duration: float = 0.8
@export var puff_down_duration: float = 0.5

@export_category("Tongue")
@export var tongue_mesh: MeshInstance3D
@export var tongue_extend_duration: float = 3.0
@export var tongue_retract_duration: float = 0.5

var tongue_material: ShaderMaterial

@onready var animation_player: AnimationPlayer = (
	%TongueOrigin/AnimationPlayer
)

var original_scale: Vector3
var attacking: bool = false


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
	if attacking:
		return

	if not is_instance_valid(target):
		return

	attacking = true

	await _puff_up()
	_puff_down()
	await _extend_tongue()

	await _spin_towards_target(
		spin_left,
		target
	)

	await _retract_tongue()

	attacking = false
	attack_finished.emit()


func start_straight_tongue_attack(
	target_position: Vector3
) -> void:
	if attacking:
		return

	attacking = true

	_face_target(target_position)

	await _puff_up()
	_puff_down()

	await _extend_tongue()
	await _retract_tongue()

	attacking = false
	attack_finished.emit()

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
	if not is_instance_valid(target):
		return

	var starting_rotation: float = rotation.y
	var spin_direction: float = 1.0 if spin_left else -1.0

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)

	tween.tween_method(
		func(progress: float) -> void:
			if not is_instance_valid(target):
				return

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
				+ spin_direction * TAU * progress
				+ target_correction * progress
			),
		0.0,
		1.0,
		spin_duration
	)

	await tween.finished

	if is_instance_valid(target):
		rotation.y = _get_local_angle_to(
			target.global_position
		)

	rotation.y = wrapf(rotation.y, -PI, PI)

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