extends Area2D

@export var speed: float = 600.0
@export var turn_speed: float = 8.0
@export var lifesteal_percent: float = 0.15

var direction: Vector2 = Vector2.ZERO
var target: Node2D = null
var damage: int = 18
var lifetime: float = 4.0

func initialize(dir: Vector2, dmg: int):
	direction = dir.normalized()
	damage = dmg
	
	get_tree().create_timer(lifetime).timeout.connect(func():
		if visible:
			PoolManager.return_object("res://scenes/BloodOrb.tscn", self)
	)

func _physics_process(delta):
	if not is_instance_valid(target) or target == null:
		_find_target()
	
	if is_instance_valid(target):
		var target_dir = (target.global_position - global_position).normalized()
		direction = direction.lerp(target_dir, turn_speed * delta).normalized()
	
	rotation = direction.angle()
	position += direction * speed * delta

func _find_target():
	if GameManager.wave_manager:
		target = GameManager.wave_manager.get_nearest_enemy(global_position)

func _on_body_entered(body):
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
			# Lore: lifesteal for player
			if GameManager.player and GameManager.player.has_method("heal"):
				var heal_amt = int(damage * lifesteal_percent)
				if heal_amt > 0:
					GameManager.player.heal(heal_amt)
		
		_spawn_hit_effect()
		PoolManager.return_object("res://scenes/BloodOrb.tscn", self)

func _spawn_hit_effect():
	var hit_effect = PoolManager.get_object("res://scenes/ProjectileHitEffect.tscn")
	if hit_effect:
		if hit_effect.get_parent() != get_parent():
			if hit_effect.get_parent(): hit_effect.get_parent().remove_child(hit_effect)
			get_parent().add_child(hit_effect)
		hit_effect.global_position = global_position
		hit_effect.modulate = Color(1.2, 0, 0)
		if hit_effect.has_method("play_effect"):
			hit_effect.play_effect()

func reset():
	direction = Vector2.ZERO
	target = null
