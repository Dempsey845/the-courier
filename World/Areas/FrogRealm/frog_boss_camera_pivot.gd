extends Marker3D

@export var player: Player

@export_category("Rotation")
@export var rotation_speed: float = 5.0

@export_category("Camera Distance")
@export var too_close_distance: float = 10.0
@export var too_far_distance: float = 25.0
@export var camera_move_speed: float = 8.0

const FAR_CAMERA_Z: float = 30.0
const IDLE_CAMERA_Z: float = 40.0
const CLOSE_CAMERA_Z: float = 45.0

@onready var camera: Camera3D = $Camera3D

var starting_camera_z: float


func _ready() -> void:
	starting_camera_z = camera.position.z


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	_rotate_towards_player(delta)
	_update_camera_distance(delta)


func _rotate_towards_player(delta: float) -> void:
	var direction := player.global_position - global_position
	direction.y = 0.0

	if direction.length_squared() <= 0.0001:
		return

	var target_y_rotation := atan2(direction.x, direction.z)

	global_rotation.y = lerp_angle(
		global_rotation.y,
		target_y_rotation,
		rotation_speed * delta
	)


func _update_camera_distance(delta: float) -> void:
	var player_distance := camera.global_position.distance_to(
		player.global_position
	)

	var target_camera_z := IDLE_CAMERA_Z

	if player_distance > too_far_distance:
		target_camera_z = FAR_CAMERA_Z

	elif player_distance < too_close_distance:
		target_camera_z = CLOSE_CAMERA_Z

	camera.position.z = move_toward(
		camera.position.z,
		target_camera_z,
		camera_move_speed * delta
	)