class_name Stairs
extends Area2D

const base_floor: String = "res://scenes/floors/base_floor.tscn"

@onready var sprite_2d = $Sprite2D
@onready var point_light_2d = $PointLight2D

func _ready():
	sprite_2d.material = material
	sprite_2d.light_mask = light_mask
	sprite_2d.visibility_layer = visibility_layer
	
	point_light_2d.enabled = visibility_layer == 1

func _on_body_entered(_body: Node2D):
	get_tree().change_scene_to_file.call_deferred(base_floor)
