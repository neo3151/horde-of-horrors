extends Node2D

var spots: Array = []

func _ready() -> void:
	z_index = -4 # Render above floor tiles, but underneath player, enemies, and projectiles
	
	# Generate a cluster of random circles to form an organic puddle
	var num_spots = randi_range(3, 8)
	for i in num_spots:
		var offset = Vector2(randf_range(-14, 14), randf_range(-14, 14))
		var radius = randf_range(3.0, 10.0)
		spots.append({"offset": offset, "radius": radius})
		
	queue_redraw()
	
	# Keep the blood on the floor for 15 seconds, then fade it out over 5 seconds
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 5.0).set_delay(15.0)
	await tween.finished
	queue_free()

func _draw() -> void:
	var blood_color = Color(0.5, 0.0, 0.0, 0.75) # Dark rich blood red
	for spot in spots:
		draw_circle(spot.offset, spot.radius, blood_color)
