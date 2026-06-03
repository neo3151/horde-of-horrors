extends Node2D

@export var damage: int = 18
@export var fire_rate: float = 0.6
@export var max_range: float = 350.0

@onready var fire_point = $FirePoint

var last_fire_time: float = 0.0
var level: int = 1

func set_level(lvl: int):
	level = lvl
	if level >= 3:
		fire_rate = 0.3
	else:
		fire_rate = 0.6

func attack():
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_fire_time < fire_rate:
		return
		
	last_fire_time = current_time
	_fire_lightning()

func _fire_lightning():
	if not GameManager.wave_manager: return
	
	var target = GameManager.wave_manager.get_nearest_enemy(global_position)
	
	if target and global_position.distance_to(target.global_position) <= max_range:
		var chain_scene = load("res://scripts/LightningChain.gd")
		if chain_scene:
			var chain = Node2D.new()
			chain.set_script(chain_scene)
			chain.set_meta("level", level)
			get_tree().current_scene.add_child(chain)
			chain.start_chain(fire_point.global_position, damage)
			
			AudioManager.play_sfx("lightning")
	else:
		# Visual fizzle or miss
		pass
