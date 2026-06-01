import re
import random

with open('scenes/MainGame.tscn', 'r') as f:
    lines = f.readlines()

new_lines = []
skip = False
for line in lines:
    if '[node name="ColorRect" type="ColorRect"' in line:
        skip = True
    elif skip and line.startswith('color = Color'):
        skip = False
        continue
    
    if not skip:
        new_lines.append(line)

content = "".join(new_lines)

# 1. Add graveyard props resource
resource_str = '[ext_resource type="Texture2D" uid="uid://graveyard_props" path="res://assets/sprites/environment/graveyard_props.png" id="8_props"]\n'
content = content.replace('[ext_resource type="Texture2D" uid="uid://floortile01"', resource_str + '[ext_resource type="Texture2D" uid="uid://floortile01"')

# 2. Y-Sort the main scene
content = content.replace('[node name="MainGame" type="Node2D"]', '[node name="MainGame" type="Node2D"]\ny_sort_enabled = true')

# 3. Add props scattered around
props_nodes = "\n[node name=\"Props\" type=\"Node2D\" parent=\".\"]\ny_sort_enabled = true\n"

# Tree region roughly (0, 0, 480, 500), but looking at the atlas, let's just make arbitrary props with region rects
# The atlas is 1024x1024. Tree is top left.
for i in range(15):
    x = random.randint(-400, 400)
    y = random.randint(-400, 400)
    # Gravestone
    props_nodes += f"""
[node name="Prop_Grave_{i}" type="Sprite2D" parent="Props"]
position = Vector2({x}, {y})
texture = ExtResource("8_props")
region_enabled = true
region_rect = Rect2(44, 638, 225, 305)
"""

for i in range(5):
    x = random.randint(-400, 400)
    y = random.randint(-400, 400)
    # Dead Tree
    props_nodes += f"""
[node name="Prop_Tree_{i}" type="Sprite2D" parent="Props"]
position = Vector2({x}, {y})
texture = ExtResource("8_props")
region_enabled = true
region_rect = Rect2(10, 20, 450, 600)
"""

content = content.replace('[node name="AmbientParticles"', props_nodes + '\n[node name="AmbientParticles"')

# 4. Give player a PointLight2D. Wait, player is in Player.tscn.
# Let's just modify the CanvasModulate to make it darker
content = content.replace('color = Color(0.35, 0.35, 0.45, 1)', 'color = Color(0.2, 0.2, 0.3, 1)')

with open('scenes/MainGame.tscn', 'w') as f:
    f.write(content)
print("Map updated")
