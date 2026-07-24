class_name Enemy
extends CharacterBody3D

signal attacked(target: Node3D)
signal state_changed(new_state: State)
signal hit

enum State {
	IDLE,
	CHASE,
	ATTACK,
	HIT,
	SCATTER
}

@export_category("Target")
@export var target: Node3D
@export var detection_distance: float = 10.0
@export var attack_distance: float = 2.0

@export_category("Movement")
@export var move_speed: float = 4.0
@export var acceleration: float = 12.0
@export var rotation_speed: float = 8.0

@export_category("Attack")
@export var attack_cooldown: float = 1.5

@export_category("Hit")
@export var stun_time: float = 0.75
@export var scatter_on_hit: bool = true
@export var scatter_radius: float = 15.0

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var hurtbox: Hurtbox = $Hurtbox

var current_state: State = State.IDLE
var cooldown_remaining: float = 0.0
var stun_remaining: float = 0.0

var scatter_position: Vector3


func _ready() -> void:
	navigation_agent.path_desired_distance = 1.2
	navigation_agent.target_desired_distance = 1.2

	hurtbox.hit.connect(
		func(_hitbox: Hitbox):
			take_hit()
	)


func _physics_process(delta: float) -> void:
	cooldown_remaining = maxf(
		cooldown_remaining - delta,
		0.0
	)

	if not is_instance_valid(target):
		change_state(State.IDLE)
		stop_moving(delta)
		move_and_slide()
		return

	match current_state:
		State.IDLE:
			update_idle(delta)

		State.CHASE:
			update_chase(delta)

		State.ATTACK:
			update_attack(delta)

		State.HIT:
			update_hit(delta)

		State.SCATTER:
			update_scatter(delta)

	move_and_slide()


func update_idle(delta: float) -> void:
	stop_moving(delta)

	if distance_to_target() <= detection_distance:
		change_state(State.CHASE)


func update_chase(delta: float) -> void:
	var distance: float = distance_to_target()

	if distance > detection_distance:
		change_state(State.IDLE)
		return

	if distance <= attack_distance:
		change_state(State.ATTACK)
		return

	navigation_agent.target_position = target.global_position
	follow_navigation_path(delta)


func update_attack(delta: float) -> void:
	stop_moving(delta)
	face_target(delta)

	var distance: float = distance_to_target()

	if distance > attack_distance:
		change_state(State.CHASE)
		return

	if cooldown_remaining <= 0.0:
		attacked.emit(target)
		cooldown_remaining = attack_cooldown


func update_hit(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0

	stun_remaining = maxf(stun_remaining - delta, 0.0)

	if stun_remaining > 0.0:
		return

	if scatter_on_hit:
		begin_scatter()
	else:
		return_to_normal_state()


func begin_scatter() -> void:
	var navigation_map: RID = navigation_agent.get_navigation_map()

	var angle: float = randf_range(0.0, TAU)

	# Square root gives a more even distribution across the circle.
	var distance: float = sqrt(randf()) * scatter_radius

	var random_offset := Vector3(
		cos(angle) * distance,
		0.0,
		sin(angle) * distance
	)

	var desired_position: Vector3 = global_position + random_offset

	scatter_position = NavigationServer3D.map_get_closest_point(
		navigation_map,
		desired_position
	)

	navigation_agent.target_position = scatter_position
	change_state(State.SCATTER)


func update_scatter(delta: float) -> void:
	if navigation_agent.is_navigation_finished():
		stop_moving(delta)
		return_to_normal_state()
		return

	follow_navigation_path(delta)


func follow_navigation_path(delta: float) -> void:
	if navigation_agent.is_navigation_finished():
		stop_moving(delta)
		return

	var next_position: Vector3 = navigation_agent.get_next_path_position()
	var direction: Vector3 = global_position.direction_to(next_position)

	direction.y = 0.0

	if direction.length_squared() <= 0.001:
		stop_moving(delta)
		return

	direction = direction.normalized()

	var target_velocity: Vector3 = direction * move_speed

	velocity.x = move_toward(
		velocity.x,
		target_velocity.x,
		acceleration * delta
	)

	velocity.z = move_toward(
		velocity.z,
		target_velocity.z,
		acceleration * delta
	)

	rotate_towards(direction, delta)


func return_to_normal_state() -> void:
	if not is_instance_valid(target):
		change_state(State.IDLE)
		return

	var distance: float = distance_to_target()

	if distance > detection_distance:
		change_state(State.IDLE)
	elif distance <= attack_distance:
		change_state(State.ATTACK)
	else:
		change_state(State.CHASE)


func take_hit() -> void:
	stun_remaining = stun_time
	change_state(State.HIT)

	velocity.x = 0.0
	velocity.z = 0.0

	hit.emit()


func stop_moving(delta: float) -> void:
	velocity.x = move_toward(
		velocity.x,
		0.0,
		acceleration * delta
	)

	velocity.z = move_toward(
		velocity.z,
		0.0,
		acceleration * delta
	)


func face_target(delta: float) -> void:
	var direction: Vector3 = global_position.direction_to(
		target.global_position
	)

	direction.y = 0.0

	if direction.length_squared() > 0.001:
		rotate_towards(direction.normalized(), delta)


func rotate_towards(direction: Vector3, delta: float) -> void:
	var target_angle: float = atan2(
		direction.x,
		direction.z
	)

	rotation.y = lerp_angle(
		rotation.y,
		target_angle,
		rotation_speed * delta
	)


func distance_to_target() -> float:
	var enemy_position: Vector2 = Vector2(
		global_position.x,
		global_position.z
	)

	var target_position: Vector2 = Vector2(
		target.global_position.x,
		target.global_position.z
	)

	return enemy_position.distance_to(target_position)


func change_state(new_state: State) -> void:
	if current_state == new_state:
		return

	current_state = new_state
	state_changed.emit(current_state)