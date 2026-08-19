class_name InputUIPrompt
extends Control

signal pressed

@export var input_action: ControllerManager.InputAction

@onready var action_icon: TextureRect = $Control/ActionIcon
@onready var input_icon: TextureRect = $Control/InputIcon

@onready var action_animation_player: AnimationPlayer = $Control/ActionAnimationPlayer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var can_press: bool = true
var shown: bool

func _ready() -> void:
	var start_controller_type: ControllerManager.ControllerType = ControllerManager.refresh()

	var icon_texture: Texture = (
		ControllerManager.input_icons[input_action][start_controller_type]
	)

	input_icon.texture = icon_texture

	ControllerManager.input_device_changed.connect(_on_input_device_change)

	if ControllerManager.action_icons.has(input_action):
		action_icon.texture = ControllerManager.action_icons[input_action]

func _on_input_device_change(
	_using_controller: bool,
	controller_type: ControllerManager.ControllerType
) -> void:
	var icon_texture: Texture = (
		ControllerManager.input_icons[input_action][controller_type]
	)

	input_icon.texture = icon_texture

func _process(_delta: float) -> void:
	if shown:
		var action: String = ControllerManager.input_actions[input_action]

		if (
			not action_animation_player.is_playing()
			and can_press
			and Input.is_action_just_pressed(action)
		):
			action_animation_player.play("press")
			pressed.emit()

func show_prompt():
	animation_player.play("show")
	shown = true

func hide_prompt():
	animation_player.play_backwards("show")
	shown = false
