extends CharacterBody3D

@export var speed: float = 5.0
@export var max_health: int = 20

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var player: Node3D

@onready var sprite: Sprite3D = $Visuals/Sprite3D

func _ready() -> void:
	add_to_group("enemy")
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if not player:
		player = get_tree().get_first_node_in_group("player")
		return

	# Simple AI: Move towards player
	var direction = (player.global_position - global_position).normalized()
	direction.y = 0
	
	if direction.length() > 0.1:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		set_meta("facing_direction", direction)
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()

func take_damage(amount: int) -> void:
	max_health -= amount
	if max_health <= 0:
		queue_free()
