extends Node3D

@export var player: Player
@export var movement_blend_speed: float = 8.0

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var hold_point: Marker3D = %HoldPoint

var state_machine: AnimationNodeStateMachinePlayback
var current_movement_blend: float = 0.0
var is_landing: bool = false
var is_dead: bool = false
var just_taken_damage: bool = false

const HOLD_BLEND_PATH := "parameters/HoldBlend/blend_amount"
const THROW_SHOT_PATH := "parameters/ThrowShot/request"

var hold_tween: Tween
var current_hold_object: Node3D

func _ready() -> void:
	state_machine = animation_tree.get(
		"parameters/MovementStateMachine/playback"
	)

	player.jump.connect(_on_player_jump)
	player.landed.connect(_on_player_landed)
	player.hold_started.connect(_on_player_hold)
	player.throw_attempt.connect(_on_player_throw_attempt)
	player.drop_attempt.connect(_on_player_drop_attempt)

	var player_hurtbox: Hurtbox = player.get_node("Hurtbox")
	var player_health: Health = player.get_node("Health")

	player_hurtbox.hit.connect(func(hitbox: Hitbox):
		if player_health.dead or !just_taken_damage:
			return
			
		match hitbox.source:
			"":
				animation_tree.set("parameters/HitShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			"puffcap":
				animation_tree.set("parameters/CoughShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			"press":
				animation_tree.set("parameters/SquishShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	)

	player_health.damage_taken.connect(func(_damage_amount, _new_health):
		just_taken_damage = true
		await get_tree().process_frame

		just_taken_damage = false
	)

	var health: Health = player.get_node("Health")

	health.death.connect(func():
		travel_to("Death")
		_tween_hold_to(0.0)
		is_dead = true
	)

	travel_to("Movement")


func _physics_process(delta: float) -> void:
	if is_landing:
		update_land_animation()
		return

	if not player.is_on_floor():
		update_air_animation()
	else:
		update_ground_animation(delta)


func update_ground_animation(delta: float) -> void:
	travel_to("Movement")

	var horizontal_speed := Vector2(
		player.velocity.x,
		player.velocity.z
	).length()

	var target_blend := clampf(
		horizontal_speed / player.move_speed,
		0.0,
		1.0
	)

	var blend_weight := 1.0 - exp(
		-movement_blend_speed * delta
	)

	current_movement_blend = lerpf(
		current_movement_blend,
		target_blend,
		blend_weight
	)

	animation_tree.set(
		"parameters/MovementStateMachine/Movement/blend_position",
		current_movement_blend
	)


func update_air_animation() -> void:
	if player.velocity.y > 0.0:
		travel_to("Jump")
	else:
		travel_to("Fall")


func update_land_animation() -> void:
	var animation_position := state_machine.get_current_play_position()
	var animation_length := state_machine.get_current_length()

	if animation_length <= 0.0:
		finish_landing()
		return

	if animation_position >= animation_length:
		finish_landing()


func finish_landing() -> void:
	is_landing = false
	travel_to("Movement")


func travel_to(state_name: StringName) -> void:
	if state_machine.get_current_node() == state_name:
		return

	if is_dead:
		return

	state_machine.travel(state_name)


func _on_player_jump() -> void:
	is_landing = false
	travel_to("Jump")


func _on_player_landed() -> void:
	is_landing = true
	travel_to("Land")

func start_holding(hold_object: Node3D) -> void:
	if is_dead:
		return

	if current_hold_object:
		current_hold_object.queue_free()
		current_hold_object = null

	hold_object.reparent(hold_point)
	hold_object.position = Vector3.ZERO

	current_hold_object = hold_object

	_tween_hold_to(1.0)


func throw_held_item() -> bool:
	if is_dead:
		return false

	var hold_amount: float = animation_tree.get(HOLD_BLEND_PATH)
	if hold_amount < 0.99:
		return false

	animation_tree.set(
		THROW_SHOT_PATH,
		AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	)

	animation_tree.set(HOLD_BLEND_PATH, 0.0)

	return true

func throw_current_held_object():
	if !is_instance_valid(current_hold_object):
		player.is_holding = false
		return
	
	if current_hold_object.has_method("throw_pickup"):
		current_hold_object.throw_pickup()
	else:
		current_hold_object.queue_free()
		
	current_hold_object = null
	player.trigger_successful_throw()

func _tween_hold_to(target: float) -> void:
	if hold_tween and hold_tween.is_running():
		hold_tween.kill()

	var current: float = animation_tree.get(HOLD_BLEND_PATH)
	hold_tween = create_tween()
	hold_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	hold_tween.tween_method(
		func(value: float) -> void:
			animation_tree.set(HOLD_BLEND_PATH, value),
		current,
		target,
		0.4
	)

func _on_player_hold(hold_object: Node3D):
	start_holding(hold_object)

func _on_player_throw_attempt():
	throw_held_item()

func _on_player_drop_attempt():
	if current_hold_object:
		current_hold_object.queue_free()
		player.is_holding = false