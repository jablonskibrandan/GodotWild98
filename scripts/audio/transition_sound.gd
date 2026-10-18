extends AudioStreamPlayer
## Plays when something enters the parent Area2D (e.g. the Stairs) and keeps
## playing through the level change that follows. It moves itself to the top
## of the game (next to MusicManager), so loading the next floor doesn't cut
## it off, then removes itself once the sound has finished.

var _root: Node
var _played := false


func _ready() -> void:
	_root = get_tree().root
	var area := get_parent() as Area2D
	if area == null:
		push_warning("TransitionSound: parent must be an Area2D.")
		return
	area.body_entered.connect(_on_body_entered)


func _on_body_entered(_body: Node2D) -> void:
	# Mirrors the Stairs: any body entering triggers the floor change.
	if _played or stream == null:
		return
	_played = true
	reparent(_root)
	finished.connect(queue_free)
	play()
