extends Control

signal joystick_moved(direction: Vector2)

@export var joystick_radius: float = 60.0
@export var dead_zone: float = 8.0

@onready var base: TextureRect = $Base
@onready var nub: TextureRect = $Nub

var _touch_index: int = -1
var _active: bool = false
var _center: Vector2 = Vector2.ZERO
var _direction: Vector2 = Vector2.ZERO

var direction: Vector2:
	get: return _direction

func _ready() -> void:
	# Make the joystick control fill the bottom 40% of the screen dynamically
	anchor_top = 0.6
	anchor_bottom = 1.0
	anchor_left = 0.0
	anchor_right = 1.0
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	_create_procedural_textures()
	
	# Hide base and nub by default (invisible until touched)
	base.self_modulate.a = 0.0
	nub.self_modulate.a = 0.0

func _create_procedural_textures() -> void:
	# Create Base Texture (Soft disk with a glowing ring outline)
	var base_grad = Gradient.new()
	base_grad.offsets = [0.0, 0.75, 0.82, 0.9, 1.0]
	base_grad.colors = [
		Color(1, 1, 1, 0.15),
		Color(1, 1, 1, 0.1),
		Color(1, 1, 1, 0.45), # Ring outline
		Color(1, 1, 1, 0.3),
		Color(1, 1, 1, 0.0)
	]
	
	var base_tex = GradientTexture2D.new()
	base_tex.gradient = base_grad
	base_tex.fill = GradientTexture2D.FILL_RADIAL
	base_tex.fill_from = Vector2(0.5, 0.5)
	base_tex.fill_to = Vector2(0.5, 0.0)
	base_tex.width = 160
	base_tex.height = 160
	base.texture = base_tex
	
	# Create Nub Texture (Solid soft disk with a center highlight)
	var nub_grad = Gradient.new()
	nub_grad.offsets = [0.0, 0.2, 0.8, 1.0]
	nub_grad.colors = [
		Color(1, 1, 1, 0.9),
		Color(1, 1, 1, 0.75),
		Color(1, 1, 1, 0.4),
		Color(1, 1, 1, 0.0)
	]
	
	var nub_tex = GradientTexture2D.new()
	nub_tex.gradient = nub_grad
	nub_tex.fill = GradientTexture2D.FILL_RADIAL
	nub_tex.fill_from = Vector2(0.5, 0.5)
	nub_tex.fill_to = Vector2(0.5, 0.0)
	nub_tex.width = 60
	nub_tex.height = 60
	nub.texture = nub_tex

func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return

	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			if event.position.y > get_viewport_rect().size.y * 0.6:
				_touch_index = event.index
				_activate(event.position)
		elif not event.pressed and event.index == _touch_index:
			_release()

	elif event is InputEventScreenDrag:
		if event.index == _touch_index:
			_update_nub(event.position)

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and _touch_index == -1 and not _active:
				if event.position.y > get_viewport_rect().size.y * 0.6:
					_active = true
					_activate(event.position)
			elif not event.pressed and _active:
				_release()

	elif event is InputEventMouseMotion:
		if _active:
			_update_nub(event.position)

func _activate(pos: Vector2) -> void:
	_center = pos
	
	# Place base centered at the touch point
	base.global_position = _center - base.size / 2.0
	
	# Fade in (semi-transparent)
	base.self_modulate.a = 0.35
	nub.self_modulate.a = 0.6
	
	_update_nub(pos)

func _update_nub(touch_pos: Vector2) -> void:
	var delta: Vector2 = touch_pos - _center
	var clamped: Vector2 = delta.limit_length(joystick_radius)
	
	# Center the nub at the clamped global position
	nub.global_position = _center + clamped - nub.size / 2.0

	if delta.length() > dead_zone:
		_direction = (clamped / joystick_radius)
	else:
		_direction = Vector2.ZERO

	joystick_moved.emit(_direction)
	
	if is_instance_valid(GameManager.player):
		GameManager.player.move_input = _direction

func _release() -> void:
	_touch_index = -1
	_active = false
	_direction = Vector2.ZERO
	
	# Fade out
	base.self_modulate.a = 0.0
	nub.self_modulate.a = 0.0
	
	joystick_moved.emit(Vector2.ZERO)
	
	if is_instance_valid(GameManager.player):
		GameManager.player.move_input = Vector2.ZERO

func _process(_delta: float) -> void:
	if _touch_index != -1 or _active:
		joystick_moved.emit(_direction)
		if is_instance_valid(GameManager.player):
			GameManager.player.move_input = _direction

func get_direction() -> Vector2:
	return _direction

