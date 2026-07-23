extends CPUParticles3D

@export var player: Player

func _ready() -> void:
	player.jump.connect(func():
		emitting = true
	)


