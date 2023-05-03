extends Control

var color = Color(0.05, 0.03, 0.11)

func _ready():
	$VBoxContainer/StartButton.grab_focus()
	VisualServer.set_default_clear_color(color)

func _on_OptionsButton_pressed():
	pass # Replace with function body.

func _on_QuitButton_pressed():
	get_tree().quit()

func _on_StartButton_pressed():
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://Levels/Level1.tscn")
