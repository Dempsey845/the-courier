class_name ItemCollectible
extends Area3D

@export var item: PlayerItemManager.Item

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collect_delay_timer: Timer = $CollectDelayTimer

var index: int = -1

var collected: bool

func _ready() -> void:
    body_entered.connect(_on_body_entered)

    await get_tree().process_frame

    index = WorldCollectibles.add_world_collectible(self, global_position)

func _on_body_entered(body: Node3D):
    if body is Player and collect_delay_timer.is_stopped() and !collected:
        collected = true
        animation_player.play("collect")
        await animation_player.animation_finished

        var item_manager: PlayerItemManager = body.get_node("PlayerItemManager")
        item_manager.add_item(item)
        
        if index == -1:
            push_error("World collectible not assigned")
            return

        WorldCollectibles.collectibles[index]["collected"] = true

        queue_free.call_deferred()