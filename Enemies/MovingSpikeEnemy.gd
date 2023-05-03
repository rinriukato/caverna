tool #enable using functions in editor
extends Path2D

enum ANIMATION_TYPE {
	LOOP,
	BOUNCE
}

export (ANIMATION_TYPE) var animation_type setget set_animation_type
export (float) var speed = 1.0 setget set_speed

onready var animation_player: = $AnimationPlayer

func _ready():
	play_updated_animation(animation_player)

func set_animation_type(value):
	animation_type = value
	
func set_speed(value):
	speed = value
	var ap = find_node("AnimationPlayer")
	if ap: ap.playback_speed = speed

func play_updated_animation(ap):
	match animation_type:
		ANIMATION_TYPE.LOOP: ap.play("MoveAlongPathLoop")
		ANIMATION_TYPE.BOUNCE: ap.play("MoveAlongPathBounce")
