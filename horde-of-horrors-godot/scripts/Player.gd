extends CharacterBody2D

# Preloaded scenes to prevent dynamic disk reads during gameplay
const DAMAGE_NUMBER_SCENE = preload("res://scenes/DamageNumber.tscn")
const BAT_TEXTURE = preload("res://assets/sprites/vampire/bat.png")

@export var move_speed: float = 320.0
@export var max_health: int = 100
@export var fire_rate: float = 0.28
@export var damage: int = 12

@export_group("Editor Testing")
@export var test_starting_secondary_weapon: String = ""
@export var test_starting_secondary_level: int = 1

var current_health: int
var last_fire_time: float = 0.0
var is_aiming_with_mouse: bool = true
var last_movement_direction: Vector2 = Vector2.RIGHT
var is_bat_form: bool = false
var is_shielded: bool = false
var speed_boost_multiplier: float = 1.0
var damage_boost_flat: int = 0
var invulnerability_timer: float = 0.0
var invulnerability_duration: float = 0.6  # i-frames after hit

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

var current_weapon_node: Node2D = null
var primary_weapon_id: String = "crossbow"
var secondary_weapons: Array[Node2D] = []
var weapon_levels: Dictionary = {}

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var ability_icon: Control = get_node_or_null("../UI/AbilityIcon")

var move_input: Vector2 = Vector2.ZERO
var aim_position: Vector2 = Vector2.ZERO

# Platformer specifics
var gravity: float = 1400.0
var jump_velocity: float = -520.0
var double_jump_available: bool = true
var was_on_floor: bool = true

func _ready() -> void:
	collision_mask |= 8
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
			
			# If texture is 512px tall, it's an 8-layer stacked sprite
			# We show the whole stack (squashed in 2D) which creates the look you liked.
			# Brightness is fixed by disabling the PlayerLight in Player.tscn.
			if tex.get_height() == 512:
				sprite.vframes = 1
				sprite.frame = 0
				sprite.modulate = Color.WHITE
				# Normalize scaling based on the 'squashed' height
				var target_height = 154.0
				var scale_factor = target_height / 128.0 # Victor is roughly 128px tall in the stack
				sprite.scale = Vector2(scale_factor, scale_factor)
			else:
				sprite.vframes = 1
				sprite.frame = 0
				sprite.modulate = Color.WHITE
				# Dynamically normalize character sprite scaling
				var target_height = 154.0
				var scale_factor = target_height / tex.get_height()
				sprite.scale = Vector2(scale_factor, scale_factor)

	current_health = max_health
	GameManager.player = self
	_setup_visuals()
	_setup_weapon()
	_update_health_ui()
	_setup_ability_icon()

	# Adjust Camera limits and zoom for top-down arena level
	if camera:
		camera.limit_left = -1250
		camera.limit_right = 1250
		camera.limit_top = -950
		camera.limit_bottom = 950
		camera.zoom = Vector2(1.5, 1.5)

func _setup_visuals() -> void:
	var sprite = $Visuals/Sprite2D
	var polygons = $Visuals.get_children().filter(func(node): return node is Polygon2D)

	if sprite:
		for p in polygons:
			p.visible = false
		if has_node("CrossbowPivot/Weapon"):
			$CrossbowPivot/Weapon.visible = false

func _setup_weapon() -> void:
	var char_name = GameManager.selected_character
	if GameManager.CHARACTERS.has(char_name):
		primary_weapon_id = GameManager.CHARACTERS[char_name].get("starting_weapon", "crossbow")
		change_weapon(primary_weapon_id)

	# Editor testing helper for starting secondary weapons
	if test_starting_secondary_weapon != "":
		var lvl = clamp(test_starting_secondary_level, 1, 5)
		for i in range(lvl):
			change_weapon(test_starting_secondary_weapon)

func change_weapon(weapon_id: String) -> void:
	if not GameManager.WEAPONS.has(weapon_id):
		return
	
	var weapon_data = GameManager.WEAPONS[weapon_id]
	
	# If this is the primary weapon, set it up
	if weapon_id == primary_weapon_id:
		# Clear existing primary weapon
		if current_weapon_node:
			current_weapon_node.queue_free()
			current_weapon_node = null
			
		if weapon_data["scene"] != "":
			var scene = load(weapon_data["scene"])
			if scene:
				current_weapon_node = scene.instantiate()
				add_child(current_weapon_node)
				current_weapon_node.position = Vector2(10, 0)
				
				# Hide weapon visuals if character already has a baked weapon (Victor/Serena)
				var char_name = GameManager.selected_character
				if char_name == "Victor" or char_name == "Serena":
					var weapon_visuals = current_weapon_node.get_node_or_null("Visuals")
					if weapon_visuals:
						weapon_visuals.visible = false
				
			if crossbow_pivot:
				crossbow_pivot.visible = false
		else:
			# Use default crossbow
			if crossbow_pivot:
				crossbow_pivot.visible = true
		print("Player initialized primary weapon: ", weapon_data["name"])
	else:
		# Add as a secondary weapon instead of replacing the primary
		# If we already have this secondary weapon, we upgrade it!
		var existing_weapon: Node2D = null
		for w in secondary_weapons:
			if w.has_meta("weapon_id") and w.get_meta("weapon_id") == weapon_id:
				existing_weapon = w
				break
				
		if existing_weapon:
			var current_lvl = weapon_levels.get(weapon_id, 1)
			if current_lvl < 5:
				current_lvl += 1
				weapon_levels[weapon_id] = current_lvl
				if existing_weapon.has_method("set_level"):
					existing_weapon.set_level(current_lvl)
				print("Secondary weapon ", weapon_id, " upgraded to level ", current_lvl)
			else:
				print("Secondary weapon ", weapon_id, " is already at max level 5!")
			return
				
		# If not existing, unlock it (Level 1)
		if weapon_data["scene"] != "":
			var scene = load(weapon_data["scene"])
			if scene:
				var w_node = scene.instantiate()
				w_node.set_meta("weapon_id", weapon_id)
				add_child(w_node)
				w_node.position = Vector2(10, 0)
				
				# Hide weapon visuals if character already has a baked weapon (Victor/Serena)
				var char_name = GameManager.selected_character
				if char_name == "Victor" or char_name == "Serena":
					var weapon_visuals = w_node.get_node_or_null("Visuals")
					if weapon_visuals:
						weapon_visuals.visible = false
				
				secondary_weapons.append(w_node)
				weapon_levels[weapon_id] = 1
				if w_node.has_method("set_level"):
					w_node.set_level(1)
				print("Player unlocked secondary weapon: ", weapon_data["name"], " at Level 1")

func _update_health_ui() -> void:
	if has_node("/root/UIManager"):
		get_node("/root/UIManager").update_player_health(current_health, max_health)

func _setup_ability_icon() -> void:
	if not ability_icon: return

	var char_name = GameManager.selected_character
	var icon_container = ability_icon.get_node("IconContainer")
	for child in icon_container.get_children():
		child.visible = false

	match char_name:
		"Werewolf":
			icon_container.get_node("Dash").visible = true
		"Hunter":
			icon_container.get_node("RapidFire").visible = true
		"Frankenstein":
			icon_container.get_node("Fortitude").visible = true
		"Vampire":
			icon_container.get_node("Lifesteal").visible = true

func _update_ability_cooldown(delta: float) -> void:
	if ability_cooldown > 0:
		ability_cooldown -= delta
		if ability_cooldown < 0:
			ability_cooldown = 0
		_update_ability_ui()
		_update_ability_icon_visual()

func _update_ability_icon_visual() -> void:
	if not ability_icon: return
	var overlay = ability_icon.get_node("CooldownOverlay")
	if ability_cooldown > 0:
		overlay.visible = true
		# We could even scale the overlay to show progress
	else:
		overlay.visible = false

func _update_ability_ui() -> void:
	if has_node("/root/UIManager"):
		get_node("/root/UIManager").update_ability_cooldown(ability_cooldown)

func _physics_process(delta: float) -> void:
	if GameManager.is_game_over:
		return

	if invulnerability_timer > 0:
		invulnerability_timer -= delta
		if invulnerability_timer <= 0:
			invulnerability_timer = 0
			modulate.a = 1.0
		else:
			# Flashing effect
			modulate.a = 0.5 if Engine.get_frames_drawn() % 4 < 2 else 1.0

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

	velocity = input_dir * move_speed * speed_boost_multiplier

	if input_dir.x != 0:
		$Visuals.scale.x = 1.0 if input_dir.x > 0 else -1.0

	move_and_slide()
	_update_animation()
	_update_ability_cooldown(delta)

	# Clamp to screen boundaries (expanded for larger map play area)
	position.x = clamp(position.x, -1200, 1200)
	position.y = clamp(position.y, -900, 900)

	# Aiming (Aim at mouse or follow last movement direction)
	var aim_dir = last_movement_direction
	if is_aiming_with_mouse:
		var world_aim = get_global_mouse_position()
		aim_dir = (world_aim - global_position).normalized()
	
	if primary_weapon_id == "crossbow":
		if crossbow_pivot:
			crossbow_pivot.rotation = aim_dir.angle()
	elif current_weapon_node and is_instance_valid(current_weapon_node):
		current_weapon_node.rotation = aim_dir.angle()

	# Process secondary weapons automatic aiming and firing
	_process_secondary_weapons(delta)

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

	if primary_weapon_id != "crossbow":
		if current_weapon_node and is_instance_valid(current_weapon_node) and current_weapon_node.has_method("attack"):
			current_weapon_node.attack()
			last_fire_time = Time.get_ticks_msec() / 1000.0
			return
	else:
		var proj = PoolManager.get_object("res://scenes/Projectile.tscn")
		if proj:
			if proj.get_parent() != get_tree().current_scene:
				proj.get_parent().remove_child(proj)
				get_tree().current_scene.add_child(proj)
			proj.global_position = fire_point.global_position
			var dir = (fire_point.global_position - crossbow_pivot.global_position).normalized()
			proj.initialize(dir, damage + damage_boost_flat)

		last_fire_time = Time.get_ticks_msec() / 1000.0
		muzzle_flash.restart()
		AudioManager.play_sfx("shoot")

func _try_auto_fire() -> void:
	if Time.get_ticks_msec() / 1000.0 - last_fire_time < fire_rate:
		return
	if not GameManager.wave_manager:
		return

	var nearest = GameManager.wave_manager.get_nearest_enemy(global_position)
	if not nearest:
		return

	if primary_weapon_id != "crossbow":
		if current_weapon_node and is_instance_valid(current_weapon_node) and current_weapon_node.has_method("attack"):
			var dir = (nearest.global_position - global_position).normalized()
			current_weapon_node.rotation = dir.angle()
			current_weapon_node.attack()
			last_fire_time = Time.get_ticks_msec() / 1000.0
			return
	else:
		var proj = PoolManager.get_object("res://scenes/Projectile.tscn")
		if proj:
			if proj.get_parent() != get_tree().current_scene:
				proj.get_parent().remove_child(proj)
				get_tree().current_scene.add_child(proj)
			proj.global_position = fire_point.global_position

			var dir = (nearest.global_position - global_position).normalized()
			if crossbow_pivot:
				crossbow_pivot.rotation = dir.angle()

			var proj_dir = (fire_point.global_position - crossbow_pivot.global_position).normalized()
			proj.initialize(proj_dir, damage + damage_boost_flat)

		last_fire_time = Time.get_ticks_msec() / 1000.0
		muzzle_flash.restart()
		AudioManager.play_sfx("shoot")

func _process_secondary_weapons(delta: float) -> void:
	if is_bat_form:
		return
		
	var nearest = null
	if GameManager.wave_manager:
		nearest = GameManager.wave_manager.get_nearest_enemy(global_position)
		
	var secondary_aim_dir = last_movement_direction
	if nearest:
		secondary_aim_dir = (nearest.global_position - global_position).normalized()
	elif is_aiming_with_mouse:
		var world_aim = get_global_mouse_position()
		secondary_aim_dir = (world_aim - global_position).normalized()
		
	for w in secondary_weapons:
		if is_instance_valid(w):
			w.rotation = secondary_aim_dir.angle()
			if w.has_method("attack"):
				w.attack()

func take_damage(amount: int) -> void:
	if is_bat_form or is_shielded or invulnerability_timer > 0:
		return
	
	current_health -= amount
	AudioManager.play_sfx("player_hurt")
	invulnerability_timer = invulnerability_duration
	
	# Repel nearby enemies when hit
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.global_position.distance_to(global_position) < 80.0:
			if enemy.has_method("apply_knockback"):
				enemy.apply_knockback(global_position, 600.0)
	
	if current_health <= 0:
		current_health = 0
		GameManager.trigger_game_over()

	_update_health_ui()

	if GameManager.selected_character == "Vampire" and current_health < max_health * 0.30 and can_trigger_bat_escape:
		trigger_bat_escape()

	if DAMAGE_NUMBER_SCENE:
		var dmg_num = DAMAGE_NUMBER_SCENE.instantiate()
		get_parent().add_child(dmg_num)
		dmg_num.global_position = global_position
		dmg_num.setup(amount, true)

func trigger_bat_escape() -> void:
	is_bat_form = true
	can_trigger_bat_escape = false

	var normal_speed = move_speed
	move_speed = normal_speed * 1.6

	var sprite = $Visuals/Sprite2D

	# Spawn dark mist/particles
	_spawn_puff_particles(global_position, Color(0.18, 0.05, 0.28, 0.8))

	if sprite:
		human_texture = sprite.texture
		sprite.texture = BAT_TEXTURE
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

func apply_speed_boost(multiplier: float, duration: float) -> void:
	speed_boost_multiplier = multiplier
	modulate = Color(1.2, 1.2, 0.8) # Slight yellow glow
	get_tree().create_timer(duration).timeout.connect(func():
		speed_boost_multiplier = 1.0
		modulate = Color.WHITE
	)

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
		"Serena":
			_ability_serena_shadow_dash()
		"Victor":
			_ability_victor_stopping_power()

func _ability_serena_shadow_dash() -> void:
	# Serena's Shadow Dash is faster and leaves afterimages (simulated with puff)
	is_dashing = true
	ability_cooldown = 3.5 # Slightly faster cooldown than werewolf

	var dash_dir = last_movement_direction
	if velocity.length() > 0:
		dash_dir = velocity.normalized()

	velocity = dash_dir * move_speed * 4.0 # Faster dash

	# Visuals
	_spawn_puff_particles(global_position, Color(0.1, 0.05, 0.2, 0.8))
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(0.5, 0.2, 1.0, 0.6), 0.1)

	get_tree().create_timer(dash_duration).timeout.connect(func():
		is_dashing = false
		velocity = Vector2.ZERO
		var tween_back = create_tween()
		tween_back.tween_property(self, "modulate", Color.WHITE, 0.1)
	)

func _ability_victor_stopping_power() -> void:
	ability_cooldown = 10.0
	_panic_knockback(220.0, 950.0) # Clear area with a holy shockwave
	
	var original_damage_boost = damage_boost_flat
	damage_boost_flat += 20 # Add +20 damage stopping power
	
	# Visual feedback: golden/yellow glow modulation
	modulate = Color(1.8, 1.5, 0.3)
	
	# Spawn golden shockwave particles
	_spawn_puff_particles(global_position, Color(1.0, 0.85, 0.2, 0.8))
	
	get_tree().create_timer(4.0).timeout.connect(func():
		damage_boost_flat = original_damage_boost
		modulate = Color.WHITE
	)

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
	_panic_knockback(200.0, 800.0) # Clear immediate area
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
	_panic_knockback(250.0, 1000.0) # Stronger knockback for Frank
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
	_panic_knockback(180.0, 700.0)
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

func _panic_knockback(radius: float, force: float) -> void:
	_spawn_puff_particles(global_position, Color(1, 1, 1, 0.5))
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.global_position.distance_to(global_position) < radius:
			if enemy.has_method("apply_knockback"):
				enemy.apply_knockback(global_position, force)

var has_double_shot: bool = false
var is_ghost_form: bool = false

func apply_powerup(powerup: PowerUpData) -> void:
	if not powerup:
		return

	match powerup.type:
		PowerUpData.PowerUpType.HEAL:
			heal(int(powerup.value))
			_spawn_puff_particles(global_position, Color(0.2, 0.8, 0.2, 0.6))

		PowerUpData.PowerUpType.SPEED_BOOST:
			speed_boost_multiplier = powerup.value
			_spawn_puff_particles(global_position, Color(0.8, 0.8, 0.2, 0.6))
			modulate = Color(1.2, 1.2, 0.8)

			get_tree().create_timer(powerup.duration).timeout.connect(func():
				speed_boost_multiplier = 1.0
				modulate = Color.WHITE
			)

		PowerUpData.PowerUpType.DAMAGE_BOOST:
			damage_boost_flat = int(powerup.value)
			_spawn_puff_particles(global_position, Color(0.8, 0.2, 0.2, 0.6))
			modulate = Color(1.5, 0.8, 0.8)

			get_tree().create_timer(powerup.duration).timeout.connect(func():
				damage_boost_flat = 0
				modulate = Color.WHITE
			)

		PowerUpData.PowerUpType.SHIELD:
			is_shielded = true
			_spawn_puff_particles(global_position, Color(0.2, 0.6, 0.8, 0.6))
			modulate = Color(0.8, 0.8, 1.5)

			get_tree().create_timer(powerup.duration).timeout.connect(func():
				is_shielded = false
				modulate = Color.WHITE
			)
			
		PowerUpData.PowerUpType.VAMPIRE_KISS:
			# Temporary lifesteal: heal 25% of current health missing
			var missing = max_health - current_health
			heal(int(missing * 0.25))
			_spawn_puff_particles(global_position, Color(0.6, 0, 0.2, 0.8))
			modulate = Color(1.5, 0.5, 0.5)
			get_tree().create_timer(powerup.duration).timeout.connect(func():
				modulate = Color.WHITE
			)

		PowerUpData.PowerUpType.HOLY_NOVA:
			_spawn_puff_particles(global_position, Color(1, 1, 0.5, 0.8))
			_panic_knockback(300.0, 1200.0) # Larger radius and force
			# Deal damage to all in radius
			for enemy in get_tree().get_nodes_in_group("enemy"):
				if enemy.global_position.distance_to(global_position) < 300.0:
					if enemy.has_method("take_damage"):
						enemy.take_damage(int(powerup.value))
			AudioManager.play_sfx("holy_blast")

		PowerUpData.PowerUpType.TIME_SLOW:
			_spawn_puff_particles(global_position, Color(0.5, 0.5, 1.0, 0.6))
			Engine.time_scale = 0.5 # Slow down the whole game engine
			get_tree().create_timer(powerup.duration * 0.5).timeout.connect(func():
				Engine.time_scale = 1.0
			)

		PowerUpData.PowerUpType.DOUBLE_SHOT:
			has_double_shot = true
			modulate = Color(1.0, 0.5, 1.0)
			get_tree().create_timer(powerup.duration).timeout.connect(func():
				has_double_shot = false
				modulate = Color.WHITE
			)

		PowerUpData.PowerUpType.BLOOD_MOON_RAGE:
			is_shielded = true
			damage_boost_flat = 20
			speed_boost_multiplier = 1.5
			modulate = Color(2.0, 0.2, 0.2)
			_spawn_puff_particles(global_position, Color(1, 0, 0, 0.8))
			get_tree().create_timer(powerup.duration).timeout.connect(func():
				is_shielded = false
				damage_boost_flat = 0
				speed_boost_multiplier = 1.0
				modulate = Color.WHITE
			)

		PowerUpData.PowerUpType.GHOST_FORM:
			is_ghost_form = true
			is_shielded = true # Ghost can't be hit
			modulate.a = 0.4
			speed_boost_multiplier = 1.3
			get_tree().create_timer(powerup.duration).timeout.connect(func():
				is_ghost_form = false
				is_shielded = false
				modulate.a = 1.0
				speed_boost_multiplier = 1.0
			)

func shake_camera(intensity: float, _duration: float) -> void:
	if camera and camera.has_method("add_shake"):
		camera.add_shake(intensity)
