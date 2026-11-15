# Issue 759 helper scripts (the hegemony_H10 build sheet)

The sandbox steps behind the hegemony_H10 sheet's README rows that the shared sheet tools do not make. Each says its usage in its
first lines. Nothing here is a standing check. The issue 738 helpers (contrib/opus/tools/issue738/: mask, grid, density_mesh,
budget, run_blend) were reused as they are.

| Script | What it does | Runs with |
|---|---|---|
| `inside_check.py` | every inside vertex against the inner skin of the mass that holds it (the design file's `inside_ok`: the wedge, a rail or the bay block), and every inside object clear of every transverse seam's band, so each sits in one compartment | bpy |
| `bell_check.py` | the export's open-bell test (tools/recipe/check_export.py `open_bell`) run on the blockout's rectangular nozzles before any export, at the export's tolerance | bpy |
| `pictures.py` | the three named 1280 by 720 pictures (overview, the whole concept beside H10, the battle camera); publish.py makes the weapon review | Python, Pillow |
