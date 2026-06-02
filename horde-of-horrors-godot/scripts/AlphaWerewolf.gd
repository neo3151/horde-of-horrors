# AlphaWerewolf.gd
extends CharacterBody2D

# Preloaded scenes/resources to prevent gameplay stutters
const DAMAGE_NUMBER_SCENE = preload("res://scenes/DamageNumber.tscn")
const BLOOD_DECAL_SCENE = preload("res://scenes/BloodDecal.tscn")
const FURY_DATA = preload("res://resources/powerups/FuryData.tres")

@export var max_health: int = 450
@export var speed: float = 210.0
@export var damage: int = 25
@export var points: int = 150

var current_health: int
var player: Node2D
var has_force_field: bool = false
var force_field_cooldowns: Array[float] = [0.60, 0.25] # Health percentage gates
var health_bar: ProgressBar

var attack_cooldown: float = 0.8 # Attack every 0.8 seconds of contact
var time_since_last_attack: float = 0.0

# Boss State Machine for dynamic, fun behavior
enum BossState { HOWL, CHASE, CIRCLE, PREPARE_LUNGE, LUNGE, RECOVER }
var current_state: BossState = BossState.HOWL
var state_timer: float = 0.0
var lunge_direction: Vector2 = Vector2.ZERO
var circle_direction: float = 1.0 # 1 or -1 for clockwise/counter-clockwise

# Visual feedback components
@onready var sprite = $Visuals/Sprite2D

func _ready() -> void:
	current_health = max_health
	player = GameManager.player
	add_to_group("enemy")
	
	_create_health_bar()
	
	# Configure visual body color to be blood crimson/dark
	var body = get_node_or_null("Visuals/Body")
	if body:
		body.color = Color(0.65, 0.1, 0.1)

func _create_health_bar() -> void:
	health_bar = ProgressBar.new()
	add_child(health_bar)
	health_bar.show_percentage = false
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.position = Vector2(-30, -50)
	health_bar.size = Vector2(60, 6)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.9, 0.1, 0.1)
	health_bar.add_theme_stylebox_override("fill", fill_style)
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.7)
	health_bar.add_theme_stylebox_override("background", bg_style)

func _physics_process(delta: float) -> void:
	if not player or GameManager.is_game_over:
		return

	# State Machine Logic
	state_timer += delta
	var to_player = player.global_position - global_position
	var dist_to_player = to_player.length()
	var dir_to_player = to_player.normalized()

	match current_state:
		BossState.HOWL:
			velocity = Vector2.ZERO
			# Visual effect: Rapidly flash crimson/blood red to represent howling
			if int(state_timer * 10) % 2 == 0:
				modulate = Color(3.0, 0.3, 0.3)
			else:
				modulate = Color.WHITE
				
			if state_timer >= 2.0: # Howl for 2 seconds at start, then chase
				current_state = BossState.CHASE
				state_timer = 0.0
				modulate = Color.WHITE

		BossState.CHASE:
			velocity = dir_to_player * speed
			if state_timer >= 3.0: # Chase for 3 seconds, then circle
				current_state = BossState.CIRCLE
				state_timer = 0.0
				circle_direction = 1.0 if randf() > 0.5 else -1.0

		BossState.CIRCLE:
			# Circle around the player (tangent direction)
			var tangent = Vector2(-dir_to_player.y, dir_to_player.x) * circle_direction
			# Mix tangent with slight retreat (0.8 tangent + 0.2 away) to back off slightly
			var circle_dir = (tangent * 0.85 - dir_to_player * 0.15).normalized()
			velocity = circle_dir * (speed * 0.8)
			
			if state_timer >= 1.8: # Circle for 1.8 seconds, then prepare lunge
				current_state = BossState.PREPARE_LUNGE
				state_timer = 0.0
				# Brief flash yellow warning
				var flash_tween = create_tween()
				modulate = Color(2.0, 1.8, 0.5)
				flash_tween.tween_property(self, "modulate", Color.WHITE, 0.4)

		BossState.PREPARE_LUNGE:
			velocity = Vector2.ZERO # Stop moving to telegraph the attack
			if state_timer >= 0.5: # 0.5s telegraph window
				current_state = BossState.LUNGE
				state_timer = 0.0
				lunge_direction = dir_to_player
				# Unleash crimson lunge roar flash
				var flash_tween = create_tween()
				modulate = Color(2.5, 0.2, 0.2)
				flash_tween.tween_property(self, "modulate", Color.WHITE, 0.3)

		BossState.LUNGE:
			# High-speed leap/lunge
			velocity = lunge_direction * (speed * 2.8)
			if state_timer >= 0.4: # Lunge for 0.4 seconds, then recover
				current_state = BossState.RECOVER
				state_timer = 0.0

		BossState.RECOVER:
			# Standing still panting/resting, player window to attack!
			velocity = Vector2.ZERO
			modulate.a = 0.85 # Dim slightly during recovery rest
			if state_timer >= 0.8: # Rest for 0.8 seconds, then chase again
				current_state = BossState.CHASE
				state_timer = 0.0
				modulate.a = 1.0

	var visuals = get_node_or_null("Visuals")
	if visuals and velocity.x != 0:
		visuals.scale = Vector2(1.2 if velocity.x >= 0 else -1.2, 1.2)

	move_and_slide()

	# Continuous contact attack logic (only if not howling)
	time_since_last_attack += delta
	if current_state != BossState.HOWL and time_since_last_attack >= attack_cooldown:
		var area = get_node_or_null("Area2D")
		if area:
			for body in area.get_overlapping_bodies():
				if body.is_in_group("player"):
					if body.has_method("take_damage"):
						body.take_damage(damage)
						# Play bite visual flash/effect (modulate crimson briefly)
						var attack_tween = create_tween()
						modulate = Color(2.0, 1.0, 1.0)
						attack_tween.tween_property(self, "modulate", Color.WHITE, 0.2)
						time_since_last_attack = 0.0
						break

func take_damage(amount: int) -> void:
	if has_force_field:
		amount = int(amount * 0.2) # 80% damage reduction
		
	current_health -= amount
	health_bar.value = current_health
	
	# Flash visual
	var tween = create_tween()
	modulate = Color(10.0, 10.0, 10.0)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	# Check health gates for temporary protection force field
	var health_ratio = float(current_health) / max_health
	for i in range(force_field_cooldowns.size() - 1, -1, -1):
		var gate = force_field_cooldowns[i]
		if health_ratio <= gate:
			force_field_cooldowns.remove_at(i)
			activate_shield()
			break

	# Spawn damage number
	if DAMAGE_NUMBER_SCENE:
		var dmg_num = DAMAGE_NUMBER_SCENE.instantiate()
		get_parent().add_child(dmg_num)
		dmg_num.global_position = global_position
		dmg_num.setup(amount, false)

	if current_health <= 0:
		_die()

func activate_shield() -> void:
	has_force_field = true
	modulate = Color(1.8, 0.5, 0.5) # Glowing blood shield modulate
	print("Alpha Werewolf triggers rage shield!")
	
	# Spawn impact burst particles
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.amount = 32
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.gravity = Vector2.ZERO
	particles.spread = 180.0
	particles.initial_velocity_min = 70.0
	particles.initial_velocity_max = 140.0
	particles.color = Color(0.9, 0.1, 0.1)
	add_child(particles)
	particles.emitting = true
	
	get_tree().create_timer(6.0).timeout.connect(func():
		has_force_field = false
		modulate = Color.WHITE
		particles.queue_free()
	)

func _die() -> void:
	# Spawn floor blood puddle decal
	if BLOOD_DECAL_SCENE:
		var decal = BLOOD_DECAL_SCENE.instantiate()
		get_parent().add_child(decal)
		decal.global_position = global_position
		
	# Drop rare items (always drop Fury / Iron Skin upgrade drop)
	var drop_scene = preload("res://scenes/PowerUpDrop.tscn")
	var drop_node = drop_scene.instantiate()
	get_parent().add_child(drop_node)
	drop_node.global_position = global_position
	
	# Choose Fury upgrade resource
	if drop_node.has_method("setup") and FURY_DATA:
		drop_node.setup(FURY_DATA)

	GameManager.add_score(points)
	GameManager.add_kill()
	GameManager.add_currency(points)
	GameManager.emit_signal("enemy_despawned", self)
	queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
