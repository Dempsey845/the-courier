extends StaticBody3D

@export var fan_strength: float = 22.0
@export var max_fan_speed: float = 12.0

@onready var fan_zone: Area3D = $FanZone
@onready var fan_particles: CPUParticles3D = $FanParticles

@onready var check_area_timer: Timer = $CheckAreaTimer

func _ready() -> void:
	fan_zone.body_entered.connect(_on_body_entered)
	fan_zone.body_exited.connect(_on_body_exited)
	
	check_area_timer.timeout.connect(func():
		var bodies = fan_zone.get_overlapping_bodies()
		for body: Node3D in bodies:
			if body is not Player:
				continue
			
			_on_body_entered(body)
	)


func _physics_process(_delta: float) -> void:
	for body: Node3D in fan_zone.get_overlapping_bodies():
		if body is Player:
			body.update_fan_direction(get_fan_direction())


func get_fan_direction() -> Vector3:
	return global_basis.y.normalized()


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		body.enter_fan(
			get_fan_direction(),
			fan_strength,
			max_fan_speed
		)


func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		body.exit_fan()

