extends Node

onready var level_1 = $LevelMusic/Level1
onready var level_2 = $LevelMusic/Level2


func play_level_one_music():
	level_1.play()

func stop_level_one_music():
	level_1.stop()

func play_level_two_music():
	level_2.play()
	
func stop_level_two_music():
	level_2.stop()
