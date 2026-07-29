extends Control

@export var health: Health
@export var droplets: Array[HealthDroplet]

var current_droplets_filled: int = 3

func _ready() -> void:
    health.damage_taken.connect(_on_damage_taken)

func _on_damage_taken(damage_amount: int, new_health: int):
    if damage_amount > 1:
        push_warning("Player should not be damaged more then 1 point!")
        
    if new_health < current_droplets_filled:
        droplets[current_droplets_filled - 1].hide_fill()
        current_droplets_filled = new_health

func _on_healed():
    pass