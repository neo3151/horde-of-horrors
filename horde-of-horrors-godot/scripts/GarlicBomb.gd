extends Node2D

@export var throw_cooldown: float = 8.0
@export var throw_range: float = 280.0

var last_throw_time: float = 0.0
var level: int = 1

func set_level(lvl: int) -> void:
	level = lvl
	if level >= 5:
		throw_cooldown = 5.0
	else:
		throw_cooldown = 8.0

func attack():
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_throw_time < throw_cooldown:
		return
		
	last_throw_time = current_time
	_throw_bomb()

func _throw_bomb():
	var bomb_scene = load("res://scenes/GarlicProjectile.tscn")
	if bomb_scene:
		if level >= 5:
			# Throw 3 bombs
			for angle_offset in [-0.35, 0.0, 0.35]:
				var bomb = bomb_scene.instantiate()
				bomb.set_meta("level", level)
				get_tree().current_scene.add_child(bomb)
				bomb.global_position = global_position
				
				var dir = Vector2.RIGHT.rotated(global_rotation + angle_offset)
				var target_pos = global_position + dir * throw_range
				bomb.initialize(target_pos)
		elif level >= 3:
			# Throw 2 bombs
			for angle_offset in [-0.25, 0.25]:
				var bomb = bomb_scene.instantiate()
				bomb.set_meta("level", level)
				get_tree().current_scene.add_child(bomb)
				bomb.global_position = global_position
				
				var dir = Vector2.RIGHT.rotated(global_rotation + angle_offset)
				var target_pos = global_position + dir * throw_range
				bomb.initialize(target_pos)
		else:
			# Throw 1 bomb
			var bomb = bomb_scene.instantiate()
			bomb.set_meta("level", level)
			get_tree().current_scene.add_child(bomb)
			bomb.global_position = global_position
			
			var dir = Vector2.RIGHT.rotated(global_rotation)
			var target_pos = global_position + dir * throw_range
			bomb.initialize(target_pos)
			
		AudioManager.play_sfx("throw")


