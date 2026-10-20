extends Node3D

signal defeated
signal health_changed(current: int, maximum: int)
signal battle_started

const CINDER := preload("res://Enemies/EmberKeeper/ember_cinder.tscn")
const HAZARD := preload("res://Enemies/EmberKeeper/ember_hazard.gd")
const HEART := preload("res://Player/Health/health_pickup.tscn")

enum State { DORMANT, INTRO, ERUPTION, WINDUP, WAVE, VENT, HIT, TRANSITION, DEAD, FAILED }

@export var arena_radius := 7.0
@export var vent_duration := 10.0
@export var camera_distance := 9.0
@export var camera_height := 7.0

var state := State.DORMANT
var remaining := 0.0
var phase := 1
var player: Player
var animation: AnimationPlayer
var cinders: Array[Node3D] = []
var supplies: Array[Node3D] = []
var retry_delay := 0.0

@onready var health: Health = $Hurtbox/Health
@onready var camera: Camera3D = $BossCamera
@onready var hint: Label = $HUD/Panel/Margin/Rows/Hint
@onready var bar: ProgressBar = $HUD/Panel/Margin/Rows/HealthBar

func _ready() -> void:
	animation = $Visual.find_child("AnimationPlayer", true, false) as AnimationPlayer

	_loop_clip("Idle")
	_loop_clip("Vent")
	_play("Idle")

	health.can_damage = false
	health.damage_taken.connect(_on_damage)

	$ArenaArea.body_entered.connect(_on_enter)
	$HUD/Panel.hide()
	$HUD/Retry.hide()
	$HUD/Retry.pressed.connect(_retry)

	camera.top_level = true
	_check_overlap.call_deferred()

func _check_overlap() -> void:
	await get_tree().physics_frame
	for body in $ArenaArea.get_overlapping_bodies():
		_on_enter(body)

func is_finished() -> bool:
	return state == State.DEAD or state == State.FAILED

func is_exposed() -> bool:
	return state == State.VENT and health.can_damage and not health.dead

func _on_enter(body: Node3D) -> void:
	if state != State.DORMANT or not body is Player or body.is_dead or body.boss_arena_active:
		return
		
	player = body as Player
	player.attempt_drop()

	var previous := player.current_camera if is_instance_valid(player.current_camera) else player.camera
	camera.global_transform = previous.global_transform

	player.enter_boss_arena(global_position, arena_radius, camera)
	player.get_node("Health").death.connect(_on_player_death)

	$HUD/Panel.show()

	bar.max_value = health.max_health
	bar.value = health.current_health
	battle_started.emit()

	if player.get_node("Health").current_health < 3:
		_spawn_heart()
	_set_state(State.INTRO, 3.0, "Dodge the orange marks. Pick up cooled cinders with Interact.")

func _physics_process(delta: float) -> void:
	if is_instance_valid(player) and player.boss_arena_active:
		_update_camera(delta)

	if state == State.FAILED:
		retry_delay -= delta
		if retry_delay <= 0.0 and Input.is_action_just_pressed("interact"):
			_retry()
		return

	if state == State.DORMANT or state == State.DEAD:
		return

	if not is_instance_valid(player) or player.is_dead:
		return

	if state != State.WINDUP and state != State.WAVE:
		var direction := player.global_position - global_position
		$Visual.rotation.y = lerp_angle($Visual.rotation.y, atan2(direction.x, direction.z), delta * 3.0)

	remaining -= delta

	if remaining > 0.0:
		return

	match state:
		State.INTRO, State.HIT, State.TRANSITION:
			_begin_eruptions()
		State.ERUPTION:
			_play("Windup")
			_set_state(State.WINDUP, 1.5, "Hands up — get ready to JUMP the heat ring!")
		State.WINDUP:
			_play("Slam")
			_spawn_hazard(global_position, true)
			_set_state(State.WAVE, 1.9, "JUMP over the low heat ring!")
		State.WAVE:
			_play("Vent")
			health.can_damage = true
			_set_state(State.VENT, vent_duration, "CORE OPEN — pick up a blue cinder, then use Attack to throw!")
		State.VENT:
			health.can_damage = false
			_play("Idle")
			_set_state(State.HIT, 1.5, "The shutter closes. Save your cinder for the next opening.")

func _set_state(next: State, duration: float, message: String) -> void:
	state = next
	remaining = duration
	hint.text = message

func _begin_eruptions() -> void:
	_play("Idle")
	_set_state(State.ERUPTION, 2.6, "MOVE away from the orange marks — they erupt, then cool into cinders.")

	var radial := player.global_position - global_position
	radial.y = 0.0
	radial = radial.normalized() * arena_radius
	_spawn_hazard(global_position + radial, false)

	if phase == 2:
		_spawn_hazard(global_position + radial.rotated(Vector3.UP, 0.65), false)
		_spawn_hazard(global_position + radial.rotated(Vector3.UP, -0.65), false)

func _spawn_hazard(at: Vector3, ring: bool) -> void:
	var hazard := Hitbox.new()
	hazard.set_script(HAZARD)
	hazard.keeper = self
	hazard.player = player
	hazard.ring = ring

	$Effects.add_child(hazard)
	hazard.global_position = Vector3(at.x, global_position.y, at.z)

func spawn_cinder(at: Vector3) -> void:
	if is_finished():
		return

	for i in range(cinders.size() - 1, -1, -1):
		if not is_instance_valid(cinders[i]):
			cinders.remove_at(i)

	var floor_items: Array[Node3D] = []

	for item in cinders:
		if not item.held and not item.flying:
			floor_items.append(item)

	if floor_items.size() >= 5:
		floor_items[0].queue_free()

	var cinder := CINDER.instantiate() as Node3D
	cinder.keeper = self
	cinder.player = player

	$Pickups.add_child(cinder)

	cinder.global_position = at + Vector3.UP * 0.15
	cinders.append(cinder)

func _spawn_heart() -> void:
	var pickup := HEART.instantiate() as Node3D
	$Pickups.add_child(pickup)
	var radial := (player.global_position - global_position).normalized().rotated(Vector3.UP, 0.45)
	pickup.global_position = global_position + Vector3(radial.x, 0.0, radial.z).normalized() * arena_radius
	supplies.append(pickup)

func _on_damage(_amount: int, value: int) -> void:
	health.can_damage = false 

	bar.value = value
	health_changed.emit(value, health.max_health)

	if value <= 0:
		_win()
	elif value == 3:
		phase = 2

		_clear_hazards()
		_spawn_heart()
		_play("Hit")
		_set_state(State.TRANSITION, 4.0, "The kiln burns hotter! Three eruption marks. A health droplet has appeared.")
	else:
		_play("Hit")
		_set_state(State.HIT, 2.0, "Direct hit! Keep a cinder ready for the next opening.")

func _clear_hazards() -> void:
	for child in $Effects.get_children():
		child.queue_free()

func _clear_pickups() -> void:
	for item in cinders:
		if is_instance_valid(item):
			item.queue_free()
	cinders.clear()

func _win() -> void:
	_set_state(State.DEAD, 0.0, "KILN KEEPER QUIETED — the Ember Vault is open.")
	_clear_hazards()
	_clear_pickups()

	_play("Death")

	$CoreLight.light_energy = 0.0
	defeated.emit()

	await get_tree().create_timer(2.6).timeout

	if is_instance_valid(player):
		player.exit_boss_arena()

	await get_tree().create_timer(2.0).timeout
	$HUD/Panel.hide()

func _on_player_death() -> void:
	if state == State.DEAD:
		return

	health.can_damage = false

	_set_state(State.FAILED, 0.0, "The kiln still burns. Interact to retry at the arena with full health.")
	_clear_hazards()
	_clear_pickups()
	_play("Idle")

	retry_delay = 2.0

	await get_tree().create_timer(2.0).timeout

	$HUD/Retry.show()
	$HUD/Retry.grab_focus()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _retry() -> void:
	if state != State.FAILED or retry_delay > 0.0:
		return

	# Metadata survives reload, but not a fresh game session.
	get_tree().set_meta("ember_keeper_retry", true)

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().reload_current_scene()

func _update_camera(delta: float) -> void:
	var radial := player.global_position - global_position
	radial.y = 0.0

	if radial.length_squared() < 0.01:
		radial = Vector3.BACK

	var desired := global_position + radial.normalized() * camera_distance + Vector3.UP * camera_height
	camera.global_position = camera.global_position.lerp(desired, minf(delta * 5.0, 1.0))
	camera.look_at(global_position + Vector3.UP * 2.0)

func _loop_clip(name: String) -> void:
	if not animation:
		return

	for clip in animation.get_animation_list():
		if String(clip).get_file() == name:
			animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR

func _play(name: String) -> void:
	if not animation:
		return
		
	for clip in animation.get_animation_list():
		if String(clip).get_file() == name:
			animation.play(clip, 0.12)
			return
