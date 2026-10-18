extends TextureRect
## Displays the real cooldown of a Player Timer on top of a tool icon.
## The timer is authoritative: this node does not start or modify it.

@export var cooldown_timer_path: NodePath

@onready var countdown_label: Label = $CooldownText

var _cooldown_timer: Timer
var _cooldown_material: ShaderMaterial


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cooldown_timer = get_node_or_null(cooldown_timer_path) as Timer
	_cooldown_material = material as ShaderMaterial
	if _cooldown_timer == null or _cooldown_material == null:
		push_warning("ToolCooldownIndicator needs a valid Timer path and ShaderMaterial: " + str(get_path()))
		countdown_label.hide()
		set_process(false)
		return
	_update_cooldown()


func _process(_delta: float) -> void:
	_update_cooldown()


func _update_cooldown() -> void:
	var seconds_left: float = _cooldown_timer.time_left
	var on_cooldown: bool = not _cooldown_timer.is_stopped() and seconds_left > 0.0
	var fraction_left: float = 0.0
	if on_cooldown and _cooldown_timer.wait_time > 0.0:
		fraction_left = clampf(seconds_left / _cooldown_timer.wait_time, 0.0, 1.0)

	_cooldown_material.set_shader_parameter("cooldown_remaining", fraction_left)
	countdown_label.visible = on_cooldown
	if on_cooldown:
		var new_text: String = str(ceili(seconds_left))
		if countdown_label.text != new_text:
			countdown_label.text = new_text
