class_name BeamTransitionRect
extends ColorRect

@export var transition_duration: float = 0.65

var transition_material: ShaderMaterial

func _ready() -> void:

	transition_material = (
		material as ShaderMaterial
	)

	transition_material.set_shader_parameter(
		"transition",
		0.0
	)

func change_scene(scene_path: String, transition_from_world: DataManager.WorldType) -> void:
	visible = true

	var cover_tween := create_tween()
	cover_tween.set_trans(Tween.TRANS_QUART)
	cover_tween.set_ease(Tween.EASE_IN_OUT)

	cover_tween.tween_property(
		transition_material,
		"shader_parameter/transition",
		1.0,
		transition_duration
	)

	await cover_tween.finished

	DataManager.change_world(scene_path, transition_from_world)

	# Give the new scene one frame to finish appearing.
	await get_tree().process_frame

	var reveal_tween := create_tween()
	reveal_tween.set_trans(Tween.TRANS_QUART)
	reveal_tween.set_ease(Tween.EASE_IN_OUT)

	reveal_tween.tween_property(
		transition_material,
		"shader_parameter/transition",
		0.0,
		transition_duration
	)

	await reveal_tween.finished

	visible = false
