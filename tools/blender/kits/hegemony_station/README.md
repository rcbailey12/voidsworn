# Hegemony station kit: station_T2 run 4

Refs #373. Fleet station first: the abandoned T2 of Vesper Reach, accepted in R206, shape damage in R279, fine detail in R284.
T1 is a later state of this kit. The refinery T3 needs its own plan.

Double-click `review_run.bat` after copying and importing the PC ship files. Blender uses CPU Cycles with eight threads
and SHEET_DEVICE=CPU. Godot studio comparisons require the current GPU clearance. Output is
`C:/Users/rcbai/Downloads/voidsworn_test/board_b/issue-373/shots/review7/`. Set RECIPE_NOPAUSE=1 for the queue.
The launcher runs the real-rules probe, Blender sheets, review and range rejection checks, then Godot captures twice,
keeps the second set and labels the sheets. No install step is present.

Run 3 builds the damage into geometry: a seized ring with its 40-degree gap over the bent stub arm, sprung joint plates,
one of three spokes buckled inward, three intact arms and one exposed half arm without collar, three held cargo pods,
one folded plate, four core holes and a torn top drum, five damaged dead caps and four cold radiator banks. Radiator 4
hangs from one hinge and swings +/-3 degrees over 240 seconds. The ring and every other part remain static. Six scattered
clusters carry 90 blue emission markers; five dull orange strips sit at damaged frames. Production paint stays pending.

Run 4 keeps those breaks and the uniform 99.2-unit span. Ryan R284 asks for fine detail rather than big new blocks:
use small connected plant pallets, pipes, hatches, vents, cable runs and antenna heads across core, ring and arms.
The five tower mounts now stand around the hub on separate radial service bridges, with different heights and caps;
only the tallest leans five degrees. Nine pressure drums vary in height and radius, joined by recessed necks, with dark
glazing bands and sparse light markers. One continuous large observation pane is the only large lit window. Six short
ring service fingers include three small cooling combs. No debris field is added; that belongs to the later debris job.

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
  comparison, not the station-map performance gate. Camera 60 adds a partial close view of the fine fittings.
- `sheets.py`: labelled 1280 x 720 pictures, concept comparisons and the generated build feature table.

The source plan fits the real seven blocked cells. R247's uniformly scaled 99.2-unit station exceeds that old footprint.
Both are measured; no live blocker constants, rules cells or scale_check KNOWN rows change. Installation still requires
matching footprint integration. Motion sampling excludes the radiator's own manifold/hinge attachment from collisions;
it tests against all other structure, not a continuous sweep or all static fit. The GLB joins static modules and does not
prove production seam export or tearing. Costs are reported without a triangle cap.

Board sheet review, production recipe/export and paint, complete fit/tear checks, station-map performance gate, outside
check and Ryan's look remain open. This kit is review evidence only under RULEBOOK 5.1.
