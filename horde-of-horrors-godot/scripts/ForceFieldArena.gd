# ForceFieldArena.gd
extends Node2D
class_name ForceFieldArena

@export var radius: float = 240.0
@export var color: Color = Color(0.85, 0.1, 0.1, 0.3)

var active: bool = false
var boss_node: Node2D = null

func _ready() -> void:
	z_index = 10
	visible = false

func activate(new_boss: Node2D, center_pos: Vector2) -> void:
	boss_node = new_boss
	global_position = center_pos
	active = true
	visible = true
	queue_redraw()
	
	# Spawn activation energy particles
	_spawn_arena_particles(center_pos, Color(0.9, 0.1, 0.1))

func _draw() -> void:
	if not active:
		return
	# Draw translucent glowing arena boundary circle
	draw_arc(Vector2.ZERO, radius, 0, TAU, 128, Color(0.95, 0.15, 0.15, 0.85), 4.0)
	draw_circle(Vector2.ZERO, radius, Color(0.85, 0.1, 0.1, 0.08))

func _physics_process(_delta: float) -> void:
	if not active:
		return
		
	# Check if boss is dead/removed
	if not is_instance_valid(boss_node):
		deactivate()
		return
		
	# Keep player inside the circular boundary
	var player = GameManager.player
	if is_instance_valid(player):
		var dist = player.global_position.distance_to(global_position)
		if dist > radius - 20: # Keep player slightly inside boundary
			var dir = (player.global_position - global_position).normalized()
			player.global_position = global_position + dir * (radius - 20)

func deactivate() -> void:
	active = false
	visible = false
	_spawn_arena_particles(global_position, Color(0.95, 0.8, 0.2))
	queue_free()

func _spawn_arena_particles(pos: Vector2, p_color: Color) -> void:
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.amount = 48
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 90.0
	particles.initial_velocity_max = 180.0
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0
	particles.color = p_color
	
	get_parent().add_child(particles)
	particles.global_position = pos
	particles.emitting = true
	get_tree().create_timer(1.2).timeout.connect(particles.queue_free)
