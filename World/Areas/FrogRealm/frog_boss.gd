class_name FrogBoss
extends StaticBody3D

enum State {
	LOOKING_AT_PLAYER,
	ATTACKING,
	ATTACK_COOLDOWN
}

enum AttackType {
	SPIN,
	STRAIGHT_TONGUE
}

@export_category("References")
@export var health: Health
@export var player: Node3D
@export var shield: FrogShield
@export var visual: FrogBossVisual

@export_category("Attack")
@export var attack_range: float = 35.0
@export var look_duration: float = 1.5
@export var attack_cooldown: float = 3.0
@export_range(0.0, 1.0) var straight_tongue_chance: float = 0.4

@export_category("Rotation")
@export var rotation_speed: float = 2.5

@onready var shield_hurtbox: Hurtbox = $ShieldBody/ShieldHurtbox
@onready var shield_shockwave_ring: GPUParticles3D = $ShieldBody/ShieldShockwaveRing

var current_state: State
var current_attack: AttackType
var state_timer: float = 0.0

var shield_active: bool = true


func _ready() -> void:
	rotation.y = 0.0
	
	if is_instance_valid(health):
		health.damage_taken.connect(_on_health_damage_taken)

	if is_instance_valid(visual):
		visual.attack_finished.connect(_on_attack_finished)

	shield_active = true
	raise_shield()

	_change_state(State.LOOKING_AT_PLAYER)

	shield_hurtbox.hit.connect(_on_shield_hurtbox_hit)
	shield_hurtbox.health.death.connect(_on_shield_death)


func _on_attack_finished() -> void:
	if current_state == State.ATTACKING:
		_change_state(State.ATTACK_COOLDOWN)


func _physics_process(delta: float) -> void:
	match current_state:
		State.LOOKING_AT_PLAYER:
			_process_looking_at_player(delta)

		State.ATTACKING:
			_process_attacking(delta)

		State.ATTACK_COOLDOWN:
			_process_attack_cooldown(delta)


func _process_looking_at_player(delta: float) -> void:
	_rotate_towards_player(delta)

	if not _is_player_within_attack_range():
		state_timer = look_duration
		return

	state_timer -= delta

	if state_timer <= 0.0:
		_change_state(State.ATTACKING)


func _process_attacking(_delta: float) -> void:
	pass


func _process_attack_cooldown(delta: float) -> void:
	_rotate_towards_player(delta)

	state_timer -= delta

	if state_timer <= 0.0:
		_change_state(State.LOOKING_AT_PLAYER)


func _change_state(new_state: State) -> void:
	current_state = new_state

	match current_state:
		State.LOOKING_AT_PLAYER:
			state_timer = look_duration

		State.ATTACKING:
			_choose_attack()
			perform_attack()

		State.ATTACK_COOLDOWN:
			state_timer = attack_cooldown


func _choose_attack() -> void:
	if randf() <= straight_tongue_chance:
		current_attack = AttackType.STRAIGHT_TONGUE
	else:
		current_attack = AttackType.SPIN


func perform_attack() -> void:
	if not is_instance_valid(player):
		_change_state(State.ATTACK_COOLDOWN)
		return

	if not is_instance_valid(visual):
		_change_state(State.ATTACK_COOLDOWN)
		return

	match current_attack:
		AttackType.SPIN:
			visual.start_attack(
				_should_spin_left(),
				player
			)

		AttackType.STRAIGHT_TONGUE:
			visual.start_straight_tongue_attack(
				player.global_position
			)

func _rotate_towards_player(delta: float) -> void:
	if not is_instance_valid(player):
		return

	if not is_instance_valid(visual):
		return

	visual.rotate_towards_position(
		player.global_position,
		rotation_speed,
		delta
	)


func _is_player_within_attack_range() -> bool:
	if not is_instance_valid(player):
		return false

	var direction: Vector3 = player.global_position - global_position
	direction.y = 0.0

	return direction.length_squared() <= attack_range * attack_range


func _on_health_damage_taken(
	_damage_amount: int,
	_new_health: int
) -> void:
	pass


func raise_shield() -> void:
	if is_instance_valid(shield):
		shield.show_shield()


func lower_shield() -> void:
	if is_instance_valid(shield):
		shield.hide_shield(_on_shield_lowered)


func _should_spin_left() -> bool:
	if not is_instance_valid(player):
		return true

	if not is_instance_valid(visual):
		return true

	var forward: Vector3 = visual.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var direction_to_player: Vector3 = (
		player.global_position - visual.global_position
	)
	direction_to_player.y = 0.0

	if direction_to_player.length_squared() <= 0.001:
		return true

	direction_to_player = direction_to_player.normalized()

	var angle: float = forward.signed_angle_to(
		direction_to_player,
		Vector3.UP
	)

	return angle > 0.0

func _on_shield_hurtbox_hit(hitbox: Hitbox) -> void:
	var hit_position: Vector3 = hitbox.global_position
	var shield_center: Vector3 = shield.global_position

	var normal: Vector3 = (hit_position - shield_center).normalized()

	var reference_axis: Vector3 = Vector3.UP

	if abs(normal.dot(reference_axis)) > 0.99:
		reference_axis = Vector3.RIGHT

	var x_axis: Vector3 = reference_axis.cross(normal).normalized()
	var z_axis: Vector3 = x_axis.cross(normal).normalized()

	shield_shockwave_ring.global_transform = Transform3D(
		Basis(x_axis, normal, z_axis),
		hit_position
	)

	shield_shockwave_ring.emitting = true

func _on_shield_death():
	lower_shield()

func _on_shield_lowered():
	shield_hurtbox.set_deferred("monitorable", false)
	shield_hurtbox.set_deferred("monitoring", false)