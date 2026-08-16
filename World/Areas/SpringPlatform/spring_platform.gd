class_name SpringPlatform
extends Node3D

@export var upward_force: float = 12.0
@export var forward_force: float = 5.0
@export var forward_pivot: Marker3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var spring_activation_area: Area3D = $SpringActivationArea

func _ready() -> void:
	spring_activation_area.body_entered.connect(_on_spring_activation_area_body_entered)

func _on_spring_activation_area_body_entered(body: Node3D):
	if body is not Player:
		return
	
	if animation_player.is_playing():
		return
	
	animation_player.play("spring")

	await animation_player.animation_finished

	var player: Player = body
	player.apply_upward_force(upward_force)
	if forward_force > 0.0:
		player.apply_directional_force(forward_pivot.global_basis.y, forward_force)

func introduce():
	animation_player.play("introduce")
