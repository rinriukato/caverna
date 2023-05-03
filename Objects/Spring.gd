extends Sprite

export (int) var spring_force = 500


func _on_Area2D_body_entered(body):
		if body is Player:
			body.apply_jump_force(spring_force)
			body.reset_air_dash()
