extends Area3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D):
    if body is not Player:
        return
    
    if animation_player.is_playing():
        return
    
    animation_player.play("collect")
    await animation_player.animation_finished
    DataManager.player_has_depetrification_device = true
    queue_free()
