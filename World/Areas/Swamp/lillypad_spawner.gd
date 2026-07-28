extends Node3D

@export var water: MeshInstance3D
@export_range(1, 100, 1) var lily_pad_count: int = 5
@export var spacing: float = 7.0
@export var maximum_x_offset: float = 0.75

var lily_pad_scene: PackedScene = preload("uid://g6qjr8aewopi")

func _ready() -> void:
	spawn_lily_pads()


func spawn_lily_pads() -> void:
	if lily_pad_scene == null:
		push_warning("No lily pad scene has been assigned.")
		return

	for index: int in range(lily_pad_count):
		var lily_pad: Buoyancy = lily_pad_scene.instantiate()

		lily_pad.water = water

		add_child(lily_pad)

		lily_pad.position = Vector3(
			randf_range(-maximum_x_offset, maximum_x_offset),
			0.0,
			-index * spacing
		)

		lily_pad.rotation.y = randf_range(0.0, TAU)