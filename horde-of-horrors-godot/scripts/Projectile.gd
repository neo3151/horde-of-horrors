extends Area2D

@export var speed: float = 720.0
var direction: Vector2 = Vector2.ZERO
var damage: int = 12

@onready var trail_particles: CPUParticles2D = $TrailParticles

func initialize(dir: Vector2, dmg: int) -> void:
    direction = dir.normalized()
    damage = dmg
    rotation = direction.angle()
    if trail_particles:
        # Set particle emission direction opposite to projectile movement
        trail_particles.direction = -direction

func _physics_process(delta: float) -> void:
    position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("enemy"):
        if body.has_method("take_damage"):
            body.take_damage(damage)
        _spawn_hit_effect()
        queue_free()

func _spawn_hit_effect() -> void:
    var hit_effect_scene = preload("res://scenes/ProjectileHitEffect.tscn")
    if hit_effect_scene:
        var hit_effect = hit_effect_scene.instantiate()
        get_parent().add_child(hit_effect)
        hit_effect.global_position = global_position