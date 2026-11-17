# station_T2: run 2 paint and lights, issue 975

Ryan returned PR 977's paint because it read as grey clay. This run retains PR 700's shape and the run 1 live swap,
then changes the finish: worn pale and warm metal, darker structural bands, a minority of blue panels, lit blue
window bands and cold damaged-side grime. [Build sheet and retained inventory](feature_table.md).

The missing local variation had an export cause. Blender's material-inferred export inserted a white `COLOR_0`
and stored the real geometry wear in `COLOR_1`. Godot uses `COLOR_0`. The station export now explicitly names
`T2_geometry_wear`; the independent GLB check rejects a white substitute. The actual run 1 GLB is rejected by that
check. The painted GLB now retains the measured RGB range, not only the presence of a colour attribute.

Method: [production_finish.py](../../../../tools/blender/kits/hegemony_station/production_finish.py) configures a
privately loaded [Hegemony stack](../../../../tools/blender/kits/hegemony/stack.py) for the accepted T2 beauty's
pale/warm metal direction. The shared PBR bake, ordered grid, no-rust treatment and Hegemony hwin emission stay.
The fleet stack is unchanged. Connected mesh islands receive stable panel tones, including their bevel faces.
Real station cavity rays, retained bevels and directional world-space soot vary the finish over the damaged side;
finer streaks also enter the albedo and roughness tiles. Service-cover seams, flush screws, vent slots, scratches
and maintenance stencils remain. All new maps are procedural own work, dedicated CC0; no concept is projected.

Existing glazing now carries reflective blue glass and framed room/sill masks in hwin emission. Most bands are lit,
with more dark gaps on the damaged side: 4,424 lit and 1,168 dark original glazing faces, across the drums,
observation pane, ring and docking lenses. Counts include the skins and edges, not individual rooms. The broad
observation pane has the same window treatment. Solar-cell glazing stays dark. All 90 original marker lights remain
in place, with dark blue lenses and the original 0.60 peak filtered blue so the key no longer turns them into white
cards. The original five battery strips, insides, damage, joints and hanging-radiator motion remain.

Measured installed cost: **697,088 triangles**, including **110,428 inside**, **12 surfaces**,
**9 materials** and **2 mesh nodes**. Full detail ships; no geometry LOD is substituted.
The station adds **12 visible draw calls** in the same-camera visibility probe. Scale remains uniformly 1.919133,
with a 99.200 x 70.211-unit plan and 69.281-unit height. Every world-space triangle and authored joint matches PR 700's
actual review GLB at 0.0001 game-unit precision. No geometry, board cells, rules or footprint code is changed.
Ryan's 19-cell footprint choice is separate work in issue 983.

Five 2048 PBR tile sets still repeat every two game units. Actual exported UV/world triangle areas give a lowest
material mean of **862.88 texels per game unit**, against the real fitted C15s_23
cruiser's **42.30** mean and **191.86**
finest triangle. The station's lowest material mean is 20.40 times the cruiser mean.
Individual bevel sliver minima remain reported. These are repeating detail tiles, not unique station-wide atlases.

Final 20-ship station-map gate, solo GPU claim: 1080p frame medians **8.082 / 9.822 / 9.124 ms**;
4K GPU medians **7.136 / 7.201 / 7.296 ms**. All six pass 12.5 ms, with one installed T2, effects, world, HUD and MSAA 4x.
An earlier run missed at 12.508 ms at 1080p; its [retained report](station_gate_contention.json) is preserved.
The unchanged gate was rerun after a separate headless import finished. The scene report includes visible and shadow draw counts. Existing late `exterior_alpha` registration is recorded
separately; it is not counted as a new station shader. Prepared rock caches are present for this final measurement.

Review the same cameras beside run 1, with each source revision and stage retained:

- [Camera 170 before and after, each beside the accepted concept](station_T2_before_after_compare170.png).
- [Camera 60 before and after, each beside the accepted concept](station_T2_before_after_compare60.png).
- [Docking arm end, closest battle camera](station_T2_before_after_closest_docking.png).
- [Habitat drum and window bands, closest battle camera](station_T2_before_after_closest_habitat.png).
- [Tower top and arrays, closest battle camera](station_T2_before_after_closest_arrays.png).

The close comparisons are 3840 x 720: two 1920 x 720 crops, with native 1080p pixels retained 1:1. No close image is
resized. Camera radius 26, pitch 0.98, targets, orbit angles, battle lighting and same-depth cruiser placement are
unchanged. Overview pairs are 2560 x 720. The five stamped [run 1 pictures](run1/station_T2_compare60.png) remain
under `run1/`. Current single views are [docking](station_T2_closest_docking.png),
[habitat](station_T2_closest_habitat.png), [arrays](station_T2_closest_arrays.png),
[camera 170](station_T2_compare170.png) and [camera 60](station_T2_compare60.png).

Compared with the accepted concept, the paint now has pale/warm panel families, dark bands and visible blue glazing.
The preserved model still has broader regular rims and a more ordered panel pattern than the concept. Its key-lit
rim metal is cleaner than the concept's most battered surfaces. These are visual limits for the Board's and Ryan's
review, not a claim of visual acceptance.

Reproduce with `tools/recipe/station_paint.bat`: stages 5 to 7, independent export/density/shape checks, preservation
of replaced assets, board-loader readback, two capture passes retaining the second, stamped comparisons and the
station-map gate. Output goes to the checkout parent's `issue-975/shots`; logs and native renders stay in TEMP.
The editable blend, production GLB and maps remain PC assets under the existing ship-asset policy.

Evidence: [production manifest](production_manifest.json), [independent checks](production_checks.json),
[retained geometry](shape_preservation.json), [per-object density](station_density.json),
[cameras and draw measurements](production_captures.json), [station-map gate](station_gate.json),
and [CC0 texture inventory](production_licences.json).

Validation: production route passes, including the corrected named-colour export and source-hash checks; old run 1
export rejected for lost wear; 63 standing PASS rows and two existing KNOWN rows; Godot loads 214 scripts and 16 scenes
with zero failures. The initial diagnostic captures exposed the lost-colour export and were replaced by the corrected
second-pass evidence. No commit or push.

PC inputs: 246 ship files match the tracked manifest. The same six H10_23 files as run 1 have no matching PC copy;
current local Dominion assets/cache are used, and the scene-gate fleet does not use H10_23. C15s_23 matches the source
manifest and supplies the measured cruiser comparison. No tracked ship manifest is changed. Editor-generated import
setting edits were preserved in TEMP and restored, keeping this delivery within the paint job.

## PR 700 geometry record

The following records the run 5 shape review before production painting. Its review-only stage descriptions and costs
belong to that earlier export; use the production section above for the current route.

## station_T2: run 5 working station details

Refs #373. Fleet station first. Ryan R290 asks for purposeful station details and upright towers.
Run 4's spread towers, varied drums and single large window remain, along with run 3's breaks and uniform R247 scale.

Review camera 170 at native size first, then the comparisons and labelled camera-60 crops:

- [Camera 170 beside a cruiser](game_compare170_cruiser.png). The full set includes all 11 combat classes.
- [Accepted T2 beauty beside the build](T2_beauty_compare.png). Direction matched by eye; no calibrated concept lens.
- [Directly above beside the accepted plan](T2_plan_compare.png).
- [Habitat and EVA access, camera 60](game_detail60_labelled.png).
- [Docking and cargo handling, camera 60](game_detail60_docking_labelled.png).
- [Power and sensors, camera 60](game_detail60_systems_labelled.png).
- [Lower thermal and attitude systems, camera 60](game_detail60_thermal_labelled.png).
- [Solar power outriggers, camera 60](game_detail60_power_labelled.png).
- [Low camera beside a cruiser](game_compare_low.png) and [open insides](sheet_inside.png).

All five tower axes are upright. Their bases, heights and cap families retain the spread arrangement from run 4.
The kit removes generic plant pallets and unexplained raised blocks. Drums and habitat arcs carry framed EVA
airlocks and wheel hatches. Docking arms carry corridor collars, service pipes and handrails; arm ends carry deep
berth collars, clamp jaws and dark blue guide lenses. Two arm-mounted cargo cranes have trussed jibs and grapples;
the wide docking arm carries a recessed segmented cargo bay door. Tower-mounted dipoles and dishes have visible
stand-offs and feed struts. Six triangular ring outriggers carry three solar wings and three cold radiator combs.
Four ring attitude quads have four open cold nozzles apiece. Radiator pumps have cylinders, flanges and headers.

Each new kit fitting records the actual vertices, faces and bounds it emits, plus its function and parent module.
The feature table groups those measurements. The labelled crops use emitted face centres and visibility rays
against collision meshes made from the loaded review GLB, rejecting anchors hidden behind other structure.
These labels help inspection; recognition and sensible placement still require the Board's and Ryan's look.

The seized ring keeps its 40-degree gap over the bent stub, five sprung plates and one buckled spoke. Three held
pods and one folded plate remain attached; no debris field is added. Four side holes and the torn top expose decks,
frames and machinery. Radiator 4 hangs from one hinge and swings +/-3 degrees over 240 seconds. It is the only moving
part. Six scattered clusters retain 90 blue emission markers and five dull orange battery strips. No red. Preview
materials only; the guide lenses are dark on this abandoned station, and there is exactly one large lit window.

Reproduce with `tools/recipe/station_review.bat`, calling the kit's `review_run.bat`. Blender uses CPU Cycles with
eight threads and SHEET_DEVICE=CPU. The watchdog controls GPU claims for the Godot captures under gpu_go.txt.
The real-rules/ShipView probe loads 30 hulls. The launcher builds and measures the meshes, checks the exported GLB,
rejects both altered scale cases, captures twice and keeps the second set, then labels the sheets.

All linked pictures, measured reports, editable blend and review GLB are saved in
`C:/Users/rcbai/Downloads/voidsworn_test/board_b/issue-373/shots/review8/`. Earlier reviews are preserved.
Pictures and reports are copied beside this README; every image is 1280 x 720. Godot pictures use actual fitted
ShipView hulls, game cameras and battle lighting in an isolated studio. They are not station-map performance evidence.
Bake and capture scripts remain under `tools/blender/kits/hegemony_station/`.

Method and budget: [build sheet](feature_table.md), [source-hashed manifest](manifest.json), [mesh and motion report](fit.json),
[export cost](cost.json), [review checks](review_checks.json), [range rejection proof](range_selftest.json),
[real inputs](game_inputs.json) and [camera framing and visible label anchors](captures.json).
Triangles are reported without a cap. Total cost includes evaluated bevels, insides and the moving radiator;
the detail inventory's subtotals count source faces before bevels. GPU draws and station-map time remain unmeasured.

Measured cost: 697,088 triangles, including 110,428 inside; 16 GLB material primitives, 13 materials and 2 mesh nodes. Span 99.200 x 70.211 units; height 69.281. Uniform scale 1.919133 on all axes. No triangle cap.

Validation: the unchanged double-click launcher exits 0. All 40 station review checks pass, including zero measured tilt on all five exported tower axes, one connected observation pane, five open shell apertures, 49 collision-free radiator poses and visible label samples for all 17 fitting types. Both out-of-range GLB cases are rejected. Two final Godot capture passes cover all 11 combat classes, the low view and five camera-60 crops. Standing suite: exit 0, 58 PASS rows and two existing KNOWN rows. Godot scale: exit 0, 53 objects, six existing KNOWN rows. Documentation, picture, source-hash, scope, whitespace and no-em-dash checks pass. All 35 delivered pictures match the shots folder at 1280 x 720; JSON mirrors and local links pass.

This checkout arrived with the original partial review. Run 4's station files were recovered from 4b7b744a1 before
run 5 edits; only task files were recovered. PC hulls came from build/godot; all 252 files matched the tracked manifest.
Missing hull import caches also came from that PC build. The fresh headless import completed successfully, and the
probe's import and placeholder guards remained enabled. Scratch logs stay in TEMP. GitHub CI awaits the runner.

The source plan fits the seven real blocked cells. Uniform R247 scale overhangs the old live footprint, so live
footprint integration remains open. Live board constants and scale_check KNOWN rows remain unchanged. Forty-nine
radiator poses allow its own hinge contact; they do not certify a continuous sweep or complete static fit.
The review GLB joins static modules and does not prove production tearing.

R129 sweep: callers remain inside the station review kit and launcher. Saves, old profiles, rule twins and UI paths
are untouched, so no oracle copy or table refresh is needed. The runner's eventual push runs standing checks,
Godot rules parity and Godot game checks. No commit or push was made by this task.

Review only. Production mask/trim paint, production recipe/export support, full fit and tear checks, live footprint
integration, station-map scene gate, outside check and Ryan's look remain pending before installation. Ryan has not
reviewed run 5 during this task. The separate debris job remains later.
