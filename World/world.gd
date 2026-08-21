extends Node3D

@export var scale_3d: float = 1.0

@export var player: Player

var portal_transition: PortalTransitionUI

var world_scene: PackedScene = preload("uid://bj3ripvo7qsjp")

func _ready() -> void:
	get_viewport().scaling_3d_scale = scale_3d

	DataManager.current_world_type = DataManager.WorldType.World

	match DataManager.previous_world_type:
		DataManager.WorldType.FrogRealm:
			DataManager.player_world_start_position = Vector3(0.0, 8.9, -152.0)
		DataManager.WorldType.Dungeon:
			DataManager.player_world_start_position = Vector3(-208.1, 2.7, -26.8)
		DataManager.WorldType.World:
			DataManager.player_world_start_position = Vector3(0, 1, -25.0)

	DataManager.previous_world_type = DataManager.WorldType.World

	player.global_position = DataManager.player_world_start_position

	var canvas_layer = player.get_node("CanvasLayer")
	portal_transition = canvas_layer.get_node("Container/PortalTransitionUI")

	if portal_transition.get_portal_transition() == 1.0:
		portal_transition.exit_portal()

	await get_tree().create_timer(1.0).timeout
	WorldEnemies.spawn_world_enemies(player)
	WorldCollectibles.spawn_world_collectibles()
	DataManager.world_started = true
