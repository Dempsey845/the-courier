extends Node3D

@export var portal: Portal

@onready var    item_bubble: ItemBubble = $ItemBubble
@onready var interact_area: InteractArea = $InteractArea

func _ready() -> void:
    interact_area.player_entered.connect(_on_player_entered)
    interact_area.player_exited.connect(_on_player_exited)
    interact_area.interacted.connect(_on_interacted)

func _on_interacted(player: Player):
    var item_manager: PlayerItemManager
    item_manager = player.get_node("PlayerItemManager")

    if item_manager.current_items.has(PlayerItemManager.Item.Mushroom) \
    and item_manager.current_items[PlayerItemManager.Item.Mushroom] >= 5:
        item_bubble.hide_bubble()
        item_manager.remove_item(PlayerItemManager.Item.Mushroom, 5)
        portal.open_portal()

func _on_player_entered():
    if !portal.shown:
        item_bubble.show_bubble()

func _on_player_exited():
    if !portal.shown:
        item_bubble.hide_bubble()