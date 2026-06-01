extends Node2D

@export var damage: int = 20
@export var fire_rate: float = 0.4
@export var burst_count: int = 3
@export var burst_delay: float = 0.08

@onready var fire_point = $FirePoint
@onready var muzzle_flash = $FirePoint/MuzzleFlash

var last_fire_time: float = 0.0
var is_bursting: bool = false

func attack():
	if is_bursting:
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_fire_time < fire_rate:
		return
		
	last_fire_time = current_time
	_fire_burst()

func _fire_burst():
	is_bursting = true
	for i in range(burst_count):
		_fire_projectile()
		if i < burst_count - 1:
			await get_tree().create_timer(burst_delay).timeout
	is_bursting = false

func _fire_projectile():
	var proj = PoolManager.get_object("res://scenes/Projectile.tscn")
	if proj:
		if proj.get_parent() != get_tree().current_scene:
			if proj.get_parent():
				proj.get_parent().remove_child(proj)
			get_tree().current_scene.add_child(proj)
		
		proj.global_position = fire_point.global_position
		
		# Get direction from rifle rotation
		var dir = Vector2.RIGHT.rotated(global_rotation)
		proj.initialize(dir, damage)
		
		if muzzle_flash:
			muzzle_flash.restart()
		
		AudioManager.play_sfx("shoot")
