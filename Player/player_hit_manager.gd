extends Node

@export var player: Player

@onready var feet_hitbox: Hitbox = $"../FeetHitbox"


func _ready() -> void:
	feet_hitbox.hit_hurtbox.connect(_hit_hurtbox)
	feet_hitbox.active = false


func _physics_process(_delta: float) -> void:
	feet_hitbox.active = (
		not player.is_on_floor()
		and player.velocity.y < 0.0
	)


func _hit_hurtbox(_hurtbox: Hurtbox) -> void:
	player.apply_upward_force(17.0)
