import re

with open('scenes/Player.tscn', 'r') as f:
    content = f.read()

light_node = """
[node name="PointLight2D" type="PointLight2D" parent="."]
energy = 0.8
texture_scale = 3.0
"""
# I need a gradient texture for the light, or I can use a built-in radial gradient.
# Let's create a GradientTexture2D for the light.
gradient_resource = """
[sub_resource type="Gradient" id="Gradient_Light"]
offsets = PackedFloat32Array(0, 1)
colors = PackedColorArray(1, 1, 1, 1, 0, 0, 0, 1)

[sub_resource type="GradientTexture2D" id="GradientTexture2D_Light"]
gradient = SubResource("Gradient_Light")
fill = 1
fill_from = Vector2(0.5, 0.5)
fill_to = Vector2(0.8, 0.8)
"""

content = content.replace('[node name="Player" type="CharacterBody2D"]', gradient_resource + '\n[node name="Player" type="CharacterBody2D"]')

light_node_full = """
[node name="PointLight2D" type="PointLight2D" parent="."]
energy = 0.8
texture_scale = 4.0
texture = SubResource("GradientTexture2D_Light")
"""

content = content.replace('[node name="Sprite" type="Sprite2D"', light_node_full + '\n[node name="Sprite" type="Sprite2D"')

with open('scenes/Player.tscn', 'w') as f:
    f.write(content)
print("Player updated with light")
