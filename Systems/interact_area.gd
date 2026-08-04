class_name InteractArea
extends Area3D

signal interacted
signal player_entered
signal player_exited

var in_area: bool

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("interact") and in_area:
        interacted.emit()

func _on_body_entered(body: Node3D):
    if body is Player:
        in_area = true
        player_entered.emit()

func _on_body_exited(body: Node3D):
    if body is Player:
        in_area = false
        player_exited.emit()