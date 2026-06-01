import os
import re

scenes = [
    "scenes/EnemyCrimsonHarpy.tscn",
    "scenes/EnemyLichPriest.tscn",
    "scenes/EnemyBoneArcher.tscn",
    "scenes/EnemyGraveyardBrute.tscn",
    "scenes/EnemyNightmareStalker.tscn",
    "scenes/EnemyBloodMoonCultist.tscn",
    "scenes/EnemyAbyssalHorror.tscn",
    "scenes/EnemyFleshWeaver.tscn",
    "scenes/EnemyTheFirstOne.tscn",
    "scenes/EnemyLich.tscn"
]

for scene_path in scenes:
    if os.path.exists(scene_path):
        with open(scene_path, 'r') as f:
            content = f.read()
            
        # Remove uid="uid://..._tex" from Texture2D lines
        content = re.sub(r'\[ext_resource type="Texture2D" uid="uid://[^"]+" path="([^"]+)" id="([^"]+)"\]', r'[ext_resource type="Texture2D" path="\1" id="\2"]', content)
        
        with open(scene_path, 'w') as f:
            f.write(content)
        print(f"Fixed UIDs in {scene_path}")
