extends Node3D

@onready var mushroom_gas_effect: CPUParticles3D = $MushroomGas
@onready var puffcap_release_spore_effect: CPUParticles3D = $PuffcapReleaseSporeEffect

func release_spores():
	puffcap_release_spore_effect.emitting = true
	mushroom_gas_effect.emitting = true
	await mushroom_gas_effect.finished
