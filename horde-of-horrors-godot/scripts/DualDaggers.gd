extends Node2D

@export var damage: int = 14
@export var bleed_damage: int = 2
@export var bleed_duration: float = 3.0
@export var attack_range: float = 60.0

@onready var animation_player = $AnimationPlayer
@onready var hit_area = $HitArea

var combo_step: int = 0
var last_attack_time: float = 0.0
var combo_reset_time: float = 0.6

func _ready():
	# HitArea should be an Area2D with a CollisionShape2D
	if hit_area:
		hit_area.body_entered.connect(_on_hit_area_body_entered)
		# Disable hit area by default
		hit_area.monitoring = false

func attack():
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_attack_time > combo_reset_time:
		combo_step = 0
	
	combo_step = (combo_step % 3) + 1
	last_attack_time = current_time
	
	match combo_step:
		1:
			animation_player.play("attack_1")
		2:
			animation_player.play("attack_2")
		3:
			animation_player.play("attack_3")

func _on_hit_area_body_entered(body):
	if body.is_in_group("enemy"):
		var actual_damage = damage
		if combo_step == 3:
			actual_damage = int(damage * 1.5) # Finisher deal more damage
		
		if body.has_method("take_damage"):
			body.take_damage(actual_damage)
		
		# Apply bleed on combo finisher
		if combo_step == 3 and body.has_method("apply_status_effect"):
			body.apply_status_effect("bleed", bleed_damage, bleed_duration)
		
		# Lore tie: gain speed if enemy is vampire (assuming EnemyType.VAMPIRE is 1)
		if body.get("type") == 1 and GameManager.selected_character == "Serena":
			if GameManager.player.has_method("apply_speed_boost"):
				GameManager.player.apply_speed_boost(1.2, 3.0)

# Methods called by AnimationPlayer to enable/disable hit detection
func enable_hitbox():
	if hit_area:
		hit_area.monitoring = true

func disable_hitbox():
	if hit_area:
		hit_area.monitoring = false
