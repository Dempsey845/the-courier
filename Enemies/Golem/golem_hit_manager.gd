extends Node

@export var hurtbox: Hurtbox

var hit_particles_scene: PackedScene = preload("uid://mo7gk0o8p4t")

func _ready() -> void:
	hurtbox.hit.connect(_on_hurtbox_hit)


func _on_hurtbox_hit(hitbox: Hitbox):
	var hit_particles = hit_particles_scene.instantiate()
	get_tree().current_scene.add_child(hit_particles)
	hit_particles.global_position = hitbox.global_position

