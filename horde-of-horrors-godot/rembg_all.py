from rembg import remove
from PIL import Image
import os

enemies = [
    ("assets/sprites/enemies/lich_priest/lich_priest.png", "lich_priest"),
    ("assets/sprites/enemies/wraith/wraith.png", "wraith"),
    ("assets/sprites/enemies/plague_doctor/plague_doctor.png", "plague_doctor"),
    ("assets/sprites/enemies/blood_golem/blood_golem.png", "blood_golem"),
    ("assets/sprites/enemies/crimson_harpy/crimson_harpy.png", "crimson_harpy"),
    ("assets/sprites/enemies/bone_archer/bone_archer.png", "bone_archer"),
    ("assets/sprites/enemies/graveyard_brute/graveyard_brute.png", "graveyard_brute"),
    ("assets/sprites/enemies/nightmare_stalker/nightmare_stalker.png", "nightmare_stalker"),
    ("assets/sprites/enemies/blood_moon_cultist/blood_moon_cultist.png", "blood_moon_cultist"),
    ("assets/sprites/enemies/abyssal_horror/abyssal_horror.png", "abyssal_horror"),
    ("assets/sprites/enemies/flesh_weaver/flesh_weaver.png", "flesh_weaver"),
    ("assets/sprites/enemies/the_first_one/the_first_one.png", "the_first_one"),
    ("assets/sprites/enemies/lich/lich.png", "lich"),
    ("assets/sprites/ghost/ghost.png", "ghost"),
]

for path, name in enemies:
    if not os.path.exists(path):
        print(f"SKIP: {path}")
        continue
    print(f"Processing {name}...")
    inp = Image.open(path)
    out = remove(inp)
    out.save(path)
    print(f"Done: {name}")

print("All done!")
