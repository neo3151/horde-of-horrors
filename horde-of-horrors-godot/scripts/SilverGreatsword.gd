extends Node2D

@export var damage: int = 45
@export var swing_speed: float = 1.0
@export var knockback_force: float = 400.0

@onready var animation_player = $AnimationPlayer
@onready var hit_area = $Visuals/HitArea

var last_attack_time: float = 0.0

func _ready():
	if hit_area:
		hit_area.body_entered.connect(_on_hit_area_body_entered)
		hit_area.monitoring = false

func attack():
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_attack_time < swing_speed:
		return
		
	last_attack_time = current_time
	animation_player.play("swing")
	AudioManager.play_sfx("sword_swing")

func _on_hit_area_body_entered(body):
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		
		if body.has_method("apply_knockback"):
			var dir = (body.global_position - global_position).normalized()
			body.apply_knockback(global_position, knockback_force)
		
		# Lore: bonus damage to Werewolves
		if body.get("type") == 0: # Assuming WEREWOLF is 0
			body.take_damage(int(damage * 0.5))

func enable_hitbox():
	hit_area.monitoring = true

func disable_hitbox():
	hit_area.monitoring = false
