extends Node3D

@export var player: Player
@export var frog_boss: FrogBoss
@export var bridge_platforms: BridgePlatforms

@onready var portal: Portal = $Arc2/Portal

var portal_transition: PortalTransitionUI

func _ready() -> void:
    DataManager.player_world_start_position = Vector3(0, 8.9, -152.0)

    var canvas_layer = player.get_node("CanvasLayer")
    portal_transition = canvas_layer.get_node("Container/PortalTransitionUI")
    portal_transition.set_portal_transition(1.0)
    portal_transition.exit_portal()

    portal.portal_entered.connect(_on_portal_entered)

    player.gravity /= 1.5

    frog_boss.death.connect(_on_frog_boss_death)
    
func _on_portal_entered():
    portal_transition.enter_portal("res://World/world.tscn")

func _on_frog_boss_death():
    bridge_platforms.show_bridge_platforms()