class_name RootSpikeHitbox
extends Hitbox

var _hit_this_strike: Dictionary = {}
var _strike_id := 0


func _ready() -> void:
	active = false
	monitoring = false
	area_entered.connect(_on_area_entered)


func begin_strike() -> void:
	_strike_id += 1
	var this_strike := _strike_id
	_hit_this_strike.clear()
	# Let the warning part of the Enter animation play before enabling damage.
	await get_tree().create_timer(0.35).timeout
	if this_strike != _strike_id or not is_inside_tree():
		return
	active = true
	monitoring = true
	await get_tree().physics_frame
	if this_strike == _strike_id and active:
		force_hit_update()


func end_strike() -> void:
	_strike_id += 1
	active = false
	monitoring = false


func register_hit(hurtbox: Hurtbox):
	if _hit_this_strike.has(hurtbox) or hurtbox.just_hit:
		return false
	if super.register_hit(hurtbox):
		_hit_this_strike[hurtbox] = true
		return true
	return false


func _on_area_entered(area: Area3D) -> void:
	if area is Hurtbox:
		register_hit(area as Hurtbox)
