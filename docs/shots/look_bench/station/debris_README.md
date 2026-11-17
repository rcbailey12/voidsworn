# station_T2: damage-side debris, issue 863

Current stage: **part set built, runtime proof pending**. The generated GLB contains 34 pieces and 14,580 triangles.
The standing suite passed 63 rows with two existing KNOWN rows, and the Godot project import reported no script errors.
The watchdog held cache installation on its game-open check. That waiting launcher was stopped without starting Godot.
Installed game proof is not built yet: the loaded clearance check, camera 170/60 pictures and visual comparison remain
unverified. The build is recorded in [debris_manifest.json](debris_manifest.json); no runtime pass is claimed here.

The painted issue 975 station is the base. This job adds a separate part set off the broken 270-degree stub arm,
following the loose cloud in the accepted T2 scale view. The station's base meshes, scale, paint and radiator animation
remain inputs. No rules, terrain cells, movement cost or collision bodies are added.

Method: [debris.py](../../../../tools/blender/kits/hegemony_station/debris.py) builds six thick folded plates with
ragged edges and back stiffeners, four bent I-section frames, three cold pressure pods with bands and severed cradles,
and 21 fine shell fragments. Each plate's tear and fold varies. The pieces reuse the installed T2's Hegemony PBR
materials at its two-unit repeat. No concept image is projected. These new meshes are own work, CC0.
The source construction is the station's pressure plating, docking structure and equipment pods, not generic rocks.

The separate debris cache is attached by [the board prop loader](../../../../godot/assets/ships/a4_props.gd).
[The motion script](../../../../godot/render/station_debris.gd) turns each piece slowly about its own axis at
0.12 to 0.38 degrees per second. Centres stay fixed, with no loop reset or outward drift across the board.
This job chooses the brief's tumble option so a long battle cannot carry pieces into new flight space.

Placement is below the fitted ships and outside the whole seven-cell station circumcircle. The
[loaded-geometry check](../../../../tools/blender/kits/hegemony_station/debris_check.gd) reads those cells from the
real rules scenario, measures every exported mesh's full tumble sphere and compares it with every cell under every
station bearing. It measures fitted roster and boss hull bottoms through ShipView, checks separate tumble spheres,
source hashes, PBR textures and triangle totals, and confirms changing mesh bounds at 60 seconds with no collision
objects or rules-view changes. The per-piece JSON retains the comparison against all seven individual cells.
The clearance proof is continuous for these fixed centres and arbitrary rotation, rather than a sample of motion poses.

Reproduce by double-clicking [debris_run.bat](../../../../tools/blender/kits/hegemony_station/debris_run.bat) after
preparing the painted station and current game caches. The launcher preserves replaced debris caches and leaves the
painted base cache untouched. It builds, installs, checks, captures twice and keeps the second pass. Native captures
and logs stay in TEMP. `STATION_DEBRIS_RESUME=1` resumes at cache installation from a source-current export.

The field's lower depth separates it from the flight plane, unlike the concept's unmeasured depth. The base station's
previously reported overhang remains; this job does not certify or change the original station footprint. The small
pieces are for the Board's visual review at camera 170 before close inspection at 60. Ryan's final look remains owed.
