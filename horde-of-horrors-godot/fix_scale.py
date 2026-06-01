import os
import glob
import re

for scene_path in glob.glob("scenes/Enemy*.tscn"):
    with open(scene_path, 'r') as f:
        content = f.read()
    
    # Increase scale from anything around 0.06 or 0.1 to 0.18
    # Wait, let's just find scale = Vector2(0.06, 0.06)
    content = content.replace("scale = Vector2(0.06, 0.06)", "scale = Vector2(0.18, 0.18)")
    
    with open(scene_path, 'w') as f:
        f.write(content)
    print(f"Fixed scale in {scene_path}")
