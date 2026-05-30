extends Node

@onready var main_game = get_tree().current_scene

func update_player_health(current: int, max_health: int) -> void:
	var bar = get_tree().current_scene.get_node_or_null("UI/HealthBar")
	var label = get_tree().current_scene.get_node_or_null("UI/HealthBar/HealthLabel")
	if bar:
		bar.max_value = max_health
		bar.value = current
	if label:
		label.text = str(current) + " / " + str(max_health)

func update_ability_cooldown(cooldown: float) -> void:
	var label = get_tree().current_scene.get_node_or_null("UI/AbilityCooldown")
	if label:
		if cooldown > 0:
			label.text = "Ability: %.1fs" % cooldown
			label.modulate = Color(1, 0.3, 0.3)
		else:
			label.text = "Ability: READY"
			label.modulate = Color(0.3, 1, 0.3)

func show_upgrade_shop() -> void:
	var shop = get_node_or_null("UpgradeShop")
	if shop:
		shop.show_shop()

