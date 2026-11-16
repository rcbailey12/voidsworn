# Hegemony station kit: station_T2 review

Refs #373. T2 is the damaged fleet station of the Vesper Reach, picked in R206. The design pack is
`contrib/muse/design/station_pack_2026_11/pack.md`; the Board answered its open questions on issue 373 on Nov 13.
Fleet comes first. T1 in service follows later from this Hegemony kit; refinery T3 is separate.

This is a provisional build sheet. It does not bypass RULEBOOK 5.1, the production recipe, the station-map frame gate,
or Ryan's look before installation. The ship manifest and export contract do not yet accept station topology. The
station recipe entry records those gaps instead of giving the station invented ship weapons or engines.

Double-click `tools/recipe/station_review.bat`. It runs the real rules/ShipView input probe headless, then builds and
renders the sheet in Blender Cycles on CPU with eight threads, checks it, and labels the pictures. The Godot and
Blender steps are watched by `tools/pc/tmo.bat`. No GPU window is used, nothing is installed, and no existing asset file is deleted.
It writes `board/issue-373/shots/review3` outside the repository. The console can be logged to `%TEMP%` by the queue.

Files:

- `design.py`: source dimensions, module counts, positions, joints, light map and motion.
- `parts.py`: Hegemony station geometry, shell thickness, corridor decks, frames, racks, deep berth bores and cap systems.
- `stack.py`: preview materials and ambient occlusion only. The production geometry-mask/trim/decal bake is pending.
- `inspect.gd`: real BattleAPI station scenario, footprint through Board.hex_world, fitted ShipView heights including
  flagships, and actual comparison cruiser geometry. The placeholder guard stops missing hulls.
- `review.py`: builds the sheet, fits height to the actual loaded ships, measures the meshes and 49 animation poses,
  renders on CPU, writes a source-hashed manifest and a review GLB. The camera uses Godot's vertical FOV.
- `check.py`: compares mesh measurements with real inputs and reads the actual GLB triangle count and animation targets.
- `sheets.py`: labels each picture at 1280 x 720 and writes the feature table from the built manifest and fit report.

The plan fits the seven real station cells, including their concave boundary. A 90-degree upper arm would extend into
an unblocked notch; its 60-degree placement follows the blocked cells. The height fit found a 51.13-unit loaded
Eclipse Tomb-ark and provisionally raised the station to 52.13 units. The Board must judge those proportions.

The sampled motion check allows contact at the tether, and tests the moving arm's triangles against the rest of the
structure at five-second intervals across its full cycle. It is not a continuous sweep or a static fit audit. Whole
module source meshes and joint intent exist; the review GLB joins static modules and does not prove production tearing.

Next: Board review of the sheet against the accepted pictures, then the approved design through production stages 2 to
7. Pending work includes the shape reference, station recipe/export contract, full fit and tear checks, geometry-mask
paint bake, station-map game captures and frame gate at 1080p and 4K, outside check, and Ryan look before a live swap.
