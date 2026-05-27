extends CharacterBody2D

@export var speed: float = 300.0
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.5

var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_direction: Vector2 = Vector2.ZERO
var _dash_cooldown_timer: float = 0.0

func _ready() -> void:
	GameManager.player = self

func _physics_process(delta: float) -> void:
	_handle_dash_cooldown(delta)

	if _is_dashing:
		_handle_dashing(delta)
	else:
		_handle_movement()
		_handle_dash_input()

	move_and_slide()

func _handle_dash_cooldown(delta: float) -> void:
	if _dash_cooldown_timer > 0:
		_dash_cooldown_timer -= delta

func _handle_movement() -> void:
	var input_vector = Vector2.ZERO

	# Touch input (assuming a virtual joystick will be implemented elsewhere)
	# For now, simulate with keyboard or mouse drag
	if Input.is_action_pressed("move_right"): input_vector.x += 1
	if Input.is_action_pressed("move_left"): input_vector.x -= 1
	if Input.is_action_pressed("move_down"): input_vector.y += 1
	if Input.is_action_pressed("move_up"): input_vector.y -= 1

	# Normalize input vector to prevent faster diagonal movement
	velocity = input_vector.normalized() * speed

func _handle_dash_input() -> void:
	# Example: Double tap or specific button for dash
	if Input.is_action_just_pressed("dash") and _dash_cooldown_timer <= 0:
		_start_dash()

func _start_dash() -> void:
	_is_dashing = true
	_dash_timer = dash_duration
	_dash_cooldown_timer = dash_cooldown

	# Dash in current movement direction, or last direction if standing still
	if velocity.length() > 0:
		_dash_direction = velocity.normalized()
	else:
		# If standing still, dash in a default direction (e.g., last input, or right)
		_dash_direction = Vector2.RIGHT # Placeholder, refine later
		
	velocity = _dash_direction * dash_speed

func _handle_dashing(delta: float) -> void:
	_dash_timer -= delta
	if _dash_timer <= 0:
		_is_dashing = false
		velocity = Vector2.ZERO # Stop dash movement, resume normal input next frame
