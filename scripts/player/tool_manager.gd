class_name ToolManager
extends Node2D

signal tool_changed(tool: BaseTool)

var _tools: Array[BaseTool] = []
var _selected_index: int = 0


func _ready() -> void:
	for child in get_children():
		if child is BaseTool:
			_tools.append(child as BaseTool)

	if _tools.is_empty():
		push_error("ToolManager requires at least one BaseTool child.")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("tool_next"):
		_select_next_tool()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("tool_use"):
		var tool: BaseTool = get_selected_tool()
		if tool != null:
			tool.activate(get_global_mouse_position())
		get_viewport().set_input_as_handled()


func get_selected_tool() -> BaseTool:
	if _tools.is_empty():
		return null
	return _tools[_selected_index]


func _select_next_tool() -> void:
	if _tools.is_empty():
		return
	_selected_index = (_selected_index + 1) % _tools.size()
	tool_changed.emit(get_selected_tool())
