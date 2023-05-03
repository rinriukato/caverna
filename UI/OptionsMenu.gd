extends Control

var color = Color(0.05, 0.03, 0.11)

func _ready():
	VisualServer.set_default_clear_color(color)
