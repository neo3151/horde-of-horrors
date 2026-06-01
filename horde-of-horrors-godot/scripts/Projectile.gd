extends Area2D

@export var speed: float = 720.0
var direction: Vector2 = Vector2.ZERO
var damage: int = 12
var lifetime: float = 4.0
var lifetime_timer: SceneTreeTimer = null

@onready var trail_particles: CPUParticles2D = $TrailParticles

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

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		_spawn_hit_effect()
		PoolManager.return_object("res://scenes/Projectile.tscn", self)

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
	if trail_particles:
		trail_particles.emitting = false