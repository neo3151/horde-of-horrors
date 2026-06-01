extends Node

# Dictionary holding lore pages for each enemy/location
const LORE_PAGES = {
	"werewolf": {
		"title": "The Howling Hunger",
		"content": "Once a proud hunter named Gregor Hale... The Crimson Realm turned his loyalty into savagery.",
		"unlocked": false
	},
	"vampire": {
		"title": "The Eternal Thirst",
		"content": "Lady Isolde Voss... She still wears her wedding ring on a chain around her neck.",
		"unlocked": false
	},
	"frankenstein": {
		"title": "The Abomination That Remembers",
		"content": "Built from the bodies of seven executed murderers and his own dead son. It was never meant to live this long.",
		"unlocked": false
	},
	"wraith": {
		"title": "The Unfinished Soul",
		"content": "Father Thomas Hale... His soul never left.",
		"unlocked": false
	},
	"plague_doctor": {
		"title": "The Merchant of Rot",
		"content": "Dr. Elias Crowe... He became the very thing he feared.",
		"unlocked": false
	},
	"blood_golem": {
		"title": "The Walking Wound",
		"content": "Created from the pooled blood of every victim... literally the valley’s collective trauma given form.",
		"unlocked": false
	}
}

func _ready() -> void:
	pass

func unlock_lore(key: String) -> void:
	if LORE_PAGES.has(key) and not LORE_PAGES[key]["unlocked"]:
		LORE_PAGES[key]["unlocked"] = true
		print("Unlocked Lore: ", LORE_PAGES[key]["title"])
		# Notify UI that a new lore page is available
		# UIManager.show_lore_notification(LORE_PAGES[key]["title"])

func is_lore_unlocked(key: String) -> bool:
	return LORE_PAGES.has(key) and LORE_PAGES[key]["unlocked"]

func get_unlocked_lore() -> Array:
	var unlocked = []
	for key in LORE_PAGES:
		if LORE_PAGES[key]["unlocked"]:
			unlocked.append(LORE_PAGES[key])
	return unlocked
