class_name DistractionTool
extends BaseTool

const PULSE_SCENE: PackedScene = preload("res://scenes/distraction_pulse.tscn")

var _valid_area: Rect2
var _effects_parent: Node2D


func configure(valid_area: Rect2, effects_parent: Node2D) -> void:
	_valid_area = valid_area
	_effects_parent = effects_parent


func activate(target: Vector2) -> void:
	if not _valid_area.has_point(target) or _effects_parent == null:
		return

	var pulse: DistractionPulse = PULSE_SCENE.instantiate() as DistractionPulse
	_effects_parent.add_child(pulse)
	pulse.global_position = target
