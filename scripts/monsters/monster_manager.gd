class_name MonsterManager
extends Node2D

var monsters : Array[BaseMonster] = []
signal player_bitten()

# Called when the node enters the scene tree for the first time.
func _ready():
	monsters = []
	for child in get_children():
		if child is BaseMonster:
			var monster := child as BaseMonster
			monsters.append(monster)
			monster.monster_bit_player.connect(_on_monster_bit_player)

func kill_monster(monster: BaseMonster) -> void:
	monsters.erase(monster)
	return

func configure(player: Node2D) -> void:
	for monster in monsters:
		monster.configure_target_finder(player)

func sound_made(source: Node2D, volume: float):
	for monster in monsters:
		monster.hear_sound_made(source, volume)

func _on_monster_bit_player():
	player_bitten.emit()
