extends Area3D

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D):
    if body is Player:
        BeamTransitionCanvasLayer.start_transition("res://World/Areas/Ruins/dungeon_area_new.tscn", DataManager.WorldType.World)
