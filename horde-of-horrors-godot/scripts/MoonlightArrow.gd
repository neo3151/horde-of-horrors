extends Area2D

@export var speed: float = 1200.0
@export var crit_chance: float = 0.4
@export var crit_multiplier: float = 2.5

var direction: Vector2 = Vector2.ZERO
var damage: int = 15
var lifetime: float = 3.0

@onready var trail = $CPUParticles2D

func initialize(dir: Vector2, dmg: int):
	direction = dir.normalized()
	damage = dmg
	rotation = direction.angle()
	
	get_tree().create_timer(lifetime).timeout.connect(func():
		if visible:
			PoolManager.return_object("res://scenes/MoonlightArrow.tscn", self)
	)

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("enemy"):
		var final_damage = damage
		var is_crit = randf() < crit_chance
		if is_crit:
			final_damage = int(damage * crit_multiplier)
		
		if body.has_method("take_damage"):
			body.take_damage(final_damage)
		
		_spawn_hit_effect(is_crit)
		PoolManager.return_object("res://scenes/MoonlightArrow.tscn", self)

func _spawn_hit_effect(is_crit: bool):
	var hit_effect = PoolManager.get_object("res://scenes/ProjectileHitEffect.tscn")
	if hit_effect:
		if hit_effect.get_parent() != get_parent():
			if hit_effect.get_parent(): hit_effect.get_parent().remove_child(hit_effect)
			get_parent().add_child(hit_effect)
		hit_effect.global_position = global_position
		
		if is_crit:
			hit_effect.modulate = Color(1.5, 1.5, 2.0) # Brighter blue for crits
		
		if hit_effect.has_method("play_effect"):
			hit_effect.play_effect()

func reset():
	direction = Vector2.ZERO
