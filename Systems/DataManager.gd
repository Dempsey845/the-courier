extends Node

var world_portal_activated: bool
var player_world_start_position: Vector3 = Vector3(0, 0, -25.0)

var world_started: bool

var player_items: Dictionary[PlayerItemManager.Item, int] = {}