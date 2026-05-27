extends Node2D

@onready var wave_label = $UI/WaveLabel
@onready var score_label = $UI/ScoreLabel
@onready var kills_label = $UI/KillsLabel
@onready var currency_label = $UI/CurrencyLabel

@onready var upgrade_button = $UI/UpgradePanel/UpgradeButton

@onready var game_over_panel = $UI/GameOverPanel
@onready var stats_label = $UI/GameOverPanel/VBox/Stats
@onready var name_input = $UI/GameOverPanel/VBox/NameInput
@onready var save_button = $UI/GameOverPanel/VBox/SaveButton
@onready var skip_button = $UI/GameOverPanel/VBox/SkipButton

func _ready() -> void:
    # Register this scene's components with the singleton
    GameManager.wave_manager = $WaveManager
    
    # Apply ambient light settings
    var base_color = Color(0.35, 0.35, 0.45, 1)
    if has_node("CanvasModulate"):
        $CanvasModulate.color = base_color * GameManager.brightness_factor
        
    # Connect signals for UI updates
    GameManager.wave_changed.connect(_on_wave_changed)
    GameManager.score_changed.connect(_on_score_changed)
    GameManager.kills_changed.connect(_on_kills_changed)
    GameManager.player_currency_changed.connect(_on_currency_changed)
    
    # Connect Game Over and UI button signals
    GameManager.game_over.connect(_on_game_over)
    save_button.pressed.connect(_on_save_pressed)
    skip_button.pressed.connect(_on_skip_pressed)
    upgrade_button.pressed.connect(_on_upgrade_button_pressed)

    # Start the game loop
    GameManager.start_game()

func _on_wave_changed(new_wave):
    wave_label.text = "Wave: " + str(new_wave)

func _on_score_changed(new_score):
    score_label.text = "Score: " + str(new_score)

func _on_kills_changed(new_kills):
    kills_label.text = "Kills: " + str(new_kills)

func _on_currency_changed(new_currency):
    currency_label.text = "Gold: " + str(new_currency)

func _on_upgrade_button_pressed() -> void:
    var upgrade_cost = 10 # Example cost
    if GameManager.spend_currency(upgrade_cost):
        GameManager.player.upgrade_damage(5) # Example damage increase

func _on_game_over(final_score: int, waves_survived: int) -> void:
    stats_label.text = "Score: " + str(final_score) + " | Wave: " + str(waves_survived)
    game_over_panel.visible = true
    name_input.grab_focus()

func _on_save_pressed() -> void:
    var p_name = name_input.text.strip_edges()
    if p_name == "":
        p_name = "Anonymous"
    GameManager.add_new_score(p_name, GameManager.score)
    get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_skip_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
