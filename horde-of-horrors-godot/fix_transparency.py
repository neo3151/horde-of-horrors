import os
from PIL import Image

def process_image(img_path):
    try:
        img = Image.open(img_path).convert("RGBA")
        datas = img.getdata()
        
        newData = []
        for item in datas:
            # If the pixel is very close to white, make it transparent
            if item[0] > 220 and item[1] > 220 and item[2] > 220:
                newData.append((255, 255, 255, 0))
            else:
                newData.append(item)
                
        img.putdata(newData)
        img.save(img_path, "PNG")
        print(f"Processed: {img_path}")
    except Exception as e:
        print(f"Error processing {img_path}: {e}")

enemies = [
    "crimson_harpy", "lich_priest", "bone_archer", "graveyard_brute",
    "nightmare_stalker", "blood_moon_cultist", "abyssal_horror", "flesh_weaver",
    "the_first_one", "lich"
]

for enemy in enemies:
    path = f"assets/sprites/enemies/{enemy}/{enemy}.png"
    if os.path.exists(path):
        process_image(path)

