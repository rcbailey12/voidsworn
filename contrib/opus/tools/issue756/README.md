# Issue 756 helper scripts (the Sunward paint stack on voidsworn_S8)

Sandbox steps behind the S8 paint pictures and the builder's checks of sunward.md section 6. Nothing here is a standing check;
the stack itself is `tools/blender/kits/voidsworn/stack.py`. Each script says its usage in its first lines.

| Script | What it does | Runs with |
|---|---|---|
| `run_cpu.py` | runs a recipe script with the bpy module as `blender -b [BLEND] -P SCRIPT -- ARGS` does, the stack's device set to CPU | bpy |
| `rivet_ab.py` | bake_sheet.py with the Sunward `rivet_pitch` replaced for one run (sunward.md 4: .011 against .013 at camera 170) | bpy |
| `preview.py` | paint_sheet.py's views under the game light and the Sunward lift (look.gd), plus the battle camera at 34 degrees (the sheet's battle camera json, and the game's true pixel size), the spires close and the port broadside | bpy |
| `pictures.py` | the three named pictures in `docs/ship_pipeline/build_sheets/voidsworn_S8/paint/` | Python, Pillow |
| `audits.py` | emissive audit (under 0.8, no blue over green), frost coverage against the 6 percent cap, lift hue test, hull median at the battle camera | Python, numpy, Pillow |

Order: `R209_SHIP=tools/recipe/ships/voidsworn_S8.json python run_cpu.py tools/blender/r209/bake_sheet.py -- JOB none none S8 2048 6`,
then `python run_cpu.py preview.py JOB/S8.blend -- PV samples=16`, `python pictures.py PV OUT`, `python audits.py JOB PV OUT.json`.
