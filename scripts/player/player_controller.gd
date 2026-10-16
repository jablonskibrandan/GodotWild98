class_name PlayerController
extends CharacterBody2D

@export_range(1.0, 1000.0, 1.0) var move_speed: float = 100.0
#@export_range(1.0, 100.0, 1.0) var radius: float = 15.0

var _movement_bounds: Rect2
var _cursor: TargetCursor
var facing_direction : String = "down"
@onready var sprite = $AnimatedSprite2D

func _get_facing() -> Vector2:

	var combined_angle : float
	var facing_vector : Vector2 = Input.get_vector(
		"move_left", "move_right", "move_up", "move_down"
	)

	if facing_vector == Vector2.ZERO:
		return Vector2.ZERO
	combined_angle = snappedf(facing_vector.angle(),PI/4)
	facing_vector = Vector2(cos(combined_angle),sin(combined_angle))
	
	return facing_vector

func _animate(vector: Vector2 = Vector2.ZERO):

	if vector == Vector2.ZERO:
		sprite.play("idle_"+facing_direction)
		return

	var snapped_vector = Vector2(snapped(cos(vector.angle()),1),snapped(sin(vector.angle()),1))
	var prev_dir = facing_direction
	if snapped_vector.y < 0:
		facing_direction = "up"
	elif snapped_vector.y > 0:
		facing_direction = "down"
	if snapped_vector.x > 0:
		facing_direction = "right"
	elif snapped_vector.x < 0:
		facing_direction = "left"
	if (snapped_vector.x != 0) && (snapped_vector.y != 0):
		if prev_dir == "down" && snapped_vector.y < 0:
			sprite.play(facing_direction)
			return
		if prev_dir == "up" && snapped_vector.y > 0:
			sprite.play(facing_direction)
			return
		if prev_dir == "left" && snapped_vector.x > 0:
			sprite.play(facing_direction)
			return
		if prev_dir == "right" && snapped_vector.x < 0:
			sprite.play(facing_direction)
			return
		sprite.play(prev_dir)
		facing_direction = prev_dir
		return
	sprite.play(facing_direction)

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

	_animate(_get_facing())
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
