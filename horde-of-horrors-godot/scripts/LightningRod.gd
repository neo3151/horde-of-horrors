extends Node2D

@export var damage: int = 18
@export var fire_rate: float = 0.6
@export var max_range: float = 350.0

@onready var fire_point = $FirePoint

var last_fire_time: float = 0.0

func attack():
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_fire_time < fire_rate:
		return
		
	last_fire_time = current_time
	_fire_lightning()

func _fire_lightning():
	if not GameManager.wave_manager: return
	
	var dir = Vector2.RIGHT.rotated(global_rotation)
	var target = GameManager.wave_manager.get_nearest_enemy(global_position)
	
	# Check if target is in front and within range
	if target and global_position.distance_to(target.global_position) <= max_range:
		var chain_scene = load("res://scripts/LightningChain.gd")
		if chain_scene:
			var chain = Node2D.new()
			chain.set_script(chain_scene)
			get_tree().current_scene.add_child(chain)
			chain.start_chain(fire_point.global_position, damage)
			
			AudioManager.play_sfx("lightning")
	else:
		# Visual fizzle or miss
		pass
