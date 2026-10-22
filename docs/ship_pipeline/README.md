# Ship pipeline: concept painting to in-game hull

Owner goal (Ryan): every ship looks just like its concept painting from every angle, crisp up close, no soft or blobby AI shapes.
Free tools only. No artificial triangle limits (full-detail meshes are compressed, not decimated, on desktop).

Status (Oct 21 2026): one ship done end to end, the Warlord's Pyre-Barge (`C19_51`, Corsair battle-barge). It is the worked example for
everything below. The other 35 hulls are listed in `SHIP_QUEUE.md`. Rules for what "done" means are in `BLOB_SWEEP.md`.

## Where things run

- **Ryan's PC** (RTX 5080 16 GB, 32 GB RAM, Windows 10): every heavy step. AI models in ComfyUI portable
  (`Downloads\ComfyUI_windows_portable`, v0.42.1), Blender 4.5.14 portable (`Downloads\voidsworn_test\blender\...`), the game screenshots.
- **The PC test runner**: `Downloads\voidsworn_test\watcher.bat` runs `build\job.bat` once whenever `run.request` appears, logs to
  `smoke_log.txt`, then deletes `job.bat` and writes `smoke_done.txt`. Never write `job.bat` while a run is going. Write the files first,
  then `run.request` in a separate, later step. Use CRLF line endings. A job must `cd /d "%~dp0"` at the end.
- **Job I/O** per ship: `Downloads\voidsworn_test\comfy_io\<CODE>\` (views, mv sets, mesh, proj, lod, kit).
- **Concept paintings**: `Downloads\voidsworn_meshes\picks\` on the PC (the Pyre-Barge's is `flux11_C19_51_cut.png`, background cut away).
  Copies for anyone working from GitHub: `docs/ship_pipeline/concepts/<CODE>.webp` (all 36, 1024 px). The Pyre-Barge's generated views and
  renders: `docs/ship_pipeline/c19_example/`.
- Worked job files, in order, for the Pyre-Barge: `tools/pc/jobs/c19_1_views.bat` ... `c19_4_kit_to_game.bat`.

## Steps

1. **Side, front and back views** (Qwen-Image-Edit 2511 + multiple-angles LoRA + Lightning 8-step, in ComfyUI):
   `python comfy_run.py views CODE seeds "name=prompt;..." [source.png] [tag]` (tools/pc/comfy_run.py).
   - Prompts use the LoRA's trigger form, e.g. `<sks> right side view eye-level shot medium shot`.
   - Gotchas: asking for the *left* side from a 3/4 concept mirrors the 3/4 view. Generate one clean side, then use it mirrored for the
     other side. Run front/back with the clean side as the source. Back views often fail: drop them.
   - **Ryan approves the side view** (length and silhouette) before anything else runs.
2. **Prepare the multi-view set**: `python tools/blender/mv_prep.py out_dir CODE front left back right [length_scale]`.
   `-` skips a view; `mirror:path` flips one. All views get one shared scale (Pixal3D's rig needs it) plus masks for paint projection.
3. **Pixal3D multi-view mesh** (TRELLIS.2 cascade under Pixal3D conditioning, in ComfyUI):
   `python comfy_run.py mesh CODE TAG views "az,el;..." 2048 2000000 1536 1`.
   - Fixed orbit: az 0 front, 90 left, 180 back, 270 right, elevation 0, fov 20.
   - The custom node `tools/pc/comfy_custom/voidsworn_pixal_views.py` allows any azimuth/elevation per view, which is how the concept
     painting itself joins as a view (its camera found in step 4).
   - Best Pyre-Barge run: E2 = sides + concept + front.
4. **Find the concept painting's camera**: `fitcam_render.py` (Blender, silhouettes over an az/el grid) then `fitcam_fit.py`
   (ComfyUI's Python, best overlap). Writes `<T>_concept.json {az, el, iou}`. Good fits score IoU about 0.89.
5. **Project the paint**: `blender -b -P tools/blender/project_paint.py -- mesh.glb out.png 4096 "img|mask|az|el|weight" ...`.
   The pictures are projected back onto the mesh and baked into its albedo, so the paint is as sharp as the pictures.
6. **Hand-built parts** (`tools/blender/hs/<code>_kit.py`, primitives in `hs_lib.py`; see `c19_kit.py`):
   - Cut the mangled AI geometry out of the hull (boxes and measured regions).
   - Rebuild the parts as clean bevelled meshes, snapped onto the real hull surface with BVH ray casts and measured off the AI hull's
     own sections.
   - Paint them by projection with the hull as occluder (`OCC`). Parts the pictures barely show keep hand paint (`KEEP` boxes) with grime.
   - Writes `<T>_cut.glb` (hull minus cut parts) and `<T>_kit.glb` / `<T>_kit_painted.glb`.
   - **Clean shell (SHELL=1, Oct 22)**: when the AI hull body is wavy, it becomes a measuring guide only. A section table (`ST` in
     `c19_kit.py`) is measured off it and lofted into a clean, subdivided hull (`<T>_shell.glb`).
   - **Detail pass** (`tools/blender/hs/detail_lib.py`, reusable): flank plating cells (raised plates, inset panels, welded patches, vent
     grilles, greebles), pipe runs with brackets, deck plating, mount flanges with bolts, dents; `corsair=True` adds spikes, scrap slabs,
     girder lattices and hazard plates. Call `detail_pass(targets, parts, tag, base_col, bounds, corsair, seed)` before the colour loop.
   - **Procedural paint** (`PAINT=proc` in project_paint.py): weathered paint baked from each part's vertex colours (mottling, dirt,
     streaks, plate tone, scorch, rust, pits, edge wear, grime). Use it on a clean shell: projecting the pictures ghosts the AI layout.
7. **Phone LOD**: `lod_make.py` (collapse decimate that keeps UVs) to 250k triangles.
8. **To the game**: `pixal_to_game.py in.glb out_dir CODE left|front TEXRES` with `ALB` (projected albedo), `KIT` (painted kit) and
   `CONCEPT` (brightness levelling). Then `node vsm_pack.mjs dir CODE` packs the hull with meshoptimizer into `CODE.vsm`
   (desktop about 11-14 MB at 1.5-2M triangles; phone about 3.5 MB at 250k).
9. **In game**: `ships3d.js` loads `hulls_hi/CODE.vsm` (desktop) or `hulls/CODE.vsm` (phone/medium), plus `CODE_kit.json` and the maps.
   Add the code to `AI_VSM` in ships3d.js.
10. **Check**: studio renders (`render_multi.py`) at the concept's angles plus top, below and stern, then in-game shots
    (`closeshot.py`, env `OUT TAG TPLS ZOOM MAP ONLY PRE EVAL`) on desktop and phone. Then the blob sweep (`BLOB_SWEEP.md`).

## Gotchas learned on the Pyre-Barge

- Ship size = hull + hand-built parts. `pixal_to_game` reads the kit for the bounds. Without that, cutting the AI bow stretched the ship 1.33x.
- Kit material: light by the stored normals (no two-sided lighting) plus a 0.3 paint self-light (`G.kitFill`). Otherwise roofs read
  black and shaded sides lose their colour.
- `closeshot.py` serves the game locally. Its server needs a big backlog (256), or desktop shots silently drop files.
- The sandbox (8 GB, CPU) runs out of memory on 2M-triangle meshes. Measure and prototype on the 250k LOD, run the real thing on the PC.
- Blender on the PC has no PIL: image maths runs in ComfyUI's Python.
- In job.bat, never use `:` as an argument separator (Windows drive letters). The scripts use `|`.
- Edge wear must stay thinner than the thinnest plate (bevel radius .0008), or whole plates paint as bare steel and read black.
- Kit atlases are mostly empty space. `pixal_to_game` fills the gaps (push-pull) so far-away mips do not average in black.
- Converted meshes come out inside-out for Babylon. The loader's `faceOut()` (ships3d.js) checks the winding against the stored normals
  and flips it. Without it the hull is lit from inside and every add-on part looks black against it.
- Kit material now matches the hull paint exactly (no self-light, `G.kitFill` 0) since the hull and kit share one HullFx material setup.
- Game frame: bow +x, up +y, port +z. Babylon is left-handed, so conversions mirror and flip winding.
