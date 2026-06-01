import re

with open('scripts/Player.gd', 'r') as f:
    content = f.read()

# Add shake variables after var was_on_floor
var_addition = """var was_on_floor: bool = true

# Camera shake
var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var base_camera_pos: Vector2 = Vector2.ZERO"""
content = content.replace('var was_on_floor: bool = true', var_addition)

# In _ready, save base camera pos
ready_addition = """func _ready() -> void:
	if camera:
		base_camera_pos = camera.position"""
content = content.replace('func _ready() -> void:', ready_addition)

# Add _process to handle shake
process_addition = """func _process(delta: float) -> void:
	if shake_timer > 0:
		shake_timer -= delta
		if camera:
			camera.position = base_camera_pos + Vector2(
				randf_range(-shake_intensity, shake_intensity),
				randf_range(-shake_intensity, shake_intensity)
			)
			# Decay intensity slightly
			shake_intensity = lerp(shake_intensity, 0.0, delta * 5.0)
	else:
		if camera and camera.position != base_camera_pos:
			camera.position = lerp(camera.position, base_camera_pos, delta * 10.0)

	_update_animation()"""
content = content.replace('func _process(delta: float) -> void:\n\t_update_animation()', process_addition)

# Add shake_camera method
method_addition = """
func shake_camera(intensity: float, duration: float) -> void:
	shake_intensity = max(shake_intensity, intensity)
	shake_timer = duration
"""
content += method_addition

with open('scripts/Player.gd', 'w') as f:
    f.write(content)
print("Added camera shake to Player.gd")
