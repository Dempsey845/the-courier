extends Hitbox

var keeper: Node3D
var player: Player
var held := false
var flying := false
var consumed := false
var elapsed := 0.0
var duration := 0.7
var origin := Vector3.ZERO
var destination := Vector3.ZERO

@onready var prompt: InputPrompt = $InputPrompt

func _ready() -> void:
	active = false
	prompt.pressed.connect(_pick_up)

func _process(delta: float) -> void:
	if not is_instance_valid(keeper) or keeper.is_finished():
		queue_free()
		return

	if flying:
		elapsed += delta
		var t := minf(elapsed / duration, 1.0)
		global_position = origin.lerp(destination, t) + Vector3.UP * sin(t * PI) * 2.2
		$Visual.rotation.y += delta * 6.0

		if t >= 1.0:
			# Explicit endpoint contact also handles low frame rates and small cores.
			register_hit(keeper.get_node("Hurtbox") as Hurtbox)
			queue_free()
			
	elif not held and is_instance_valid(player):
		var allowed := not player.is_holding and not player.is_dead
		if prompt.can_be_shown != allowed:
			prompt.can_be_shown = allowed
		$Visual.rotation.y += delta

func _pick_up() -> void:
	if held or flying or not is_instance_valid(player) or player.is_holding or player.is_dead:
		return

	held = true
	prompt.can_be_shown = false
	prompt.set_deferred("monitoring", false)
	prompt.hide()
	player.start_holding(self)

func throw_pickup() -> void:
	if not is_instance_valid(keeper):
		queue_free()
		return

	reparent(get_tree().current_scene, true)

	origin = global_position
	destination = keeper.get_node("Hurtbox").global_position
	duration = maxf(origin.distance_to(destination) / 13.0, 0.35)
	
	elapsed = 0.0
	flying = true
	active = true

func register_hit(hurtbox: Hurtbox):
	if consumed or not flying or not is_instance_valid(keeper):
		return false

	if hurtbox != keeper.get_node("Hurtbox"):
		return false

	if not keeper.is_exposed():
		return false

	consumed = true
	var accepted: bool = super.register_hit(hurtbox)
	active = false
	queue_free()

	return accepted
