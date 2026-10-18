extends AudioStreamPlayer
## Plays when a button is pressed, even if the press loads a new scene right
## away (Play / Retry). It moves itself to the top of the game first, so the
## scene change doesn't cut it off, then removes itself when finished.
## Uses the "UI" bus so menu sounds skip the SFX reverb and filter.

## The button that triggers the sound.
@export var button_path: NodePath

var _root: Node
var _played := false


func _ready() -> void:
	_root = get_tree().root
	var button := get_node_or_null(button_path) as BaseButton
	if button == null:
		push_warning("ButtonSound: Button Path doesn't point to a button.")
		return
	button.pressed.connect(_on_pressed)


func _on_pressed() -> void:
	if _played or stream == null:
		return
	_played = true
	reparent(_root)
	finished.connect(queue_free)
	play()
