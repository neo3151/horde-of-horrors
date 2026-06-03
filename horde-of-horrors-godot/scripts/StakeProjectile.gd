extends Area2D

@export var speed: float = 900.0
@export var piercing_count: int = 3
var current_pierce: int = 0
var direction: Vector2 = Vector2.ZERO
var damage: int = 50
var lifetime: float = 3.0

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
		var lvl = get_meta("level") if has_meta("level") else 1
		if current_pierce >= piercing_count:
			if lvl >= 5:
				_spawn_splinters()
			PoolManager.return_object("res://scenes/StakeProjectile.tscn", self)
	elif body.is_in_group("obstacle"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		_spawn_hit_effect()
		var lvl = get_meta("level") if has_meta("level") else 1
		if lvl >= 5:
			_spawn_splinters()
		PoolManager.return_object("res://scenes/StakeProjectile.tscn", self)

func _spawn_splinters() -> void:
	for angle in [0.0, PI/2.0, PI, 3.0*PI/2.0]:
		var splinter = PoolManager.get_object("res://scenes/StakeProjectile.tscn")
		if splinter:
			if splinter.get_parent() != get_tree().current_scene:
				if splinter.get_parent(): splinter.get_parent().remove_child(splinter)
				get_tree().current_scene.add_child(splinter)
			
			splinter.set_meta("level", 1)
			splinter.global_position = global_position
			splinter.scale = Vector2(0.5, 0.5)
			splinter.piercing_count = 1
			splinter.initialize(Vector2.RIGHT.rotated(angle), int(damage * 0.4))

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
	scale = Vector2(1.0, 1.0)
	if has_meta("level"):
		remove_meta("level")
	if trail_particles:
		trail_particles.emitting = false
