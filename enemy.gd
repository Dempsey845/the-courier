class_name Enemy
extends CharacterBody3D

signal attacked(target: Node3D)
signal state_changed(new_state: State)
signal hit

enum State {
	IDLE,
	WANDER,
	CHASE,
	ATTACK,
	HIT,
	SCATTER,
	DEATH
}


@export_category("Zone")
@export var assigned_zone: ZoneManager.Zone

@export_category("Target")
@export var target: Node3D
@export var detection_distance: float = 10.0
@export var attack_distance: float = 2.0

@export_category("Movement")
@export var move_speed: float = 4.0
@export var acceleration: float = 12.0
@export var rotation_speed: float = 8.0

@export_category("Chase")
@export var can_chase: bool = true

@export_category("Wandering")
## Maximum distance from the enemy's starting position.
@export var wander_radius: float = 8.0
@export var can_wander: bool = true
@export var min_idle_time: float = 1.0
@export var max_idle_time: float = 3.0

@export_category("Attack")
@export var attack_cooldown: float = 1.5
@export var wait_after_attack: bool = false
@export var wait_time: float = 5.0
## Allows attacking while stationary when chasing is disabled.
@export var can_attack_idle: bool = false

@export_category("Hit")
@export var stun_time: float = 0.75
@export var scatter_on_hit: bool = true
@export var scatter_radius: float = 15.0

@export_category("Death")
@export var death_duration: float = 3.0
@export var remove_on_death: bool = true


@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health: Health = $Health


var current_state: State = State.IDLE

var spawn_position: Vector3
var wander_position: Vector3
var scatter_position: Vector3

var cooldown_remaining: float = 0.0
var idle_remaining: float = 0.0
var stun_remaining: float = 0.0
var wait_remaining: float = 0.0
var death_remaining: float = 0.0

var index: int


func _ready() -> void:
	navigation_agent.path_desired_distance = 1.2
	navigation_agent.target_desired_distance = 1.2

	spawn_position = global_position
	reset_idle_timer()

	hurtbox.hit.connect(_on_hurtbox_hit)
	health.death.connect(die)

	connect_target_health()


func _physics_process(delta: float) -> void:
	# Death is handled separately because it is a terminal state.
	if current_state == State.DEATH:
		update_death(delta)
		move_and_slide()
		return

	update_timers(delta)

	if not is_inside_assigned_zone():
		enter_idle()
	else:
		update_current_state(delta)

	move_and_slide()


func update_timers(delta: float) -> void:
	cooldown_remaining = maxf(cooldown_remaining - delta, 0.0)


func update_current_state(delta: float) -> void:
	match current_state:
		State.IDLE:
			update_idle(delta)

		State.WANDER:
			update_wander(delta)

		State.CHASE:
			update_chase(delta)

		State.ATTACK:
			update_attack(delta)

		State.HIT:
			update_hit(delta)

		State.SCATTER:
			update_scatter(delta)


# State changes

func change_state(new_state: State) -> void:
	if current_state == State.DEATH:
		return

	if current_state == new_state:
		return

	current_state = new_state
	state_changed.emit(current_state)


func enter_idle(reset_timer: bool = true) -> void:
	if current_state == State.DEATH:
		return

	if reset_timer:
		reset_idle_timer()

	change_state(State.IDLE)


func return_to_normal_state() -> void:
	if current_state == State.DEATH:
		return

	if wait_remaining > 0.0:
		enter_idle(false)
		return

	if not has_valid_target():
		enter_idle()
		return

	var distance: float = distance_to_target()

	if distance > detection_distance:
		enter_idle()
	elif distance <= attack_distance and (can_chase or can_attack_idle):
		change_state(State.ATTACK)
	elif can_chase:
		change_state(State.CHASE)
	else:
		enter_idle()


# Idle

func update_idle(delta: float) -> void:
	stop_moving(delta)

	if wait_remaining > 0.0:
		wait_remaining = maxf(wait_remaining - delta, 0.0)

		if wait_remaining <= 0.0:
			reset_idle_timer()

		return

	if can_detect_target():
		if can_chase:
			change_state(State.CHASE)
		elif can_attack_idle and distance_to_target() <= attack_distance:
			change_state(State.ATTACK)

		return

	idle_remaining = maxf(idle_remaining - delta, 0.0)

	if can_wander and idle_remaining <= 0.0:
		begin_wander()


func reset_idle_timer() -> void:
	idle_remaining = randf_range(min_idle_time, max_idle_time)


# Wandering

func begin_wander() -> void:
	if current_state == State.DEATH:
		return

	var navigation_map := navigation_agent.get_navigation_map()

	if not navigation_map.is_valid():
		enter_idle()
		return

	var desired_position: Vector3 = get_random_position(
		spawn_position,
		wander_radius
	)

	wander_position = NavigationServer3D.map_get_closest_point(
		navigation_map,
		desired_position
	)

	navigation_agent.target_position = wander_position
	change_state(State.WANDER)


func update_wander(delta: float) -> void:
	if can_detect_target() and can_chase:
		change_state(State.CHASE)
		return

	if navigation_agent.is_navigation_finished():
		enter_idle()
		return

	follow_navigation_path(delta)


# Chasing

func update_chase(delta: float) -> void:
	if not has_valid_target():
		enter_idle()
		return

	var distance: float = distance_to_target()

	if distance > detection_distance:
		enter_idle()
		return

	if distance <= attack_distance:
		change_state(State.ATTACK)
		return

	navigation_agent.target_position = target.global_position
	follow_navigation_path(delta)


# Attacking

func update_attack(delta: float) -> void:
	if not has_valid_target():
		enter_idle()
		return

	stop_moving(delta)
	face_target(delta)

	var distance: float = distance_to_target()

	if distance > attack_distance:
		if can_chase and distance <= detection_distance:
			change_state(State.CHASE)
		else:
			enter_idle()

		return

	if cooldown_remaining > 0.0:
		return

	cooldown_remaining = attack_cooldown
	attacked.emit(target)

	# A signal handler may have killed this enemy.
	if current_state == State.DEATH:
		return

	if wait_after_attack:
		wait_remaining = wait_time
		enter_idle(false)


# Hit and scatter

func _on_hurtbox_hit(_hitbox: Hitbox) -> void:
	take_hit()


func take_hit() -> void:
	if current_state == State.DEATH:
		return

	if health.dead or health.current_health <= 0:
		die()
		return

	stun_remaining = stun_time
	stop_immediately()
	change_state(State.HIT)
	hit.emit()


func update_hit(_delta: float) -> void:
	stop_immediately()

	stun_remaining = maxf(stun_remaining - _delta, 0.0)

	if stun_remaining > 0.0:
		return

	if scatter_on_hit:
		begin_scatter()
	else:
		return_to_normal_state()


func begin_scatter() -> void:
	if current_state == State.DEATH:
		return

	var navigation_map := navigation_agent.get_navigation_map()

	if not navigation_map.is_valid():
		return_to_normal_state()
		return

	var desired_position: Vector3 = get_random_position(
		global_position,
		scatter_radius
	)

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


# Death

func die() -> void:
	if current_state == State.DEATH:
		return

	death_remaining = death_duration

	cooldown_remaining = 0.0
	idle_remaining = 0.0
	stun_remaining = 0.0
	wait_remaining = 0.0

	stop_immediately()

	navigation_agent.target_position = global_position
	navigation_agent.set_velocity_forced(Vector3.ZERO)

	hurtbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)

	# Set this directly because change_state() blocks transitions from death,
	# and death must be entered unconditionally.
	current_state = State.DEATH
	state_changed.emit(current_state)


func update_death(delta: float) -> void:
	stop_moving(delta)

	if not remove_on_death:
		return

	death_remaining = maxf(death_remaining - delta, 0.0)

	if death_remaining <= 0.0:
		queue_free()


# Navigation and movement

func follow_navigation_path(delta: float) -> void:
	if current_state == State.DEATH:
		return

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

	var desired_velocity: Vector3 = direction * move_speed

	velocity.x = move_toward(
		velocity.x,
		desired_velocity.x,
		acceleration * delta
	)

	velocity.z = move_toward(
		velocity.z,
		desired_velocity.z,
		acceleration * delta
	)

	rotate_towards(direction, delta)


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


func stop_immediately() -> void:
	velocity.x = 0.0
	velocity.z = 0.0


func face_target(delta: float) -> void:
	if not has_valid_target():
		return

	var direction: Vector3 = global_position.direction_to(target.global_position)
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


# Target helpers

func connect_target_health() -> void:
	if not has_valid_target():
		return

	var target_health: Health = target.get_node_or_null("Health") as Health

	if target_health and not target_health.death.is_connected(_on_target_died):
		target_health.death.connect(_on_target_died)


func _on_target_died() -> void:
	target = null

	if current_state != State.DEATH:
		enter_idle()


func has_valid_target() -> bool:
	return is_instance_valid(target)


func can_detect_target() -> bool:
	return (
		has_valid_target()
		and distance_to_target() <= detection_distance
	)


func distance_to_target() -> float:
	if not has_valid_target():
		return INF

	var enemy_position: Vector2 = Vector2(
		global_position.x,
		global_position.z
	)

	var target_position: Vector2 = Vector2(
		target.global_position.x,
		target.global_position.z
	)

	return enemy_position.distance_to(target_position)


# General helpers

func is_inside_assigned_zone() -> bool:
	return (
		not ZoneManager.instance
		or ZoneManager.instance.current_zone == assigned_zone
	)


func get_random_position(
	origin: Vector3,
	radius: float
) -> Vector3:
	var angle: float = randf_range(0.0, TAU)
	var distance: float = sqrt(randf()) * radius

	return origin + Vector3(
		cos(angle) * distance,
		0.0,
		sin(angle) * distance
	)