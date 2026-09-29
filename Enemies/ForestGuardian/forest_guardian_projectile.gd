class_name ForestGuardianProjectile
extends Hitbox

@onready var hitbox: CollisionShape3D = $CollisionShape3D

@export var destroy_on_land: bool = true
@export var hit_effect_scene: PackedScene

var velocity := Vector3.ZERO
var grav := 0.0
var lifetime := 5.0
var ground_y := -INF


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func setup(attack_damage: int) -> void:
	damage = attack_damage


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	if not active:
		return

	velocity.y -= grav * delta
	global_position += velocity * delta


func _spawn_hit_effect():
	if !hit_effect_scene:
		return

	var hit_effect = hit_effect_scene.instantiate()
	get_tree().current_scene.add_child(hit_effect)
	hit_effect.global_position = global_position
	queue_free()

func _on_area_entered(area: Area3D) -> void:
	if not active or not area is Hurtbox:
		return
	var hurtbox := area as Hurtbox
	if hurtbox.just_hit:
		return
	if register_hit(hurtbox):
		active = false
		_spawn_hit_effect()
		queue_free()

func _on_body_entered(body: Node3D):
	if body is Player or body is Enemy or body is ForestGuardian:
		return
	
	active = false

	if destroy_on_land:
		_spawn_hit_effect()
		queue_free()
	else:
		on_landed()

func on_landed():
	pass
