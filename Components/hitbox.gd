class_name Hitbox
extends Area3D

signal hit_hurtbox(hurtbox: Hurtbox)

@export var damage: int = 1
@export var active: bool = true
@export var source: String = ""

func register_hit(hurtbox: Hurtbox):
	if not active:
		return false

	hurtbox.health.take_damage(damage)
	hit_hurtbox.emit(hurtbox)
	hurtbox.emit_hit(self)

	return true

func force_hit_update():
	var overlapping_areas = get_overlapping_areas()

	for area: Area3D in overlapping_areas:
		if area is not Hurtbox:
			continue
		
		var hurtbox: Hurtbox = area
		if hurtbox.just_hit:
			continue
		
		register_hit(hurtbox)
