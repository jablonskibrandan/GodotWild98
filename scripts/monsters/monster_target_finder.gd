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
#direction towards player with 1 seconds grace
var face_target_player_direction: Vector2 = Vector2.ZERO
# monster needs hearing higher than sound volume to notice it
@export_range(0.0, 200.0, 1.0) var hearing: float = 80.0
# seconds monster will remember hearing or seeing something
@export_range(0.0, 30.0, 1.0) var memory: float = 5.0
# percentage monster will focus on current target (extending memory and increasing senses) over other targets
@export_range(0.1, 1.0, 0.01) var focus: float = .40 #keep within range, do not make 0

var player: PlayerController
# targets monster remembers sensing, along with last known position
var target_infos: Dictionary[int, MonsterTargetInfo] = {} 
var chosen_target: int = 0
# priority monster has to chase current target
# correlated to distance for vision, and excess volume for hearing
@export var chosen_priority:int = 0

@onready var bite_area : Area2D = $BiteArea

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

func get_face_target_player_direction(): 
	#if has seen player in the last second, face towards player
	if chosen_target != 0 && target_infos.has(chosen_target) && player.get_instance_id() == chosen_target:
		if target_infos[chosen_target].last_noticed <= 1.0:
			face_target_player_direction = global_position.direction_to(player.global_position)
		return face_target_player_direction
	else:
		return null

func should_bite():
	if player != null && player.get_instance_id() == chosen_target && target_infos[chosen_target].last_noticed <= .1:
		return bite_area.has_overlapping_areas()

func look_around():
	if player != null:
		var focus_vision := vision
		var flashlight_beam_positions := player.flashlight_beam_positions()
		var sneaking := flashlight_beam_positions.size() == 0
		if player.get_instance_id() == chosen_target: #chasing
			focus_vision *= (1 + focus)
			sneaking = false
		
		var spotted := see(player, player.global_position, focus_vision, sneaking)
		if !spotted:
			for beam_position in flashlight_beam_positions:
				spotted = see(player.flashlight_sprite, beam_position, focus_vision, false, 0.1)
				if spotted:
					break

func see(target_node: Node2D, target_position: Vector2, effective_vision: float, sneaking: bool, priority_mult: float = 1.0) -> bool:
	var distance := global_position.distance_to(target_position)
	if distance <= effective_vision && has_line_of_sight(target_position, sneaking):
		var priority := int((effective_vision-distance) * priority_mult) 
		notice(target_node, priority, target_position)
		return true
	return false

func has_line_of_sight(target_position: Vector2, sneaking: bool) -> bool:
	var space_state = get_world_2d().direct_space_state
	const environment_layer := 1
	const hidden_room_door_layer := 5
	const seaweed_layer := 6
	const door_layer := 8
	var collision_mask := (1 << (environment_layer-1)) + (1 << (hidden_room_door_layer-1)) + (1 << (door_layer-1))
	if sneaking:
		collision_mask += (1 << (seaweed_layer-1))
	
	#first ray moved towards eye to get around corners
	var query_ray = PhysicsRayQueryParameters2D.create(global_position + (facing * radius), target_position, collision_mask)
	var result_ray = space_state.intersect_ray(query_ray)
	var view_obstructed = result_ray.size() > 0
	
	if !view_obstructed:
		#make sure starting point of ray was not in a wall
		var query_point = PhysicsPointQueryParameters2D.new()
		query_point.position = query_ray.from
		query_point.collision_mask = query_ray.collision_mask
		var result_point = space_state.intersect_point(query_point)
		view_obstructed = result_point.size() > 0

	if view_obstructed:
		#second ray towards center to avoid getting stuck on walls
		var query2 = PhysicsRayQueryParameters2D.create(global_position + (facing * 2), target_position, collision_mask)
		var result2 = space_state.intersect_ray(query2)
		view_obstructed = result2.size() > 0
	
	var distance_to_target := global_position.distance_to(target_position)
	var direction_to_target := global_position.direction_to(target_position)
	var angle_to_target: float = abs(facing.angle_to(direction_to_target))
	var in_field_of_vision = angle_to_target <= deg_to_rad(field_of_vision / 2.0) || distance_to_target <= radius*3
	
	return in_field_of_vision && !view_obstructed

#this is backwards than it should be: basically higher volume = quiter, low volume = loud
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

func notice(target_node: Node2D, priority: int, alternate_position = null):
	var target_info: MonsterTargetInfo = MonsterTargetInfo.new()
	
	if alternate_position != null && alternate_position is Vector2:
		target_info.notice(alternate_position, priority)
	else:
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
