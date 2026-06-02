extends CharacterBody3D

@export var move_speed: float = 8.0 # 3D units are larger than pixels
@export var acceleration: float = 40.0
@export var friction: float = 30.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var facing_direction: Vector3 = Vector3.BACK

@onready var sprite: Sprite3D = $Visuals/Sprite3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	# Force Portrait Orientation on Mobile immediately at launch
	DisplayServer.screen_set_orientation(1)
	
	# Set metadata for the DirectionalSprite3D script
	set_meta("facing_direction", facing_direction)
	
	# Reference current player in GameManager (logic ported from 2D)
	GameManager.player = self

func _physics_process(delta: float) -> void:
	if GameManager.is_game_over:
		return

	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	# Input handling (mapped from Project Settings)
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# In 3D, we move on the X/Z plane
	# Transform input to camera-relative movement
	var cam = get_viewport().get_camera_3d()
	var direction = Vector3.ZERO
	
	if cam:
		var forward = -cam.global_transform.basis.z
		forward.y = 0
		forward = forward.normalized()
		var right = cam.global_transform.basis.x
		right.y = 0
		right = right.normalized()
		
		# Fixed reversed directions: S goes back, W goes forward, A goes left, D goes right
		direction = (-forward * input_dir.y + right * input_dir.x).normalized()

	if direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direction.x * move_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * move_speed, acceleration * delta)
		facing_direction = direction
		set_meta("facing_direction", facing_direction)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)

	move_and_slide()
	if velocity.length() > 0.1:
		print("[Player3D] Global Position: ", global_position, " is_on_floor: ", is_on_floor())
	_update_animation()

func _update_animation() -> void:
	var anim = "idle"
	if velocity.length() > 0.2:
		anim = "run"
	
	if animation_player.has_animation(anim):
		if animation_player.current_animation != anim:
			animation_player.play(anim)

# Logic for taking damage, health, etc. would be ported here as well.
# For the sake of the initial demo, we focus on movement visuals.
func take_damage(amount: int) -> void:
	# Ported from Player.gd
	print("Player3D took damage: ", amount)
	# ... rest of the logic
