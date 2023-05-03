extends Node2D

onready var sprite: = $AnimatedSprite
onready var hitbox:= $Hitbox/CollisionShape2D
onready var timer:= $Cooldown

func _on_Hitbox_body_entered(body):
	if body is Player:
		
		# Check if the jump is enabled:
		if not body.is_air_dash_enabled():
			# Enable Air Dash Power
			body.set_air_dash(true)
			
		# Otherwise give the airdash back to the player
		else:
			body.increment_air_dash()
		
		#Disappear for like 10 seconds
		sprite.visible = false
		hitbox.set_deferred("disabled", true)
		timer.start()

func _on_Cooldown_timeout():
	sprite.visible = true
	hitbox.set_deferred("disabled", false)
