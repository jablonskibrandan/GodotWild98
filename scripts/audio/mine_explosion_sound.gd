extends AudioStreamPlayer2D
## Plays the explosion when this mine kills a monster. Put this node under the
## NavalMine. The mine deletes itself the moment it explodes, so this node
## moves out of the mine first, plays where the mine was, and removes itself
## when the sound has finished.

## Also play the explosion when the mine goes off on the player.
@export var play_on_player_hit: bool = false
## Random pitch change per explosion (0.05 = +/-5%).
@export_range(0.0, 0.5, 0.01) var pitch_variation: float = 0.05


func _ready() -> void:
	var mine := get_parent()
	if mine != null and mine.has_signal("exploded"):
		mine.exploded.connect(_on_mine_exploded)


func _on_mine_exploded(mine: Node2D, target: Node2D) -> void:
	var killed_monster := target is BaseMonster
	var hit_player := target is PlayerController
	if not killed_monster and not (play_on_player_hit and hit_player):
		return
	var new_parent := mine.get_parent()
	if new_parent == null or stream == null:
		return
	reparent(new_parent)  # keeps its position where the mine was
	pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	finished.connect(queue_free)
	play()
