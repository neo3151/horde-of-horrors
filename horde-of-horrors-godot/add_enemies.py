import re

file_path = "scenes/MainGame.tscn"
with open(file_path, "r") as f:
    content = f.read()

new_resources = """[ext_resource type="PackedScene" uid="uid://enemy_crimson_harpy" path="res://scenes/EnemyCrimsonHarpy.tscn" id="101"]
[ext_resource type="PackedScene" uid="uid://enemy_lich_priest" path="res://scenes/EnemyLichPriest.tscn" id="102"]
[ext_resource type="PackedScene" uid="uid://enemy_bone_archer" path="res://scenes/EnemyBoneArcher.tscn" id="103"]
[ext_resource type="PackedScene" uid="uid://enemy_graveyard_brute" path="res://scenes/EnemyGraveyardBrute.tscn" id="104"]
[ext_resource type="PackedScene" uid="uid://enemy_nightmare_stalker" path="res://scenes/EnemyNightmareStalker.tscn" id="105"]
[ext_resource type="PackedScene" uid="uid://enemy_blood_moon_cultist" path="res://scenes/EnemyBloodMoonCultist.tscn" id="106"]
[ext_resource type="PackedScene" uid="uid://enemy_abyssal_horror" path="res://scenes/EnemyAbyssalHorror.tscn" id="107"]
[ext_resource type="PackedScene" uid="uid://enemy_flesh_weaver" path="res://scenes/EnemyFleshWeaver.tscn" id="108"]
[ext_resource type="PackedScene" uid="uid://enemy_the_first_one" path="res://scenes/EnemyTheFirstOne.tscn" id="109"]
"""

# Find the last ext_resource
last_ext_index = content.rfind("[ext_resource")
end_of_last_ext = content.find("]\n", last_ext_index) + 2

content = content[:end_of_last_ext] + new_resources + content[end_of_last_ext:]

# Update the enemy_scenes array
old_array_match = re.search(r'enemy_scenes\s*=\s*\[([^\]]+)\]', content)
if old_array_match:
    old_array = old_array_match.group(1)
    new_array = old_array + ', ExtResource("101"), ExtResource("102"), ExtResource("103"), ExtResource("104"), ExtResource("105"), ExtResource("106"), ExtResource("107"), ExtResource("108"), ExtResource("109")'
    content = content[:old_array_match.start(1)] + new_array + content[old_array_match.end(1):]

with open(file_path, "w") as f:
    f.write(content)

print("MainGame updated.")
