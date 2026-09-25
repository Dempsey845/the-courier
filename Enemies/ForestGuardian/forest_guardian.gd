class_name ForestGuardian
extends Node3D

signal health_changed(current_health: int, max_health: int)
signal phase_changed(phase: int)
signal defeated

enum State {
	INACTIVE,
	IDLE,
	TELEGRAPH,
	ATTACK,
	RECOVERY,
	PHASE_TRANSITION,
	DEAD
}

enum Attack {
	FRUIT_DROP,
	AIR_PUFF,
	ROOT_STRIKE
}

@export var max_health := 100
@export var idle_duration := 1.5
@export var telegraph_duration := 0.8
@export var attack_duration := 1.2
@export var recovery_duration := 1.0
@export var phase_transition_duration := 2.0

var health: int
var phase := 1
var state := State.INACTIVE
var current_attack := Attack.FRUIT_DROP

var state_time := 0.0
var attack_index := 0


func _ready() -> void:
	health = max_health


func _process(delta: float) -> void:
	if state == State.INACTIVE or state == State.DEAD:
		return

	state_time -= delta

	if state_time > 0.0:
		return

	match state:
		State.IDLE:
			current_attack = _choose_next_attack()
			_change_state(State.TELEGRAPH)

		State.TELEGRAPH:
			_change_state(State.ATTACK)

		State.ATTACK:
			_change_state(State.RECOVERY)

		State.RECOVERY:
			_change_state(State.IDLE)

		State.PHASE_TRANSITION:
			_change_state(State.IDLE)


func start_battle() -> void:
	if state != State.INACTIVE:
		return

	_change_state(State.IDLE)


func take_damage(amount: int) -> void:
	if amount <= 0 or state == State.INACTIVE or state == State.DEAD:
		return

	health = max(health - amount, 0)
	health_changed.emit(health, max_health)

	if health == 0:
		_change_state(State.DEAD)
	elif phase == 1 and health <= max_health * 0.5:
		phase = 2
		attack_index = 0
		phase_changed.emit(phase)
		_change_state(State.PHASE_TRANSITION)


func _choose_next_attack() -> Attack:
	var attacks: Array[Attack]

	if phase == 1:
		attacks = [Attack.FRUIT_DROP, Attack.AIR_PUFF]
	else:
		attacks = [Attack.ROOT_STRIKE, Attack.FRUIT_DROP, Attack.AIR_PUFF]

	var chosen_attack := attacks[attack_index % attacks.size()]
	attack_index += 1
	return chosen_attack


func _change_state(new_state: State) -> void:
	state = new_state

	match state:
		State.IDLE:
			state_time = idle_duration

		State.TELEGRAPH:
			state_time = telegraph_duration
			_telegraph_attack(current_attack)

		State.ATTACK:
			state_time = attack_duration
			_perform_attack(current_attack)

		State.RECOVERY:
			state_time = recovery_duration

		State.PHASE_TRANSITION:
			state_time = phase_transition_duration
			_on_phase_two_started()

		State.DEAD:
			defeated.emit()
			_on_defeated()


func _telegraph_attack(_attack: Attack) -> void:
	pass


func _perform_attack(attack: Attack) -> void:
	match attack:
		Attack.FRUIT_DROP:
			_attack_fruit_drop()

		Attack.AIR_PUFF:
			_attack_air_puff()

		Attack.ROOT_STRIKE:
			_attack_root_strike()


func _attack_fruit_drop() -> void:
	pass


func _attack_air_puff() -> void:
	pass


func _attack_root_strike() -> void:
	pass


func _on_phase_two_started() -> void:
	pass


func _on_defeated() -> void:
	pass