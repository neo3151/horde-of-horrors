extends Area2D

@export var damage_per_tick: int = 5
@export var tick_rate: float = 0.5
@export var duration: float = 5.0

@onready var particles = $CPUParticles2D

var timer: float = 0.0
var tick_timer: float = 0.0

func _ready():
	var lvl = get_meta("level") if has_meta("level") else 1
	if lvl >= 4:
		duration = 6.0
		scale = Vector2(1.5, 1.5)
		
	get_tree().create_timer(duration).timeout.connect(func():
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.5)
		tween.finished.connect(queue_free)
	)

func _physics_process(delta):
	tick_timer += delta
	if tick_timer >= tick_rate:
		tick_timer = 0
		_damage_enemies()
		_heal_player()

func _damage_enemies():
	for body in get_overlapping_bodies():
		if body.is_in_group("enemy") and body.has_method("take_damage"):
			body.take_damage(damage_per_tick)
			if body.get("type") == 1:
				body.take_damage(damage_per_tick)

func _heal_player():
	var lvl = get_meta("level") if has_meta("level") else 1
	if lvl >= 5:
		if GameManager.player and is_instance_valid(GameManager.player):
			var dist = global_position.distance_to(GameManager.player.global_position)
			var max_dist = 180.0 if lvl >= 4 else 120.0
			if dist < max_dist:
				if GameManager.player.has_method("heal"):
					GameManager.player.heal(2)
