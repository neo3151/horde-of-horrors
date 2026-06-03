extends Node2D

@export var throw_cooldown: float = 1.5
@export var throw_range: float = 250.0

var last_throw_time: float = 0.0
var level: int = 1

func set_level(lvl: int):
	level = lvl
	if level >= 3:
		throw_cooldown = 0.8
	else:
		throw_cooldown = 1.5

func attack():
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_throw_time < throw_cooldown:
		return
		
	last_throw_time = current_time
	_throw_vial()

func _throw_vial():
	var vial_scene = load("res://scenes/HolyWaterProjectile.tscn")
	if vial_scene:
		var num_vials = 2 if level >= 2 else 1
		for i in range(num_vials):
			var vial = vial_scene.instantiate()
			vial.set_meta("level", level)
			get_tree().current_scene.add_child(vial)
			vial.global_position = global_position
			
			var dir = Vector2.RIGHT.rotated(global_rotation)
			if num_vials > 1:
				var angle_offset = -0.25 if i == 0 else 0.25
				dir = dir.rotated(angle_offset)
				
			var target_pos = global_position + dir * throw_range
			vial.initialize(target_pos)
			
		AudioManager.play_sfx("throw")
