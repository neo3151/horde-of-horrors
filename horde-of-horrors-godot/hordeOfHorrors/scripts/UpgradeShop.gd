extends Control

@onready var background = $Background
@onready var panel = $Panel
@onready var title = $Panel/VBoxContainer/Title
@onready var hbox_categories = $Panel/VBoxContainer/HBoxContainer
@onready var upgrade_list = $Panel/VBoxContainer/UpgradeList
@onready var continue_button = $Panel/VBoxContainer/ContinueButton

func _ready() -> void:
	continue_button.pressed.connect(_on_continue_button_pressed)
	# Connect category buttons later when they have specific logic

func _on_continue_button_pressed() -> void:
	hide_shop()

func show_shop() -> void:
	visible = true
	# Populate upgrade options based on current game state / player
	# For now, just show placeholder items
	for child in upgrade_list.get_children():
		child.queue_free()
	
	var item1 = Button.new()
	item1.text = "Upgrade Damage (Cost: 10 Gold)"
	item1.pressed.connect(func(): _on_upgrade_selected("damage", 10))
	upgrade_list.add_child(item1)
	
	var item2 = Button.new()
	item2.text = "Upgrade Health (Cost: 15 Gold)"
	item2.pressed.connect(func(): _on_upgrade_selected("health", 15))
	upgrade_list.add_child(item2)
	
	# More upgrade options here, grouped by category

func hide_shop() -> void:
	visible = false

func _on_upgrade_selected(upgrade_type: String, cost: int) -> void:
	if GameManager.spend_currency(cost):
		match upgrade_type:
			"damage":
				GameManager.player.damage += 5 # Placeholder for player upgrade
				print("Upgraded damage!")
			"health":
				GameManager.player.max_health += 10 # Placeholder for player upgrade
				GameManager.player.health += 10 # Also heal a bit
				print("Upgraded health!")
		# Update UI or re-populate shop after upgrade
	else:
		print("Not enough gold for ", upgrade_type)
