class_name ForestGuardianFruit
extends ForestGuardianProjectile

@onready var input_prompt: InputPrompt = $InputPrompt

var player: Player

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
    
    player.start_holding()

    queue_free()