extends Node

@export var minimum_walk_speed: float = 0.1

@onready var animation_tree: AnimationTree = $"../AnimationTree"

var enemy: Enemy
var state_machine: AnimationNodeStateMachinePlayback


func _ready() -> void:
	enemy = get_parent().get_parent()
	state_machine = animation_tree.get("parameters/playback")

	enemy.hit.connect(_on_enemy_hit)
	enemy.attacked.connect(_on_enemy_attack)

	var enemy_health: Health = enemy.get_node("Health")
	enemy_health.death.connect(func(): 
		travel_to("Death")
	)


func _process(_delta: float) -> void:
	if enemy.current_state == Enemy.State.DEATH:
		return

	if enemy.current_state == Enemy.State.HIT:
		return

	if enemy.current_state == Enemy.State.ATTACK:
		return

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


func _on_enemy_hit() -> void:
	# travel_to("Hit")
	pass

func _on_enemy_attack(_target: Node3D) -> void:
	travel_to("Inflate")
	await animation_tree.animation_finished
	get_parent().release_spores()
