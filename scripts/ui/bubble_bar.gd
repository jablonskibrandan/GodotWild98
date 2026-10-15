extends HBoxContainer

@export var bubble_health_path: NodePath
@export var pop_duration: float = 0.35

const BUBBLE_TEXTURE: Texture2D = preload("res://visuals/ui/bubble.png")
const BUBBLE_FRAME_SIZE := Vector2(16, 16)
const BUBBLE_FULL_FRAME := 13

var bubble_health: Node
var _previous_amount: int = 0
var _pop_tweens: Dictionary = {}


func _ready() -> void:
	bubble_health = get_node_or_null(bubble_health_path)
	if bubble_health == null:
		push_warning("BubbleBar: bubble_health_path is not assigned or is invalid.")
		return

	var max_bubbles: int = bubble_health.calculate_bubble_amount(bubble_health.bubble_max_time)
	for index in range(max_bubbles):
		var bubble_image := AtlasTexture.new()
		bubble_image.atlas = BUBBLE_TEXTURE
		bubble_image.region = Rect2(Vector2(BUBBLE_FULL_FRAME * 16, 0), BUBBLE_FRAME_SIZE)

		var icon := TextureRect.new()
		icon.texture = bubble_image
		icon.custom_minimum_size = BUBBLE_FRAME_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(icon)

	_previous_amount = clampi(bubble_health.bubble_amount, 0, get_child_count())
	_update_icons(_previous_amount)
	bubble_health.bubble_amount_changed.connect(_on_bubble_amount_changed)


func _on_bubble_amount_changed(amount: int) -> void:
	amount = clampi(amount, 0, get_child_count())
	for index in range(get_child_count()):
		var icon: TextureRect = get_child(index)
		if index >= amount and index < _previous_amount:
			_pop_bubble(icon)
		elif index < amount:
			_cancel_pop(icon)
			_set_bubble_frame(BUBBLE_FULL_FRAME, icon)
			icon.visible = true
	_previous_amount = amount


func _update_icons(amount: int) -> void:
	for index in range(get_child_count()):
		get_child(index).visible = index < amount


func _pop_bubble(icon: TextureRect) -> void:
	_cancel_pop(icon)
	icon.visible = true
	_set_bubble_frame(BUBBLE_FULL_FRAME, icon)
	var tween := create_tween()
	_pop_tweens[icon] = tween
	tween.tween_method(_set_bubble_frame.bind(icon), float(BUBBLE_FULL_FRAME), 0.0, pop_duration)
	tween.tween_callback(_finish_pop.bind(icon))


func _set_bubble_frame(frame: float, icon: TextureRect) -> void:
	var frame_index := clampi(roundi(frame), 0, BUBBLE_FULL_FRAME)
	var atlas: AtlasTexture = icon.texture
	atlas.region = Rect2(Vector2(frame_index * 16, 0), BUBBLE_FRAME_SIZE)


func _finish_pop(icon: TextureRect) -> void:
	_pop_tweens.erase(icon)
	icon.visible = false


func _cancel_pop(icon: TextureRect) -> void:
	if _pop_tweens.has(icon):
		var tween: Tween = _pop_tweens[icon]
		tween.kill()
		_pop_tweens.erase(icon)
