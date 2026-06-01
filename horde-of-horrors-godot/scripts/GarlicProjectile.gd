extends Node2D

@export var speed: float = 450.0
@export var rotation_speed: float = 8.0
@export var arc_height: float = 90.0

var target_position: Vector2 = Vector2.ZERO
var start_position: Vector2 = Vector2.ZERO
var distance_total: float = 0.0
var distance_traveled: float = 0.0

func initialize(target_pos: Vector2):
	start_position = global_position
	target_position = target_pos
	distance_total = start_position.distance_to(target_position)

func _physics_process(delta):
	if distance_traveled >= distance_total:
		_explode()
		return
	
	var move_amount = speed * delta
	distance_traveled += move_amount
	
	var t = distance_traveled / distance_total
	t = clamp(t, 0.0, 1.0)
	
	var current_ground_pos = start_position.lerp(target_position, t)
	var height = 4 * arc_height * t * (1 - t)
	
	global_position = current_ground_pos + Vector2(0, -height)
	$Visuals.rotation += rotation_speed * delta

func _explode():
	var cloud_scene = load("res://scenes/GarlicCloud.tscn")
	if cloud_scene:
		var cloud = cloud_scene.instantiate()
		get_tree().current_scene.add_child(cloud)
		cloud.global_position = target_position
	
	AudioManager.play_sfx("bomb_impact")
	queue_free()
