extends Area2D

@export var speed: float = 1200.0
@export var crit_chance: float = 0.4
@export var crit_multiplier: float = 2.5

var direction: Vector2 = Vector2.ZERO
var damage: int = 15
var lifetime: float = 3.0

@onready var trail = $CPUParticles2D

func _ready() -> void:
	collision_mask |= 8

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
			
		var lvl = get_meta("level") if has_meta("level") else 1
		if is_crit and lvl >= 5:
			_spawn_lunar_shockwave(global_position, direction)
		
		_spawn_hit_effect(is_crit)
		PoolManager.return_object("res://scenes/MoonlightArrow.tscn", self)
	elif body.is_in_group("obstacle"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		_spawn_hit_effect(false)
		PoolManager.return_object("res://scenes/MoonlightArrow.tscn", self)

func _spawn_lunar_shockwave(pos: Vector2, dir: Vector2):
	var line = Line2D.new()
	get_tree().current_scene.add_child(line)
	line.width = 4.0
	line.default_color = Color(0.7, 0.9, 1.2, 1.0)
	
	var perp = Vector2(-dir.y, dir.x)
	var points = []
	var center = pos + dir * 30.0
	for angle in range(-60, 61, 10):
		var rad = deg_to_rad(angle)
		var p = center + dir * (cos(rad) * 20.0) + perp * (sin(rad) * 40.0)
		points.append(p)
	line.points = PackedVector2Array(points)
	
	var tween = create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.3)
	tween.finished.connect(line.queue_free)
	
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.global_position.distance_to(pos) < 180.0:
			var to_enemy = (enemy.global_position - pos).normalized()
			var dot = to_enemy.dot(dir)
			if dot > 0.7:
				if enemy.has_method("take_damage"):
					enemy.take_damage(int(damage * 1.0))

func _spawn_hit_effect(is_crit: bool):
	var hit_effect = PoolManager.get_object("res://scenes/ProjectileHitEffect.tscn")
	if hit_effect:
		if hit_effect.get_parent() != get_parent():
			if hit_effect.get_parent(): hit_effect.get_parent().remove_child(hit_effect)
			get_parent().add_child(hit_effect)
		hit_effect.global_position = global_position
		
		if is_crit:
			hit_effect.modulate = Color(1.5, 1.5, 2.0)
		
		if hit_effect.has_method("play_effect"):
			hit_effect.play_effect()

func reset():
	direction = Vector2.ZERO
	crit_chance = 0.4
	crit_multiplier = 2.5
	if has_meta("level"):
		remove_meta("level")
