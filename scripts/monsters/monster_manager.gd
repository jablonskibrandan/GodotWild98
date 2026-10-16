class_name MonsterManager
extends Node2D

var monsters : Array[BaseMonster] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	monsters = []
	for child in get_children():
		if child is BaseMonster:
			monsters.append(child)


func configure(player: Node2D) -> void:
	for monster in monsters:
		monster.configure_target_finder(player)

func sound_made(source: Node2D, volume: float):
	for monster in monsters:
		monster.hear_sound_made(source, volume)
