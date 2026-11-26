extends Control

signal start_pressed
signal settings_pressed

@onready var play_button: Button = $CenterContainer/VBoxContainer/Button2
@onready var settings_button: Button = $CenterContainer/VBoxContainer/Button3
@onready var exit_button: Button = $CenterContainer/VBoxContainer/Button4


func _ready() -> void:
	play_button.pressed.connect(start_pressed.emit)
	settings_button.pressed.connect(settings_pressed.emit)
	exit_button.pressed.connect(get_tree().quit)
