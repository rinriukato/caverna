extends Sprite


export(String, FILE, "*.tscn") var target_level_path = ""

func _on_Area2D_body_entered(body):
	if not body is Player: return
	if target_level_path.empty(): return

	get_tree().change_scene(target_level_path)
