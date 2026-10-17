extends Node2D

# Floor-specific wiring and level visuals.
@export var play_area: Rect2 = Rect2(48.0, 80.0, 864.0, 472.0)
@export_range(8, 128, 8) var grid_size: int = 48

@onready var player: PlayerController = $Player
@onready var cursor: TargetCursor = $TargetCursor
@onready var tool_manager: ToolManager = $ToolManager
@onready var flashlight: FlashlightTool = $ToolManager/Flashlight
@onready var distraction: DistractionTool = $ToolManager/Distraction
@onready var effects: DistractionManager = $DistractionEffects
@onready var monster_manager: MonsterManager = $MonsterManager
@onready var bubble_health: BubbleHealth = $Player/Bubble_Health

@onready var tool_label: Label = $HUD/Panel/VBox/Tool
@onready var light_label: Label = $HUD/Panel/VBox/Light
@onready var target_label: Label = $HUD/Panel/VBox/Target

@onready var naval_mine: NavalMineTool = $ToolManager/NavalMine
@onready var naval_mines: Node2D = $NavalMines

func _ready() -> void:
	player.configure(play_area, cursor)
	flashlight.configure(player, cursor)
	distraction.configure(play_area, effects, player)
	monster_manager.configure(player)
	naval_mine.configure(play_area, naval_mines)
	tool_manager.tool_changed.connect(_on_tool_changed)
	flashlight.state_changed.connect(_on_flashlight_state_changed)
	cursor.target_moved.connect(_on_target_moved)
	effects.sound_made.connect(_on_sound_made)
	monster_manager.player_bitten.connect(_on_player_bitten)

	# Signals emitted by child _ready methods occur before the parent's _ready.
	# Explicitly seed the initial HUD state here.
	_on_tool_changed(tool_manager.get_selected_tool())
	_on_flashlight_state_changed(flashlight.enabled)
	_on_target_moved(cursor.global_position)


func _on_tool_changed(tool: BaseTool) -> void:
	if tool == null:
		return
	tool_label.text = "Selected: " + tool.display_name
	cursor.set_target_color(tool.target_color)


func _on_flashlight_state_changed(is_enabled: bool) -> void:
	light_label.text = "Flashlight: " + ("ON" if is_enabled else "OFF")


func _on_target_moved(target: Vector2) -> void:
	target_label.text = "Target: (%d, %d)" % [roundi(target.x), roundi(target.y)]

func _on_sound_made(source: Node2D, volume: float):
	monster_manager.sound_made(source, volume)

func _on_player_bitten() -> void:
	print("Player bitten!")
	bubble_health.take_bubble_hit(1)
	print("Bubbles remaining: ", bubble_health.bubble_amount)
	print("stealth: ", player.stealth)
