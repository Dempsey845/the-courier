class_name NPC
extends Node3D

@onready var interact_zone: Area3D = $InteractZone
@onready var dialogue_controller: DialogueController = $DialogueController

var is_in_area: bool

func _ready() -> void:
    interact_zone.area_entered.connect(_on_area_entered)
    interact_zone.area_exited.connect(_on_area_exited)

func _process(_delta: float) -> void:
    if is_in_area and Input.is_action_just_pressed("interact"):
        dialogue_controller.start()

func _on_area_entered(area: Area3D):
    if area.get_parent() is Player:
        is_in_area = true

func _on_area_exited(area: Area3D):
    if area.get_parent() is Player:
        is_in_area = false