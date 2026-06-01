extends Node2D

@export var damage: int = 35
@export var fire_rate: float = 0.8

@onready var fire_point = $FirePoint

var last_fire_time: float = 0.0

func attack():
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_fire_time < fire_rate:
		return
		
	last_fire_time = current_time
	_fire_arrow()

func _fire_arrow():
	var arrow = PoolManager.get_object("res://scenes/MoonlightArrow.tscn")
	if arrow:
		if arrow.get_parent() != get_tree().current_scene:
			if arrow.get_parent(): arrow.get_parent().remove_child(arrow)
			get_tree().current_scene.add_child(arrow)
		
		arrow.global_position = fire_point.global_position
		var dir = Vector2.RIGHT.rotated(global_rotation)
		arrow.initialize(dir, damage)
		
		AudioManager.play_sfx("bow_shoot")
