extends Node

onready var death_sound = $AudioPlayers/DeathSound

func play_death_sound():
	death_sound.play()
