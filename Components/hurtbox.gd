class_name Hurtbox
extends Area3D

signal hit(hitbox: Hitbox)

@export var health: Health
@export var flags: Array[String]

var just_hit: bool = false
var hit_sequence: int = 0


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area3D) -> void:
	if area is not Hitbox:
		return

	var hitbox: Hitbox = area

	if hitbox.register_hit(self):
		just_hit = true
		hit_sequence += 1

		clear_just_hit_next_frame(hit_sequence)


func clear_just_hit_next_frame(sequence: int) -> void:
	await get_tree().physics_frame

	if sequence == hit_sequence:
		just_hit = false

func emit_hit(hitbox: Hitbox):
	hit.emit(hitbox)