class_name Hurtbox
extends Area3D

signal hit(hitbox: Hitbox)

@export var health: Health

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area3D):
	if area is not Hitbox:
		return

	var hitbox: Hitbox = area
	if hitbox.register_hit(self):
		hit.emit(hitbox)