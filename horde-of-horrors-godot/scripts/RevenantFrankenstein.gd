# RevenantFrankenstein.gd
extends CharacterBody2D

@export var max_health: int = 1200
@export var speed: float = 120.0
@export var damage: int = 35
@export var points: int = 400

var current_health: int
var player: Node2D
var health_bar: ProgressBar
var is_charging: bool = false
var last_charge_time: float = 0.0
var charge_cooldown: float = 6.0

func _ready() -> void:
	current_health = max_health
	player = GameManager.player
	add_to_group("enemy")
	
	_create_health_bar()
	
	var body = get_node_or_null("Visuals/Body")
	if body:
		body.color = Color(0.2, 0.4, 0.2) # Rotten green

func _create_health_bar() -> void:
	health_bar = ProgressBar.new()
	add_child(health_bar)
	health_bar.show_percentage = false
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.position = Vector2(-40, -70)
	health_bar.size = Vector2(80, 8)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.0, 0.6, 0.0)
	health_bar.add_theme_stylebox_override("fill", fill_style)
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.7)
	health_bar.add_theme_stylebox_override("background", bg_style)

func _physics_process(delta: float) -> void:
	if not player or GameManager.is_game_over:
		return
		
	if is_charging:
		return
		
	var dist = global_position.distance_to(player.global_position)
	
	# Charge mechanic
	if dist < 350 and Time.get_ticks_msec() / 1000.0 - last_charge_time > charge_cooldown:
		_start_charge()
	
	var dir = (player.global_position - global_position).normalized()
	velocity = dir * speed
	
	var visuals = get_node_or_null("Visuals")
	if visuals and dir.x != 0:
		visuals.scale.x = 1.4 if dir.x >= 0 else -1.4
		
	move_and_slide()

func _start_charge() -> void:
	is_charging = true
	last_charge_time = Time.get_ticks_msec() / 1000.0
	
	# Windup visual
	modulate = Color(2.0, 2.0, 0.5) # Yellow glow
	var charge_dir = (player.global_position - global_position).normalized()
	
	await get_tree().create_timer(1.2).timeout
	
	# Charge forward
	modulate = Color(1.0, 1.0, 1.0)
	var charge_tween = create_tween()
	var target_pos = global_position + charge_dir * 300.0
	charge_tween.tween_property(self, "global_position", target_pos, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	await charge_tween.finished
	is_charging = false
	
	# Ground slam effect
	_spawn_slam_particles()

func _spawn_slam_particles() -> void:
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.amount = 40
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 200.0
	particles.scale_amount_min = 5.0
	particles.scale_amount_max = 10.0
	particles.color = Color(0.4, 0.3, 0.2)
	get_parent().add_child(particles)
	particles.global_position = global_position
	particles.emitting = true
	get_tree().create_timer(1.0).timeout.connect(particles.queue_free)

func take_damage(amount: int) -> void:
	current_health -= amount
	health_bar.value = current_health
	
	# Flash visual
	var tween = create_tween()
	modulate = Color(5.0, 5.0, 5.0)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	# Spawn damage number
	var dmg_scene = load("res://scenes/DamageNumber.tscn")
	if dmg_scene:
		var dmg_num = dmg_scene.instantiate()
		get_parent().add_child(dmg_num)
		dmg_num.global_position = global_position
		dmg_num.setup(amount, false)

	if current_health <= 0:
		_die()

func _die() -> void:
	var drop_scene = preload("res://scenes/PowerUpDrop.tscn")
	var drop_node = drop_scene.instantiate()
	get_parent().add_child(drop_node)
	drop_node.global_position = global_position
	
	# Revenant drops Fortitude / Health upgrade
	var health_res = load("res://resources/powerups/FortitudeData.tres")
	if drop_node.has_method("setup") and health_res:
		drop_node.setup(health_res)

	GameManager.add_score(points)
	GameManager.add_kill()
	GameManager.add_currency(points)
	GameManager.emit_signal("enemy_despawned", self)
	queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
