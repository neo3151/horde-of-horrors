import os
import glob

# The new sub_resource block and updated Sprite2D node
SHADER_SUB_RESOURCE = '[sub_resource type="ShaderMaterial" id="RemoveBgMat"]\nresource_local_to_scene = true\nshader = ExtResource("bg_shader")\nshader_parameter/bg_color = Color(0.88, 0.88, 0.88, 1)\nshader_parameter/tolerance = 0.22\n\n'

SHADER_EXT_RESOURCE = '[ext_resource type="Shader" path="res://assets/shaders/remove_bg.gdshader" id="bg_shader"]\n'

# Enemies that use AI-generated sprites needing bg removal
targets = [
    "scenes/EnemyLichPriest.tscn",
    "scenes/EnemyBoneArcher.tscn",
    "scenes/EnemyGraveyardBrute.tscn",
    "scenes/EnemyNightmareStalker.tscn",
    "scenes/EnemyBloodMoonCultist.tscn",
    "scenes/EnemyAbyssalHorror.tscn",
    "scenes/EnemyFleshWeaver.tscn",
    "scenes/EnemyTheFirstOne.tscn",
    "scenes/EnemyCrimsonHarpy.tscn",
    "scenes/EnemyLich.tscn",
    "scenes/EnemyWraith.tscn",
    "scenes/EnemyPlagueDoctor.tscn",
    "scenes/EnemyBloodGolem.tscn",
]

for scene_path in targets:
    if not os.path.exists(scene_path):
        print(f"SKIP (not found): {scene_path}")
        continue

    with open(scene_path, 'r') as f:
        content = f.read()

    # Skip if already patched
    if "bg_shader" in content:
        print(f"Already patched: {scene_path}")
        continue

    # 1. Add the shader ext_resource after the first [ext_resource line
    first_ext = content.find('[ext_resource')
    content = content[:first_ext] + SHADER_EXT_RESOURCE + content[first_ext:]

    # 2. Insert the ShaderMaterial sub_resource before the first [node
    first_node = content.find('[node')
    content = content[:first_node] + SHADER_SUB_RESOURCE + content[first_node:]

    # 3. Add material to the Sprite2D node
    content = content.replace(
        '[node name="Sprite2D" type="Sprite2D" parent="Visuals"]\nuse_parent_material = true',
        '[node name="Sprite2D" type="Sprite2D" parent="Visuals"]\nmaterial = SubResource("RemoveBgMat")'
    )

    with open(scene_path, 'w') as f:
        f.write(content)
    print(f"Patched: {scene_path}")

