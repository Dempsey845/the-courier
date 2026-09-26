class_name Player
extends CharacterBody3D

signal jump
signal jump_cut
signal hit_jump
signal landed
signal hold_started
signal throw_attempt

@export_category("Movement")
@export var move_speed: float = 7.0
@export var slow_move_speed: float = 2.5
@export var acceleration: float = 30.0
@export var deceleration: float = 25.0
@export var air_acceleration: float = 10.0
@export var rotation_speed: float = 12.0

var slow_movement_enabled: bool = false

var boss_arena_center: Vector3 = Vector3.ZERO
var boss_orbit_radius: float = 0.0
var boss_arena_active: bool = false
var _camera_before_boss: Camera3D


@export_category("Camera")
@export var current_camera: Camera3D

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

var can_move: bool = true
var jump_enabled: bool = true

var launched_by_force: bool = false

@export_category("Fan")
@export var max_fan_speed: float = 12.0

var in_fan: bool = false
var fan_strength: float = 0.0
var fan_direction: Vector3 = Vector3.UP

@onready var landing_ray: RayCast3D = $LandingShadowRay

var is_holding: bool = false

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

func _process(_delta: float) -> void:
	if is_holding and Input.is_action_just_pressed("attack"):
		attempt_throw()

func _physics_process(delta: float) -> void:
	var was_on_floor: bool = is_on_floor()

	if not player_in_dialogue:
		update_jump_timers(delta)
		handle_jump()
	else:
		jump_buffer_timer = 0.0

	apply_gravity(delta)
	apply_fan_force(delta)

	if launched_by_force and velocity.y <= 0.0:
		launched_by_force = false

	knockback_timer = maxf(knockback_timer - delta, 0.0)

	if player_in_dialogue:
		look_at_dialogue_npc(delta)
	elif knockback_timer <= 0.0:
		if can_move:
			handle_movement(delta)
		else:
			decelerate_to_still(delta)

	move_and_slide()
	if boss_arena_active:
		_constrain_to_boss_orbit()

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

	if launched_by_force:
		jump_buffer_timer = 0.0
	elif Input.is_action_just_pressed("jump"):
		# Remember a jump pressed shortly before landing.
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = maxf(
			jump_buffer_timer - delta,
			0.0
		)


func handle_jump() -> void:
	var has_buffered_jump: bool = jump_buffer_timer > 0.0
	var can_jump: bool = coyote_timer > 0.0 and jump_enabled

	if has_buffered_jump and can_jump:
		velocity.y = jump_velocity
		# Consume both timers so the same input cannot jump twice.
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

		jump.emit()

func decelerate_to_still(delta: float) -> void:
	var horizontal_velocity: Vector3 = Vector3(
		velocity.x,
		0.0,
		velocity.z
	)

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

func handle_movement(delta: float) -> void:
	var input: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_back"
	)

	if boss_arena_active:
		_handle_boss_orbit_movement(input.x, delta)
		return

	# Flatten the camera directions so movement remains horizontal.
	var camera_forward: Vector3 = -current_camera.global_basis.z
	var camera_right: Vector3 = current_camera.global_basis.x

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

	var current_move_speed: float = (
		slow_move_speed if slow_movement_enabled
		else move_speed
	)

	if direction != Vector3.ZERO:
		var current_acceleration: float = (
			acceleration if is_on_floor()
			else air_acceleration
		)

		horizontal_velocity = horizontal_velocity.move_toward(
			direction * current_move_speed,
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

func enter_boss_arena(center: Vector3, orbit_radius: float, boss_camera: Camera3D) -> void:
	if boss_arena_active:
		return
	boss_arena_center = center
	boss_orbit_radius = orbit_radius
	boss_arena_active = true
	_camera_before_boss = current_camera if is_instance_valid(current_camera) else camera
	current_camera = boss_camera
	boss_camera.make_current()
	_constrain_to_boss_orbit()
	velocity.x = 0.0
	velocity.z = 0.0


func exit_boss_arena() -> void:
	if not boss_arena_active:
		return

	boss_arena_active = false
	boss_orbit_radius = 0.0
	velocity.x = 0.0
	velocity.z = 0.0

	var normal_camera := _camera_before_boss
	if not is_instance_valid(normal_camera):
		normal_camera = camera

	var outgoing_camera := get_viewport().get_camera_3d()
	current_camera = normal_camera
	_camera_before_boss = null

	var transition_camera := Camera3D.new()
	transition_camera.top_level = true
	get_tree().current_scene.add_child(transition_camera)

	transition_camera.global_transform = outgoing_camera.global_transform
	transition_camera.fov = outgoing_camera.fov
	transition_camera.make_current()

	var start_transform := transition_camera.global_transform
	var start_fov := transition_camera.fov

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(
		func(weight: float) -> void:
			transition_camera.global_transform = start_transform.interpolate_with(
				normal_camera.global_transform, weight
			)
			transition_camera.fov = lerpf(start_fov, normal_camera.fov, weight),
		0.0, 1.0, 0.7
	)
	tween.finished.connect(
		func() -> void:
			normal_camera.make_current()
			transition_camera.queue_free()
	)


func _handle_boss_orbit_movement(axis: float, delta: float) -> void:
	var radial := global_position - boss_arena_center
	radial.y = 0.0
	if radial.length_squared() < 0.001:
		radial = Vector3.FORWARD
	radial = radial.normalized()
	var tangent := Vector3(radial.z, 0.0, -radial.x)
	var desired := tangent * axis * (slow_move_speed if slow_movement_enabled else move_speed)
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var rate := (acceleration if absf(axis) > 0.01 else deceleration) if is_on_floor() else air_acceleration
	horizontal = horizontal.move_toward(desired, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if horizontal.length_squared() > 0.01:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(horizontal.x, horizontal.z), rotation_speed * delta)


func _constrain_to_boss_orbit() -> void:
	var offset := global_position - boss_arena_center
	offset.y = 0.0
	if offset.length_squared() < 0.001:
		offset = Vector3.FORWARD
	var position_on_orbit := boss_arena_center + offset.normalized() * boss_orbit_radius
	position_on_orbit.y = global_position.y
	global_position = position_on_orbit
	# Remove radial speed so collisions and knockback cannot push outside the orbit.
	var radial := offset.normalized()
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	horizontal -= radial * horizontal.dot(radial)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


func apply_fan_force(delta: float) -> void:
	if not in_fan:
		return

	var direction: Vector3 = fan_direction.normalized()
	var force_velocity: Vector3 = velocity.project(direction)

	var current_speed: float = force_velocity.dot(direction)
	var new_speed: float = minf(
		current_speed + fan_strength * delta,
		max_fan_speed
	)

	velocity += direction * (new_speed - current_speed)

func apply_gravity(delta: float) -> void:
	if is_on_floor() and not in_fan:
		return

	var gravity_multiplier: float = 1.0

	if launched_by_force:
		gravity_multiplier = 1.0
	elif in_fan and fan_direction.dot(Vector3.UP) > 0.1:
		gravity_multiplier = 1.0
	elif velocity.y < 0.0:
		gravity_multiplier = fall_gravity_multiplier
	elif Input.is_action_just_released("jump"):
		gravity_multiplier = jump_cut_gravity_multiplier
		jump_cut.emit()
	elif not Input.is_action_pressed("jump"):
		gravity_multiplier = jump_cut_gravity_multiplier

	velocity.y -= gravity * gravity_multiplier * delta

func apply_upward_force(force: float) -> void:
	velocity.y = force
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	launched_by_force = true

	hit_jump.emit()

func apply_forward_force(force: float) -> void:
	var forward: Vector3 = model.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()

	velocity.x = forward.x * force
	velocity.z = forward.z * force

	knockback_timer = knockback_control_lock_time

func apply_camera_forward_force(force: float) -> void:
	var camera_forward: Vector3 = -camera.global_basis.z
	camera_forward.y = 0.0
	camera_forward = camera_forward.normalized()

	velocity.x = camera_forward.x * force
	velocity.z = camera_forward.z * force

	knockback_timer = knockback_control_lock_time

func apply_directional_force(forward_direction: Vector3, force: float) -> void:
	forward_direction.y = 0.0

	if forward_direction.is_zero_approx():
		return

	forward_direction = forward_direction.normalized()

	velocity.x = forward_direction.x * force
	velocity.z = forward_direction.z * force

	knockback_timer = knockback_control_lock_time

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

func set_slow_movement(enabled: bool) -> void:
	slow_movement_enabled = enabled

func stop_moving() -> void:
	can_move = false
	jump_enabled = false
	jump_buffer_timer = 0.0

func enter_fan(
	direction: Vector3,
	strength: float,
	max_speed: float = 20.0
) -> void:
	in_fan = true
	fan_direction = direction.normalized()
	fan_strength = strength
	max_fan_speed = max_speed


func exit_fan() -> void:
	in_fan = false
	fan_strength = 0.0
	fan_direction = Vector3.UP
	
func update_fan_direction(direction: Vector3) -> void:
	if in_fan:
		fan_direction = direction.normalized()

func get_ground_position() -> Vector3:
	landing_ray.force_raycast_update()

	if landing_ray.is_colliding():
		return landing_ray.get_collision_point()
	
	return global_position

func start_holding():
	hold_started.emit()
	is_holding = true

func attempt_throw():
	throw_attempt.emit()

func trigger_successful_throw():
	is_holding = false