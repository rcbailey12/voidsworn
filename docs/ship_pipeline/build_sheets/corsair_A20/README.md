# corsair_A20 build sheet: the Den, R244 (issue 688)

A20 now has two deep bow intakes and angular flanks. The bow housing is cut open behind the existing kit tubes, exposing their rolled lips, bolts, three stepped internal rings and dark rear baffles. The broad slab now has shoulder facets, lower chines, a recessed waist in plan and four tapered, stepped starboard armour wedges. The class length stays **16.5**; the exterior extent is exactly the same as before, **16.504628**.

Ashfall Hullbreakers carrier; game entry `data.js c_hulk`, game asset `C16s_23`. Accepted concept: `contrib/muse/design/class_family_corsair_2026_11/corsair_A20_beauty.jpg` (PR 625). Design: `tools/blender/build_sheets/ships/corsair_A20.py`. This is the CPU geometry revision requested in R244. The Board reviews the look and queues the GPU paint and game run.

## Pictures

- [Bow: concept, before and after](A20_bow_R244_before_after.jpg).
- [Side and plan: concept, before and after](A20_side_R244_before_after.jpg).
- [Whole concept and current build](beauty_vs_blockout.jpg).
- Current [bow detail](A20_bow_detail_after.jpg), [port flank](A20_flank_detail_after.jpg) and [starboard flank](A20_flank_starboard_after.jpg).

These comparisons are labeled A20 and 1280 x 720. Before and after use the same cameras and lights. They show geometry in sheet colour zones, not a new paint bake. [sheet.jpg](sheet.jpg) is the full construction sheet; [feature_table.md](feature_table.md), [inventory.md](inventory.md), [fit_view.jpg](fit_view.jpg), [fit_report.md](fit_report.md) and [manifest.json](manifest.json) are rebuilt from this design.

## Method and changes

- **Route:** hand-built faceted lofts and applied boolean cuts for the hull and bow housing; the existing Hullbreaker `parts.py` kit for both intake tubes and all machines. No new kit part or generated mesh.
- **Bow:** each tube remains a fuel and dust intake. No extra torpedo weapon or engine plume is implied. All 34 sampled bore rays used to hit the housing after 0.14 units; they now stay clear for at least 2.08 units before the dark baffles. Testing includes the interior geometry, so hidden room surfaces cannot fill the openings. The bow loot locker moved behind the wells to keep it out of both bores. See [R244_geometry.json](R244_geometry.json) and [R244_before_geometry.json](R244_before_geometry.json).
- **Flanks:** upper chamfers are 0.70 to 0.92 through the main body, with lower chines, diagonal shoulders into a waist inset 0.30 on port and 0.22 on starboard, and stepped salvage armour on starboard. Lamps, trophies, vents, breach and boarding points follow the new surfaces. The forward hangar cheeks remain the functional frames of the launch bays.
- **Inside:** full decks, bulkheads and machinery spaces remain, with 23 interior mesh objects. The crosswise bow locker sits aft of both intake wells. The three authored seams stay in their existing positions.
- **R239 and R240:** both hangar mouths still face forward beside the central bow block; their dark liners, warm deck lamps and parked craft remain. Both raised dorsal turrets remain clear of the dishes and antenna. The accepted Hullbreaker patchwork stack is unchanged.
- **Paint:** the existing `bake: stack` route and `tools/blender/kits/hullbreakers/stack.py` remain. Files under [paint/](paint/) record earlier painted hulls; they are not pictures of this R244 geometry. The Board's queued paint run replaces that evidence.

## Checks and budget

| Check | This revision |
|---|---|
| Sheet proportions (`layout.py`) | PASS; side and top length agree; class length 16.5, exterior extent unchanged |
| Fit, including 3c sensors | CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0; 368 objects, 44 parts, 18 sensor pairs |
| Inventory (`inventory.py`) | PASS, 0 failing lines |
| Build-sheet contract self-test | PASS, all 12 checks; 2 data weapon slots, 4 muzzle points, 2 turret pivots, 5 engine exits and 23 interior objects retained |
| Recipe audit and its self-test | PASS; 0 problems and 0 machines across seams; all 9 self-test cases behave correctly |
| Unpainted export and export self-test | PASS at default tolerance; 2 turret slots, 4 gun points, 5 engines, 2 bays, 7 breaches, core, 2 RCS and 2 boarding points |
| Actual bore clearance, including interiors | PASS, 34 of 34 rays; at least 2.08 clear units; interior faces do not obstruct either bore |
| Standing suite | Exit 0: 48 PASS, 2 KNOWN baseline rows, 0 FAIL, 0 SKIP; see [R244_validation.json](R244_validation.json) |
| Dedicated weapon-match checker | Absent from this checkout; contract and export checks verify both actual `turret T` slots and all four muzzles |

Before: **90,784 exterior + 708 interior = 91,492 triangles**. After: **90,450 exterior + 708 interior = 91,158 triangles**, 334 fewer. The sheet has 368 exterior mesh objects and 15 exterior material zones. The unpainted test export has 88,306 triangles in the fixed ship mesh plus 2,852 in the two turning turret meshes, also 91,158 total. It has 14 material primitives (12 fixed, one on each turret), an estimate of 14 base draws before painting. Final painted draws and the scene gate belong to the Board's GPU run. Costs are reported, not capped.

Outline overlap at the unchanged concept camera is **53.42% after, 54.06% before**, using the same largest-component luminance mask for both. This is reported, not a gate (RULEBOOK 5.8); the camera has not been refitted. [checks.json](checks.json) records the mask and view measurements. The bow tubes, hangars and prescribed game weapons are judged against the pictures and game data, not bent to raise that score.

## Reproduce

`render_R244.py` runs the shared renderer with CPU forced in memory, writes the normal views, three detail views and the bore measurements. It does not change the shared renderer or use the GPU. Use Blender 4.5.14, six CPU threads and `SHEET_SAMPLES=16`:

```
blender -b -t 6 --python-exit-code 1 -P render_R244.py -- corsair_A20 TEMP_AFTER render
```

For the before capture, set `SHIP_FILE` to a temporary copy of the design from this job's parent revision and use a separate output folder. Reset `SHIP_FILE` for the after capture. Then use Blender's bundled Python (Pillow, numpy, scipy) to assemble the sheet and comparisons in a temporary folder:

```
python assemble_R244.py TEMP_BEFORE TEMP_AFTER TEMP_SHEET
```

Copy the resulting JPG, JSON and MD artifacts into this sheet folder. Keep the raw renders, logs and temporary blends in `%TEMP%\voidsworn-688`. Review copies, including the blockout at `shots\corsair_A20\corsair_A20_blockout.blend`, are in `C:\Users\rcbai\Downloads\voidsworn_test\board\issue-688\shots`.

The checks used `sheet_contract_selftest.py`, `sheet_hull.py`, `audit.py`, `audit_selftest.py`, `export7.py unbaked=1`, `check_export.py unbaked=1`, `check_export_selftest.py unbaked=1`, `inventory.py`, `layout.py`, the renderer's bore measurements, and `node contrib/opus/tools/run_all_checks.js` with bundled Node 22. The Windows sandbox needs `NODE_OPTIONS=--preserve-symlinks --preserve-symlinks-main` for the standing runner to resolve this checkout.

GPU paint, installation, game captures and the painted scene gate were left to the Board as the brief directs. No game assets were installed by this job. No commit or push was made.
