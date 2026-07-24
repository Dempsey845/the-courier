extends Node3D

@onready var puffcap_spore_effect: CPUParticles3D = $PuffcapSporeEffect
@onready var puffcap_release_spore_effect: CPUParticles3D = $PuffcapReleaseSporeEffect

func release_spores():
    print("Released")
    puffcap_release_spore_effect.emitting = true
    puffcap_spore_effect.emitting = true