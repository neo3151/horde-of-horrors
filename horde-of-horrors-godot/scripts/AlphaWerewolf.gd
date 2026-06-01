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

func _physics_process(_delta: float) -> void:
	if not player or GameManager.is_game_over:
		return
		
	var dir = (player.global_position - global_position).normalized()
	velocity = dir * speed
	
	var visuals = get_node_or_null("Visuals")
	if visuals and dir.x != 0:
		visuals.scale.x = 1.2 if dir.x >= 0 else -1.2
		
	move_and_slide()

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
