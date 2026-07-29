class_name ProtectionVisual
extends MeshInstance3D

@export var player_model: Node3D

var protection_material: ShaderMaterial

var protection_tween: Tween

var health_manager: PlayerHealthManager

func _ready() -> void:
	protection_material = material_overlay

	health_manager = player_model.player.get_node("PlayerHealthManager")

	health_manager.protection_started.connect(show_protection)
	health_manager.protection_ended.connect(hide_protection)

func show_protection() -> void:
	if protection_tween:
		protection_tween.kill()

	protection_material.set_shader_parameter("progress", 0.0)

	protection_tween = create_tween()
	protection_tween.set_trans(Tween.TRANS_QUAD)
	protection_tween.set_ease(Tween.EASE_OUT)

	protection_tween.tween_method(
		set_protection_progress,
		0.0,
		1.0,
		0.25
	)


func hide_protection() -> void:
	if protection_tween:
		protection_tween.kill()

	var current_progress: float = protection_material.get_shader_parameter(
		"progress"
	)

	protection_tween = create_tween()
	protection_tween.set_trans(Tween.TRANS_QUAD)
	protection_tween.set_ease(Tween.EASE_IN)

	protection_tween.tween_method(
		set_protection_progress,
		current_progress,
		0.0,
		0.3
	)


func set_protection_progress(value: float) -> void:
	protection_material.set_shader_parameter("progress", value)
