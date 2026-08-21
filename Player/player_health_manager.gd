class_name PlayerHealthManager
extends Node

signal protection_started
signal protection_ended

@export var health: Health

@onready var protection_timer: Timer = $ProtectionTimer

func _ready() -> void:
	health.damage_taken.connect(_on_damage_taken)

	protection_timer.timeout.connect(func():
		health.can_damage = true
		protection_ended.emit()
	)

	health.death.connect(func():
		get_parent().stop_moving()
	)

func _on_damage_taken(_damage_amount, _new_health):
	health.can_damage = false
	protection_timer.start()
	protection_started.emit()
