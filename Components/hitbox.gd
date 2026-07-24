class_name Hitbox
extends Area3D

signal hit_hurtbox(hurtbox: Hurtbox)

@export var damage: int = 1
@export var active: bool = true

func register_hit(hurtbox: Hurtbox):
	if not active:
		return false

	hurtbox.health.take_damage(damage)
	hit_hurtbox.emit(hurtbox)

	return true