class_name DoorKey
extends Area2D

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var point_light_2d = $PointLight2D

func _ready():
	animated_sprite_2d.material = material
	animated_sprite_2d.light_mask = light_mask
	animated_sprite_2d.visibility_layer = visibility_layer
	
	point_light_2d.enabled = visibility_layer == 1

func _on_body_entered(body: Node2D):
	if body is PlayerController:
		var player_keys := body.get_node_or_null("Keys") as PlayerKeys
		if player_keys != null:
			player_keys.add_key()
			queue_free()
