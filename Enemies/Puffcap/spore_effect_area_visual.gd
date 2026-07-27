extends MeshInstance3D

const MAX_INTERACTORS: int = 8
const MAX_RIPPLES: int = 8

@export_category("Ripples")
@export var ripple_duration: float = 2.0

var interaction_bodies: Array[Node3D] = []
var ripples: Array[Dictionary] = []

var shader_material: ShaderMaterial

@onready var interaction_area: Area3D = $SporeInteractionArea
@onready var shape: CollisionShape3D = (
	$SporeInteractionArea/CollisionShape3D
)


func _ready() -> void:
	shader_material = get_active_material(0) as ShaderMaterial

	interaction_area.body_entered.connect(
		_on_interaction_body_entered
	)

	interaction_area.body_exited.connect(
		_on_interaction_body_exited
	)

	var size: Vector2 = mesh.get("size")

	shape.shape.set(
		"size",
		Vector3(size.x, 0.6, size.y)
	)

	# Collect bodies that may already be inside without
	# creating entry ripples when the scene first loads.
	for body in interaction_area.get_overlapping_bodies():
		add_interaction_body(body, false)


func _process(delta: float) -> void:
	if not shader_material:
		return

	remove_invalid_interaction_bodies()
	update_ripples(delta)
	update_interaction_shader_parameters()
	update_ripple_shader_parameters()


func remove_invalid_interaction_bodies() -> void:
	for index in range(
		interaction_bodies.size() - 1,
		-1,
		-1
	):
		if not is_instance_valid(
			interaction_bodies[index]
		):
			interaction_bodies.remove_at(index)


func update_interaction_shader_parameters() -> void:
	var local_positions := PackedVector3Array()

	for body in interaction_bodies:
		if local_positions.size() >= MAX_INTERACTORS:
			break

		local_positions.append(
			to_local(body.global_position)
		)

	var interaction_count := local_positions.size()

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


func create_ripple(world_position: Vector3) -> void:
	var local_position := to_local(world_position)

	ripples.append({
		"position": local_position,
		"age": 0.0
	})

	# Remove the oldest ripple when the limit is exceeded.
	if ripples.size() > MAX_RIPPLES:
		ripples.pop_front()


func update_ripples(delta: float) -> void:
	for index in range(ripples.size() - 1, -1, -1):
		ripples[index]["age"] = (
			float(ripples[index]["age"]) + delta
		)

		if ripples[index]["age"] >= ripple_duration:
			ripples.remove_at(index)


func update_ripple_shader_parameters() -> void:
	var ripple_positions := PackedVector3Array()
	var ripple_ages := PackedFloat32Array()

	for ripple in ripples:
		ripple_positions.append(
			ripple["position"] as Vector3
		)

		ripple_ages.append(
			float(ripple["age"])
		)

	var ripple_count := ripple_positions.size()

	# Shader uniform arrays require exactly eight entries.
	while ripple_positions.size() < MAX_RIPPLES:
		ripple_positions.append(Vector3.ZERO)
		ripple_ages.append(ripple_duration)

	shader_material.set_shader_parameter(
		"ripple_count",
		ripple_count
	)

	shader_material.set_shader_parameter(
		"ripple_positions",
		ripple_positions
	)

	shader_material.set_shader_parameter(
		"ripple_ages",
		ripple_ages
	)

	shader_material.set_shader_parameter(
		"ripple_duration",
		ripple_duration
	)


func add_interaction_body(
	body: Node3D,
	create_entry_ripple: bool
) -> void:
	if body in interaction_bodies:
		return

	interaction_bodies.append(body)

	if create_entry_ripple:
		create_ripple(body.global_position)


func _on_interaction_body_entered(body: Node3D) -> void:
	add_interaction_body(body, true)


func _on_interaction_body_exited(body: Node3D) -> void:
	interaction_bodies.erase(body)