extends Control

signal joystick_moved(direction: Vector2)

@export var joystick_radius: float = 60.0
@export var dead_zone: float = 8.0

@onready var base: TextureRect = $Base
@onready var nub: TextureRect = $Nub

var _touch_index: int = -1
var _center: Vector2 = Vector2.ZERO
var _direction: Vector2 = Vector2.ZERO

var direction: Vector2:
	get: return _direction

func _ready() -> void:
	_center = size / 2.0
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			if _is_within_joystick(event.position):
				_touch_index = event.index
				_center = event.position
				_update_nub(event.position)
		elif not event.pressed and event.index == _touch_index:
			_release()

	elif event is InputEventScreenDrag:
		if event.index == _touch_index:
			_update_nub(event.position)

func _is_within_joystick(pos: Vector2) -> bool:
	return pos.x < get_viewport_rect().size.x * 0.5

func _update_nub(touch_pos: Vector2) -> void:
	var delta: Vector2 = touch_pos - _center
	var clamped: Vector2 = delta.limit_length(joystick_radius)
	nub.position = _center + clamped - nub.size / 2.0

	if delta.length() > dead_zone:
		_direction = (clamped / joystick_radius)
	else:
		_direction = Vector2.ZERO

	joystick_moved.emit(_direction)

func _release() -> void:
	_touch_index = -1
	_direction = Vector2.ZERO
	nub.position = base.position + (base.size - nub.size) / 2.0
	joystick_moved.emit(Vector2.ZERO)

func _process(_delta: float) -> void:
	if _touch_index != -1:
		joystick_moved.emit(_direction)

func get_direction() -> Vector2:
	return _direction
