extends CanvasLayer

onready var animation_player = $AnimationPlayer

signal transition_completed

func play_exit_transition():
	animation_player.play("ExitLevel")
	
func play_enter_transition():
	animation_player.play("EnterLevel")

func _on_AnimationPlayer_animation_finished(anim_name):
	emit_signal("transition_completed")
