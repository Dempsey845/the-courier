class_name FrogRealm
extends Node3D

signal frog_boss_spawned

@export var player: Player
@export var frog_boss_camera: Camera3D
@export var frog_boss_camera_pivot: Marker3D
@export var camera_transition_duration: float = 1.25
@export var bridge_platforms: BridgePlatforms

@onready var portal: Portal = $Arc2/Portal
@onready var frog_boss_spawn_point: Marker3D = %FrogBossSpawnPoint
@onready var spring_platforms: Node3D = $SpringPlatforms

var portal_transition: PortalTransitionUI

var camera_transition_tween: Tween
var frog_boss_camera_local_transform: Transform3D

var frog_boss: FrogBoss

func _ready() -> void:
	DataManager.current_world_type = DataManager.WorldType.FrogRealm

	if DataManager.player_killed_frog_boss:
		if DataManager.previous_world_type != DataManager.WorldType.World:
			DataManager.player_world_start_position = Vector3(-80.0, 1.3, 0.0)
	else:
		frog_boss = preload("uid://es6r4xwsgwka").instantiate()
		frog_boss.player = player
		frog_boss.spring_platforms_owner = spring_platforms

		add_child(frog_boss)
		frog_boss.global_position = frog_boss_spawn_point.global_position

		DataManager.player_world_start_position = Vector3(0.0, 0.0, 0.0)

		frog_boss.death.connect(_on_frog_boss_death)

		frog_boss_spawned.emit()

	DataManager.previous_world_type = DataManager.WorldType.FrogRealm

	player.global_position = DataManager.player_world_start_position

	frog_boss_camera_local_transform = frog_boss_camera.transform

	var canvas_layer = player.get_node("CanvasLayer")
	portal_transition = canvas_layer.get_node("Container/PortalTransitionUI")
	portal_transition.set_portal_transition(1.0)
	portal_transition.exit_portal()

	portal.portal_entered.connect(_on_portal_entered)

	player.gravity /= 1.2


	
func switch_to_frog_boss_camera() -> void:
	if camera_transition_tween:
		camera_transition_tween.kill()

	var start_fov: float = player.camera.fov
	var target_fov: float = frog_boss_camera.fov

	frog_boss_camera.global_transform = player.camera.global_transform
	frog_boss_camera.fov = start_fov
	frog_boss_camera.current = true
	player.current_camera = frog_boss_camera

	camera_transition_tween = create_tween()
	camera_transition_tween.set_trans(Tween.TRANS_QUAD)
	camera_transition_tween.set_ease(Tween.EASE_IN_OUT)

	camera_transition_tween.tween_method(
		func(weight: float) -> void:
			var player_transform := player.camera.global_transform

			var boss_transform := (
				frog_boss_camera_pivot.global_transform
				* frog_boss_camera_local_transform
			)

			frog_boss_camera.global_transform = (
				player_transform.interpolate_with(
					boss_transform,
					weight
				)
			)

			frog_boss_camera.fov = lerpf(
				start_fov,
				target_fov,
				weight
			),
		0.0,
		1.0,
		camera_transition_duration
	)

	await camera_transition_tween.finished

	frog_boss_camera.transform = frog_boss_camera_local_transform
	frog_boss_camera.fov = target_fov

	camera_transition_tween = null

func switch_to_player_camera() -> void:
	if camera_transition_tween:
		camera_transition_tween.kill()

	var start_transform := frog_boss_camera.global_transform
	var start_fov := frog_boss_camera.fov

	frog_boss_camera.current = true
	player.current_camera = frog_boss_camera

	camera_transition_tween = create_tween()
	camera_transition_tween.set_trans(Tween.TRANS_QUAD)
	camera_transition_tween.set_ease(Tween.EASE_IN_OUT)

	camera_transition_tween.tween_method(
		func(weight: float) -> void:
			frog_boss_camera.global_transform = start_transform.interpolate_with(
				player.camera.global_transform,
				weight
			)
			frog_boss_camera.fov = lerpf(
				start_fov,
				player.camera.fov,
				weight
			),
		0.0,
		1.0,
		camera_transition_duration
	)

	await camera_transition_tween.finished

	player.camera.current = true
	player.current_camera = player.camera
	camera_transition_tween = null

func _on_portal_entered():
	portal_transition.enter_portal("res://World/world.tscn", DataManager.WorldType.FrogRealm)

func _on_frog_boss_death():
	bridge_platforms.show_bridge_platforms()
	DataManager.player_killed_frog_boss = true
