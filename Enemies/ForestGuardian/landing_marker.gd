class_name LandingMarker
extends MeshInstance3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func despawn():
    animation_player.play("despawn")

    await animation_player.animation_finished

    queue_free()