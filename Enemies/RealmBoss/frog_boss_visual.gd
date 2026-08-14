class_name FrogBossVisual
extends Node3D

@export_category("Spin")
@export var spin_duration: float = 3.0

@export_category("Charge")
@export var puff_scale_multiplier: float = 1.25
@export var puff_up_duration: float = 1.5
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


func start_attack(
	spin_left: bool,
	target_position: Vector3
) -> void:
	if attacking:
		return

	attacking = true

	await _puff_up()
	_puff_down()
	await _extend_tongue()

	await _spin_towards_position(
		spin_left,
		target_position
	)

	await _retract_tongue()

	attacking = false


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


func _spin_towards_position(
	spin_left: bool,
	target_position: Vector3
) -> void:
	var direction: Vector3 = (
		target_position - global_position
	)
	direction.y = 0.0

	if direction.length_squared() <= 0.001:
		return

	direction = direction.normalized()

	var forward: Vector3 = global_basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var angle_to_target: float = forward.signed_angle_to(
		direction,
		Vector3.UP
	)

	var spin_angle: float

	if spin_left:
		spin_angle = (
			TAU + fposmod(angle_to_target, TAU)
		)
	else:
		spin_angle = (
			-TAU - fposmod(-angle_to_target, TAU)
		)

	var target_rotation: float = rotation.y + spin_angle

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)

	tween.tween_property(
		self,
		"rotation:y",
		target_rotation,
		spin_duration
	)

	await tween.finished

	rotation.y = wrapf(rotation.y, -PI, PI)

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
