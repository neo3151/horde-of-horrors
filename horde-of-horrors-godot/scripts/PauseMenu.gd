extends Control

@onready var main_vbox = $CenterContainer/MainVBox
@onready var options_vbox = $CenterContainer/OptionsVBox
@onready var resume_btn = $CenterContainer/MainVBox/ResumeButton
@onready var options_btn = $CenterContainer/MainVBox/OptionsButton
@onready var restart_btn = $CenterContainer/MainVBox/RestartButton
@onready var exit_btn = $CenterContainer/MainVBox/ExitButton

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
    emit_signal("visibility_changed_custom", false)

func show_main_menu() -> void:
    main_vbox.visible = true
    options_vbox.visible = false

func show_options_menu() -> void:
    main_vbox.visible = false
    options_vbox.visible = true

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
