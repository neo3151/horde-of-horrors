extends CanvasLayer

@onready var main_game = get_tree().current_scene

func _ready() -> void:
	# Keep HUD hidden by default — it should only show during gameplay
	var hud = get_node_or_null("HUD")
	if hud:
		hud.visible = false
	
	# Connect GameManager signals to update HUD
	GameManager.wave_changed.connect(update_wave)
	GameManager.score_changed.connect(update_score)
	GameManager.kills_changed.connect(update_kills)
	GameManager.player_currency_changed.connect(update_currency)
	
	# Listen for scene changes to show/hide HUD appropriately
	get_tree().tree_changed.connect(_on_tree_changed)

func _on_tree_changed() -> void:
	var current = get_tree().current_scene
	var hud = get_node_or_null("HUD")
	if not hud:
		return
	# Only show HUD when we're in the MainGame scene
	if current and current.name == "MainGame":
		hud.visible = true
	else:
		hud.visible = false

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

