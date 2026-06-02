extends Node2D

@export var enemy_scenes: Array[PackedScene] = []
@export var spawn_rate: float = 1.2
@export var base_enemies_per_wave: int = 6

var active_enemies: Array = []
var enemies_to_spawn: int = 0
var next_spawn_time: float = 0.0
var wave_in_progress: bool = false
var wave_time_left: float = -1.0
var is_timer_wave: bool = false
var is_spawning_active: bool = false

const ENVIRONMENTS = {
	1: "res://scenes/environments/ForsakenVillageOutskirts.tscn",
	11: "res://scenes/environments/ShatteredTradeDistrict.tscn",
	21: "res://scenes/environments/CursedBloodwoodForest.tscn",
	31: "res://scenes/environments/AbandonedCathedralDistrict.tscn",
	41: "res://scenes/environments/FogShroudedHarbor.tscn",
	51: "res://scenes/environments/UndergroundCatacombs.tscn",
	61: "res://scenes/environments/OvergrownGraveyard.tscn",
	71: "res://scenes/environments/DecayingVictorianMansion.tscn",
	81: "res://scenes/environments/RuinedCastleEldritch.tscn",
	91: "res://scenes/environments/CursedIronworks.tscn"
}

func _ready() -> void:
	GameManager.wave_manager = self
	# Removed initial map load from here to prevent race conditions with MainGame

func start_wave(wave_number: int) -> void:
	print("[WaveManager] start_wave called for wave ", wave_number)
	active_enemies.clear()
	
	# Clear and spawn obstacles dynamically
	_spawn_obstacles()
	
	# Load and check environment change
	_check_environment_change(wave_number)

	var is_boss_wave = wave_number > 0 and wave_number % 10 == 0
	if is_boss_wave:
		wave_time_left = -1.0
		is_timer_wave = false
	else:
		wave_time_left = 30.0 + (wave_number * 5.0)
		is_timer_wave = true

	# Trigger UIManager briefing panel and pause game
	if has_node("/root/UIManager"):
		get_node("/root/UIManager").show_stage_briefing(wave_number)
	else:
		start_spawning()

func start_spawning() -> void:
	is_spawning_active = true
	wave_in_progress = true
	var wave = GameManager.current_wave
	var is_boss_wave = wave > 0 and wave % 10 == 0
	
	if is_boss_wave:
		enemies_to_spawn = 0
		var boss_path = ""
		match wave:
			10: boss_path = "res://scenes/AlphaWerewolf.tscn"
			20: boss_path = "res://scenes/VampireMatriarch.tscn"
			30: boss_path = "res://scenes/RevenantFrankenstein.tscn"
			40: boss_path = "res://scenes/LichHighPriest.tscn"
			50: boss_path = "res://scenes/EnemyStitcher.tscn"
			60: boss_path = "res://scenes/EnemyTheFirstOne.tscn"
			70: boss_path = "res://scenes/AlphaWerewolf.tscn"
			80: boss_path = "res://scenes/VampireMatriarch.tscn"
			90: boss_path = "res://scenes/RevenantFrankenstein.tscn"
			100: boss_path = "res://scenes/EnemyStitcher.tscn"
			_: boss_path = "res://scenes/AlphaWerewolf.tscn"

		var boss_scene = load(boss_path)
		if boss_scene:
			var boss = boss_scene.instantiate()
			boss.global_position = Vector2.ZERO
			add_child(boss)
			active_enemies.append(boss)
			GameManager.emit_signal("enemy_spawned", boss)

			if is_instance_valid(GameManager.player):
				GameManager.player.global_position = Vector2(0, 280)

			var arena_script = load("res://scripts/ForceFieldArena.gd")
			if arena_script:
				var arena = arena_script.new()
				add_child(arena)
				arena.activate(boss, Vector2.ZERO)
	else:
		next_spawn_time = Time.get_ticks_msec() / 1000.0 + 0.5
		print("[WaveManager] Spawning started for survival wave ", wave)

func _spawn_obstacles() -> void:
	# Clear any existing cover obstacles
	for node in get_tree().get_nodes_in_group("obstacle"):
		node.queue_free()
		
	var count = randi_range(5, 8)
	var obstacle_scene = load("res://scenes/CoverObstacle.tscn")
	if not obstacle_scene:
		return
		
	var types = ["gravestone", "pillar", "barricade", "barrel"]
	for i in range(count):
		var obstacle = obstacle_scene.instantiate()
		obstacle.obstacle_type = types[randi() % types.size()]
		
		# Set random position inside screen boundaries, away from player spawn center
		var pos = Vector2.ZERO
		while true:
			pos = Vector2(randf_range(-320, 320), randf_range(-220, 220))
			if pos.length() > 100:
				break
		obstacle.global_position = pos
		get_parent().add_child(obstacle)

func _process(delta: float) -> void:
	if not wave_in_progress or not is_spawning_active:
		return

	# Clean null references
	active_enemies = active_enemies.filter(func(e): return is_instance_valid(e))

	if is_timer_wave:
		wave_time_left -= delta
		if has_node("/root/UIManager"):
			get_node("/root/UIManager").update_timer_label(wave_time_left)
			
		if wave_time_left <= 0:
			_trigger_cleansing_flash()
			wave_in_progress = false
			is_spawning_active = false
			if has_node("/root/UIManager"):
				get_node("/root/UIManager").update_timer_label(-1)
				get_node("/root/UIManager").show_upgrade_shop()
			else:
				GameManager.next_wave()
			return
			
		# Intensify spawning in the final 10 seconds of a wave
		var current_spawn_rate = spawn_rate
		if wave_time_left <= 10.0:
			current_spawn_rate = spawn_rate * 0.4
			
		if Time.get_ticks_msec() / 1000.0 >= next_spawn_time:
			_spawn_enemy()
			next_spawn_time = Time.get_ticks_msec() / 1000.0 + current_spawn_rate
	else:
		# Boss waves require defeating the boss to complete
		if active_enemies.size() == 0:
			print("[WaveManager] Boss defeated - wave complete!")
			wave_in_progress = false
			is_spawning_active = false
			if has_node("/root/UIManager"):
				get_node("/root/UIManager").show_upgrade_shop()
			else:
				GameManager.next_wave()
			return

func _trigger_cleansing_flash() -> void:
	AudioManager.play_sfx("bomb_impact")
	
	# Instakill all normal enemies with death effects
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			if enemy.has_method("take_damage"):
				enemy.take_damage(99999)
			else:
				enemy.queue_free()
	active_enemies.clear()
	
	# Blinding holy light flash effect by manipulating CanvasModulate
	var canvas = get_node_or_null("/root/MainGame/CanvasModulate")
	if canvas:
		var orig_color = canvas.color
		var tween = create_tween()
		tween.tween_property(canvas, "color", Color(3.0, 3.0, 3.0, 1.0), 0.15)
		tween.tween_property(canvas, "color", orig_color, 0.45)

	# Clean null references
	active_enemies = active_enemies.filter(func(e): return is_instance_valid(e))

func _spawn_enemy() -> void:
	if enemy_scenes.is_empty():
		print("[WaveManager] ERROR: enemy_scenes array is empty!")
		return

	var wave = GameManager.current_wave
	var max_index = 1 # Start with only basic enemies

	if wave >= 3:
		max_index = 3 # Add ghosts and vampires
	if wave >= 5:
		max_index = 4 # Add Frankensteins
	if wave >= 7:
		max_index = 5 # Add Lich
	if wave >= 10:
		max_index = 7 # Add Wraith and Plague Doctor
	if wave >= 13:
		max_index = 9 # Add Blood Golem and Crimson Harpy
	if wave >= 16:
		max_index = 11 # Add Lich Priest and Bone Archer
	if wave >= 20:
		max_index = 13 # Add Graveyard Brute and Nightmare Stalker
	if wave >= 25:
		max_index = 15 # Add Blood Moon Cultist and Abyssal Horror
	if wave >= 30:
		max_index = enemy_scenes.size() # Allow everything

	var spawn_pos = _get_random_spawn_position()
	var index = randi() % max_index
	var enemy = enemy_scenes[index].instantiate()
	add_child(enemy)
	enemy.global_position = spawn_pos
	active_enemies.append(enemy)
	if not is_timer_wave:
		enemies_to_spawn -= 1
	GameManager.emit_signal("enemy_spawned", enemy)

func _get_random_spawn_position() -> Vector2:
	var x = randf_range(-420, 420)
	var y = 320 if randf() > 0.5 else -320
	if randf() > 0.5:
		x = 420 if randf() > 0.5 else -420
		y = randf_range(-280, 280)
	return Vector2(x, y)

func get_nearest_enemy(from_pos: Vector2) -> Node2D:
	var nearest = null
	var min_dist = INF
	for e in active_enemies:
		if not is_instance_valid(e):
			continue
		var d = from_pos.distance_to(e.global_position)
		if d < min_dist:
			min_dist = d
			nearest = e
	return nearest
func _check_environment_change(wave_number: int) -> void:
	var target_env = ""
	var milestones = ENVIRONMENTS.keys()
	milestones.sort() # Ensure numerical order: 1, 11, 21, etc.
	
	for m in milestones:
		if wave_number >= m:
			target_env = ENVIRONMENTS[m]
		else:
			break
			
	if target_env != "":
		var main_game = get_parent()
		if main_game and main_game.has_method("change_environment"):
			main_game.change_environment(target_env)
