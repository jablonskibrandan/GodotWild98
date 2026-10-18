class_name DoorKey
extends Area2D

func _on_body_entered(body: Node2D):
	if body is PlayerController:
		var player_keys := body.get_node_or_null("Keys") as PlayerKeys
		if player_keys != null:
			player_keys.add_key()
			queue_free()
