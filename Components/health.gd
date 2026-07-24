class_name Health
extends Node

signal health_changed
signal damage_taken(damage_amount: int, new_health: int)
signal healed(heal_amount: int, new_health: int)
signal death

@export var max_health: int = 3

var _current_health: int
var current_health: int:
	get():
		return _current_health
	set(value):
		_current_health = value
		health_changed.emit()

var dead: bool

func _ready() -> void:
	_current_health = max_health

func clamp_health():
	_current_health = clamp(_current_health, 0, max_health)

func take_damage(damage: int):
	if dead:
		return

	current_health -= damage
	clamp_health()
	damage_taken.emit(damage, current_health)

	if current_health <= 0:
		dead = true
		death.emit()

func heal(amount: int):
	if dead:
		return
		
	current_health += amount
	clamp_health()
	healed.emit(amount, current_health)