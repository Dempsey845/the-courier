class_name PortalTransitionUI
extends Control

@export var transition_duration: float = 2.0

@onready var portal_material: ShaderMaterial = material

var transition_running: bool = false


func enter_portal(next_scene_path: String) -> void:
	if transition_running:
		return

	if next_scene_path.is_empty():
		push_error(
			"Portal destination path is empty."
		)
		return

	if not ResourceLoader.exists(
		next_scene_path,
		"PackedScene"
	):
		push_error(
			"Portal destination does not exist: %s"
			% next_scene_path
		)
		return

	transition_running = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	show()

	var tween := create_tween()

	tween.tween_method(
		set_portal_transition,
		0.0,
		1.0,
		transition_duration
	).set_trans(
		Tween.TRANS_QUINT
	).set_ease(
		Tween.EASE_OUT
	)

	await tween.finished

	var error := get_tree().change_scene_to_file(
		next_scene_path
	)

	if error != OK:
		transition_running = false

		push_error(
			"Failed to change scene to %s: %s"
			% [
				next_scene_path,
				error_string(error)
			]
		)


func exit_portal() -> void:
	show()

	var tween := create_tween()

	tween.tween_method(
		set_portal_transition,
		1.0,
		0.0,
		transition_duration
	).set_trans(
		Tween.TRANS_QUINT
	).set_ease(
		Tween.EASE_OUT
	)

	await tween.finished

	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()


func set_portal_transition(value: float) -> void:
	portal_material.set_shader_parameter(
		"transition_progress",
		value
	)

func get_portal_transition():
	return material.get_shader_parameter("transition_progress")