class_name Stairs
extends Area2D

const base_floor: String = "res://scenes/floors/base_floor.tscn"

func _on_body_entered(_body: Node2D):
	get_tree().change_scene_to_file.call_deferred(base_floor)
