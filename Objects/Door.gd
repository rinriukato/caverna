extends Area2D

export(String, FILE, "*.tscn") var target_level_path = ""

func _on_Door_body_entered(body):
	if not body is Player: return
	if target_level_path.empty(): return
#	Transition.play_exit_transition()
#	yield(Transition, "transition_completed")
#	Transition.play_enter_transition()
#	yield(Transition, "transition_completed")
#warning-ignore:return_value_discarded
	get_tree().change_scene(target_level_path)
#	Transition.toggle_visible()
