# Pyre-Barge (C19_51), source of truth

Engine-neutral source for the barge (plan A1 step 5). Everything here is rebuilt from one script, so the Babylon game files and any Godot import come from the same place.

## The chain

1. **Build** (Blender 4.5 or the bpy module): `python3 tools/blender/a1/barge_v15.py OUT` writes `OUT.blend`, the shape plus every part, with flat Corsair colours as vertex colours. Approved by Ryan: shape (R12, R13) and paint (R14) in contrib/opus/FINDINGS.md.
2. **Export:** the build's export step writes the two standard glTF files kept here:
   - `C19_51_v15_shell.glb`: the hull, superstructure and ordnance block, joined.
   - `C19_51_v15_kit.glb`: every part and plate.
3. **Paint** (Ryan's PC, GPU): `tools/blender/project_paint.py` with `PAINT=proc` bakes weathered paint, roughness and metal, and fine normals from the vertex colours. It writes `shell_painted.glb` and `kit_painted.glb` (standard glTF with textures; the kit one is about 35 MB, so it stays on the PC under `Downloads\voidsworn_test\comfy_io\C19_51\v15\`). PC job: `tools/pc/jobs/c19_v15c.bat`.
4. **Game files (Babylon):** `tools/blender/pixal_to_game.py` and `vsm_pack.mjs` turn the painted files into `hulls_hi/C19_51.*` and `hulls/C19_51.*`.
5. **Godot (A2 engine test):** import the painted .glb files directly.

Frame: x aft (bow at -x), y to port, z up, length about 1.0. The game files flip the bow to +x.
