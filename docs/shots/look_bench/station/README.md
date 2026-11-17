# station_T2: production paint, issue 975

Issue 863 adds a separate damage-side debris kit on this painted base. Its current pictures, motion proof, triangle
cost and per-piece cell clearances are in [the debris evidence](debris_README.md). The production paint record below
belongs to issue 975 and remains the reference for the unchanged base station.

Ryan approved PR 700's T2 shape on Nov 17. Issue 975 takes that exact kit through recipe stages 5 to 7.
`design.py`, `parts.py`, towers, ring, arms, authored joints, damage and insides are unchanged. The production check
compares every evaluated vertex and triangle before and after painting, then reads the exported GLB independently.
It also compares all 697,088 world-space triangles against PR 700's actual review GLB at 0.0001 game-unit precision;
they match exactly, despite the new UV, colour and material splits.

Method: the real [Hegemony stack](../../../../tools/blender/kits/hegemony/stack.py) and shared paint machinery bake
five repeating PBR material sets, each with albedo, roughness/metalness and tangent-space detail normal. Each 2048-pixel
tile covers two game units, rather than stretching one atlas across the 99.2-unit station. Geometry-derived cavity
rays and bevel normals supply local wear, with stronger cold grime toward the damaged side. The station adapter adds
recessed service covers, flush screws, small vent slots, handling scratches and low-contrast maintenance stencils in
the normal, roughness and albedo maps. Existing hatches, pipes, window frames, docking jaws, cranes, rails and arrays
remain real geometry. No generated concept paint, random boxes or shape simplification is used.
New procedural tiles and drawn service markings are own work dedicated CC0; the bake writes their licence inventory.
Six existing outer glass faces beside the two authored core light clusters take the Hegemony `hwin` emission.
Most glazing stays dark; the one large observation pane and all 90 original marker lights remain.

Measured production cost: **697,088 triangles**, including **110,428 inside**, **12 exported surfaces**, nine materials
and two mesh nodes. Full detail ships; no geometry LOD is substituted. The approved uniform 1.919133 scale retains
the 99.200 x 70.211-unit plan and 69.281-unit height. The new optional scene cache is loaded by the actual board prop
path; the old O1_37 asset remains available as the fallback. The local cache install verifies the board's readback.

Texture density is measured from the actual exported UV and world triangle areas, not map size divided by span.
Every painted surface has a surface-area weighted density of at least **862.88 texels per game unit**. The real
installed C15s_23 cruiser, fitted by its current 23.36-unit game length, averages **42.30 texels per game unit**;
its finest triangle is **191.86**. Thus even the lowest station material mean is 20.40 times the cruiser mean and
4.50 times its finest triangle. Individual original bevel slivers can have lower triangle minima; these and every
material's measurements remain in the report. This is texture resolution, not a claim that every point contains
unique detail. The PBR tiles deliberately repeat, while modelled modules and local wear vary over the actual structure.

Reproduce by double-clicking `tools/recipe/station_paint.bat` after preparing the existing PC game assets.
It stops on a failed bake, geometry/density check, install readback, capture or station-map gate. It preserves replaced
T2 assets and caches, never deletes files, and puts scratch logs and native captures in TEMP. GPU work goes through
the watchdog; the real 20-ship scene gate uses `--map station`, 1080p frame medians and 4K GPU medians with a solo claim.
The launcher's final pass requires three sessions at each resolution below 12.5 ms and an actual installed T2 instance.

Final station-map gate: three 1080p frame medians **4.112 / 4.113 / 4.143 ms** and three 4K GPU medians
**6.639 / 6.569 / 6.565 ms**, all below 12.5 ms. The real 20-ship battle loads one installed T2, with effects, world,
HUD, MSAA 4x and full geometry. The studio visibility comparison measures **12 added visible draw calls** for the
station; the full station-map scene reports its own visible and shadow draw counts separately. The earlier cold-import
measurement is superseded by this completed-import run. Late `exterior_alpha` shader registration remains one per
mode in the existing effects path and is recorded in the gate report.

Review evidence:

- [Docking arm end, closest battle camera](station_T2_closest_docking.png).
- [Habitat drum, framed window band and authored lights](station_T2_closest_habitat.png).
- [Tower top and actual dish arrays](station_T2_closest_arrays.png).
- [Camera 170 beside the accepted T2 concept](station_T2_compare170.png).
- [Camera 60 beside the accepted T2 concept](station_T2_compare60.png).

The three close pictures are 1920 x 720 crops from native 1920 x 1080 renders, with no resizing. The camera is at the
game's actual minimum radius, 26, at pitch 0.98. The habitat view orbits 40 degrees away from the light cluster's
radial bearing to clear the intervening dish tower. A crop of the actual C15s_23 cruiser stays in the same frame at the same target depth. The wide
170 view shows the full cruiser. The 1280 x 720 overview sheets include the accepted concept as a reference;
its lens is not calibrated. The finish follows the Hegemony palette and ordered panel language and is darker and
more regular than the concept's worn pale metal. This is a visual difference for the Board's review.

Measured files: [production manifest](production_manifest.json), [geometry and density checks](production_checks.json),
[complete retained geometry](shape_preservation.json), [per-object density](station_density.json),
[camera and GPU draw measurements](production_captures.json), [station-map gate](station_gate.json),
and [texture licences](production_licences.json). The editable blend, production GLB and PBR maps stay in the task's
PC shots folder, following the existing ship-asset policy.

Validation: 63 standing PASS rows and two existing KNOWN rows; Godot loads 214 scripts and 16 scenes with zero failed;
scale check passes 54 objects outside four existing KNOWN rows; C15s_23 install readback passes; T2 board readback
passes. The double-click production route passes, including a source-verified stage-7 resume after capture target
correction. Two final capture passes retain the second set. No commit or push.

PC inputs: 246 ship files matched the tracked manifest. Six listed H10_23 files had no matching PC copy, so validation
used the current local Dominion assets/cache. The scene-gate fleet does not use H10_23. The comparison C15s_23 matches
its source manifest and installed-cache readback. No Dominion source or tracked manifest is changed by this job.

Ryan's final paint judgement and the Board's outside review remain owed. The logical seven-cell station footprint is
unchanged; the approved shape's
previously reported visual overhang remains. This paint job does not change the rules, add a debris field or certify
new tearing behavior.

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
