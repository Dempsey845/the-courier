class_name Player
extends CharacterBody3D

signal jump
signal jump_cut
signal hit_jump
signal landed

@export_category("Movement")
@export var move_speed: float = 7.0
@export var acceleration: float = 30.0
@export var deceleration: float = 25.0
@export var air_acceleration: float = 10.0
@export var rotation_speed: float = 12.0

@export_category("Jumping")
@export var gravity: float = 18.0
@export var jump_velocity: float = 10.0
## Applied while rising after releasing the jump button.
@export var jump_cut_gravity_multiplier: float = 3.0
@export var fall_gravity_multiplier: float = 1.5
@export var coyote_time: float = 0.15
@export var jump_buffer_time: float = 0.15

@export_category("Knockback")
@export var knockback_control_lock_time: float = 0.2
var knockback_timer: float = 0.0

@onready var model: Node3D = $Model
@onready var camera: Camera3D = \
	$CameraController/SpringArm3D/Camera3D


var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

var player_in_dialogue: bool
var dialogue_npc: NPC

func _ready() -> void:
	await get_tree().process_frame

	DialogueManager.instance.dialogue_started.connect(func(npc: NPC):
		player_in_dialogue = true
		jump_buffer_timer = 0.0
		velocity.x = 0.0
		velocity.z = 0.0

		dialogue_npc = npc
	)

	DialogueManager.instance.dialogue_ended.connect(func():
		player_in_dialogue = false
		dialogue_npc = null
	)

func _physics_process(delta: float) -> void:
	var was_on_floor: bool = is_on_floor()

	if not player_in_dialogue:
		update_jump_timers(delta)
		handle_jump()
	else:
		jump_buffer_timer = 0.0

	apply_gravity(delta)

	knockback_timer = maxf(knockback_timer - delta, 0.0)

	if player_in_dialogue:
		look_at_dialogue_npc(delta)
	elif knockback_timer <= 0.0:
		handle_movement(delta)

	move_and_slide()

	if not was_on_floor and is_on_floor():
		landed.emit()


func look_at_dialogue_npc(delta: float) -> void:
	if not is_instance_valid(dialogue_npc):
		return

	var direction: Vector3 = dialogue_npc.global_position - global_position
	direction.y = 0.0

	if direction.length_squared() <= 0.001:
		return

	var target_angle: float = atan2(direction.x, direction.z)

	model.rotation.y = lerp_angle(
		model.rotation.y,
		target_angle,
		rotation_speed * delta
	)

func update_jump_timers(delta: float) -> void:
	# Refresh coyote time while standing on the ground.
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)

	# Remember a jump pressed shortly before landing.
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = maxf(
			jump_buffer_timer - delta,
			0.0
		)


func handle_jump() -> void:
	var has_buffered_jump: bool = jump_buffer_timer > 0.0
	var can_jump: bool = coyote_timer > 0.0

	if has_buffered_jump and can_jump:
		velocity.y = jump_velocity
		# Consume both timers so the same input cannot jump twice.
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

		jump.emit()


func handle_movement(delta: float) -> void:
	var input: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_back"
	)

	# Flatten the camera directions so movement remains horizontal.
	var camera_forward: Vector3 = -camera.global_basis.z
	var camera_right: Vector3 = camera.global_basis.x

	camera_forward.y = 0.0
	camera_right.y = 0.0

	camera_forward = camera_forward.normalized()
	camera_right = camera_right.normalized()

	var direction: Vector3 = (
		camera_right * input.x
		+ camera_forward * -input.y
	).normalized()

	var horizontal_velocity: Vector3 = Vector3(
		velocity.x,
		0.0,
		velocity.z
	)

	if direction != Vector3.ZERO:
		var current_acceleration: float = (
			acceleration if is_on_floor()
			else air_acceleration
		)

		horizontal_velocity = horizontal_velocity.move_toward(
			direction * move_speed,
			current_acceleration * delta
		)

		var target_angle: float = atan2(
			direction.x,
			direction.z
		)

		model.rotation.y = lerp_angle(
			model.rotation.y,
			target_angle,
			rotation_speed * delta
		)
	else:
		var current_deceleration: float = (
			deceleration if is_on_floor()
			else air_acceleration
		)

		horizontal_velocity = horizontal_velocity.move_toward(
			Vector3.ZERO,
			current_deceleration * delta
		)

	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z


func apply_gravity(delta: float) -> void:
	if is_on_floor():
		return

	var gravity_multiplier: float = 1.0

	if velocity.y < 0.0:
		# Make falling faster and less floaty.
		gravity_multiplier = fall_gravity_multiplier
	elif Input.is_action_just_released("jump"):
		gravity_multiplier = jump_cut_gravity_multiplier
		jump_cut.emit()
	elif not Input.is_action_pressed("jump"):
		# Cut the jump short when the button is released.
		gravity_multiplier = jump_cut_gravity_multiplier

	velocity.y -= gravity * gravity_multiplier * delta

func apply_upward_force(force: float):
	velocity.y = force
	hit_jump.emit()

func apply_knockback(
	source_position: Vector3,
	force: float,
	upward_force: float = 5.0 
	) -> void:
	var direction: Vector3 = global_position - source_position
	direction.y = 0.0

	if direction.length_squared() <= 0.001:
		direction = -model.global_basis.z
		direction.y = 0.0

	direction = direction.normalized()

	velocity.x = direction.x * force
	velocity.z = direction.z * force
	velocity.y = upward_force

	knockback_timer = knockback_control_lock_time