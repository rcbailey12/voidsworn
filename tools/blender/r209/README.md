# Issue 209 build-route comparison: the tools (rounds 1 to 3)

Report and sheets: `docs/shots/ship_pipeline/route209/README.md`. Design note: `docs/shots/ship_pipeline/route209/design_c15s.md`.

| File | What it does |
|---|---|
| `common.py` | Shared by every cell: the break structure (skin, bulkheads, rim bands, decks), the paint (round 6 recipe, bands by geometry), the audit and the cost report, AI mesh import and alignment. |
| `armA.py` | Arm A: the hand build on the AI massing underlay (station table, hard-point parts, modest detail). |
| `armB.py` | Arm B cells B0 to B3: imports the TRELLIS.2 generations, fits them into the same slots and hard points, adds the shared structure. |
| `armB_fix.json` | Per-generation turn fixes found by eye in the assembly check (the cleanup cost of Arm B). |
| `render.py` | Same lights, exposure and cameras for every cell: hero (paint, clay), top / side / below orthographic (paint, clay), battle crop, break pieces from two quarters. |
| `sheets.py` | Phone-width comparison sheets from the renders (PIL, runs outside Blender). |
| `report_table.py` | The per-cell numbers table for the report. |

Generation scripts (run on the PC, kept beside the job files in `Downloads\voidsworn_test\opus209\gen\`): `gen209_qwen.py` (Qwen-Image-Edit 2511 reference views and section or part redraws through ComfyUI) and `trellis209.py` (TRELLIS.2 on each image, one process per job is safest). Copies live in `docs/shots/ship_pipeline/route209/gen/`.

Run order on the PC: Qwen pass, TRELLIS pass, then `blender -b -P armA.py -- OUT`, `blender -b -P armB.py -- CELL GEN3D B0_GLB OUT` for B0 to B3, `blender -b OUT\CELL.blend -P render.py -- OUT\r CELL`, then `python3 sheets.py`. The bpy module (`pip install bpy==4.5.*` on Python 3.11) runs the builds in the cloud sandbox too; the renders need the PC GPU.

## Round 2 (report: `docs/shots/ship_pipeline/route209/round2/README.md`)

| File | What it does |
|---|---|
| `armA2.py` | Arm A round 2: the structure traced from the corrected B0 and the concept (13 hull blocks), the hard-point parts, and the detail rungs (`-- OUT 0` structure only, `-- OUT 2` the round 2 rung). Break lines on the structural joints. |
| `armB2.py` | `B0r2` (the whole generation with its yaw fixed) and `B3r2` (generated parts at double budget on A2's structure and hull detail). |
| `bakeAb.py` | The bake cell: A2's structure joined and unwrapped, B0's surface baked to 4096 normal and AO maps on the GPU, A2's hand parts. |
| `export_glb.py` | One glb per cell for Godot (modifiers applied, one surface per material, flat game colours; Ab keeps its maps). |
| `godot/bench209.gd`, `godot/project.godot` | The Godot cost run: twenty copies, LOD off and on, 1080p and 3D at 4K, distance sweep and stills. |
| `flat_views.py`, `massing_sheet.py` | The flat-shaded structure compare (Workbench, runs on the CPU). |
| `sheets2.py` | Round 2 sheets, plus the LOD sheet. |
| `pc/r2_queue.bat`, `pc/r2_run.bat` | The PC run: the queue job brings the clone to the branch and starts the run in its own window. |

Round 1 bug fixed in `common.ai_align`: the yaw was set as an Euler angle on a glTF import (quaternion mode), so it never applied and B0 sat about 20 degrees off the ship axis. The mesh is turned directly now; B0's best yaw is 22 degrees. `render.py` reads each cell's break lines from the blend (round 2 moved them onto the structural joints).

## Round 3 (report: `docs/shots/ship_pipeline/route209/round3/README.md`)

| File | What it does |
|---|---|
| `armA3.py` | Round 3 structure: rounded sections (rolled bow shoulders, chamfered chine and belly corner, domed nose, rounded block corners), 46 layered armour plates ray-cast onto the blocks (thickness, chamfer, alternating stand-off, none across a break line), round 2's hand parts seated on the plated surface, and the hybrid's generated hero-part slots (the hand parts there stay as hidden proxies for the far LODs). `-- OUT A3s` builds the structure alone for the flat compare. |
| `paint3.py` | The concept paint (rust-red forward, gunmetal aft, cargo red-brown, near-black belly, ochre drum bands; AO grime, bevel edge wear, streaks, B0 cavity) as procedural materials, the band assignment, and the bake of the graph to albedo and ORM atlases. |
| `bakeAb3.py` | One cell end to end (`-- OUT B0_GLB GEN3D CELL [RES] [SAMPLES]`, CELL Ab3 or Hy3): geometry, audit, hull joined and unwrapped, break structure, B0 trimmed to a shell and baked as a detail-only normal map plus a cavity map, the paint baked (hull 4096, hand parts 2048, generated parts 2048, hidden proxies 1024), textured materials. |
| `export3.py` | The hand LOD chain (lod0 to lod3 by rule from the full ship, sharing the atlases) to one glb. |
| `godot/bench209r3.gd` | The cost run: twenty copies, three modes (LOD off, Godot auto LOD, hand chain by visibility range), 1080p and 3D at 4K, textures given mipmaps and VRAM compression on load; `quick` as a fifth argument for a logic test on a software renderer. |
| `sheets3.py`, `report3.py` | The round 3 sheets (overview, paint against the concept, battle, close, break, LOD, maps) and the cost tables. |
| `pc/r3_run.bat`, `pc/r3b_run.bat`, `pc/r3c_run.bat` and their queue jobs | The three PC runs (both cells; the hybrid again twice after two atlas fixes). |
