extends Node3D

@export var player: Player
@export var minimum_walk_speed: float = 0.1

@onready var animation_tree: AnimationTree = $AnimationTree

var state_machine: AnimationNodeStateMachinePlayback
var is_landing: bool = false

func _ready() -> void:
	state_machine = animation_tree.get(
		"parameters/MovementStateMachine/playback"
	)

	player.jump.connect(_on_player_jump)
	player.landed.connect(_on_player_landed)

	state_machine.travel("Idle")


func _physics_process(_delta: float) -> void:
	if is_landing:
		update_land_animation()
		return

	if not player.is_on_floor():
		update_air_animation()
	else:
		update_ground_animation()


func update_ground_animation() -> void:
	var horizontal_speed: float = Vector2(
		player.velocity.x,
		player.velocity.z
	).length()

	if horizontal_speed > minimum_walk_speed:
		travel_to("Walk")
	else:
		travel_to("Idle")


func update_air_animation() -> void:
	if player.velocity.y > 0.0:
		travel_to("Jump")
	else:
		travel_to("Fall")


func update_land_animation() -> void:
	# Land does not automatically travel back to another state,
	# so wait for it to finish and then deliberately change state.
	var animation_position: float = \
		state_machine.get_current_play_position()

	var animation_length: float = \
		state_machine.get_current_length()

	if animation_length <= 0.0:
		finish_landing()
		return

	if animation_position >= animation_length:
		finish_landing()


func finish_landing() -> void:
	is_landing = false
	update_ground_animation()


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
