import os
from PIL import Image

sprites_dir = "assets/sprites/enemies"

def remove_white_background(img_path):
    img = Image.open(img_path).convert("RGBA")
    datas = img.getdata()
    
    new_data = []
    # Tolerance for white
    for item in datas:
        # change all white (also shades of whites)
        # to transparent
        if item[0] > 220 and item[1] > 220 and item[2] > 220:
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append(item)
            
    img.putdata(new_data)
    
    # Save as PNG
    new_path = img_path
    if img_path.lower().endswith(".jpeg") or img_path.lower().endswith(".jpg"):
        new_path = img_path.rsplit('.', 1)[0] + '.png'
        
    img.save(new_path, "PNG")
    print(f"Processed {new_path}")

# Find all new sprites
targets = [
    "crimson_harpy/crimson_harpy.png",
    "lich_priest/lich_priest.png",
    "bone_archer/bone_archer.png",
    "graveyard_brute/graveyard_brute.png",
    "nightmare_stalker/nightmare_stalker.png",
    "blood_moon_cultist/blood_moon_cultist.png",
    "abyssal_horror/abyssal_horror.png",
    "flesh_weaver/flesh_weaver.png",
    "the_first_one/the_first_one.png"
]

for target in targets:
    path = os.path.join(sprites_dir, target)
    if os.path.exists(path):
        remove_white_background(path)


# Process boss sprites too
boss_targets = [
    "alpha_werewolf.png",
    "lich/lich.png"
]

for target in boss_targets:
    path = os.path.join(sprites_dir, target)
    if os.path.exists(path):
        remove_white_background(path)

