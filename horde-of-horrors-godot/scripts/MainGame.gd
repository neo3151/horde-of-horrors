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

	# Obstacle walls to carve out of the navmesh (with buffer):
	# Wall1 (x: -220 to -180, y: -100 to 100)
	var wall1_outline = PackedVector2Array([
		Vector2(-235, -115),
		Vector2(-165, -115),
		Vector2(-165, 115),
		Vector2(-235, 115)
	])
	nav_poly.add_outline(wall1_outline)

	# Wall2 (x: 180 to 220, y: -100 to 100)
	var wall2_outline = PackedVector2Array([
		Vector2(165, -115),
		Vector2(235, -115),
		Vector2(235, 115),
		Vector2(165, 115)
	])
	nav_poly.add_outline(wall2_outline)

	# Wall3 (x: -100 to 100, y: -170 to -130)
	var wall3_outline = PackedVector2Array([
		Vector2(-115, -185),
		Vector2(115, -185),
		Vector2(115, -115),
		Vector2(-115, -115)
	])
	nav_poly.add_outline(wall3_outline)

	# Wall4 (x: -100 to 100, y: 130 to 170)
	var wall4_outline = PackedVector2Array([
		Vector2(-115, 115),
		Vector2(115, 115),
		Vector2(115, 185),
		Vector2(-115, 185)
	])
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

func change_environment(env_path: String) -> void:
	var env_scene = load(env_path)
	if not env_scene:
		return
	var old_env = get_node_or_null("ActiveEnvironment")
	if old_env:
		old_env.queue_free()
	var new_env = env_scene.instantiate()
	new_env.name = "ActiveEnvironment"
	add_child(new_env)
	move_child(new_env, 0)
