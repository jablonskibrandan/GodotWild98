extends Node2D

# Floor-specific wiring and level visuals.

@onready var player: PlayerController = $Player
@onready var cursor: TargetCursor = $TargetCursor
@onready var tool_manager: ToolManager = $ToolManager
@onready var flashlight: FlashlightTool = $ToolManager/Flashlight
@onready var distraction: DistractionTool = $ToolManager/Distraction
@onready var effects: DistractionManager = $DistractionEffects
@onready var bubble_health: BubbleHealth = $Player/Bubble_Health
@onready var key_count_label: Label = $HUD/HBoxContainer/KeyCountLabel
@onready var player_keys: PlayerKeys = $Player/Keys

@onready var tool_label: Label = $HUD/Panel/VBox/Tool
@onready var light_label: Label = $HUD/Panel/VBox/Light
@onready var flashlight_indicator: TextureRect = $HUD/FlashlightIndicator

const FLASHLIGHT_OFF_TEXTURE: Texture2D = preload("res://visuals/ui/ui_flashlight_off.png")
const FLASHLIGHT_ON_TEXTURE: Texture2D = preload("res://visuals/ui/ui_flashlight_on.png")
@onready var target_label: Label = $HUD/Panel/VBox/Target

@onready var naval_mine: NavalMineTool = $ToolManager/NavalMine
@onready var naval_mines: Node2D = $NavalMines

#set after floor loads
var monster_manager: MonsterManager
var starting_point: Node2D

func _ready() -> void:
	add_floor()
	
	player.configure(starting_point.global_position, cursor, effects)
	flashlight.configure(player, cursor)
	distraction.configure(effects, player)
	monster_manager.configure(player)
	naval_mine.configure(naval_mines, player, effects)
	player_keys.key_count_changed.connect(update_key_count)
	update_key_count(player_keys.key_count)
	
	tool_manager.tool_changed.connect(_on_tool_changed)
	flashlight.state_changed.connect(_on_flashlight_state_changed)
	cursor.target_moved.connect(_on_target_moved)
	effects.sound_made.connect(_on_sound_made)
	monster_manager.player_bitten.connect(_on_player_bitten)
	bubble_health.time_ran_out.connect(_on_out_of_breath)

	# Signals emitted by child _ready methods occur before the parent's _ready.
	# Explicitly seed the initial HUD state here.
	_on_tool_changed(tool_manager.get_selected_tool())
	_on_flashlight_state_changed(flashlight.enabled)
	_on_target_moved(cursor.global_position)

func add_floor():
	var floor_scene: PackedScene = load(FloorManager.get_next_floor())
	var floor_instance = floor_scene.instantiate()
	add_child(floor_instance)
	move_child(floor_instance, 0)
	monster_manager = $Floor/MonsterManager
	starting_point = $Floor/StartingPoint

func _on_out_of_breath():
	## get_tree().reload_current_scene()
	get_tree().change_scene_to_file.call_deferred("res://scenes/death_screen.tscn")
	FloorManager.floor_failed()
	return

func _on_tool_changed(tool: BaseTool) -> void:
	if tool == null:
		return
	tool_label.text = "Selected: " + tool.display_name
	cursor.set_target_color(tool.target_color)


func _on_flashlight_state_changed(is_enabled: bool) -> void:
	light_label.text = "Flashlight: " + ("ON" if is_enabled else "OFF")
	flashlight_indicator.texture = FLASHLIGHT_ON_TEXTURE if is_enabled else FLASHLIGHT_OFF_TEXTURE
	player.toggle_flashlight(is_enabled)


func _on_target_moved(target: Vector2) -> void:
	target_label.text = "Target: (%d, %d)" % [roundi(target.x), roundi(target.y)]

func _on_sound_made(source: Node2D, volume: float):
	monster_manager.sound_made(source, volume)

func _on_player_bitten() -> void:
	print("Player bitten!")
	bubble_health.take_bubble_hit(1)
	player.take_hit()
	print("Bubbles remaining: ", bubble_health.bubble_amount)


func update_key_count(count: int) -> void:
	key_count_label.text = "x " + str(count)
