extends Area2D

@export var speed: float = 720.0
var direction: Vector2 = Vector2.ZERO
var damage: int = 12
var lifetime: float = 4.0
var lifetime_timer: SceneTreeTimer = null

@onready var trail_particles: CPUParticles2D = $TrailParticles

func _ready() -> void:
	collision_mask |= 8

func initialize(dir: Vector2, dmg: int) -> void:
	direction = dir.normalized()
	damage = dmg
	rotation = direction.angle()
	if trail_particles:
		trail_particles.direction = -direction
		trail_particles.emitting = true
	
	# Auto return to pool after lifetime expires
	lifetime_timer = get_tree().create_timer(lifetime)
	lifetime_timer.timeout.connect(func():
		if visible: # Only return if it hasn't hit something already
			PoolManager.return_object("res://scenes/Projectile.tscn", self)
	)

var pierce_count: int = 0
var explode_on_hit: bool = false
var hit_bodies: Array = []

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if hit_bodies.has(body):
		return
	hit_bodies.append(body)

	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		_spawn_hit_effect()
		if explode_on_hit:
			_explode()
		if pierce_count > 0:
			pierce_count -= 1
		else:
			PoolManager.return_object("res://scenes/Projectile.tscn", self)
	elif body.is_in_group("obstacle"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		_spawn_hit_effect()
		if explode_on_hit:
			_explode()
		if pierce_count > 0:
			pierce_count -= 1
		else:
			PoolManager.return_object("res://scenes/Projectile.tscn", self)

func _explode() -> void:
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.amount = 20
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 60.0
	particles.initial_velocity_max = 120.0
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 5.0
	particles.color = Color(1.0, 0.9, 0.4)
	get_parent().add_child(particles)
	particles.global_position = global_position
	particles.emitting = true
	
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.global_position.distance_to(global_position) < 100.0:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)
				
	AudioManager.play_sfx("holy_blast")
	get_tree().create_timer(1.0).timeout.connect(func():
		particles.queue_free()
	)

func _spawn_hit_effect() -> void:
	var hit_effect = PoolManager.get_object("res://scenes/ProjectileHitEffect.tscn")
	if hit_effect:
		if hit_effect.get_parent() != get_parent():
			hit_effect.get_parent().remove_child(hit_effect)
			get_parent().add_child(hit_effect)
		hit_effect.global_position = global_position
		if hit_effect.has_method("play_effect"):
			hit_effect.play_effect()

func reset() -> void:
	direction = Vector2.ZERO
	pierce_count = 0
	explode_on_hit = false
	hit_bodies.clear()
	if trail_particles:
		trail_particles.emitting = false