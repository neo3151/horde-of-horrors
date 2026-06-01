import os

enemies = [
    {"name": "CrimsonHarpy", "id": "crimson_harpy", "type": 8},
    {"name": "LichPriest", "id": "lich_priest", "type": 9},
    {"name": "BoneArcher", "id": "bone_archer", "type": 10},
    {"name": "GraveyardBrute", "id": "graveyard_brute", "type": 11},
    {"name": "NightmareStalker", "id": "nightmare_stalker", "type": 12},
    {"name": "BloodMoonCultist", "id": "blood_moon_cultist", "type": 13},
    {"name": "AbyssalHorror", "id": "abyssal_horror", "type": 14},
    {"name": "FleshWeaver", "id": "flesh_weaver", "type": 15},
    {"name": "TheFirstOne", "id": "the_first_one", "type": 16}
]

template = """[gd_scene load_steps=5 format=3 uid="uid://enemy_{id}"]

[ext_resource type="Script" path="res://scripts/Enemy.gd" id="1"]
[ext_resource type="Shader" path="res://assets/shaders/hit_flash.gdshader" id="2"]
[ext_resource type="Texture2D" uid="uid://{id}_tex" path="res://assets/sprites/enemies/{id}/{id}.png" id="3"]

[sub_resource type="ShaderMaterial" id="ShaderMaterial_1"]
resource_local_to_scene = true
shader = ExtResource("2")
shader_parameter/active = false
shader_parameter/flash_color = Color(1, 1, 1, 1)

[sub_resource type="CircleShape2D" id="CircleShape2D_1"]
radius = 16.0

[sub_resource type="CircleShape2D" id="CircleShape2D_2"]
radius = 18.0

[node name="Enemy" type="CharacterBody2D" groups=["enemy"]]
collision_layer = 2
collision_mask = 1
script = ExtResource("1")
type = {type}

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_1")

[node name="Visuals" type="Node2D" parent="."]
material = SubResource("ShaderMaterial_1")

[node name="Sprite2D" type="Sprite2D" parent="Visuals"]
use_parent_material = true
unique_name_in_owner = true
texture = ExtResource("3")
scale = Vector2(0.55, 0.55)

[node name="Body" type="Polygon2D" parent="Visuals"]
use_parent_material = true
color = Color(0.8, 0.2, 0.2, 1)
polygon = PackedVector2Array(-10, -10, 10, -10, 12, 12, -12, 12)

[node name="Features" type="Polygon2D" parent="Visuals"]
use_parent_material = true
color = Color(0.1, 0.1, 0.1, 0.5)
polygon = PackedVector2Array(-5, -5, 5, -5, 5, 5, -5, 5)

[node name="Area2D" type="Area2D" parent="."]
collision_layer = 2
collision_mask = 1

[node name="CollisionShape2D2" type="CollisionShape2D" parent="Area2D"]
shape = SubResource("CircleShape2D_2")

[connection signal="body_entered" from="Area2D" to="." method="_on_body_entered"]
"""

for enemy in enemies:
    filename = f"scenes/Enemy{enemy['name']}.tscn"
    content = template.format(id=enemy['id'], type=enemy['type'])
    with open(filename, "w") as f:
        f.write(content)
    print(f"Created {filename}")

