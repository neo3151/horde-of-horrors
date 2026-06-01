import re

with open('scripts/UIManager.gd', 'r') as f:
    content = f.read()

# Add button connection
ready_str = """	GameManager.player_currency_changed.connect(update_currency)
	
	# Listen for scene changes to show/hide HUD appropriately"""
ready_new = """	GameManager.player_currency_changed.connect(update_currency)
	
	var ability_btn = get_node_or_null("HUD/AbilityButton")
	if ability_btn:
		ability_btn.pressed.connect(_on_ability_button_pressed)
	
	# Listen for scene changes to show/hide HUD appropriately"""
content = content.replace(ready_str, ready_new)

# Add callback function
func_str = """
func _on_ability_button_pressed() -> void:
	if GameManager.player and GameManager.player.has_method("use_ability"):
		GameManager.player.use_ability()
"""
content += func_str

with open('scripts/UIManager.gd', 'w') as f:
    f.write(content)
print("Added ability button connection")
