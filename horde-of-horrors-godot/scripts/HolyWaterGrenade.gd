extends Node2D

@export var throw_cooldown: float = 1.5
@export var throw_range: float = 250.0

var last_throw_time: float = 0.0

func attack():
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_throw_time < throw_cooldown:
		return
		
	last_throw_time = current_time
	_throw_vial()

func _throw_vial():
	var vial_scene = load("res://scenes/HolyWaterProjectile.tscn")
	if vial_scene:
		var vial = vial_scene.instantiate()
		get_tree().current_scene.add_child(vial)
		vial.global_position = global_position
		
		# Target position is throw_range in current direction
		var dir = Vector2.RIGHT.rotated(global_rotation)
		var target_pos = global_position + dir * throw_range
		
		vial.initialize(target_pos)
		AudioManager.play_sfx("throw")
