extends Area3D

@export var camera_switch_prompt: InputUIPrompt
@export var frog_boss: FrogBoss

@onready var frog_realm: FrogRealm = get_parent()
@onready var switch_cooldown_timer: Timer = $SwitchCooldownTimer

var is_player_camera: bool = true
var auto_switch: bool = true

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	camera_switch_prompt.pressed.connect(_on_camera_switch_input)

	switch_cooldown_timer.timeout.connect(func():
		camera_switch_prompt.can_press = true
	)

	frog_boss.encounter.connect(_on_frog_boss_encounter)
	frog_boss.death.connect(_on_frog_boss_death)

func switch_to_player_camera():
	if !switch_cooldown_timer.is_stopped():
		return

	frog_realm.switch_to_player_camera()
	is_player_camera = true

	switch_cooldown_timer.start()

func switch_to_frog_boss_camera():
	if !switch_cooldown_timer.is_stopped():
		return

	frog_realm.switch_to_frog_boss_camera()
	is_player_camera = false

	switch_cooldown_timer.start()

func _on_body_entered(body: Node3D):
	if body is not Player or !auto_switch or !is_player_camera:
		return
	
	switch_to_frog_boss_camera()

func _on_body_exited(body: Node3D):
	if body is not Player or is_player_camera:
		return
	
	switch_to_player_camera()
	
func _on_camera_switch_input():
	auto_switch = false

	if is_player_camera:
		switch_to_frog_boss_camera()
	else:
		switch_to_player_camera()

	camera_switch_prompt.can_press = false

func _on_frog_boss_encounter():
	camera_switch_prompt.show_prompt()

func _on_frog_boss_death():
	camera_switch_prompt.hide_prompt()
	frog_realm.switch_to_player_camera()
	queue_free()
