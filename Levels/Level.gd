extends Node2D

const PlayerScene = preload("res://Player/Miku.tscn")

var player_spawn_location = Vector2.ZERO
var color = Color(0.05, 0.03, 0.11)
onready var camera: = $PlayerCamera
onready var player: = $Miku
onready var respawn_timer: = $RespawnTimer

func _ready():
	VisualServer.set_default_clear_color(color)
	player_spawn_location = player.global_position
	player.connect_camera(camera)
# warning-ignore:return_value_discarded
	Events.connect("player_died", self, "_on_player_died")
	
	var context = get_tree().get_current_scene().get_name()
	if context == "Level1":
		MusicPlayer.play_level_one_music()
	if context == "Level4":
		MusicPlayer.stop_level_one_music()
		MusicPlayer.play_level_two_music()
	
func _on_player_died():
	respawn_timer.start(1.0)
	yield(respawn_timer, "timeout")
	
# warning-ignore:shadowed_variable
	var player = PlayerScene.instance()
	
	player.global_position = player_spawn_location
	add_child(player)
	player.connect_camera(camera)
