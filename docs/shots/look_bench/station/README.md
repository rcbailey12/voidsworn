# station_T2: run 3 module paint and attached wreckage, issue 975

Ryan asked for a station-wide method correction after run 2's random plate colours, plain black tower, blue patch and
loose square debris. This run replaces that method across the station. The accepted layout, scale, insides, module joints,
90 marker lights, five battery strips, lit window bands and hanging-radiator motion remain. Footprint and rules belong to 983.

Issue 863 adds a separate damage-side debris kit on this painted base. Its current pictures, motion proof, triangle
cost and per-piece cell clearances are in [the debris evidence](debris_README.md). The production paint record below
belongs to issue 975 and remains the reference for the unchanged base station.

Method: [build sheet and inventory](feature_table.md), [production manifest](production_manifest.json),
[station recipe entry](../../../../tools/recipe/stations/station_T2.json). The PR 700 kit goes through stages 5 to 7 using
[production.py](../../../../tools/blender/kits/hegemony_station/production.py) and the private
[station Hegemony configuration](../../../../tools/blender/kits/hegemony_station/production_finish.py).
The fleet and other factions' stacks are unchanged. All maps are procedural own work, dedicated CC0; no concept is projected.

The tone hierarchy is now module, structural zone, then plate. Complete modules receive pale metal, warm tan, steel or
Hegemony blue from the accepted beauty's palette. Core drum, habitat and tower families are explicit in `module_family`;
arm 2 and two complete service fingers carry blue. Structural bands are darker, edge metal lighter, secondary panels only
slightly lower in value. Each connected plate varies +/-1.5 percent in value within its module family. The privately loaded
stack disables the inherited patchwork, object-random tone, mottle and colour grain. No single plate randomly becomes blue
or tan. The manifest records every module's chosen family.

Cylindrical UVs follow core drums and towers; other faces keep physical box coordinates. The five 2048 metal PBR sets still
repeat every two game units. Every zone now has structural seams, maintenance covers, flush fasteners, vent slots, detail
normals and varying roughness. Seam dirt shoulders, vent-origin residue and service-cover scuffs make the detail readable
at the native closest camera. Actual station cavity rays, existing bevels and continuous damaged-side exposure control
local grime and worn edges. There is no per-plate random weather colour. Dark liner roughness has a readable metal range.

Every exported material was fixed, not only the highlighted tower:

| Material | Run 3 correction |
|---|---|
| `T2_painted_hgrey` | Calm module base; service covers, seam dirt, vent trails and scuffs |
| `T2_painted_hpanel` | Small value step within the same family; full hull PBR detail |
| `T2_painted_htrim` | Structural band tone; seams, handling wear, flush bolts and vent slots |
| `T2_painted_hmetal` | Machined edge metal with non-flat albedo, normal and roughness detail |
| `T2_painted_dark` | Readable liner, deck and rack metal; full panel, access and grime stack replaces the plain black fields |
| `T2_glass_lit` | Real-size repeating frames, mullions, dark room silhouettes, reflective variation and frame relief |
| `T2_glass_dark` | Same glazing detail with reduced emission, including the cold solar cells |
| `T2_marker_lens` | Replaces flat `T2_blue` cards with face-fitted bezels, recessed ribbed lenses and masked blue emission |
| `T2_battery_strip` | Replaces flat `T2_battery` material with a face-fitted bezel, ribbed lens and full PBR maps |

Glazing repeats at .50 by .48 game units in actual surface UVs, instead of stretching one room grid over a pane. The large
observation pane keeps its existing pressure-frame geometry and gains texture mullions, reflections and a dark interior.
Marker and battery faces each fit one complete lens. Glazing stays opaque to avoid sorting the nested pressure shells.
The unchanged geometry has 4,424 lit and 1,528 dark original glazing faces; these count skins and edges,
not individual rooms. Solar cells remain dark. All nine materials have non-flat albedo, normal and roughness maps.

[production_check.py](../../../../tools/blender/kits/hegemony_station/production_check.py) reads the actual GLB, including
exported `_T2_MODULE` identities, rather than accepting the presence of a texture node. It checks each material's decoded
maps and samples textured albedo on 267 module/material combinations. A missing detail map, a flat albedo map and flat
albedo across a module are each planted and rejected by name in [the independent report](production_checks.json).
The named `T2_geometry_wear` export remains `COLOR_0`; a white substitute still fails.

## Loose-piece inventory and the allowed geometry repair

The original build and the repaired build are compared before painting. Only 32 named exterior source meshes differ;
357 other meshes and every inside mesh match. Paint changes no geometry. [The source comparison](shape_preservation.json)
and independent exported comparison retain the original bounds and authored joints. Of the prior GLB's 697,088 triangles,
696,746 remain identical at 0.0001-unit precision. Only 342 old triangles are replaced; the attached replacements and feet
add 5,770, for a net 5,428. No geometry LOD or interior reduction is substituted.

Every former loose sheet has a continuous attachment root, thick bent skins, jagged distal edges and exposed frame ribs.
The report lists the 18 measured replacement assemblies, their bounds and source triangles. They replace 19 old sheets:

| Original piece IDs | What they became |
|---|---|
| `core_03`, minus-side and plus-side peeled teeth | Two torn sheets rooted at the existing breach |
| `core_05`, minus-side and plus-side peeled teeth | Two torn sheets rooted at the existing breach |
| `core_07`, minus-side and plus-side peeled teeth | Two torn sheets rooted at the existing breach |
| `core_08`, minus-side and plus-side peeled teeth | Two torn sheets rooted at the existing breach |
| `core_09`, minus-side and plus-side top-rim slabs | Two attached torn rim sheets with bent frame ribs |
| `habitat_1_slot_00`, sprung bearing sheet | Torn hinged joint cover seated on the bearing top |
| `habitat_2_slot_02`, sprung bearing sheet | Torn hinged joint cover seated on the bearing top |
| `habitat_3_slot_05`, sprung bearing sheet | Torn hinged joint cover seated on the bearing top |
| `habitat_5_slot_08`, sprung bearing sheet | Torn hinged joint cover seated on the bearing top |
| `habitat_6_slot_10`, sprung bearing sheet | Torn hinged joint cover seated on the bearing top |
| `tower_1`, left and right pad leaves | Two joined buckled sheets, torn edges and ribs; four feet seat them on the cap |
| `folded_plate`, both walkway leaves | One connected folded torn assembly rooted on the existing arm roof, with two brackets |

The attachment sweep also seats all 66 existing ring roof stiffeners: crossbeam indices 0 to 5 on each of slots
00, 01, 02, 03, 04, 05, 06, 07, 08, 09 and 10, in their existing `habitat_N_slot_XX` modules. Each now has two short
welded feet from the roof to the beam. `spoke_3` tread plates 0 to 9 retain their shapes and gain two braces each to the
existing buckled truss. Cargo pods already have ribs and cradle struts; solar cells have backing plates and trusses;
radiator fins meet their headers; pressure doors, racks and hatches are functional parts. Those shapes remain unchanged.
There is no new debris field and no footprint, board-cell or rules edit.

## Installed measurements

| Measurement | Run 3 |
|---|---|
| Triangles, full detail | 702,516, including 110,428 inside |
| Surfaces / materials / mesh nodes | 12 / 9 / 2 |
| Visible station draw-call delta | 12 at every one of the seven views |
| Scale and dimensions | Uniform 1.919133; 99.200 x 70.211 plan, 69.281 height, unchanged |
| Lowest material mean texture density | 862.88 texels per game unit |
| Actual fitted C15s_23 cruiser density | 42.30 mean; 191.86 finest triangle, texels per game unit |
| Station minimum mean / cruiser mean | 20.40 times finer |
| Station-map 1080p frame medians | 7.917 / 6.907 / 5.652 ms |
| Station-map 4K GPU medians | 6.938 / 6.913 / 6.915 ms |

All six final medians pass 12.5 ms. The unchanged 20-ship station-map gate runs with one installed T2, effects, world, HUD,
MSAA 4x and a solo GPU claim. The final timing follows completion of the standing CPU fixture tests. Individual UV sliver
minima and visible/shadow draw counts remain reported, never capped. These are repeated detail tiles, not unique atlases.

## Same-camera pictures beside run 2

- [Camera 170, run 2 and run 3, each beside the accepted concept](station_T2_before_after_compare170.png).
- [Camera 60, run 2 and run 3, each beside the accepted concept](station_T2_before_after_compare60.png).
- [Docking arm end, closest camera, run 2 and run 3](station_T2_before_after_closest_docking.png).
- [Habitat and window bands, closest camera, run 2 and run 3](station_T2_before_after_closest_habitat.png).
- [Tower arrays, closest camera, run 2 and run 3](station_T2_before_after_closest_arrays.png).
- [Tall tower, closest camera](station_T2_closest_tall_tower.png).
- [Habitat top deck and attached torn rim, closest camera](station_T2_closest_top_deck.png).

Close views retain native 1920x1080 render pixels in 1920x720 crops, with the real fitted C15s_23 cruiser at the same depth.
Pairs are 3840x720; concept-comparison pairs are 2560x720. No close image is resized. A readback comparison verifies the
same radius, alpha, pitch, FOV, target and cruiser position on all five shared cameras. Closest radius is 26, pitch .98.
Every image names station_T2, its source revision/working digest and installed stage. Both capture passes ran; only the
second is presented. The five original [run 2 pictures](run2/station_T2_closest_habitat.png) and their sidecars are retained.
Current single views: [docking](station_T2_closest_docking.png), [habitat](station_T2_closest_habitat.png),
[arrays](station_T2_closest_arrays.png), [170](station_T2_compare170.png), [60](station_T2_compare60.png).

The accepted beauty still has more irregular exposed structure and finer silhouette breaks. The retained kit has broader,
more regular rims and repeated modules. This run fixes the station-wide finish and loose sheets within that shape; the
pictures and numeric checks are submitted for the Board's and Ryan's visual review, not a claim of their acceptance.

Reproduce with `tools/recipe/station_paint.bat`. It bakes the private stack, checks the GLB and density, preserves replaced
assets, installs and verifies the board loader, captures twice, stamps the comparisons and runs the station-map gate.
Stage 7 may resume with `STATION_START_STAGE=7`; `STATION_BASELINE` can name a retained prior GLB for the independent
world-space comparison. No commit or push was made. PC blend, GLB and maps stay outside git under the existing asset policy.

Evidence: [manifest](production_manifest.json), [checks and planted faults](production_checks.json),
[geometry comparison](shape_preservation.json), [density](station_density.json), [cameras and draws](production_captures.json),
[station gate](station_gate.json), [CC0 inventory](production_licences.json).

Validation: final production route passes; nine detailed materials and all 267 module/material samples pass; all three
planted faults fail; all five shared cameras match; all 17 new/current and retained run 2 pictures verify and are at most
720 pixels high. Godot loads 215 scripts and 16 scenes with zero failures. Standing suite: 62 PASS, two existing KNOWN,
one existing FAIL. The failure is untouched FINDINGS row R317, whose `landed in LOOP.md` points to a missing root file;
`contrib/opus/LOOP.md` is the actual file. HEAD has the same row. That unrelated memory correction is left to the Board.

PC inputs: 246 ship files match the tracked manifest. The six H10_23 files still lack matching local copies, as in run 2;
current local Dominion assets/cache are used, and the measured fleet does not use H10_23. C15s_23 matches the tracked
manifest. The fresh checkout's missing generated manifest and caches were supplied from the PC build; the placeholder
and import guards stayed enabled. Editor-generated import-setting edits were preserved in TEMP and restored. Scratch
logs and native renders stay in TEMP; final stamped pictures and sidecars are also in the required issue-975 shots folder.

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
