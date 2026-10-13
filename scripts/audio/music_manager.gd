extends Node
## Global music player, registered as the "MusicManager" autoload.
##
## Lives above every scene, so a track keeps looping seamlessly when the game
## changes scenes (e.g. Main Menu -> Floor One) instead of restarting.
## Uses two players so tracks can crossfade.
##
## Usage from any script:
##     MusicManager.play(preload("res://audio/music/floor_theme.ogg"))
##     MusicManager.play(some_stream, 2.0)   # 2-second crossfade
##     MusicManager.stop(1.5)                # fade out
##     MusicManager.set_volume(0.8)          # 0.0 - 1.0 (linear)

## Track that starts automatically when the game boots. Drop your file here
## (or change this path). OGG Vorbis is recommended for music.
const DEFAULT_TRACK_PATH := "res://audio/music/main_theme.ogg"
const MUSIC_BUS := &"Music"
const SILENT := 0.0001

## Overall music level, linear 0..1 (0.5 is about -6 dB).
var volume: float = 0.5

var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _tweens: Dictionary = {}


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

	if ResourceLoader.exists(DEFAULT_TRACK_PATH):
		play(load(DEFAULT_TRACK_PATH), 0.0)
	else:
		push_warning("MusicManager: no track at %s yet - add one to hear music." % DEFAULT_TRACK_PATH)


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
	# OGG/MP3: turning loop on keeps any loop_offset set in the Import dock,
	# so an intro that plays once before the loop still works.
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamWAV and stream.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		push_warning(
			"MusicManager: '%s' is a WAV without looping. Select it, open the Import dock, "
			% stream.resource_path
			+ "set Loop Mode to Forward, and click Reimport."
		)
