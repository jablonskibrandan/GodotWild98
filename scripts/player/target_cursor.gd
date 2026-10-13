class_name TargetCursor
extends Node2D

signal target_moved(target: Vector2)

@export_range(4.0, 48.0, 1.0) var square_size: float = 22.0

@export var target_color: Color = Color("#ffe27a")


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_update_position()


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(_delta: float) -> void:
	_update_position()


func set_target_color(color: Color) -> void:
	target_color = color
	queue_redraw()


func _update_position() -> void:
	var next_position: Vector2 = get_global_mouse_position()
	if global_position == next_position:
		return
	global_position = next_position
	target_moved.emit(global_position)
	queue_redraw()


func _draw() -> void:
	var half_size := Vector2.ONE * square_size * 0.5
	draw_rect(Rect2(-half_size, Vector2.ONE * square_size), target_color, false, 2.0)
	draw_circle(Vector2.ZERO, 1.0, target_color)
