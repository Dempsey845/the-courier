class_name ForestGuardianFruit
extends ForestGuardianProjectile

@onready var input_prompt: InputPrompt = $InputPrompt

var player: Player
var guardian: ForestGuardian

var fruit_scene: PackedScene = preload("uid://bl4h4eaj6vlr5")

func _ready() -> void:
	super._ready()

	player = get_tree().current_scene.player

	input_prompt.pressed.connect(_on_input_prompt_pressed)

func on_landed():
	input_prompt.set_deferred("monitoring", true)

func _on_input_prompt_pressed():
	if !is_instance_valid(player):
		return
	
	if player.is_holding:
		return
	
	var fruit_pickup: Node3D = fruit_scene.instantiate()
	fruit_pickup.current_target = guardian

	get_tree().current_scene.add_child(fruit_pickup)

	player.start_holding(fruit_pickup)

	queue_free()
