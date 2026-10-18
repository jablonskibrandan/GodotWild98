extends AudioStreamPlayer2D
## Beeps on a loop for as long as the mine exists. Put this node under the
## NavalMine. When the mine explodes it's removed, which stops the beeping.

## Seconds between beeps.
@export_range(0.1, 10.0, 0.05, "suffix:s") var interval: float = 1.5
## Delay before the first beep, so it doesn't stack on the placement sound.
@export_range(0.0, 5.0, 0.05, "suffix:s") var first_beep_delay: float = 0.6
## Random pitch change per beep (0.02 = +/-2%). Keep small for a mechanical beep.
@export_range(0.0, 0.5, 0.01) var pitch_variation: float = 0.0

var _time_left := 0.0


func _ready() -> void:
	_time_left = first_beep_delay


func _process(delta: float) -> void:
	if stream == null:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		_time_left += interval
		pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
		play()
