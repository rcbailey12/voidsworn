# Hegemony station kit: station_T2 production paint

## Issue 863: detached damage-side debris

After installing the approved issue 975 run 3 paint, double-click `debris_run.bat` from the checkout. It builds the
part set with the T2 paint, installs `gen/ships/station_T2_debris.scn`, checks the live board, captures twice and keeps
the second pass. The final step runs the solo #207 station-map gate. `STATION_DEBRIS_RESUME=1` reuses a current build.
`STATION_DEBRIS_RULES` can point to an upcoming Godot rules file for a second clearance check in the same run.
Review pictures go to `board/issue-863/shots`. The launcher prints the TEMP folder for logs and measurements.
The install preserves replaced debris caches.

`debris.py` builds folded pressure skin with burnt backs and peeled ribs, open docking trusses with broken braces,
a split pressure pod, a torn sensor dish and fine pieces of skin and rail. The CC0 geometry uses the approved T2
Hegemony paint tiles at their two-unit repeat, with separate material tones for scorched interiors and torn edges.

`godot/render/station_debris.gd` tumbles each piece independently around a fixed centre. The live board derives the
blocked area from its station cells and shifts the group outward along the stub if a larger footprint needs room.
`debris_check.gd` reads the rules radius from `TERRAIN_META.stationR` through the battle view, with a fallback of 1.
It checks every loaded piece against every blocked cell, every station bearing and the full tumble sphere. It also checks
vertical separation from fitted roster and boss hulls and verifies the PBR channels, hashes, triangles and motion.

Review evidence and measured placement: `docs/shots/look_bench/station/debris_README.md`. The recipe entry is still
`tools/recipe/stations/station_T2.json`; the station paint route and debris route can be reproduced separately.

## Issue 975: production paint

Issue 975 authorizes painting and installing the PR 700 shape approved by Ryan Nov 17. Double-click
`tools/recipe/station_paint.bat` for the station adapter to recipe stages 5 to 7, two capture passes and the station-map
frame gate. It retains every evaluated triangle and inside, preserves replaced T2 files, and changes no rules cells.
The existing ship GLBs and import/cache files must first be present in this checkout, as for every PC look bench.

`production.py` uses the actual Hegemony faction stack and shared bake machinery for five 2048 PBR tile sets at a fixed
two-unit repeat. It adds normal/roughness service covers, flush fasteners, vents and low-contrast stencils, and masks
wear with rays against the real geometry and its bevel normals. `production_check.py` reads the exported GLB's PBR
channels, vertex colours, triangle count, bounds, animation and UV areas independently. It compares those densities
with the actual installed C15s_23 cruiser and rejects incomplete paint or lost geometry.

Run 2's `production_finish.py` configures a privately loaded Hegemony stack with T2's accepted pale and warm-metal
direction. It keeps ordered seams, blue hwin emission and no rust. The fleet stack is unchanged. Connected mesh
islands receive stable panel tones, with a minority in blue; cavity rays, the retained bevels and world-space
damaged-side soot supply wear. Fine directional residue also enters the albedo and roughness tiles. Existing
window geometry takes reflective framed glazing with a room/sill mask in hwin emission, including the broad
observation pane. Dark panels are more frequent toward the damaged side. The original 90 marker lights remain.
Solar-cell glazing stays dark. Glass filters the hwin light blue without raising its original emission peak.
The production export explicitly names `T2_geometry_wear` as `COLOR_0`. Blender's default material inference inserted
a white `COLOR_0` and put the real wear in `COLOR_1`, which Godot does not multiply into the hull. The independent
GLB check now rejects that white substitute; the actual run 1 GLB proves the rejection.

`install.gd` writes a compressed, mipmapped station cache and reads it through the board's real prop loader.
`production_capture.gd` loads that same cache, production lighting/camera and real ShipView cruiser; its closest
comparisons put the cruiser at the same camera depth as the inspected fitting. `production_pictures.py` produces
1920 x 720 crops without resizing their native 1920 x 1080 pixels, plus 1280 x 720 camera 170/60 concept comparisons.
Every review picture carries its stage, source revision and provenance sidecar. The frame gate takes a solo GPU claim
and requires three 1080p frame and 4K GPU medians below 12.5 ms on the actual 20-ship station-map scene.

Production output: the checkout's parent `issue-975/shots` folder, lane B in this run. Scratch logs and native source captures: TEMP.
The default recipe entry is `tools/recipe/stations/station_T2.json`. Do not pass it to the ship hardpoint export.
After a capture interruption, `STATION_START_STAGE=7` resumes from the painted export. The independent check first
requires its baked source hashes to match the current production, design, faction and shared paint files.
Shape review scripts below remain for reproducing PR 700. Their preview palette is not the production paint.
Run 1's five stamped pictures are retained under `docs/shots/look_bench/station/run1`. The compositor puts each
beside its run 2 counterpart, preserving native close pixels, camera settings, revision stamps and the concept views.

## PR 700 shape review route

Refs #373. Fleet station first: the abandoned T2 of Vesper Reach, accepted in R206, shape damage in R279, fine detail in R284.
T1 is a later state of this kit. The refinery T3 needs its own plan.

Double-click `review_run.bat` after copying and importing the PC ship files. Blender uses CPU Cycles with eight threads
and SHEET_DEVICE=CPU. Godot studio comparisons require the current GPU clearance. Output is
`C:/Users/rcbai/Downloads/voidsworn_test/board_b/issue-373/shots/review8/`. Set RECIPE_NOPAUSE=1 for the queue.
The launcher runs the real-rules probe, Blender sheets, review and range rejection checks, then Godot captures twice,
keeps the second set and labels the sheets. No install step is present.

Run 3 builds the damage into geometry: a seized ring with its 40-degree gap over the bent stub arm, sprung joint plates,
one of three spokes buckled inward, three intact arms and one exposed half arm without collar, three held cargo pods,
one folded plate, four core holes and a torn top drum, five damaged dead caps and four cold radiator banks. Radiator 4
hangs from one hinge and swings +/-3 degrees over 240 seconds. The ring and every other part remain static. Six scattered
clusters carry 90 blue emission markers; five dull orange strips sit at damaged frames. Production paint stays pending.

Run 5 follows Ryan R290: every fitting has a visible working purpose and a sensible mount. The kit removes the
repeated generic plant pallets. Core drums and habitat arcs carry framed EVA airlocks and round wheel hatches.
Docking corridors carry pressure hatches, connected service pipes and EVA rails; arm ends carry deep pressure
collars, clamp jaws and dark blue guide lenses. Cargo cranes and a recessed segmented cargo-bay door belong to the
docking arms. Crossed dipole sensors and dishes sit on the towers. Solar wings and cold radiator combs sit on
triangular outriggers with visible roots. Four thruster quads have open nozzles on the outer ring. The existing
three held containers, folded plate, four cold radiator banks and hanging-radiator motion remain.

All five towers are upright, retaining run 4's separate radial bridges and varied heights. Exported tower axis
nodes let the review check measure tilt. Nine pressure drums retain their varied heights and radii, window bands,
stepped shoulders and single large observation pane. No debris field is added.

Keep this placement rule for later T1 work too: a kit helper names a real machine or access fitting and emits its
parts together. Do not scatter boxes for density. `Parts.detail` measures each helper's actual emitted geometry,
with its module, function and bounds in `manifest.json`; the feature table groups that inventory. Source triangle
subtotals precede bevels; total station cost includes evaluated bevels. Native camera-60 views label the projected
face centres of those parts, with visibility rays against the actual loaded GLB. The pictures still require the Board's and Ryan's judgement on recognition and placement.

- `design.py`: source dimensions, damage locations, counts, joints, lights and motion. Its inventory follows the run 3
  brief and concept rather than the older pack's four spokes and animated tethered arm.
- `parts.py`: thick station shells, open damaged drums, annular decks, racks and ribs, bent stub and dead cap machinery.
- `stack.py`: preview palette and AO only. No production geometry-mask, trim or decal bake is claimed.
- `scale.py`: reads the range from scale.md and live STATION constants from board.gd. Uniform scale preserves proportions.
- `inspect.gd`: real BattleAPI station scenario and fitted ShipView measurements, including all flagships. Missing ships
  or incomplete imports fail before pictures. Exports actual cruiser geometry for the CPU studio.
- `review.py`: measures the actual meshes and 49 motion poses; casts through four core holes and the torn top shell;
  writes source hashes, review blend/GLB and CPU pictures. Both concept comparison directions are included.
- `check.py`: reads the table independently, measures actual exported GLB bounds, uniform transforms, light geometry,
  animated target/duration, inside triangles, shell apertures and moving vertex displacement. The run 2 coverage remains,
  with the superseded fifth tethered arm replaced by the run 3 radiator motion and four-arm inventory.
  It also measures tower separation and drum variation, and counts connected observation glazing shells in actual GLB triangles.
- `range_selftest.py`: alters real GLB scales in preserved TEMP copies with an unchanged manifest. Both out-of-range
  exports must be refused.
- `capture.gd`: isolated Godot viewport with game camera, lighting and real hulls for every combat class. This is a studio
  comparison, not the station-map performance gate. Camera 60 adds habitat, docking, power/sensor and lower thermal crops, with labelled copies from sheets.py.
- `sheets.py`: labelled 1280 x 720 pictures, concept comparisons and the generated build feature table.

The source plan fits the real seven blocked cells. R247's uniformly scaled 99.2-unit station exceeds that old footprint.
Both are measured; no live blocker constants, rules cells or scale_check KNOWN rows change. Installation still requires
matching footprint integration. Motion sampling excludes the radiator's own manifold/hinge attachment from collisions;
it tests against all other structure, not a continuous sweep or all static fit. The GLB joins static modules and does not
prove production seam export or tearing. Costs are reported without a triangle cap.

Board sheet review, production recipe/export and paint, complete fit/tear checks, station-map performance gate, outside
check and Ryan's look remain open. This kit is review evidence only under RULEBOOK 5.1.

## The outpost (issue 1791)

Ryan, Nov 24 2026 ("Yes agree on 1", "Yes outpost"): the 3-hex teaching cluster and the 1-hex station hole get a smaller
station from this kit instead of a shrunken T2; the big 19-hex cluster keeps T2 at unit scale (docs/playbooks/scale.md,
Outpost row).
- `outpost.py`: the shape. Four stacked drums, two docking arms, one dish tower, two radiators, emergency lights, all
  from `parts.py` and the Hegemony stack. Pictures only (`--out DIR`).
- `outpost_production.py`: T2's paint route on that shape: production.py's masks, glass and wear, at T2's kit-to-world
  factor, with T2's own painted tiles read from the installed station_T2.glb (`--t2-glb`). Writes station_outpost.glb.
  Its own tile bake (no `--t2-glb`) goes through the newer shared paint stack and is not the accepted T2 look.
- `outpost_install.gd`: caches gen/ships/station_outpost.scn and reads back the two small spots (they must pick it) and
  the big one (it must keep T2). a4_props.station() uses the outpost for any cluster under 19 hexes once it exists.
- The PC job (build, install, look bench props capture, nothing published) is OPUS1791_OUTPOST_<letter>.bat on the board.
