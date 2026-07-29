extends Node3D

@export var shoot_projectile_time: float = 1.2

@onready var projectile_point: Marker3D = $ProjectilePoint
@onready var animation_tree: AnimationTree = $AnimationTree

var projectile_scene: PackedScene = preload("uid://cahnx3e1k3wqg")

var state_machine: AnimationNodeStateMachinePlayback

var just_hit: bool

func _ready() -> void:
	var enemy: Enemy = get_parent()

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
		_spawn_projectile(projectile_point)