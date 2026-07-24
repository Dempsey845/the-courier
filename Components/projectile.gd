class_name Projectile
extends Hitbox

@export var speed: float = 10.0
@export var lifetime: float = 5.0


func _ready() -> void:
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

	hit_hurtbox.connect(func(_hurtbox: Hurtbox):
		queue_free()
	)


func _physics_process(delta: float) -> void:
	global_position += global_basis.z * speed * delta