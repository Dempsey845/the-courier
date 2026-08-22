class_name NPC
extends Node3D

signal interact

@onready var interact_zone: Area3D = $InteractZone
@onready var dialogue_controller: DialogueController = $DialogueController
@onready var input_prompt: InputPrompt = $InputPrompt

var is_in_area: bool

func _ready() -> void:
	interact_zone.area_entered.connect(_on_area_entered)
	interact_zone.area_exited.connect(_on_area_exited)

	DialogueManager.instance.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.instance.dialogue_ended.connect(_on_dialogue_ended)

func _process(_delta: float) -> void:
	if is_in_area and Input.is_action_just_pressed("interact"):
		dialogue_controller.start()
		interact.emit()

func _on_area_entered(area: Area3D):
	if area.get_parent() is Player:
		is_in_area = true

func _on_area_exited(area: Area3D):
	if area.get_parent() is Player:
		is_in_area = false

func _on_dialogue_started(_npc):
	input_prompt.can_be_shown = false

func _on_dialogue_ended():
	input_prompt.can_be_shown = true