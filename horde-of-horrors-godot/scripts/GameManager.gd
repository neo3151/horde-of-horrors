extends Node

signal wave_changed(new_wave)
signal score_changed(new_score)
signal kills_changed(new_kills)
signal player_currency_changed(new_currency)
signal enemy_spawned(enemy_node)
signal enemy_despawned(enemy_node)
signal game_over(final_score, waves_survived)

var current_wave: int = 1
var score: int = 0
var kills: int = 0
var player_currency: int = 0  # New: currency for upgrades
var is_game_over: bool = false
var purchased_upgrades: Dictionary = { "damage": 0, "fire_rate": 0, "health": 0, "speed": 0, "pact": 0 }

var player: Node # Changed from Node2D to support Node3D
var wave_manager: Node

var selected_character: String = "Hunter"

const WEAPONS = {
	"crossbow": {
		"id": "crossbow",
		"name": "Silver Crossbow",
		"scene": "", # Empty means use default crossbow logic in Player.gd for now
		"description": "Standard issue hunter weapon. Rapid firing silver bolts.",
		"cost": 0
	},
	"daggers": {
		"id": "daggers",
		"name": "Dual Daggers",
		"scene": "res://scenes/DualDaggers.tscn",
		"description": "Fast melee strikes that apply bleed on combo finishers.",
		"cost": 0
	},
	"rifle": {
		"id": "rifle",
		"name": "Blessed Repeating Rifle",
		"scene": "res://scenes/BlessedRepeatingRifle.tscn",
		"description": "High damage 3-round burst rifle.",
		"cost": 600
	},
	"stake_launcher": {
		"id": "stake_launcher",
		"name": "Stake Launcher",
		"scene": "res://scenes/StakeLauncher.tscn",
		"description": "Slow but powerful piercing stakes.",
		"cost": 750
	},
	"holy_water": {
		"id": "holy_water",
		"name": "Holy Water Grenades",
		"scene": "res://scenes/HolyWaterGrenade.tscn",
		"description": "Thrown vials that create sanctified ground.",
		"cost": 550
	},
	"garlic_bomb": {
		"id": "garlic_bomb",
		"name": "Garlic Bomb",
		"scene": "res://scenes/GarlicBomb.tscn",
		"description": "Slows and damages monsters in a smelly cloud.",
		"cost": 500
	},
	"longbow": {
		"id": "longbow",
		"name": "Moonlight Longbow",
		"scene": "res://scenes/MoonlightLongbow.tscn",
		"description": "Long range with very high critical hit chance.",
		"cost": 800
	},
	"greatsword": {
		"id": "greatsword",
		"name": "Silver Greatsword",
		"scene": "res://scenes/SilverGreatsword.tscn",
		"description": "Massive melee swings that knock back enemies.",
		"cost": 900
	},
	"staff": {
		"id": "staff",
		"name": "Blood Crystal Staff",
		"scene": "res://scenes/BloodCrystalStaff.tscn",
		"description": "Fires homing blood orbs that steal life.",
		"cost": 1000
	},
	"lightning_rod": {
		"id": "lightning_rod",
		"name": "Lightning Rod",
		"scene": "res://scenes/LightningRod.tscn",
		"description": "Chains electric damage between nearby enemies.",
		"cost": 850
	}
}

const CHARACTERS = {
	"Hunter": {
		"name": "Hunter",
		"texture": "res://assets/sprites/player/hunter.png",
		"health": 100,
		"speed": 320.0,
		"damage": 12,
		"fire_rate": 0.28,
		"bio": "A veteran hunter wielding a repeating silver crossbow. Balanced stats and high rate of fire.",
		"ability": "Rapid Crossbow Bolts",
		"starting_weapon": "crossbow"
	},
	"Werewolf": {
		"name": "Werewolf",
		"texture": "res://assets/sprites/werewolf/werewolf.png",
		"health": 120,
		"speed": 320.0,
		"damage": 22,
		"fire_rate": 0.45,
		"bio": "A feral beast that broke free from the horde. Unmatched movement speed and devastating melee claws.",
		"ability": "Feral Swiftness & Shredding Claws",
		"starting_weapon": "daggers"
	},
	"Vampire": {
		"name": "Vampire",
		"texture": "res://assets/sprites/vampire/vampire.png",
		"health": 100,
		"speed": 400.0,
		"damage": 16,
		"fire_rate": 0.35,
		"bio": "A dark noble who rebelled against the elders. Shoots seeking bats and manipulates shadow power.",
		"ability": "Lifestealing Blood Orbs",
		"starting_weapon": "staff"
	},
	"Frankenstein": {
		"name": "Frankenstein",
		"texture": "res://assets/sprites/frankenstein/frankenstein.png",
		"health": 180,
		"speed": 220.0,
		"damage": 26,
		"fire_rate": 0.60,
		"bio": "A towering construct built from stitched remnants. Immune to minor knockback, boasts titanic health.",
		"ability": "Superhuman Fortitude",
		"starting_weapon": "greatsword"
	},
	"Elias": {
		"name": "Elias",
		"texture": "res://assets/sprites/player/elias/elias.png",
		"health": 80,
		"speed": 340.0,
		"damage": 30,
		"fire_rate": 0.45,
		"bio": "A master of runic arts who found the 'Book of Dead Whispers'. Fragile but deals massive burst damage.",
		"ability": "Runic Burst",
		"starting_weapon": "crossbow"
	},
	"Serena": {
		"name": "Serena",
		"texture": "res://assets/sprites/player/serena/serena.png",
		"health": 90,
		"speed": 420.0,
		"damage": 14,
		"fire_rate": 0.22,
		"bio": "The swiftest huntress of the Silent Woods. Can dash through shadows and fire at lightning speeds.",
		"ability": "Shadow Dash",
		"starting_weapon": "daggers"
	},
	"Victor": {
		"name": "Victor",
		"texture": "res://assets/sprites/player/victor/victor.png",
		"health": 140,
		"speed": 280.0,
		"damage": 20,
		"fire_rate": 0.40,
		"bio": "A grizzled veteran who has survived a hundred full moons. High health and reliable stopping power.",
		"ability": "Holy Stopping Power",
		"starting_weapon": "rifle"
	}
}

const SCORES_SAVE_PATH = "user://scoreboard.cfg"
const SETTINGS_SAVE_PATH = "user://settings.cfg"

var high_scores: Array = []
var brightness_factor: float = 1.0

func _ready() -> void:
	load_scores()
	load_settings()

func start_game() -> void:
	current_wave = 1
	score = 0
	kills = 0
	player_currency = 0
	is_game_over = false
	purchased_upgrades = { "damage": 0, "fire_rate": 0, "health": 0, "speed": 0, "pact": 0 }
	emit_signal("wave_changed", current_wave)
	emit_signal("player_currency_changed", player_currency)
	emit_signal("score_changed", score)
	emit_signal("kills_changed", kills)
	if wave_manager:
		wave_manager.start_wave(current_wave)

func add_score(points: int) -> void:
	score += points
	emit_signal("score_changed", score)

func add_kill() -> void:
	kills += 1
	emit_signal("kills_changed", kills)

func next_wave() -> void:
	current_wave += 1
	emit_signal("wave_changed", current_wave)
	if wave_manager:
		wave_manager.start_wave(current_wave)

func add_currency(amount: int) -> void:
	player_currency += amount
	emit_signal("player_currency_changed", player_currency)

func spend_currency(amount: int) -> bool:
	if player_currency >= amount:
		player_currency -= amount
		emit_signal("player_currency_changed", player_currency)
		return true
	return false

func load_unlocked_characters() -> Array:
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_SAVE_PATH)
	if err == OK:
		return config.get_value("unlocks", "characters", ["Hunter"])
	return ["Hunter"]

func save_unlocked_characters(chars: Array) -> void:
	var config = ConfigFile.new()
	config.load(SETTINGS_SAVE_PATH)
	config.set_value("unlocks", "characters", chars)
	config.save(SETTINGS_SAVE_PATH)

func purchase_character(char_name: String) -> bool:
	var chars = load_unlocked_characters()
	var char_data = CHARACTERS.get(char_name)
	if not char_data or chars.has(char_name):
		return false # Already unlocked or invalid
		
	var cost = char_data.get("cost", 500)
	if spend_currency(cost):
		chars.append(char_name)
		save_unlocked_characters(chars)
		return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() or OS.has_feature("editor"):
		if event is InputEventKey and event.pressed and not event.echo:
			# Press L to skip current wave
			if event.keycode == KEY_L:
				if wave_manager and wave_manager.wave_in_progress:
					wave_manager.enemies_to_spawn = 0
					for enemy in wave_manager.active_enemies:
						if is_instance_valid(enemy):
							enemy.queue_free()
					wave_manager.active_enemies.clear()
					print("Debug: Skipped Wave ", current_wave)
			# Press K to jump forward 10 waves
			elif event.keycode == KEY_K:
				if wave_manager:
					current_wave += 10
					# Force UI update directly as signal might be delayed or blocked
					if UIManager:
						UIManager.update_wave(current_wave)
					
					emit_signal("wave_changed", current_wave)
					
					wave_manager.enemies_to_spawn = 0
					for enemy in wave_manager.active_enemies:
						if is_instance_valid(enemy):
							enemy.queue_free()
					wave_manager.active_enemies.clear()
					
					# Manually trigger environment check and wave start
					wave_manager.start_wave(current_wave)
					print("Debug: Jumped forward to Wave ", current_wave)

func trigger_game_over() -> void:
	is_game_over = true
	emit_signal("game_over", score, current_wave)

# Scoreboard functions
func load_scores() -> void:
	high_scores.clear()
	var config = ConfigFile.new()
	var err = config.load(SCORES_SAVE_PATH)
	if err == OK:
		high_scores = config.get_value("scores", "list", [])
	else:
		# Seed default high scores
		high_scores = [
			{"name": "Hunter Alpha", "score": 1200},
			{"name": "Belmont", "score": 850},
			{"name": "Van Helsing", "score": 600},
			{"name": "Blade", "score": 400},
			{"name": "Buffy", "score": 200}
		]
		save_scores()

func save_scores() -> void:
	var config = ConfigFile.new()
	config.set_value("scores", "list", high_scores)
	config.save(SCORES_SAVE_PATH)

func add_new_score(player_name: String, final_score: int) -> void:
	high_scores.append({"name": player_name, "score": final_score})
	# Sort scores descending
	high_scores.sort_custom(func(a, b): return a["score"] > b["score"])
	# Keep only top 5 scores
	if high_scores.size() > 5:
		high_scores = high_scores.slice(0, 5)
	save_scores()

# Settings functions
func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_SAVE_PATH)
	if err == OK:
		brightness_factor = config.get_value("display", "brightness", 1.0)
	else:
		brightness_factor = 1.0

func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("display", "brightness", brightness_factor)
	config.save(SETTINGS_SAVE_PATH)
