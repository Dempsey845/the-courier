class_name RuneBeam
extends MeshInstance3D

@export var input_prompt: InputPrompt

@onready var beam_material: ShaderMaterial = material_override

var beam_started: bool

func _ready() -> void:
	input_prompt.pressed.connect(_on_input_prompt_pressed)

func start_beam_transition():
	if beam_started:
		return
	
	beam_started = true

	beam_material.set_shader_parameter("transition", 0.0)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		beam_material,
		"shader_parameter/transition",
		1.0,
		1.5
	)

	input_prompt.can_be_shown = false

	await tween.finished

	BeamTransitionCanvasLayer.start_transition("res://World/world.tscn", DataManager.WorldType.Dungeon)

func _on_input_prompt_pressed():
	start_beam_transition()
