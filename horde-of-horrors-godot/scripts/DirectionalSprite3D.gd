extends Sprite3D
class_name DirectionalSprite3D

## How many directions does this sprite have? (1, 4 or 8)
@export var directions: int = 8

## How many vertical layers are stacked? (Set to 1 for flat 8-directional billboard)
@export var layer_count: int = 1

## The distance between each layer on the Y-axis
@export var layer_height: float = 0.01

## For debugging: expands the stack so you can see each slice clearly
@export var expand_stack: float = 1.0

## How much to scale the width of the sprite
@export var width_scale: float = 1.0

var parent: CharacterBody3D
var stacked_sprite_layers: Array[Sprite3D] = []

# Load the 8 split frame files directly to completely avoid edge-bleeding / white fragments
var billboard_textures: Array[Texture2D] = []

# Map direction index (0=Front, clockwise) to hunter_8way_split frame index:
# Front-facing angles (0, 1, 7) use Row 0 frames (0, 1) and Row 1 frames (4)
# Left/Right are mirrored to fix left-right facing direction:
# 0: Front       -> Frame 0
# 1: Front-Left  -> Frame 4 (Front-Right)
# 2: Left        -> Frame 5 (Right)
# 3: Back-Left   -> Frame 6 (Back-Right)
# 4: Back        -> Frame 7 (Back)
# 5: Back-Right  -> Frame 3 (Back-Left)
# 6: Right       -> Frame 2 (Left)
# 7: Front-Right -> Frame 1 (Front-Left)
const MIRRORED_FRAME_MAP = [0, 4, 5, 6, 7, 3, 2, 1]

func _ready() -> void:
	# 1. Load the 8 individual full-body frame textures for flat 8-directional mode
	if layer_count == 1:
		for i in range(8):
			var path = "res://assets/sprites/player/hunter_8way_split/frame_" + str(i) + ".png"
			billboard_textures.append(load(path))
			
	var p = get_parent()
	while p and not p is CharacterBody3D:
		p = p.get_parent()
	parent = p as CharacterBody3D
	
	_update_layers()

func _update_layers() -> void:
	if layer_count > 1:
		hframes = directions
		vframes = layer_count
	else:
		# Individual split frames are not sliced sheets, so hframes/vframes are 1!
		hframes = 1
		vframes = 1
		
	scale.x = width_scale
	
	# Clear existing children
	for child in get_children():
		if child is Sprite3D:
			child.queue_free()
	stacked_sprite_layers.clear()
	
	# Only stack if layer_count > 1
	if layer_count > 1:
		for i in range(1, layer_count):
			var s = Sprite3D.new()
			s.texture = texture
			s.hframes = hframes
			s.vframes = vframes
			s.billboard = billboard
			s.shaded = shaded
			s.texture_filter = texture_filter
			s.alpha_cut = alpha_cut
			s.pixel_size = pixel_size
			s.no_depth_test = no_depth_test
			s.render_priority = render_priority + i
			s.position = Vector3(0, i * layer_height * expand_stack, 0)
			s.scale.x = 1.0
			add_child(s)
			stacked_sprite_layers.append(s)

func _process(_delta: float) -> void:
	if layer_count > 1:
		hframes = directions
		vframes = layer_count
		for l in stacked_sprite_layers:
			if l.texture != texture:
				l.texture = texture
			l.hframes = hframes
			l.vframes = vframes
	else:
		hframes = 1
		vframes = 1

	var cam = get_viewport().get_camera_3d()
	if not cam or not parent:
		return

	# Get the character's movement or facing direction in 3D
	var facing_dir = Vector3.FORWARD
	if parent.velocity.length() > 0.1:
		facing_dir = parent.velocity.normalized()
	elif parent.has_meta("facing_direction"):
		facing_dir = parent.get_meta("facing_direction")

	_update_direction(facing_dir, cam)

func _update_direction(facing: Vector3, cam: Camera3D) -> void:
	# Calculate the angle between character facing and camera forward on the XZ plane
	var cam_forward = -cam.global_transform.basis.z
	cam_forward.y = 0
	cam_forward = cam_forward.normalized()
	
	var facing_xz = facing
	facing_xz.y = 0
	facing_xz = facing_xz.normalized()

	# Angle in radians
	var angle = atan2(facing_xz.x, facing_xz.z) - atan2(cam_forward.x, cam_forward.z)
	angle = wrapf(angle, -PI, PI)

	if layer_count > 1:
		# Sprite Stacking multi-angle slicing logic
		var dir_idx = 0
		if directions > 1:
			var norm_angle = (angle + PI) / (2 * PI) # 0 to 1
			dir_idx = int(round(norm_angle * directions)) % directions
		
		frame = (layer_count - 1) * directions + dir_idx
		
		for i in range(stacked_sprite_layers.size()):
			var layer_idx = i + 1
			var sheet_row = (layer_count - 1) - layer_idx
			stacked_sprite_layers[i].frame = sheet_row * directions + dir_idx
	else:
		# 8-directional flat billboard logic
		# Convert angle (-PI..PI) to index (0..7)
		var norm_angle = (angle + PI) / (2 * PI) # 0 to 1
		var dir_idx = int(round(norm_angle * 8)) % 8
		
		# Map index to correct mirrored frame index to fix left-right direction reversal
		var mapped_frame = MIRRORED_FRAME_MAP[dir_idx]
		
		# Assign the clean, split individual frame texture directly
		if billboard_textures.size() > mapped_frame:
			texture = billboard_textures[mapped_frame]
		
		# Dynamic offset compensation to keep feet perfectly planted on the ground
		# Row 0 frames (0, 1, 2, 3) have feet at the bottom (bottom_margin ≈ 11px)
		# Row 1 frames (4, 5, 6, 7) have feet near the middle (bottom_margin ≈ 217px)
		if mapped_frame >= 4:
			position.y = 0.117
		else:
			position.y = 0.735
