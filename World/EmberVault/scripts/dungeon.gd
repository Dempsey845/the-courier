extends Node3D

signal puzzle_solved
signal checkpoint_reached(marker: Marker3D)

@export var interaction_distance := 3.2

@onready var player: Player = $Player

var solved := false
var states: Array[int] = [0, 0, 0]
var busy := false
var checkpoint: Marker3D
const SOLUTION: Array[int] = [2, 0, 1]

func _ready() -> void:
	checkpoint = $Markers/PlayerSpawn
	$Checkpoints/FarBank.body_entered.connect(_on_checkpoint)
	$Markers/BossSpawn/EmberKeeper.defeated.connect(_on_ember_keeper_defeated)
	if get_tree().has_meta("ember_keeper_retry"):
		get_tree().remove_meta("ember_keeper_retry")
		set_puzzle_solved()
		player.position = Vector3(0, 0.3, -66.5)
		checkpoint = $Markers/BossSpawn
		checkpoint_reached.emit(checkpoint)

func interact_nearest(from: Vector3) -> bool:
	var nearest := -1
	var distance := interaction_distance

	for i in range(3):
		var d: float = from.distance_to(($Puzzle.get_child(i) as Node3D).global_position)
		if d < distance:
			distance = d
			nearest = i

	if nearest >= 0:
		rotate_pillar(nearest)
		return true

	return false

func rotate_pillar(index: int) -> void:
	if solved or busy or index < 0 or index > 2:
		return

	busy = true
	states[index] = (states[index] + 1) % 4

	var drum := $Puzzle.get_child(index).get_node("Drum") as Node3D
	var tween := create_tween()

	tween.tween_property(drum, "rotation:y", drum.rotation.y - PI / 2.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	busy = false
	if states == SOLUTION:
		set_puzzle_solved()

func set_puzzle_solved() -> void:
	if solved:
		return
	solved = true

	for i in range(3):
		var prompt := get_node("Puzzle/Pillar%d/InputPrompt" % i) as InputPrompt
		prompt.can_be_shown = false

	states.assign(SOLUTION)

	for i in range(3):
		($Puzzle.get_child(i).get_node("Drum") as Node3D).rotation.y = -SOLUTION[i] * PI / 2.0
		
	$VaultDoor/CollisionShape3D.set_deferred("disabled", true)
	$Navigation/VaultLink.enabled = true
	create_tween().tween_property($VaultDoor, "position:y", 6.5, 1.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	$PuzzleMessage.text = "THE VAULT REMEMBERS"
	puzzle_solved.emit()

func _on_checkpoint(body: Node3D) -> void:
	if body is Player:
		checkpoint = $Markers/FarBankRespawn
		checkpoint_reached.emit(checkpoint)

func _on_ember_keeper_defeated() -> void:
	$BossDoor/CollisionShape3D.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property($BossDoor, "position:y", 8.5, 1.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
