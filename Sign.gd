extends Node

export (String) var text = ""

onready var popup_dialog = $Textbox/PopupDialog
onready var dialouge = $Textbox/PopupDialog/RichTextLabel
onready var text_scroll = $Textbox/Textscroll
onready var hovering_sprite = $HoveringSprite

var can_read = false

func _ready():
	dialouge.bbcode_text = text

func _process(_delta):
	if can_read && Input.is_action_just_pressed("ui_accept"):
		popup_dialog.visible = true
		hovering_sprite.visible = false
		text_scroll.play("textscroll")
		
func _on_Area2D_body_entered(body):
	if body is Player:
		can_read = true
		hovering_sprite.visible = true

func _on_Area2D_body_exited(body):
	if body is Player:
		can_read = false
		popup_dialog.visible = false
		text_scroll.stop()
		hovering_sprite.visible = false
