# Issue 780 helper scripts (the Hegemony paint stack on hegemony_H10 and hegemony_IM5)

Sandbox steps behind the Hegemony paint pictures and the builder's checks of hegemony.md section 6. Nothing here is a standing
check; the stack itself is `tools/blender/kits/hegemony/stack.py`. Each script says its usage in its first lines. The CPU driver
is issue 756's `contrib/opus/tools/issue756/run_cpu.py` (unchanged).

| Script | What it does | Runs with |
|---|---|---|
| `preview.py` | paint_sheet.py's views (with `cam170`, the fixed 34 degree battle camera at the game's true pixel size) under the game light and the Hegemony lift read from look.gd, plus the sheet's battle camera (long lens), a module band close and the port flank close | bpy |
| `pictures.py` | the three named pictures in `docs/ship_pipeline/build_sheets/hegemony_<cell>/paint/` | Python, Pillow |
| `audits.py` | emissive audit (under 0.8, nothing warm), the #626d7d value cap on both baked atlases, lift hue test, hull medians at the battle cameras against the concept's, the decal mirror check | Python, numpy, Pillow |

Order, per ship (H10 shown; IM5 the same with its concept `contrib/muse/design/iron_mandate_2026_11/round_2/IM5.jpg`):
`R209_SHIP=tools/recipe/ships/hegemony_H10.json python run_cpu.py tools/blender/r209/bake_sheet.py -- JOB none none H10 2048 6`,
then `python run_cpu.py preview.py JOB/H10.blend -- PV hegemony_H10 CONCEPT samples=16`, `python pictures.py PV OUT hegemony_H10 CONCEPT`,
`python audits.py JOB PV H10 CONCEPT OUT.json`.
