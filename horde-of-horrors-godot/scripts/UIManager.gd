extends CanvasLayer

@onready var main_game = get_tree().current_scene

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Keep HUD hidden by default — it should only show during gameplay
	var hud = get_node_or_null("HUD")
	if hud:
		hud.visible = false
	
	# Connect GameManager signals to update HUD
	GameManager.wave_changed.connect(update_wave)
	GameManager.score_changed.connect(update_score)
	GameManager.kills_changed.connect(update_kills)
	GameManager.player_currency_changed.connect(update_currency)
	GameManager.game_over.connect(_on_game_over)
	
	var ability_btn = get_node_or_null("HUD/AbilityButton")
	if ability_btn:
		ability_btn.pressed.connect(_on_ability_button_pressed)
	
	var save_btn = get_node_or_null("GameOverPanel/VBox/SaveButton")
	if save_btn:
		save_btn.pressed.connect(_on_save_score_pressed)
		
	var skip_btn = get_node_or_null("GameOverPanel/VBox/SkipButton")
	if skip_btn:
		skip_btn.pressed.connect(_on_skip_pressed)
	
	var pause_btn = get_node_or_null("HUD/PauseButton")
	if pause_btn:
		pause_btn.pressed.connect(_on_pause_button_pressed)
	
	# Explicit methods to show/hide HUD called from game scenes
	hide_hud()

func show_hud() -> void:
	var hud = get_node_or_null("HUD")
	if hud:
		hud.visible = true
	var panel = get_node_or_null("GameOverPanel")
	if panel:
		panel.visible = false

func hide_hud() -> void:
	var hud = get_node_or_null("HUD")
	if hud:
		hud.visible = false
	var panel = get_node_or_null("GameOverPanel")
	if panel:
		panel.visible = false

func update_player_health(current: int, max_health: int) -> void:
	var bar = get_node_or_null("HUD/HealthBar")
	var label = get_node_or_null("HUD/HealthBar/HealthLabel")
	if bar:
		bar.max_value = max_health
		bar.value = current
	if label:
		label.text = str(current) + " / " + str(max_health)

func update_ability_cooldown(cooldown: float) -> void:
	var label = get_node_or_null("HUD/AbilityCooldown")
	if label:
		if cooldown > 0:
			label.text = "Ability: %.1fs" % cooldown
			label.modulate = Color(1, 0.3, 0.3)
		else:
			label.text = "Ability: READY"
			label.modulate = Color(0.3, 1, 0.3)

func update_wave(wave_number: int) -> void:
	var label = get_node_or_null("HUD/WaveLabel")
	if label:
		label.text = "Wave: %d" % wave_number

func update_score(new_score: int) -> void:
	var label = get_node_or_null("HUD/ScoreLabel")
	if label:
		label.text = "Score: %d" % new_score

func update_kills(new_kills: int) -> void:
	var label = get_node_or_null("HUD/KillsLabel")
	if label:
		label.text = "Kills: %d" % new_kills

func update_currency(new_currency: int) -> void:
	var label = get_node_or_null("HUD/CurrencyLabel")
	if label:
		label.text = "Gold: %d" % new_currency

func show_upgrade_shop() -> void:
	var shop = get_node_or_null("UpgradeShop")
	if shop:
		shop.show_shop()


func _on_pause_button_pressed() -> void:
	var pause_menu = get_node_or_null("PauseMenu")
	if pause_menu and pause_menu.has_method("toggle_pause"):
		pause_menu.toggle_pause()

func _on_ability_button_pressed() -> void:
	if GameManager.player and GameManager.player.has_method("use_ability"):
		GameManager.player.use_ability()

func _on_game_over(final_score: int, waves: int) -> void:
	var panel = get_node_or_null("GameOverPanel")
	if panel:
		panel.visible = true
		var stats_label = panel.get_node("VBox/Stats")
		if stats_label:
			stats_label.text = "Score: %d | Waves Survived: %d" % [final_score, waves]
		
		# Hide the HUD
		var hud = get_node_or_null("HUD")
		if hud:
			hud.visible = false

func _on_save_score_pressed() -> void:
	print("Save score pressed!")
	var input = get_node_or_null("GameOverPanel/VBox/NameInput")
	var player_name = "Unknown Hunter"
	if input and input.text != "":
		player_name = input.text
	
	GameManager.add_new_score(player_name, GameManager.score)
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_skip_pressed() -> void:
	print("Skip pressed!")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
