extends Node3D

@export var player: Player
@export var movement_blend_speed: float = 8.0

@onready var animation_tree: AnimationTree = $AnimationTree

var state_machine: AnimationNodeStateMachinePlayback
var current_movement_blend: float = 0.0
var is_landing: bool = false


func _ready() -> void:
	state_machine = animation_tree.get(
		"parameters/MovementStateMachine/playback"
	)

	player.jump.connect(_on_player_jump)
	player.landed.connect(_on_player_landed)

	var player_hurtbox: Hurtbox = player.get_node("Hurtbox")

	player_hurtbox.hit.connect(func(hitbox: Hitbox):
		match hitbox.source:
			"":
				animation_tree.set("parameters/HitShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			"puffcap":
				animation_tree.set("parameters/CoughShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
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

	state_machine.travel(state_name)


func _on_player_jump() -> void:
	is_landing = false
	travel_to("Jump")


func _on_player_landed() -> void:
	is_landing = true
	travel_to("Land")