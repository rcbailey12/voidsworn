#!/bin/sh
# Rebuilds the #271 round 2 mockups from the repo root: sh contrib/opus/ui271_mockups/r2/make2.sh
# Needs python3 with Pillow, OpenCV and Playwright (Chromium). Writes into a temp folder; copy the results by hand.
set -e
W=$(mktemp -d); H=contrib/opus/ui271_mockups
cp $H/style.css $H/r2/index2.html $H/r2/style2.css $H/r2/mock2.js $H/r2/pieces.html $H/r2/pieces2.js "$W"/
cp godot/ui/battle/fonts/*.ttf godot/ui/campaign/fonts/*.ttf "$W"/
cp godot/portraits/crests/faction_voidsworn.svg godot/portraits/crests/faction_corsair.svg "$W"/
cp godot/portraits/nemesis/pool/nem_corsair_1.webp "$W"/nem.webp
python3 -c "from PIL import Image; Image.open('docs/shots/ship_pipeline/bench207/scene_engagement.webp').convert('RGB').save('$W/src.png')"
python3 $H/build_bg.py "$W/src.png" "$W/bg.png"
python3 $H/r2/render2.py "$W" "$W" stress:C:b
python3 $H/r2/render2.py "$W" "$W" pieces
python3 $H/r2/sheet2.py "$W"
echo "mockups in $W"
