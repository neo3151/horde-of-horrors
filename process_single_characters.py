import os
from PIL import Image
import numpy as np

def clean_and_center_character(path, is_serena):
    print(f"Processing: {path}")
    img = Image.open(path).convert('RGB')
    arr = np.array(img)
    h, w, c = arr.shape
    
    # 1. Define candidate check and exact grid check
    if is_serena:
        def is_candidate(r, g, b):
            if abs(int(r) - int(g)) > 10 or abs(int(g) - int(b)) > 10 or abs(int(r) - int(b)) > 10:
                return False
            return abs(int(r) - 136) <= 25 or abs(int(r) - 188) <= 25
            
        def matches_grid(y, x, r, g, b):
            if not is_candidate(r, g, b):
                return False
            sq = int(y / 32) + int(x / 32)
            expected = 188 if sq % 2 == 0 else 135
            return abs(int(r) - expected) <= 15
    else:
        def is_candidate(r, g, b):
            diff_a = max(abs(int(r) - 207), abs(int(g) - 215), abs(int(b) - 222))
            diff_b = max(abs(int(r) - 244), abs(int(g) - 249), abs(int(b) - 253))
            return diff_a <= 20 or diff_b <= 20
            
        def matches_grid(y, x, r, g, b):
            sq = int(y / 20.48) + int(x / 20.48)
            if sq % 2 == 0:
                expected = (207, 215, 222)
            else:
                expected = (244, 249, 253)
            diff = max(abs(int(r) - expected[0]), abs(int(g) - expected[1]), abs(int(b) - expected[2]))
            return diff <= 15

    # 2. Find all candidate background pixels
    candidate_mask = np.zeros((h, w), dtype=bool)
    for y in range(h):
        for x in range(w):
            r, g, b = arr[y, x]
            if is_candidate(r, g, b):
                candidate_mask[y, x] = True
                
    # 3. Find connected components of candidate pixels
    visited = np.zeros((h, w), dtype=bool)
    transparent_mask = np.zeros((h, w), dtype=bool)
    
    for y in range(h):
        for x in range(w):
            if candidate_mask[y, x] and not visited[y, x]:
                # Start BFS to find the connected component
                component = []
                queue = [(y, x)]
                visited[y, x] = True
                
                head = 0
                while head < len(queue):
                    cy, cx = queue[head]
                    head += 1
                    component.append((cy, cx))
                    for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                        ny, nx = cy + dy, cx + dx
                        if 0 <= ny < h and 0 <= nx < w and candidate_mask[ny, nx] and not visited[ny, nx]:
                            visited[ny, nx] = True
                            queue.append((ny, nx))
                            
                # Analyze the component
                N = len(component)
                M = 0
                touches_border = False
                
                for cy, cx in component:
                    if cy == 0 or cy == h-1 or cx == 0 or cx == w-1:
                        touches_border = True
                    r, g, b = arr[cy, cx]
                    if matches_grid(cy, cx, r, g, b):
                        M += 1
                        
                match_rate = M / N
                is_bg = touches_border or (match_rate >= 0.60)
                
                if is_bg:
                    for cy, cx in component:
                        transparent_mask[cy, cx] = True

    # 4. Create temporary RGBA array with background removed
    rgba_arr = np.zeros((h, w, 4), dtype=np.uint8)
    rgba_arr[:, :, :3] = arr
    rgba_arr[:, :, 3] = 255
    rgba_arr[transparent_mask, 3] = 0
    
    # 5. BFS from center to isolate character from border noise
    start_y, start_x = None, None
    for r in range(0, min(h, w) // 2):
        cy, cx = h // 2, w // 2
        for dy, dx in [(-r, -r), (-r, r), (r, -r), (r, r)]:
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < h and 0 <= nx < w and rgba_arr[ny, nx, 3] > 0:
                start_y, start_x = ny, nx
                break
        if start_y is not None:
            break
        for i in range(-r+1, r):
            for ny, nx in [(cy - r, cx + i), (cy + r, cx + i), (cy + i, cx - r), (cy + i, cx + r)]:
                if 0 <= ny < h and 0 <= nx < w and rgba_arr[ny, nx, 3] > 0:
                    start_y, start_x = ny, nx
                    break
            if start_y is not None:
                break
        if start_y is not None:
            break
            
    if start_y is None:
        raise ValueError("Could not find any foreground pixel near the center!")
        
    visited_fg = np.zeros((h, w), dtype=bool)
    visited_fg[start_y, start_x] = True
    queue_fg = [(start_y, start_x)]
    
    head = 0
    while head < len(queue_fg):
        cy, cx = queue_fg[head]
        head += 1
        for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < h and 0 <= nx < w and not visited_fg[ny, nx]:
                if rgba_arr[ny, nx, 3] > 0:
                    visited_fg[ny, nx] = True
                    queue_fg.append((ny, nx))
                    
    # Zero out anything not in the character component
    rgba_arr[~visited_fg, 3] = 0
    
    # Find bounding box
    ys, xs = np.where(visited_fg)
    ymin, ymax = ys.min(), ys.max()
    xmin, xmax = xs.min(), xs.max()
    cw, ch = xmax - xmin + 1, ymax - ymin + 1
    print(f"Isolated bounding box: y={ymin}..{ymax}, x={xmin}..{xmax} (width={cw}, height={ch})")
    
    # Crop character
    char_crop = Image.fromarray(rgba_arr).crop((xmin, ymin, xmax + 1, ymax + 1))
    
    # Scale proportionally to fit target dimensions
    target_canvas_size = (256, 512)
    target_ymax = 480
    max_w = 240
    max_h = 340
    
    scale = min(max_w / cw, max_h / ch)
    new_w = int(round(cw * scale))
    new_h = int(round(ch * scale))
    print(f"Resizing to: width={new_w}, height={new_h}")
    
    char_resized = char_crop.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    # Place on target canvas
    canvas = Image.new('RGBA', target_canvas_size, (0, 0, 0, 0))
    paste_x = (target_canvas_size[0] - new_w) // 2
    paste_y = target_ymax - new_h
    canvas.paste(char_resized, (paste_x, paste_y))
    
    # Save image
    canvas.save(path)
    print(f"Successfully processed and saved transparent centered character at: {path}\n")

if __name__ == '__main__':
    clean_and_center_character('horde-of-horrors-godot/assets/sprites/player/serena/serena.png', is_serena=True)
    clean_and_center_character('horde-of-horrors-godot/assets/sprites/player/victor/victor.png', is_serena=False)
