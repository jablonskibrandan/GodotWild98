extends Node

var current_floor: int = -1
var floors: Array[String] = [
	
		"res://scenes/floors/floor_one.tscn",
		"res://scenes/floors/floor_two.tscn",
		"res://scenes/floors/floor_three.tscn",
		"res://scenes/floors/floor_four.tscn",
		"res://scenes/floors/floor_final.tscn",
		"res://scenes/main_menu.tscn"
]

func get_next_floor() -> String:
	current_floor = clampi(current_floor+1, 0, floors.size() - 1)
	return floors[current_floor]

func floor_failed():
	current_floor -= 1
