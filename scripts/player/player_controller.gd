class_name PlayerController
extends CharacterBody2D

@export_range(1.0, 1000.0, 1.0) var move_speed: float = 100.0
#@export_range(1.0, 100.0, 1.0) var radius: float = 15.0

var _movement_bounds: Rect2
var _cursor: TargetCursor


func configure(bounds: Rect2, cursor: TargetCursor) -> void:
	_movement_bounds = bounds
	_cursor = cursor


func _physics_process(_delta: float) -> void:
	var direction: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_up", "move_down"
	)
	if direction != Vector2.ZERO:
		velocity = direction * move_speed
		move_and_slide()
		#global_position = Vector2(
			#clampf(global_position.x, _movement_bounds.position.x + radius, _movement_bounds.end.x - radius),
			#clampf(global_position.y, _movement_bounds.position.y + radius, _movement_bounds.end.y - radius)
		#)

	# The aiming line also changes when the mouse moves without player movement.
	queue_redraw()


func _draw() -> void:
	pass
	#draw_circle(Vector2.ZERO, radius, Color("#ebf2ff"))
	#draw_circle(Vector2.ZERO, radius * 0.6, Color("#5d87c9"))
#
	#if _cursor == null:
		#return
	#var direction: Vector2 = to_local(_cursor.global_position).normalized()
	#if direction == Vector2.ZERO:
		#direction = Vector2.RIGHT
	#draw_line(Vector2.ZERO, direction * (radius + 10.0), Color("#eaf2ff"), 3.0)
