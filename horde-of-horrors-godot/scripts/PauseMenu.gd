extends Control

const FURY_DATA = preload("res://resources/powerups/FuryData.tres")
const SPEED_DATA = preload("res://resources/powerups/BloodRushData.tres")
const SHIELD_DATA = preload("res://resources/powerups/IronSkinData.tres")
const HEAL_DATA = preload("res://resources/powerups/VampiresKissData.tres")

@onready var main_vbox = $CenterContainer/MainVBox
@onready var options_vbox = $CenterContainer/OptionsVBox
@onready var resume_btn = $CenterContainer/MainVBox/ResumeButton
@onready var options_btn = $CenterContainer/MainVBox/OptionsButton
@onready var restart_btn = $CenterContainer/MainVBox/RestartButton
@onready var exit_btn = $CenterContainer/MainVBox/ExitButton

@onready var inventory_btn = $CenterContainer/MainVBox/InventoryButton
@onready var trade_panel = $TradePanel
@onready var trade_back_btn = $TradePanel/VBox/TradeBackButton
@onready var gold_label = $TradePanel/VBox/GoldLabel
@onready var upgrades_list_label = $TradePanel/VBox/HBox/InventorySection/UpgradesList
@onready var effects_list_label = $TradePanel/VBox/HBox/InventorySection/EffectsList

@onready var buy_fury_btn = $TradePanel/VBox/HBox/MarketSection/BuyFury
@onready var buy_speed_btn = $TradePanel/VBox/HBox/MarketSection/BuySpeed
@onready var buy_shield_btn = $TradePanel/VBox/HBox/MarketSection/BuyShield
@onready var buy_heal_btn = $TradePanel/VBox/HBox/MarketSection/BuyHeal

@onready var swap_speed_to_dmg_btn = $TradePanel/VBox/HBox/MarketSection/SwapSpeedToDamage
@onready var swap_dmg_to_speed_btn = $TradePanel/VBox/HBox/MarketSection/SwapDamageToSpeed

@onready var back_btn = $CenterContainer/OptionsVBox/BackButton
@onready var minimap_toggle = $CenterContainer/OptionsVBox/MinimapToggle
@onready var master_vol = $CenterContainer/OptionsVBox/MasterVolSlider
@onready var music_vol = $CenterContainer/OptionsVBox/MusicVolSlider
@onready var sfx_vol = $CenterContainer/OptionsVBox/SfxVolSlider

# Signal to tell the MainGame to pause/unpause
signal visibility_changed_custom(is_visible)

func _ready() -> void:
    visible = false
    resume_btn.pressed.connect(_on_resume_pressed)
    options_btn.pressed.connect(_on_options_pressed)
    restart_btn.pressed.connect(_on_restart_pressed)
    exit_btn.pressed.connect(_on_exit_pressed)
    
    back_btn.pressed.connect(_on_back_pressed)
    minimap_toggle.toggled.connect(_on_minimap_toggled)
    
    master_vol.value_changed.connect(_on_master_vol_changed)
    music_vol.value_changed.connect(_on_music_vol_changed)
    sfx_vol.value_changed.connect(_on_sfx_vol_changed)

    inventory_btn.pressed.connect(_on_inventory_pressed)
    trade_back_btn.pressed.connect(_on_trade_back_pressed)
    
    buy_fury_btn.pressed.connect(func(): _buy_powerup(FURY_DATA, 25))
    buy_speed_btn.pressed.connect(func(): _buy_powerup(SPEED_DATA, 25))
    buy_shield_btn.pressed.connect(func(): _buy_powerup(SHIELD_DATA, 30))
    buy_heal_btn.pressed.connect(func(): _buy_powerup(HEAL_DATA, 15))
    
    swap_speed_to_dmg_btn.pressed.connect(_on_swap_speed_to_dmg)
    swap_dmg_to_speed_btn.pressed.connect(_on_swap_dmg_to_speed)
    
    # Set icons and expand options for shop buttons
    buy_fury_btn.icon = load("res://assets/sprites/ui/icons/rapid.png")
    buy_fury_btn.expand_icon = true
    
    buy_speed_btn.icon = load("res://assets/sprites/ui/icons/dash.png")
    buy_speed_btn.expand_icon = true
    
    buy_shield_btn.icon = load("res://assets/sprites/ui/icons/shield.png")
    buy_shield_btn.expand_icon = true
    
    buy_heal_btn.icon = load("res://assets/sprites/ui/icons/heart.png")
    buy_heal_btn.expand_icon = true
    
    swap_speed_to_dmg_btn.icon = load("res://assets/sprites/ui/icons/crossbow.png")
    swap_speed_to_dmg_btn.expand_icon = true
    
    swap_dmg_to_speed_btn.icon = load("res://assets/sprites/ui/icons/dash.png")
    swap_dmg_to_speed_btn.expand_icon = true

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_ESCAPE:
            toggle_pause()

func toggle_pause() -> void:
    if get_tree().paused:
        unpause()
    else:
        pause()

func pause() -> void:
    get_tree().paused = true
    visible = true
    show_main_menu()
    emit_signal("visibility_changed_custom", true)

func unpause() -> void:
    get_tree().paused = false
    visible = false
    trade_panel.visible = false
    emit_signal("visibility_changed_custom", false)

func show_main_menu() -> void:
    main_vbox.visible = true
    options_vbox.visible = false
    trade_panel.visible = false

func show_options_menu() -> void:
    main_vbox.visible = false
    options_vbox.visible = true
    trade_panel.visible = false

func _on_resume_pressed() -> void:
    unpause()

func _on_options_pressed() -> void:
    show_options_menu()

func _on_restart_pressed() -> void:
    get_tree().paused = false
    get_tree().reload_current_scene()

func _on_exit_pressed() -> void:
    get_tree().paused = false
    get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_back_pressed() -> void:
    show_main_menu()

func _on_minimap_toggled(button_pressed: bool) -> void:
    # Set minimap visibility via GameManager or directly if available
    var minimap = get_tree().root.get_node_or_null("MainGame/UILayer/Minimap")
    if minimap:
        if minimap.has_method("set_minimap_visible"):
            minimap.set_minimap_visible(button_pressed)
        else:
            minimap.visible = button_pressed

func _on_master_vol_changed(value: float) -> void:
    var bus_idx = AudioServer.get_bus_index("Master")
    if bus_idx >= 0:
        AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

func _on_music_vol_changed(value: float) -> void:
    var bus_idx = AudioServer.get_bus_index("Music")
    if bus_idx >= 0:
        AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

func _on_sfx_vol_changed(value: float) -> void:
    var bus_idx = AudioServer.get_bus_index("SFX")
    if bus_idx >= 0:
        AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

func show_trade_menu() -> void:
    main_vbox.visible = false
    options_vbox.visible = false
    trade_panel.visible = true
    update_trade_ui()

func update_trade_ui() -> void:
    gold_label.text = "[center][color=#ffd700][img=24x24]res://assets/sprites/ui/icons/coin.png[/img] Gold: %d[/color][/center]" % GameManager.player_currency
    
    # Update active passives count
    var u = GameManager.purchased_upgrades
    upgrades_list_label.text = "[img=20x20]res://assets/sprites/ui/icons/crossbow.png[/img] Crossbow Damage: +%d\n[img=20x20]res://assets/sprites/ui/icons/rapid.png[/img] Fire Rate Cooldown: -%d%%\n[img=20x20]res://assets/sprites/ui/icons/heart.png[/img] Max Health Bonus: +%d\n[img=20x20]res://assets/sprites/ui/icons/dash.png[/img] Speed Bonus: +%d%%\n[img=20x20]res://assets/sprites/ui/icons/pact.png[/img] Sinister Pact: %d" % [
        u["damage"] * 3,
        int((1.0 - pow(0.85, u["fire_rate"])) * 100),
        u["health"] * 25,
        int((pow(1.15, u["speed"]) - 1.0) * 100),
        u["pact"]
    ]
    
    # Update temporary status effects
    var player = GameManager.player
    if is_instance_valid(player):
        var dmg_boost = "Active (+%d)" % player.damage_boost_flat if player.damage_boost_flat > 0 else "Inactive"
        var speed_boost = "Active (x%.1f)" % player.speed_boost_multiplier if player.speed_boost_multiplier > 1.0 else "Inactive"
        var shield = "Active" if player.is_shielded else "Inactive"
        effects_list_label.text = "[img=20x20]res://assets/sprites/ui/icons/crossbow.png[/img] Damage Boost: %s\n[img=20x20]res://assets/sprites/ui/icons/dash.png[/img] Speed Boost: %s\n[img=20x20]res://assets/sprites/ui/icons/shield.png[/img] Shield: %s" % [dmg_boost, speed_boost, shield]
    else:
        effects_list_label.text = "[img=20x20]res://assets/sprites/ui/icons/crossbow.png[/img] Damage Boost: Inactive\n[img=20x20]res://assets/sprites/ui/icons/dash.png[/img] Speed Boost: Inactive\n[img=20x20]res://assets/sprites/ui/icons/shield.png[/img] Shield: Inactive"

func _on_inventory_pressed() -> void:
    show_trade_menu()

func _on_trade_back_pressed() -> void:
    show_main_menu()
    trade_panel.visible = false

func _buy_powerup(powerup: PowerUpData, cost: int) -> void:
    if not is_instance_valid(GameManager.player):
        return
    if GameManager.spend_currency(cost):
        GameManager.player.apply_powerup(powerup)
        AudioManager.play_sfx("hit") # Play click sound on success
        update_trade_ui()
    else:
        print("Not enough gold!")

func _on_swap_speed_to_dmg() -> void:
    var player = GameManager.player
    if not is_instance_valid(player):
        return
    var u = GameManager.purchased_upgrades
    if u["speed"] > 0 and GameManager.spend_currency(10):
        # Revert speed boost
        player.move_speed /= 1.15
        u["speed"] -= 1
        
        # Apply damage boost
        player.upgrade_damage(3)
        u["damage"] += 1
        
        AudioManager.play_sfx("hit")
        update_trade_ui()

func _on_swap_dmg_to_speed() -> void:
    var player = GameManager.player
    if not is_instance_valid(player):
        return
    var u = GameManager.purchased_upgrades
    if u["damage"] > 0 and GameManager.spend_currency(10):
        # Revert damage boost
        player.damage = max(1, player.damage - 3)
        u["damage"] -= 1
        
        # Apply speed boost
        player.move_speed *= 1.15
        u["speed"] += 1
        
        AudioManager.play_sfx("hit")
        update_trade_ui()
