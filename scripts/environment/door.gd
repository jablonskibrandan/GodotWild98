class_name Door
extends Area2D

## Emitted when the player uses a key on this door, just before it's removed.
signal unlocked

func _on_body_entered(body: Node2D):
	if body is PlayerController:
		var player_keys := body.get_node_or_null("Keys") as PlayerKeys
		if player_keys != null:
			var door_opened = player_keys.use_key()
			if door_opened:
				unlocked.emit()
				queue_free()
			
