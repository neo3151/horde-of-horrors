extends Node2D

@export var damage: int = 35
@export var fire_rate: float = 0.8

@onready var fire_point = $FirePoint

var last_fire_time: float = 0.0
var level: int = 1

func set_level(lvl: int):
	level = lvl
	if level >= 3:
		fire_rate = 0.5
	else:
		fire_rate = 0.8

func attack():
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_fire_time < fire_rate:
		return
		
	last_fire_time = current_time
	_fire_arrow()

func _fire_arrow():
	var num_arrows = 2 if level >= 2 else 1
	for i in range(num_arrows):
		var arrow = PoolManager.get_object("res://scenes/MoonlightArrow.tscn")
		if arrow:
			if arrow.get_parent() != get_tree().current_scene:
				if arrow.get_parent(): arrow.get_parent().remove_child(arrow)
				get_tree().current_scene.add_child(arrow)
			
			arrow.set_meta("level", level)
			arrow.global_position = fire_point.global_position
			
			var dir = Vector2.RIGHT.rotated(global_rotation)
			if num_arrows > 1:
				var angle_offset = -0.1 if i == 0 else 0.1
				dir = dir.rotated(angle_offset)
				
			arrow.initialize(dir, damage)
			
			# Setup crit based on level
			if level >= 4:
				arrow.crit_chance = 0.60
				arrow.crit_multiplier = 3.5
			else:
				arrow.crit_chance = 0.30
				arrow.crit_multiplier = 2.5
				
	AudioManager.play_sfx("bow_shoot")
