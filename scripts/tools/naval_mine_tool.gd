
class_name NavalMineTool
extends BaseTool

const MINE_SCENE: PackedScene = preload(
    "res://scenes/tools/naval_mine.tscn"
)

@export var placement_radius: float = 12.0

var _mines_parent: Node2D
var _player: PlayerController
var _effects_parent: DistractionManager


func configure(mines_parent: Node2D, player: PlayerController, effects_parent: DistractionManager) -> void:
	_mines_parent = mines_parent
	_player = player
	_effects_parent = effects_parent

func activate(target: Vector2) -> void:
	if (_player.get_time_left(self) == 0):
		if _mines_parent == null:
			return
		# Reject placement on walls, players or monsters.
		var circle := CircleShape2D.new()
		circle.radius = placement_radius
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
		# Spawn the mine at the click location.
		var mine := MINE_SCENE.instantiate() as NavalMine
		_mines_parent.add_child(mine)
		mine.global_position = target
		mine.set_effects_parent(_effects_parent)
		print("Mine placed at: ", target)
		_player.toolUsed(self)
