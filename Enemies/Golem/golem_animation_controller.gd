extends Node

@export var minimum_walk_speed: float = 0.1

@onready var animation_tree: AnimationTree = $'../AnimationTree'

var enemy: Enemy

var state_machine: AnimationNodeStateMachinePlayback

func _ready() -> void:
	enemy = get_parent().get_parent()

	state_machine = animation_tree.get("parameters/playback")

func _process(_delta: float) -> void:
	var horizontal_speed: float = Vector2(
		enemy.velocity.x,
		enemy.velocity.z
	).length()

	if horizontal_speed > minimum_walk_speed:
		travel_to("Walk")
	else:
		travel_to("Idle")

func travel_to(state_name: StringName) -> void:
	if state_machine.get_current_node() == state_name:
		return

	state_machine.travel(state_name)
