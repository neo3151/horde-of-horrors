extends Area2D

@export var damage_per_tick: int = 5
@export var tick_rate: float = 0.5
@export var duration: float = 5.0

@onready var particles = $CPUParticles2D

var timer: float = 0.0
var tick_timer: float = 0.0

func _ready():
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

func _damage_enemies():
	for body in get_overlapping_bodies():
		if body.is_in_group("enemy") and body.has_method("take_damage"):
			body.take_damage(damage_per_tick)
			# Holy water deals bonus damage to some types (e.g. Vampires)
			if body.get("type") == 1: # Assuming VAMPIRE is 1
				body.take_damage(damage_per_tick)
