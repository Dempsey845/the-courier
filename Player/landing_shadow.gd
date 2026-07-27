extends MeshInstance3D

@export var player: Player
@export var raycast: RayCast3D

@export_category("Appearance")
@export var ground_offset: float = 0.02
@export var minimum_scale: float = 0.35
@export var maximum_scale: float = 1.0
@export var maximum_distance: float = 20.0
@export var maximum_distance_transparency: float = 0.75
@export var smoothing_speed: float = 20.0
@export var fade_speed: float = 10.0

var starting_transparency: float
var current_transparency: float

var jump_is_active: bool = false
var jump_was_cut: bool = false


func _ready() -> void:
	top_level = true

	starting_transparency = transparency
	current_transparency = starting_transparency

	player.jump.connect(_on_player_jump)
	player.hit_jump.connect(_on_player_jump)
	player.jump_cut.connect(_on_player_jump_cut)
	player.landed.connect(_on_player_landed)


func _process(delta: float) -> void:
	var is_colliding: bool = raycast.is_colliding()

	# Continue updating the position even while fading out.
	if is_colliding:
		update_shadow_position(delta)

	var target_transparency: float = 1.0

	if (
		is_colliding
		and jump_is_active
		and not jump_was_cut
	):
		target_transparency = get_distance_transparency()

	current_transparency = lerpf(
		current_transparency,
		target_transparency,
		1.0 - exp(-fade_speed * delta)
	)

	transparency = current_transparency
	visible = is_colliding or current_transparency < 0.999


func _on_player_jump() -> void:
	jump_is_active = true
	jump_was_cut = false


func _on_player_jump_cut() -> void:
	jump_was_cut = true


func _on_player_landed() -> void:
	jump_is_active = false
	jump_was_cut = false


func update_shadow_position(delta: float) -> void:
	var collision_point: Vector3 = raycast.get_collision_point()
	var collision_normal: Vector3 = raycast.get_collision_normal()

	var distance: float = player.global_position.distance_to(
		collision_point
	)

	var height_ratio: float = clampf(
		distance / maximum_distance,
		0.0,
		1.0
	)

	var target_position: Vector3 = (
		collision_point
		+ collision_normal * ground_offset
	)

	global_position = global_position.lerp(
		target_position,
		1.0 - exp(-smoothing_speed * delta)
	)

	align_with_surface(collision_normal)

	var target_scale: float = lerpf(
		maximum_scale,
		minimum_scale,
		height_ratio
	)

	scale = Vector3.ONE * target_scale


func get_distance_transparency() -> float:
	var collision_point: Vector3 = raycast.get_collision_point()

	var distance: float = player.global_position.distance_to(
		collision_point
	)

	var height_ratio: float = clampf(
		distance / maximum_distance,
		0.0,
		1.0
	)

	return lerpf(
		starting_transparency,
		maximum_distance_transparency,
		height_ratio
	)


func align_with_surface(normal: Vector3) -> void:
	var forward: Vector3 = Vector3.FORWARD

	if absf(normal.dot(forward)) > 0.99:
		forward = Vector3.RIGHT

	var right: Vector3 = forward.cross(normal).normalized()
	forward = normal.cross(right).normalized()

	global_basis = Basis(
		right,
		normal,
		forward
	).orthonormalized()