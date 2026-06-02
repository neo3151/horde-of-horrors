extends StaticBody2D
class_name CoverObstacle

@export var max_health: int = 150
@export var obstacle_type: String = "gravestone" # "gravestone", "pillar", "barricade", "barrel"

var current_health: int

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("obstacle")
	current_health = max_health
	
	# Load texture based on type
	var tex_path = "res://assets/sprites/obstacles/" + obstacle_type + ".png"
	var tex = load(tex_path)
	if tex and sprite:
		sprite.texture = tex
		
		# Dynamically scale to target height (e.g. 100px)
		var target_height = 100.0
		if obstacle_type == "pillar":
			target_height = 145.0 # Pillars should be taller
		elif obstacle_type == "barricade":
			target_height = 80.0  # Barricades are wider
			
		var scale_factor = target_height / tex.get_height()
		sprite.scale = Vector2(scale_factor, scale_factor)
		
		# Set up dynamic collision shape boundary matching
		if collision_shape and collision_shape.shape is RectangleShape2D:
			var rect = collision_shape.shape as RectangleShape2D
			# Adjust collision footprint slightly smaller than the sprite bounds for better gameplay feel
			var coll_w = tex.get_width() * scale_factor * 0.8
			var coll_h = tex.get_height() * scale_factor * 0.8
			rect.size = Vector2(coll_w, coll_h)

func take_damage(amount: int) -> void:
	current_health -= amount
	
	# Flash red/white when hit
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1.8, 1.2, 1.2, 1.0), 0.07)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.07)
	
	# Apply visual cracking feedback: dim green/blue colors as health drops
	var ratio = float(current_health) / float(max_health)
	sprite.self_modulate = Color(1.0, 0.3 + 0.7 * ratio, 0.3 + 0.7 * ratio)
	
	if current_health <= 0:
		_crumble()

func _crumble() -> void:
	_spawn_particles()
	AudioManager.play_sfx("die")
	queue_free()

func _spawn_particles() -> void:
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.amount = 24
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 60.0
	particles.initial_velocity_max = 120.0
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0
	particles.color = Color(0.45, 0.45, 0.45, 0.85) # Grey dust cloud
	
	get_parent().add_child(particles)
	particles.global_position = global_position
	particles.emitting = true
	
	get_tree().create_timer(1.0).timeout.connect(particles.queue_free)
