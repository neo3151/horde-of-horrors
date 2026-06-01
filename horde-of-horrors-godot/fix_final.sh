#!/bin/bash
ENEMIES="abyssal_horror blood_moon_cultist bone_archer crimson_harpy flesh_weaver graveyard_brute lich lich_priest nightmare_stalker the_first_one blood_golem wraith plague_doctor"

for enemy in $ENEMIES; do
    path="assets/sprites/enemies/$enemy/$enemy.png"
    if [ -f "$path" ]; then
        echo "Processing $enemy..."
        # Use imagemagick: detect bg color from top-left, flood fill remove it, crop to content, resize to 128x128
        convert "$path" \
            -fuzz 20% \
            -fill none \
            -draw "color 0,0 floodfill" \
            -trim \
            -resize 128x128\> \
            +repage \
            "$path"
        echo "Done: $enemy"
    fi
done
