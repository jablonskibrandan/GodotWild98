class_name EndScreen
extends Control

@export_category("Buttons")

@export var quit_button: Button


func _ready() -> void:
	quit_button.pressed.connect(_on_quit_button_pressed)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
