extends AudioStreamPlayer2D
## Plays when the player collects this pickup. Put this node under the pickup
## (e.g. AirBubbles). The pickup deletes itself on collection, so this node
## moves out of it first, plays where the pickup was, and removes itself when
## the sound has finished.

## The Area2D on the pickup that detects the player.
@export var area_path: NodePath = ^"../Area2D"
## Only bodies that have a child with this name count as "the player".
@export var player_marker_node: String = "Bubble_Health"

var _played := false


func _ready() -> void:
	var area := get_node_or_null(area_path) as Area2D
	if area == null:
		push_warning("PickupSound: Area Path doesn't point to an Area2D.")
		return
	area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _played or stream == null or not body.has_node(player_marker_node):
		return
	_played = true
	# Deferred: this runs inside a physics callback, where moving nodes is unsafe.
	_detach_and_play.call_deferred()


func _detach_and_play() -> void:
	var pickup := get_parent()
	var new_parent := pickup.get_parent() if pickup != null else null
	if new_parent == null:
		return
	reparent(new_parent)  # keeps its position where the pickup was
	finished.connect(queue_free)
	play()
