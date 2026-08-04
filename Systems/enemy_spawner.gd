class_name EnemySpawner
extends Marker3D

@export var enemy_type: WorldEnemies.EnemyType

func _ready() -> void:
    WorldEnemies.add_world_enemy(self, enemy_type)