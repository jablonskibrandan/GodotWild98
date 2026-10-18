class_name AirBubbles
extends Node2D

@onready var animated_sprite_2d_1 = $AnimatedSprite2D_1
@onready var animated_sprite_2d_2 = $AnimatedSprite2D_2
@onready var animated_sprite_2d_3 = $AnimatedSprite2D_3

func _ready():
	animated_sprite_2d_1.material = material
	animated_sprite_2d_1.light_mask = light_mask
	animated_sprite_2d_1.visibility_layer = visibility_layer
	
	animated_sprite_2d_2.material = material
	animated_sprite_2d_2.light_mask = light_mask
	animated_sprite_2d_2.visibility_layer = visibility_layer
	
	animated_sprite_2d_3.material = material
	animated_sprite_2d_3.light_mask = light_mask
	animated_sprite_2d_3.visibility_layer = visibility_layer

func _on_area_2d_body_entered(body: Node2D) -> void:
	if(body.has_node("Bubble_Health")):
		var breath = body.get_node("Bubble_Health")
		#print("breathing is found.")
		breath.take_breath(3)
		self.queue_free()
	pass # Replace with function body.
