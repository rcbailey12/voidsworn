# Hegemony station kit: station_T2 run 5

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
