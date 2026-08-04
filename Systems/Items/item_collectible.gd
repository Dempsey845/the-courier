class_name ItemCollectible
extends Area3D

@export var item: PlayerItemManager.Item

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collect_delay_timer: Timer = $CollectDelayTimer

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D):
    if body is Player and collect_delay_timer.is_stopped():
        animation_player.play("collect")
        await animation_player.animation_finished
        var item_manager: PlayerItemManager = body.get_node("PlayerItemManager")
        item_manager.add_item(item)
        queue_free.call_deferred()