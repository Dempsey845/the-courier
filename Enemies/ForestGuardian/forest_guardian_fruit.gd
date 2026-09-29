class_name ForestGuardianFruit
extends ForestGuardianProjectile

@onready var input_prompt: InputPrompt = $InputPrompt

var player: Player
var guardian: ForestGuardian

var fruit_scene: PackedScene = preload("uid://bl4h4eaj6vlr5")

var landed: bool = false

func _ready() -> void:
	super._ready()

	player = get_tree().current_scene.player

	input_prompt.pressed.connect(_on_input_prompt_pressed)

	player.hold_started.connect(_on_player_hold_started)

	player.drop_attempt.connect(_on_player_drop_attempt)
	player.throw_successful.connect(_on_player_throw_successful)

func on_landed():
	input_prompt.set_deferred("monitoring", true)
	await get_tree().process_frame
	landed = true

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

func _on_player_hold_started(_hold_object):
	input_prompt.can_be_shown = false

func _try_show_prompt():
	var can_be_shown = !player.is_dead and !player.is_holding and landed
	if can_be_shown:
		input_prompt.set_deferred("monitoring", true)
		await get_tree().process_frame
		input_prompt.can_be_shown = !player.is_dead and !player.is_holding

func _on_player_drop_attempt():
	_try_show_prompt()

func _on_player_throw_successful():
	_try_show_prompt()