extends Node

enum WorldType {
    World,
    FrogRealm,
    Dungeon
}

var world_portal_activated: bool
var player_world_start_position: Vector3 = Vector3(-191.144, 2, -25.8)

var world_started: bool

var player_items: Dictionary[PlayerItemManager.Item, int] = {}

var player_killed_frog_boss: bool

var player_has_depetrification_device: bool

var previous_world_type: WorldType
var current_world_type: WorldType

func change_world(world_scene_file_path: String, transition_from_world_type: WorldType) -> Error:
    previous_world_type = transition_from_world_type
    var error: Error = get_tree().change_scene_to_file(
		world_scene_file_path
	)
    return error
