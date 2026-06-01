extends SceneTree

func _init():
    var root = Control.new()
    root.name = "PauseMenu"
    root.process_mode = Node.PROCESS_MODE_ALWAYS
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    
    var color_rect = ColorRect.new()
    color_rect.name = "BackgroundDim"
    color_rect.color = Color(0, 0, 0, 0.7)
    color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_child(color_rect)
    color_rect.owner = root
    
    var center = CenterContainer.new()
    center.name = "CenterContainer"
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_child(center)
    center.owner = root
    
    var main_vbox = VBoxContainer.new()
    main_vbox.name = "MainVBox"
    center.add_child(main_vbox)
    main_vbox.owner = root
    
    var label = Label.new()
    label.name = "PauseLabel"
    label.text = "PAUSED"
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 32)
    main_vbox.add_child(label)
    label.owner = root
    
    var resume_btn = Button.new()
    resume_btn.name = "ResumeButton"
    resume_btn.text = "Resume Game"
    main_vbox.add_child(resume_btn)
    resume_btn.owner = root
    
    var options_btn = Button.new()
    options_btn.name = "OptionsButton"
    options_btn.text = "Options"
    main_vbox.add_child(options_btn)
    options_btn.owner = root
    
    var options_vbox = VBoxContainer.new()
    options_vbox.name = "OptionsVBox"
    options_vbox.visible = false
    center.add_child(options_vbox)
    options_vbox.owner = root
    
    var options_label = Label.new()
    options_label.name = "OptionsLabel"
    options_label.text = "OPTIONS"
    options_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    options_label.add_theme_font_size_override("font_size", 32)
    options_vbox.add_child(options_label)
    options_label.owner = root
    
    var minimap_toggle = CheckButton.new()
    minimap_toggle.name = "MinimapToggle"
    minimap_toggle.text = "Show Minimap"
    minimap_toggle.button_pressed = true
    options_vbox.add_child(minimap_toggle)
    minimap_toggle.owner = root
    
    var back_btn = Button.new()
    back_btn.name = "BackButton"
    back_btn.text = "Back"
    options_vbox.add_child(back_btn)
    back_btn.owner = root
    
    var packed_scene = PackedScene.new()
    packed_scene.pack(root)
    ResourceSaver.save(packed_scene, "res://scenes/PauseMenu.tscn")
    print("PauseMenu.tscn created successfully.")
    quit()
