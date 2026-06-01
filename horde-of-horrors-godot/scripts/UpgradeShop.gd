extends Control

var UPGRADES = [
	{
		"id": "damage",
		"title": "+3 Crossbow Damage",
		"description": "Increases silver bolt damage by 3.",
		"action": func(player): player.upgrade_damage(3)
	},
	{
		"id": "fire_rate",
		"title": "-15% Fire Cooldown",
		"description": "Increases crossbow rate of fire.",
		"action": func(player): player.fire_rate = max(0.1, player.fire_rate * 0.85)
	},
	{
		"id": "health",
		"title": "+25 Max Health",
		"description": "Boosts maximum vitality and heals you.",
		"action": func(player): player.max_health += 25; player.heal(25)
	},
	{
		"id": "speed",
		"title": "+15% Movement Speed",
		"description": "Makes you swifter on your feet.",
		"action": func(player): player.move_speed *= 1.15
	},
	{
		"id": "pact",
		"title": "Sinister Blood Pact",
		"description": "Increases damage by 8 but lowers max health by 15.",
		"action": func(player): player.upgrade_damage(8); player.max_health = max(20, player.max_health - 15); player.current_health = min(player.current_health, player.max_health); player._update_health_ui()
	},
	{
		"id": "w_rifle",
		"title": "Blessed Rifle",
		"description": "Unlock the 3-round burst Blessed Repeating Rifle.",
		"action": func(player): player.change_weapon("rifle"),
		"type": "weapon"
	},
	{
		"id": "w_stake",
		"title": "Stake Launcher",
		"description": "Unlock the powerful piercing Stake Launcher.",
		"action": func(player): player.change_weapon("stake_launcher"),
		"type": "weapon"
	},
	{
		"id": "w_holy",
		"title": "Holy Grenades",
		"description": "Unlock Holy Water Grenades for AoE damage zones.",
		"action": func(player): player.change_weapon("holy_water"),
		"type": "weapon"
	},
	{
		"id": "w_garlic",
		"title": "Garlic Bombs",
		"description": "Unlock Garlic Bombs to slow and damage enemies.",
		"action": func(player): player.change_weapon("garlic_bomb"),
		"type": "weapon"
	},
	{
		"id": "w_bow",
		"title": "Moonlight Bow",
		"description": "Unlock the high-crit Moonlight Longbow.",
		"action": func(player): player.change_weapon("longbow"),
		"type": "weapon"
	},
	{
		"id": "w_sword",
		"title": "Silver Greatsword",
		"description": "Unlock the heavy-hitting Silver Greatsword.",
		"action": func(player): player.change_weapon("greatsword"),
		"type": "weapon"
	},
	{
		"id": "w_staff",
		"title": "Crystal Staff",
		"description": "Unlock the lifestealing Blood Crystal Staff.",
		"action": func(player): player.change_weapon("staff"),
		"type": "weapon"
	},
	{
		"id": "w_lightning",
		"title": "Lightning Rod",
		"description": "Unlock the chain-lightning Lightning Rod.",
		"action": func(player): player.change_weapon("lightning_rod"),
		"type": "weapon"
	},
	{
		"id": "p_nova",
		"title": "Holy Nova",
		"description": "Radial blast that purges all nearby enemies.",
		"action": func(player): 
			var data = PowerUpData.new()
			data.type = PowerUpData.PowerUpType.HOLY_NOVA
			data.value = 50.0
			player.apply_powerup(data),
		"type": "powerup"
	},
	{
		"id": "p_time",
		"title": "Temporal Rift",
		"description": "Slow down time for 5 seconds.",
		"action": func(player): 
			var data = PowerUpData.new()
			data.type = PowerUpData.PowerUpType.TIME_SLOW
			data.duration = 5.0
			player.apply_powerup(data),
		"type": "powerup"
	},
	{
		"id": "p_double",
		"title": "Echo Strike",
		"description": "Fire twice as many projectiles for 10 seconds.",
		"action": func(player): 
			var data = PowerUpData.new()
			data.type = PowerUpData.PowerUpType.DOUBLE_SHOT
			data.duration = 10.0
			player.apply_powerup(data),
		"type": "powerup"
	},
	{
		"id": "p_rage",
		"title": "Blood Moon Rage",
		"description": "Ultimate power! Invulnerability and massive damage for 8s.",
		"action": func(player): 
			var data = PowerUpData.new()
			data.type = PowerUpData.PowerUpType.BLOOD_MOON_RAGE
			data.duration = 8.0
			player.apply_powerup(data),
		"type": "powerup"
	},
	{
		"id": "p_ghost",
		"title": "Ghost Phase",
		"description": "Become intangible and move faster for 6s.",
		"action": func(player): 
			var data = PowerUpData.new()
			data.type = PowerUpData.PowerUpType.GHOST_FORM
			data.duration = 6.0
			player.apply_powerup(data),
		"type": "powerup"
	}
]

@onready var upgrade_list = $Panel/VBoxContainer/UpgradeList
@onready var continue_btn = $Panel/VBoxContainer/ContinueButton

func _ready() -> void:
	if continue_btn:
		continue_btn.pressed.connect(hide_shop)
	# Hide category selectors if we are doing direct card drafts
	var category_container = get_node_or_null("Panel/VBoxContainer/HBoxContainer")
	if category_container:
		category_container.visible = false

func show_shop() -> void:
	visible = true
	get_tree().paused = true
	_populate_upgrades()

var ICONS = {
	"damage": load("res://assets/sprites/ui/powerup_icons/fury.svg"),
	"fire_rate": load("res://assets/sprites/ui/icons/rapid.png"),
	"health": load("res://assets/sprites/ui/powerup_icons/health_pack.svg"),
	"speed": load("res://assets/sprites/ui/powerup_icons/blood_rush.svg"),
	"pact": load("res://assets/sprites/ui/icons/pact.png"),
	"w_rifle": load("res://assets/sprites/ui/weapon_icons/rifle_icon.svg"),
	"w_stake": load("res://assets/sprites/ui/weapon_icons/stake_launcher_icon.svg"),
	"w_holy": load("res://assets/sprites/ui/weapon_icons/holy_grenade_icon.svg"),
	"w_garlic": load("res://assets/sprites/ui/weapon_icons/garlic_bomb_icon.svg"),
	"w_bow": load("res://assets/sprites/ui/weapon_icons/moonlight_bow_icon.svg"),
	"w_sword": load("res://assets/sprites/ui/weapon_icons/greatsword_icon.svg"),
	"w_staff": load("res://assets/sprites/ui/weapon_icons/crystal_staff_icon.svg"),
	"w_lightning": load("res://assets/sprites/ui/weapon_icons/lightning_rod_icon.svg"),
	"p_nova": load("res://assets/sprites/ui/powerup_icons/holy_nova.svg"),
	"p_time": load("res://assets/sprites/ui/powerup_icons/time_slow.svg"),
	"p_double": load("res://assets/sprites/ui/powerup_icons/double_shot.svg"),
	"p_rage": load("res://assets/sprites/ui/powerup_icons/blood_moon_rage.svg"),
	"p_ghost": load("res://assets/sprites/ui/powerup_icons/ghost_form.svg")
}

func hide_shop() -> void:
	visible = false
	get_tree().paused = false
	GameManager.next_wave()

func _populate_upgrades() -> void:
	# Clear previous items
	for child in upgrade_list.get_children():
		child.queue_free()
	
	# Select 3 random unique upgrades
	var choices = []
	var pool = UPGRADES.duplicate()
	pool.shuffle()
	for i in range(min(3, pool.size())):
		choices.append(pool[i])
		
	# Populate buttons
	for item in choices:
		var btn = Button.new()
		btn.text = " %s\n %s" % [item["title"], item["description"]]
		btn.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
		btn.custom_minimum_size = Vector2(0, 60)
		
		if ICONS.has(item["id"]):
			btn.icon = ICONS[item["id"]]
			btn.expand_icon = true
			
		upgrade_list.add_child(btn)
		
		# Connect button pressed
		btn.pressed.connect(func():
			if is_instance_valid(GameManager.player):
				item["action"].call(GameManager.player)
				if GameManager.purchased_upgrades.has(item["id"]):
					GameManager.purchased_upgrades[item["id"]] += 1
			hide_shop()
		)

