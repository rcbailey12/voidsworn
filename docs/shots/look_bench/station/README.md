# station_T2: run 5 working station details

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
