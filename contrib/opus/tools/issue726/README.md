# Issue 726 helper scripts (the Hullbreaker trophy patches, R252)

Sandbox steps behind the A20 and A16 pictures of PR for issue 726. Nothing here is a standing check; the change itself is
`TROPHY` and `panel_nodes` in `tools/blender/kits/hullbreakers/stack.py`. Each script says its usage in its first lines.

| Script | What it does | Runs with |
|---|---|---|
| `tune.py` | `issue756/run_cpu.py`'s job plus two tuning shortcuts (skip the hull normal bake; override `TROPHY` from JSON, for example a debug green); never used for the PR's pictures or numbers | bpy |
| `preview.py` | the game light and the battle lift exactly as `paint_sheet.py` sets them, then only the fitted beauty camera (transparent film, so the ship mask is exact), a deck close and a flank close | bpy |
| `measure.py` | mean value and trophy patch area share (pale, violet), patch sizes, on the concept and on renders; thresholds fixed from the concept before tuning | Python, numpy, scipy, Pillow |
| `pictures.py` | the named pictures (concept, old, new and the numbers; the close views) | Python, Pillow |

Order: `R209_SHIP=tools/recipe/ships/corsair_A20.json python contrib/opus/tools/issue756/run_cpu.py tools/blender/r209/bake_sheet.py -- JOB none none A20 1024 6`
(the same from a tree at main for the old stack), then `python contrib/opus/tools/issue756/run_cpu.py contrib/opus/tools/issue726/preview.py JOB/A20.blend -- PV corsair_A20 CONCEPT samples=16 scale=0.5`,
`python measure.py concept=CONCEPT old=PV_OLD/paint_beauty.png new=PV/paint_beauty.png --json M.json`,
`python pictures.py OUT A20 CONCEPT PV_OLD PV M.json`.
