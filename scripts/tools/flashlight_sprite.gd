class_name FlashlightSprite
extends Sprite2D

@export_range(1.0, 1000.0, 1.0) var beam_length: float = 100.0
@export_range(1.0, 89.0, 1.0) var half_angle_degrees: float = 28.0
@export_range(4, 128, 1) var beam_segments: int = 28

@onready var flashlight_point_left : Node2D = $Flashlight_Point_Left
@onready var flashlight_point_right : Node2D = $Flashlight_Point_Right
@onready var flashlight_light : Node2D = $FlashlightLights

var enabled : bool = false
var cursor_position : Vector2 = Vector2.ZERO

func _ready():
	cursor_position = global_position

#points where monsters can see flashlight beam
func get_flashlight_points() -> Array[Vector2]: 
	if enabled:
		var p0:= global_position
		var p1:= flashlight_point_left.global_position
		var p2:= flashlight_point_right.global_position
		return [(p0+p1+p2)/3.0,
				p0.lerp(p1, 0.5), p0.lerp(p2, 0.5), p1.lerp(p2, 0.5),
				p1, p2]
	else:
		return []

func toggle(_enabled: bool):
	enabled = _enabled
	if enabled:
		frame = 1
		flashlight_light.visible = true
	else:
		frame = 0
		flashlight_light.visible = false
	queue_redraw()

func update_facing(facing_animation : String):
	if facing_animation == "down":
		show_behind_parent = false
		position.x = 6
		position.y = 6
	elif facing_animation == "up":
		show_behind_parent = true
		position.x = -6
		position.y = 4
	elif facing_animation == "right":
		show_behind_parent = true
		position.x = 0
		position.y = 3
	elif facing_animation == "left":
		show_behind_parent = false
		position.x = 0
		position.y = 3
	
	queue_redraw()

func update_cursor(_cursor_position : Vector2):
	cursor_position = _cursor_position
	var direction: Vector2 = global_position.direction_to(cursor_position)
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	rotation = direction.angle()

func _draw() -> void:
	if enabled:
		var origin: Vector2 = to_local(global_position)
		var aim: Vector2 = to_local(cursor_position) - origin
		if aim.length_squared() < 0.01:
			aim = Vector2.RIGHT
		var center_angle: float = aim.angle()

		var beam_points := PackedVector2Array([origin])
		for i in range(beam_segments + 1):
			var fraction: float = float(i) / float(beam_segments)
			var angle: float = center_angle + deg_to_rad(lerpf(-half_angle_degrees, half_angle_degrees, fraction))
			beam_points.append(origin + Vector2.RIGHT.rotated(angle) * beam_length)

		draw_colored_polygon(beam_points, Color(1.0, 0.91, 0.39, 0.139))
		draw_line(origin, beam_points[1], Color(1.0, 0.91, 0.39, 0.247), 1.0)
		draw_line(origin, beam_points[beam_points.size() - 1], Color(1.0, 0.91, 0.39, 0.38), 1.0)
