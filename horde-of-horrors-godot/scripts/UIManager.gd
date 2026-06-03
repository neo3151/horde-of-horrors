extends CanvasLayer

@onready var main_game = get_tree().current_scene

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Keep HUD hidden by default — it should only show during gameplay
	var hud = get_node_or_null("HUD")
	if hud:
		hud.visible = false
	_create_active_items_bar()
	
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
	
	var start_btn = get_node_or_null("StageBriefingPanel/VBox/StartButton")
	if start_btn:
		start_btn.pressed.connect(_on_start_wave_pressed)
		
	var briefing = get_node_or_null("StageBriefingPanel")
	if briefing:
		briefing.visible = false
		
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
	AudioManager.play_sfx("hit")
	var pause_menu = get_node_or_null("PauseMenu")
	if pause_menu and pause_menu.has_method("toggle_pause"):
		pause_menu.toggle_pause()

func _on_ability_button_pressed() -> void:
	AudioManager.play_sfx("hit")
	if GameManager.player and GameManager.player.has_method("use_ability"):
		GameManager.player.use_ability()

func _on_game_over(final_score: int, waves: int) -> void:
	AudioManager.stop_music()
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
	AudioManager.play_sfx("hit")
	print("Save score pressed!")
	var input = get_node_or_null("GameOverPanel/VBox/NameInput")
	var player_name = "Unknown Hunter"
	if input and input.text != "":
		player_name = input.text
	
	GameManager.add_new_score(player_name, GameManager.score)
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_skip_pressed() -> void:
	AudioManager.play_sfx("hit")
	print("Skip pressed!")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_start_wave_pressed() -> void:
	AudioManager.play_sfx("hit")
	var briefing = get_node_or_null("StageBriefingPanel")
	if briefing:
		var tween = create_tween()
		tween.parallel().tween_property(briefing, "modulate:a", 0.0, 0.15)
		tween.parallel().tween_property(briefing, "scale", Vector2(1.1, 1.1), 0.15)
		tween.tween_callback(func():
			briefing.visible = false
			get_tree().paused = false
			if GameManager.wave_manager and GameManager.wave_manager.has_method("start_spawning"):
				GameManager.wave_manager.start_spawning()
		)
	else:
		get_tree().paused = false
		if GameManager.wave_manager and GameManager.wave_manager.has_method("start_spawning"):
			GameManager.wave_manager.start_spawning()

func show_stage_briefing(wave_num: int) -> void:
	var briefing = get_node_or_null("StageBriefingPanel")
	if not briefing:
		return
	
	# Determine Environment Name and Description (Lore)
	var env_name = "Forsaken Village Outskirts"
	var env_lore = "The shadows grow long, and the wolves are hungry. Keep moving through the foggy village."
	if wave_num >= 91:
		env_name = "Cursed Ironworks"
		env_lore = "The furnaces burn with hellfire. A final stand against metal-clad behemoths."
	elif wave_num >= 81:
		env_name = "Ruined Castle Eldritch"
		env_lore = "The stronghold of the ancient vampire lords. Their thirst remains unquenched."
	elif wave_num >= 71:
		env_name = "Decaying Victorian Mansion"
		env_lore = "Dust settled in the grand halls, but the ancestors' spirits still walk the corridors."
	elif wave_num >= 61:
		env_name = "Overgrown Graveyard"
		env_lore = "Mossy gravestones crumble, and ancient ghouls rise to claim the living."
	elif wave_num >= 51:
		env_name = "Underground Catacombs"
		env_lore = "Deep beneath the earth, a dark tomb crawling with skeletal archers and plague doctors."
	elif wave_num >= 41:
		env_name = "Fog-Shrouded Harbor"
		env_lore = "Lurk in the misty docks where the dead wash ashore and undead pirates patrol."
	elif wave_num >= 31:
		env_name = "Abandoned Cathedral District"
		env_lore = "The holy bells ring no more. Only the hollow groans of Abyssal Horrors echo."
	elif wave_num >= 21:
		env_name = "Cursed Bloodwood Forest"
		env_lore = "The trees whisper ancient curses, drinking the blood of those who fall."
	elif wave_num >= 11:
		env_name = "Shattered Trade District"
		env_lore = "Once a wealthy marketplace, now a ruined corridor where ghosts and vampires hunt."
	
	var env_label = briefing.get_node_or_null("VBox/EnvironmentLabel")
	if env_label:
		env_label.text = "Environment: %s (Wave %d)" % [env_name, wave_num]
		
	var lore_label = briefing.get_node_or_null("VBox/LoreLabel")
	if lore_label:
		lore_label.text = '"' + env_lore + '"'
		
	# Determine Threat Level in skulls
	var threat_label = briefing.get_node_or_null("VBox/ThreatLabel")
	if threat_label:
		var skulls = "💀"
		if wave_num >= 36: skulls = "💀💀💀💀💀"
		elif wave_num >= 26: skulls = "💀💀💀💀"
		elif wave_num >= 16: skulls = "💀💀💀"
		elif wave_num >= 6: skulls = "💀💀"
		threat_label.text = "Threat Level: %s" % skulls
		
	# Determine Objective
	var obj_label = briefing.get_node_or_null("VBox/ObjectiveLabel")
	if obj_label:
		if wave_num % 10 == 0:
			var boss_name = "Alpha Werewolf"
			match wave_num:
				10: boss_name = "Alpha Werewolf"
				20: boss_name = "Vampire Matriarch"
				30: boss_name = "Revenant Frankenstein"
				40: boss_name = "Lich High Priest"
				50: boss_name = "Stitcher Golem"
				60: boss_name = "The First One"
				_: boss_name = "Alpha Werewolf"
			obj_label.text = "Slay the Boss: %s!" % boss_name
		else:
			var duration = 30.0 + (wave_num * 5.0)
			obj_label.text = "Survive the Horde: %d seconds" % int(duration)
			
	# Determine Expected Monsters
	var monsters_label = briefing.get_node_or_null("VBox/MonstersLabel")
	if monsters_label:
		if wave_num % 10 == 0:
			var boss_name = "Alpha Werewolf"
			match wave_num:
				10: boss_name = "Alpha Werewolf"
				20: boss_name = "Vampire Matriarch"
				30: boss_name = "Revenant Frankenstein"
				40: boss_name = "Lich High Priest"
				50: boss_name = "Stitcher Golem"
				60: boss_name = "The First One"
				_: boss_name = "Alpha Werewolf"
			monsters_label.text = "%s (BOSS)" % boss_name
		else:
			var monsters = ["Werewolf", "Vampire"]
			if wave_num >= 3: monsters.append("Ghost")
			if wave_num >= 5: monsters.append("Frankenstein")
			if wave_num >= 7: monsters.append("Lich")
			if wave_num >= 10: 
				monsters.append("Wraith")
				monsters.append("Plague Doctor")
			if wave_num >= 13:
				monsters.append("Blood Golem")
				monsters.append("Crimson Harpy")
			if wave_num >= 16:
				monsters.append("Lich Priest")
				monsters.append("Bone Archer")
			if wave_num >= 20:
				monsters.append("Graveyard Brute")
				monsters.append("Nightmare Stalker")
			if wave_num >= 25:
				monsters.append("Blood Moon Cultist")
				monsters.append("Abyssal Horror")
			monsters_label.text = ", ".join(monsters)
			
	# Determine Tip
	var tips_label = briefing.get_node_or_null("VBox/TipsLabel")
	if tips_label:
		var tips = [
			"Destructible cover (barrels, gravestones, pillars) spawns each wave. Hide behind them to block enemy projectiles!",
			"Melee enemies will hit and chip away at your cover. Don't stay behind a crumbling barricade for too long!",
			"Your dodge roll makes you briefly invincible. Use it to escape when surrounded.",
			"Normal waves are survival-based. Keep kiting and staying alive until the timer expires!",
			"When the countdown timer hits 0:00, a holy blast will cleanse the arena of all normal enemies.",
			"Enemy spawn rates intensify in the final 10 seconds of a wave. Conserve your active abilities for the end!"
		]
		tips_label.text = tips[randi() % tips.size()]
		
	# Show panel and start pause mode animations
	briefing.visible = true
	briefing.modulate.a = 0.0
	briefing.scale = Vector2(0.85, 0.85)
	
	var tween = create_tween()
	tween.parallel().tween_property(briefing, "modulate:a", 1.0, 0.25)
	tween.parallel().tween_property(briefing, "scale", Vector2(1.0, 1.0), 0.25)
	
	get_tree().paused = true

func update_timer_label(time_left: float) -> void:
	var label = get_node_or_null("HUD/TimerLabel")
	if label:
		if time_left < 0:
			label.text = ""
		else:
			var mins = int(time_left) / 60
			var secs = int(time_left) % 60
			label.text = "%02d:%02d" % [mins, secs]

var active_items_container: HBoxContainer

func _create_active_items_bar() -> void:
	var hud = get_node_or_null("HUD")
	if not hud:
		return
		
	active_items_container = HBoxContainer.new()
	active_items_container.name = "ActiveItemsBar"
	active_items_container.layout_mode = 1
	
	active_items_container.anchors_preset = 2
	active_items_container.anchor_top = 1.0
	active_items_container.anchor_bottom = 1.0
	active_items_container.anchor_left = 0.0
	active_items_container.anchor_right = 0.0
	active_items_container.offset_left = 20.0
	active_items_container.offset_top = -120.0
	active_items_container.offset_right = 360.0
	active_items_container.offset_bottom = -70.0
	active_items_container.add_theme_constant_override("separation", 15)
	
	hud.add_child(active_items_container)

func update_active_items(charges: Dictionary, double_shot: bool, vampire_kiss: bool) -> void:
	if not active_items_container:
		_create_active_items_bar()
	if not active_items_container:
		return
		
	# Clear existing children
	for child in active_items_container.get_children():
		child.queue_free()
		
	var items_config = {
		"dash": {
			"name": "Blood Rush",
			"key": "1",
			"icon": "res://assets/sprites/ui/powerup_icons/blood_rush.png",
			"color": Color(0.2, 0.8, 0.8)
		},
		"fury": {
			"name": "Fury",
			"key": "2",
			"icon": "res://assets/sprites/ui/powerup_icons/fury.png",
			"color": Color(0.8, 0.2, 0.2)
		},
		"nova": {
			"name": "Holy Nova",
			"key": "3",
			"icon": "res://assets/sprites/ui/powerup_icons/holy_nova.png",
			"color": Color(1.0, 0.9, 0.4)
		},
		"time_slow": {
			"name": "Time Slow",
			"key": "4",
			"icon": "res://assets/sprites/ui/powerup_icons/time_slow.png",
			"color": Color(0.5, 0.5, 1.0)
		},
		"rage": {
			"name": "Rage",
			"key": "5",
			"icon": "res://assets/sprites/ui/powerup_icons/blood_moon_rage.png",
			"color": Color(1.0, 0.1, 0.1)
		}
	}
	
	# Add charges
	for item_id in charges:
		var count = charges[item_id]
		if count <= 0:
			continue
			
		var config = items_config.get(item_id, {})
		if config.is_empty():
			continue
			
		var slot = Button.new()
		slot.custom_minimum_size = Vector2(52, 52)
		slot.focus_mode = Control.FOCUS_NONE
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.08, 0.08, 0.75)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = config["color"]
		style.set_corner_radius_all(6)
		
		var style_pressed = style.duplicate()
		style_pressed.bg_color = config["color"].lerp(Color.BLACK, 0.5)
		
		slot.add_theme_stylebox_override("normal", style)
		slot.add_theme_stylebox_override("hover", style)
		slot.add_theme_stylebox_override("pressed", style_pressed)
		
		slot.pressed.connect(func():
			if GameManager.player and GameManager.player.has_method("use_active_charge"):
				GameManager.player.use_active_charge(item_id)
		)
		
		var vbox = VBoxContainer.new()
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 2)
		slot.add_child(vbox)
		
		var tex_rect = TextureRect.new()
		var img = load(config["icon"])
		if img:
			tex_rect.texture = img
		tex_rect.custom_minimum_size = Vector2(24, 24)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		vbox.add_child(tex_rect)
		
		var count_label = Label.new()
		count_label.text = "[%s] x%d" % [config["key"], count]
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_label.add_theme_font_size_override("font_size", 9)
		count_label.add_theme_color_override("font_outline_color", Color.BLACK)
		count_label.add_theme_constant_override("outline_size", 2)
		vbox.add_child(count_label)
		
		active_items_container.add_child(slot)
		
	# Add wave passives
	if double_shot:
		_add_passive_slot("Double Shot", "res://assets/sprites/ui/powerup_icons/double_shot.png", Color(0.9, 0.5, 0.9))
	if vampire_kiss:
		_add_passive_slot("Vampire Kiss", "res://assets/sprites/ui/powerup_icons/vampires_kiss.png", Color(1.0, 0.3, 0.3))

func _add_passive_slot(passive_name: String, icon_path: String, border_color: Color) -> void:
	var slot = PanelContainer.new()
	slot.custom_minimum_size = Vector2(52, 52)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.08, 0.75)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = border_color
	style.set_corner_radius_all(6)
	slot.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	slot.add_child(vbox)
	
	var tex_rect = TextureRect.new()
	var img = load(icon_path)
	if img:
		tex_rect.texture = img
	tex_rect.custom_minimum_size = Vector2(24, 24)
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vbox.add_child(tex_rect)
	
	var label = Label.new()
	label.text = "Wave"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	vbox.add_child(label)
	
	active_items_container.add_child(slot)

