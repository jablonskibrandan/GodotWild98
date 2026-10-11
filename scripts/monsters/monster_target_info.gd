class_name MonsterTargetInfo

var position: Vector2 = Vector2.ZERO
var priority: int = 0
var last_noticed: float = 0.0

func notice(_position: Vector2, _priority: int):
	position = _position
	priority = _priority
	last_noticed = 0.0

func pass_time(delta: float) -> float:
	last_noticed += delta
	return last_noticed
