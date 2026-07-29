class_name SporeHitbox
extends Hitbox

@export var start_delay: float = 0.5


@onready var spore_controller: SporeController = $SporeController

func _ready() -> void:
    var enemy: Enemy = get_parent()

    enemy.attacked.connect(func(_target: Node3D):
        await get_tree().create_timer(start_delay).timeout
        spore_controller.start_tick_damage()
        await get_tree().create_timer(enemy.attack_cooldown - start_delay).timeout
        spore_controller.stop_tick_damage()
    )
