# Issue 209 build-route comparison: the tools (round 1)

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
