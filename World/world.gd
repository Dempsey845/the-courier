extends Node3D

@export var scale_3d: float = 1.0

@export var player: Player

var portal_transition: PortalTransitionUI

var world_scene: PackedScene = preload("uid://bj3ripvo7qsjp")

func _ready() -> void:
	get_viewport().scaling_3d_scale = scale_3d

	var canvas_layer = player.get_node("CanvasLayer")
	portal_transition = canvas_layer.get_node("Container/PortalTransitionUI")

	if portal_transition.get_portal_transition() == 1.0:
		portal_transition.exit_portal()
