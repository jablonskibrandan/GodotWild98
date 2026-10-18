extends Node
## Global music player, registered as the "MusicManager" autoload
## (res://scripts/audio/music_manager.tscn).
##
## Lives above every scene, so a track keeps looping seamlessly when the game
## changes scenes (e.g. Main Menu -> Floor One) instead of restarting.
## Uses two players so tracks can crossfade.
##
## Tension layer: two stems that play in sync with the base track.
##   - Tension Center stays in the middle of the stereo field.
##   - Tension Pan follows the chasing monster left / right.
## Both stay silent until a monster is chasing the player, then come in and
## get louder the closer it gets. When the monster is above or below the
## player, both are low-pass filtered (muffled) to suggest verticality.
## Tune everything in the Inspector by opening music_manager.tscn.
##
## Usage from any script:
##     MusicManager.play(preload("res://audio/music/floor_theme.ogg"))
##     MusicManager.play(some_stream, 2.0)   # 2-second crossfade
##     MusicManager.stop(1.5)                # fade out
##     MusicManager.set_volume(0.8)          # 0.0 - 1.0 (linear)

const MUSIC_BUS := &"Music"
const TENSION_BUS := &"Tension"          # center layer + filter, sends to Music
const TENSION_PAN_BUS := &"TensionPan"   # pan layer + panner, sends to Tension
const SILENT := 0.0001
const OPEN_CUTOFF_HZ := 20000.0
const RESYNC_THRESHOLD := 0.05  # seconds of drift before a layer is re-aligned

## Main loop that starts when the game boots.
@export var base_track: AudioStream
## Overall music level, linear 0..1 (0.5 is about -6 dB).
@export_range(0.0, 1.0, 0.01) var volume: float = 0.5

@export_group("Tension Layer")
## Stem that stays centered. Same length and tempo as the base track.
@export var tension_center: AudioStream
## Stem that pans toward the chasing monster. Same length and tempo as the base track.
@export var tension_pan: AudioStream
## Trim for the centered stem.
@export_range(-24.0, 12.0, 0.1, "suffix:dB") var center_trim_db: float = 0.0
## Trim for the panning stem.
@export_range(-24.0, 12.0, 0.1, "suffix:dB") var pan_trim_db: float = 0.0
## Level of the layer the moment a chase starts, however far away the monster
## is (0..1). The layer only plays while a monster is chasing the player.
@export_range(0.0, 1.0, 0.01) var chase_min_level: float = 0.35
## Chasing monster farther than this (pixels): layer sits at Chase Min Level.
## Closer than this, it starts getting louder.
@export_range(0.0, 2000.0, 1.0, "suffix:px") var tension_start_distance: float = 220.0
## Chasing monster closer than this (pixels): layer is at full level.
@export_range(0.0, 2000.0, 1.0, "suffix:px") var tension_full_distance: float = 60.0
## Level of the tension layer when fully in.
@export_range(-24.0, 12.0, 0.1, "suffix:dB") var tension_max_db: float = 0.0
## Seconds to swell in when the monster closes in (lower = more reactive).
@export_range(0.0, 10.0, 0.05, "suffix:s") var tension_attack: float = 0.75
## Seconds to settle back down when the monster backs off or gives up the
## chase (higher = lingers).
@export_range(0.0, 20.0, 0.05, "suffix:s") var tension_release: float = 3.0

@export_group("Tension Panning")
## How far the pan stem can lean (0 = never pans, 1 = can go fully to one ear).
@export_range(0.0, 1.0, 0.01) var max_pan: float = 0.7
## Horizontal distance (pixels) at which the pan reaches Max Pan.
@export_range(1.0, 1000.0, 1.0, "suffix:px") var pan_distance: float = 100.0
## Seconds for the pan to glide to a new position (higher = smoother).
@export_range(0.0, 2.0, 0.01, "suffix:s") var pan_smoothing: float = 0.25

@export_group("Tension Verticality")
## Cutoff when the monster is fully above or below the player (muffled).
@export_range(100.0, 20000.0, 1.0, "suffix:Hz") var muffled_cutoff_hz: float = 900.0
## Vertical distance (pixels) at which the layer is fully muffled.
## Closer than this, the effect fades out so a monster right on top of you sounds clear.
@export_range(1.0, 1000.0, 1.0, "suffix:px") var muffle_distance: float = 100.0
## Filter resonance (0.5 is neutral; higher adds a peak at the cutoff).
@export_range(0.1, 1.0, 0.01) var filter_resonance: float = 0.5
## Seconds for the filter to move to a new setting.
@export_range(0.0, 2.0, 0.01, "suffix:s") var filter_smoothing: float = 0.3

@export_group("Game Over")
## While this scene is showing, the base loop fades out and only the tension
## layer plays. Leaving it (e.g. Retry) fades the base loop back in.
@export_file("*.tscn") var game_over_scene: String = "res://scenes/death_screen.tscn"
## Tension level on the game over screen (0..1, before Max dB and trims).
@export_range(0.0, 1.0, 0.01) var game_over_tension_level: float = 1.0
## Seconds for the base loop to fade out (and tension to swell) at game over.
@export_range(0.0, 10.0, 0.05, "suffix:s") var game_over_fade: float = 1.5
## Seconds for the base loop to fade back in after Retry.
@export_range(0.0, 10.0, 0.05, "suffix:s") var retry_fade_in: float = 2.0

## Current tension, 0..1 (read-only; handy for debugging or other systems).
var tension: float = 0.0
## Current pan of the pan stem, -1 (left) .. 1 (right). Read-only.
var pan: float = 0.0
## Current low-pass cutoff on the tension layer. Read-only.
var cutoff_hz: float = OPEN_CUTOFF_HZ

var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _tweens: Dictionary = {}

var _center_player: AudioStreamPlayer
var _pan_player: AudioStreamPlayer
var _panner: AudioEffectPanner
var _filter: AudioEffectLowPassFilter
var _tension_bus_idx := -1
var _pan_target := 0.0
var _vertical_target := 0.0
var _tension_stopped := false
var _in_game_over := false

var _player_node: Node2D
var _monsters: Array[Node] = []
var _scan_timer := 0.0


func _ready() -> void:
	# Keep the music going while the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS

	var bus := _music_bus()
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.name = "MusicPlayer%d" % i
		player.bus = bus
		player.volume_db = linear_to_db(SILENT)
		add_child(player)
		_players.append(player)

	if base_track == null:
		push_warning("MusicManager: no Base Track set in music_manager.tscn.")
		return

	play(base_track, 0.0)

	if tension_center != null or tension_pan != null:
		_setup_tension_buses()
		_center_player = _make_tension_player("TensionCenter", tension_center, TENSION_BUS)
		_pan_player = _make_tension_player("TensionPan", tension_pan, TENSION_PAN_BUS)
		# Started in the same frame as the base track so they line up.
		for p in [_center_player, _pan_player]:
			if p != null:
				p.play()


## Plays [param stream] on loop. Does nothing if it is already playing, so it
## is safe to call from every scene's _ready().
func play(stream: AudioStream, fade_time: float = 1.0) -> void:
	if stream == null:
		return

	var current := _players[_active]
	if current.playing and current.stream == stream:
		return

	_ensure_looping(stream)

	var next := _players[1 - _active]
	next.stream = stream
	next.play()

	_fade(next, volume, fade_time)
	if current.playing:
		_fade(current, SILENT, fade_time, true)

	_active = 1 - _active


## Fades out and stops whatever is playing, including the tension layer.
func stop(fade_time: float = 1.0) -> void:
	for player in _players:
		if player.playing:
			_fade(player, SILENT, fade_time, true)
	_tension_stopped = true
	for player in [_center_player, _pan_player]:
		if player != null and player.playing:
			_fade(player, SILENT, fade_time, true)


## Sets the music level (linear 0..1) on the active track.
func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	var current := _players[_active]
	if current.playing:
		_fade(current, volume, 0.0)


func is_playing() -> bool:
	return _players[_active].playing


func _process(delta: float) -> void:
	_check_game_over()

	if _tension_stopped or (_center_player == null and _pan_player == null):
		return

	# Level: rises with attack, falls with release. On the game over screen
	# the tension holds at its game-over level, centered and unfiltered.
	var target: float
	var time: float
	if _in_game_over:
		target = game_over_tension_level
		_pan_target = 0.0
		_vertical_target = 0.0
		time = game_over_fade
	else:
		target = _update_targets(delta)
		time = tension_attack if target > tension else tension_release
	if time <= 0.0:
		tension = target
	else:
		tension = move_toward(tension, target, delta / time)

	var level := tension * db_to_linear(tension_max_db) * volume
	_set_layer_level(_center_player, level, center_trim_db)
	_set_layer_level(_pan_player, level, pan_trim_db)

	# Pan glides toward the monster's side.
	pan = lerpf(pan, _pan_target, _smooth(delta, pan_smoothing))
	if _panner != null:
		_panner.pan = pan

	# Filter: interpolate in log-frequency so the sweep sounds even.
	var target_cutoff := exp(lerpf(log(OPEN_CUTOFF_HZ), log(muffled_cutoff_hz), _vertical_target))
	cutoff_hz = exp(lerpf(log(cutoff_hz), log(target_cutoff), _smooth(delta, filter_smoothing)))
	if _filter != null:
		_filter.cutoff_hz = cutoff_hz
		_filter.resonance = filter_resonance
		AudioServer.set_bus_effect_enabled(_tension_bus_idx, 0, cutoff_hz < OPEN_CUTOFF_HZ - 500.0)

	_keep_in_sync()


# --- Game over ---------------------------------------------------------------

## Fades the base loop out when the game over scene appears, and back in when
## it goes away. The base keeps playing silently so it stays in sync with the
## tension layer and comes back in time rather than restarting.
func _check_game_over() -> void:
	var scene := get_tree().current_scene
	var now := scene != null and game_over_scene != "" \
		and scene.scene_file_path == _resolve_path(game_over_scene)
	if now == _in_game_over:
		return
	_in_game_over = now

	var base := _players[_active]
	if not base.playing:
		return
	if now:
		_fade(base, SILENT, game_over_fade)
	else:
		_fade(base, volume, retry_fade_in)


## Exported file paths may be stored as uid:// strings; scene_file_path is res://.
func _resolve_path(path: String) -> String:
	if path.begins_with("uid://"):
		var id := ResourceUID.text_to_id(path)
		if ResourceUID.has_id(id):
			return ResourceUID.get_id_path(id)
	return path


# --- Tension -----------------------------------------------------------------

## Returns the target level (0..1) and updates the pan / filter targets from
## the closest monster that is chasing the player. With no chase, pan and
## filter hold where they were so the layer fades out in place.
func _update_targets(delta: float) -> float:
	_scan_timer -= delta
	if _scan_timer <= 0.0 or not is_instance_valid(_player_node):
		_scan_scene()

	if not is_instance_valid(_player_node):
		return 0.0

	var nearest: Node2D = null
	var nearest_dist := INF
	for monster in _monsters:
		if not is_instance_valid(monster) or not monster.is_inside_tree():
			continue
		if not _is_chasing_player(monster):
			continue
		var d := _player_node.global_position.distance_to(monster.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = monster as Node2D

	if nearest == null:
		return 0.0

	var offset := nearest.global_position - _player_node.global_position
	_pan_target = clampf(offset.x / pan_distance, -1.0, 1.0) * max_pan
	# How "vertical" the direction is (0 = level with player, 1 = straight
	# above/below), scaled by how far away vertically it is.
	var verticality := absf(offset.y) / maxf(offset.length(), 0.001)
	_vertical_target = verticality * clampf(absf(offset.y) / muffle_distance, 0.0, 1.0)

	var span := maxf(tension_start_distance - tension_full_distance, 0.001)
	var t := clampf((tension_start_distance - nearest_dist) / span, 0.0, 1.0)
	return lerpf(chase_min_level, 1.0, smoothstep(0.0, 1.0, t))


func _is_chasing_player(monster: Node) -> bool:
	var finder = monster.get("target_finder")
	if finder == null:
		return false
	return finder.get("chosen_target") == _player_node.get_instance_id()


func _scan_scene() -> void:
	_scan_timer = 0.5
	_monsters.clear()
	_player_node = null
	var scene := get_tree().current_scene
	if scene == null:
		return
	_monsters = scene.find_children("*", "BaseMonster", true, false)
	var found := scene.find_children("*", "PlayerController", true, false)
	if not found.is_empty():
		_player_node = found[0] as Node2D


# --- Tension audio plumbing ----------------------------------------------------

func _setup_tension_buses() -> void:
	# Tension bus: low-pass filter for verticality, feeds the Music bus.
	_tension_bus_idx = _get_or_add_bus(TENSION_BUS, _music_bus())
	_filter = AudioEffectLowPassFilter.new()
	_filter.cutoff_hz = OPEN_CUTOFF_HZ
	AudioServer.add_bus_effect(_tension_bus_idx, _filter, 0)
	AudioServer.set_bus_effect_enabled(_tension_bus_idx, 0, false)

	# Pan bus: panner, feeds the Tension bus (so the filter applies to both).
	var pan_idx := _get_or_add_bus(TENSION_PAN_BUS, TENSION_BUS)
	_panner = AudioEffectPanner.new()
	AudioServer.add_bus_effect(pan_idx, _panner, 0)


func _get_or_add_bus(bus_name: StringName, send_to: StringName) -> int:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, send_to)
	return idx


func _make_tension_player(player_name: String, stream: AudioStream, bus: StringName) -> AudioStreamPlayer:
	if stream == null:
		return null
	if absf(stream.get_length() - base_track.get_length()) > 0.01:
		push_warning(
			"MusicManager: '%s' (%.3fs) and the base track (%.3fs) are different lengths - they will drift out of sync."
			% [stream.resource_path.get_file(), stream.get_length(), base_track.get_length()]
		)
	_ensure_looping(stream)
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.stream = stream
	player.bus = bus
	player.volume_db = linear_to_db(SILENT)
	add_child(player)
	return player


func _set_layer_level(player: AudioStreamPlayer, level: float, trim_db: float) -> void:
	if player == null:
		return
	player.volume_db = linear_to_db(maxf(level * db_to_linear(trim_db), SILENT))


## Separate players are started together, but a hitch could nudge them apart.
## If a layer drifts from the base track, snap it back.
func _keep_in_sync() -> void:
	var base := _players[_active]
	if not base.playing or base.stream != base_track:
		return
	var length := base_track.get_length()
	if length <= 0.0:
		return
	var base_pos := base.get_playback_position()
	for player in [_center_player, _pan_player]:
		if player == null or not player.playing:
			continue
		var drift := fposmod(player.get_playback_position() - base_pos + length * 0.5, length) - length * 0.5
		if absf(drift) > RESYNC_THRESHOLD:
			player.seek(base_pos)


# --- Helpers -----------------------------------------------------------------

func _music_bus() -> StringName:
	return MUSIC_BUS if AudioServer.get_bus_index(MUSIC_BUS) != -1 else &"Master"


## Frame-rate independent smoothing factor for lerp.
func _smooth(delta: float, seconds: float) -> float:
	if seconds <= 0.0:
		return 1.0
	return 1.0 - exp(-delta / seconds)


func _fade(player: AudioStreamPlayer, to_linear: float, duration: float, stop_after := false) -> void:
	if _tweens.has(player) and _tweens[player].is_valid():
		_tweens[player].kill()

	to_linear = maxf(to_linear, SILENT)
	if duration <= 0.0:
		player.volume_db = linear_to_db(to_linear)
		if stop_after:
			player.stop()
		return

	# Fade in linear amplitude (not dB) so the fade sounds even.
	var from_linear := db_to_linear(player.volume_db)
	var tween := create_tween()
	tween.tween_method(
		func(v: float) -> void: player.volume_db = linear_to_db(v),
		from_linear, to_linear, duration
	)
	if stop_after:
		tween.tween_callback(player.stop)
	_tweens[player] = tween


func _ensure_looping(stream: AudioStream) -> void:
	if stream is AudioStreamSynchronized:
		for i in stream.stream_count:
			_ensure_looping(stream.get_sync_stream(i))
	# OGG/MP3: turning loop on keeps any loop_offset set in the Import dock,
	# so an intro that plays once before the loop still works.
	elif stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamWAV and stream.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		push_warning(
			"MusicManager: '%s' is a WAV without looping. Select it, open the Import dock, "
			% stream.resource_path
			+ "set Loop Mode to Forward, and click Reimport."
		)
