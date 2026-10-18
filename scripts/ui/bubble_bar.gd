extends HBoxContainer

@export var bubble_health_path: NodePath
@export var pop_duration: float = 0.35

const BUBBLE_TEXTURE: Texture2D = preload("res://visuals/ui/bubble.png")
const BUBBLE_FRAME_SIZE := Vector2(16, 16)
const BUBBLE_FULL_FRAME := 13

var bubble_health: BubbleHealth
var _previous_amount: int = 0
var _natural_losses_pending: int = 0
var _pop_tweens: Dictionary = {}


func _ready() -> void:
	bubble_health = get_node_or_null(bubble_health_path) as BubbleHealth
	if bubble_health == null:
		push_warning("BubbleBar: bubble_health_path is not assigned or is invalid.")
		set_process(false)
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
		icon.pivot_offset = BUBBLE_FRAME_SIZE * 0.5
		add_child(icon)

	_previous_amount = clampi(bubble_health.bubble_amount, 0, get_child_count())
	_update_icons(_previous_amount)
	bubble_health.bubble_lost_naturally.connect(_on_natural_bubble_loss)
	bubble_health.bubble_amount_changed.connect(_on_bubble_amount_changed)
	_update_countdown_bubble()


func _process(_delta: float) -> void:
	_update_countdown_bubble()


## Only the last visible bubble shrinks, 10s = 2/3, 5s = 1/3.
func _update_countdown_bubble() -> void:
	if _previous_amount <= 0:
		return
	var icon: TextureRect = get_child(_previous_amount - 1) as TextureRect
	if not _pop_tweens.has(icon):
		var remaining_fraction: float = bubble_health.get_active_bubble_fraction()
		icon.scale = Vector2.ONE * remaining_fraction


func _on_natural_bubble_loss(count: int) -> void:
	_natural_losses_pending += count


func _on_bubble_amount_changed(amount: int) -> void:
	amount = clampi(amount, 0, get_child_count())
	var naturally_lost: int = mini(_natural_losses_pending, maxi(_previous_amount - amount, 0))
	for index in range(get_child_count()):
		var icon: TextureRect = get_child(index) as TextureRect
		if index >= amount and index < _previous_amount:
			if naturally_lost > 0:
				_cancel_pop(icon)
				icon.visible = false
				icon.scale = Vector2.ONE
				naturally_lost -= 1
			else:
				_pop_bubble(icon)
		elif index < amount:
			_cancel_pop(icon)
			_set_bubble_frame(BUBBLE_FULL_FRAME, icon)
			icon.scale = Vector2.ONE
			icon.visible = true
	_natural_losses_pending = 0
	_previous_amount = amount
	_update_countdown_bubble()


func _update_icons(amount: int) -> void:
	for index in range(get_child_count()):
		get_child(index).visible = index < amount


func _pop_bubble(icon: TextureRect) -> void:
	_cancel_pop(icon)
	icon.visible = true
	# A bite/mine still uses the existing full pop animation.
	icon.scale = Vector2.ONE
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
	icon.scale = Vector2.ONE


func _cancel_pop(icon: TextureRect) -> void:
	if _pop_tweens.has(icon):
		var tween: Tween = _pop_tweens[icon]
		tween.kill()
		_pop_tweens.erase(icon)
