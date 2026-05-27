extends Control

@onready var main_panel = $MainPanel
@onready var scoreboard_panel = $ScoreboardPanel
@onready var settings_panel = $SettingsPanel

# Scoreboard elements
@onready var score_list = $ScoreboardPanel/VBox/ScoreList

# Settings elements
@onready var brightness_slider = $SettingsPanel/VBox/HBox/BrightnessSlider
@onready var brightness_val_label = $SettingsPanel/VBox/HBox/BrightnessValLabel

func _ready() -> void:
	# Show main options, hide others
	main_panel.visible = true
	scoreboard_panel.visible = false
	settings_panel.visible = false
	
	# Load settings UI states
	brightness_slider.value = GameManager.brightness_factor
	brightness_val_label.text = str(int(brightness_slider.value * 100)) + "%"
	brightness_slider.value_changed.connect(_on_brightness_changed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn")

func _on_scoreboard_pressed() -> void:
	# Clean list
	for child in score_list.get_children():
		child.queue_free()
		
	# Populate scores
	for item in GameManager.high_scores:
		var entry = Label.new()
		entry.text = str(item["name"]) + " : " + str(item["score"])
		entry.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		entry.add_theme_font_size_override("font_size", 18)
		score_list.add_child(entry)
		
	main_panel.visible = false
	scoreboard_panel.visible = true

func _on_settings_pressed() -> void:
	main_panel.visible = false
	settings_panel.visible = true

func _on_back_pressed() -> void:
	scoreboard_panel.visible = false
	settings_panel.visible = false
	main_panel.visible = true

func _on_brightness_changed(value: float) -> void:
	GameManager.brightness_factor = value
	brightness_val_label.text = str(int(value * 100)) + "%"
	GameManager.save_settings()

func _on_quit_pressed() -> void:
	get_tree().quit()
