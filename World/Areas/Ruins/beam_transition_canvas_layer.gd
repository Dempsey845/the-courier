extends CanvasLayer

@onready var beam_transition_rect: BeamTransitionRect  = $BeamTransitionRect

func start_transition(scene_path: String, transition_from_world: DataManager.WorldType):
    beam_transition_rect.change_scene(scene_path, transition_from_world)
