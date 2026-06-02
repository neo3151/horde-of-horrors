import os
from PIL import Image, ImageDraw

def create_montage():
    src_path = "/home/neo/.gemini/antigravity/scratch/horde-of-horrors/horde-of-horrors-godot/assets/sprites/enemies/alpha_werewolf.png"
    if not os.path.exists(src_path):
        print("Source image not found!")
        return
        
    img = Image.open(src_path)
    w, h = img.size
    cols, rows = 8, 8
    cw, ch = w // cols, h // rows
    
    # Create a copy to draw grid lines on
    montage = img.copy().convert("RGB")
    draw = ImageDraw.Draw(montage)
    
    # Draw red grid lines
    for r in range(rows + 1):
        y = r * ch
        if y >= h: y = h - 1
        draw.line([(0, y), (w, y)], fill=(255, 0, 0), width=2)
    for c in range(cols + 1):
        x = c * cw
        if x >= w: x = w - 1
        draw.line([(x, 0), (x, h)], fill=(255, 0, 0), width=2)
        
    dest_path = "/home/neo/.gemini/antigravity-ide/brain/e7c35fb0-7ad8-45ac-982e-7722359aac2b/alpha_werewolf_grid.png"
    montage.save(dest_path)
    print(f"Montage saved to {dest_path}")

if __name__ == "__main__":
    create_montage()
