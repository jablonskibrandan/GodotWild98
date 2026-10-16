class_name FlashlightTool
extends BaseTool

signal state_changed(is_enabled: bool)

@export_range(1.0, 1000.0, 1.0) var beam_length: float = 120.0
@export_range(1.0, 89.0, 1.0) var half_angle_degrees: float = 28.0
@export_range(4, 128, 1) var beam_segments: int = 28

@export_group("Audio")
## Plays when the flashlight turns on.
@export var on_sound: AudioStream
## Plays when the flashlight turns off. Leave empty to reuse the on sound.
@export var off_sound: AudioStream
@export_range(-40.0, 12.0, 0.1, "suffix:dB") var sound_volume_db: float = 0.0
## Random pitch change per click (0.05 = +/-5%) so repeats don't sound identical.
@export_range(0.0, 0.5, 0.01) var pitch_variation: float = 0.0

var enabled: bool = false
var _player: PlayerController
var _cursor: TargetCursor
var _sfx: AudioStreamPlayer


func _ready() -> void:
	_sfx = AudioStreamPlayer.new()
	_sfx.name = "ToggleSound"
	_sfx.bus = &"SFX"
	add_child(_sfx)


func configure(player: PlayerController, cursor: TargetCursor) -> void:
	_player = player
	_cursor = cursor


func activate(_target: Vector2) -> void:
	toggle()


func toggle() -> void:
	enabled = not enabled
	state_changed.emit(enabled)
	queue_redraw()
	_play_toggle_sound()


func _play_toggle_sound() -> void:
	var stream: AudioStream = on_sound
	if not enabled and off_sound != null:
		stream = off_sound
	if stream == null or _sfx == null:
		return
	_sfx.stream = stream
	_sfx.volume_db = sound_volume_db
	_sfx.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	_sfx.play()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("flashlight_toggle"):
		toggle()
		_player.flashlight_power(enabled)
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if enabled:
		queue_redraw()


func _draw() -> void:
	if not enabled or _player == null or _cursor == null:
		return

	var origin: Vector2 = to_local(_player.flashlight_sprite.global_position)
	var aim: Vector2 = to_local(_cursor.global_position) - origin
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
