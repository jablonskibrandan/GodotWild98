class_name BaseMonster
extends Node2D

#remove this reference once vision is properly implemented
@export var player: Node2D

@export_range(1.0, 100.0, 1.0) var radius: float = 15.0
@export_range(1.0, 1000.0, 1.0) var move_speed: float = 100.0
@onready var target_finder: MonsterTargetFinder = $TargetFinder
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

func _ready():
	target_finder.player = player

func _physics_process(delta: float) -> void:
	var direction: Vector2 = direction_to_target()
	if direction != Vector2.ZERO:
		global_position += direction * move_speed * delta
		#global_position = Vector2(
			#clampf(global_position.x, _movement_bounds.position.x + radius, _movement_bounds.end.x - radius),
			#clampf(global_position.y, _movement_bounds.position.y + radius, _movement_bounds.end.y - radius)
		#)
	
	target_finder.queue_redraw()

func hear_sound_made(source: Node2D, volume: float):
	target_finder.hear(source, volume)

func direction_to_target() -> Vector2:
	var target_position = target_finder.get_chosen_target_position()
	
	if target_position != null && target_position is Vector2 && global_position.distance_to(target_position) > radius:
		navigation_agent.target_position = target_position
		var path_position := navigation_agent.get_next_path_position()
		return global_position.direction_to(path_position)
	else:
		return Vector2.ZERO

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color("4e6700ff"))
