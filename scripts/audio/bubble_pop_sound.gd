extends AudioStreamPlayer
## Plays a bubble pop every time the player loses a bubble (oxygen running
## down, a monster bite or a mine hit). Put this node under the Player, next to
## Bubble_Health.
##
## The Stream is audio/sfx/bubble_pop.tres, an AudioStreamRandomizer holding
## the bubble takes. Open it to add/remove takes or change the pitch range.

@export var bubble_health_path: NodePath = ^"../Bubble_Health"
## When several bubbles pop at once (e.g. a mine hit), seconds between pops.
@export_range(0.0, 0.5, 0.01, "suffix:s") var stagger: float = 0.07

var _health: BubbleHealth
var _last_amount := 0


func _ready() -> void:
	_health = get_node_or_null(bubble_health_path) as BubbleHealth
	if _health == null:
		push_warning("BubblePopSound: Bubble Health Path doesn't point to a BubbleHealth node.")
		return
	_last_amount = _health.bubble_amount
	_health.bubble_amount_changed.connect(_on_bubble_amount_changed)


func _on_bubble_amount_changed(amount: int) -> void:
	var lost := _last_amount - amount
	_last_amount = amount
	for i in lost:
		if i > 0 and stagger > 0.0:
			await get_tree().create_timer(stagger).timeout
			if not is_inside_tree():
				return
		play()
