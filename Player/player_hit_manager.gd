extends Node

@export var player: Player
@export var upward_force: float = 22.0

@onready var feet_hitbox: Hitbox = $"../FeetHitbox"

func _ready() -> void:
	feet_hitbox.hit_hurtbox.connect(_hit_hurtbox)
	feet_hitbox.active = false


func _physics_process(_delta: float) -> void:
	feet_hitbox.active = (
		not player.is_on_floor()
		and player.velocity.y < 0.0
	)


func _hit_hurtbox(hurtbox: Hurtbox) -> void:
	if hurtbox.flags.has("UpwardForce"):
		player.apply_upward_force(upward_force)
