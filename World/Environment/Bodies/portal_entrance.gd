extends Area3D

@export var portal: Portal

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D):
	if body is Player and portal.shown:
		portal.play_enter_feedback()
