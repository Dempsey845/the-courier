extends Node3D

@export var player: Player

@onready var portal: Portal = $Arc2/Portal

var portal_transition: PortalTransitionUI

func _ready() -> void:
    var canvas_layer = player.get_node("CanvasLayer")
    portal_transition = canvas_layer.get_node("Container/PortalTransitionUI")
    portal_transition.set_portal_transition(1.0)
    portal_transition.exit_portal()

    portal.portal_entered.connect(_on_portal_entered)

func _on_portal_entered():
    portal_transition.enter_portal("res://World/world.tscn")