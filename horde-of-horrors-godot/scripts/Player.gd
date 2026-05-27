extends CharacterBody2D

@export var move_speed: float = 320.0
@export var max_health: int = 100
@export var fire_rate: float = 0.28
@export var damage: int = 12

var current_health: int
var last_fire_time: float = 0.0

@onready var crossbow_pivot: Node2D = $CrossbowPivot
@onready var fire_point: Node2D = $CrossbowPivot/FirePoint
@onready var camera: Camera2D = $Camera2D
@onready var muzzle_flash: CPUParticles2D = $CrossbowPivot/FirePoint/MuzzleFlash
@onready var shoot_sound: AudioStreamPlayer2D = $ShootSound
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var move_input: Vector2 = Vector2.ZERO
var aim_position: Vector2 = Vector2.ZERO

# Platformer specifics
var gravity: float = 1400.0
var jump_velocity: float = -520.0
var double_jump_available: bool = true
var was_on_floor: bool = true

func _ready() -> void:
	# Load selected character data dynamically
	var char_name = GameManager.selected_character
	if GameManager.CHARACTERS.has(char_name):
		var data = GameManager.CHARACTERS[char_name]
		max_health = data["health"]
		move_speed = data["speed"]
		damage = data["damage"]
		fire_rate = data["fire_rate"]
		
		var tex = load(data["texture"])
		if tex and %Sprite2D:
			%Sprite2D.texture = tex
			
	current_health = max_health
	GameManager.player = self
	_setup_visuals()
	_update_health_ui()

	# Adjust Camera limits for platformer side-scroller level
	if camera:
		camera.limit_left = -2000
		camera.limit_right = 2000
		camera.limit_top = -800
		camera.limit_bottom = 600

func _setup_visuals() -> void:
	var sprite = %Sprite2D
	var polygons = $Visuals.get_children().filter(func(node): return node is Polygon2D)
	
	if sprite and sprite.texture:
		for p in polygons:
			p.visible = false
		if has_node("CrossbowPivot/Weapon"):
			$CrossbowPivot/Weapon.visible = false

func _update_health_ui() -> void:
	var bar = get_node_or_null("../UI/HealthBar")
	var label = get_node_or_null("../UI/HealthBar/HealthLabel")
	if bar:
		bar.max_value = max_health
		bar.value = current_health
	if label:
		label.text = str(current_health) + " / " + str(max_health)

func _physics_process(delta: float) -> void:
	if GameManager.is_game_over:
		return

	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		double_jump_available = true

	# Read horizontal inputs
	var keyboard_input = Input.get_axis("move_left", "move_right")
	var direction = 0.0
	
	if keyboard_input != 0.0:
		direction = keyboard_input
	else:
		direction = move_input.x # Mobile drag horizontal input
		
	# Apply horizontal velocity
	if direction != 0.0:
		velocity.x = direction * move_speed
		# Flip visuals to face the movement direction
		$Visuals.scale.x = 1.0 if direction > 0 else -1.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 10.0 * delta)

	# Handle jump inputs
	var jump_just_pressed = Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("jump")
	
	if jump_just_pressed:
		if is_on_floor():
			velocity.y = jump_velocity
		elif double_jump_available:
			velocity.y = jump_velocity * 0.95 # Slightly weaker double jump
			double_jump_available = false

	move_and_slide()
	_update_animation()

	# Screen boundary clamps
	position.x = clamp(position.x, -1950, 1950)
	
	# Pit check
	if position.y > 580:
		take_damage(20)
		# Teleport back to center-top platform
		position = Vector2(0, -200)
		velocity = Vector2.ZERO

	# Aiming (Crossbow pivots towards mouse cursor on PC)
	if crossbow_pivot:
		var world_aim = get_global_mouse_position()
		var dir = (world_aim - crossbow_pivot.global_position).normalized()
		crossbow_pivot.rotation = dir.angle()

	# Mobile auto-fire, PC manual fire
	if OS.has_feature("mobile"):
		_try_auto_fire()
	else:
		if Input.is_action_pressed("fire"):
			_try_manual_fire()

func _try_manual_fire() -> void:
	if Time.get_ticks_msec() / 1000.0 - last_fire_time < fire_rate:
		return

	var proj_scene = preload("res://scenes/Projectile.tscn")
	var proj = proj_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = fire_point.global_position
	var dir = (fire_point.global_position - crossbow_pivot.global_position).normalized()
	proj.initialize(dir, damage)

	last_fire_time = Time.get_ticks_msec() / 1000.0
	muzzle_flash.restart()
	if shoot_sound:
		shoot_sound.play()

func _try_auto_fire() -> void:
	if Time.get_ticks_msec() / 1000.0 - last_fire_time < fire_rate:
		return
	if not GameManager.wave_manager:
		return

	var nearest = GameManager.wave_manager.get_nearest_enemy(global_position)
	if not nearest:
		return

	var proj_scene = preload("res://scenes/Projectile.tscn")
	var proj = proj_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = fire_point.global_position
	
	var dir = (nearest.global_position - global_position).normalized()
	if crossbow_pivot:
		crossbow_pivot.rotation = dir.angle()
	
	var proj_dir = (fire_point.global_position - crossbow_pivot.global_position).normalized()
	proj.initialize(proj_dir, damage)

	last_fire_time = Time.get_ticks_msec() / 1000.0
	muzzle_flash.restart()

func take_damage(amount: int) -> void:
	current_health -= amount
	if current_health <= 0:
		current_health = 0
		GameManager.trigger_game_over()
		
	_update_health_ui()
	
	var dmg_scene = load("res://scenes/DamageNumber.tscn")
	if dmg_scene:
		var dmg_num = dmg_scene.instantiate()
		get_parent().add_child(dmg_num)
		dmg_num.global_position = global_position
		dmg_num.setup(amount, true)

func upgrade_damage(amount: int) -> void:
	damage += amount
	print("Player damage upgraded to: ", damage)

func heal(amount: int) -> void:
	current_health = min(current_health + amount, max_health)
	_update_health_ui()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		aim_position = event.position

	# Mobile platformer screen inputs:
	# Touch/drag on the left side of the screen moves left, right moves right
	if event is InputEventScreenDrag or event is InputEventScreenTouch:
		var view_width = get_viewport_rect().size.x
		var touch_x = event.position.x
		var touch_y = event.position.y
		
		# Tap on the top half of the screen to jump
		if event is InputEventScreenTouch and event.pressed and touch_y < get_viewport_rect().size.y * 0.45:
			if is_on_floor():
				velocity.y = jump_velocity
			elif double_jump_available:
				velocity.y = jump_velocity * 0.95
				double_jump_available = false
		
		# Tap/drag on lower half of the screen handles horizontal movement
		if touch_y >= get_viewport_rect().size.y * 0.45:
			if event.pressed or event is InputEventScreenDrag:
				if touch_x < view_width * 0.5:
					move_input = Vector2(-1.0, 0) # Move Left
				else:
					move_input = Vector2(1.0, 0)  # Move Right
			else:
				move_input = Vector2.ZERO
		else:
			if event is InputEventScreenTouch and not event.pressed:
				move_input = Vector2.ZERO

func _update_animation() -> void:
	if not animation_player:
		return
	var anim_name = "idle"
	if abs(velocity.x) > 10.0:
		anim_name = "run"

	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name)