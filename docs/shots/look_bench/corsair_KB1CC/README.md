# corsair_KB1CC paint proof

Refs #853. The accepted Wide Glacis bomber, painted with the Hullbreaker stack.
The recipe entry now selects `bake: stack`. No shape changes or game install.

Start with [the battle camera at drawn length 3.84](corsair_KB1CC_paint_cam170.jpg),
then [the concept and painted craft at the fitted concept camera](corsair_KB1CC_paint_full.jpg).
[The extra glacis view](corsair_KB1CC_paint_glacis.jpg) shows the accepted slope.
[The size comparison](corsair_KB1CC_paint_size_compare.jpg) shows the first capital
pattern beside the final craft setting, at the same camera and light.
The other sheets show the bow, middle, stern, engines and full-body paint views.
Every review picture carries the code name and is at most 720 pixels tall.
The fitted camera is nearly head-on, so the shared bow, middle and stern crop
windows overlap heavily. Use the full-body views and extra glacis view to inspect
the separate regions.

## Method and budget

Build sheet: [corsair_KB1CC](../../../ship_pipeline/build_sheets/corsair_KB1CC/README.md).
Part manifest: [manifest.json](../../../ship_pipeline/build_sheets/corsair_KB1CC/manifest.json).
The accepted sheet and manifest are unchanged. Geometry masks, the faction's own
CC0 trim and decals, and the R274 dark grey and violet trophy palette supply the
paint. The concept is never projected.

The first bake made tiny patch cells and too much bright wear on trophy plates.
`tools/blender/kits/hullbreakers/stack.py` now selects `CRAFT_SIZE` from the build
contract's sheet length, 1.6 here. Plain patch cells are three times larger,
trophy cells 1.5 times larger, scuffs and rivet pitch twice as large. Mottle, rust
blooms and wear marks are coarser. Grey trophies have less bare edge wear and no
capital trophy brightening. All settings reset before each bake; a larger ship
gets the original values exactly, also checked after selecting a craft.

Painted build: 19,080 outside triangles, 142 outside objects, four materials and
four draws after joining by material. Both atlases are 4096, with 64 samples on
OPTIX. Five small authored interior objects remain in the blend. Paint and mesh
density reports have zero flags. These are build reports, not a measured game
scene cost; no stage 6 bench or stage 7 install was requested.

## Capture

[capture.py](capture.py) runs the shared `paint_sheet.py`, including PR 845's
evaluated-bound camera clip planes, then fits the flat views to this wide craft.
It uses the sheet's fitted beauty camera and the standard game-light preview.
The battle preview uses radius 170, vertical FOV 45 and pitch 0.98 radians from
up, with drawn length 3.84. The left panel is the unscaled middle 640 by 360
pixels of a 1920 by 1080 frame; the right panel is explicitly enlarged twice.
This is a painted asset preview. The live game still draws craft in code.

Reproduce from the repo root, with raw output in a temporary folder:

```text
blender -b C:\Users\rcbai\Downloads\voidsworn_test\recipe\corsair_KB1CC\KB1CC.blend -P docs/shots/look_bench/corsair_KB1CC/capture.py -- render RAW_DIR
python docs/shots/look_bench/corsair_KB1CC/capture.py compose RAW_DIR OUT_DIR [BEFORE_RAW_DIR]
```

The PC copy of the pictures and capture evidence is in
`C:\Users\rcbai\Downloads\voidsworn_test\board\issue-853\shots`.
The recipe build, maps and full per-stage logs remain in
`C:\Users\rcbai\Downloads\voidsworn_test\recipe\corsair_KB1CC`.
The initial AI reference needed the recipe's 1024 fallback after a 1536 GPU
memory failure. It is comparison input only; the accepted sheet supplies the hull.

## Checks

PC stages 4 and 5 completed with exit 0. The build contract and audit self-tests
passed. The surface check found zero outside pixels of room colours or surfaces
without stack materials. Paint views, texture licences and lights passed, as did
`standing.py all` and the craft-selection/default-reset check.

```text
Stage 4 done: audit PASS, outline overlap reported above (not a pass bar, RULEBOOK 5.8)
PASS every standing check
```

Full stage lines are in the PC shots folder's `stage_checks.txt`.
`node contrib/opus/tools/run_all_checks.js` completed with exit 0 after the stack
change. Its two existing KNOWN rows are `findings_tests` (seven listed findings)
and `oracle_drift_guard` (12 constant differences within its baseline). The final
suite log is in the PC shots folder's `standing_suite.txt`. `git diff --check`
and the changed-text em dash scan also passed. No commits or pushes were made.
