class_name BubbleHealth
extends Node

signal bubble_amount_changed(amount: int)
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

	# Decrease remaining time
	bubble_current_time = maxf(bubble_current_time - delta, 0.0)

	var new_bubble_amount = calculate_bubble_amount(bubble_current_time)

	if new_bubble_amount != bubble_amount:
		bubble_amount = new_bubble_amount
		bubble_amount_changed.emit(bubble_amount)

	if bubble_current_time <= 0.0:
		time_ran_out.emit()

func take_bubble_hit(damage_amount: int) -> void:
	if bubble_current_time <= 0.0:
		return

	# Each hit removes X seconds of oxygen per bubble.
	bubble_current_time = maxf(
		bubble_current_time - damage_amount * time_per_bubble_loss,
		0.0
	)

	# Recalculate bubbles based on the remaining oxygen.
	var new_amount: int = calculate_bubble_amount(bubble_current_time)

	if new_amount != bubble_amount:
		bubble_amount = new_amount
		bubble_amount_changed.emit(bubble_amount)

	if bubble_current_time <= 0.0:
		time_ran_out.emit()
	
func calculate_bubble_amount(current_time: float) -> int:
	return int(ceil(current_time / time_per_bubble_loss))
