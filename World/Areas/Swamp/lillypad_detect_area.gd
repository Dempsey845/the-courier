extends Area3D

@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"

func _ready() -> void:
	body_entered.connect(func(_body: Node3D):
		animation_player.play("bounce")
	)
	
