class_name DialogueUI
extends Control

signal typing_complete
signal user_advance

@export var typing_speed: float = 0.03

@onready var dialogue_label: Label = %DialogueLabel
@onready var icon_texture: TextureRect = %IconTexture
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _typing: bool

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("advance_dialogue"):
		user_advance.emit()	

func open_dialogue(icon: CompressedTexture2D):
	icon_texture.texture = icon
	animation_player.play("open")

func close_dialogue():
	dialogue_label.text = ""
	animation_player.play("close")

func start_dialogue_text(text: String) -> void:
	dialogue_label.text = text
	dialogue_label.visible_characters = 0

	_typing = true

	for i in text.length():
		if !_typing:
			break

		dialogue_label.visible_characters = i + 1
		await get_tree().create_timer(typing_speed).timeout

	dialogue_label.visible_characters = -1 
	_typing = false
	typing_complete.emit()
