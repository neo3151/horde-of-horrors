extends Node2D

@export var damage: int = 55
@export var fire_rate: float = 0.9

@onready var fire_point = $FirePoint
@onready var muzzle_flash = $FirePoint/MuzzleFlash

var last_fire_time: float = 0.0

func attack():
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_fire_time < fire_rate:
		return
		
	last_fire_time = current_time
	_fire_projectile()

func _fire_projectile():
	var proj = PoolManager.get_object("res://scenes/StakeProjectile.tscn")
	if proj:
		if proj.get_parent() != get_tree().current_scene:
			if proj.get_parent(): proj.get_parent().remove_child(proj)
			get_tree().current_scene.add_child(proj)
		
		proj.global_position = fire_point.global_position
		var dir = Vector2.RIGHT.rotated(global_rotation)
		proj.initialize(dir, damage)
		
		if muzzle_flash:
			muzzle_flash.restart()
		
		AudioManager.play_sfx("shoot") # Should maybe be a "thunk" sound
