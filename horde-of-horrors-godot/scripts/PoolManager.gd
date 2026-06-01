# PoolManager.gd
extends Node

# Dictionary: { "res://path/to/scene.tscn": { "available": [], "active": [] } }
var pools: Dictionary = {}

# Pre-spawn counts (tweak these based on profiling)
const PRE_SPAWN_COUNTS = {
	"res://scenes/Projectile.tscn": 40,
	"res://scenes/ProjectileHitEffect.tscn": 20,
	"res://scenes/EnemyWerewolf.tscn": 15,
	"res://scenes/EnemyVampire.tscn": 12,
	"res://scenes/EnemyGhost.tscn": 10,
	"res://scenes/EnemyFrankenstein.tscn": 5,
	"res://scenes/EnemyStitcher.tscn": 5,
	"res://scenes/EnemyButcherBoy.tscn": 3,
}

func _ready() -> void:
	# Pre-spawn everything at game start
	for scene_path in PRE_SPAWN_COUNTS:
		_create_pool(scene_path, PRE_SPAWN_COUNTS[scene_path])

func _create_pool(scene_path: String, count: int) -> void:
	if pools.has(scene_path):
		return
	
	pools[scene_path] = {
		"available": [],
		"active": []
	}
	
	var template = load(scene_path)
	for i in count:
		var instance = template.instantiate()
		instance.visible = false
		instance.set_process(false)
		instance.set_physics_process(false)
		_set_collisions_disabled(instance, true)
		
		add_child(instance)                    # Keep in tree under PoolManager for speed
		pools[scene_path].available.append(instance)

func get_object(scene_path: String) -> Node:
	if not pools.has(scene_path):
		_create_pool(scene_path, 10)           # Lazy create if missing
	
	var pool = pools[scene_path]
	
	var instance: Node
	if pool.available.size() > 0:
		instance = pool.available.pop_back()
	else:
		# Pool ran dry — create new one
		var template = load(scene_path)
		instance = template.instantiate()
		add_child(instance)
	
	pool.active.append(instance)
	
	instance.visible = true
	instance.set_process(true)
	instance.set_physics_process(true)
	_set_collisions_disabled(instance, false)
	
	return instance

func return_object(scene_path: String, instance: Node) -> void:
	if not instance or not pools.has(scene_path):
		return
	
	var pool = pools[scene_path]
	if pool.active.has(instance):
		pool.active.erase(instance)
		pool.available.append(instance)
		
		# Deactivate
		instance.visible = false
		instance.set_process(false)
		instance.set_physics_process(false)
		_set_collisions_disabled(instance, true)
		
		# Reparent back to PoolManager if it was added elsewhere
		if instance.get_parent() != self:
			instance.get_parent().remove_child(instance)
			add_child(instance)
		
		# Call reset if the object has one
		if instance.has_method("reset"):
			instance.reset()

func _set_collisions_disabled(node: Node, disabled: bool) -> void:
	if node is CollisionObject2D:
		node.set_deferred("monitoring", !disabled)
		node.set_deferred("monitorable", !disabled)
		for child in node.get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", disabled)
	elif node is Area2D:
		node.set_deferred("monitoring", !disabled)
		node.set_deferred("monitorable", !disabled)
		for child in node.get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", disabled)
	
	for child in node.get_children():
		_set_collisions_disabled(child, disabled)
