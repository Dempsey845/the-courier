extends Area3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var claimed: bool = false

func _ready() -> void:
    animation_player.play("appear")
    await animation_player.animation_finished
    body_entered.connect(_on_body_entered)

    var overlapping_bodies = get_overlapping_bodies()

    for body in overlapping_bodies:
        _on_body_entered(body)

func _on_body_entered(body: Node3D):
    if body is not Player or claimed:
        return

    claimed = true

    var player_health: Health = body.get_node_or_null("Health")

    if player_health:
        player_health.heal(1)

    
    
    animation_player.play("disappear")
    await animation_player.animation_finished
    queue_free()