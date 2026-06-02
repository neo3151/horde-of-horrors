import os
from PIL import Image
import numpy as np

def transparentize_black_bg(src_path, dest_path, threshold=35):
    print(f"Processing: {src_path} -> {dest_path}")
    if not os.path.exists(src_path):
        print(f"Error: {src_path} not found!")
        return
        
    img = Image.open(src_path).convert('RGB')
    arr = np.array(img)
    h, w, c = arr.shape
    
    # BFS from borders to find background pixels
    visited = np.zeros((h, w), dtype=bool)
    queue = []
    
    def is_bg(y, x):
        r, g, b = arr[y, x]
        return r < threshold and g < threshold and b < threshold
        
    # Start BFS from all border pixels
    for y in range(h):
        for x in [0, w-1]:
            if is_bg(y, x):
                queue.append((y, x))
                visited[y, x] = True
    for x in range(w):
        for y in [0, h-1]:
            if not visited[y, x] and is_bg(y, x):
                queue.append((y, x))
                visited[y, x] = True
                
    head = 0
    while head < len(queue):
        cy, cx = queue[head]
        head += 1
        for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx]:
                if is_bg(ny, nx):
                    visited[ny, nx] = True
                    queue.append((ny, nx))
                    
    # Create RGBA image
    rgba_arr = np.zeros((h, w, 4), dtype=np.uint8)
    rgba_arr[:, :, :3] = arr
    rgba_arr[:, :, 3] = 255
    rgba_arr[visited, 3] = 0
    
    # Crop to bounding box of opaque pixels
    ys, xs = np.where(~visited)
    if len(ys) > 0:
        ymin, ymax = ys.min(), ys.max()
        xmin, xmax = xs.min(), xs.max()
        print(f"Bounding Box: y={ymin}..{ymax}, x={xmin}..{xmax} (width={xmax-xmin+1}, height={ymax-ymin+1})")
        
        # Add 1px padding to avoid edge artifacts
        ymin = max(0, ymin - 1)
        ymax = min(h - 1, ymax + 1)
        xmin = max(0, xmin - 1)
        xmax = min(w - 1, xmax + 1)
        
        cropped_arr = rgba_arr[ymin:ymax+1, xmin:xmax+1]
        out_img = Image.fromarray(cropped_arr)
    else:
        print("Warning: Entire image became transparent!")
        out_img = Image.fromarray(rgba_arr)
        
    out_img.save(dest_path)
    print(f"Successfully saved to {dest_path}\n")

if __name__ == '__main__':
    obstacle_dir = 'horde-of-horrors-godot/assets/sprites/obstacles'
    transparentize_black_bg(f'{obstacle_dir}/gravestone.png', f'{obstacle_dir}/gravestone.png')
    transparentize_black_bg(f'{obstacle_dir}/pillar.png', f'{obstacle_dir}/pillar.png')
    transparentize_black_bg(f'{obstacle_dir}/barricade.png', f'{obstacle_dir}/barricade.png')
    transparentize_black_bg(f'{obstacle_dir}/barrel.png', f'{obstacle_dir}/barrel.png')
