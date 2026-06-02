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
	
	# Dynamically load the selected character in 3D
	var char_name = GameManager.selected_character
	print("Player3D: Loading character: " + char_name)
	if GameManager.CHARACTERS.has(char_name) and is_instance_valid(sprite):
		var data = GameManager.CHARACTERS[char_name]
		if char_name == "Elias":
			print("Player3D: Setting up Elias with 8-way split frames")
			sprite.split_frames_dir = "res://assets/sprites/player/elias_8way_split"
			sprite.directions = 8
			sprite.layer_count = 1
			sprite.pixel_size = 0.0195
			sprite.billboard_textures.clear()
			sprite._ready()
			print("Player3D: Elias frames loaded: " + str(sprite.billboard_textures.size()))
		elif char_name == "Victor" or char_name == "Serena":
			print("Player3D: Setting up " + char_name + " as original stacked sprite")
			sprite.texture = load(data["texture"])
			sprite.directions = 1
			sprite.layer_count = 8
			sprite.layer_height = 0.008
			sprite.pixel_size = 0.008
			sprite.width_scale = 1.0
			sprite.modulate = Color(0.8, 0.8, 0.8, 1.0) # Dim slightly
			sprite.split_frames_dir = ""
			sprite._update_layers()
		elif char_name == "Hunter" or char_name == "Elias Voss" or char_name.contains("Hunter"):
			print("Player3D: Setting up Hunter")
			sprite.split_frames_dir = "res://assets/sprites/player/hunter_8way_split"
			sprite.directions = 8
			sprite.layer_count = 1
			sprite.billboard_textures.clear()
			sprite._ready()
		else:
			# Fallback for other characters (Werewolf, Vampire, Frankenstein) as flat billboards
			print("Player3D: Fallback for " + char_name)
			sprite.texture = load(data["texture"])
			sprite.directions = 1
			sprite.layer_count = 1
			sprite.split_frames_dir = ""
			sprite._update_layers()
	else:
		print("Player3D: Character not found or sprite invalid")

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
