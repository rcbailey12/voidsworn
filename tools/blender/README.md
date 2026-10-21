# Blender tools (run on the owner's PC: Downloads\voidsworn_test, portable Blender 4.5.14 LTS, OptiX on the RTX 5080)
- hullbake.py: high-poly Hunyuan GLB + game hull JSON -> normal map + AO/curvature map; aligns automatically (24 rotations + similarity ICP); ops keep_main / tall.
- uvprep.py: xatlas UV charts for hull JSONs (run in the sandbox; xatlas inside Blender crashes on Windows).
- bake_all.py: bakes every hull (env BAKE_REFS, BAKE_OUT, BAKE_DIV for the phone set).
- rockgen.py: sculpted asteroid library (carbon, stone, crystal, ice), high GLB + game low JSON. rocks_bake.py bakes them.
- fxsim.py: Mantaflow explosion sims rendered as tintable flame/smoke frames (work in progress).
