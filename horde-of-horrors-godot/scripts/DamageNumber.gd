extends Node2D

@onready var label = $Label

func setup(amount: int, is_crit: bool = false) -> void:
	label.text = str(amount)
	if is_crit:
		label.modulate = Color(1.0, 0.2, 0.2) # Bright Red
		scale = Vector2(1.4, 1.4)
	else:
		label.modulate = Color(1.0, 0.9, 0.1) # Gold/Yellow
		scale = Vector2(1.0, 1.0)
		
	# Spawn variance
	position += Vector2(randf_range(-15, 15), randf_range(-15, 15))
		
	# Animate floating up and fading out
	var tween = create_tween().set_parallel(true)
	var target_pos = position + Vector2(randf_range(-25, 25), -60)
	tween.tween_property(self, "position", target_pos, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.15)
	
	# Scale animation
	var scale_tween = create_tween()
	scale_tween.tween_property(self, "scale", scale * 1.2, 0.15)
	scale_tween.tween_property(self, "scale", Vector2.ZERO, 0.5).set_delay(0.15)
	
	await tween.finished
	queue_free()
