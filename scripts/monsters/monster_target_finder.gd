class_name MonsterTargetFinder
extends Node2D

# distance monster can see
@export_range(0.0, 200.0, 1.0) var vision: float = 100.0
#field of vision (degrees)
@export_range(45.0, 360.0, 45.0) var field_of_vision: float = 270.0
#how far in front of monster to have vision
var radius: float = 0.0
#direction monster is facing
var facing: Vector2 = Vector2.LEFT
# monster needs hearing higher than sound volume to notice it
@export_range(0.0, 200.0, 1.0) var hearing: float = 80.0
# seconds monster will remember hearing or seeing something
@export_range(0.0, 30.0, 1.0) var memory: float = 5.0
# percentage monster will focus on current target (extending memory and increasing senses) over other targets
@export_range(0.1, 1.0, 0.01) var focus: float = .40 #keep within range, do not make 0

var player: Node2D
# targets monster remembers sensing, along with last known position
var target_infos: Dictionary[int, MonsterTargetInfo] = {} 
var chosen_target: int = 0
# priority monster has to chase current target
# correlated to distance for vision, and excess volume for hearing
@export var chosen_priority:int = 0

########################################################################### 
# main functions for processing and handling input

func _process(delta: float) -> void:
	remember_targets(delta)
	look_around()

func configure(_player: Node2D, _radius: float, _facing: Vector2):
	player = _player
	radius = _radius
	facing = _facing

func get_chosen_target_position(): # -> Vector 2 or null
	if chosen_target != 0 && target_infos.has(chosen_target):
		return target_infos[chosen_target].position
	else:
		return null

func should_bite():
	return (player != null && player.get_instance_id() == chosen_target
			&& global_position.distance_to(player.global_position) < radius*2.0)

func look_around():
	if player != null:
		var distance := global_position.distance_to(player.global_position)
		var focus_vision := vision
		if player.get_instance_id() == chosen_target:
			focus_vision *= (1 + focus)
		if distance <= focus_vision && (distance <= radius*3 || has_line_of_sight(player)):
			var priority := int((focus_vision-distance))
			notice(player, priority)

func has_line_of_sight(target_node: Node2D) -> bool:
	var space_state = get_world_2d().direct_space_state
	const environment_layer := 1
	const hidden_room_door_layer := 5
	var collision_mask := (1 << (environment_layer-1)) + (1 << (hidden_room_door_layer-1))
	var query = PhysicsRayQueryParameters2D.create(global_position + (facing * radius), target_node.position, collision_mask)
	var result = space_state.intersect_ray(query)
	var view_obstructed = result.size() > 0
	
	var direction_to_target := global_position.direction_to(target_node.global_position)
	var angle_to_target: float = abs(facing.angle_to(direction_to_target))
	var in_field_of_vision = angle_to_target <= deg_to_rad(field_of_vision / 2.0)
	
	return in_field_of_vision && !view_obstructed

func hear(source_node: Node2D, volume: float):
	var focus_hearing := hearing
	if source_node.get_instance_id() == chosen_target:
		focus_hearing *= (1 + focus)
	if focus_hearing > volume:
		var priority := int(focus_hearing - volume)
		notice(source_node, priority)

func _draw() -> void:
	pass
	#draw_arc(Vector2.ZERO, vision, 0, TAU, 64, Color("98c50080"), 3)
	#if chosen_target != null && target_infos.has(chosen_target):
		#draw_circle(target_infos[chosen_target].position - global_position, 10.0, Color("9c351f80"))

########################################################################### 

# helper functions

func notice(target_node: Node2D, priority: int):
	var target_info: MonsterTargetInfo = MonsterTargetInfo.new()
	target_info.notice(target_node.global_position, priority)
	target_infos[target_node.get_instance_id()] = target_info
	compare_and_choose_target(target_node.get_instance_id())

func remember_targets(delta: float):
	for target in target_infos.keys():
		var focus_delta := delta
		if target == chosen_target:
			focus_delta *= (1 - (focus/2.0))
		var last_noticed := target_infos[target].pass_time(focus_delta)
		if last_noticed > memory:
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
