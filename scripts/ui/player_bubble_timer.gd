extends Node2D
## World-space oxygen countdown that follows the player's head.
## Reads the BubbleHealth timer; never modifies oxygen itself.

@export var bubble_health_path: NodePath = ^"../Bubble_Health"

@onready var bubble_sprite: Sprite2D = $BubbleSprite
@onready var seconds_label: Label = $SecondsLabel

var _health: BubbleHealth
var _bubble_material: ShaderMaterial


func _ready() -> void:
	_health = get_node_or_null(bubble_health_path) as BubbleHealth
	_bubble_material = bubble_sprite.material as ShaderMaterial
	if _health == null or _bubble_material == null:
		push_warning("PlayerBubbleTimer needs a BubbleHealth and a shader material.")
		visible = false
		set_process(false)
		return
	_update_timer()


func _process(_delta: float) -> void:
	_update_timer()


func _update_timer() -> void:
	var active: bool = _health.bubble_current_time > 0.0
	visible = active
	if not active:
		return

	var seconds_left: float = _health.get_active_bubble_time_left()
	_bubble_material.set_shader_parameter("oxygen_remaining", _health.get_active_bubble_fraction())
	var text_seconds: String = str(ceili(seconds_left))
	if seconds_label.text != text_seconds:
		seconds_label.text = text_seconds
