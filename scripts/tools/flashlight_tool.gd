class_name FlashlightTool
extends BaseTool

signal state_changed(is_enabled: bool)

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
	_player.toolUsed(self)


func toggle() -> void:
	enabled = not enabled
	state_changed.emit(enabled)
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
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if enabled:
		queue_redraw()


func _draw() -> void:
	if not enabled or _player == null or _cursor == null:
		return

	
