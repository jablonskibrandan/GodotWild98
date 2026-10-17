extends Node2D

@onready var animated_sprite_2d = $AnimatedSprite2D

func _ready():
	#offset animation starts and starting animation frame
	var offset = randf_range(0.01, 0.5)
	await get_tree().create_timer(offset).timeout
	animated_sprite_2d.play("default")
	animated_sprite_2d.frame = randi_range(0, 2)
	
	#offset positions slightly so looks more natural in a patch
	#keep position offset limited to <= 2 so collision is continuous
	const max_offset : float = 2.0
	position += Vector2(randf_range(-max_offset, max_offset), randf_range(max_offset,max_offset))
