# Issue 793 helper scripts (the hegemony_HF1D, corsair_KB1CC and chorus_CS1BA2 craft sheets)

Sandbox steps behind the three craft sheets that the shared sheet tools do not make. Nothing here is a standing check. The issue
738 helpers (`contrib/opus/tools/issue738/`: mask, grid, run_blend, budget, density_mesh) and the issue 769 helpers (`game_view.py`,
`launcher_shot.py`) were used as they are.

| Script | What it does | Runs with |
|---|---|---|
| `grid_window.py` | issue 738's camera grid with the azimuth and elevation held to a window (AZ_LO, AZ_HI, EL_LO, EL_HI), for a concept whose outline alone is ambiguous | Python, numpy, Pillow |
| `pictures.py` | the named 1280 by 720 pictures: each craft's overview and whole-concept compare; the three craft beside their flagships at true game scale (one orthographic scale); the battle camera read | Python, Pillow, numpy, scipy |

The commands, in order, per craft: `mask.py` on the concept with its name label blanked; `build.py <code> <out> mesh`; `grid.py`
(or `grid_window.py`) and `fit.py --fit` (KB1CC: `fit.py --fit --fix-angles` at angles set by eye, see its camera note);
`build.py <code> <out> render`; `inventory.py`, `layout.py`, `sheet_extras.py`, `publish.py` (tools/blender/build_sheets);
`sheet_contract_selftest.py`, `tools/blender/r209/sheet_hull.py`, then `run_blend.py` with `audit.py` and `audit_selftest.py`,
`budget.py`, `density_mesh.py`; `launcher_shot.py` for a launcher's weapon close-up; `pictures.py overview`. For the three:
`game_view.py` once per faction with GV_FULL=1 and one GV_ORTHO (the flagship and a wing of four), then `pictures.py scale`;
`game_view.py` plain (the battle camera) with the three wings, then `pictures.py battle`.
