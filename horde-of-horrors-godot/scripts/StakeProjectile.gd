extends Area2D

@export var speed: float = 900.0
@export var piercing_count: int = 3
var current_pierce: int = 0
var direction: Vector2 = Vector2.ZERO
var damage: int = 50
var lifetime: float = 3.0

@onready var trail_particles: CPUParticles2D = $TrailParticles

func initialize(dir: Vector2, dmg: int) -> void:
	direction = dir.normalized()
	damage = dmg
	rotation = direction.angle()
	if trail_particles:
		trail_particles.direction = -direction
		trail_particles.emitting = true
	
	get_tree().create_timer(lifetime).timeout.connect(func():
		if visible:
			PoolManager.return_object("res://scenes/StakeProjectile.tscn", self)
	)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		
		_spawn_hit_effect()
		
		current_pierce += 1
		if current_pierce >= piercing_count:
			PoolManager.return_object("res://scenes/StakeProjectile.tscn", self)

func _spawn_hit_effect() -> void:
	var hit_effect = PoolManager.get_object("res://scenes/ProjectileHitEffect.tscn")
	if hit_effect:
		if hit_effect.get_parent() != get_parent():
			if hit_effect.get_parent(): hit_effect.get_parent().remove_child(hit_effect)
			get_parent().add_child(hit_effect)
		hit_effect.global_position = global_position
		if hit_effect.has_method("play_effect"):
			hit_effect.play_effect()

func reset() -> void:
	direction = Vector2.ZERO
	current_pierce = 0
	if trail_particles:
		trail_particles.emitting = false
