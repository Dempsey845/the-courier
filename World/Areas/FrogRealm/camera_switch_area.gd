extends Area3D

@export var camera_switch_prompt: InputUIPrompt
@export var player: Player

@onready var frog_realm: FrogRealm = get_parent()
@onready var switch_cooldown_timer: Timer = $SwitchCooldownTimer

var is_player_camera: bool = true
var frog_boss: FrogBoss

func _ready() -> void:
	frog_realm.frog_boss_spawned.connect(_on_frog_boss_spawned)

func _on_frog_boss_spawned():
	frog_boss = frog_realm.frog_boss

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	camera_switch_prompt.pressed.connect(_on_camera_switch_input)

	switch_cooldown_timer.timeout.connect(func():
		camera_switch_prompt.can_press = true
	)

	frog_boss.encounter.connect(_on_frog_boss_encounter)
	frog_boss.death.connect(_on_frog_boss_death)

func switch_to_player_camera() -> bool:
	if !is_instance_valid(switch_cooldown_timer):
		return false

	if not switch_cooldown_timer.is_stopped():
		return false

	frog_realm.switch_to_player_camera()
	is_player_camera = true

	switch_cooldown_timer.start()
	return true


func switch_to_frog_boss_camera() -> bool:
	if !is_instance_valid(switch_cooldown_timer):
		return false
		
	if not switch_cooldown_timer.is_stopped():
		return false

	if player.global_position.y > frog_boss.maximum_player_attack_height:
		return false

	frog_realm.switch_to_frog_boss_camera()
	is_player_camera = false

	switch_cooldown_timer.start()
	return true

func _on_body_entered(body: Node3D):
	if body is not Player or !is_player_camera:
		return
	
	switch_to_frog_boss_camera()

func _on_body_exited(body: Node3D):
	if body is not Player or is_player_camera:
		return
	
	switch_to_player_camera()
	
func _on_camera_switch_input() -> void:
	var switched: bool

	if is_player_camera:
		switched = switch_to_frog_boss_camera()
	else:
		switched = switch_to_player_camera()

	if switched:
		camera_switch_prompt.can_press = false

func _on_frog_boss_encounter():
	camera_switch_prompt.show_prompt()

func _on_frog_boss_death():
	camera_switch_prompt.hide_prompt()
	if !is_player_camera:
		frog_realm.switch_to_player_camera()
	queue_free()
