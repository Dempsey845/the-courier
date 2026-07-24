extends Node

@export var golem_collider: CollisionShape3D

@onready var health: Health = $"../Health"

var golem_physics_body_scene: PackedScene = preload("uid://b1sill1p3gsml")

func _ready() -> void:
	health.death.connect(_on_death)

func _on_death():
	golem_collider.set_deferred("disabled", true)

	await get_tree().process_frame

	var body = golem_physics_body_scene.instantiate()

	get_tree().current_scene.add_child(body)
	body.global_position = get_parent().global_position
	body.global_rotation = get_parent().global_rotation
	get_parent().queue_free()
