import os
from PIL import Image

def process_image(img_path):
    try:
        print(f"Processing: {img_path}")
        img = Image.open(img_path).convert("RGBA")
        datas = img.getdata()
        
        newData = []
        for item in datas:
            # If the pixel is very close to white, make it transparent
            # Thresholding above 240 to be safer and avoid artifacts
            if item[0] > 240 and item[1] > 240 and item[2] > 240:
                newData.append((255, 255, 255, 0))
            else:
                newData.append(item)
                
        img.putdata(newData)
        img.save(img_path, "PNG")
        print(f"Successfully processed: {img_path}")
    except Exception as e:
        print(f"Error processing {img_path}: {e}")

paths = [
    "horde-of-horrors-godot/assets/sprites/enemies/the_stitcher/the_stitcher.png",
    "horde-of-horrors-godot/assets/sprites/enemies/the_butcher_boy/the_butcher_boy.png"
]

for path in paths:
    if os.path.exists(path):
        process_image(path)
    else:
        print(f"File not found: {path}")
