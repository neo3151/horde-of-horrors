import re

with open('scripts/Enemy.gd', 'r') as f:
    content = f.read()

# Increase flash duration
content = content.replace('await get_tree().create_timer(0.08).timeout', 'await get_tree().create_timer(0.12).timeout')

# Add camera shake and blood splatter in take_damage
take_damage_original = """    current_health -= amount
    _flash()"""
take_damage_new = """    current_health -= amount
    _flash()
    
    # Spawn blood splatter on hit
    var splatter_scene = load("res://scenes/BloodSplatter.tscn")
    if splatter_scene:
        var splatter = splatter_scene.instantiate()
        get_parent().add_child(splatter)
        splatter.global_position = global_position
        splatter.rotation = randf_range(0, 2 * PI)
        splatter.emitting = true
        
    # Camera shake on hit
    if GameManager.player and GameManager.player.has_method("shake_camera"):
        GameManager.player.shake_camera(3.0, 0.1)"""
content = content.replace(take_damage_original, take_damage_new)

# Add blood splatter and bigger camera shake in _die
die_original = """    # Spawn floor blood puddle decal
    var decal_scene = load("res://scenes/BloodDecal.tscn")"""
die_new = """    # Bigger camera shake on death
    if GameManager.player and GameManager.player.has_method("shake_camera"):
        GameManager.player.shake_camera(6.0, 0.2)
        
    # Extra blood splatter on death
    var splatter_scene = load("res://scenes/BloodSplatter.tscn")
    if splatter_scene:
        for i in range(2):
            var splatter = splatter_scene.instantiate()
            get_parent().add_child(splatter)
            splatter.global_position = global_position
            splatter.rotation = randf_range(0, 2 * PI)
            splatter.scale = Vector2(1.5, 1.5)
            splatter.emitting = true

    # Spawn floor blood puddle decal
    var decal_scene = load("res://scenes/BloodDecal.tscn")"""
content = content.replace(die_original, die_new)

with open('scripts/Enemy.gd', 'w') as f:
    f.write(content)
print("Modified Enemy.gd with VFX")
