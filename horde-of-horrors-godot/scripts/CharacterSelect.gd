extends Control

@onready var character_list_container = $VBoxMain/LeftPanel/CharacterList
@onready var bio_label = $VBoxMain/RightPanel/VBox/BioLabel
@onready var ability_label = $VBoxMain/RightPanel/VBox/AbilityLabel
@onready var health_bar = $VBoxMain/RightPanel/VBox/StatsGrid/HealthBar
@onready var speed_bar = $VBoxMain/RightPanel/VBox/StatsGrid/SpeedBar
@onready var damage_bar = $VBoxMain/RightPanel/VBox/StatsGrid/DamageBar
@onready var firerate_bar = $VBoxMain/RightPanel/VBox/StatsGrid/FireRateBar
@onready var preview_texture = $VBoxMain/RightPanel/VBox/PreviewPanel/PreviewTexture
@onready var char_title_label = $VBoxMain/RightPanel/VBox/CharTitle

var current_preview: String = "Hunter"

func _ready() -> void:
	# Default selection
	select_character("Hunter")
	
	# Connect buttons for items
	for char_name in GameManager.CHARACTERS.keys():
		var btn = get_node_or_null("VBoxMain/LeftPanel/CharacterList/" + char_name + "Card/SelectButton")
		if btn:
			btn.pressed.connect(func(): select_character(char_name))

	if has_node("/root/UIManager"):
		get_node("/root/UIManager").hide_hud()

func select_character(char_name: String) -> void:
	current_preview = char_name
	GameManager.selected_character = char_name
	
	# Get data
	var data = GameManager.CHARACTERS[char_name]
	
	# Update UI details
	char_title_label.text = data["name"].to_upper()
	bio_label.text = data["bio"]
	ability_label.text = "SPECIALTY: " + data["ability"]
	
	# Update Stats progress bars
	health_bar.value = data["health"]
	speed_bar.value = data["speed"]
	damage_bar.value = data["damage"]
	# Represent fire rate (lower is faster, so we map 1.0 - fire_rate to show higher bar for faster weapon)
	firerate_bar.value = (1.0 - data["fire_rate"]) * 100.0
	
	# Update preview sprite
	var tex = load(data["texture"])
	if tex:
		preview_texture.texture = tex
		
	# Update active highlights (modulate unselected cards)
	for other_name in GameManager.CHARACTERS.keys():
		var card = get_node_or_null("VBoxMain/LeftPanel/CharacterList/" + other_name + "Card")
		if card:
			if other_name == char_name:
				card.self_modulate = Color(1.2, 1.2, 1.2, 1.0) # Bright/Highlighted
				var btn = card.get_node("SelectButton")
				if btn: btn.text = "SELECTED"
			else:
				card.self_modulate = Color(0.5, 0.5, 0.5, 0.9) # Dimmed
				var btn = card.get_node("SelectButton")
				if btn: btn.text = "SELECT"

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainGame.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
