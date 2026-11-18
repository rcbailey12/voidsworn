# station_T2_debris, issue 863

A loose trail of wreckage follows the damaged 270-degree stub. Five pressure plates have folded edges, backing ribs
and burnt inner faces. Three open docking trusses have bent chords and missing braces. A split pod, a broken sensor
dish and 22 fine chips and rail slivers fill out the trail. The CC0 part set uses Hegemony PBR tiles from Ryan's
approved issue 975 run 3 export, at the station's two-world-unit repeat.

Method. [T2 station recipe](../../../../tools/recipe/stations/station_T2.json),
[parts generator](../../../../tools/blender/kits/hegemony_station/debris.py) and
[accepted T2 plan](../../../../contrib/muse/design/station_concept_2026_11/station_T2_scale.jpg).
The generator is a separate Blender export with no station rebake. The loaded debris is 2,306 triangles across
55 surfaces. The base station is 702,516 triangles, for 704,822 total.

The board reads the blocked station cells from the battle. It leaves the authored group in place whenever the true
footprint fits and can push it outward along the stub when a larger station needs more room. The pieces turn
independently at 0.12 to 0.38 degrees per second around fixed centres. The pose updates up to 12 Hz, which moves an
edge by less than one pixel at camera 60. Debris has no collision bodies or terrain entries.

[The loaded check](../../../../tools/blender/kits/hegemony_station/debris_check.gd) reads the rules radius from
`TERRAIN_META.stationR` through the battle view, falling back to 1. It checks each fragment's full tumble sphere against
each blocked cell across all station bearings. It also checks against every fitted roster and boss hull floor, the other
pieces, and the measured motion. Only the detached field is covered by this clearance proof.

The final field clears the seven-cell footprint by at least **18.71 world units** and the 19-cell footprint by **1.38**.
It stays **2.39 world units** below the lowest fitted hull, the Eclipse D22. Both PC projects load the same coated
station and the 32 debris pieces. The 19-cell run loaded the issue 983 rules from `363df0268cef` for the check.

- [Per-piece positions and clearances](debris_placement.md)
- [Seven-cell check](debris_checks.json) and [19-cell check](debris_checks_983.json)
- [Parts manifest](debris_manifest.json) and [matching PC project files](debris_installation.json)
- [Camera positions and fragment projections](debris_captures.json)

The solo #207 test used 20 ships and four squadrons with this field installed. The initial 1080p run peaked at
13.790 ms. The control with the debris hidden peaked at 13.584 ms. All three 1080p frame medians on the same build's
warm repeat cleared 12.5 ms, with a slowest median of **12.241 ms**. The slowest of the three 4K GPU medians was
**6.776 ms**. [Scene gate measurements](debris_gate.json)

Double-click [debris_run.bat](../../../../tools/blender/kits/hegemony_station/debris_run.bat) after preparing the approved
paint and ship caches in the checkout. It runs the installed clearance check, keeps the second camera pass, then measures
the 20-ship #207 station-map gate with a solo GPU claim. `STATION_DEBRIS_RESUME=1` reuses an export with a matching source
hash. `STATION_DEBRIS_RULES` takes a second rules source for testing a pending footprint.
