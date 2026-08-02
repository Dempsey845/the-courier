class_name ZoneArea
extends Area3D

@export var zone: ZoneManager.Zone

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D):
    if body is Player:
        if ZoneManager.instance:
            ZoneManager.instance.change_zone(zone)