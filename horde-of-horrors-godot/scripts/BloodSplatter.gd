extends CPUParticles2D

func _ready() -> void:
	emitting = true
	# Wait for lifetime and delete
	await get_tree().create_timer(lifetime + 0.1).timeout
	queue_free()
