class_name BridgePlatforms
extends Node3D

func _ready() -> void:
    if DataManager.player_killed_frog_boss:
        show_bridge_platforms()

func show_bridge_platform(bridge_platform: Node3D):
    if !bridge_platform.has_node("AnimationPlayer"):
        return
    
    var animation_player: AnimationPlayer = bridge_platform.get_node("AnimationPlayer")
    animation_player.play("spawn_in")

    await animation_player.animation_finished

func show_bridge_platforms():
    for bridge_platform: Node3D in get_children():
        await show_bridge_platform(bridge_platform)