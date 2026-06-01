import os
import glob
import re

for scene_path in glob.glob("scenes/*.tscn"):
    with open(scene_path, 'r') as f:
        content = f.read()
    
    original_content = content
    # Remove all uid="uid://... " from Texture2D
    content = re.sub(r'\[ext_resource type="Texture2D" uid="uid://[^"]+" path="([^"]+)" id="([^"]+)"\]', r'[ext_resource type="Texture2D" path="\1" id="\2"]', content)
    
    if content != original_content:
        with open(scene_path, 'w') as f:
            f.write(content)
        print(f"Fixed UIDs in {scene_path}")
