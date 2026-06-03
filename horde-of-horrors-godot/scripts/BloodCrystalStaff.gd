extends Node2D

@export var damage: int = 22
@export var fire_rate: float = 0.45

@onready var fire_point = $FirePoint
@onready var crystal_glow = $Visuals/Crystal/PointLight2D

var last_fire_time: float = 0.0
var level: int = 1

func set_level(lvl: int):
	level = lvl
	if level >= 3:
		fire_rate = 0.25
	else:
		fire_rate = 0.45

func attack():
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_fire_time < fire_rate:
		return
		
	last_fire_time = current_time
	_fire_orb()

func _fire_orb():
	var num_orbs = 2 if level >= 2 else 1
	for i in range(num_orbs):
		var orb = PoolManager.get_object("res://scenes/BloodOrb.tscn")
		if orb:
			if orb.get_parent() != get_tree().current_scene:
				if orb.get_parent(): orb.get_parent().remove_child(orb)
				get_tree().current_scene.add_child(orb)
			
			orb.set_meta("level", level)
			orb.global_position = fire_point.global_position
			
			var dir = Vector2.RIGHT.rotated(global_rotation)
			if num_orbs > 1:
				var angle_offset = -0.2 if i == 0 else 0.2
				dir = dir.rotated(angle_offset)
				
			orb.initialize(dir, damage)
			
			# Apply Level 4 size/speed upgrades
			if level >= 4:
				orb.scale = Vector2(1.4, 1.4)
				orb.speed = 850.0
				orb.turn_speed = 12.0
			else:
				orb.scale = Vector2(1.0, 1.0)
				orb.speed = 600.0
				orb.turn_speed = 8.0
		
	if crystal_glow:
		var tween = create_tween()
		tween.tween_property(crystal_glow, "energy", 2.0, 0.1)
		tween.tween_property(crystal_glow, "energy", 0.8, 0.2)
	
	AudioManager.play_sfx("magic_cast")
