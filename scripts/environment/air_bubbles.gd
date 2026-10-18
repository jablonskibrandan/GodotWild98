class_name AirBubbles
extends Node2D


func _on_area_2d_body_entered(body: Node2D) -> void:
	if(body.has_node("Bubble_Health")):
		var breath = body.get_node("Bubble_Health")
		print("breathing is found.")
		breath.take_breath(3)
		self.queue_free()
	pass # Replace with function body.
