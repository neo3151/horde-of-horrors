extends Node

var screen_shake_intensity: float = 0.0
var screen_shake_duration: float = 0.0

func _physics_process(delta: float) -> void:
	if screen_shake_duration > 0:
		_apply_screen_shake(delta)
		screen_shake_duration -= delta
	else:
		get_viewport().set_canvas_transform(Transform2D())

func start_screen_shake(intensity: float, duration: float) -> void:
	screen_shake_intensity = intensity
	screen_shake_duration = duration

func _apply_screen_shake(delta: float) -> void:
	var shake_offset = Vector2(randf_range(-screen_shake_intensity, screen_shake_intensity), randf_range(-screen_shake_intensity, screen_shake_intensity))
	get_viewport().set_canvas_transform(Transform2D().translated(shake_offset))
	# Reduce intensity over time
	screen_shake_intensity = lerp(screen_shake_intensity, 0.0, delta * 5.0) # Adjust falloff speed

func spawn_hit_particles(position: Vector2, color: Color, count: int = 5) -> void:
	# Placeholder for particle instantiation
	# For now, just print a message
	print("Spawning ", count, " ", color, " hit particles at ", position)
