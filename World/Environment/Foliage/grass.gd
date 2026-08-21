extends Node3D

@onready var player: Player = get_tree().current_scene.player
@onready var grass: MeshInstance3D = $Grass2/Grass

var grass_material: ShaderMaterial


func _ready() -> void:
	var active_material := grass.get_active_material(0)

	if active_material is not ShaderMaterial:
		push_error("Grass does not have a ShaderMaterial.")
		return

	grass_material = active_material.duplicate() as ShaderMaterial
	grass.set_surface_override_material(0, grass_material)


func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return

	if not is_instance_valid(grass_material):
		return

	var local_player_position := grass.to_local(
		player.global_position
	)

	grass_material.set_shader_parameter(
		"player_position",
		local_player_position
	)