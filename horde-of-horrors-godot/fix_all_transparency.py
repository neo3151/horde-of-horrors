import os
import glob
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

# Find all pngs in all subdirectories of assets/sprites/enemies
for img_path in glob.glob("assets/sprites/enemies/**/*.png", recursive=True):
    # Only process if it's not the alpha_werewolf (which is in the root of enemies/)
    # Wait, actually process everything just in case, but alpha_werewolf is already transparent?
    process_image(img_path)

