extends MeshInstance3D

const MAX_INTERACTORS: int = 8

var interaction_bodies: Array[Node3D] = []
var shader_material: ShaderMaterial

@onready var interaction_area: Area3D = $SporeInteractionArea
@onready var shape: CollisionShape3D = $SporeInteractionArea/CollisionShape3D

func _ready() -> void:
	shader_material = get_active_material(0)

	interaction_area.body_entered.connect(
		_on_interaction_body_entered
	)

	interaction_area.body_exited.connect(
		_on_interaction_body_exited
	)

	var size: Vector2 = mesh.get("size")

	shape.shape.set("size", Vector3(size.x, 0.6, size.y))

	# Collect bodies that may already be inside the area.
	for body in interaction_area.get_overlapping_bodies():
		_on_interaction_body_entered(body)


func _process(_delta: float) -> void:
	if not shader_material:
		print("No mat")
		return

	# Remove bodies that have been deleted.
	for index in range(interaction_bodies.size() - 1, -1, -1):
		if not is_instance_valid(interaction_bodies[index]):
			interaction_bodies.remove_at(index)

	var local_positions := PackedVector3Array()

	for body in interaction_bodies:
		if local_positions.size() >= MAX_INTERACTORS:
			break

		local_positions.append(
			to_local(body.global_position)
		)

	# Store the real count before padding the shader array.
	var interaction_count := local_positions.size()

	# The shader expects an array containing exactly eight values.
	while local_positions.size() < MAX_INTERACTORS:
		local_positions.append(Vector3.ZERO)

	shader_material.set_shader_parameter(
		"interaction_count",
		interaction_count
	)

	shader_material.set_shader_parameter(
		"interaction_positions",
		local_positions
	)


func _on_interaction_body_entered(body: Node3D) -> void:
	if body in interaction_bodies:
		return

	interaction_bodies.append(body)


func _on_interaction_body_exited(body: Node3D) -> void:
	interaction_bodies.erase(body)