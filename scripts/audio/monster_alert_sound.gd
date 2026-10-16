extends AudioStreamPlayer2D
## Plays an alert when this monster starts chasing something.
## Put this node directly under the monster (next to its TargetFinder).
## Plays from the monster's position, so it pans and fades with distance.

## Plays when the monster starts chasing the player.
@export var player_alert: AudioStream
## Plays when the monster starts chasing a distraction ping.
@export var distraction_alert: AudioStream
## Minimum seconds before the same alert can play again, so a monster
## flip-flopping between targets doesn't spam it.
@export_range(0.0, 10.0, 0.05, "suffix:s") var cooldown: float = 1.5
## Random pitch change per alert (0.05 = +/-5%).
@export_range(0.0, 0.5, 0.01) var pitch_variation: float = 0.0

var _finder: MonsterTargetFinder
var _last_target := 0
var _cooldowns: Dictionary = {}


func _ready() -> void:
	_finder = get_parent().get_node_or_null("TargetFinder") as MonsterTargetFinder
	if _finder == null:
		push_warning("AlertSound: no TargetFinder next to this node, alerts disabled.")


func _process(delta: float) -> void:
	for key in _cooldowns.keys():
		_cooldowns[key] = maxf(_cooldowns[key] - delta, 0.0)

	if _finder == null:
		return
	var target := _finder.chosen_target
	if target == _last_target:
		return
	_last_target = target
	if target != 0:
		_play_alert(_alert_for(target))


func _alert_for(target_id: int) -> AudioStream:
	if is_instance_valid(_finder.player) and target_id == _finder.player.get_instance_id():
		return player_alert
	if instance_from_id(target_id) is DistractionPulse:
		return distraction_alert
	return null


func _play_alert(alert: AudioStream) -> void:
	if alert == null or _cooldowns.get(alert, 0.0) > 0.0:
		return
	stream = alert
	pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	play()
	_cooldowns[alert] = cooldown
