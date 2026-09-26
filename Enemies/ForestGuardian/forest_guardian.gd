class_name ForestGuardian
extends Node3D

signal health_changed(current_health: int, max_health: int)
signal phase_changed(phase: int)
signal defeated
signal attack_telegraphed(attack: Attack)

const AIR_SCENE: PackedScene = preload("uid://0a14w1khj3nq")
const FRUIT_SCENE: PackedScene = preload("uid://klg4jkj7o70b")
const LANDING_MARKER_SCENE: PackedScene = preload("uid://yin8v2gv5aer")

enum State { INACTIVE, IDLE, TELEGRAPH, ATTACK, RECOVERY, PHASE_TRANSITION, DEAD }
enum Attack { FRUIT_DROP, AIR_PUFF, ROOT_STRIKE }

@export var max_health := 100
@export var target: Node3D

@export_group("Circular Boss Arena")
@export var arena_radius := 10.0
@export var orbit_radius := 8.0
@export var camera_distance := 17.0
@export var camera_height := 5.0
@export var camera_look_height := 4.5
@export var camera_follow_speed := 6.0

@export_group("State Durations")
@export var idle_duration := 1.5
@export var telegraph_duration := 0.8
@export var attack_duration := 1.5
@export var recovery_duration := 1.0
@export var phase_transition_duration := 2.0

@export_category("Fruit Drop")
@export var fruit_count := 3
@export var fruit_height := 9.0
@export var fruit_spread := 2.0
@export var fruit_damage := 1

@export_category("Air Puff")
@export var air_damage := 1
@export var air_speed := 13.0

@export_category("Root Strike")
@export var root_damage := 1
@export var root_active_time := 1.0

var health: int
var phase := 1
var state := State.INACTIVE
var current_attack := Attack.FRUIT_DROP
var state_time := 0.0
var attack_index := 0
var attack_elapsed := 0.0
var shots_fired := 0
var projectiles: Array[ForestGuardianProjectile] = []
var warning_markers: Array[MeshInstance3D] = []
var fruit_positions: Array[Vector3] = []
var roots: Array[RootSpikeHitbox] = []
var arena_player: Player

@onready var arena_area: Area3D = $ArenaArea
@onready var arena_shape: CollisionShape3D = $ArenaArea/CollisionShape3D
@onready var boss_camera: Camera3D = $BossCamera


func _ready() -> void:
	health = max_health

	var trigger_shape := arena_shape.shape.duplicate() as SphereShape3D
	trigger_shape.radius = arena_radius - 1.0
	arena_shape.shape = trigger_shape
	arena_area.body_entered.connect(_on_arena_body_entered)

	for point_name in ["SpikePoint", "SpikePoint2", "SpikePoint3", "SpikePoint4"]:
		var root := get_node_or_null(NodePath(point_name + "/TreeSpike")) as RootSpikeHitbox
		if root == null:
			continue

		roots.append(root)
		root.visible = false
		root.monitoring = false
		root.active = false

	_check_initial_arena_overlap.call_deferred()
	boss_camera.top_level = true


func _process(delta: float) -> void:
	if is_instance_valid(arena_player):
		_update_boss_camera(delta)
	if state == State.INACTIVE or state == State.DEAD:
		return

	var doing_root_attack := (
		state == State.TELEGRAPH or state == State.ATTACK
	) and current_attack == Attack.ROOT_STRIKE

	if not doing_root_attack:
		var player := _get_target()
		if is_instance_valid(player):
			var direction := player.global_position - global_position
			direction.y = 0.0

			if direction.length_squared() > 0.001:
				var target_angle := atan2(direction.x, direction.z)
				rotation.y = lerp_angle(rotation.y, target_angle, 4.0 * delta)

	if Input.is_action_just_pressed("attack"):
		take_damage(10)

	state_time -= delta
	if state == State.ATTACK:
		attack_elapsed += delta
		if current_attack == Attack.FRUIT_DROP:
			_fire_scheduled_fruit()
		elif current_attack == Attack.AIR_PUFF:
			_fire_scheduled_air()
		elif current_attack == Attack.ROOT_STRIKE and attack_elapsed >= root_active_time:
			_retract_roots()
	if state_time > 0.0:
		return
	match state:
		State.IDLE:
			current_attack = _choose_next_attack()
			_change_state(State.TELEGRAPH)
		State.TELEGRAPH:
			_change_state(State.ATTACK)
		State.ATTACK:
			_change_state(State.RECOVERY)
		State.RECOVERY, State.PHASE_TRANSITION:
			_change_state(State.IDLE)


func start_battle() -> void:
	if state == State.INACTIVE:
		_change_state(State.IDLE)


func take_damage(amount: int) -> void:
	if amount <= 0 or state == State.INACTIVE or state == State.DEAD:
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	if health == 0:
		_change_state(State.DEAD)
	elif phase == 1 and health <= max_health * 0.5:
		phase = 2
		attack_index = 0
		phase_changed.emit(phase)
		_change_state(State.PHASE_TRANSITION)


func _choose_next_attack() -> Attack:
	var attacks: Array[Attack] = [Attack.FRUIT_DROP, Attack.AIR_PUFF]
	if phase == 2:
		attacks = [Attack.ROOT_STRIKE, Attack.FRUIT_DROP, Attack.AIR_PUFF]
	var chosen := attacks[attack_index % attacks.size()]
	attack_index += 1
	return chosen


func _change_state(next_state: State) -> void:
	_clear_warnings()
	if state == State.ATTACK or next_state == State.PHASE_TRANSITION or next_state == State.DEAD:
		_retract_roots()
	state = next_state
	match state:
		State.IDLE:
			state_time = idle_duration
		State.TELEGRAPH:
			state_time = telegraph_duration
			_telegraph_attack()
		State.ATTACK:
			state_time = attack_duration
			attack_elapsed = 0.0
			shots_fired = 0
			_perform_attack()
		State.RECOVERY:
			state_time = recovery_duration
		State.PHASE_TRANSITION:
			state_time = phase_transition_duration
		State.DEAD:
			if is_instance_valid(arena_player):
				arena_player.exit_boss_arena()
				arena_player = null
			for projectile in projectiles:
				if is_instance_valid(projectile):
					projectile.queue_free()
			defeated.emit()


func _get_target() -> Node3D:
	if is_instance_valid(target):
		return target
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty() and players[0] is Node3D:
		return players[0] as Node3D
	return null


func _telegraph_attack() -> void:
	attack_telegraphed.emit(current_attack)
	if current_attack != Attack.FRUIT_DROP:
		return

	fruit_positions.clear()

	var player := _get_target() as Player
	if player == null:
		return

	for i in range(maxi(fruit_count, 1) + (2 if phase == 2 else 0)):
		var offset := Vector3(randf_range(-fruit_spread, fruit_spread), 0.0, randf_range(-fruit_spread, fruit_spread))
		var landing := player.get_ground_position() + offset
		fruit_positions.append(landing)

		var marker := LANDING_MARKER_SCENE.instantiate() as LandingMarker
		get_tree().current_scene.add_child(marker)
		marker.global_position = landing + Vector3.UP * 0.04
		warning_markers.append(marker)


func _perform_attack() -> void:
	match current_attack:
		Attack.FRUIT_DROP:
			_fire_scheduled_fruit()
		Attack.AIR_PUFF:
			_fire_scheduled_air()
		Attack.ROOT_STRIKE:
			for root in roots:
				root.visible = true
				root.damage = root_damage
				root.begin_strike()
				var animation := root.get_node_or_null("AnimationPlayer") as AnimationPlayer
				if animation:
					animation.play("Enter")


func _fire_scheduled_fruit() -> void:
	if fruit_positions.is_empty():
		return
	var interval := attack_duration / float(fruit_positions.size())
	while shots_fired < fruit_positions.size() and attack_elapsed >= shots_fired * interval:
		var landing := fruit_positions[shots_fired]
		var fruit := _spawn_projectile(FRUIT_SCENE, 0.5, fruit_damage)
		fruit.global_position = landing + Vector3.UP * fruit_height
		fruit.velocity = Vector3.DOWN * 2.0
		fruit.grav = 20.0
		fruit.ground_y = landing.y
		shots_fired += 1


func _fire_scheduled_air() -> void:
	var player := _get_target()
	if player == null:
		return
	var total := 2 if phase == 1 else 4
	var interval := attack_duration / float(total)
	while shots_fired < total and attack_elapsed >= shots_fired * interval:
		var puff := _spawn_projectile(AIR_SCENE, 0.48, air_damage)
		var origin := global_position + global_basis * Vector3(0, 6.0, 2.4)
		puff.global_position = origin
		var direction := (player.global_position + Vector3.UP - origin).normalized()
		puff.velocity = direction * air_speed
		shots_fired += 1


func _spawn_projectile(scene: PackedScene, radius: float, damage: int) -> ForestGuardianProjectile:
	var projectile := scene.instantiate() as ForestGuardianProjectile
	get_tree().current_scene.add_child(projectile)
	projectile.setup(radius, damage)
	projectiles.append(projectile)
	return projectile


func _retract_roots() -> void:
	for root in roots:
		root.end_strike()
		if root.visible:
			var animation := root.get_node_or_null("AnimationPlayer") as AnimationPlayer
			if animation:
				animation.play("Exit")
				# Hide only after the exit animation finishes.
				get_tree().create_timer(0.8).timeout.connect(_hide_root.bind(root, animation))


func _hide_root(root: Area3D, animation: AnimationPlayer) -> void:
	if is_instance_valid(root) and is_instance_valid(animation) and animation.current_animation == "Exit":
		root.visible = false


func _clear_warnings() -> void:
	for marker in warning_markers:
		if is_instance_valid(marker):
			marker.despawn()
	warning_markers.clear()


func _check_initial_arena_overlap() -> void:
	await get_tree().physics_frame
	for body in arena_area.get_overlapping_bodies():
		_on_arena_body_entered(body)


func _on_arena_body_entered(body: Node3D) -> void:
	if state == State.DEAD or arena_player != null or not body is Player:
		return

	var player := body as Player
	var distance := Vector2(player.global_position.x - global_position.x, player.global_position.z - global_position.z).length()
	if distance > arena_radius:
		return
	arena_player = player
	target = player
	var old_camera := player.current_camera
	if not is_instance_valid(old_camera):
		old_camera = player.camera

	boss_camera.global_transform = old_camera.global_transform
	player.enter_boss_arena(global_position, distance, boss_camera)
	start_battle()


func _update_boss_camera(delta: float) -> void:
	var radial := arena_player.global_position - global_position
	radial.y = 0.0
	if radial.length_squared() < 0.001:
		radial = Vector3.FORWARD

	var desired_position := (
		global_position
		+ radial.normalized() * camera_distance
		+ Vector3.UP * camera_height
	)
	var blend := clampf(delta * camera_follow_speed, 0.0, 1.0)

	boss_camera.global_position = boss_camera.global_position.lerp(
		desired_position, blend
	)

	var look_target := global_position + Vector3.UP * camera_look_height
	var desired_basis := Basis.looking_at(
		(look_target - boss_camera.global_position).normalized(),
		Vector3.UP
	)
	boss_camera.global_basis = Basis(
		boss_camera.global_basis.get_rotation_quaternion().slerp(
			desired_basis.get_rotation_quaternion(),
			blend
		)
	)
