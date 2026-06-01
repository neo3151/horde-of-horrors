extends Area2D

@export var damage_per_tick: int = 3
@export var slow_multiplier: float = 0.5
@export var duration: float = 4.0

var tick_timer: float = 0.0

func _ready():
	get_tree().create_timer(duration).timeout.connect(func():
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.8)
		tween.finished.connect(queue_free)
	)

func _physics_process(delta):
	tick_timer += delta
	if tick_timer >= 0.5:
		tick_timer = 0
		_apply_effects()

func _damage_enemies():
	for body in get_overlapping_bodies():
		if body.is_in_group("enemy"):
			if body.has_method("take_damage"):
				body.take_damage(damage_per_tick)
			if body.has_method("apply_slow"):
				body.apply_slow(slow_multiplier, 0.6)

func _apply_effects():
	for body in get_overlapping_bodies():
		if body.is_in_group("enemy"):
			if body.has_method("take_damage"):
				body.take_damage(damage_per_tick)
			# Lore: extra damage to vampires
			if body.get("type") == 1:
				body.take_damage(damage_per_tick * 2)
			
			# Slow logic (if enemy has it)
			if body.has_method("apply_speed_boost"):
				body.apply_speed_boost(slow_multiplier, 0.6)
