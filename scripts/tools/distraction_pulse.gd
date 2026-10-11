class_name DistractionPulse
extends Node2D

@export_range(0.1, 20.0, 0.1) var duration: float = 2.0
@export_range(1.0, 500.0, 1.0) var max_radius: float = 95.0
@export_range(1.0, 100.0, 1.0) var volume: float = 50.0

var _elapsed: float = 0.0


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var progress: float = _elapsed / duration
	var color := Color(0.25, 0.88, 1.0, 1.0 - progress)
	draw_circle(Vector2.ZERO, 7.0, color)
	draw_arc(Vector2.ZERO, 10.0 + max_radius * progress, 0.0, TAU, 64, color, 3.0, true)
