extends Node2D

@export var damage: int = 45
@export var swing_speed: float = 1.0
@export var knockback_force: float = 400.0

@onready var animation_player = $AnimationPlayer
@onready var hit_area = $Visuals/HitArea

var last_attack_time: float = 0.0
var level: int = 1

func _ready():
	if hit_area:
		hit_area.body_entered.connect(_on_hit_area_body_entered)
		hit_area.monitoring = false

func set_level(lvl: int):
	level = lvl
	if level >= 3:
		swing_speed = 0.5
	else:
		swing_speed = 1.0
		
	if level >= 4:
		knockback_force = 800.0
	else:
		knockback_force = 400.0

func attack():
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_attack_time < swing_speed:
		return
		
	last_attack_time = current_time
	
	if level >= 5:
		_blade_storm()
	else:
		if level >= 2:
			$Visuals.scale = Vector2(1.4, 1.4)
		else:
			$Visuals.scale = Vector2(1.0, 1.0)
		animation_player.play("swing")
		AudioManager.play_sfx("sword_swing")

func _blade_storm():
	AudioManager.play_sfx("sword_swing")
	$Visuals.scale = Vector2(1.6, 1.6)
	$Visuals.rotation = 0.0
	enable_hitbox()
	
	var tween = create_tween()
	tween.tween_property($Visuals, "rotation", 2.0 * PI, 0.4)
	tween.finished.connect(func():
		disable_hitbox()
		$Visuals.rotation = 0.0
	)

func _on_hit_area_body_entered(body):
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		
		if body.has_method("apply_knockback"):
			body.apply_knockback(global_position, knockback_force)
		
		# Lore: bonus damage to Werewolves
		if body.get("type") == 0: # Assuming WEREWOLF is 0
			body.take_damage(int(damage * 0.5))

func enable_hitbox():
	hit_area.monitoring = true

func disable_hitbox():
	hit_area.monitoring = false
