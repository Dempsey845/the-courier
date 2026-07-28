extends Area3D

@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"

var force: float = 35.0

func _ready() -> void:
	body_entered.connect(func(body: Node3D):
		animation_player.play("bounce")

		if body is Player:
			var player: Player = body
			player.apply_upward_force(22.0)
			player.apply_camera_forward_force(12.0)
	)
	
