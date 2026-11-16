# Hegemony station kit: station_T2 review

Refs #373. Fleet station first: T2 damaged, Vesper Reach, accepted in R206.
T1 in service follows later from this kit; refinery T3 is separate.

This is a review sheet. Production paint, recipe/export support, complete fit and tear checks,
the station-map performance gate and Ryan's look remain open. Nothing installs the model.

For the R247 review, double-click `review_run.bat` in this folder after the ship files have been
copied with `tools/pc/get_ship_files.bat` and the Godot import has completed. Wait for other GPU
jobs before running it. The launcher checks the Board's `gpu_go.txt`, runs the real
rules/ShipView probe headless, builds the sheet in CPU
Cycles, checks the exported GLB, rejects deliberately undersized and oversized GLBs, then runs
the Godot GPU studio twice and keeps the second captures. Its output folder is
`../issue-373/shots/review5/` beside the checkout. In lane B this is
`C:/Users/rcbai/Downloads/voidsworn_test/board_b/issue-373/shots/review5/`.
Set `RECIPE_NOPAUSE=1` for the queue. Long commands use `tools/pc/tmo.bat`; nothing is deleted.

- `design.py`, `parts.py`, `stack.py`: existing station design, Hegemony geometry and preview
  materials. The materials are not the production geometry-mask, trim and decal bake.
- `scale.py`: reads the two station ranges from `docs/playbooks/scale.md` and reports the live
  `godot/render/board.gd` STATION constants. No range is copied from the build's fitted output.
- `inspect.gd`: makes real BattleAPI scenarios and measures fitted ShipView hulls, flagships
  included. It exports real unit inputs for comparisons and actual cruiser geometry for CPU
  sheets. Missing hulls or incomplete texture imports stop the probe.
- `review.py`: scales the whole station uniformly to the table's minimum long axis, preserving
  all source proportions and animation transforms. Writes source hashes, measurements, the
  review blend/GLB and CPU sheets. The former vertical +1-unit fit is gone.
- `check.py`: independently reads the table and live board constants, measures actual GLB bounds
  through node transforms, checks uniform export scale, inside geometry, lights and 49 motion
  poses. `--gpu` also requires a camera-170 capture for every combat class and checks framing.
- `range_selftest.py`: changes the actual exported GLB scale in preserved TEMP copies while the
  manifest stays unchanged. Both an undersized and oversized export must be refused.
- `capture.gd`: isolated Godot GPU viewport with the real camera rig, battle lighting and fitted
  ShipView hulls. One class per 1280 x 720 picture, with both code names. These are GPU studio
  comparisons, not a station-map battle or performance gate.
- `sheets.py`: labels CPU sheets at original pixel size and writes the feature table.

The original plan fits seven real blocked cells. The R247 scale exceeds them. Both the source
fit and the scaled spill are reported; no blocked cell, live station constant or scale_check
KNOWN entry changes in this run. A matching footprint remains required before installation.

The motion probe permits tether contact and samples mesh intersections across one 240-second
cycle. It does not certify a continuous sweep or full static fit. The review GLB joins static
modules for cost inspection; production seams and tearing remain unproved. Costs are reported
without a triangle cap. RULEBOOK 5.1 still requires the sheet to pass before production.
