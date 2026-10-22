# Graphics review: hidden problems that hurt detail (Oct 22, 2026)

Owner asked (Oct 22): "are there other items like being lit from the inside that we should review that might be impacting graphical
quality and detail?" Found by in-game probes on the PC (closeshot `EVAL`), not by eye.

| # | Problem | Effect | Status |
|---|---------|--------|--------|
| 1 | Converted meshes wound inside-out for Babylon: every AI hull and kit, the rocks (drawn with back-face culling, so we saw their far inner walls), the station, transport and beacon, the AI small craft. Procedural ship parts had mixed winding. | Hulls lit from inside (shaded side bright, sunlit side dull); add-on parts looked black against them; rocks and craft lit wrong. | Fixed: `faceOut()` / `faceOutMesh()` in ships3d.js flip any triangle whose winding disagrees with its normals, at load, for hulls, kits, stations, craft, rocks, wreck pieces and procedural parts. `G.diagNoFaceOut=true` turns it off. |
| 2 | Kit paint atlas mostly empty (black) space. | Far-away mip levels averaged in black: parts read 2.6x darker at game zoom. | Fixed: `pixal_to_game` push-pull fills the gaps of every atlas it writes. |
| 3 | Edge-wear radius bigger than the new thin plates. | Whole plates painted as worn steel (near-black in game). | Fixed: radius .0008. |
| 4 | Painted hulls forced to one dull finish (roughness at least .42, metal .08 everywhere). | The "clay" look: paint, rust and bare metal all shone the same. | Fixed: finish read from the paint in the shader for every painted hull; the Pyre-Barge gets baked roughness/metal + fine normal maps (`_f`, `_fn`, `_kit_f`, `_kit_n`). |
| 5 | Shader panel-seam grid laid over the whole Pyre-Barge. | Same line pattern everywhere ("the linework is all the same"). | Off when a ship has baked finish maps. |
| 6 | Kit atlas used 15 to 38% of its texture. | Blurry parts up close. | Partly fixed: thinner UV margins (the gap fill makes them safe). Next: pack per part size, or split the kit into two atlases. |
| 7 | Baked (non-painted) AI hulls: one even sheen. | Uniform plastic look on the other 34 ships. | Improved: worn raised edges read as metal, sheen breaks up in weathered patches (shader, uses each hull's existing curvature map). |
| 8 | Brightness was tuned while hulls were lit from inside. | Now that light comes from the right side, pale hulls (Dominion) can blow out to white in direct sun. | Open: re-tune `directIntensity` / exposure on a real GPU. |
| 9 | All screenshots so far come from SwiftShader (software rendering). | Says nothing about speed, anti-aliasing or shadow quality on a real GPU or the Pixel. | Open: real-GPU and Pixel check before more ships. |
| 10 | A folded plate sliver with "even thickness" blew out to a 2 m spike. | Broke framing and darkened shots. | Fixed: plain solidify plus a stray-part guard in `detail_lib.detail_pass`. |

## How to probe

- Winding audit: the `EVAL` in `tools/pc/jobs/v13k_winding_audit.bat` lists every mesh kind whose triangles disagree with their normals.
- Material probes: `tools/pc/jobs/c19_8..c19_12` (cull, shadows, flat colour, unlit, no HullFx, one-sided lighting). Change the
  material on the visible clone (`ship.ship.fore...`), not the hidden prototype, and give the shader time to compile (`EVALWAIT`).
