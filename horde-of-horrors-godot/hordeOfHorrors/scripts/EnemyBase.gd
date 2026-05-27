extends CharacterBody2D

@export var enemy_stats: EnemyStats

var _player: Node2D
var _attack_timer: float = 0.0

func _ready() -> void:
	# Initialize stats from the resource
	if enemy_stats:
		health = enemy_stats.health
		speed = enemy_stats.speed
		damage = enemy_stats.damage
		attack_cooldown = enemy_stats.attack_cooldown
		score_value = enemy_stats.score_value
	
	add_to_group("enemies")
	_player = GameManager.player # Get player reference from GameManager singleton

func _physics_process(delta: float) -> void:
	if _player:
		var direction = (_player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()

	_attack_timer -= delta

	# Basic attack if close enough
	if _player and global_position.distance_to(_player.global_position) < 30 and _attack_timer <= 0:
		_attack_player()
		_attack_timer = attack_cooldown

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0:
		_die()

func _attack_player() -> void:
	# GameManager.player.take_damage(damage) # Implement take_damage in PlayerController
	pass # Placeholder for actual player damage

func _die() -> void:
	GameManager.add_score(score_value)
	GameManager.add_kill()
	GameManager.emit_signal("enemy_despawned", self)
	# Replace queue_free() with PoolManager.return_instance for pooling
	# queue_free() # Remove enemy from scene

	# We should eventually pass the scene path to PoolManager, but for now we'll pass enemy_stats.enemy_name
	PoolManager.return_instance(enemy_stats.resource_path, self)

func _ready() -> void:
	add_to_group("enemies")
	_player = GameManager.player # Get player reference from GameManager singleton

func _physics_process(delta: float) -> void:
	if _player:
		var direction = (_player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()

	_attack_timer -= delta

	# Basic attack if close enough
	if _player and global_position.distance_to(_player.global_position) < 30 and _attack_timer <= 0:
		_attack_player()
		_attack_timer = attack_cooldown

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0:
		_die()

func _attack_player() -> void:
	# GameManager.player.take_damage(damage) # Implement take_damage in PlayerController
	pass # Placeholder for actual player damage

func _die() -> void:
	GameManager.add_score(score_value)
	GameManager.add_kill()
	GameManager.emit_signal("enemy_despawned", self)
	queue_free() # Remove enemy from scene
