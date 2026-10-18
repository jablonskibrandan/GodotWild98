class_name DistractionTool
extends BaseTool

const PULSE_SCENE: PackedScene = preload("res://scenes/tools/distraction_pulse.tscn")

var _effects_parent: DistractionManager

var _player: PlayerController


func configure(effects_parent: DistractionManager, player: PlayerController) -> void:
	_effects_parent = effects_parent
	_player = player


func activate(target: Vector2) -> void:
	if _effects_parent == null:
		return
	if (_player.get_time_left(self) == 0):
		var circle := CircleShape2D.new()
		circle.radius = 5.0
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = circle
		query.transform = Transform2D(0.0, target)
		# Layer 1 = walls, 2 = player, 4 = monsters.
		query.collision_mask = 11
		query.collide_with_bodies = true
		query.collide_with_areas = false
		var space := get_world_2d().direct_space_state
		if not space.intersect_shape(query, 1).is_empty():
			return
		var pulse: DistractionPulse = PULSE_SCENE.instantiate() as DistractionPulse
		_effects_parent.add_child(pulse)
		pulse.global_position = target
		_effects_parent.broadcast_sound(pulse, pulse.volume)
		_player.toolUsed(self)
