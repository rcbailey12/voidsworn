# station_T2: review sheet, not an installed station

Refs #373. The first kind is the fleet station, T2 damaged. This is a partial delivery at the required build-sheet
review step, not completion of issue 373. The live station is unchanged.

Reproduce on the PC by double-clicking `tools/recipe/station_review.bat`. Its bake and layout scripts are kept under
`tools/blender/kits/hegemony_station/`. All pictures, model files and measured reports are in
`C:/Users/rcbai/Downloads/voidsworn_test/board/issue-373/shots/review3/`. Earlier review folders are preserved.

Review the camera170 pictures at true pixel size first, then the low camera beside the real cruiser, then the
orthographic views. Every image is labelled station_T2 and is 1280 x 720. These are CPU studio renders with the real
game camera radius, beta and vertical FOV; they are not in-game captures. The cruiser is actual fitted ShipView
geometry with neutral studio material. The four orthographic views share one scale and a 10-unit scale bar.

| Evidence | Filename in the review3 folder |
|---|---|
| Battle camera first | sheet_camera170.png |
| Battle camera beside cruiser | sheet_compare170.png |
| Low camera beside cruiser | sheet_compare_low.png |
| True top, side, end and underside | sheet_top.png, sheet_side.png, sheet_front.png, sheet_underside.png |
| Insides, skins and liners hidden | sheet_inside.png |
| Overview | sheet_threequarter.png |
| Feature table and departures | feature_table.md |
| Counts, source hashes, fitted joints | manifest.json |
| Real rules footprint and 30 fitted hulls | game_inputs.json |
| Mesh footprint and sampled movement | fit.json, review_checks.json |
| Cost, including insides and moving arm | cost.json |
| Editable review scene and GLB | station_T2_sheet.blend, station_T2_review.glb |

The seven blocked cells span three hex columns. The measured draft is 51.59 units wide and 52.13 units tall, above
the tallest loaded flagship at 51.13. It contains 325,900 triangles, including 55,092 inside triangles. The review
GLB has 20 material primitives, 11 materials and two mesh nodes. These are reported geometry costs; actual GPU draws
and frame time remain unmeasured. No triangle cap was imposed.

The existing audit images map_03, map_04 and map_15 were opened before the draft. They confirm the low pale mass,
weak height read and orange outlines described by finding P12. This draft establishes a readable silhouette and
inventory for review. It still needs the production surface detail, damage shaping and paint treatment of the
accepted T2 concept. The height fit is a provisional design departure and needs the Board's judgement.

The generated feature table, manifest, cost and review check reports are copied beside this README for diff review.
The source-hashed model and all pictures stay in the required PC shots folder. No new look-bench baseline is accepted.

Validation: the double-click review launcher ran successfully on the PC, CPU only. All 21 review checks passed,
including the actual GLB light geometry, animation duration, fitted joint metadata and triangle total. The real
headless probe loaded 30 hulls with no placeholders. The standing command `node contrib/opus/tools/run_all_checks.js`
ran under bundled Node 22 and returned 0: 48 PASS rows and two existing KNOWN rows (seven listed findings and twelve
constant differences). The document check, whitespace check and no-em-dash scan passed. Scratch logs are in `%TEMP%`.

R129 impact sweep: the new footprint helper is called only by the review probe. The existing live build path has
no behavior change. Saves, profiles, rule twins and UI paths are untouched; no oracle copy or table refresh is needed.
The branch shape will run standing checks, Godot rules parity and Godot game checks on GitHub when the runner pushes.
Those GitHub jobs have not run during this no-commit task, and are not claimed as PC validation here.

RULEBOOK 5.1 requires the build sheet to pass before a production build. This sheet has no approval. Full static
fit, production break paths and tear checks, the concept shape reference, the mask/trim paint bake, station support
in the production recipe/export, and the station-map scene gate remain pending. The CPU-only job did not run a
GPU capture or gate. After those pass, the outside check and Ryan's look are required before any live swap.
