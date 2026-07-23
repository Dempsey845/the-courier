class_name Enemy
extends CharacterBody3D

signal attacked(target: Node3D)
signal state_changed(new_state: State)

enum State {
	IDLE,
	CHASE,
	ATTACK
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

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

var current_state: State = State.IDLE
var cooldown_remaining: float = 0.0


func _ready() -> void:
	navigation_agent.path_desired_distance = 1.5
	navigation_agent.target_desired_distance = attack_distance


func _physics_process(delta: float) -> void:
	cooldown_remaining = maxf(cooldown_remaining - delta, 0.0)

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

	if navigation_agent.is_navigation_finished():
		stop_moving(delta)
		return

	var next_position: Vector3 = navigation_agent.get_next_path_position()
	var direction: Vector3 = global_position.direction_to(next_position)
	direction.y = 0.0
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
	var target_angle: float = atan2(direction.x, direction.z)

	rotation.y = lerp_angle(
		rotation.y,
		target_angle,
		rotation_speed * delta
	)


func distance_to_target() -> float:
	return global_position.distance_to(
		target.global_position
	)


func change_state(new_state: State) -> void:
	if current_state == new_state:
		return

	current_state = new_state
	state_changed.emit(current_state)