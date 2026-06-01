extends CharacterBody2D

enum EnemyType { WEREWOLF, VAMPIRE, FRANKENSTEIN, GHOST, LICH, WRAITH, PLAGUE_DOCTOR, BLOOD_GOLEM, CRIMSON_HARPY, LICH_PRIEST, BONE_ARCHER, GRAVEYARD_BRUTE, NIGHTMARE_STALKER, BLOOD_MOON_CULTIST, ABYSSAL_HORROR, FLESH_WEAVER, THE_FIRST_ONE, THE_STITCHER, THE_BUTCHER_BOY }

# Preloaded scenes and resources to prevent disk read stutters during gameplay
const BLOOD_SPLATTER_SCENE = preload("res://scenes/BloodSplatter.tscn")
const DAMAGE_NUMBER_SCENE = preload("res://scenes/DamageNumber.tscn")
const BLOOD_DECAL_SCENE = preload("res://scenes/BloodDecal.tscn")
const BAT_TEXTURE = preload("res://assets/sprites/vampire/bat.png")

const VAMPIRES_KISS_DATA = preload("res://resources/powerups/VampiresKissData.tres")
const BLOOD_RUSH_DATA = preload("res://resources/powerups/BloodRushData.tres")
const IRON_SKIN_DATA = preload("res://resources/powerups/IronSkinData.tres")
const FURY_DATA = preload("res://resources/powerups/FuryData.tres")
const HOLY_NOVA_DATA = preload("res://resources/powerups/HolyNovaData.tres")
const TIME_SLOW_DATA = preload("res://resources/powerups/TimeSlowData.tres")
const DOUBLE_SHOT_DATA = preload("res://resources/powerups/DoubleShotData.tres")
const BLOOD_MOON_RAGE_DATA = preload("res://resources/powerups/BloodMoonRageData.tres")
const GHOST_FORM_DATA = preload("res://resources/powerups/GhostFormData.tres")

# Throttling and caching variables for physics process optimization
var path_update_timer: float = 0.0
var path_update_interval: float = 0.25 # Update path finding 4 times a second

var cached_separation: Vector2 = Vector2.ZERO
var separation_update_frames: int = 6 # Update separation vector 10 times a second
var separation_frame_counter: int = 0

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

var status_effects: Dictionary = {} # { "bleed": { "damage": 2, "time": 3.0, "timer": 0.0 } }

var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_decay: float = 12.0
var separation_force: float = 1200.0

@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
@onready var separation_area: Area2D = get_node_or_null("SeparationArea")

var health_bar: ProgressBar
var nav_agent: NavigationAgent2D

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
        EnemyType.CRIMSON_HARPY:
            speed = 220.0
        EnemyType.LICH_PRIEST:
            speed = 120.0
        EnemyType.BONE_ARCHER:
            speed = 130.0
        EnemyType.GRAVEYARD_BRUTE:
            speed = 110.0
        EnemyType.NIGHTMARE_STALKER:
            speed = 200.0
        EnemyType.BLOOD_MOON_CULTIST:
            speed = 150.0
        EnemyType.ABYSSAL_HORROR:
            speed = 250.0
        EnemyType.FLESH_WEAVER:
            speed = 90.0
        EnemyType.THE_FIRST_ONE:
            speed = 160.0
        EnemyType.THE_STITCHER:
            speed = 260.0
            max_health = 35
            damage = 12
        EnemyType.THE_BUTCHER_BOY:
            speed = 95.0
            max_health = 60
            damage = 15
    current_health = max_health
    player = GameManager.player
    _configure_visuals()
    _create_health_bar()

    # Stagger pathfinding and separation update frames across enemies
    path_update_timer = randf_range(0.0, path_update_interval)
    separation_frame_counter = randi() % separation_update_frames

    # Initialize dynamic NavigationAgent2D for obstacle avoidance pathfinding
    nav_agent = NavigationAgent2D.new()
    add_child(nav_agent)
    nav_agent.avoidance_enabled = false
    nav_agent.target_desired_distance = 15.0
    nav_agent.path_max_distance = 50.0

    # Add a separation area if it doesn't exist
    if not has_node("SeparationArea"):
        var area = Area2D.new()
        area.name = "SeparationArea"
        var collision = CollisionShape2D.new()
        var circle = CircleShape2D.new()
        circle.radius = 25.0
        collision.shape = circle
        area.add_child(collision)
        add_child(area)
        separation_area = area

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

    # Apply and decay knockback
    if knockback_velocity.length() > 5.0:
        velocity = knockback_velocity
        knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_decay * delta)
        move_and_slide()
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

    # Throttled Pathfinding target updates (4 times a second instead of 60)
    path_update_timer += delta
    if path_update_timer >= path_update_interval:
        path_update_timer = 0.0
        if is_instance_valid(nav_agent):
            nav_agent.target_position = player.global_position

    var dir = (player.global_position - global_position).normalized()

    # Use NavigationAgent2D pathfinding if available to bypass walls/obstacles
    if is_instance_valid(nav_agent):
        var next_pos = nav_agent.get_next_path_position()
        if next_pos != global_position:
            dir = (next_pos - global_position).normalized()

    # Throttled separation update (every 6 frames instead of every frame)
    separation_frame_counter += 1
    if separation_frame_counter >= separation_update_frames:
        separation_frame_counter = 0
        cached_separation = _get_separation_vector()

    if not is_charging:
        velocity = (dir * speed) + (cached_separation * separation_force * delta)
        # Flip visuals to face movement direction
        var visuals = $Visuals
        if visuals and dir.x != 0:
            visuals.scale.x = 1.0 if dir.x >= 0 else -1.0
        move_and_slide()

    if (type == EnemyType.VAMPIRE or type == EnemyType.THE_STITCHER) and player and not is_bat_form:
        if Time.get_ticks_msec() / 1000.0 - last_ranged_attack_time >= ranged_attack_cooldown:
            _perform_ranged_attack()
            last_ranged_attack_time = Time.get_ticks_msec() / 1000.0
    elif (type == EnemyType.FRANKENSTEIN or type == EnemyType.THE_BUTCHER_BOY) and player and not is_charging:
        if Time.get_ticks_msec() / 1000.0 - last_charge_time >= charge_cooldown:
            _perform_charge_attack(dir)
            last_charge_time = Time.get_ticks_msec() / 1000.0
    elif is_charging:
        move_and_slide()

    _update_animation()
    _process_status_effects(delta)

func _process_status_effects(delta: float) -> void:
    var to_remove = []
    for effect_name in status_effects:
        var effect = status_effects[effect_name]
        effect.timer += delta
        
        if effect_name == "bleed":
            # Apply damage once per second
            if int(effect.timer) > int(effect.timer - delta):
                take_damage(effect.damage)
        
        if effect.timer >= effect.time:
            to_remove.append(effect_name)
            
    for effect_name in to_remove:
        status_effects.erase(effect_name)

func apply_status_effect(effect_name: String, amount: int, duration: float) -> void:
    status_effects[effect_name] = {
        "damage": amount,
        "time": duration,
        "timer": 0.0
    }

func _update_animation() -> void:
    if not animation_player:
        return
    var anim_name = "idle"
    if velocity.length() > 0:
        anim_name = "run"

    if animation_player.current_animation != anim_name:
        animation_player.play(anim_name)

func _get_separation_vector() -> Vector2:
    var separation = Vector2.ZERO
    if not is_instance_valid(separation_area):
        return separation
        
    var neighbors = separation_area.get_overlapping_bodies()
    for body in neighbors:
        if body == self:
            continue
        if body.is_in_group("enemy") or body.is_in_group("player"):
            var diff = global_position - body.global_position
            if diff.length() > 0:
                separation += diff.normalized() / diff.length()
    return separation.normalized()

func apply_knockback(source_pos: Vector2, strength: float) -> void:
    var dir = (global_position - source_pos).normalized()
    knockback_velocity = dir * strength

func take_damage(amount: int) -> void:
    if is_bat_form:
        return
    current_health -= amount
    AudioManager.play_sfx("hit")
    _flash()
    
    # Apply small knockback on hit
    if player:
        apply_knockback(player.global_position, 400.0)
    
    # Spawn blood splatter on hit (using preloaded scene)
    if BLOOD_SPLATTER_SCENE:
        var splatter = BLOOD_SPLATTER_SCENE.instantiate()
        get_parent().add_child(splatter)
        splatter.global_position = global_position
        splatter.rotation = randf_range(0, 2 * PI)
        splatter.emitting = true
        
    # Camera shake on hit
    if GameManager.player and GameManager.player.has_method("shake_camera"):
        GameManager.player.shake_camera(3.0, 0.1)

    if (type == EnemyType.VAMPIRE or type == EnemyType.THE_STITCHER) and current_health < max_health * 0.35 and not has_escaped:
        _enter_bat_form()
        return

    # Update and show floating health bar
    if health_bar:
        health_bar.visible = true
        health_bar.value = current_health
 
    # Spawn floating damage number (using preloaded scene)
    if DAMAGE_NUMBER_SCENE:
        var dmg_num = DAMAGE_NUMBER_SCENE.instantiate()
        get_parent().add_child(dmg_num)
        dmg_num.global_position = global_position
        # Random crit (20% chance)
        var is_crit = randf() < 0.20
        var final_dmg = int(amount * 1.5) if is_crit else amount
        dmg_num.setup(final_dmg, is_crit)

    # Spawn blood spray particle effect (using preloaded scene)
    if BLOOD_SPLATTER_SCENE:
        var blood = BLOOD_SPLATTER_SCENE.instantiate()
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
        await get_tree().create_timer(0.12).timeout
        visuals.material.set_shader_parameter("active", false)

func _die() -> void:
    AudioManager.play_sfx("die")
    # Bigger camera shake on death
    if GameManager.player and GameManager.player.has_method("shake_camera"):
        GameManager.player.shake_camera(6.0, 0.2)
        
    # Extra blood splatter on death (using preloaded scene)
    if BLOOD_SPLATTER_SCENE:
        for i in range(2):
            var splatter = BLOOD_SPLATTER_SCENE.instantiate()
            get_parent().add_child(splatter)
            splatter.global_position = global_position
            splatter.rotation = randf_range(0, 2 * PI)
            splatter.scale = Vector2(1.5, 1.5)
            splatter.emitting = true

    # Spawn floor blood puddle decal (using preloaded scene)
    if BLOOD_DECAL_SCENE:
        var decal = BLOOD_DECAL_SCENE.instantiate()
        get_parent().add_child(decal)
        decal.global_position = global_position

    # Chance to drop a power-up (25% chance)
    if randf() < 0.25:
        var rolls = randf()
        var res: Resource = null

        # New weighted drop table for all 10 power-ups
        if rolls < 0.30:
            res = VAMPIRES_KISS_DATA # 30% Health (Common)
        elif rolls < 0.45:
            res = BLOOD_RUSH_DATA # 15% Speed
        elif rolls < 0.60:
            res = IRON_SKIN_DATA # 15% Shield
        elif rolls < 0.75:
            res = FURY_DATA # 15% Damage
        elif rolls < 0.82:
            res = HOLY_NOVA_DATA # 7% Holy Nova
        elif rolls < 0.88:
            res = TIME_SLOW_DATA # 6% Time Slow
        elif rolls < 0.93:
            res = DOUBLE_SHOT_DATA # 5% Double Shot
        elif rolls < 0.97:
            res = GHOST_FORM_DATA # 4% Ghost Form
        else:
            res = BLOOD_MOON_RAGE_DATA # 3% Rage (Very Rare)

        if res:
            var drop_scene = preload("res://scenes/PowerUpDrop.tscn")
            var drop_node = drop_scene.instantiate()
            get_parent().add_child(drop_node)
            drop_node.global_position = global_position
            if drop_node.has_method("setup"):
                drop_node.setup(res)

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
    if sprite and sprite.texture:
        human_texture = sprite.texture
        sprite.texture = BAT_TEXTURE
        sprite.self_modulate = Color(0.65, 0.25, 0.85, 0.85)

        # Squash animation transition
        var tween = create_tween()
        sprite.scale = Vector2(0.05, 0.05)
        tween.tween_property(sprite, "scale", Vector2(0.15, 0.15), 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
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
        tween.tween_property(sprite, "scale", Vector2(0.55, 0.55), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
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