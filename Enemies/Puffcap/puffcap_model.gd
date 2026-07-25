extends Node3D

@onready var puffcap_spore_effect: CPUParticles3D = $PuffcapSporeEffect
@onready var puffcap_release_spore_effect: CPUParticles3D = $PuffcapReleaseSporeEffect
@onready var animation_player: AnimationPlayer = $EffectAreaVisual/AnimationPlayer

func release_spores():
    animation_player.play("show")
    puffcap_release_spore_effect.emitting = true
    puffcap_spore_effect.emitting = true
    await puffcap_spore_effect.finished
    animation_player.play_backwards("show")
