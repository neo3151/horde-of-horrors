#!/bin/bash
# Original sprites that are still large 1024x1024 or similar
declare -A SPRITE_PATHS
SPRITE_PATHS["ghost"]="assets/sprites/ghost/ghost.png"
SPRITE_PATHS["werewolf"]="assets/sprites/werewolf/werewolf.png"
SPRITE_PATHS["vampire"]="assets/sprites/vampire/vampire.png"
SPRITE_PATHS["frankenstein"]="assets/sprites/frankenstein/frankenstein.png"

for enemy in "${!SPRITE_PATHS[@]}"; do
    path="${SPRITE_PATHS[$enemy]}"
    if [ -f "$path" ]; then
        SIZE=$(python3 -c "from PIL import Image; img=Image.open('$path'); print(img.size)")
        echo "Processing $enemy ($SIZE)..."
        convert "$path" \
            -fuzz 20% \
            -fill none \
            -draw "color 0,0 floodfill" \
            -trim \
            -resize 128x128\> \
            +repage \
            "$path"
        echo "Done: $enemy"
    else
        echo "SKIP: $path not found"
    fi
done
