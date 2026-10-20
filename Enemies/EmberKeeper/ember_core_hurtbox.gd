extends Hurtbox
## Armour rejects ordinary melee and cinders thrown outside the vent window.
func _on_area_entered(area: Area3D) -> void:
	if area is Hitbox and area.source == "ember_cinder":
		super._on_area_entered(area)
