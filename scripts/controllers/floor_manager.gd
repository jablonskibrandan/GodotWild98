extends Node

var current_floor: int = -1
var floors: Array[String] = [
	"res://scenes/floors/floor_one.tscn",
	"res://scenes/floors/floor_two.tscn",
]

func get_next_floor() -> String:
	current_floor += 1;
	return floors[clampi(current_floor, 0, floors.size() - 1)]
