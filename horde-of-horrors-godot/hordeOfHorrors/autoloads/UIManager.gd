extends Control

@onready var wave_label = $WaveLabel
@onready var score_label = $ScoreLabel
@onready var kills_label = $KillsLabel
@onready var currency_label = $CurrencyLabel
@onready var health_bar = $HealthBar
@onready var game_over_panel = $GameOverPanel
@onready var upgrade_panel = $UpgradePanel

func _ready() -> void:
	GameManager.wave_changed.connect(_on_wave_changed)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.kills_changed.connect(_on_kills_changed)
	GameManager.player_currency_changed.connect(_on_currency_changed)
	GameManager.game_over.connect(_on_game_over)

func _on_wave_changed(new_wave: int) -> void:
	wave_label.text = "Wave: " + str(new_wave)

func _on_score_changed(new_score: int) -> void:
	score_label.text = "Score: " + str(new_score)

func _on_kills_changed(new_kills: int) -> void:
	kills_label.text = "Kills: " + str(new_kills)

func _on_currency_changed(new_currency: int) -> void:
	currency_label.text = "Gold: " + str(new_currency)

func update_player_health(current_health: float, max_health: float) -> void:
	health_bar.value = current_health
	health_bar.max_value = max_health

func _on_game_over(final_score: int, waves_survived: int) -> void:
	game_over_panel.visible = true
	# Update game over panel stats here

func show_upgrade_panel() -> void:
	upgrade_panel.visible = true

func hide_upgrade_panel() -> void:
	upgrade_panel.visible = false
