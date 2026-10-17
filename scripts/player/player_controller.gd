class_name PlayerController
extends CharacterBody2D


@export_range(1.0, 1000.0, 1.0) var move_speed: float = 100.0
#@export_range(1.0, 100.0, 1.0) var radius: float = 15.0

var _movement_bounds: Rect2
var _cursor: TargetCursor
var input_direction : Vector2 = Vector2.ZERO
var facing_animation : String = "down"
var cursor_direction : Vector2 = Vector2.DOWN

@onready var sprite = $AnimatedSprite2D
@onready var flashlight_sprite = $FlashlightSprite

func _process(_delta: float) -> void:
	animate()

func animate() -> void:
	if input_direction == Vector2.ZERO:
		sprite.play("idle_"+facing_animation)
	else:
		sprite.play(facing_animation)

func take_hit() -> void:
	var hit_tween = get_tree().create_tween()
	hit_tween.tween_method(set_shader_value, 1, 2, .2)
	hit_tween.tween_method(set_shader_value, 2, 1, .2)
	return
	

func set_shader_value(value: float) -> void:
	$AnimatedSprite2D.material.set_shader_parameter("progress", value)
	return


func configure(bounds: Rect2, cursor: TargetCursor) -> void:
	_movement_bounds = bounds
	_cursor = cursor

func toolUsed(tool = BaseTool) -> void:
	if (tool is DistractionTool):
		$Timers/DistractionSignal_Timer.start()
	return

func get_time_left(tool = BaseTool) -> float:
	var timeLeft
	if (tool is DistractionTool):
		timeLeft = $Timers/DistractionSignal_Timer.time_left
	return timeLeft


func _physics_process(_delta: float) -> void:
	var direction: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_up", "move_down"
	)
	
	if direction != Vector2.ZERO:
		update_facing(direction)
		velocity = direction * move_speed
		move_and_slide()
		#global_position = Vector2(
			#clampf(global_position.x, _movement_bounds.position.x + radius, _movement_bounds.end.x - radius),
			#clampf(global_position.y, _movement_bounds.position.y + radius, _movement_bounds.end.y - radius)
		#)
	
	input_direction = direction
	
	update_cursor()
	if facing_animation == "down":
		flashlight_sprite.show_behind_parent = false
		flashlight_sprite.position.x = 6
		flashlight_sprite.position.y = 6
	elif facing_animation == "up":
		flashlight_sprite.show_behind_parent = true
		flashlight_sprite.position.x = -6
		flashlight_sprite.position.y = 4
	elif facing_animation == "right":
		flashlight_sprite.show_behind_parent = true
		flashlight_sprite.position.x = 0
		flashlight_sprite.position.y = 3
	elif facing_animation == "left":
		flashlight_sprite.show_behind_parent = false
		flashlight_sprite.position.x = 0
		flashlight_sprite.position.y = 3
	flashlight_sprite.rotation = cursor_direction.angle()

func update_facing(direction: Vector2):
	if direction == Vector2.ZERO:
		return
	elif direction == Vector2.RIGHT:
		facing_animation = "right"
	elif direction == Vector2.LEFT:
		facing_animation = "left"
	elif direction == Vector2.UP:
		facing_animation = "up"
	elif direction == Vector2.DOWN:
		facing_animation = "down"
	#up/down plus left/right defaults to left/right, unless already facing one of the directions
	elif (direction.x > 0 
		&& facing_animation != "up" && facing_animation != "down"):
		facing_animation = "right"
	elif (direction.x < 0 
		&& facing_animation != "up" && facing_animation != "down"):
		facing_animation = "left"
	

func update_cursor():
	if _cursor == null:
		return
	var direction: Vector2 = to_local(_cursor.global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	
	cursor_direction = direction

func flashlight_power(on: bool):
	if on:
		flashlight_sprite.frame = 1
	else:
		flashlight_sprite.frame = 0

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
