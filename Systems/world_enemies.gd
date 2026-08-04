extends Node

enum EnemyType
{
	Golem,
	Puffcap,
	Snapper
}

var enemy_scenes: Dictionary[EnemyType, PackedScene] = {
	EnemyType.Golem: preload("res://Enemies/Golem/golem_enemy.tscn"),
	EnemyType.Puffcap: preload("res://Enemies/Puffcap/puffcap_enemy.tscn"),
	EnemyType.Snapper: preload("res://Enemies/Snapper/snapper_enemy.tscn")
}

var enemies: Array[Dictionary]

func add_world_enemy(marker: Marker3D, enemy: EnemyType):
	if DataManager.world_started:
		return

	var enemy_data = {
		"type": enemy,
		"position": marker.global_position,
		"rotation": marker.global_rotation,
		"killed": false
	}

	enemies.append(enemy_data)

	return enemies.size() - 1

func spawn_world_enemies(player: Player):
	for i in range(enemies.size()):
		var enemy = enemies[i]
		if enemy["killed"]:
			continue
		
		var enemy_instance: Enemy = enemy_scenes[enemy["type"]].instantiate()
		get_tree().current_scene.add_child(enemy_instance)
		
		enemy_instance.global_position = enemy["position"]
		enemy_instance.global_rotation = enemy["rotation"]
		enemy_instance.target = player

		enemy_instance.health.death.connect(func():
			_on_enemy_death(enemy_instance)
		)

		enemy_instance.index = i


func _on_enemy_death(enemy: Enemy):
	enemies[enemy.index]["killed"] = true
