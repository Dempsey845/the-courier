class_name ForestGuardianFruit
extends ForestGuardianProjectile

@onready var input_prompt: InputPrompt = $InputPrompt

func on_landed():
    input_prompt.set_deferred("monitoring", true)