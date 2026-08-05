extends Node

var world_portal_activated: bool
var player_world_start_position: Vector3 = Vector3(-191.144, 2, -25.8)

var world_started: bool

var player_items: Dictionary[PlayerItemManager.Item, int] = {}
