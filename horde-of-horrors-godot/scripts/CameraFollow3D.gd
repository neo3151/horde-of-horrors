extends Node3D

@export var target_path: NodePath
@export var offset: Vector3 = Vector3(0, 8, 8)
@export var follow_speed: float = 5.0

var target: Node3D

func _ready() -> void:
	if target_path:
		target = get_node(target_path)

func _process(delta: float) -> void:
	if not target:
		# Try to find the player if target not set
		target = get_tree().get_first_node_in_group("player")
		if not target: return

	var target_pos = target.global_position + offset
	global_position = global_position.lerp(target_pos, follow_speed * delta)
	
	# Look at the player but keep the fixed angle
	# We don't actually use look_at here to maintain the 2.5D feel, 
	# just fixed rotation is often better for HD-2D.
