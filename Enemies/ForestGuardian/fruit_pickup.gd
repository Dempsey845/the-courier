extends Hitbox

@export var throw_speed: float = 12.0
@export var throw_arc_height: float = 2.0

var is_being_thrown: bool = false
var current_target: Node3D

var throw_start: Vector3
var throw_duration: float
var throw_elapsed: float = 0.0


func _ready() -> void:
	hit_hurtbox.connect(_on_hit_hurtbox)


func _process(delta: float) -> void:
	if not is_being_thrown:
		return

	if not is_instance_valid(current_target):
		queue_free()
		return

	throw_elapsed += delta
	var progress := minf(throw_elapsed / throw_duration, 1.0)
	var destination := current_target.global_position

	global_position = throw_start.lerp(destination, progress)
	global_position.y += sin(progress * PI) * throw_arc_height

	if progress >= 1.0:
		queue_free()


func throw_pickup() -> void:
	if not is_instance_valid(current_target):
		queue_free()
		return

	var previous_global_transform := global_transform
	reparent(get_tree().current_scene)
	global_transform = previous_global_transform

	throw_start = global_position
	throw_elapsed = 0.0
	throw_duration = maxf(
		throw_start.distance_to(current_target.global_position) / maxf(throw_speed, 0.01),
		0.01
	)

	is_being_thrown = true


func _on_hit_hurtbox(_hurtbox: Hurtbox) -> void:
	queue_free()