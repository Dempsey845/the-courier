extends Node

var collectible_scenes: Dictionary[PlayerItemManager.Item, String] = {
	PlayerItemManager.Item.Mushroom: "res://Systems/Items/mushroom_item_collectible.tscn"
}

var collectibles: Array[Dictionary]

func add_world_collectible(collectible: ItemCollectible, position: Vector3):
	for i in range(collectibles.size()):
		var data = collectibles[i]
		if data["position"] == position:
			return i

	var collectible_data = {
		"type": collectible.item,
		"position": position,
		"collected": false
	}

	collectibles.append(collectible_data)

	return collectibles.size() - 1

func spawn_world_collectibles():
	for collectible_data in collectibles:
		if collectible_data["collected"]:
			continue

		var collectible_scene: PackedScene = load(collectible_scenes[collectible_data["type"]])
		var item_collectible: ItemCollectible = collectible_scene.instantiate()

		get_tree().current_scene.add_child(item_collectible)

		item_collectible.global_position = collectible_data["position"]