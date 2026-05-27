extends Node

var object_pools: Dictionary = {}

func _ready() -> void:
	pass # No initial setup needed

# Call this to set up a pool for a specific scene
func setup_pool(scene_path: String, initial_size: int = 10) -> void:
	var scene = load(scene_path)
	if scene == null:
		push_error("Failed to load scene for pooling: ", scene_path)
		return

	if not object_pools.has(scene_path):
		object_pools[scene_path] = []
		for i in range(initial_size):
			var instance = scene.instantiate()
			add_child(instance)
			instance.queue_free() # Add to queue for later deletion, so it won't be in the scene tree yet
			object_pools[scene_path].append(instance)

# Get an instance from the pool
func get_instance(scene_path: String) -> Node:
	if not object_pools.has(scene_path):
		push_error("Pool not set up for scene: ", scene_path)
		return null

	var instance: Node = null
	if object_pools[scene_path].size() > 0:
		instance = object_pools[scene_path].pop_front()
		# Remove from the deferred queue_free and add back to the scene
		get_parent().add_child(instance)
		instance.set_process_mode(Node.PROCESS_MODE_INHERIT) # Ensure it's active
	else:
		# If pool is empty, create a new instance (can expand pool if needed)
		var scene = load(scene_path)
		if scene:
			instance = scene.instantiate()
			get_parent().add_child(instance)
			push_warning("Expanded pool for: ", scene_path)

	return instance

# Return an instance to the pool
func return_instance(scene_path: String, instance: Node) -> void:
	if not object_pools.has(scene_path):
		push_error("Pool not set up for scene: ", scene_path)
		instance.queue_free() # Just free it if no pool exists
		return

	if instance:
		instance.set_process_mode(Node.PROCESS_MODE_DISABLED) # Disable processing when in pool
		instance.get_parent().remove_child(instance) # Remove from current parent
		object_pools[scene_path].append(instance)
