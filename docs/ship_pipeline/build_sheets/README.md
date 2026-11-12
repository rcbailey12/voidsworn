# Build sheets (issue 532, R203, R207, R209)

One folder per ship. Each sheet is built from ONE Blender blockout: every orthographic view (side, top, underside, bow-on,
engine end, the INSIDE cutaway) is a render of that one model at one scale (80 px per world unit), so the views agree by
construction. The feature table is written by the same model, and on counts it outranks the pictures.

| Ship | Sheet | Table |
|---|---|---|
| corsair_A16, Warlord's Pyre-Barge | [sheet](corsair_A16/sheet.jpg) | [feature_table.md](corsair_A16/feature_table.md) |
| corsair_A17, Hullbreaker wrecker (Pack Hunter) | [sheet](corsair_A17/sheet.jpg) | [feature_table.md](corsair_A17/feature_table.md) |

How it is made (tools/blender/build_sheets/):

1. `ships/<code>.py` is the design: hull loft sections, every fitting with its mount, the insides, hard points, colour
   zones, the "Changed from the picture" list. `kit.py` turns it into simple stand-in meshes.
2. `fit.py` scores the blockout's outline against the accepted beauty at a camera fitted to it (plain python: numpy, scipy,
   Pillow), and writes the camera to `ships/<code>_camera.json`. The camera is fitted, never the ship.
3. `build.py` (Blender 4.5 on the PC, `render_sheets.bat`) renders every view, the cutaway and the fitted beauty camera,
   writes `<code>_model.json` and saves the blockout .blend.
4. `layout.py` measures length, beam and height off the renders themselves, annotates every view from the model and writes
   the sheet, the 720 px preview, `feature_table.md` and `checks.json`.

The .blend files stay on the PC: `C:\Users\rcbai\Downloads\voidsworn_test\opus532\<code>\<code>_blockout.blend`.
