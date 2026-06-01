extends CPUParticles2D

func _ready() -> void:
	play_effect()

func play_effect() -> void:
	emitting = true
	get_tree().create_timer(lifetime).timeout.connect(func():
		PoolManager.return_object("res://scenes/ProjectileHitEffect.tscn", self)
	)

func reset() -> void:
	emitting = false

