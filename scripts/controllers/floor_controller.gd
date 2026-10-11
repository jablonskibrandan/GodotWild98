extends Node2D

# Floor-specific wiring and level visuals.
@export var play_area: Rect2 = Rect2(48.0, 80.0, 864.0, 472.0)
@export_range(8, 128, 8) var grid_size: int = 48

@onready var player: PlayerController = $Player
@onready var cursor: TargetCursor = $TargetCursor
@onready var tool_manager: ToolManager = $ToolManager
@onready var flashlight: FlashlightTool = $ToolManager/Flashlight
@onready var distraction: DistractionTool = $ToolManager/Distraction
@onready var effects: Node2D = $DistractionEffects

@onready var tool_label: Label = $HUD/Panel/VBox/Tool
@onready var light_label: Label = $HUD/Panel/VBox/Light
@onready var target_label: Label = $HUD/Panel/VBox/Target


func _ready() -> void:
	player.configure(play_area, cursor)
	flashlight.configure(player, cursor)
	distraction.configure(play_area, effects)

	tool_manager.tool_changed.connect(_on_tool_changed)
	flashlight.state_changed.connect(_on_flashlight_state_changed)
	cursor.target_moved.connect(_on_target_moved)

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


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color("#101722"), true)
	draw_rect(play_area, Color("#202c3a"), true)

	for x in range(int(play_area.position.x), int(play_area.end.x) + 1, grid_size):
		draw_line(Vector2(x, play_area.position.y), Vector2(x, play_area.end.y), Color("#2c3949"), 1.0)
	for y in range(int(play_area.position.y), int(play_area.end.y) + 1, grid_size):
		draw_line(Vector2(play_area.position.x, y), Vector2(play_area.end.x, y), Color("#2c3949"), 1.0)

	draw_rect(play_area, Color("#63748a"), false, 3.0)
