extends Node2D

@export var rotation_speed: float = 8.0
@export var arc_height: float = 90.0

var target_position: Vector2 = Vector2.ZERO
var start_position: Vector2 = Vector2.ZERO
var distance_total: float = 0.0
var elapsed_time: float = 0.0
const FUSE_TIME: float = 1.5

func initialize(target_pos: Vector2):
	start_position = global_position
	target_position = target_pos
	distance_total = start_position.distance_to(target_position)
	
	# Visual upgrade for Level 5
	var lvl = get_meta("level") if has_meta("level") else 1
	if lvl >= 5:
		if has_node("Visuals"):
			$Visuals.modulate = Color(2.5, 2.5, 1.5) # Glowing bright holy energy

func _physics_process(delta):
	elapsed_time += delta
	if elapsed_time >= FUSE_TIME:
		_explode()
		return
	
	var t = elapsed_time / FUSE_TIME
	t = clamp(t, 0.0, 1.0)
	
	var current_ground_pos = start_position.lerp(target_position, t)
	var height = 4 * arc_height * t * (1 - t)
	
	global_position = current_ground_pos + Vector2(0, -height)
	if has_node("Visuals"):
		$Visuals.rotation += rotation_speed * delta

func _explode():
	var level = get_meta("level") if has_meta("level") else 1
	
	# Determine radius
	var radius = 100.0
	if level == 5:
		radius = 200.0
	elif level >= 2:
		radius = 140.0
		
	# Explosion damage
	var explosion_damage = 25
	
	# Burn parameters (holy fire DoT)
	var burn_dmg = 5
	var burn_dur = 3.0
	if level >= 3:
		burn_dmg = 10
		burn_dur = 5.0
		
	# Find enemies in radius
	var enemies = get_tree().get_nodes_in_group("enemy")
	var hit_enemies = []
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.global_position.distance_to(target_position) <= radius:
			hit_enemies.append(enemy)
			
	# Deal explosion damage + burn
	for enemy in hit_enemies:
		if enemy.has_method("take_damage"):
			enemy.take_damage(explosion_damage)
		if enemy.has_method("apply_status_effect"):
			enemy.apply_status_effect("burn", burn_dmg, burn_dur)
			
	# Level 4 Chaining: "Explosion now chains to nearby enemies (jumps to 2-3 additional targets)."
	if level >= 4:
		var chain_targets = []
		var chain_range = 250.0
		for enemy in enemies:
			if is_instance_valid(enemy) and not enemy in hit_enemies:
				if enemy.global_position.distance_to(target_position) <= chain_range:
					chain_targets.append(enemy)
					if chain_targets.size() >= 3: # Cap at 3 targets
						break
		for enemy in chain_targets:
			if enemy.has_method("take_damage"):
				enemy.take_damage(explosion_damage)
			if enemy.has_method("apply_status_effect"):
				enemy.apply_status_effect("burn", burn_dmg, burn_dur)
			_create_chain_visual(target_position, enemy.global_position)
			
	# Spawns garlic field at level >= 2
	if level >= 2:
		var cloud_scene = load("res://scenes/GarlicCloud.tscn")
		if cloud_scene:
			var cloud = cloud_scene.instantiate()
			cloud.set_meta("level", level)
			get_tree().current_scene.add_child(cloud)
			cloud.global_position = target_position
			
	AudioManager.play_sfx("bomb_impact")
	
	# Spawn explosion particles
	_spawn_explosion_particles(target_position, radius, level)
	
	queue_free()

func _create_chain_visual(from_pos: Vector2, to_pos: Vector2):
	var line = Line2D.new()
	line.global_position = Vector2.ZERO
	line.points = PackedVector2Array([from_pos, to_pos])
	line.width = 4.0
	line.default_color = Color(1.0, 0.9, 0.4, 0.8) # Holy yellow color
	get_tree().current_scene.add_child(line)
	
	# Fade out and delete
	var tween = create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.3)
	tween.finished.connect(line.queue_free)

func _spawn_explosion_particles(pos: Vector2, radius: float, lvl: int):
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.amount = 32
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = radius * 0.8
	particles.initial_velocity_max = radius * 1.5
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 5.0
	
	if lvl >= 5:
		particles.color = Color(1.0, 0.95, 0.7, 0.9) # Glowing gold-white for Level 5
	else:
		particles.color = Color(0.8, 0.3, 0.1, 0.8) # Red-orange explosion for others
		
	get_tree().current_scene.add_child(particles)
	particles.global_position = pos
	particles.emitting = true
	get_tree().create_timer(1.0).timeout.connect(particles.queue_free)

