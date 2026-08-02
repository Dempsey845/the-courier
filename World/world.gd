extends Node3D

@export var scale_3d: float = 1.0

func _ready() -> void:
    get_viewport().scaling_3d_scale = scale_3d