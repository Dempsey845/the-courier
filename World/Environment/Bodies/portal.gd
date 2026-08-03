extends MeshInstance3D

func open_portal():
    var tween := create_tween()

    tween.tween_method(
        func(value: float):
            material_override.set_shader_parameter("transition_progress", value),
        0.0,
        1.0,
        0.8
    ).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func close_portal():
    var tween := create_tween()

    tween.tween_method(
        func(value: float):
            material_override.set_shader_parameter("transition_progress", value),
        1.0,
        0.0,
        0.6
    ).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)