extends "res://scripts/Enemy.gd"

@export var force_field_duration: float = 5.0
@export var force_field_cooldown: float = 10.0
@export var summon_interval: float = 2.0

var has_force_field: bool = false
var last_shield_time: float = -5.0 # Allow initial shield fairly soon
var last_summon_time: float = 0.0

@onready var shield_visual: Node2D = get_node_or_null("Visuals/Shield")

func _ready() -> void:
	type = EnemyType.LICH
	max_health = 450
	speed = 100.0
	damage = 18
	points = 250 # Big reward
	
	super._ready()
	
	# Start shielded after a short delay
	get_tree().create_timer(2.0).timeout.connect(activate_force_field)

func _physics_process(delta: float) -> void:
	if not player or GameManager.is_game_over:
		return
		
	super._physics_process(delta)
	
	# Logic for shield rotation/cooldown
	var current_time = Time.get_ticks_msec() / 1000.0
	if not has_force_field and current_time - last_shield_time >= force_field_cooldown:
		activate_force_field()
		
	# Logic for summoning while shielded
	if has_force_field and current_time - last_summon_time >= summon_interval:
		_summon_ghost_guard()
		last_summon_time = current_time

func activate_force_field() -> void:
	if is_bat_form: return # Don't shield while escaping
	
	has_force_field = true
	last_shield_time = Time.get_ticks_msec() / 1000.0
	
	# Visual Feedback
	if shield_visual:
		shield_visual.visible = true
		shield_visual.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(shield_visual, "modulate:a", 0.7, 0.5)
	
	# Tint the Lich
	$Visuals.modulate = Color(0.6, 0.6, 1.2, 1.0) # Ghostly Blue tint
	_spawn_puff_particles(global_position, Color(0.2, 0.2, 0.8, 0.5))
	
	print("Lich High Priest activated Force Field!")
	
	await get_tree().create_timer(force_field_duration).timeout
	deactivate_force_field()

func deactivate_force_field() -> void:
	has_force_field = false
	if shield_visual:
		var tween = create_tween()
		tween.tween_property(shield_visual, "modulate:a", 0.0, 0.3)
		tween.finished.connect(func(): shield_visual.visible = false)
	
	$Visuals.modulate = Color.WHITE
	_spawn_puff_particles(global_position, Color(0.4, 0.4, 0.4, 0.5))
	print("Lich High Priest Force Field collapsed!")

func _summon_ghost_guard() -> void:
	var ghost_scene = load("res://scenes/EnemyGhost.tscn")
	if ghost_scene:
		var ghost = ghost_scene.instantiate()
		get_parent().add_child(ghost)
		# Spawn at a random offset near the Lich
		var offset = Vector2(randf_range(-60, 60), randf_range(-60, 60))
		ghost.global_position = global_position + offset
		_spawn_puff_particles(ghost.global_position, Color(0.7, 0.9, 1.0, 0.6))

func take_damage(amount: int) -> void:
	if has_force_field:
		amount = int(amount * 0.15) # 85% damage reduction
		# Play a shield hit effect?
		_spawn_puff_particles(global_position, Color(0.3, 0.3, 1.0, 0.3))
	
	super.take_damage(amount)
