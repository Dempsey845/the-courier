class_name FrogShield
extends MeshInstance3D

@export var transition_duration: float = 1.5

@onready var shield_material: ShaderMaterial = \
	get_active_material(0) as ShaderMaterial


func show_shield() -> void:
	var tween := create_tween()

	tween.tween_method(
		_set_shield_transition,
		0.0,
		1.0,
		transition_duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func hide_shield() -> void:
	var tween := create_tween()

	tween.tween_method(
		_set_shield_transition,
		1.0,
		0.0,
		transition_duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _set_shield_transition(value: float) -> void:
	shield_material.set_shader_parameter("transition", value)