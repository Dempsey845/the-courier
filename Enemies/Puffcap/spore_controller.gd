class_name SporeController
extends Node

@onready var spore_hitbox: Hitbox = get_parent()
@onready var timer: Timer = $'../Timer'

func _ready() -> void:
	timer.timeout.connect(func():
		spore_hitbox.force_hit_update()
	)

func start_tick_damage():
	timer.start()
	spore_hitbox.active = true

func stop_tick_damage():
	timer.stop()
	spore_hitbox.active = false
