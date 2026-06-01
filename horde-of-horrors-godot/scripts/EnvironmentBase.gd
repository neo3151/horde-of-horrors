extends Node2D
class_name EnvironmentBase

@export var environment_name: String = "Unknown Location"
@export var ambient_color: Color = Color(0.3, 0.3, 0.4, 1.0)
@export var hazard_damage: int = 10
@export var music_track: String = "battle_theme"

func _ready():
	# Apply ambient light when loaded
	var canvas_modulate = get_tree().current_scene.get_node_or_null("CanvasModulate")
	if canvas_modulate:
		canvas_modulate.color = ambient_color * GameManager.brightness_factor
	
	AudioManager.play_music(music_track)
