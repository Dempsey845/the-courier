class_name PlayerItemManager
extends Node

enum Item {
	Mushroom,
}

@export var item_spacing_x: float = 0.8
@export var bubble_move_duration: float = 0.2
@export var item_to_texture: Dictionary[Item, CompressedTexture2D]

@onready var bubble_point: Marker3D = %BubblePoint

var current_items: Dictionary[Item, int] = {}

var current_bubbles: Dictionary[Item, ItemBubble] = {}

var bubble_order: Array[ItemBubble] = []

var item_bubble_scene: PackedScene = preload("uid://bxgl2yh2tglip")

func _ready() -> void:
	await get_tree().process_frame
	for item in DataManager.player_items:
		var quantity = DataManager.player_items[item]
		for i in range(quantity):
			add_item(item, false)

func add_item(item: Item, play_add_animation: bool = true) -> void:
	if item in current_items:
		current_items[item] += 1
		current_bubbles[item].add(play_add_animation)
		if !play_add_animation:
			current_bubbles[item].update_quantity_label()
		return

	await _make_space_for_new_bubble()

	var item_bubble: ItemBubble = item_bubble_scene.instantiate()
	if item in item_to_texture:
		item_bubble.texture = item_to_texture[item]
	bubble_point.add_child(item_bubble)

	item_bubble.position = _get_new_bubble_position()
	item_bubble.show_bubble()

	current_items[item] = 1
	current_bubbles[item] = item_bubble
	bubble_order.append(item_bubble)

func remove_item(item: Item, amount: int) -> void:
	if item not in current_bubbles:
		return

	var bubble: ItemBubble = current_bubbles[item]

	await bubble.remove(amount)

	current_items[item] = max(
		current_items.get(item, 0) - amount,
		0
	)

	if bubble.quantity <= 0:
		current_bubbles.erase(item)
		current_items.erase(item)

		bubble.queue_free()

		# Prevent the deleted bubble from affecting the layout.
		await get_tree().process_frame

		await resort_bubbles()

func _make_space_for_new_bubble() -> void:
	var new_bubble_count: int = bubble_order.size() + 1

	if new_bubble_count % 2 != 0:
		return

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)

	for bubble in bubble_order:
		tween.tween_property(
			bubble,
			"position:x",
			bubble.position.x - item_spacing_x,
			bubble_move_duration
		)

	await tween.finished


func _get_new_bubble_position() -> Vector3:
	var existing_count: int = bubble_order.size()
	var slot_index: int = existing_count / 2

	return Vector3(
		float(slot_index) * item_spacing_x,
		0.0,
		0.0
	)

func resort_bubbles() -> void:
	var bubbles: Array[ItemBubble] = []

	for bubble: ItemBubble in current_bubbles.values():
		if is_instance_valid(bubble):
			bubbles.append(bubble)

	var start_x: float = -floori(bubbles.size() / 2.0) * item_spacing_x

	var movement_tweens: Array[Tween] = []

	for index: int in bubbles.size():
		var bubble: ItemBubble = bubbles[index]
		var target_position := Vector3(
			start_x + index * item_spacing_x,
			0.0,
			0.0
		)

		var tween := create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(
			bubble,
			"position",
			target_position,
			0.25
		)

		movement_tweens.append(tween)

	for tween: Tween in movement_tweens:
		await tween.finished

func _exit_tree() -> void:
	DataManager.player_items.clear()
	DataManager.player_items = current_items.duplicate()
