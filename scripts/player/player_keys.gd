
class_name PlayerKeys
extends Node

signal key_count_changed(count: int)

var key_count: int = 0

func add_key() -> void:
	key_count += 1
	key_count_changed.emit(key_count)

func use_key() -> bool:
	if key_count > 0:
		key_count -= 1
		key_count_changed.emit(key_count)
		return true

	return false
