class_name Portal
extends MeshInstance3D

signal portal_entered

@export var shown: bool

func open_portal():
	var tween: Tween = create_tween()

	tween.tween_method(
		func(value: float):
			material_override.set_shader_parameter("transition_progress", value),
		0.0,
		1.0,
		0.8
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	shown = true

func close_portal():
	var tween: Tween = create_tween()

	tween.tween_method(
		func(value: float):
			material_override.set_shader_parameter("transition_progress", value),
		1.0,
		0.0,
		0.6
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	shown = false

func play_enter_feedback() -> void:
	set_instance_shader_parameter(
		"interaction_progress",
		0.0
	)

	portal_entered.emit()

	var tween: Tween = create_tween()

	tween.tween_method(
		func(value: float) -> void:
			set_instance_shader_parameter(
				"interaction_progress",
				value
			),
		0.0,
		1.0,
		0.45
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

