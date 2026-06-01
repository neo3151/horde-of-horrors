extends Node2D

@export var chain_damage: int = 15
@export var max_chains: int = 3
@export var chain_radius: float = 120.0

var damaged_bodies: Array = []

func start_chain(start_pos: Vector2, initial_damage: int):
	global_position = start_pos
	chain_damage = initial_damage
	damaged_bodies.clear()
	_chain_to_nearest(start_pos, max_chains)

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
		if nearest.has_method("take_damage"):
			nearest.take_damage(chain_damage)
			
		# Draw lightning line
		_draw_lightning(from_pos, nearest.global_position)
		
		# Chain again from new position
		get_tree().create_timer(0.05).timeout.connect(func():
			_chain_to_nearest(nearest.global_position, remaining_chains - 1)
		)
	else:
		get_tree().create_timer(0.2).timeout.connect(queue_free)

func _draw_lightning(from: Vector2, to: Vector2):
	var line = Line2D.new()
	get_tree().current_scene.add_child(line)
	line.width = 2.0
	line.default_color = Color(0.6, 0.9, 1.0, 1.0)
	
	# Create jagged lightning points
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
