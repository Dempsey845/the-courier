extends Node

@export var puffcap_collider: CollisionShape3D

@onready var health: Health = $"../Health"
@onready var death_particle_spawn_point: Marker3D = $"../DeathParticleSpawnPoint"

var death_particles_scene: PackedScene = preload("uid://cwn1qdf23m88y")

func _ready() -> void:
	health.death.connect(_on_death)

func _on_death():
	var death_particles = death_particles_scene.instantiate()
	get_tree().current_scene.add_child(death_particles)
	death_particles.global_position = death_particle_spawn_point.global_position
	
	puffcap_collider.set_deferred("disabled", true)
