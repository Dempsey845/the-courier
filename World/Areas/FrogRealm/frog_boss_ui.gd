class_name FrogBossUI
extends CanvasLayer

@export_category("Health References")
@export var shield_health: Health
@export var boss_health: Health

@export_category("Animation")
@export var bar_update_duration: float = 0.25
@export var stage_transition_duration: float = 0.45
@export var damage_flash_duration: float = 0.12

@onready var boss_panel: Control = %BossPanel
@onready var shield_stage: Control = %ShieldStage
@onready var health_stage: Control = %HealthStage

@onready var shield_bar: ProgressBar = %ShieldBar
@onready var health_bar: ProgressBar = %HealthBar

@onready var shield_value_label: Label = %ShieldValueLabel
@onready var health_value_label: Label = %HealthValueLabel
@onready var stage_label: Label = %StageLabel

@onready var shield_flash: ColorRect = %ShieldFlash
@onready var health_flash: ColorRect = %HealthFlash

var shield_depleted: bool = false
var ui_hiding: bool = false
var shown_panel_position: Vector2
var visibility_tween: Tween

var shield_bar_tween: Tween
var health_bar_tween: Tween
var transition_tween: Tween
var flash_tween: Tween


func _ready() -> void:
	shown_panel_position = boss_panel.position

	_setup_health_bars()
	_connect_health_signals()
	_update_stage_immediately()

	boss_panel.position = shown_panel_position + Vector2(0.0, 14.0)
	boss_panel.modulate.a = 0.0
	visible = false


func _setup_health_bars() -> void:
	if shield_health:
		shield_bar.max_value = shield_health.max_health
		shield_bar.value = shield_health.current_health
		_update_shield_label(shield_health.current_health)

	if boss_health:
		health_bar.max_value = boss_health.max_health
		health_bar.value = boss_health.current_health
		_update_health_label(boss_health.current_health)


func _connect_health_signals() -> void:
	if shield_health:
		shield_health.damage_taken.connect(_on_shield_damage_taken)

	if boss_health:
		boss_health.damage_taken.connect(_on_boss_damage_taken)


func _update_stage_immediately() -> void:
	shield_depleted = (
		shield_health == null
		or shield_health.current_health <= 0.0
	)

	shield_stage.visible = not shield_depleted
	health_stage.modulate = (
		Color.WHITE
		if shield_depleted
		else Color(0.42, 0.30, 0.48, 0.65)
	)

	stage_label.text = (
		"FROG KING"
		if shield_depleted
		else "ARCANE SHIELD"
	)


func show_boss_ui() -> void:
	if visibility_tween and visibility_tween.is_valid():
		visibility_tween.kill()

	ui_hiding = false
	visible = true

	boss_panel.position = (
		shown_panel_position
		+ Vector2(0.0, 14.0)
	)
	boss_panel.modulate.a = 0.0

	visibility_tween = create_tween()
	visibility_tween.set_parallel()

	visibility_tween.tween_property(
		boss_panel,
		"modulate:a",
		1.0,
		0.3
	)

	visibility_tween.tween_property(
		boss_panel,
		"position",
		shown_panel_position,
		0.4
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_shield_damage_taken(
	_damage_amount: float,
	new_health: float
) -> void:
	_update_shield_label(new_health)
	_tween_bar(shield_bar, new_health, true)
	_flash_bar(shield_flash, Color(0.45, 0.95, 1.0, 0.65))

	if new_health <= 0.0 and not shield_depleted:
		shield_depleted = true
		_transition_to_health_stage()


func _on_boss_damage_taken(
	_damage_amount: float,
	new_health: float
) -> void:
	_update_health_label(new_health)
	_tween_bar(health_bar, new_health, false)
	_flash_bar(
		health_flash,
		Color(1.0, 0.18, 0.32, 0.55)
	)

	if new_health <= 0.0 and not ui_hiding:
		await get_tree().create_timer(
			bar_update_duration
		).timeout

		hide_boss_ui()


func _tween_bar(
	bar: ProgressBar,
	target_value: float,
	is_shield: bool
) -> void:
	var existing_tween := (
		shield_bar_tween
		if is_shield
		else health_bar_tween
	)

	if existing_tween and existing_tween.is_valid():
		existing_tween.kill()

	var tween := create_tween()
	tween.tween_property(
		bar,
		"value",
		clampf(target_value, 0.0, bar.max_value),
		bar_update_duration
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

	if is_shield:
		shield_bar_tween = tween
	else:
		health_bar_tween = tween


func _transition_to_health_stage() -> void:
	if transition_tween and transition_tween.is_valid():
		transition_tween.kill()

	stage_label.text = "SHIELD BROKEN!"

	transition_tween = create_tween()

	transition_tween.tween_property(
		shield_stage,
		"modulate",
		Color(0.3, 0.7, 1.0, 0.0),
		stage_transition_duration
	)

	transition_tween.tween_callback(
		func() -> void:
			shield_stage.visible = false
			stage_label.text = "FROG KING"
	)

	transition_tween.set_parallel()

	transition_tween.tween_property(
		health_stage,
		"modulate",
		Color.WHITE,
		stage_transition_duration
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

	transition_tween.tween_property(
		health_stage,
		"scale",
		Vector2(1.03, 1.03),
		stage_transition_duration * 0.5
	)

	transition_tween.chain().tween_property(
		health_stage,
		"scale",
		Vector2.ONE,
		stage_transition_duration * 0.5
	)


func _flash_bar(
	flash: ColorRect,
	flash_colour: Color
) -> void:
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()

	flash.color = flash_colour

	flash_tween = create_tween()
	flash_tween.tween_property(
		flash,
		"color:a",
		0.0,
		damage_flash_duration
	)


func _update_shield_label(value: float) -> void:
	shield_value_label.text = "%d / %d" % [
		ceili(maxf(value, 0.0)),
		ceili(shield_bar.max_value)
	]


func _update_health_label(value: float) -> void:
	health_value_label.text = "%d / %d" % [
		ceili(maxf(value, 0.0)),
		ceili(health_bar.max_value)
	]


func hide_boss_ui() -> void:
	if ui_hiding:
		return

	ui_hiding = true

	if visibility_tween and visibility_tween.is_valid():
		visibility_tween.kill()

	visibility_tween = create_tween()
	visibility_tween.set_parallel()

	visibility_tween.tween_property(
		boss_panel,
		"modulate:a",
		0.0,
		0.3
	)

	visibility_tween.tween_property(
		boss_panel,
		"position",
		shown_panel_position + Vector2(0.0, 14.0),
		0.3
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)

	visibility_tween.chain().tween_callback(
		func() -> void:
			visible = false
	)
	