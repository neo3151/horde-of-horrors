extends Node

var current_blood_essence: int = 0
var permanent_upgrades: Dictionary = {
	"health_boost": 0,
	"damage_boost": 0,
	"speed_boost": 0,
	"magnet_range": 0
}

var unlocked_characters: Array[String] = ["Elias Voss", "Serena Nightshade"]
var premium_character_unlocked: bool = false

func _ready() -> void:
	load_meta_progression()

func add_blood_essence(amount: int) -> void:
	current_blood_essence += amount
	save_meta_progression()

func spend_blood_essence(amount: int) -> bool:
	if current_blood_essence >= amount:
		current_blood_essence -= amount
		save_meta_progression()
		return true
	return false

func purchase_permanent_upgrade(upgrade_name: String, cost: int) -> bool:
	if permanent_upgrades.has(upgrade_name) and spend_blood_essence(cost):
		permanent_upgrades[upgrade_name] += 1
		save_meta_progression()
		print("Purchased permanent upgrade: ", upgrade_name)
		return true
	return false

func unlock_premium_character_with_essence() -> bool:
	if not premium_character_unlocked and spend_blood_essence(650):
		premium_character_unlocked = true
		unlocked_characters.append("Victor Van Helsing")
		save_meta_progression()
		print("Unlocked Victor Van Helsing with Blood Essence!")
		return true
	return false
	
func unlock_premium_character_with_iap() -> void:
	# Placeholder for real IAP logic
	print("Simulating IAP purchase for Victor Van Helsing...")
	if not premium_character_unlocked:
		premium_character_unlocked = true
		unlocked_characters.append("Victor Van Helsing")
		save_meta_progression()
		print("Unlocked Victor Van Helsing via IAP!")

func get_permanent_multiplier(stat_name: String) -> float:
	match stat_name:
		"health": return 1.0 + (permanent_upgrades["health_boost"] * 0.05)
		"damage": return 1.0 + (permanent_upgrades["damage_boost"] * 0.05)
		"speed": return 1.0 + (permanent_upgrades["speed_boost"] * 0.02)
		"magnet": return 1.0 + (permanent_upgrades["magnet_range"] * 0.1)
	return 1.0

func save_meta_progression() -> void:
	var save_data = {
		"blood_essence": current_blood_essence,
		"upgrades": permanent_upgrades,
		"unlocked_chars": unlocked_characters,
		"premium_unlocked": premium_character_unlocked
	}
	# Assuming SaveManager has a general save_data function that merges with existing
	if SaveManager.has_method("save_meta_data"):
		SaveManager.save_meta_data(save_data)

func load_meta_progression() -> void:
	if SaveManager.has_method("load_meta_data"):
		var data = SaveManager.load_meta_data()
		if data.is_empty(): return
		
		if data.has("blood_essence"): current_blood_essence = data["blood_essence"]
		if data.has("upgrades"): permanent_upgrades = data["upgrades"]
		if data.has("unlocked_chars"): unlocked_characters = data["unlocked_chars"]
		if data.has("premium_unlocked"): premium_character_unlocked = data["premium_unlocked"]
