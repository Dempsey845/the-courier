extends Node

@onready var fps_label: Label = %FPSLabel

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("reload"):
		get_tree().reload_current_scene()
		
	fps_label.text = str(Engine.get_frames_per_second())
