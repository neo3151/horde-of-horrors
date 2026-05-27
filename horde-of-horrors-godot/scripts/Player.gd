extends CharacterBody2D

@export var move_speed: float = 320.0
@export var max_health: int = 100
@export var fire_rate: float = 0.28
@export var damage: int = 12

var current_health: int
var last_fire_time: float = 0.0
var is_aiming_with_mouse: bool = true
var last_movement_direction: Vector2 = Vector2.RIGHT
var is_bat_form: bool = false

# Ability states
var is_dashing: bool = false
var dash_duration: float = 0.2
var dash_speed_multiplier: float = 3.5
var ability_cooldown: float = 0.0
var ability_cooldown_max: float = 5.0
var can_trigger_bat_escape: bool = true
var bat_escape_duration: float = 2.5
var bat_escape_cooldown: float = 20.0
var human_texture: Texture2D

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
		var sprite = $Visuals/Sprite2D
		if tex and sprite:
			sprite.texture = tex
			
	current_health = max_health
	GameManager.player = self
	_setup_visuals()
	_update_health_ui()

	# Adjust Camera limits for top-down arena level
	if camera:
		camera.limit_left = -600
		camera.limit_right = 600
		camera.limit_top = -500
		camera.limit_bottom = 500

func _setup_visuals() -> void:
	var sprite = $Visuals/Sprite2D
	var polygons = $Visuals.get_children().filter(func(node): return node is Polygon2D)
	
	if sprite:
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

func _update_ability_cooldown(delta: float) -> void:
	if ability_cooldown > 0:
		ability_cooldown -= delta
		if ability_cooldown < 0:
			ability_cooldown = 0
		_update_ability_ui()

func _update_ability_ui() -> void:
	var label = get_node_or_null("../UI/AbilityCooldown")
	if label:
		if ability_cooldown > 0:
			label.text = "Ability: %.1fs" % ability_cooldown
			label.modulate = Color(1, 0.3, 0.3)
		else:
			label.text = "Ability: READY"
			label.modulate = Color(0.3, 1, 0.3)

func _physics_process(delta: float) -> void:
	if GameManager.is_game_over:
		return

	if is_dashing:
		return

	# Keyboard movement input
	var keyboard_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var input_dir = Vector2.ZERO

	if keyboard_input != Vector2.ZERO:
		input_dir = keyboard_input
		last_movement_direction = keyboard_input.normalized()
		is_aiming_with_mouse = false
	else:
		input_dir = move_input # Touch/Mouse drag fallback

	velocity = input_dir * move_speed
	
	if input_dir.x != 0:
		$Visuals.scale.x = 1.0 if input_dir.x > 0 else -1.0
		
	move_and_slide()
	_update_animation()
	_update_ability_cooldown(delta)

	# Clamp to screen boundaries
	position.x = clamp(position.x, -380, 380)
	position.y = clamp(position.y, -280, 280)

	# Aiming (Aim at mouse or follow last movement direction)
	if crossbow_pivot:
		if is_aiming_with_mouse:
			var world_aim = get_global_mouse_position()
			var dir = (world_aim - crossbow_pivot.global_position).normalized()
			crossbow_pivot.rotation = dir.angle()
		else:
			crossbow_pivot.rotation = last_movement_direction.angle()

	# Mobile auto-fire, PC manual fire
	if not is_bat_form:
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
	if is_bat_form:
		return
	current_health -= amount
	if current_health <= 0:
		current_health = 0
		GameManager.trigger_game_over()
		
	_update_health_ui()
	
	if GameManager.selected_character == "Vampire" and current_health < max_health * 0.30 and can_trigger_bat_escape:
		trigger_bat_escape()
	
	var dmg_scene = load("res://scenes/DamageNumber.tscn")
	if dmg_scene:
		var dmg_num = dmg_scene.instantiate()
		get_parent().add_child(dmg_num)
		dmg_num.global_position = global_position
		dmg_num.setup(amount, true)

func trigger_bat_escape() -> void:
	is_bat_form = true
	can_trigger_bat_escape = false
	
	var normal_speed = move_speed
	move_speed = normal_speed * 1.6
	
	var sprite = $Visuals/Sprite2D
	var bat_texture = load("res://assets/sprites/vampire/bat.png")
	
	# Spawn dark mist/particles
	_spawn_puff_particles(global_position, Color(0.18, 0.05, 0.28, 0.8))
	
	if sprite:
		human_texture = sprite.texture
		sprite.texture = bat_texture
		sprite.self_modulate = Color(0.65, 0.25, 0.85, 0.85)
		
		# Squash animation transition
		var tween = create_tween()
		sprite.scale = Vector2(0.1, 0.1)
		tween.tween_property(sprite, "scale", Vector2(0.55, 0.55), 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		
	print("Player Dracula entered Bat Form (invulnerable, high speed)!")
	
	get_tree().create_timer(bat_escape_duration).timeout.connect(func():
		is_bat_form = false
		move_speed = normal_speed
		
		_spawn_puff_particles(global_position, Color(0.18, 0.05, 0.28, 0.8))
		
		if sprite:
			sprite.texture = human_texture
			sprite.self_modulate = Color.WHITE
			
			var tween = create_tween()
			sprite.scale = Vector2(0.1, 0.1)
			tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			
		print("Player Dracula transformed back to humanoid form.")
		
		get_tree().create_timer(bat_escape_cooldown).timeout.connect(func():
			can_trigger_bat_escape = true
			print("Player Dracula's Bat Escape is off cooldown.")
		)
	)

func _spawn_puff_particles(pos: Vector2, color: Color) -> void:
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.amount = 24
	particles.one_shot = true
	particles.explosiveness = 0.85
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 55.0
	particles.initial_velocity_max = 110.0
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0
	particles.color = color
	get_parent().add_child(particles)
	particles.global_position = pos
	particles.emitting = true
	get_tree().create_timer(1.0).timeout.connect(func():
		particles.queue_free()
	)

func upgrade_damage(amount: int) -> void:
	damage += amount
	print("Player damage upgraded to: ", damage)

func heal(amount: int) -> void:
	current_health = min(current_health + amount, max_health)
	_update_health_ui()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		aim_position = event.position
		is_aiming_with_mouse = true
	elif event is InputEventMouseButton:
		is_aiming_with_mouse = true
	elif event is InputEventKey:
		if event.pressed:
			is_aiming_with_mouse = false
			if event.keycode == KEY_SHIFT or event.keycode == KEY_E:
				use_ability()

	# Handle touch dragging / mouse dragging to move
	if event is InputEventScreenDrag or (event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
		var player_screen_pos = get_global_transform_with_canvas().origin
		move_input = (event.position - player_screen_pos).normalized()

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var player_screen_pos = get_global_transform_with_canvas().origin
			move_input = (event.position - player_screen_pos).normalized()
		else:
			move_input = Vector2.ZERO

	elif event is InputEventScreenTouch:
		if event.pressed:
			var player_screen_pos = get_global_transform_with_canvas().origin
			move_input = (event.position - player_screen_pos).normalized()
		else:
			move_input = Vector2.ZERO

func use_ability() -> void:
	if ability_cooldown > 0 or is_bat_form or is_dashing:
		return
	
	var char_name = GameManager.selected_character
	match char_name:
		"Werewolf":
			_ability_werewolf_dash()
		"Hunter":
			_ability_hunter_rapid_fire()
		"Frankenstein":
			_ability_frankenstein_fortitude()
		"Vampire":
			_ability_vampire_lifesteal()

func _ability_werewolf_dash() -> void:
	is_dashing = true
	ability_cooldown = 4.0
	
	var dash_dir = last_movement_direction
	if velocity.length() > 0:
		dash_dir = velocity.normalized()
	
	velocity = dash_dir * move_speed * dash_speed_multiplier
	
	# Visuals
	_spawn_puff_particles(global_position, Color(0.4, 0.3, 0.2, 0.6))
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.5, 0.1)
	
	get_tree().create_timer(dash_duration).timeout.connect(func():
		is_dashing = false
		velocity = Vector2.ZERO
		var tween_back = create_tween()
		tween_back.tween_property(self, "modulate:a", 1.0, 0.1)
	)

func _ability_hunter_rapid_fire() -> void:
	ability_cooldown = 8.0
	var original_fire_rate = fire_rate
	fire_rate = original_fire_rate * 0.4
	
	# Visual feedback
	modulate = Color(1.0, 1.0, 0.5) # Yellow tint
	
	get_tree().create_timer(3.0).timeout.connect(func():
		fire_rate = original_fire_rate
		modulate = Color.WHITE
	)

func _ability_frankenstein_fortitude() -> void:
	ability_cooldown = 10.0
	var original_speed = move_speed
	# Hardened state: slower but much tougher (simulated here with higher health/temp armor)
	move_speed = original_speed * 0.7
	
	# Add temporary "armor" by reducing incoming damage logic
	# For now, let's just show a visual shield
	var shield_visual = Color(0.5, 1.0, 0.5, 0.5)
	modulate = Color(0.5, 2.0, 0.5)
	
	get_tree().create_timer(4.0).timeout.connect(func():
		move_speed = original_speed
		modulate = Color.WHITE
	)

func _ability_vampire_lifesteal() -> void:
	ability_cooldown = 12.0
	# Next 5 shots heal for 20% of damage dealt
	# Simple implementation: burst heal for now
	heal(20)
	_spawn_puff_particles(global_position, Color(0.8, 0.1, 0.1, 0.7))

func _update_animation() -> void:
	if not animation_player:
		return
	var anim_name = "idle"
	if velocity.length() > 10.0:
		anim_name = "run"

	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name)