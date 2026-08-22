extends Node

@export var dialogue_controller: DialogueController
@export var flame_wisp_model: FlameWispModel

@onready var npc: NPC = get_parent()

var is_depetrifying: bool

func _ready() -> void:
    dialogue_controller.can_start = false

    npc.interact.connect(_on_npc_interact)

func _on_npc_interact():
    if dialogue_controller.can_start or is_depetrifying or !DataManager.player_has_depetrification_device:
        return

    is_depetrifying = true
    await flame_wisp_model.depetrify()

    dialogue_controller.can_start = true
    is_depetrifying = false
