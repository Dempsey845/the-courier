extends StaticBody3D

@export var fire_cooldown: float = 2.0
@export var ammo_drain_duration: float = 1.2

@onready var ammo_orb: MeshInstance3D = $AmmoOrb
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var fire_point: Marker3D = %FirePoint

var projectile_scene: PackedScene = preload("uid://chmyrswmwh50o")

var ammo_material: ShaderMaterial
var ammo_tween: Tween
var is_firing: bool = false


func _ready() -> void:
	ammo_material = ammo_orb.get_surface_override_material(0)

	ammo_material.set_shader_parameter("fill_progress", 1.0)

	await get_tree().create_timer(6.0).timeout
	fire()
	await get_tree().create_timer(6.0).timeout
	fire()
	await get_tree().create_timer(6.0).timeout
	fire()
	await get_tree().create_timer(6.0).timeout
	fire()
	await get_tree().create_timer(6.0).timeout
	fire()


func fire() -> void:
	if is_firing or ammo_material == null:
		return

	is_firing = true
	animation_player.play("aim_fire")

	_tween_fill_progress(
		0.0,
		ammo_drain_duration,
		Tween.TRANS_QUAD,
		Tween.EASE_IN
	)

	await animation_player.animation_finished

	_tween_fill_progress(
		1.0,
		fire_cooldown,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	)

	await ammo_tween.finished
	is_firing = false

func shoot_projectile():
	var projectile: Projectile = projectile_scene.instantiate()

	fire_point.add_child(projectile)

	projectile.global_position = fire_point.global_position
	projectile.global_rotation = fire_point.global_rotation

func _tween_fill_progress(
	target: float,
	duration: float,
	transition: Tween.TransitionType,
	ease_type: Tween.EaseType
) -> void:
	if ammo_tween and ammo_tween.is_valid():
		ammo_tween.kill()

	var current_fill: float = ammo_material.get_shader_parameter(
		"fill_progress"
	)

	ammo_tween = create_tween()
	ammo_tween.set_trans(transition)
	ammo_tween.set_ease(ease_type)

	ammo_tween.tween_method(
		_set_fill_progress,
		current_fill,
		target,
		duration
	)


func _set_fill_progress(value: float) -> void:
	ammo_material.set_shader_parameter("fill_progress", value)