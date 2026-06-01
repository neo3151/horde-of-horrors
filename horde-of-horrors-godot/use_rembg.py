import os
from rembg import remove
from PIL import Image
import sys

def process_rembg(img_path):
    try:
        input_image = Image.open(img_path)
        output_image = remove(input_image)
        output_image.save(img_path)
        print(f"Processed with rembg: {img_path}")
    except Exception as e:
        print(f"Error processing {img_path}: {e}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        for path in sys.argv[1:]:
            if os.path.exists(path):
                process_rembg(path)
            else:
                print(f"File not found: {path}")
