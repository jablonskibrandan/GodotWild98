class_name PlayerController
extends CharacterBody2D


@export_range(1.0, 1000.0, 1.0) var move_speed: float = 100.0
#@export_range(1.0, 100.0, 1.0) var radius: float = 15.0

var _cursor: TargetCursor
var input_direction : Vector2 = Vector2.ZERO
var facing_animation : String = "down"

@onready var sprite = $AnimatedSprite2D
@onready var flashlight_sprite : FlashlightSprite = $FlashlightSprite

var _effects_parent: DistractionManager
# volume is backwards and 100 is very quiet, 5 is super loud
const flashlight_volume: float = 120.0

const DistractionSignalClass = preload("res://scripts/tools/distraction_tool.gd")
const NavalMineSignalClass = preload("res://scripts/tools/naval_mine_tool.gd")

func _process(_delta: float) -> void:
	animate()

func animate() -> void:
	if input_direction == Vector2.ZERO:
		sprite.play("idle_"+facing_animation)
	else:
		sprite.play(facing_animation)

func take_hit() -> void:
	var hit_tween = self.create_tween()
	hit_tween.tween_method(set_shader_value, 1, 2, .2)
	hit_tween.tween_method(set_shader_value, 2, 1, .2)
	return

func set_shader_value(value: float) -> void:
	$AnimatedSprite2D.material.set_shader_parameter("progress", value)
	return


func configure(starting_position: Vector2, cursor: TargetCursor, effects_parent: DistractionManager) -> void:
	global_position = starting_position
	_cursor = cursor
	_effects_parent = effects_parent

func toolUsed(tool: BaseTool) -> void:
	if (tool is DistractionSignalClass):
		$Timers/DistractionSignal_Timer.start()
		print("set distraction signal")
	elif (tool is NavalMineSignalClass):
		$Timers/MineSignal_Timer.start()
		print("set naval mine signal")
	return

func get_time_left(tool: BaseTool) -> float:
	var timeLeft
	if (tool is DistractionSignalClass):
		timeLeft = $Timers/DistractionSignal_Timer.time_left
	elif (tool is NavalMineSignalClass):
		timeLeft = $Timers/MineSignal_Timer.time_left
	return timeLeft


func _physics_process(_delta: float) -> void:
	var direction: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_up", "move_down"
	)
	
	update_cursor()
	
	if direction != Vector2.ZERO:
		update_facing(direction)
		velocity = direction * move_speed
		move_and_slide()
	
	input_direction = direction


func update_facing(direction: Vector2):
	if direction == Vector2.ZERO:
		return
	elif direction == Vector2.RIGHT:
		facing_animation = "right"
	elif direction == Vector2.LEFT:
		facing_animation = "left"
	elif direction == Vector2.UP:
		facing_animation = "up"
	elif direction == Vector2.DOWN:
		facing_animation = "down"
	#up/down plus left/right defaults to left/right, unless already facing one of the directions
	elif (direction.x > 0 
		&& facing_animation != "up" && facing_animation != "down"):
		facing_animation = "right"
	elif (direction.x < 0 
		&& facing_animation != "up" && facing_animation != "down"):
		facing_animation = "left"
	
	flashlight_sprite.update_facing(facing_animation)

func toggle_flashlight(enabled: bool):
	flashlight_sprite.toggle(enabled)
	_effects_parent.broadcast_sound(flashlight_sprite, flashlight_volume)

func update_cursor():
	if _cursor == null:
		return
	flashlight_sprite.update_cursor(_cursor.global_position)

func flashlight_beam_positions() -> Array[Vector2]:
	return flashlight_sprite.get_flashlight_points()

func _draw() -> void:
	pass
