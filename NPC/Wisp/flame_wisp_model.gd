class_name FlameWispModel
extends Node3D

@export var wisp_mesh: MeshInstance3D
@export var depetrification_duration: float = 2.0

@onready var lantern_fire_particles: CPUParticles3D = $LanternFireParticles
@onready var fire_particles: FireParticles = $FireParticles

var petrification_material: ShaderMaterial

func _ready() -> void:
	petrification_material = wisp_mesh.material_overlay

func depetrify():
	var tween := create_tween()

	tween.tween_method(
		func(value: float) -> void:
			petrification_material.set_shader_parameter(
				"progress",
				value
			),
		1.0,
		0.0,
		depetrification_duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	await tween.finished

	fire_particles.enable_fire()
	lantern_fire_particles.emitting = true