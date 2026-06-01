extends Camera2D

@export var base_zoom: Vector2 = Vector2(2.0, 2.0)
@export var boss_zoom: Vector2 = Vector2(1.5, 1.5)
@export var zoom_speed: float = 2.0

@export var shake_decay: float = 15.0
var current_shake_intensity: float = 0.0

func _ready():
	zoom = base_zoom
	# Connect to GameManager signals if needed
	if GameManager.has_signal("game_over"):
		GameManager.game_over.connect(_on_game_over)

func _process(delta):
	# Handle Zoom
	var target_zoom = base_zoom
	if GameManager.wave_manager and GameManager.current_wave % 10 == 0:
		target_zoom = boss_zoom
	
	zoom = zoom.lerp(target_zoom, zoom_speed * delta)
	
	# Handle Shake
	if current_shake_intensity > 0:
		offset = Vector2(
			randf_range(-1.0, 1.0) * current_shake_intensity,
			randf_range(-1.0, 1.0) * current_shake_intensity
		)
		current_shake_intensity = lerp(current_shake_intensity, 0.0, shake_decay * delta)
	else:
		offset = Vector2.ZERO

func add_shake(intensity: float):
	current_shake_intensity = max(current_shake_intensity, intensity)

func _on_game_over(_score, _waves):
	# Dramatic zoom out on death
	var tween = create_tween()
	tween.tween_property(self, "zoom", Vector2(1.0, 1.0), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
