# Issue 843 evidence

The formation measures the mesh in each craft's own frame, including nested
parts and off-centre geometry. Its clearance bounds include the weave, bank,
roll and spore breathing. Meshes are measured once, when the formation is fitted.
The normal setup fits the factory's craft. `fit_formation()` also lets a preview
refit after replacing those meshes with a sheet model.

The capture uses the unchanged, unpainted issue 793 sheet geometry from
`d624d9dee3edec93a90983307dff309228f37c8a` (`origin/opus/issue-793` at the time of
this run). That branch includes the wide KB1CC, plus HF1D, SF3 and SB4. These sheet
models are not installed factory assets on this checkout. The game still draws
the procedural factory craft; the same spacing code handles either geometry.

Reproduction, with scratch files under TEMP:

1. Extract `tools/blender/kits`, `tools/blender/build_sheets/kit.py` and the four
   craft's sheet Python files and inventory files from that revision into a TEMP
   source folder. Keep their relative paths.
2. Run Blender in background mode with `export_craft.py -- SOURCE_ROOT MODEL_DIR`.
   It builds each unchanged sheet and exports its selected craft collection to
   GLB, with its sheet length beside it. No renderer or paint bake runs here.
3. Run Godot with `--headless --path godot --script
   res://render/test/formation_check.gd -- MODEL_DIR`. Without the last argument,
   the same check covers all factory kinds, the committed Sunward sheet sizes
   and mesh regressions without needing the unshipped models.
4. With the GPU free and Ryan's GPU go active, run Godot through `tools/pc/tmo.bat`
   with `--path godot --rendering-method forward_plus --script
   ../contrib/codex/issue843/capture.gd -- MODEL_DIR CAPTURE_DIR`.
5. Run `python contrib/codex/issue843/sheet.py CAPTURE_DIR OUTPUT.jpg`.

The before side uses the original fixed offsets. The after side uses the live
`fit_formation()`. Both use the same model, flight phase, light, camera 170 and
1080p viewport. The sheet shows unchanged native pixels and labelled 2x details,
at 1280 by 720. The R275 shape pass and the paint finish belong to the craft job.
