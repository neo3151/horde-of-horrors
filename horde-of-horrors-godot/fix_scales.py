import os
import re

scenes = {
    "scenes/AlphaWerewolf.tscn": "0.12",
    "scenes/LichHighPriest.tscn": "0.12",
    "scenes/EnemyCrimsonHarpy.tscn": "0.06",
    "scenes/EnemyLichPriest.tscn": "0.06",
    "scenes/EnemyBoneArcher.tscn": "0.06",
    "scenes/EnemyGraveyardBrute.tscn": "0.06",
    "scenes/EnemyNightmareStalker.tscn": "0.06",
    "scenes/EnemyBloodMoonCultist.tscn": "0.06",
    "scenes/EnemyAbyssalHorror.tscn": "0.06",
    "scenes/EnemyFleshWeaver.tscn": "0.06",
    "scenes/EnemyTheFirstOne.tscn": "0.12"
}

for scene_path, new_scale in scenes.items():
    if os.path.exists(scene_path):
        with open(scene_path, 'r') as f:
            content = f.read()
            
        # Replace scale = Vector2(X, Y) with new scale
        content = re.sub(r'scale = Vector2\([0-9.]+, [0-9.]+\)', f'scale = Vector2({new_scale}, {new_scale})', content)
        
        with open(scene_path, 'w') as f:
            f.write(content)
        print(f"Fixed scale in {scene_path}")
