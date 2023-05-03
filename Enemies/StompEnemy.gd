extends Node2D

enum {
	HOVER, 
	FALL, 
	RISE,
	LAND
}

export (int) var FALL_SPEED = 100
export (int) var RISE_SPEED = 20

var state = HOVER

onready var start_position = global_position
onready var timer: = $Timer
onready var raycast: = $RayCast2D
onready var collisionShape = $Hitbox/CollisionShape2D
onready var particles = $Particles2D

func _ready():
	particles.emitting = false
	particles.one_shot = true

func _physics_process(delta):
	match state:
		HOVER: hover_state()
		FALL: fall_state(delta)
		LAND: land_state()
		RISE: rise_state(delta)

func hover_state():
	state = FALL

func fall_state(delta):
	$AnimatedSprite.animation = "Falling"
	global_position.y += FALL_SPEED * delta
	if raycast.is_colliding():
		var collision_point = raycast.get_collision_point()
		var shape = collisionShape.shape

		global_position.y = collision_point.y - shape.extents.y
		timer.start(1.0)
		state = LAND
		particles.emitting = true

func land_state():
	if timer.time_left == 0:
		state = RISE

func rise_state(delta):
	particles.emitting = false
	$AnimatedSprite.animation = "Rising"
	position.y = move_toward(position.y, start_position.y, RISE_SPEED * delta)
	
	if position.y == start_position.y:
		state = HOVER
