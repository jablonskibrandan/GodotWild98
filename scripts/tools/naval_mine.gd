
class_name NavalMine
extends Node2D

signal exploded(mine: NavalMine, target: Node2D)

@export var slide_speed: float = 180.0
@export var slide_friction: float = 240.0
@export var pull_strength: float = 90.0

@onready var detection_area: Area2D = $Area2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
#var _effects_parent: DistractionManager
@onready var beep_sound: BeepSound = $BeepSound

var velocity: Vector2 = Vector2.ZERO
var has_exploded: bool = false


func _ready() -> void:
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.area_entered.connect(_on_area_entered)

	# Detect player (layer 2) and monsters (layer 4).
	detection_area.collision_layer = 0
	detection_area.collision_mask = 10

	sprite.play("default")

func set_effects_parent(_effects_parent: DistractionManager):
	if beep_sound != null:
		beep_sound._effects_parent = _effects_parent

func _physics_process(delta: float) -> void:
	if has_exploded:
		return

	if velocity.length_squared() > 0.01:
		global_position += velocity * delta
		velocity = velocity.move_toward(
			Vector2.ZERO,
			slide_friction * delta
		)


# Called when the tongue pulls the mine.
func pull_towards(target: Vector2) -> void:
	if has_exploded:
		return

	var direction := global_position.direction_to(target)
	velocity += direction * pull_strength
	velocity = velocity.limit_length(slide_speed)


func _on_body_entered(body: Node2D) -> void:
	if has_exploded:
		return

	if body.is_in_group("player_tongue"):
		return

	explode(body)


func _on_area_entered(area: Area2D) -> void:
	if has_exploded:
		return

	if area.is_in_group("player_tongue"):
		return

	# Other trigger areas can detonate the mine if desired.
	#explode(area)


func explode(target: Node2D) -> void:
	if has_exploded:
		return

	has_exploded = true
	velocity = Vector2.ZERO

	detection_area.set_deferred("monitoring", false)

	print("NAVAL MINE EXPLODED!")
	exploded.emit(self, target)

	# Damage/kill monsters.
	if target is BaseMonster:
		target.die()

	# Damage the player using the existing BubbleHealth.
	elif (target.has_node("Bubble_Health")):
		var breath = target.get_node("Bubble_Health")
		breath.take_bubble_hit(1)
		
	
	# Replace this with an explosion animation later.
	queue_free()
