extends Hitbox
## Geometry-tested hits go through Hitbox -> Hurtbox -> existing Health.
## No physics overlap callbacks: one attempt per hazard, no duplicate hits.
var keeper: Node3D
var player: Player
var ring := false
var elapsed := 0.0
var warning_time := 1.3
var radius := 1.35
var struck := false
var visual: MeshInstance3D
var material: StandardMaterial3D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	damage = 1
	source = "ember_keeper"
	material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.48, 0.07)
	visual = MeshInstance3D.new()
	visual.material_override = material
	add_child(visual)
	if ring:
		var mesh := TorusMesh.new()
		mesh.inner_radius = 0.86
		mesh.outer_radius = 1.14
		mesh.rings = 48
		mesh.ring_segments = 8
		visual.mesh = mesh
		visual.position.y = 0.2
	else:
		var mesh := CylinderMesh.new()
		mesh.top_radius = radius
		mesh.bottom_radius = radius
		mesh.height = 0.035
		mesh.radial_segments = 24
		visual.mesh = mesh
		visual.position.y = 0.04

func _physics_process(delta: float) -> void:
	if is_queued_for_deletion():
		return
	if not is_instance_valid(keeper) or keeper.is_finished() or not is_instance_valid(player) or player.is_dead:
		queue_free()
		return
	elapsed += delta
	var offset := player.global_position - global_position
	var horizontal := Vector2(offset.x, offset.z).length()
	var contact := false
	if ring:
		var previous_radius := radius
		radius = 2.0 + elapsed * 4.2
		visual.scale = Vector3(radius, 1.0, radius)
		# Swept radial test prevents tunnelling. A jump clears the low wave.
		contact = horizontal >= previous_radius - 0.5 and horizontal <= radius + 0.5 and offset.y < 0.65 and offset.y > -0.5
		if radius > 9.2:
			queue_free()
	else:
		if elapsed < warning_time:
			var pulse := 0.85 + sin(elapsed * 14.0) * 0.1
			visual.scale = Vector3(pulse, 1.0, pulse)
		elif elapsed < warning_time + 0.65:
			visual.scale = Vector3.ONE
			visual.mesh.height = 2.4
			visual.position.y = 1.2
			material.albedo_color = Color(1.0, 0.23, 0.035)
			contact = horizontal < radius + 0.3 and offset.y < 2.4 and offset.y > -0.5
		else:
			keeper.spawn_cinder(global_position)
			queue_free()
	if contact and not struck:
		var hurtbox := player.get_node_or_null("Hurtbox") as Hurtbox
		if hurtbox and hurtbox.health.can_damage and not hurtbox.health.dead:
			struck = true
			register_hit(hurtbox)
