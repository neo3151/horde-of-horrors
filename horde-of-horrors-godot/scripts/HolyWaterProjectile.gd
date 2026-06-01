extends Node2D

@export var speed: float = 400.0
@export var rotation_speed: float = 10.0
@export var arc_height: float = 100.0

var direction: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO
var start_position: Vector2 = Vector2.ZERO
var distance_total: float = 0.0
var distance_traveled: float = 0.0

func initialize(target_pos: Vector2):
	start_position = global_position
	target_position = target_pos
	distance_total = start_position.distance_to(target_position)
	direction = (target_position - start_position).normalized()

func _physics_process(delta):
	if distance_traveled >= distance_total:
		_explode()
		return
	
	var move_amount = speed * delta
	distance_traveled += move_amount
	
	var t = distance_traveled / distance_total
	t = clamp(t, 0.0, 1.0)
	
	# Linear interpolation for ground position
	var current_ground_pos = start_position.lerp(target_position, t)
	
	# Parabolic arc for height
	var height = 4 * arc_height * t * (1 - t)
	
	global_position = current_ground_pos + Vector2(0, -height)
	$Visuals.rotation += rotation_speed * delta

func _explode():
	var zone_scene = load("res://scenes/SanctifiedZone.tscn")
	if zone_scene:
		var zone = zone_scene.instantiate()
		get_tree().current_scene.add_child(zone)
		zone.global_position = target_position
	
	AudioManager.play_sfx("glass_shatter") # Assuming we have or will add this
	queue_free()
