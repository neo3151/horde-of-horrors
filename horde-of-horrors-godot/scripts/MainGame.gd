extends Node2D

func _ready() -> void:
	# Register this scene's components with the singleton
	GameManager.wave_manager = $WaveManager

	# Dynamic Navigation Setup for Smart Pathfinding
	var nav_region = NavigationRegion2D.new()
	var nav_poly = NavigationPolygon.new()

	# Outer game boundaries outline
	var outer_outline = PackedVector2Array([
		Vector2(-430, -330),
		Vector2(430, -330),
		Vector2(430, 330),
		Vector2(-430, 330)
	])
	nav_poly.add_outline(outer_outline)

	# Obstacle walls to carve out of the navmesh (with buffer)
	var wall1_outline = PackedVector2Array([Vector2(-235, -115), Vector2(-165, -115), Vector2(-165, 115), Vector2(-235, 115)])
	nav_poly.add_outline(wall1_outline)
	var wall2_outline = PackedVector2Array([Vector2(165, -115), Vector2(235, -115), Vector2(235, 115), Vector2(165, 115)])
	nav_poly.add_outline(wall2_outline)
	var wall3_outline = PackedVector2Array([Vector2(-115, -185), Vector2(115, -185), Vector2(115, -115), Vector2(-115, -115)])
	nav_poly.add_outline(wall3_outline)
	var wall4_outline = PackedVector2Array([Vector2(-115, 115), Vector2(115, 115), Vector2(115, 185), Vector2(-115, 185)])
	nav_poly.add_outline(wall4_outline)

	nav_poly.make_polygons_from_outlines()
	nav_region.navigation_polygon = nav_poly
	add_child(nav_region)

	# Apply ambient light settings
	var base_color = Color(0.35, 0.35, 0.45, 1)
	if has_node("CanvasModulate"):
		$CanvasModulate.color = base_color * GameManager.brightness_factor

	# Start the game loop
	if has_node("/root/UIManager"):
		get_node("/root/UIManager").show_hud()
	
	GameManager.start_game()
	AudioManager.play_music("battle_theme")

	var mobile_pause_btn = get_node_or_null("UILayer/MobilePauseButton")
	var pause_menu = get_node_or_null("UILayer/PauseMenu")
	if mobile_pause_btn and pause_menu:
		mobile_pause_btn.pressed.connect(pause_menu.toggle_pause)
		
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
		return
		
	# Special bypass for the first load to ensure it's forced
	if env_path == current_env_scene_path and current_env_scene_path != "":
		return
		
	print("MainGame: Swapping from [", current_env_scene_path, "] to [", env_path, "]")
	
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
		
	current_env_scene_path = env_path
	print("MainGame: Environment is now visible and active.")
