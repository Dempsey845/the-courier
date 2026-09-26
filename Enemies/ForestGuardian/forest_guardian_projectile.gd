class_name ForestGuardianProjectile
extends Hitbox

@onready var visual: MeshInstance3D = $Visual
@onready var hitbox: CollisionShape3D = $CollisionShape3D

@export var destroy_on_land: bool = true

var velocity := Vector3.ZERO
var grav := 0.0
var lifetime := 5.0
var radius := 0.45
var ground_y := -INF


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func setup(size: float, attack_damage: int) -> void:
	radius = size
	damage = attack_damage

	var sphere := visual.mesh.duplicate() as SphereMesh
	sphere.radius = size
	sphere.height = size * 2.0
	visual.mesh = sphere
	
	var shape := hitbox.shape.duplicate() as SphereShape3D
	shape.radius = size
	hitbox.shape = shape


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	if not active:
		return

	velocity.y -= grav * delta
	global_position += velocity * delta


func _on_area_entered(area: Area3D) -> void:
	if not active or not area is Hurtbox:
		return
	var hurtbox := area as Hurtbox
	if hurtbox.just_hit:
		return
	if register_hit(hurtbox):
		active = false
		queue_free()

func _on_body_entered(body: Node3D):
	if body is Player or body is Enemy:
		return
	
	active = false

	if destroy_on_land:
		queue_free()
	else:
		on_landed()

func on_landed():
	pass