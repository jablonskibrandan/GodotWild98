class_name FlashlightTool
extends BaseTool

signal state_changed(is_enabled: bool)

@export_range(1.0, 1000.0, 1.0) var beam_length: float = 260.0
@export_range(1.0, 89.0, 1.0) var half_angle_degrees: float = 28.0
@export_range(4, 128, 1) var beam_segments: int = 28

var enabled: bool = false
var _player: PlayerController
var _cursor: TargetCursor


func configure(player: PlayerController, cursor: TargetCursor) -> void:
	_player = player
	_cursor = cursor


func activate(_target: Vector2) -> void:
	toggle()


func toggle() -> void:
	enabled = not enabled
	state_changed.emit(enabled)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("flashlight_toggle"):
		toggle()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if enabled:
		queue_redraw()


func _draw() -> void:
	if not enabled or _player == null or _cursor == null:
		return

	var origin: Vector2 = to_local(_player.global_position)
	var aim: Vector2 = to_local(_cursor.global_position) - origin
	if aim.length_squared() < 0.01:
		aim = Vector2.RIGHT
	var center_angle: float = aim.angle()

	var beam_points := PackedVector2Array([origin])
	for i in range(beam_segments + 1):
		var fraction: float = float(i) / float(beam_segments)
		var angle: float = center_angle + deg_to_rad(lerpf(-half_angle_degrees, half_angle_degrees, fraction))
		beam_points.append(origin + Vector2.RIGHT.rotated(angle) * beam_length)

	draw_colored_polygon(beam_points, Color(1.0, 0.91, 0.39, 0.21))
	draw_line(origin, beam_points[1], Color(1.0, 0.91, 0.39, 0.38), 1.0)
	draw_line(origin, beam_points[beam_points.size() - 1], Color(1.0, 0.91, 0.39, 0.38), 1.0)
