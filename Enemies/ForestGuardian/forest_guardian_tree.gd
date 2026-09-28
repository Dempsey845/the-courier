class_name ForestGuardianTree
extends StaticBody3D

@onready var tree: MeshInstance3D = %Tree
@onready var face_animation_player: AnimationPlayer = %FaceAnimationPlayer

var leaf_material: ShaderMaterial
var rustle_tween: Tween


func _ready() -> void:
	leaf_material = tree.get_surface_override_material(1).duplicate() as ShaderMaterial
	tree.set_surface_override_material(1, leaf_material) 


func trigger_rustle() -> void:
	if rustle_tween and rustle_tween.is_running():
		rustle_tween.kill()

	rustle_tween = create_tween()
	rustle_tween.tween_method(_set_rustle_strength, 0.35, 0.2, 0.12)
	rustle_tween.tween_method(_set_rustle_strength, 0.2, 0.0, 0.7)


func _set_rustle_strength(value: float) -> void:
	leaf_material.set_shader_parameter("rustle_strength", value)

func start_puff():
	face_animation_player.play("start_puff")
	
func end_puff():
	face_animation_player.play_backwards("start_puff")

func puff():
	face_animation_player.play("puff")
