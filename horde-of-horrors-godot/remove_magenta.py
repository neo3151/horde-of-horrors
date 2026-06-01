import os
from PIL import Image

def make_transparent(img_path):
    try:
        img = Image.open(img_path).convert("RGBA")
        datas = img.getdata()
        
        # Target magenta-ish colors
        target_colors = [
            (234, 119, 173), # Detected for dash
            (218, 46, 136),  # Detected for rapid
            (199, 51, 116),  # Detected for shield
            (211, 39, 106),  # Detected for heart
            (215, 40, 117),  # Detected for pact
            (192, 45, 129),  # Detected for crossbow
            (196, 48, 121),  # Detected for coin
            (255, 0, 255)    # Pure magenta
        ]
        
        newData = []
        for item in datas:
            is_target = False
            for target in target_colors:
                if abs(item[0] - target[0]) < 80 and \
                   abs(item[1] - target[1]) < 80 and \
                   abs(item[2] - target[2]) < 80:
                    is_target = True
                    break
            
            if is_target:
                newData.append((0, 0, 0, 0))
            else:
                newData.append(item)
                
        img.putdata(newData)
        img.save(img_path, "PNG")
        print(f"Processed: {img_path}")
    except Exception as e:
        print(f"Error processing {img_path}: {e}")

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        for path in sys.argv[1:]:
            if os.path.exists(path):
                make_transparent(path)
            else:
                print(f"File not found: {path}")
