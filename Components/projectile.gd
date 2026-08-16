class_name Projectile
extends Hitbox

@export var speed: float = 10.0
@export var lifetime: float = 5.0
@export var explosion_effect_scene: PackedScene


func _ready() -> void:
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

	hit_hurtbox.connect(func(_hurtbox: Hurtbox):
		if explosion_effect_scene:
			var explosion_effect = explosion_effect_scene.instantiate()
			get_parent().add_child(explosion_effect)
			explosion_effect.global_position = global_position
			explosion_effect.global_rotation = global_rotation
			
		queue_free()
	)


func _physics_process(delta: float) -> void:
	global_position += global_basis.z * speed * delta