extends Node2D

@export var chain_damage: int = 15
@export var max_chains: int = 3
@export var chain_radius: float = 120.0

var damaged_bodies: Array = []

func start_chain(start_pos: Vector2, initial_damage: int):
	global_position = start_pos
	chain_damage = initial_damage
	damaged_bodies.clear()
	
	var lvl = get_meta("level") if has_meta("level") else 1
	var chains = 2
	if lvl == 2 or lvl == 3 or lvl == 4:
		chains = 4
	elif lvl >= 5:
		chains = 6
		
	_chain_to_nearest(start_pos, chains)

func _chain_to_nearest(from_pos: Vector2, remaining_chains: int):
	if remaining_chains <= 0:
		get_tree().create_timer(0.2).timeout.connect(queue_free)
		return
		
	var enemies = get_tree().get_nodes_in_group("enemy")
	var nearest = null
	var min_dist = chain_radius
	
	for e in enemies:
		if e in damaged_bodies: continue
		var dist = from_pos.distance_to(e.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = e
			
	if nearest:
		damaged_bodies.append(nearest)
		
		var lvl = get_meta("level") if has_meta("level") else 1
		_draw_lightning(from_pos, nearest.global_position, lvl)
		
		var current_damage = chain_damage
		if lvl >= 4:
			var jump_index = damaged_bodies.size() - 1
			current_damage = int(chain_damage * (1.0 + 0.3 * jump_index))
			
		if nearest.has_method("take_damage"):
			nearest.take_damage(current_damage)
			
		if lvl >= 5 and nearest.has_method("apply_stun"):
			nearest.apply_stun(0.5)
			
		get_tree().create_timer(0.05).timeout.connect(func():
			_chain_to_nearest(nearest.global_position, remaining_chains - 1)
		)
	else:
		get_tree().create_timer(0.2).timeout.connect(queue_free)

func _draw_lightning(from: Vector2, to: Vector2, lvl: int):
	var line = Line2D.new()
	get_tree().current_scene.add_child(line)
	line.width = 2.5 if lvl >= 5 else 2.0
	
	if lvl >= 5:
		line.default_color = Color(1.0, 0.4, 0.8, 1.0)
	else:
		line.default_color = Color(0.6, 0.9, 1.0, 1.0)
	
	var points = []
	var dist = from.distance_to(to)
	var dir = (to - from).normalized()
	var perp = Vector2(-dir.y, dir.x)
	
	points.append(from)
	var segment_count = int(dist / 20.0) + 2
	for i in range(1, segment_count - 1):
		var p = from + dir * (dist * i / segment_count)
		p += perp * randf_range(-10.0, 10.0)
		points.append(p)
	points.append(to)
	
	line.points = PackedVector2Array(points)
	
	var tween = create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.2)
	tween.finished.connect(line.queue_free)
