extends KinematicBody2D
class_name Player

# FSM of player states
enum { MOVE, CLIMB, DASH, WALLSLIDE}

### Animation and Sprites ###
onready var player_sprite: = $Sprite
onready var animation_player = $AnimationPlayer

### Raycasts ###
onready var ladder_check: = $LadderCheck
onready var left_wall_check: = $LeftWallCheck
onready var right_wall_check: = $RightWallCheck

#### Timers ###
onready var jump_buffer_timer: = $Timers/JumpBufferTimer
onready var coyote_jump_timer: = $Timers/CoyoteJumpTimer
onready var ghost_timer: = $Timers/GhostTimer
onready var dash_timer: = $Timers/DashTimer

### Sounds ###
onready var jump_sound: = $PlayerSounds/JumpSound
onready var dash_sound: = $PlayerSounds/DashSound

### Camera Functionality ####
onready var remote_transform_2D: = $RemoteTransform2D
onready var player_camera: = $"../PlayerCamera"

var ghost_scene = preload("res://Player/DashGhost.tscn")

# Player movement stats avaliable in inspector
export (int) var GRAVITY = 300
export (int) var MAX_SPEED = 250
export (int) var MAX_JUMP_POWER = 150
export (int) var MIN_JUMP_POWER = 30
export (int) var WALL_JUMP_PUSH = 300 # Push force against the wall
export (int) var WALL_JUMP_POWER = 200 # Vertical force from wall
export (int) var WALL_SLIDE_SPEED = 120
export (int) var ACCELERATION = 700
export (int) var FRICTION = 650
export (int) var FAST_FALL_SPEED = 1800
export (int) var MAX_GRAVITY = 300
export (int) var CLIMB_SPEED = 50
export (int) var DOUBLE_JUMPS_COUNT = 1
export (int) var AIR_DASH_POWER = 1000

# States for animations
var is_jumping : bool = false
var is_landed : bool = false
var is_blinking : bool = false
var is_crouching : bool = false
var is_dead : bool = false
var num_blinks : int = 0

# Movement Vars
var velocity : Vector2 = Vector2.ZERO
var dash_direction : Vector2 = Vector2.ZERO
var state : int = MOVE
var air_dash_enabled : float = true
var double_jump : int = DOUBLE_JUMPS_COUNT
var floatiness : float = 4.0 # controls the "floatiness" post air-dash. Higher the less floaty
var buffered_jump : bool = false
var coyote_jump : bool = false
var is_dashing : bool  = false

func _physics_process(delta):
	var input = Vector2.ZERO

	# Direction Vector	
	input.x = Input.get_axis("move_left", "move_right") # -1 is left
	input.y = Input.get_axis("move_up", "move_down") # -1 is up
	
	match state:
		MOVE: move_state(input, delta)
		CLIMB: climb_state(input)
		DASH: dash_state()
		WALLSLIDE: wallslide_state(input, delta)

func apply_gravity(delta):
	velocity.y += GRAVITY * delta
	velocity.y = min(velocity.y, MAX_GRAVITY)
	velocity.y = min(velocity.y, MAX_GRAVITY)
	
func apply_friction(delta):
	velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

func apply_acceleration(direction, delta):
	velocity.x = move_toward(velocity.x, MAX_SPEED * direction, ACCELERATION * delta)
	
func is_on_ladder():
	if not ladder_check.is_colliding(): return false
	var collider = ladder_check.get_collider()
	
	if not collider is Ladder: return false # Check if the collider is class name "Ladder"
	
	return true

func move_state(input, delta):
	# NOTE: HAVE TRANSITION FROM STATES IN THE STATE YOU'RE TRANSITIONING FROM!
	# i.e: [Move] -> [Climb]. The transition should be in [Move]
	if is_dead: return
	
	if is_on_ladder() && Input.is_action_just_pressed("move_up"): 
		state = CLIMB
	
	if is_dashing:
		state = DASH
		
	if is_on_wall() && !is_on_floor():
		velocity = Vector2.ZERO
		state = WALLSLIDE
	
	apply_gravity(delta)
	
	if !is_moving_horizontally(input):
		apply_friction(delta)
	else:
		apply_acceleration(input.x, delta)
	
	if is_on_floor():
		reset_air_dash()

	if can_jump():
		input_jump()
	
	# Player is currently jumping
	else:
		input_jump_release()
		input_air_dash(input)
		buffer_jump()
		fast_fall(delta)
	
	var was_on_floor = is_on_floor()

	velocity = move_and_slide(velocity, Vector2.UP)
	
	var just_left_ground = !is_on_floor() && was_on_floor
	
	# We "walked" off a cliff if the velocity is positive
	enable_coyote_jump(just_left_ground)
	handle_animation()

func climb_state(input):
	if !is_on_ladder(): state = MOVE
	animation_player.play("run (copy) 0.7 (copy)")
	
	if input.length() != 0:
		animation_player.play()
	else:
		animation_player.stop()
	
	velocity = input * CLIMB_SPEED
	velocity = move_and_slide(velocity, Vector2.UP)

func dash_state():
	if !is_dashing:
		state = MOVE
		
	velocity = move_and_slide(dash_direction, Vector2.UP)
	velocity = velocity / floatiness
	handle_animation()

func wallslide_state(input, delta):
	
	# for the wall jump itself: I probably want a timer before regaining control
	if !is_on_wall():
		state = MOVE
	
	# Apply reduced "gravity" because you're sliding
	velocity.y += WALL_SLIDE_SPEED * delta
	
	# Allows player to slide off a wall once on it
	if !is_moving_horizontally(input):
		apply_friction(delta)
	else:
		apply_acceleration(input.x, delta)
	
	input_wall_jump()
	
	velocity = move_and_slide(velocity, Vector2.UP)
	handle_animation()	
	
func player_die():
	if is_dead == true : return
	is_dead = true
	SoundPlayer.play_death_sound()
	velocity = Vector2.ZERO
	animation_player.play("death")

func input_jump_release():
	if Input.is_action_just_released("jump") && velocity.y < -MIN_JUMP_POWER:
		velocity.y = -MIN_JUMP_POWER

func input_air_dash(input):
	if Input.is_action_just_pressed("jump") && double_jump > 0 && input != Vector2(0,0):
		is_dashing = true
		
		dash_timer.start()
		ghost_timer.start()
		instance_ghost()
		
		dash_direction = input * AIR_DASH_POWER
		double_jump -= 1
		player_camera.apply_noise_shake()
		dash_sound.play()
		

func buffer_jump():
	if Input.is_action_just_pressed("jump"):
		buffered_jump = true
		jump_buffer_timer.start()

func fast_fall(delta):
	if velocity.y > -30:
		velocity.y += FAST_FALL_SPEED * delta

func input_jump():
	if Input.is_action_just_pressed("jump") || buffered_jump:
		velocity.y = -MAX_JUMP_POWER
		buffered_jump = false
		jump_sound.play()
		
func input_wall_jump():
	if Input.is_action_just_pressed("jump"):
		if right_wall_check.is_colliding():
			velocity.x = -WALL_JUMP_PUSH # Move from right wall go left
			velocity.y = -WALL_JUMP_POWER
	
		elif left_wall_check.is_colliding():
			velocity.x = WALL_JUMP_PUSH # Move from left wall go right
			velocity.y = -WALL_JUMP_POWER
		
		
		jump_sound.play()

func enable_coyote_jump(just_left_ground):
	if just_left_ground && velocity.y >= 0:
		coyote_jump = true
		coyote_jump_timer.start()

func is_moving_horizontally(input):
	return input.x != 0

func is_on_wall():
	return left_wall_check.is_colliding() || right_wall_check.is_colliding()

func reset_air_dash():
	double_jump = DOUBLE_JUMPS_COUNT

func can_jump():
	return is_on_floor() || coyote_jump == true

func handle_animation():
	# Character is dead,
	if animation_player.current_animation == "death": return
	
	# Character is idle
	if velocity.x == 0 && velocity.y == 0 && is_on_floor() && is_landed && !is_crouching:
		if Input.is_action_pressed("move_down"):
			animation_player.play("crouch")
			is_crouching = true
			
		elif num_blinks < 5 && !is_blinking:
			animation_player.play("idle")
		else:
			is_blinking = true
			animation_player.play("blink")
			
	if is_crouching && Input.is_action_just_released("move_down"):
		animation_player.play("uncrouch")
	
	# Character is going right
	if velocity.x != 0 && velocity.y == 0:
		
		if abs(velocity.x) == MAX_SPEED:
			animation_player.play("run (copy) 0.7 (copy)")
		else:
			animation_player.play("walk")
		
		# Character is going left
		player_sprite.flip_h = velocity.x < 0

	# Character is jumping 
	if velocity.y < -3:
		animation_player.play("jump (rising)")
		is_landed = false
		
		# Turn the character mid-air
		player_sprite.flip_h = velocity.x < 0
	
	if velocity.y > -3 && velocity.y <= -1:
		animation_player.play("jump (peak)")
		player_sprite.flip_h = velocity.x < 0
	
		# Character is falling 
	if velocity.y > 0:
		animation_player.play("falling")

		# Turn the character mid-air
		player_sprite.flip_h = velocity.x < 0

	if velocity.x == 0 && velocity.y == 0 && is_on_floor() && !is_landed:
		animation_player.play("landing")

func connect_camera(camera):
	var carmera_path = camera.get_path()
	remote_transform_2D.remote_path = carmera_path

func instance_ghost():
	var ghost: Sprite = ghost_scene.instance()
	get_parent().get_parent().add_child(ghost)
	
	ghost.global_position = global_position
	ghost.texture = player_sprite.texture
	ghost.vframes = player_sprite.vframes
	ghost.hframes = player_sprite.hframes
	ghost.frame = player_sprite.frame
	ghost.flip_h = player_sprite.flip_h

func is_air_dash_enabled():
	return air_dash_enabled

func set_air_dash(toggle):
	air_dash_enabled = toggle

func increment_air_dash():
	double_jump += 1;

func apply_jump_force(force):
	velocity.y = -force

func _on_JumpBufferTimer_timeout():
	buffered_jump = false

func _on_CoyoteJumpTimer_timeout():
	coyote_jump = false

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "landing":
		is_landed = true
	if anim_name == "uncrouch":
		is_crouching = false
	if anim_name == "idle":
		num_blinks += 1
	if anim_name == "blink":
		num_blinks = 0
		is_blinking = false
	if anim_name == "death":
		queue_free()
		Events.emit_signal("player_died")
		is_dead = false

func _on_GhostTimer_timeout():
	instance_ghost()

func _on_DashTimer_timeout():
	is_dashing = false
	ghost_timer.stop()
