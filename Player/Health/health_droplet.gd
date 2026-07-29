class_name HealthDroplet
extends TextureRect

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var fill_hidden: bool

func show_fill():
    if !fill_hidden:
        return

    animation_player.play_backwards("hide")
    fill_hidden = false

func hide_fill():
    if fill_hidden:
        return

    animation_player.play("hide")
    fill_hidden = true