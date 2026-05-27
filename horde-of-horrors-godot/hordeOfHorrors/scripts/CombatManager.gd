extends Node

func apply_damage(target: Node, amount: float) -> void:
	if target and target.has_method("take_damage"):
		target.take_damage(amount)

func spawn_projectile(projectile_scene: PackedScene, start_position: Vector2, target_position: Vector2, speed: float, damage: float, pierce_count: int = 0) -> void:
	var projectile = PoolManager.get_instance(projectile_scene.resource_path)
	if projectile:
		projectile.global_position = start_position
		# Calculate direction and set velocity
		var direction = (target_position - start_position).normalized()
		projectile.velocity = direction * speed
		projectile.damage = damage
		projectile.pierce_count = pierce_count
		get_tree().current_scene.add_child(projectile) # Add to current scene

func perform_melee_attack(attacker: Node, target: Node, damage: float) -> void:
	if attacker and target and target.has_method("take_damage"):
		target.take_damage(damage)

func check_death(target: Node) -> void:
	if target and target.has_method("get_health") and target.get_health() <= 0:
		target.die()
