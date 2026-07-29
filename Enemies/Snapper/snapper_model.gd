extends Node3D

@export var projectile_speed: float = 12.0
@export var maximum_prediction_time: float = 2.0
@export var shoot_projectile_time: float = 1.2

@onready var projectile_point: Marker3D = $ProjectilePoint
@onready var animation_tree: AnimationTree = $AnimationTree

var projectile_scene: PackedScene = preload("uid://cahnx3e1k3wqg")

var state_machine: AnimationNodeStateMachinePlayback

var just_hit: bool

var target: Node3D

func _ready() -> void:
	var enemy: Enemy = get_parent()

	target = enemy.target

	await get_tree().process_frame

	state_machine = animation_tree.get("parameters/playback")

	enemy.attacked.connect(func(_target: Node3D):
		state_machine.travel("Shoot")

		var projectile_shoot_timer: SceneTreeTimer = get_tree().create_timer(shoot_projectile_time)
		projectile_shoot_timer.timeout.connect(spawn_projectiles)
	)

	enemy.health.damage_taken.connect(func(_damage_amount, _new_health):
		state_machine.travel("Hit")
		just_hit = true
		await animation_tree.animation_finished
		just_hit = false
	)

	var shoot_animation: Animation = animation_tree.get_animation("Shoot")
	if enemy.attack_cooldown < shoot_animation.length:
		push_error("Enemy attack cooldown is shorter then the attack animation length!")


func _spawn_projectile(spawn_point: Marker3D):
	var projectile: Projectile = projectile_scene.instantiate()
	
	get_tree().current_scene.add_child(projectile)

	projectile.global_position = spawn_point.global_position
	projectile.global_rotation = spawn_point.global_rotation

func spawn_projectiles():
	if !just_hit:
		aim_at_predicted_position()
		_spawn_projectile(projectile_point)

func aim_at_predicted_position() -> void:
	if not is_instance_valid(target):
		return

	var target_position: Vector3 = target.global_position

	if target is CharacterBody3D:
		var character_target := target as CharacterBody3D

		target_position = calculate_intercept_position(
			projectile_point.global_position,
			character_target.global_position + Vector3.UP,
			character_target.velocity,
			projectile_speed
		)

	if projectile_point.global_position.distance_squared_to(
		target_position
	) <= 0.001:
		return

	projectile_point.look_at(
		target_position,
		Vector3.UP,
		true
	)

func calculate_intercept_position(
	shooter_position: Vector3,
	target_position: Vector3,
	target_velocity: Vector3,
	speed: float
) -> Vector3:
	if speed <= 0.0:
		return target_position

	var displacement: Vector3 = target_position - shooter_position

	var a: float = target_velocity.length_squared() - speed * speed
	var b: float = 2.0 * displacement.dot(target_velocity)
	var c: float = displacement.length_squared()

	var prediction_time: float = 0.0

	if absf(a) < 0.001:
		if absf(b) > 0.001:
			prediction_time = maxf(-c / b, 0.0)
	else:
		var discriminant: float = b * b - 4.0 * a * c

		if discriminant >= 0.0:
			var square_root: float = sqrt(discriminant)
			var time_a: float = (-b - square_root) / (2.0 * a)
			var time_b: float = (-b + square_root) / (2.0 * a)

			if time_a > 0.0 and time_b > 0.0:
				prediction_time = minf(time_a, time_b)
			elif time_a > 0.0:
				prediction_time = time_a
			elif time_b > 0.0:
				prediction_time = time_b

	prediction_time = minf(
		prediction_time,
		maximum_prediction_time
	)

	return target_position + target_velocity * prediction_time