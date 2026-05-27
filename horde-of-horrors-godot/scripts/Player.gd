extends CharacterBody2D

@export var move_speed: float = 320.0
@export var max_health: int = 100
@export var fire_rate: float = 0.28
@export var damage: int = 12

var current_health: int
var last_fire_time: float = 0.0

@onready var crossbow_pivot: Node2D = $CrossbowPivot
@onready var fire_point: Node2D = $CrossbowPivot/FirePoint
@onready var camera: Camera2D = $Camera2D
@onready var muzzle_flash: CPUParticles2D = $CrossbowPivot/FirePoint/MuzzleFlash
@onready var shoot_sound: AudioStreamPlayer2D = $ShootSound

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var move_input: Vector2 = Vector2.ZERO
var aim_position: Vector2 = Vector2.ZERO

func _ready() -> void:
    current_health = max_health
    GameManager.player = self
    _setup_visuals()
    _update_health_ui()

func _setup_visuals() -> void:
    var sprite = %Sprite2D
    var polygons = $Visuals.get_children().filter(func(node): return node is Polygon2D)
    
    # If a custom sprite is assigned, hide the fallback polygons
    if sprite and sprite.texture:
        for p in polygons:
            p.visible = false
        if has_node("CrossbowPivot/Weapon"):
            $CrossbowPivot/Weapon.visible = false

func _update_health_ui() -> void:
    var bar = get_node_or_null("../UI/HealthBar")
    var label = get_node_or_null("../UI/HealthBar/HealthLabel")
    if bar:
        bar.max_value = max_health
        bar.value = current_health
    if label:
        label.text = str(current_health) + " / " + str(max_health)

func _physics_process(delta: float) -> void:
    if GameManager.is_game_over:
        return

    # Keyboard movement input
    var keyboard_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    var input_dir = Vector2.ZERO
    
    if keyboard_input != Vector2.ZERO:
        input_dir = keyboard_input
    else:
        input_dir = move_input # Touch/Mouse drag fallback

    velocity = input_dir * move_speed
    move_and_slide()

    _update_animation()

    # Clamp to screen boundaries
    position.x = clamp(position.x, -380, 380)
    position.y = clamp(position.y, -280, 280)

    # Aiming (Aim at mouse cursor)
    if crossbow_pivot:
        var world_aim = get_global_mouse_position()
        var dir = (world_aim - crossbow_pivot.global_position).normalized()
        crossbow_pivot.rotation = dir.angle()

    # If playing on mobile, use auto-fire. On PC, use manual fire.
    if OS.has_feature("mobile"):
        _try_auto_fire()
    else:
        if Input.is_action_pressed("fire"):
            _try_manual_fire()

func _try_manual_fire() -> void:
    if Time.get_ticks_msec() / 1000.0 - last_fire_time < fire_rate:
        return

    var proj_scene = preload("res://scenes/Projectile.tscn")
    var proj = proj_scene.instantiate()
    get_tree().current_scene.add_child(proj)
    proj.global_position = fire_point.global_position
    var dir = (fire_point.global_position - crossbow_pivot.global_position).normalized()
    proj.initialize(dir, damage)

    last_fire_time = Time.get_ticks_msec() / 1000.0
    muzzle_flash.restart()
    shoot_sound.play()

func _try_auto_fire() -> void:
    if Time.get_ticks_msec() / 1000.0 - last_fire_time < fire_rate:
        return
    if not GameManager.wave_manager:
        return

    var nearest = GameManager.wave_manager.get_nearest_enemy(global_position)
    if not nearest:
        return

    var proj_scene = preload("res://scenes/Projectile.tscn")
    var proj = proj_scene.instantiate()
    get_tree().current_scene.add_child(proj)
    proj.global_position = fire_point.global_position
    
    # Point crossbow and shoot at nearest enemy
    var dir = (nearest.global_position - global_position).normalized()
    if crossbow_pivot:
        crossbow_pivot.rotation = dir.angle()
    
    var proj_dir = (fire_point.global_position - crossbow_pivot.global_position).normalized()
    proj.initialize(proj_dir, damage)

    last_fire_time = Time.get_ticks_msec() / 1000.0
    muzzle_flash.restart()

func take_damage(amount: int) -> void:
    current_health -= amount
    if current_health <= 0:
        current_health = 0
        GameManager.trigger_game_over()
        
    _update_health_ui()
    
    # Spawn floating damage number
    var dmg_scene = load("res://scenes/DamageNumber.tscn")
    if dmg_scene:
        var dmg_num = dmg_scene.instantiate()
        get_parent().add_child(dmg_num)
        dmg_num.global_position = global_position
        dmg_num.setup(amount, true) # Red critical for player taking damage

func upgrade_damage(amount: int) -> void:
    damage += amount
    print("Player damage upgraded to: ", damage)

func heal(amount: int) -> void:
    current_health = min(current_health + amount, max_health)
    _update_health_ui()
    print("Player healed by ", amount, ". Current health: ", current_health)

# Input handling for aiming and drag/touch movement
func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        aim_position = event.position

    # Handle touch dragging / mouse dragging to move
    if event is InputEventScreenDrag or (event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
        var player_screen_pos = get_global_transform_with_canvas().origin
        move_input = (event.position - player_screen_pos).normalized()
        
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            var player_screen_pos = get_global_transform_with_canvas().origin
            move_input = (event.position - player_screen_pos).normalized()
        else:
            move_input = Vector2.ZERO
            
    elif event is InputEventScreenTouch:
        if event.pressed:
            var player_screen_pos = get_global_transform_with_canvas().origin
            move_input = (event.position - player_screen_pos).normalized()
        else:
            move_input = Vector2.ZERO

func _update_animation() -> void:
    var anim_name = "idle"
    if velocity.length() > 0:
        anim_name = "run"

    if animation_player.current_animation != anim_name:
        animation_player.play(anim_name)