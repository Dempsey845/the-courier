class_name ItemBubble
extends Node3D

@export var texture: CompressedTexture2D
@export var quantity: int = 1

@onready var texture_quad: MeshInstance3D = $TextureQuad
@onready var quantity_label: Label3D = $Label3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	texture_quad.material_override.set("albedo_texture", texture)
	update_quantity_label()

func show_bubble():
	animation_player.play("pop_in")

func hide_bubble():
	animation_player.play_backwards("pop_in")
	
func add(play_animation: bool = true):
	quantity += 1
	if play_animation:
		animation_player.play("add")

func remove(amount: int):
	if quantity - amount <= 0:
		animation_player.play_backwards("pop_in")
	else:
		animation_player.play("add")

	quantity -= amount
	quantity = max(0, quantity)

	await get_tree().create_timer(1.5).timeout

func update_quantity_label():
	quantity_label.text = "x" + str(quantity)
