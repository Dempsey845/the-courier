extends Area3D

@onready var animation_player: AnimationPlayer = $"CanvasLayer/AnimationPlayer"

var dungeon_scene: PackedScene = preload("uid://bdtphcf1wm32j")

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D):
    if body is Player:
        animation_player.play("fade_out")
        await animation_player.animation_finished
        get_tree().change_scene_to_packed.call_deferred(dungeon_scene)
