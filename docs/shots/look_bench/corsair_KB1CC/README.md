# corsair_KB1CC paint, run 2

Refs #853. The Wide Glacis bomber now uses `bake: stack`, with rust-red armour,
dark iron framing and a few dark grey salvaged plates. No purple or pale tiles.

Start with [camera 170 at drawn length 3.84](corsair_KB1CC_paint_cam170.jpg):
the left panel keeps 1:1 pixels from a 1080p frame; the right crop is enlarged
exactly 3x with nearest-neighbour sampling. Then compare
[the concept and painted glacis](corsair_KB1CC_paint_full.jpg).
[The six views](corsair_KB1CC_paint_views.jpg) include both sides and the belly.
Every review picture carries the code name and is at most 720 pixels tall.
These are painted asset previews. The game still draws craft in code.

## Method

Build sheet: [corsair_KB1CC](../../../ship_pipeline/build_sheets/corsair_KB1CC/README.md).
Part manifest: [manifest.json](../../../ship_pipeline/build_sheets/corsair_KB1CC/manifest.json).
The accepted geometry, sheet and manifest are unchanged. Geometry masks, the
faction's own CC0 trim and decals supply the paint; no concept projection.

The run 1 `CRAFT_SIZE` switch is retained and reads the sheet's LENGTH 1.6.
Its craft setting now uses the sheet's large, uneven modelled plates and real
seams, without subdividing them again using the capital shader's patch grids.
The soot, rust and blood armour zones carry red tones; the sheet's violet zone
also becomes red. Its few pale-zone plates become R274 dark grey metal. Iron
rails, rims and frame edges stay dark iron. Less scuffing and bare edge wear
keeps small red faces from washing grey. All settings reset before each bake;
larger ships retain their original values exactly.

`capture.py` uses shared `paint_sheet.py`, including PR 845's evaluated-bound
clip planes. Only the preview camera read is overridden: azimuth 35 degrees,
elevation 30 degrees, matched by eye to the concept's above-and-three-quarter
view. The head-on outline-fit camera is unsuitable for seeing the glacis.
No design camera, geometry or saved blend is changed by the capture.
Camera 170 uses vertical FOV 45 degrees, pitch 0.98 radians from up and the
game's light and Hullbreaker albedo lift. The shared `sky_spec=0` option reflects
the dark battle sky instead of a uniform grey studio world. This is a preview,
not an install.

Painted build budget: 19,080 outside triangles, 142 outside objects, four
surfaces and four draws after joining by material. Hull and parts atlases are
4096 pixels, baked at 64 samples on OPTIX. Five authored inside objects remain.
Paint and mesh density reports have no flags. No stage 6 performance bench or
stage 7 install was requested; these are build counts, not a game cost result.

Reproduce from the repo root:

```text
blender -b C:\Users\rcbai\Downloads\voidsworn_test\recipe\corsair_KB1CC\KB1CC.blend -P docs/shots/look_bench/corsair_KB1CC/capture.py -- render RAW_DIR
python docs/shots/look_bench/corsair_KB1CC/capture.py compose RAW_DIR OUT_DIR
```

The PC review copies and evidence are saved in
`C:\Users\rcbai\Downloads\voidsworn_test\board_b\issue-853\shots`.
Raw captures and scratch logs stay in `%TEMP%\voidsworn_853_run2`.
The recipe's blend, maps and stage records remain in
`C:\Users\rcbai\Downloads\voidsworn_test\recipe\corsair_KB1CC`.

## Checks

PC stages 4 and 5 completed with exit 0. The build contract and audit
self-tests passed. The final surface check found zero outside pixels from
room colours or surfaces without stack materials. Paint views, texture
licences and lights passed, as did a final `standing.py all` readback.
The craft palette, dark collar mapping and capital default-reset check passed.
`git diff --check`, Python compilation and the changed-text em dash scan passed.

```text
Stage 4 done: audit PASS, outline overlap reported above (not a pass bar, RULEBOOK 5.8)
PASS surface check: 0 pixels of inside room colours and 0 of surfaces with no stack material seen from outside
Stage 5 done: renders in ...\recipe\corsair_KB1CC\r and ...\recipe\corsair_KB1CC\close
PASS every standing check
```

Full stage lines are in the PC shots folder's `stage_checks.txt`.
`node contrib/opus/tools/run_all_checks.js` completed with exit 0. Its two
existing KNOWN rows are `findings_tests` (seven listed findings) and
`oracle_drift_guard` (12 constant differences within the baseline). The full
suite log is in that folder's `standing_suite.txt`.
No stage 7 export or install, commits or pushes were made.
