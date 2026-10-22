# Gemini Audit & Drop-In Fixes (`contrib/gemini/`)

## Summary of Changes and Why

1. **`reviews/ship_pipeline_audit.md`**
   - Complete audit answering Questions 0 through 5 from `docs/ship_pipeline/AUDIT_BRIEF.md`.

2. **`tools/blender/hs/c19_kit.py`**
   - **Rebuilt midship side tanks (`TANK`)**: Previously measured on lines 44-50 and cut out of the hull on line 58, but never built. Now builds paired domed side tanks (`sidetank`) on two saddle mounts (`tanksaddle`) per side.
   - **Fixed aft casemate gun direction (`casegun`)**: Previously used direction `(1, s_ * .05, -.01)` where `+X` is aft, aiming backward toward the stern opposite `longgun`. Now mounted on the forward casemate cheek (`x = 0.155`) on a ball mount (`caseball`) aimed forward and outboard `(-1, s_ * .25, -.02)`.
   - **Fixed aft long cannon yaw (`longgun`) and casemate shape (`casemate`)**: Yawed `longgun` and its rings `8 deg` outboard so the forward muzzle clears the midship hull flare; replaced the axis-aligned `casemate` box with a sloped frustum blister; capped the aft deck cutout (`0.285 <= x <= 0.36`) with a recessed hatch bay (`aftbay`).
   - **Fixed deck gun mounts (`gunplate`, `gunball`, `GUNS`)**: Fixed `cyl(..., axis='Z', rot=Rn)` (previously passed `axis=Rn` which broke `hs_lib.cyl` axis lookup) and lowered the aft deck gun tip `z1` from `0.080` to `0.028` so it aims outboard instead of straight up.
   - **Fixed symmetry (`fun1`, `fun2`, `hatch2`)**: Centered both funnels on `y = 0` and mirrored `hatch2` to both port and starboard.
   - **Rebuilt front armour plates (`frontslab0..3`)**: Replaced the 4 flat boxes (whose outer corners floated over the crowned glacis) with 3-section cambered chevron lofts (`hs_lib.loft`) that follow the lateral hull slope, with shingled lower lips, longitudinal side cheek rails (`frontcheek`), a central spine rib (`frontspine`), and warm dark iron paint (`IRON`).
   - **Rebuilt bridge crown and mast (`tier2`, `wingsponson`, `brvents`, `mast`)**: Added a stepped upper conning tier (`tier2`) with a red armored brow visor and 4 amber viewport lights, side rangefinder sponsons, aft bridge roof vent louvers (`hs_lib.vents`), a mast base collar, and rear tripod struts anchored to the bridge roof (fixing the floating `brace` at `z = 0.123`).
   - **Fixed kit export for `project_paint.py`**: Transfers every part's `COL` linear color into a mesh `FLOAT_COLOR` vertex attribute (`Col`) and calls `hs_lib.finish('kit')` before exporting `_kit.glb` so `project_paint.py` receives a single joined mesh with valid vertex colors.

3. **`tools/blender/project_paint.py`**
   - **Multi-object join and material-color fallback**: Automatically joins multi-object GLBs and converts material `Base Color` values into a `Col` vertex color attribute if one is missing.
   - **Bare view path auto-upgrade**: If called with bare image paths (as in `c19_4_kit_to_game.bat` line 14) instead of `img|mask|az|el|wt`, automatically resolves masks, camera angles, and `@fitcam.json` so the batch script does not fail with `IndexError`.
   - **Color management fix**: Forces `sc.view_settings.view_transform = 'Standard'` and `sc.view_settings.look = 'None'` before `EMIT` baking so Blender 4.5's default AgX tone-mapper does not compress or desaturate highlights.
   - **Energy-neutral `DETAIL=1` pass**: Centers the brick, noise, and bevel-edge multipliers around a mean of `1.00` so procedural surface detail does not darken or brighten the kit relative to the hull.

4. **`tools/blender/auto_sweep.py`**
   - New automated preprocessor implementing Question 4: deletes disconnected islands and thin wire debris (internal ray diameter `< 7 mm`), flattens wavy macro plates, auto-lofts a symmetrized bow from 16 cross-sections, segments blurred bolt-on protrusions against a smoothed base hull envelope, and writes `<CODE>_sockets.json`.

5. **`tools/pc/jobs/c19_4_kit_to_game.bat`**
   - Passes explicit `view|mask|az|el|weight` arguments to `project_paint.py` and matches kit gain to the hull so both meshes share identical projected brightness without manual fudges.
