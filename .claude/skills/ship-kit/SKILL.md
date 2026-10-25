---
name: ship-kit
description: Use when building, dressing, painting or exporting any Voidsworn hull or kit (Blender scripts in tools/blender, the barge chain, max-detail flagships), or when touching the hull pipeline (project_paint, pixal_to_game, vsm_pack). Gives the build-check-export procedure and the ship rules every part must pass.
---

# Ship kit: build, check, export

The worked example is the Pyre-Barge (C19_51). Its chain is the template for every ship: `assets/ships/C19_51/README.md`.

## Rules every ship must pass (owner rulings, CLAUDE.md)
- Space ships, not naval: no keel or raked stem, no jackstaffs, bollards, anchors, crow's nests, yardarms, rigging, mast ladders, lifeboats, porthole rows, crossbar masts or smokestack funnels. This covers hull shape (bow profile, keel line, deck line) as well as bolted parts. Prefer flat armoured bellies with chines, sensor housings, antenna arrays, equipment pods, recessed lights, engine bells and thruster pods, docking hatches, heat radiators.
- Bolted parts sit on the real hull surface on a visible mount (plate, ball, saddle, column), never floating or sunk, in matched symmetric pairs at sensible hard points. Corsair may be junky and asymmetric.
- Guns face forward or out to the side, never backward. Bow guns may face forward along the prow.
- Hand-built parts carry the AI hull's level of surface detail (seams, grit, worn edges).
- Shields keep faction colours (the cyan-only rule is retired). No artificial triangle caps (retired), but keep load time in mind.

## Procedure
1. **Build in Blender from a script**, never by hand edits that cannot be re-run: `tools/blender/a1/barge_v15.py` (uses `hs_lib.py`, `detail_lib.py`). Max-detail flagships: `tools/blender/a2detail/`. Cloud checks: `pip install --break-system-packages bpy` (5.2); the PC runs Blender 4.5.14, so avoid 5.x-only API.
2. **Automatic audit in the build** (blocking): no backward guns, no floating parts (BVH overlap, or nearest surface under 1.5 mm; choose near objects by bounding-box overlap, not centre distance), and a reimport of every exported glb with matching triangle counts. The barge's `audit()` and `export()` are the reference. Do not show a ship that fails.
3. **Blob sweep** before showing a ship: bow, midship and stern, each from top, side and below (9 cells, studio renders at the concept's angles). Every cell gets a verdict: clean, or rebuild by hand. Rebuild by default: guns and launchers, bridge and superstructure tiers, masts and antennas, tanks and drums, the bow (faired loft from the hull's own sections), engine nozzles, armour stacks, sponsons, and any thin spiky AI debris.
4. **Clay and colour sheets** with `tools/blender/a1/clay.py` and `render_v15.py`; contact sheets with `sheet.py`. Send Ryan screenshots, not descriptions.
5. **Paint** on the PC (`tools/blender/project_paint.py`, PAINT=proc; parts the concept shows poorly keep hand paint via KEEP boxes). Keep the faction palette.
6. **To the game** on the PC: `pixal_to_game.py` (reads the kit for bounds: the game size comes from hull plus kit together) then `vsm_pack.mjs`, for `hulls_hi` (4096) and `hulls` (2048). Job example: `tools/pc/jobs/c19_v15d.bat`.
7. **Check in the game** on the PC with closeshot (see the screenshot-verdict skill), including damage states.
8. **Commit** the script, the glb exports (`assets/ships/<code>/`), the game files and the sheets; update the ship's README chain and FINDINGS.

## Frames and formats
- Game frame: bow +x, y up, z port. Blender kit frame: x aft (bow -x), y port, z up; `clay.py` turns game hulls with FLIP=1.
- Older AI hulls: `CODE.json` (base64 int16 positions, int8 normals, indices, uv2) plus `_m.webp` (R AO, G curvature) and `_n.webp`. The barge: `.vsm` (meshopt) plus `CODE_kit.json`.
- Kit material lights by stored normals (no two-sided lighting); paint self-light is 0 (ships3d.js:790).

## PC runs
Heavy work (bakes, paints, closeshots) runs on Ryan's PC through the watcher: see the playtest-and-balance skill's "PC runner" section.
