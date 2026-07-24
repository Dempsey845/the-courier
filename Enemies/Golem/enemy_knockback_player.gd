class_name EnemyKnockbackPlayer
extends Node

@export var hitbox: Hitbox
@export var source: Node3D
@export var force: float = 12.0
@export var upward_force: float = 6.0

func _ready() -> void:
	hitbox.hit_hurtbox.connect(func(hurtbox: Hurtbox):
		if hurtbox.get_parent() is Player:
			var player: Player = hurtbox.get_parent()
			player.apply_knockback(source.global_position, force, upward_force)
	)

