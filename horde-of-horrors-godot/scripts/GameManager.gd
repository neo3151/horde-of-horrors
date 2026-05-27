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

var player: Node2D
var wave_manager: Node

var selected_character: String = "Hunter"

const CHARACTERS = {
	"Hunter": {
		"name": "Hunter",
		"texture": "res://assets/sprites/player/hunter.png",
		"health": 100,
		"speed": 320.0,
		"damage": 12,
		"fire_rate": 0.28,
		"bio": "A veteran hunter wielding a repeating silver crossbow. Balanced stats and high rate of fire.",
		"ability": "Rapid Crossbow Bolts"
	},
	"Werewolf": {
		"name": "Werewolf",
		"texture": "res://assets/sprites/werewolf/werewolf.png",
		"health": 120,
		"speed": 390.0,
		"damage": 22,
		"fire_rate": 0.45,
		"bio": "A feral beast that broke free from the horde. Unmatched movement speed and devastating melee claws.",
		"ability": "Feral Swiftness & Shredding Claws"
	},
	"Vampire": {
		"name": "Vampire",
		"texture": "res://assets/sprites/vampire/vampire.png",
		"health": 100,
		"speed": 300.0,
		"damage": 16,
		"fire_rate": 0.35,
		"bio": "A dark noble who rebelled against the elders. Shoots seeking bats and manipulates shadow power.",
		"ability": "Lifestealing Blood Orbs"
	},
	"Frankenstein": {
		"name": "Frankenstein",
		"texture": "res://assets/sprites/frankenstein/frankenstein.png",
		"health": 180,
		"speed": 220.0,
		"damage": 26,
		"fire_rate": 0.60,
		"bio": "A towering construct built from stitched remnants. Immune to minor knockback, boasts titanic health.",
		"ability": "Superhuman Fortitude"
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