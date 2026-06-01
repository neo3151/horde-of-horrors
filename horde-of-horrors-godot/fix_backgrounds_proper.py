import glob
import numpy as np
from PIL import Image
from collections import deque

def remove_background_floodfill(img_path, tolerance=30):
    """Use flood-fill from all 4 corners to cleanly remove the background."""
    img = Image.open(img_path).convert("RGBA")
    arr = np.array(img)
    h, w = arr.shape[:2]
    
    # Sample background color from corners (average them)
    corners = [arr[0,0,:3], arr[0,w-1,:3], arr[h-1,0,:3], arr[h-1,w-1,:3]]
    bg_color = np.mean(corners, axis=0)
    
    visited = np.zeros((h, w), dtype=bool)
    queue = deque()
    
    # Seed from all 4 edges
    for x in range(w):
        queue.append((0, x))
        queue.append((h-1, x))
    for y in range(h):
        queue.append((y, 0))
        queue.append((y, w-1))
    
    while queue:
        y, x = queue.popleft()
        if y < 0 or y >= h or x < 0 or x >= w:
            continue
        if visited[y, x]:
            continue
        pixel = arr[y, x, :3].astype(float)
        dist = np.sqrt(np.sum((pixel - bg_color) ** 2))
        if dist > tolerance:
            continue
        visited[y, x] = True
        arr[y, x, 3] = 0  # Make transparent
        queue.append((y+1, x))
        queue.append((y-1, x))
        queue.append((y, x+1))
        queue.append((y, x-1))
    
    result = Image.fromarray(arr)
    result.save(img_path, "PNG")
    print(f"Fixed: {img_path} (bg_color≈{bg_color.astype(int)})")

enemies = [
    "abyssal_horror", "blood_moon_cultist", "bone_archer", "crimson_harpy",
    "flesh_weaver", "graveyard_brute", "lich", "lich_priest",
    "nightmare_stalker", "the_first_one", "blood_golem", "wraith", "plague_doctor"
]

for enemy in enemies:
    path = f"assets/sprites/enemies/{enemy}/{enemy}.png"
    import os
    if os.path.exists(path):
        remove_background_floodfill(path)

