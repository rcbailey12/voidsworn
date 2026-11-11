# A16 and A17 measured build sheets

Issue 532. Added one consistent Blender blockout and one build sheet for each
accepted Hullbreaker concept. The sheets use clean renders, with the accepted
beauty beside them. They define a measurable proposed build; hidden machinery
remains explicitly TO BE DESIGNED. No game asset was installed. No commit or push.

| Ship | Game class length | Side / top rendered length | Difference | Outline IoU, unrounded | Fittings |
|---|---:|---|---:|---:|---:|
| corsair_A16, Warlord's Pyre-Barge | 26 units | 1,000 / 1,000 px | 0% | 90.1826% | 26 |
| corsair_A17, Pack Hunter | 14.5 units | 1,000 / 1,000 px | 0% | 91.0099% | 22 |

Lengths are read from `godot/render/hull_table.gd`, `CLS_LEN`. The feature tables
also explain `SHIP_K = 1.6`: the game draws these classes at 41.6 and 23.2 units.
The drawings and their 5-unit bars use the base class lengths above.

Files changed: `docs/ship_pipeline/build_sheets/corsair_A16/` and `corsair_A17/`
contain the sheet, five measured views, a blockout identity view, feature table,
annotated gun inventory, placement data, frozen fit, camera and check results.
`tools/recipe/build_sheets_532.bat` rebuilds both from the frozen fit. The three
Python helpers beside it implement the cutout, local shape guide, loft and socket
fit, rendering, style trial, layout and checks. This report is the other deliverable.

All PC pictures and models are below:
`C:\Users\rcbai\Downloads\voidsworn_test\board\issue-532\shots\`.

![corsair_A16 build sheet](../../../../issue-532/shots/corsair_A16_preview.jpg)

![corsair_A17 build sheet](../../../../issue-532/shots/corsair_A17_preview.jpg)

[A16 full sheet](../../../../issue-532/shots/corsair_A16_sheet.jpg),
[A17 full sheet](../../../../issue-532/shots/corsair_A17_sheet.jpg).
Both previews are 960 by 720. Full sheets are 3600 by 2700.

## One model per ship

Feature tables were drafted before geometry, then checked against close crops
and the annotated inventories. A16 has eight single mounts, five twin mounts,
one ten-mouth launcher, four visible engine units, two intakes, two dishes, two
claws and two chain runs. A17 has four single mounts, six twins, four visible
engine units, two intakes, two dishes, two claws and two chain runs. Each row
gives count, final station from the prow, signed offset, height and aim. The
major masses and schematic colour zones have a second dimension table.

The cutouts isolate the main ship, excluding the escort. Their recorded method
is a manual region, RGB maximum above 8, four-pixel closing, largest connected
component and filled holes. The gate canvas pads the original to square without
stretching it. Mask quality and proposed depth still warrant the Board's visual
review; the overlap score alone does not prove the design.

Local shape guides used the installed Microsoft TRELLIS.2-4B, seed 1234, pipeline
512, with the recipe's Windows kernel fallbacks. Both original and corrected
guides remain on the PC. Hand masses and enumerated stand-ins form the build
geometry. The recipe's `silhouette4.py` supplies camera projection and IoU.
Seven loft sections, whole-fitting translations, visible seats and a fitted
perspective camera pin the beauty comparison. A uniform final calibration puts
the complete model, fittings included, at its game class length.

Every measurement image is a fresh orthographic Blender render of that same
model, at 1200 square and ortho scale 1.2 times length. Views are pasted into the
sheet at 1:1, with only empty margins cropped. Key light is fixed forward-port,
45 degrees above; aft-starboard fill is 20% of key. Ambient fill is identical in
every view. The background is flat neutral dark grey. The blockout identity
camera is 45 degrees to port and 30 degrees above.

PC Blender files:

- [corsair_A16_blockout.blend](../../../../issue-532/shots/corsair_A16/corsair_A16_blockout.blend)
- [corsair_A17_blockout.blend](../../../../issue-532/shots/corsair_A17/corsair_A17_blockout.blend)

Each .blend contains the actual named fitting meshes and saved orthographic
cameras. No .blend, TRELLIS mesh, Godot asset, gen file or .uid is in the change.

## Local texture trial and fallback

Used `tools/pc/comfy_run.py`'s Qwen graph and runner with the installed
`qwen_image_edit_2511_fp8mixed.safetensors`, Qwen 2.5 VL text encoder,
`qwen_image_vae.safetensors`, and the free Lightning 8-step LoRA. No angle LoRA.
Image 1 was the then-current Blender top render, image 2 the accepted A16 beauty, image
3 its fixed edge guide. Seed 532, 8 steps, CFG 1, Euler, simple scheduler,
1024 square. No ControlNet weights are installed, so this was multi-reference
structure guidance, not a claimed hard ControlNet lock.

The 0.25-denoise pilot left the finish close to clay and changed small fitting
edges. Its workflow, input guides, settings, history and result are retained in
`shots/style_trial/`. The stronger 0.65 pilot added isolated wear to dishes,
rocket-rack edges and a few mounts while leaving the hull clay. Dish-feed and
small mount edges also changed. It did not establish a useful, locked dressing
pass either. Its workflow, guides, history and result remain separately in
`shots/style_trial_strong/`. Both pilots were rejected.

![corsair_A16 texture pilot](../../../../issue-532/shots/corsair_A16_style_trial_preview.jpg)

Final sheets retain the clean Blender renders. No generated result is used as a
measurement view. The method was not rolled out to all views or A17 because the
pilot did not establish both useful finish transfer and reliable structure.

## Standard fail list, checked line by line

| Failure condition | Result / evidence |
|---|---|
| Required view absent, cropped or perspective | PASS. Port profile bow left, plan bow up, underside, bow-on, engine-end inset and identity view present. Alpha bounds check finds no clipped geometry. |
| Side or top is a reprojected/traced beauty | PASS. Both are independent ORTHO camera renders of the saved model. The beauty is identity only. |
| Length or scale disagrees by more than 2% | PASS. Mesh lengths 26 and 14.5 exactly; actual side and top alpha extents both 1,000 px per ship; 0% disagreement. |
| Counts, outline or colour stations disagree across views/table | PASS for the proposed blockouts. One geometry/material set, 26/22 enumerated fittings, checked barrel counts and annotated beauty inventory. Schematic colours are not a finished paint bake. |
| Gun aft, ambiguous or shown from wrong aspect | PASS. Barrel geometry supplies the aspect and direction. All gun aim X components are positive. A16 roof rest angle is explicitly corrected from the apparent aft-facing beauty barrel. |
| Feature absent where visible without a note/inset | PASS. Far guns dashed at real profile positions and listed below; top/belly IDs, bow and stern insets expose the fitting set. Hidden lower starboard weapons, belly machinery, chain returns and exit details say TO BE DESIGNED. |
| No length, scale bar or feature table | PASS. Class length and matching 5-unit bars printed on side/top; attached tables include every enumerated mount and major mass. |
| Sea-vessel cues | PASS by visual review of these blockouts. Armoured volume, intake mouths, engine pods and boarding jaws; no keel, mast, rigging, waterline windows or naval fittings. |

The top also dimensions maximum cross-section beam and its station. The profile
dimensions hull-prow overhang and marks a continuous deck edge. Belly-only jaw
tips can project beyond the hull in plan; the belly surface stays occluded.

## Checks and limits

- `build_sheets_532.py check`: PASS for both. Tests unrounded IoU, physical
  length, rendered pixel length, shared scale, clipping, fitting presence,
  barrel counts, forward gun directions and barrel intersections with other parts.
- Frozen-fit restore followed by the same check: PASS, same scores and lengths.
- Actual `build_sheets_532.bat` with input redirected from NUL: PASS end to end,
  reusing the saved guides and fits, rendering both ships, assembling both
  sheets and passing all geometry checks.
- Python compilation: PASS. Text and path hygiene checked separately.
- `node contrib/opus/tools/run_all_checks.js`: 40 PASS, 2 KNOWN, 1 FAIL. The
  failure was `fx_death_spawn_tests`, flash root 2.094 from hull, limit 1.856.
  Focused rerun `node contrib/opus/tools/fx_death_spawn_tests.js`: PASS,
  33 pictures recorded, zero stray and zero errors. These game/test files were
  unchanged. The first full-suite failure remains reported rather than called green.

Not built: production interiors, break lines, hidden fittings, final materials
or game exports. They are outside this sheet job. Neutral engine/claw mounting
braces and the belly closure are visible placeholders, explicitly open. A17's
round forward-port fitting J1 is the written single-gun interpretation shown in
the inventory; it is not silently duplicated onto the concealed side.

The final clearance pass changed several rest aims toward the outside so their
barrels do not cut through plating, a neighbouring mount or a dish. The final
table records those directions. The automated segment/triangle check finds no
barrel intersections with another part on either ship.

Refs

- [Sheet standard](../../muse/design/concept_standard_2026_11/standard.md) and [failed-generation trial](../../muse/design/concept_standard_2026_11/trial.md)
- [Recipe](../../../docs/ship_pipeline/RECIPE.md), stages 1 to 3
- [A16 sheet and table](../../../docs/ship_pipeline/build_sheets/corsair_A16/README.md)
- [A17 sheet and table](../../../docs/ship_pipeline/build_sheets/corsair_A17/README.md)
- [A16 beauty comparison](../../../../issue-532/shots/corsair_A16_fit_compare.jpg), [A17 beauty comparison](../../../../issue-532/shots/corsair_A17_fit_compare.jpg)
- [A16 annotated inventory](../../../../issue-532/shots/corsair_A16_inventory_preview.jpg), [A17 annotated inventory](../../../../issue-532/shots/corsair_A17_inventory_preview.jpg)
- [Stronger texture trial](../../../../issue-532/shots/corsair_A16_style_strong_preview.jpg) and [both trials' settings](../../../docs/ship_pipeline/build_sheets/corsair_A16/style_trials.json)
