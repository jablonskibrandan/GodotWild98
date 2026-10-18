class_name PlayerKeys
extends Node

var key_count:int = 0

func add_key():
	key_count += 1

func use_key() -> bool:
	if key_count > 0:
		key_count -= 1
		return true
	return false
