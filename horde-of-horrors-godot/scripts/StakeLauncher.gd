extends Node2D

@export var damage: int = 55
@export var fire_rate: float = 0.9

@onready var fire_point = $FirePoint
@onready var muzzle_flash = $FirePoint/MuzzleFlash

var last_fire_time: float = 0.0
var level: int = 1

func set_level(lvl: int):
	level = lvl
	if level >= 3:
		fire_rate = 0.5
	else:
		fire_rate = 0.9

func attack():
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_fire_time < fire_rate:
		return
		
	last_fire_time = current_time
	_fire_projectile()

func _fire_projectile():
	var num_stakes = 2 if level >= 4 else 1
	for i in range(num_stakes):
		var proj = PoolManager.get_object("res://scenes/StakeProjectile.tscn")
		if proj:
			if proj.get_parent() != get_tree().current_scene:
				if proj.get_parent(): proj.get_parent().remove_child(proj)
				get_tree().current_scene.add_child(proj)
			
			proj.set_meta("level", level)
			proj.global_position = fire_point.global_position
			
			var dir = Vector2.RIGHT.rotated(global_rotation)
			if num_stakes > 1:
				var angle_offset = -0.15 if i == 0 else 0.15
				dir = dir.rotated(angle_offset)
				
			proj.initialize(dir, damage)
			
			# Apply Level 2 size upgrade
			if level >= 2:
				proj.scale = Vector2(1.4, 1.4)
				proj.piercing_count = 4
			else:
				proj.scale = Vector2(1.0, 1.0)
				proj.piercing_count = 2
		
		if muzzle_flash:
			muzzle_flash.restart()
		
		AudioManager.play_sfx("shoot")
