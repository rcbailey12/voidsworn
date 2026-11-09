#!/bin/sh
# Rebuilds the #271 identity mockups from the repo root: sh contrib/opus/ui271_mockups/identity/make_id.sh
# Needs python3 with Pillow, OpenCV and Playwright (Chromium). Writes into a temp folder; copy the results by hand.
set -e
W=$(mktemp -d); H=contrib/opus/ui271_mockups/identity
cp $H/index_id.html $H/base.css $H/identity.css $H/mock_id.js "$W"/
cp -r $H/fonts "$W"/fonts
cp godot/portraits/crests/faction_voidsworn.svg godot/portraits/crests/faction_corsair.svg "$W"/
cp godot/portraits/nemesis/pool/nem_corsair_1.webp "$W"/nem.webp
python3 -c "from PIL import Image; Image.open('docs/shots/ship_pipeline/bench207/scene_engagement.webp').convert('RGB').save('$W/src.png')"
python3 $H/build_bg.py "$W/src.png" "$W/bg.png"
python3 $H/render_id.py "$W" "$W"
python3 $H/sheet_id.py "$W"
echo "mockups in $W"
