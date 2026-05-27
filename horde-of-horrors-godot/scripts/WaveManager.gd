extends Node2D

@export var enemy_scenes: Array[PackedScene] = []
@export var spawn_rate: float = 1.2
@export var base_enemies_per_wave: int = 6

var active_enemies: Array = []
var enemies_to_spawn: int = 0
var next_spawn_time: float = 0.0

func start_wave(wave_number: int) -> void:
    enemies_to_spawn = base_enemies_per_wave + (wave_number - 1) * 4
    active_enemies.clear()
    next_spawn_time = Time.get_ticks_msec() / 1000.0 + 1.0

func _process(delta: float) -> void:
    if enemies_to_spawn <= 0 and active_enemies.size() == 0:
        GameManager.next_wave()
        return

    if enemies_to_spawn > 0 and Time.get_ticks_msec() / 1000.0 >= next_spawn_time:
        _spawn_enemy()
        next_spawn_time = Time.get_ticks_msec() / 1000.0 + spawn_rate

    # Clean null references
    active_enemies = active_enemies.filter(func(e): return is_instance_valid(e))

func _spawn_enemy() -> void:
    if enemy_scenes.is_empty():
        return

    var spawn_pos = _get_random_spawn_position()
    var index = randi() % enemy_scenes.size()
    var enemy = enemy_scenes[index].instantiate()
    add_child(enemy)
    enemy.global_position = spawn_pos
    active_enemies.append(enemy)
    enemies_to_spawn -= 1
    GameManager.emit_signal("enemy_spawned", enemy)

func _get_random_spawn_position() -> Vector2:
    var x = randf_range(-420, 420)
    var y = 320 if randf() > 0.5 else -320
    if randf() > 0.5:
        x = 420 if randf() > 0.5 else -420
        y = randf_range(-280, 280)
    return Vector2(x, y)

func get_nearest_enemy(from_pos: Vector2) -> Node2D:
    var nearest = null
    var min_dist = INF
    for e in active_enemies:
        if not is_instance_valid(e):
            continue
        var d = from_pos.distance_to(e.global_position)
        if d < min_dist:
            min_dist = d
            nearest = e
    return nearest