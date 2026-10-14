extends Node
## Global music player, registered as the "MusicManager" autoload
## (res://scripts/audio/music_manager.tscn).
##
## Lives above every scene, so a track keeps looping seamlessly when the game
## changes scenes (e.g. Main Menu -> Floor One) instead of restarting.
## Uses two players so tracks can crossfade.
##
## Tension layer: if a tension stem is set, it plays in sync with the base
## track and fades in as the nearest monster gets closer to the player.
## Tune everything below in the Inspector by opening music_manager.tscn.
##
## Usage from any script:
##     MusicManager.play(preload("res://audio/music/floor_theme.ogg"))
##     MusicManager.play(some_stream, 2.0)   # 2-second crossfade
##     MusicManager.stop(1.5)                # fade out
##     MusicManager.set_volume(0.8)          # 0.0 - 1.0 (linear)

const MUSIC_BUS := &"Music"
const SILENT := 0.0001

## Main loop that starts when the game boots.
@export var base_track: AudioStream
## Overall music level, linear 0..1 (0.5 is about -6 dB).
@export_range(0.0, 1.0, 0.01) var volume: float = 0.5

@export_group("Tension Layer")
## Stem that plays in sync with the base track. Must be the same length and tempo.
@export var tension_stem: AudioStream
## Monster farther than this (pixels): tension layer is silent.
@export_range(0.0, 2000.0, 1.0, "suffix:px") var tension_start_distance: float = 220.0
## Monster closer than this (pixels): tension layer is at full level.
@export_range(0.0, 2000.0, 1.0, "suffix:px") var tension_full_distance: float = 60.0
## Level of the tension layer when fully in.
@export_range(-24.0, 12.0, 0.1, "suffix:dB") var tension_max_db: float = 0.0
## Seconds to swell in when the monster closes in (lower = more reactive).
@export_range(0.0, 10.0, 0.05, "suffix:s") var tension_attack: float = 0.75
## Seconds to settle back down when the monster backs off (higher = lingers).
@export_range(0.0, 20.0, 0.05, "suffix:s") var tension_release: float = 3.0
## Minimum tension while the monster is chasing something, at any distance.
## 0 = distance only.
@export_range(0.0, 1.0, 0.01) var tension_while_chasing: float = 0.0

## Current tension, 0..1 (read-only; handy for debugging or other systems).
var tension: float = 0.0

var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _tweens: Dictionary = {}

var _layered: AudioStreamSynchronized
var _player_node: Node2D
var _monsters: Array[Node] = []
var _scan_timer := 0.0


func _ready() -> void:
	# Keep the music going while the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS

	var bus := MUSIC_BUS if AudioServer.get_bus_index(MUSIC_BUS) != -1 else &"Master"
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

	if tension_stem != null:
		_layered = _make_layered(base_track, tension_stem)
		play(_layered, 0.0)
	else:
		play(base_track, 0.0)


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


## Fades out and stops whatever is playing.
func stop(fade_time: float = 1.0) -> void:
	for player in _players:
		if player.playing:
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
	if _layered == null:
		return

	var target := _target_tension(delta)
	var time := tension_attack if target > tension else tension_release
	if time <= 0.0:
		tension = target
	else:
		tension = move_toward(tension, target, delta / time)

	var level := maxf(tension * db_to_linear(tension_max_db), SILENT)
	_layered.set_sync_stream_volume(1, linear_to_db(level))


# --- Tension -----------------------------------------------------------------

func _target_tension(delta: float) -> float:
	_scan_timer -= delta
	if _scan_timer <= 0.0 or not is_instance_valid(_player_node):
		_scan_scene()

	if not is_instance_valid(_player_node):
		return 0.0

	var nearest := INF
	var chasing := false
	for monster in _monsters:
		if not is_instance_valid(monster) or not monster.is_inside_tree():
			continue
		nearest = minf(nearest, _player_node.global_position.distance_to(monster.global_position))
		var finder = monster.get("target_finder")
		if finder != null and finder.get("chosen_target") != 0:
			chasing = true

	if nearest == INF:
		return 0.0

	var span := maxf(tension_start_distance - tension_full_distance, 0.001)
	var t := clampf((tension_start_distance - nearest) / span, 0.0, 1.0)
	t = smoothstep(0.0, 1.0, t)
	if chasing:
		t = maxf(t, tension_while_chasing)
	return t


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


func _make_layered(base: AudioStream, layer: AudioStream) -> AudioStreamSynchronized:
	if absf(base.get_length() - layer.get_length()) > 0.01:
		push_warning(
			"MusicManager: base track (%.3fs) and tension stem (%.3fs) are different lengths - they will drift out of sync."
			% [base.get_length(), layer.get_length()]
		)
	var sync := AudioStreamSynchronized.new()
	sync.stream_count = 2
	sync.set_sync_stream(0, base)
	sync.set_sync_stream(1, layer)
	sync.set_sync_stream_volume(0, 0.0)
	sync.set_sync_stream_volume(1, linear_to_db(SILENT))
	return sync


# --- Helpers -----------------------------------------------------------------

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
