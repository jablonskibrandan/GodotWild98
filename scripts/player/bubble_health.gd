class_name BubbleHealth
extends Node

signal bubble_amount_changed(amount: int)
## Emitted only when the oxygen timer consumes a bubble, not on damage.
signal bubble_lost_naturally(count: int)
signal time_ran_out

@export var bubble_max_time: float = 120.0
@export var time_per_bubble_loss: float = 15.0

var bubble_current_time: float
var bubble_amount: int


func _ready() -> void:
	bubble_current_time = bubble_max_time
	bubble_amount = calculate_bubble_amount(bubble_current_time)


func _process(delta: float) -> void:
	if bubble_current_time <= 0.0:
		return

	bubble_current_time = maxf(bubble_current_time - delta, 0.0)
	var new_bubble_amount: int = calculate_bubble_amount(bubble_current_time)

	if new_bubble_amount != bubble_amount:
		# Let displays distinguish an oxygen loss from a hit.
		if new_bubble_amount < bubble_amount:
			bubble_lost_naturally.emit(bubble_amount - new_bubble_amount)
		bubble_amount = new_bubble_amount
		bubble_amount_changed.emit(bubble_amount)

	if bubble_current_time <= 0.0:
		time_ran_out.emit()


## Remaining seconds in the last (rightmost) bubble. At each exact
## 15-second boundary the next bubble begins fully filled.
func get_active_bubble_time_left() -> float:
	if bubble_current_time <= 0.0 or time_per_bubble_loss <= 0.0:
		return 0.0
	var seconds: float = fposmod(bubble_current_time, time_per_bubble_loss)
	if is_zero_approx(seconds):
		return time_per_bubble_loss
	return seconds


func get_active_bubble_fraction() -> float:
	if time_per_bubble_loss <= 0.0:
		return 0.0
	return clampf(get_active_bubble_time_left() / time_per_bubble_loss, 0.0, 1.0)


func take_bubble_hit(damage_amount: int) -> void:
	if bubble_current_time <= 0.0:
		return

	bubble_current_time = maxf(
		bubble_current_time - damage_amount * time_per_bubble_loss,
		0.0
	)
	var new_amount: int = calculate_bubble_amount(bubble_current_time)
	if new_amount != bubble_amount:
		bubble_amount = new_amount
		bubble_amount_changed.emit(bubble_amount)

	if bubble_current_time <= 0.0:
		time_ran_out.emit()


func take_breath(heal_amount: int) -> void:
	if bubble_current_time <= 0.0:
		return

	bubble_current_time = minf(
		bubble_current_time + heal_amount * time_per_bubble_loss,
		bubble_max_time
	)
	var new_amount: int = calculate_bubble_amount(bubble_current_time)
	if new_amount != bubble_amount:
		bubble_amount = new_amount
		bubble_amount_changed.emit(bubble_amount)


func calculate_bubble_amount(current_time: float) -> int:
	if time_per_bubble_loss <= 0.0:
		return 0
	return int(ceil(maxf(current_time, 0.0) / time_per_bubble_loss))
