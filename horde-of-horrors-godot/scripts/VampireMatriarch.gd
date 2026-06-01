# VampireMatriarch.gd
extends CharacterBody2D

# Preloaded scenes/resources to prevent gameplay stutters
const DAMAGE_NUMBER_SCENE = preload("res://scenes/DamageNumber.tscn")
const BLOOD_DECAL_SCENE = preload("res://scenes/BloodDecal.tscn")
const VAMP_KISS_DATA = preload("res://resources/powerups/VampiresKissData.tres")

@export var max_health: int = 580
@export var speed: float = 190.0
@export var damage: int = 22
@export var points: int = 250

var current_health: int
var player: Node2D
var has_force_field: bool = false
var health_bar: ProgressBar
var last_blink_time: float = 0.0
var blink_cooldown: float = 4.0

@onready var sprite = get_node_or_null("Visuals/Sprite2D")

func _ready() -> void:
	current_health = max_health
	player = GameManager.player
	add_to_group("enemy")
	
	_create_health_bar()
	
	var body = get_node_or_null("Visuals/Body")
	if body:
		body.color = Color(0.4, 0.05, 0.05) # Deep blood maroon

func _create_health_bar() -> void:
	health_bar = ProgressBar.new()
	add_child(health_bar)
	health_bar.show_percentage = false
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.position = Vector2(-35, -60)
	health_bar.size = Vector2(70, 6)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.7, 0.0, 0.0)
	health_bar.add_theme_stylebox_override("fill", fill_style)
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.7)
	health_bar.add_theme_stylebox_override("background", bg_style)

func _physics_process(delta: float) -> void:
	if not player or GameManager.is_game_over:
		return
		
	var dist = global_position.distance_to(player.global_position)
	
	# Blink mechanic (teleport near player)
	if dist > 200 and Time.get_ticks_msec() / 1000.0 - last_blink_time > blink_cooldown:
		_blink_to_player()
	
	var dir = (player.global_position - global_position).normalized()
	velocity = dir * speed
	
	var visuals = get_node_or_null("Visuals")
	if visuals and dir.x != 0:
		visuals.scale.x = 1.1 if dir.x >= 0 else -1.1
		
	move_and_slide()

func _blink_to_player() -> void:
	last_blink_time = Time.get_ticks_msec() / 1000.0
	
	# Visual effect at start
	_spawn_mist_particles(global_position)
	
	# Teleport to a random spot near player
	var angle = randf_range(0, TAU)
	var offset = Vector2.from_angle(angle) * 120.0
	global_position = player.global_position + offset
	
	# Visual effect at end
	_spawn_mist_particles(global_position)

func _spawn_mist_particles(pos: Vector2) -> void:
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.amount = 24
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 100.0
	particles.color = Color(0.3, 0.0, 0.0, 0.6)
	get_parent().add_child(particles)
	particles.global_position = pos
	particles.emitting = true
	get_tree().create_timer(1.0).timeout.connect(particles.queue_free)

func take_damage(amount: int) -> void:
	current_health -= amount
	health_bar.value = current_health
	
	# Flash visual
	var tween = create_tween()
	modulate = Color(8.0, 1.0, 1.0)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	# Spawn damage number
	if DAMAGE_NUMBER_SCENE:
		var dmg_num = DAMAGE_NUMBER_SCENE.instantiate()
		get_parent().add_child(dmg_num)
		dmg_num.global_position = global_position
		dmg_num.setup(amount, false)

	if current_health <= 0:
		_die()

func _die() -> void:
	if BLOOD_DECAL_SCENE:
		var decal = BLOOD_DECAL_SCENE.instantiate()
		get_parent().add_child(decal)
		decal.global_position = global_position
		
	var drop_scene = preload("res://scenes/PowerUpDrop.tscn")
	var drop_node = drop_scene.instantiate()
	get_parent().add_child(drop_node)
	drop_node.global_position = global_position
	
	# Matriarch drops Lifesteal upgrade or Blood Bag
	if drop_node.has_method("setup") and VAMP_KISS_DATA:
		drop_node.setup(VAMP_KISS_DATA)

	GameManager.add_score(points)
	GameManager.add_kill()
	GameManager.add_currency(points)
	GameManager.emit_signal("enemy_despawned", self)
	queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
