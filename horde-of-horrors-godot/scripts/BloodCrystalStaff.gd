extends Node2D

@export var damage: int = 22
@export var fire_rate: float = 0.45

@onready var fire_point = $FirePoint
@onready var crystal_glow = $Visuals/Crystal/PointLight2D

var last_fire_time: float = 0.0

func attack():
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_fire_time < fire_rate:
		return
		
	last_fire_time = current_time
	_fire_orb()

func _fire_orb():
	var orb = PoolManager.get_object("res://scenes/BloodOrb.tscn")
	if orb:
		if orb.get_parent() != get_tree().current_scene:
			if orb.get_parent(): orb.get_parent().remove_child(orb)
			get_tree().current_scene.add_child(orb)
		
		orb.global_position = fire_point.global_position
		var dir = Vector2.RIGHT.rotated(global_rotation)
		orb.initialize(dir, damage)
		
		if crystal_glow:
			var tween = create_tween()
			tween.tween_property(crystal_glow, "energy", 2.0, 0.1)
			tween.tween_property(crystal_glow, "energy", 0.8, 0.2)
		
		AudioManager.play_sfx("magic_cast")
