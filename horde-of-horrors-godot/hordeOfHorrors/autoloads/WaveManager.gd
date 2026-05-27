extends Node

signal wave_started(wave_number)
signal wave_completed(wave_number)
signal all_waves_completed()

@export var enemy_scene: PackedScene # This will be the base enemy scene

var current_wave_number: int = 0
var enemies_in_wave: int = 0
var enemies_killed_in_wave: int = 0
var wave_active: bool = false

var current_environment_index: int = 0
const ENVIRONMENTS: Array[String] = [
	"res://hordeOfHorrors/scenes/game/VillageStreets.tscn",
	"res://hordeOfHorrors/scenes/game/AbandonedCathedral.tscn",
	"res://hordeOfHorrors/scenes/game/FrankensteinMansion.tscn", # Placeholder
	"res://hordeOfHorrors/scenes/game/GraveyardCrypts.tscn", # Placeholder
	"res://hordeOfHorrors/scenes/game/DarkForest.tscn", # Placeholder
	"res://hordeOfHorrors/scenes/game/CastleRuins.tscn" # Placeholder
]

# Dictionary to hold elite enemy scenes per environment (placeholder for now)
var elite_enemy_scenes: Dictionary = {
	0: preload("res://hordeOfHorrors/scenes/enemies/Werewolf.tscn"), # Village Streets Elite
	1: preload("res://hordeOfHorrors/scenes/enemies/Vampire.tscn") # Abandoned Cathedral Elite
} # More environments and their elites will be added here

func _ready() -> void:
	GameManager.enemy_despawned.connect(_on_enemy_despawned)

func start_wave(wave_number: int) -> void:
	current_wave_number = wave_number
	emit_signal("wave_started", current_wave_number)
	wave_active = true
	enemies_killed_in_wave = 0

	# Determine number of enemies based on wave number (simple scaling for now)
	enemies_in_wave = 5 + (current_wave_number * 2)
	spawn_enemies(enemies_in_wave)

func spawn_enemies(count: int) -> void:
	var current_env_path = ENVIRONMENTS[current_environment_index]

	for i in range(count):
		var enemy_to_spawn: PackedScene
		# Implement elite spawn logic (every 5 waves)
		if current_wave_number % 5 == 0 and i == 0 and elite_enemy_scenes.has(current_environment_index):
			enemy_to_spawn = elite_enemy_scenes[current_environment_index]
		else:
			# For now, always spawn Werewolf as basic enemy, later this will be dynamic
			enemy_to_spawn = load("res://hordeOfHorrors/scenes/enemies/Werewolf.tscn")

		var enemy = PoolManager.get_instance(enemy_to_spawn.resource_path)
		if enemy:
			enemy.global_position = Vector2(randf_range(0, 1024), randf_range(0, 600))
			get_parent().add_child(enemy) # Assuming WaveManager is child of MainGame scene
			GameManager.emit_signal("enemy_spawned", enemy)

func _on_enemy_despawned(enemy_node: CharacterBody2D) -> void:
	PoolManager.return_instance(enemy_node.enemy_stats.resource_path, enemy_node)
	enemies_killed_in_wave += 1
	if wave_active and enemies_killed_in_wave >= enemies_in_wave:
		wave_active = false
		emit_signal("wave_completed", current_wave_number)
		if current_wave_number >= 20: # Example: 20 waves per environment
			current_environment_index += 1
			if current_environment_index < ENVIRONMENTS.size():
				GameManager.change_environment(ENVIRONMENTS[current_environment_index]) # GameManager needs to handle environment changes
			else:
				emit_signal("all_waves_completed")
		else:
			GameManager.next_wave()

func _ready() -> void:
	GameManager.enemy_despawned.connect(_on_enemy_despawned)

func start_wave(wave_number: int) -> void:
	current_wave_number = wave_number
	emit_signal("wave_started", current_wave_number)
	wave_active = true
	enemies_killed_in_wave = 0

	# Determine number of enemies based on wave number (simple scaling for now)
	enemies_in_wave = 5 + (current_wave_number * 2)
	spawn_enemies(enemies_in_wave)

func spawn_enemies(count: int) -> void:
	for i in range(count):
		var enemy = PoolManager.get_instance(enemy_scene.resource_path)
		if enemy:
			enemy.position = Vector2(randf_range(0, 1024), randf_range(0, 600))
			GameManager.emit_signal("enemy_spawned", enemy)

func _on_enemy_despawned(enemy_node: Node2D) -> void:
	PoolManager.return_instance(enemy_scene.resource_path, enemy_node)
	enemies_killed_in_wave += 1
	if wave_active and enemies_killed_in_wave >= enemies_in_wave:
		wave_active = false
		emit_signal("wave_completed", current_wave_number)
		if current_wave_number >= 100: # Placeholder for total waves
			emit_signal("all_waves_completed")
		else:
			GameManager.next_wave()
