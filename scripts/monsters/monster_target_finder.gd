class_name MonsterTargetFinder
extends Node2D

var player: Node2D

const MAX_HEARING = 200.0

@export_range(0.0, 200.0, 1.0) var vision: float = 200.0
@export_range(0.0, MAX_HEARING, 1.0) var hearing: float = 100.0
@export_range(0.0, 30.0, 1.0) var memory: float = 5.0

var target_infos: Dictionary[int, MonsterTargetInfo] = {} 
var chosen_target: int = 0
@export var chosen_priority:int = 0

########################################################################### 
# main functions for processing and handling input

func _process(delta: float) -> void:
	remember_targets(delta)
	look_around()

func get_chosen_target_position(): # -> Vector 2 or null
	if chosen_target != 0 && target_infos.has(chosen_target):
		return target_infos[chosen_target].position
	else:
		return null

# needs fixed with proper vision logic and remove reference to player
func look_around():
	if player != null:
		var distance := global_position.distance_to(player.global_position)
		if distance <= vision:
			var priority := int((vision-distance))
			notice(player, priority)

# needs a method connected to a signal to call this whenever the player makes sound
func hear(source_node: Node2D, volume: int):
	if hearing >= volume:
		var priority := int(hearing - volume)
		notice(source_node, priority)

func _draw() -> void:
	draw_arc(Vector2.ZERO, vision, 0, TAU, 64, Color("98c50080"), 3)
	if chosen_target != null && target_infos.has(chosen_target):
		draw_circle(target_infos[chosen_target].position - global_position, 10.0, Color("9c351f80"))

########################################################################### 

# helper functions

func notice(target_node: Node2D, priority: int):
	var target_info: MonsterTargetInfo = MonsterTargetInfo.new()
	target_info.notice(target_node.global_position, priority)
	target_infos[target_node.get_instance_id()] = target_info
	compare_and_choose_target(target_node.get_instance_id())

func remember_targets(delta: float):
	for target in target_infos.keys():
		var last_noticed := target_infos[target].pass_time(delta)
		if (last_noticed > memory):
			forget_target(target)

func find_new_target():
	for target in target_infos.keys():
		compare_and_choose_target(target)

func compare_and_choose_target(target: int):
	if compare_targets(chosen_target, target):
		choose_target(target)

func compare_targets(target1: int, target2: int) -> bool:
	if target1 != 0 && target1 == target2:
		return true
	
	var info1: MonsterTargetInfo = target_infos.get(target1)
	var info2: MonsterTargetInfo = target_infos.get(target2)
	
	if (info1 == null || info2 == null):
		return info2 != null
	
	if info1.priority == info2.priority:
		return info2.last_noticed < info1.last_noticed
	else:
		return info2.priority > info1.priority

func choose_target(target: int):
	if target_infos.has(target):
		chosen_target = target
		chosen_priority = target_infos[chosen_target].priority

func forget_target(target: int):
	target_infos.erase(target)
	if target == chosen_target:
		chosen_target = 0
		find_new_target()
