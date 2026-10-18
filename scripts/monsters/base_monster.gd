class_name BaseMonster
extends CharacterBody2D

## VARIATIONS
## blue - default
## red - larger and slower
## yellow - a bit faster, high vision, low hearing, high memory + focus
## gray - fast, very low vision, high hearing, low memory + focus


signal monster_bit_player()

@export_range(1.0, 100.0, 1.0) var radius: float = 10.0
@export_range(1.0, 1000.0, 1.0) var chase_speed: float = 50.0
@export_range(1.0, 1000.0, 1.0) var wander_speed: float = 10.0
@export_range(1.0, 100.0, 1.0) var wander_distance: float = 60.0
@export_range(1.0, 10.0, 0.5) var bite_cooldown: float = 2.0
@onready var target_finder: MonsterTargetFinder = $TargetFinder
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var point_light: PointLight2D = $PointLight2D
var starting_position: Vector2 = Vector2.ZERO
var wander_position: Vector2 = Vector2.ZERO

var bite_cooldown_time_left: float = 0.0
var animation_locked: bool = false

func _ready():
	starting_position = global_position
	wander_position = starting_position
	point_light.scale = Vector2(target_finder.vision/100,target_finder.vision/100)
	animated_sprite.animation_finished.connect(on_animation_finished)

func configure_target_finder(player: Node2D):
	target_finder.configure(player, radius, Vector2.LEFT)

func _physics_process(_delta: float) -> void:
	var target_velocity:= velocity_to_target()
	velocity = target_velocity
	
	move_and_slide()
	#target_finder.queue_redraw()

func _process(delta: float) -> void:
	if bite_cooldown_time_left > 0:
		bite_cooldown_time_left = clampf(bite_cooldown_time_left - delta, 0, bite_cooldown)
	
	# face towards last known player location, with 1 seconds grace to help with corner vision
	var face_target_player_direction = target_finder.get_face_target_player_direction()
	if face_target_player_direction != null && face_target_player_direction is Vector2:
		if face_target_player_direction.x < 0:
			face_left()
		else:
			face_right()
	# using 1 instead of 0 to help prevent repeated flips
	elif velocity.x < 1:
		face_left()
	elif velocity.x > 1:
		face_right()
	
	if !animation_locked:
		animated_sprite.speed_scale = clampf((abs(velocity.x) + (abs(velocity.y)/6)) / wander_speed, 0.5, 2)
		
		if bite_cooldown_time_left <= 0 && target_finder.should_bite():
			start_biting()

func face_left():
	animated_sprite.flip_h = false
	target_finder.facing = Vector2.LEFT
	target_finder.bite_area.position = Vector2(-radius*0.8, 0)

func face_right():
	animated_sprite.flip_h = true
	target_finder.facing = Vector2.RIGHT
	target_finder.bite_area.position = Vector2(radius*0.8, 0)

func on_animation_finished():
	if animation_locked:
		animation_locked = false
		animated_sprite.play("swim")

func start_biting() -> void:
	print("MONSTER STARTED BITING!")

	animated_sprite.speed_scale = 1.0
	animated_sprite.play("bite")
	animation_locked = true
	bite_cooldown_time_left = bite_cooldown

	monster_bit_player.emit()
	print("Monster bite signal emitted!")

func hear_sound_made(source: Node2D, volume: float):
	target_finder.hear(source, volume)

func velocity_to_target() -> Vector2:
	var target_position = target_finder.get_chosen_target_position()
	
	if target_position != null && target_position is Vector2: #has target
		if global_position.distance_to(target_position) > radius:
			return chase_velocity(target_position)
		else:
			return Vector2.ZERO
	else: #return to wandering around starting position
		return wander_velocity(starting_position)

func chase_velocity(target_position: Vector2) -> Vector2:
	return navigation_direction(target_position) * chase_speed

func wander_velocity(target_position: Vector2) -> Vector2:
	if (wander_position == starting_position 
	|| wander_position.distance_to(target_position) > wander_distance
	|| global_position.distance_to(wander_position) <= radius
	|| velocity.length() < (wander_speed * 0.1)): #in case stuck on wall
		wander_position = new_wander_position(target_position)
	return navigation_direction(wander_position) * wander_speed

func new_wander_position(target_position: Vector2) -> Vector2:
	var angle := randf_range(0.0, TAU)
	var distance := randf_range(0.1, 1.0) * wander_distance
	var new_position := target_position + (Vector2.from_angle(angle) * distance)
	navigation_agent.target_position = new_position
	if navigation_agent.is_target_reachable() && navigation_agent.distance_to_target() <= wander_distance:
		return new_position
	else:
		return target_position

func navigation_direction(target_position: Vector2):
	navigation_agent.target_position = target_position
	if navigation_agent.is_target_reachable():
		var path_position := navigation_agent.get_next_path_position()
		return global_position.direction_to(path_position)
	else:
		return Vector2.ZERO

func _draw() -> void:
	pass
	#draw_circle(Vector2.ZERO, radius, Color("4e6700ff"))

func die() -> void:
	get_parent().kill_monster(self)
	queue_free()
