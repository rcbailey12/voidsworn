# Issue 769 helper scripts (the voidsworn_SF3 and voidsworn_SB4 craft sheets)

Sandbox steps behind the two craft sheets that the shared sheet tools do not make. Nothing here is a standing check. The issue
738 helpers (`contrib/opus/tools/issue738/`: mask, grid, run_blend, budget, density_mesh) were used as they are.

| Script | What it does | Runs with |
|---|---|---|
| `game_view.py` | renders sheet ships together at their game size through the game's battle camera (or a closer or orthographic camera): wings of four in the game's own formation, the S8 flagship beside them | bpy |
| `pictures.py` | the named 1280 by 720 pictures: each craft's overview and whole-concept compare, the true-scale picture with S8 (lengths measured off the picture), the battle camera read | Python, Pillow, numpy, scipy |
| `launcher_shot.py` | the weapon close-up for a launcher (build.py's close-ups cover guns only): weapon_bombs.jpg | bpy |
| `model_notes.py` | refreshes the words in a build.py model json (changes, open items, fit fixes) without rendering again; refuses when the design's parts changed | bpy |

The commands, in order: `build.py <code> <out> render`; `inventory.py`, `layout.py`, `sheet_extras.py`, `publish.py`
(tools/blender/build_sheets); `game_view.py` with GV_FULL=1 GV_DIST=200 GV_EL=32 GV_TARGET=4,0 GV_ORTHO=72 for the scale view
and plain for the battle view; `GV_ORTHO=72 pictures.py`.
