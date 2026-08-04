extends Node3D

@export var portal: Portal

@onready var item_bubble: ItemBubble = $ItemBubble
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
        portal.portal_entered.connect(func():
            var canvas_layer = player.get_node("CanvasLayer")
            var portal_transition: PortalTransitionUI = canvas_layer.get_node("Container/PortalTransitionUI")
            portal_transition.enter_portal("res://World/Areas/FrogRealm/frog_realm.tscn")
        )

func _on_player_entered():
    if !portal.shown:
        item_bubble.show_bubble()

func _on_player_exited():
    if !portal.shown:
        item_bubble.hide_bubble()