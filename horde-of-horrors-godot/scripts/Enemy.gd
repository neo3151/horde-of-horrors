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
var last_ranged_attack_time: float = 0.0
var charge_cooldown: float = 3.0 # Cooldown for charge attack (Frankenstein)
var last_charge_time: float = 0.0
var is_charging: bool = false
var charge_speed_multiplier: float = 2.5 # Speed multiplier during charge

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var health_bar: ProgressBar

func _ready() -> void:
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
    var sprite = %Sprite2D
    
    if not body:
        return
        
    # If a custom sprite is assigned in the inspector, hide the blocks
    if sprite.texture:
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

    var dir = (player.global_position - global_position).normalized()
    if not is_charging:
        velocity = dir * speed
        move_and_slide()

    if type == EnemyType.VAMPIRE and player:
        if Time.get_ticks_msec() / 1000.0 - last_ranged_attack_time >= ranged_attack_cooldown:
            _perform_ranged_attack()
            last_ranged_attack_time = Time.get_ticks_msec() / 1000.0
    elif type == EnemyType.FRANKENSTEIN and player and not is_charging:
        if Time.get_ticks_msec() / 1000.0 - last_charge_time >= charge_cooldown:
            _perform_charge_attack(dir)
            last_charge_time = Time.get_ticks_msec() / 1000.0
    elif is_charging:
        # Continue charging in the direction set by _perform_charge_attack
        move_and_slide()

    _update_animation()

func _update_animation() -> void:
    var anim_name = "idle"
    if velocity.length() > 0:
        anim_name = "run"

    if animation_player.current_animation != anim_name:
        animation_player.play(anim_name)

func take_damage(amount: int) -> void:
    current_health -= amount
    _flash()
    
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
    if body.is_in_group("player"):
        var pc = body as CharacterBody2D
        if pc.has_method("take_damage"):
            pc.take_damage(damage)