extends Area3D

@onready var frog_realm: FrogRealm = get_parent()

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D):
    if body is not Player:
        return
    
    frog_realm.switch_to_frog_boss_camera()

func _on_body_exited(body: Node3D):
    if body is not Player:
        return
    
    frog_realm.switch_to_player_camera()
    