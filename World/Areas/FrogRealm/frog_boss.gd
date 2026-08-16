class_name FrogBoss
extends StaticBody3D

enum State {
	IDLE,
	LOOKING_AT_PLAYER,
	ATTACKING,
	ATTACK_COOLDOWN,
	DEAD
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
@export var spring_platforms_owner: Node3D

@export_category("Encounter")
@export var start_range: float = 45.0

@export_category("Attack")
@export var attack_range: float = 35.0
@export var look_duration: float = 1.5
@export var attack_cooldown: float = 3.0
@export_range(0.0, 1.0) var straight_tongue_chance: float = 0.4

@export_category("Rotation")
@export var rotation_speed: float = 2.5

@onready var shield_hurtbox: Hurtbox = %ShieldBody/ShieldHurtbox
@onready var shield_shockwave_ring: GPUParticles3D = (
	%ShieldBody/ShieldShockwaveRing
)
@onready var shield_body: StaticBody3D = %ShieldBody
@onready var frog_boss_ui: FrogBossUI = $FrogBossUI
@onready var frog_boss_hurtbox: Area3D = $FrogBossHurtbox

var current_state: State = State.IDLE
var current_attack: AttackType
var state_timer: float = 0.0

var shield_active: bool = true
var encounter_started: bool = false


func _ready() -> void:
	rotation.y = 0.0

	if is_instance_valid(health):
		health.damage_taken.connect(_on_health_damage_taken)
		health.death.connect(_on_health_death)

	if is_instance_valid(visual):
		visual.attack_finished.connect(_on_attack_finished)

	shield_active = true

	shield_hurtbox.hit.connect(_on_shield_hurtbox_hit)
	shield_hurtbox.health.death.connect(_on_shield_death)

	_change_state(State.IDLE)


func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE:
			_process_idle()

		State.LOOKING_AT_PLAYER:
			_process_looking_at_player(delta)

		State.ATTACKING:
			_process_attacking(delta)

		State.ATTACK_COOLDOWN:
			_process_attack_cooldown(delta)

		State.DEAD:
			_process_dead()


func _process_idle() -> void:
	if encounter_started:
		return

	if _is_player_within_range(start_range):
		_start_encounter()


func _start_encounter() -> void:
	if encounter_started or current_state == State.DEAD:
		return

	encounter_started = true

	if is_instance_valid(frog_boss_ui):
		frog_boss_ui.show_boss_ui()

	raise_shield()
	_change_state(State.LOOKING_AT_PLAYER)


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


func _process_dead() -> void:
	pass


func _change_state(new_state: State) -> void:
	if current_state == State.DEAD and new_state != State.DEAD:
		return

	current_state = new_state

	match current_state:
		State.IDLE:
			state_timer = 0.0

		State.LOOKING_AT_PLAYER:
			state_timer = look_duration

		State.ATTACKING:
			_choose_attack()
			perform_attack()

		State.ATTACK_COOLDOWN:
			state_timer = attack_cooldown

		State.DEAD:
			_enter_death_state()


func _enter_death_state() -> void:
	state_timer = 0.0

	if is_instance_valid(visual):
		visual._retract_tongue()

		if is_instance_valid(visual.tongue_hitbox):
			visual.tongue_hitbox.active = false

			visual.die()

	if is_instance_valid(shield_hurtbox):
		shield_hurtbox.set_deferred("monitoring", false)
		shield_hurtbox.set_deferred("monitorable", false)

	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	frog_boss_hurtbox.set_deferred("monitoring", false)
	frog_boss_hurtbox.set_deferred("monitorable", false)


func _choose_attack() -> void:
	if randf() <= straight_tongue_chance:
		current_attack = AttackType.STRAIGHT_TONGUE
	else:
		current_attack = AttackType.SPIN


func perform_attack() -> void:
	if current_state == State.DEAD:
		return

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
	if current_state == State.DEAD:
		return

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
	return _is_player_within_range(attack_range)


func _is_player_within_range(distance: float) -> bool:
	if not is_instance_valid(player):
		return false

	var direction: Vector3 = (
		player.global_position - global_position
	)
	direction.y = 0.0

	return direction.length_squared() <= distance * distance


func _on_attack_finished() -> void:
	if current_state == State.ATTACKING:
		_change_state(State.ATTACK_COOLDOWN)


func _on_health_damage_taken(
	_damage_amount: int,
	_new_health: int
) -> void:
	pass


func _on_health_death() -> void:
	_change_state(State.DEAD)


func raise_shield() -> void:
	if current_state == State.DEAD:
		return

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
	if current_state == State.DEAD:
		return

	var hit_position: Vector3 = hitbox.global_position
	var shield_center: Vector3 = shield.global_position
	var normal := (hit_position - shield_center).normalized()

	var reference_axis := Vector3.UP

	if abs(normal.dot(reference_axis)) > 0.99:
		reference_axis = Vector3.RIGHT

	var x_axis := reference_axis.cross(normal).normalized()
	var z_axis := x_axis.cross(normal).normalized()

	shield_shockwave_ring.global_transform = Transform3D(
		Basis(x_axis, normal, z_axis),
		hit_position
	)

	shield_shockwave_ring.emitting = true


func _on_shield_death() -> void:
	if current_state == State.DEAD:
		return

	lower_shield()


func _on_shield_lowered() -> void:
	if is_instance_valid(shield_body):
		shield_body.queue_free.call_deferred()

	if not is_instance_valid(spring_platforms_owner):
		return

	for spring_platform: Node3D in spring_platforms_owner.get_children():
		if spring_platform is SpringPlatform:
			spring_platform.introduce()