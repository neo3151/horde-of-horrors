extends Node2D

func _ready() -> void:
	# Register this scene's components with the singleton
	GameManager.wave_manager = $WaveManager

	# Apply ambient light settings
	var base_color = Color(0.35, 0.35, 0.45, 1)
	if has_node("CanvasModulate"):
		$CanvasModulate.color = base_color * GameManager.brightness_factor

	# Start the game loop
	if has_node("/root/UIManager"):
		get_node("/root/UIManager").show_hud()
	
	GameManager.start_game()
	# Force restart music for game start impact
	AudioManager.play_music("battle_theme", 1.0, true)

	# Ensure the first map loads AFTER everything else is fully ready
	_safe_initial_map_load()

func _safe_initial_map_load() -> void:
	# Wait one frame for the engine to stabilize
	await get_tree().process_frame
	if is_instance_valid($WaveManager):
		$WaveManager._check_environment_change(1)

var current_env_scene_path: String = ""

func change_environment(env_path: String) -> void:
	if env_path == "":
		print("[MainGame] change_environment called with empty path, ignoring")
		return
		
	# Special bypass for the first load to ensure it's forced
	if env_path == current_env_scene_path and current_env_scene_path != "":
		print("[MainGame] Skipping duplicate environment load: ", env_path)
		return
		
	print("[MainGame] Swapping from [", current_env_scene_path, "] to [", env_path, "]")
	
	var env_scene = load(env_path)
	if not env_scene:
		print("MainGame Error: Failed to load scene at ", env_path)
		return
		
	# Thoroughly hide all legacy background elements from MainGame.tscn
	for node_name in ["Floor", "Obstacles", "Props", "AmbientParticles", "FloorGrid"]:
		var n = get_node_or_null(node_name)
		if n:
			n.visible = false
			if n is CPUParticles2D:
				n.emitting = false
	
	# Important: Find and rename the old environment to avoid name collisions
	var old_env = get_node_or_null("ActiveEnvironment")
	if old_env:
		old_env.name = "OldEnvironment_BeingRemoved"
		old_env.queue_free()
	
	# Instantiate and add the new environment
	var new_env = env_scene.instantiate()
	new_env.name = "ActiveEnvironment" 
	add_child(new_env)
	
	# Force background layering
	move_child(new_env, 0)
	new_env.visible = true
	
	# Force absolute bottom draw order
	if "z_index" in new_env:
		new_env.z_index = -20
		
	# Dynamically scale floor to cover the expanded bounds
	var floor_node = new_env.get_node_or_null("Floor")
	if floor_node and floor_node is Sprite2D:
		floor_node.scale = Vector2(6.5, 6.5)
		
	current_env_scene_path = env_path
	print("MainGame: Environment is now visible and active.")

func rebuild_navigation_mesh() -> void:
	var nav_region = get_node_or_null("NavigationRegion2D")
	if not nav_region:
		nav_region = NavigationRegion2D.new()
		nav_region.name = "NavigationRegion2D"
		add_child(nav_region)
		
	var nav_poly = NavigationPolygon.new()
	
	# 1. Add outer boundary outline (clock-wise outline)
	var outer_outline = PackedVector2Array([
		Vector2(-1250, -950),
		Vector2(1250, -950),
		Vector2(1250, 950),
		Vector2(-1250, 950)
	])
	nav_poly.add_outline(outer_outline)
	
	# Buffer/offset for pathfinding to prevent enemies from clipping corners
	var safety_margin = 25.0
	
	# 2. Add static obstacles from active environment (counter-clockwise outlines)
	var env = get_node_or_null("ActiveEnvironment")
	if env:
		var static_obstacles = env.get_node_or_null("Obstacles")
		if static_obstacles:
			for child in static_obstacles.get_children():
				if child is StaticBody2D:
					var shape_node = child.get_node_or_null("CollisionShape2D")
					if shape_node and shape_node.shape is RectangleShape2D:
						var size = shape_node.shape.size
						var pos = child.global_position
						
						# Create outline around this static wall/crate
						var half_w = size.x / 2.0 + safety_margin
						var half_h = size.y / 2.0 + safety_margin
						
						var outline = PackedVector2Array([
							pos + Vector2(-half_w, -half_h),
							pos + Vector2(half_w, -half_h),
							pos + Vector2(half_w, half_h),
							pos + Vector2(-half_w, half_h)
						])
						nav_poly.add_outline(outline)
						
	# 3. Add spawned cover obstacles (counter-clockwise outlines)
	for obstacle in get_tree().get_nodes_in_group("obstacle"):
		if is_instance_valid(obstacle):
			var shape_node = obstacle.get_node_or_null("CollisionShape2D")
			if shape_node and shape_node.shape is RectangleShape2D:
				var size = shape_node.shape.size
				var pos = obstacle.global_position
				
				var half_w = size.x / 2.0 + safety_margin
				var half_h = size.y / 2.0 + safety_margin
				
				var outline = PackedVector2Array([
					pos + Vector2(-half_w, -half_h),
					pos + Vector2(half_w, -half_h),
					pos + Vector2(half_w, half_h),
					pos + Vector2(-half_w, half_h)
				])
				nav_poly.add_outline(outline)
				
	# Recompile the navigation mesh polygons
	nav_poly.make_polygons_from_outlines()
	nav_region.navigation_polygon = nav_poly
	
	print("[Navigation] Rebuilt navigation mesh with active obstacles.")
