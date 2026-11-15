# station_T2: R247 scale review

Refs #373. Fleet station first, T2 damaged. Run 2 delivers the requested review sheets and
scale check. Production work and installation remain open on this issue.

The station is now uniformly scaled by 1.922853 on every axis: 99.200 x 72.189 world units
in plan, 66.553 units tall. The source proportions are preserved. The old vertical-only
fit to the tallest ship plus 1 unit is removed. The long axis uses the minimum station
target in `docs/playbooks/scale.md`, 99.2 to 297.6 units. `scale.py` reads that table and
the live `godot/render/board.gd` STATION constants; `check.py` independently measures the
exported GLB against the table. It does not read its acceptance range from the fit output.

Review the camera-170 comparisons at true pixel size first. These are real Godot GPU
studio captures with the real camera rig, battle lighting and fitted ShipView geometry.
They are not a station-map battle or the production frame gate. Each picture is labelled
with station_T2 and the ship's code, at 1280 x 720. The GPU studio ran twice; the delivered
pictures are the second run. All 11 combat classes are included. Transport objectives use
combat hulls in the real rules and are not a separate combat class; squadrons are excluded.

| Class | Camera 170 picture |
|---|---|
| Frigate | [V14_23](game_compare170_frigate.png) |
| Destroyer | [V15_37](game_compare170_destroyer.png) |
| Cruiser | [V16_37](game_compare170_cruiser.png) |
| Carrier | [V18_51](game_compare170_carrier.png) |
| Battleship | [V17_37](game_compare170_battleship.png) |
| Dreadnought | [V1b_r_23](game_compare170_dreadnought.png) |
| Super-dreadnought | [H4_11](game_compare170_super_dreadnought.png) |
| Battle-barge | [C19_51](game_compare170_battle_barge.png) |
| Bio-titan | [B16_23](game_compare170_bio_titan.png) |
| Ark | [I8_37](game_compare170_ark.png) |
| Tomb-ark | [D22_23](game_compare170_tomb_ark.png) |

The [low GPU view beside V16_37](game_compare_low.png) also uses radius 170, with a lower angle.
The CPU build sheets show [camera 170](sheet_camera170.png), [beside C15s_23](sheet_compare170.png),
[low beside C15s_23](sheet_compare_low.png), [true top](sheet_top.png), [side](sheet_side.png),
[end](sheet_front.png), [underside](sheet_underside.png), [inside](sheet_inside.png) and
[overview](sheet_threequarter.png). Their four orthographic views share one scale and a
10-unit scale bar. CPU cruiser geometry is real ShipView geometry with neutral studio material.

Method: existing hand-built Hegemony station kit, modelled insides, preview materials.
The [feature table](feature_table.md), [source-hashed manifest](manifest.json),
[cost](cost.json), [fit measurements](fit.json), [real game inputs](game_inputs.json),
[GPU capture measurements](captures.json), [review checks](review_checks.json) and
[range rejection proof](range_selftest.json) are included beside the pictures.
Cost: 325,652 triangles, including 55,092 inside triangles; 20 material primitives,
11 materials and two mesh nodes in a 17,801,940-byte review GLB. No triangle cap.
GPU draw calls and the production frame gate are not measured in this review run.

The source plan fits seven real station cells across three hex columns. After uniform
scaling, 65,530 source mesh vertices extend outside the existing blocked-cell union.
This is reported rather than hidden by another fit. Live footprint integration is required
before a swap. No live STATION constant, blocked cell or scale_check KNOWN row changes here.
The station is taller than all 30 measured hulls, whose maximum height is 51.129 units.

Reproduce by double-clicking `tools/recipe/station_review.bat`. The implementation and
bake scripts are in `tools/blender/kits/hegemony_station/`; its README names each step.
The launcher requires the Board's GPU go file and fully imported PC-built ship files.
All pictures, measurements, editable blend and review GLB also remain in the required
PC folder: `C:/Users/rcbai/Downloads/voidsworn_test/board/issue-373/shots/review4/`.
The repo contains the pictures and reports, not generated models or ship assets.

Validation: the double-click launcher completed on this PC. All 30 review checks passed,
including actual exported dimensions, uniform scale, insides, lights, passive motion,
all-class coverage and unclipped GPU framing. The rejection test changed the actual GLB
while keeping its manifest and fit unchanged: 39.680-unit and 396.800-unit exports were
both refused against 99.2 to 297.6. Asset copy source: `build/godot`; all 252 shipped files
matched the tracked manifest. Texture cache copies were checked against source-image MD5s.
An early probe during import had missing textures; it was discarded and repeated cleanly. The initial sandboxed import could not save editor settings; a normal-access headless import then returned 0.

The existing headless scale check passed: 53 objects, six existing KNOWN rows, zero unexpected
failures. The document check and script/scene load check passed (191 scripts, 11 scenes, zero failures). Standing checks returned 0: 51 PASS rows and two existing KNOWN baselines.
No new look-bench baseline is accepted by this delivery.

R129 impact sweep: review helpers have only review callers; saves, profiles, rule twins and
player UI paths are untouched. No oracle copy or table refresh is needed. The branch shape
runs standing checks, Godot rules parity and Godot game checks when the runner pushes.
GitHub checks have not run during this no-commit, no-push task.

Still open under RULEBOOK 5.1 and the run 2 brief: Board sheet approval, production paint,
AI shape reference, station recipe/export support, matching live footprint, full static
fit and continuous swept-volume review, production seam and tear proof, the GPU station-map
gate at 1080p and 4K, outside check and Ryan's look. Those steps are deferred by this run's
review-only scope. Nothing is installed and issue 373 remains open.
