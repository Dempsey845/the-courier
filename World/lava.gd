extends Hitbox

func _ready() -> void:
    hit_hurtbox.connect(_on_hit_hurtbox)

func _on_hit_hurtbox(hurtbox: Hurtbox):
    if hurtbox.get_parent() is Player:
        if hurtbox.health.dead:
            return
            
        var player: Player = hurtbox.get_parent()
        player.apply_upward_force(10.0)