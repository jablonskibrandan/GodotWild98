extends AudioStreamPlayer2D
## Plays when the parent node emits a signal (e.g. a Door's "unlocked"), even
## if the parent deletes itself right after. This node moves out of the parent
## first, plays where it was, and removes itself when the sound has finished.

## Name of the parent's signal that triggers the sound.
@export var trigger_signal: StringName = &"unlocked"
## Random pitch change per play (0.05 = +/-5%).
@export_range(0.0, 0.5, 0.01) var pitch_variation: float = 0.0

var _played := false


func _ready() -> void:
	var owner_node := get_parent()
	if owner_node == null or not owner_node.has_signal(trigger_signal):
		push_warning("DetachingSound: parent has no '%s' signal." % trigger_signal)
		return
	owner_node.connect(trigger_signal, _on_trigger)


func _on_trigger() -> void:
	if _played or stream == null:
		return
	_played = true
	# Deferred: this usually fires inside a physics callback.
	_detach_and_play.call_deferred()


func _detach_and_play() -> void:
	var owner_node := get_parent()
	var new_parent := owner_node.get_parent() if owner_node != null else null
	if new_parent == null:
		return
	reparent(new_parent)  # keeps its position where the parent was
	pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	finished.connect(queue_free)
	play()
