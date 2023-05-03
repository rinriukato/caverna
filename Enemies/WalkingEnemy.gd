extends KinematicBody2D

var direction = Vector2.LEFT # Starting direction, walks left
var velocity = Vector2.ZERO

onready var ledge_check: = $LedgeCheck	 # Connect a 2D Ray for collision
onready var sprite: = $SpikeEnemySprite # Get enemy sprite

func _physics_process(_delta):
	var found_wall = is_on_wall()
	var found_ledge = not ledge_check.is_colliding()
	
	if found_wall or found_ledge:
		direction *= -1 # flip the direction the enemy is going
		scale.x *= -1 # flip entire body
	
	velocity = direction * 25
	velocity = move_and_slide(velocity, Vector2.UP) # Move the character, UP is for detecting the wall
