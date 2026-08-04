extends Node3D

@onready var item_bubble: ItemBubble = $ItemBubble
@onready var interact_area: InteractArea = $InteractArea

func _ready() -> void:
    interact_area.player_entered.connect(_on_player_entered)
    interact_area.player_exited.connect(_on_player_exited)

func _on_player_entered():
    item_bubble.show_bubble()

func _on_player_exited():
    item_bubble.hide_bubble()