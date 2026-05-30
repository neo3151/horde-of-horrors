extends Control

var UPGRADES = [
	{
		"title": "🩸 +3 Crossbow Damage",
		"description": "Increases silver bolt damage by 3.",
		"action": func(player): player.upgrade_damage(3)
	},
	{
		"title": "⚡ -15% Fire Cooldown",
		"description": "Increases crossbow rate of fire.",
		"action": func(player): player.fire_rate = max(0.1, player.fire_rate * 0.85)
	},
	{
		"title": "💚 +25 Max Health",
		"description": "Boosts maximum vitality and heals you.",
		"action": func(player): player.max_health += 25; player.heal(25)
	},
	{
		"title": "👢 +15% Movement Speed",
		"description": "Makes you swifter on your feet.",
		"action": func(player): player.move_speed *= 1.15
	},
	{
		"title": "😈 Sinister Blood Pact",
		"description": "Increases damage by 8 but lowers max health by 15.",
		"action": func(player): player.upgrade_damage(8); player.max_health = max(20, player.max_health - 15); player.current_health = min(player.current_health, player.max_health); player._update_health_ui()
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
		btn.text = "%s\n%s" % [item["title"], item["description"]]
		btn.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
		btn.custom_minimum_size = Vector2(0, 60)
		upgrade_list.add_child(btn)
		
		# Connect button pressed
		btn.pressed.connect(func():
			if is_instance_valid(GameManager.player):
				item["action"].call(GameManager.player)
			hide_shop()
		)

func hide_shop() -> void:
	visible = false
	get_tree().paused = false
	GameManager.next_wave()
