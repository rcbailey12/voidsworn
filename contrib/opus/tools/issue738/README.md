# Issue 738 helper scripts (the voidsworn_S8 build sheet)

The sandbox steps behind the voidsworn_S8 sheet's README rows that the shared sheet tools do not make. Each says its usage in
its first lines; each runs with the bpy module (pip `bpy` 5.3) or plain Python as marked. Nothing here is a standing check.

| Script | What it does | Runs with |
|---|---|---|
| `mask.py` | the S8 beauty's outline mask (edges or bright over the blurred picture, closed, filled, largest shape; the picture's background glow kept out) | Python, numpy, scipy, Pillow |
| `grid.py` | a coarse camera grid over azimuth, elevation and roll, scored by outline overlap, written as a fit.py starting camera (fit.py only refines) | Python, numpy, Pillow |
| `inside_check.py` | every inside vertex against the hull's inner skin at its own station and height, and the clear band kept above and below each peel seam | bpy |
| `density_mesh.py` | R224's mesh half (tools/recipe/density.py's measures) on a stage 4 build: triangles and edge features per square unit, per part type, against the hull | bpy |
| `budget.py` | triangles outside and inside, materials, objects of a stage 4 build | bpy |
| `run_blend.py` | runs a recipe script on an opened blend, as `blender -b BLEND -P SCRIPT -- ARGS` does (audit.py, audit_selftest.py) | bpy |
| `pictures.py` | the three named 1280 by 720 pictures (overview, the whole concept beside S8, the battle camera); publish.py makes the weapon review | Python, Pillow |
