extends Area2D

@export var damage_per_tick: int = 2
@export var slow_multiplier: float = 0.6
@export var duration: float = 4.0

var tick_timer: float = 0.0
var level: int = 1

func _ready():
	level = get_meta("level") if has_meta("level") else 1
	
	# Configure parameters based on level
	match level:
		2:
			duration = 4.0
			slow_multiplier = 0.6
			damage_per_tick = 2
		3:
			duration = 4.0
			slow_multiplier = 0.6
			damage_per_tick = 3
		4:
			duration = 6.0
			slow_multiplier = 0.3
			damage_per_tick = 3
			scale = Vector2(1.4, 1.4)
		5:
			duration = 8.0
			slow_multiplier = 0.3
			damage_per_tick = 4
			scale = Vector2(1.8, 1.8)
			modulate = Color(1.0, 0.95, 0.75, 1.0)
			body_entered.connect(_on_body_entered)
			
	get_tree().create_timer(duration).timeout.connect(func():
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.8)
		tween.finished.connect(queue_free)
	)

func _physics_process(delta):
	tick_timer += delta
	if tick_timer >= 0.5:
		tick_timer = 0.0
		_apply_effects()

func _apply_effects():
	for body in get_overlapping_bodies():
		if body.is_in_group("enemy"):
			if body.has_method("take_damage"):
				body.take_damage(damage_per_tick)
			# Lore: extra damage to vampires
			if body.get("type") == 1:
				body.take_damage(damage_per_tick * 2)
			
			# Slow logic
			if body.has_method("apply_slow"):
				body.apply_slow(slow_multiplier, 0.6)

func _on_body_entered(body: Node2D):
	if level >= 5 and body.is_in_group("enemy") and body.has_method("apply_stun"):
		body.apply_stun(1.0)

