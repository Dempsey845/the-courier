class_name FireParticles
extends Node3D

@onready var flames: GPUParticles3D = $Flames
@onready var smoke: GPUParticles3D = $Smoke
@onready var fire_light: OmniLight3D = $FireLight

var base_fire_light_energy: float

func _ready() -> void:
    base_fire_light_energy = fire_light.light_energy
    fire_light.light_energy = 0.0

func enable_fire():
    fire_light.light_energy = base_fire_light_energy
    flames.emitting = true
    smoke.emitting = true