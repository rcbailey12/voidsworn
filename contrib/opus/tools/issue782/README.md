# Issue 782 helper scripts (the deathless_E14 redesign: the upright ring and the null lance)

The sandbox steps behind the E14 sheet's README rows that the shared sheet tools do not make. Nothing here is a standing check.
Reused as they are: contrib/opus/tools/issue738/ (grid.py for the starting camera, run_blend.py, budget.py).

| Script | What it does | Runs with |
|---|---|---|
| `mask_e14.py` | the E14 beauty's outline mask for the camera fit: the engine glow, the nebula and the sky seen through the ring's open middle left out | Python, numpy, scipy, Pillow |

The battle camera picture is made by `tools/blender/build_sheets/studies/e14_ring_study.py` (BLOCKOUT.blend OUT_DIR [samples]),
the whole compare by `studies/whole_compare.py`. The checks ran against issue 784's data.js (this branch merges opus/issue-784).
