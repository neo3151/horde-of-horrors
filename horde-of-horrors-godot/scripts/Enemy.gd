extends CharacterBody2D

enum EnemyType { WEREWOLF, VAMPIRE, FRANKENSTEIN, GHOST }

@export var type: EnemyType = EnemyType.WEREWOLF
@export var speed: float = 180.0
@export var max_health: int = 28
@export var damage: int = 9
@export var points: int = 12

var current_health: int
var player: Node2D
var ranged_attack_cooldown: float = 2.0 # Cooldown for ranged attack (Vampire)
var is_bat_form: bool = false
var has_escaped: bool = false
var bat_speed_multiplier: float = 2.2
var escape_target: Vector2 = Vector2.ZERO
var human_texture: Texture2D
var last_ranged_attack_time: float = 0.0
var charge_cooldown: float = 3.0 # Cooldown for charge attack (Frankenstein)
var last_charge_time: float = 0.0
var is_charging: bool = false
var charge_speed_multiplier: float = 2.5 # Speed multiplier during charge

@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")

var health_bar: ProgressBar

func _ready() -> void:
    match type:
        EnemyType.FRANKENSTEIN:
            speed = 100.0
        EnemyType.WEREWOLF:
            speed = 175.0
        EnemyType.VAMPIRE:
            speed = 240.0
        EnemyType.GHOST:
            speed = 140.0
    current_health = max_health
    player = GameManager.player
    _configure_visuals()
    _create_health_bar()

func _create_health_bar() -> void:
    health_bar = ProgressBar.new()
    add_child(health_bar)
    health_bar.show_percentage = false
    health_bar.max_value = max_health
    health_bar.value = current_health
    
    # Position above the enemy's head
    health_bar.position = Vector2(-22, -38)
    health_bar.size = Vector2(44, 5)
    
    # Style styling
    var fill_style = StyleBoxFlat.new()
    fill_style.bg_color = Color(0.85, 0.15, 0.15) # Rich blood red
    health_bar.add_theme_stylebox_override("fill", fill_style)
    
    var bg_style = StyleBoxFlat.new()
    bg_style.bg_color = Color(0.08, 0.08, 0.08, 0.6) # Dark transparent
    health_bar.add_theme_stylebox_override("background", bg_style)
    
    # Hide health bar initially until they take damage
    health_bar.visible = false

func _configure_visuals() -> void:
    var body = $Visuals/Body
    var features = $Visuals/Features
    var sprite = $Visuals/Sprite2D
    
    if not body:
        return
        
    # If a custom sprite is assigned in the inspector, hide the blocks
    if sprite and sprite.texture:
        body.visible = false
        features.visible = false
        return
        
    match type:
        EnemyType.WEREWOLF:
            body.color = Color(0.4, 0.3, 0.2) # Brown
            body.polygon = PackedVector2Array([Vector2(-10, -10), Vector2(10, -10), Vector2(14, 14), Vector2(-14, 14)]) # Bulky
            features.polygon = PackedVector2Array([Vector2(-8, -15), Vector2(-4, -10), Vector2(4, -10), Vector2(8, -15)]) # Ears
            features.color = Color(0.3, 0.2, 0.1)
        EnemyType.VAMPIRE:
            body.color = Color(0.1, 0.1, 0.1) # Black suit
            body.polygon = PackedVector2Array([Vector2(-8, -12), Vector2(8, -12), Vector2(10, 12), Vector2(-10, 12)]) # Slim
            features.polygon = PackedVector2Array([Vector2(-15, -10), Vector2(0, 0), Vector2(15, -10), Vector2(0, 15)]) # Cape
            features.color = Color(0.6, 0.0, 0.0)
        EnemyType.FRANKENSTEIN:
            body.color = Color(0.3, 0.7, 0.4) # Green skin
            body.polygon = PackedVector2Array([Vector2(-12, -15), Vector2(12, -15), Vector2(12, 15), Vector2(-12, 15)]) # Blocky
            features.polygon = PackedVector2Array([Vector2(-15, -5), Vector2(-12, -5), Vector2(-12, 5), Vector2(-15, 5), Vector2(15, 5), Vector2(12, 5), Vector2(12, -5), Vector2(15, -5)]) # Bolts
            features.color = Color(0.5, 0.5, 0.5)
        EnemyType.GHOST:
            body.color = Color(0.6, 0.8, 0.9, 0.7) # Translucent blue/white
            body.polygon = PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(10, 10), Vector2(-10, 10)]) # Ghostly shape
            features.polygon = PackedVector2Array([Vector2(-5, -12), Vector2(0, -15), Vector2(5, -12)]) # Ethereal wisp
            features.color = Color(0.7, 0.9, 1.0, 0.7)

func _physics_process(delta: float) -> void:
    if not player or GameManager.is_game_over:
        return

    if is_bat_form:
        var dir = (escape_target - global_position).normalized()
        velocity = dir * speed * bat_speed_multiplier
        var visuals = $Visuals
        if visuals and dir.x != 0:
            visuals.scale.x = 1.0 if dir.x >= 0 else -1.0
        move_and_slide()
        
        if global_position.distance_to(escape_target) < 15.0:
            _exit_bat_form()
        return

    var dir = (player.global_position - global_position).normalized()
    if not is_charging:
        velocity = dir * speed
        # Flip visuals to face movement direction
        var visuals = $Visuals
        if visuals and dir.x != 0:
            visuals.scale.x = 1.0 if dir.x >= 0 else -1.0
        move_and_slide()

    if type == EnemyType.VAMPIRE and player and not is_bat_form:
        if Time.get_ticks_msec() / 1000.0 - last_ranged_attack_time >= ranged_attack_cooldown:
            _perform_ranged_attack()
            last_ranged_attack_time = Time.get_ticks_msec() / 1000.0
    elif type == EnemyType.FRANKENSTEIN and player and not is_charging:
        if Time.get_ticks_msec() / 1000.0 - last_charge_time >= charge_cooldown:
            _perform_charge_attack(dir)
            last_charge_time = Time.get_ticks_msec() / 1000.0
    elif is_charging:
        move_and_slide()

    _update_animation()

func _update_animation() -> void:
    if not animation_player:
        return
    var anim_name = "idle"
    if velocity.length() > 0:
        anim_name = "run"

    if animation_player.current_animation != anim_name:
        animation_player.play(anim_name)

func take_damage(amount: int) -> void:
    if is_bat_form:
        return
    current_health -= amount
    _flash()
    
    if type == EnemyType.VAMPIRE and current_health < max_health * 0.35 and not has_escaped:
        _enter_bat_form()
        return
    
    # Update and show floating health bar
    if health_bar:
        health_bar.visible = true
        health_bar.value = current_health

    # Spawn floating damage number
    var dmg_scene = load("res://scenes/DamageNumber.tscn")
    if dmg_scene:
        var dmg_num = dmg_scene.instantiate()
        get_parent().add_child(dmg_num)
        dmg_num.global_position = global_position
        # Random crit (20% chance)
        var is_crit = randf() < 0.20
        var final_dmg = int(amount * 1.5) if is_crit else amount
        dmg_num.setup(final_dmg, is_crit)

    # Spawn blood spray particle effect
    var blood_scene = load("res://scenes/BloodSplatter.tscn")
    if blood_scene:
        var blood = blood_scene.instantiate()
        get_parent().add_child(blood)
        blood.global_position = global_position
        # Spray particles away from the player
        if player:
            var dir = (global_position - player.global_position).normalized()
            blood.rotation = dir.angle()

    if current_health <= 0:
        _die()

func _flash() -> void:
    var visuals = $Visuals
    if visuals and visuals.material:
        visuals.material.set_shader_parameter("active", true)
        await get_tree().create_timer(0.08).timeout
        visuals.material.set_shader_parameter("active", false)

func _die() -> void:
    # Spawn floor blood puddle decal
    var decal_scene = load("res://scenes/BloodDecal.tscn")
    if decal_scene:
        var decal = decal_scene.instantiate()
        get_parent().add_child(decal)
        decal.global_position = global_position
        
    # Chance to drop a power-up
    if randf() < 0.2: # 20% chance to drop a power-up
        var powerup_scene = preload("res://scenes/PowerUpHealth.tscn")
        var powerup = powerup_scene.instantiate()
        get_parent().add_child(powerup)
        powerup.global_position = global_position

    GameManager.add_score(points)
    GameManager.add_kill()
    GameManager.add_currency(points)
    GameManager.emit_signal("enemy_despawned", self)
    queue_free()

func _perform_ranged_attack() -> void:
    var projectile_scene = preload("res://scenes/Projectile.tscn")
    var projectile = projectile_scene.instantiate()
    get_parent().add_child(projectile)
    projectile.global_position = global_position # Spawn at enemy position
    var dir = (player.global_position - global_position).normalized()
    projectile.initialize(dir, damage)

func _perform_charge_attack(charge_dir: Vector2) -> void:
    is_charging = true
    velocity = charge_dir * speed * charge_speed_multiplier
    # Stop charging after a short duration
    var charge_duration = 0.5 # seconds
    get_tree().create_timer(charge_duration).timeout.connect(func():
        is_charging = false
        velocity = Vector2.ZERO # Stop movement after charge
    )

func _on_body_entered(body: Node) -> void:
    if is_bat_form:
        return
    if body.is_in_group("player"):
        var pc = body as CharacterBody2D
        if pc.has_method("take_damage"):
            pc.take_damage(damage)

func _enter_bat_form() -> void:
    is_bat_form = true
    has_escaped = true
    
    if health_bar:
        health_bar.visible = false
    
    # Find opposite quadrant from player
    var target_x = -320 if player.global_position.x > 0 else 320
    var target_y = -220 if player.global_position.y > 0 else 220
    target_x += randf_range(-50, 50)
    target_y += randf_range(-50, 50)
    escape_target = Vector2(target_x, target_y)
    
    _spawn_puff_particles(global_position, Color(0.18, 0.05, 0.28, 0.8))
    
    var sprite = $Visuals/Sprite2D
    var bat_texture = load("res://assets/sprites/vampire/bat.png")
    if sprite and sprite.texture:
        human_texture = sprite.texture
        sprite.texture = bat_texture
        sprite.self_modulate = Color(0.65, 0.25, 0.85, 0.85)
        
        # Squash animation transition
        var tween = create_tween()
        sprite.scale = Vector2(0.1, 0.1)
        tween.tween_property(sprite, "scale", Vector2(0.55, 0.55), 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
    else:
        var body = $Visuals/Body
        if body:
            body.color = Color(0.3, 0.0, 0.5, 0.7)
            
    print("Enemy Dracula entered Bat Escape to: ", escape_target)

func _exit_bat_form() -> void:
    is_bat_form = false
    
    _spawn_puff_particles(global_position, Color(0.18, 0.05, 0.28, 0.8))
    
    var sprite = $Visuals/Sprite2D
    if sprite and sprite.texture:
        sprite.texture = human_texture
        sprite.self_modulate = Color.WHITE
        
        var tween = create_tween()
        sprite.scale = Vector2(0.1, 0.1)
        tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    else:
        var body = $Visuals/Body
        if body:
            body.color = Color(0.1, 0.1, 0.1)
            
    print("Enemy Dracula transformed back to humanoid form.")

func _spawn_puff_particles(pos: Vector2, color: Color) -> void:
    var particles = CPUParticles2D.new()
    particles.emitting = false
    particles.amount = 24
    particles.one_shot = true
    particles.explosiveness = 0.85
    particles.spread = 180.0
    particles.gravity = Vector2.ZERO
    particles.initial_velocity_min = 55.0
    particles.initial_velocity_max = 110.0
    particles.scale_amount_min = 3.0
    particles.scale_amount_max = 6.0
    particles.color = color
    get_parent().add_child(particles)
    particles.global_position = pos
    particles.emitting = true
    get_tree().create_timer(1.0).timeout.connect(particles.queue_free)