class_name BaseTool
extends Node2D

# Add more tools as children of ToolManager. Their order is the cycle order.
@export var display_name: String = "Tool"
@export var target_color: Color = Color.WHITE


func activate(_target: Vector2) -> void:
	push_error("Tool '%s' must implement activate()." % display_name)
