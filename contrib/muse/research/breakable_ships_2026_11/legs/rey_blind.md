# Issue 171 blind Rey leg: breakable ships by design, the Blender build method

Written by Rey on 2026-11-04, first, from the issue 171 pack and my own web research only. No other leg for this issue existed when this was written, and none was read. Claims from the project record cite the file they came from. Everything else is either cited to a web source or labelled INFERRED.

## Headline

Do not solidify the whole hull and carry the result around intact. Split the hull at two or three authored break planes first, give each piece a thin inward wall only where a cut or a breach can see it, put the real interior (decks, bulkheads, ribs) inside the broken-piece variants only, and let Godot swap the intact mesh for the pieces at death. The intact ship pays for one cheap dark inner shell. The wreck pays for the guts, and wrecks are few on screen at once. That split is what makes the method fit the R96 ceiling, because the Pyre-Barge intact hull already sits on it.

## 1. Hull thickness from a single-skin AI mesh

Project facts: the current hulls are single-sided surfaces with nothing inside (contrib/muse/research/destruction_2026_11/synthesis.md), the ship-kit rule requires real hull thickness with no single-skin shells (.claude/skills/ship-kit/SKILL.md, "Breakable by design"), and builds are Blender scripts on Blender 4.5.14, never unrepeatable hand edits (same skill, procedure step 1).

Proposed script stages (Blender built-ins only):

1. Repair first, using the existing tools/blender/hull_repair/ chain. Solidify and booleans both misbehave on non-manifold geometry, so the repaired, reimport-checked hull is the input, never the raw AI mesh.
2. Cut the hull into its break pieces (section 3) before adding thickness, so every piece is an open shell with known openings.
3. Per piece, apply the Solidify modifier inward (offset minus 1, so the exterior silhouette does not grow). The Blender manual states Solidify takes the surface of a mesh and adds depth or thickness to it, offset locates the solidified output inside or outside the original, and Complex mode can guarantee manifold output where Simple mode fails; it also warns thickness is an approximation calculated in local coordinates, so non-uniform object scale must be applied before this step. Source: https://docs.blender.org/manual/es/3.3/modeling/modifiers/generate/solidify.html (Spanish 3.3 mirror; the English current page needs verifying in the writer legs).
4. Do not keep the full-resolution inner skin. INFERRED: a full inward solidify roughly doubles a piece's triangles, which no hull at the R96 ceiling can carry. Instead, keep the solidify rim (the wall edge at each opening, which is what a camera actually sees as thickness) and replace the deep inner surface with a decimated inner shell: a duplicate of the piece, decimated hard, normals flipped, offset inward, wearing the near-black interior material from the Nov 1 rule. The rim sells thickness, the dark shell blocks see-through, and neither needs exterior density.
5. Assign three material slots per piece before export: exterior paint (the existing baked-mask procedural paint, FINDINGS R96), interior dark, and cap or damage (section 3). Material slots, not separate objects, are what keep draw calls down (section 5).

## 2. Internal decks and bulkheads, sized for the battle camera

Camera grounding from the pack: the battle camera sits about 170 units away and Ryan plays at 4K, about 15.4 px per unit. INFERRED from that: interior detail smaller than about a quarter unit is invisible in play, so decks and bulkheads should be big simple shapes with texture doing the close-zoom work, not modelled detail.

Per hull, scripted from the hull's own bounding sections:

- One spine deck running the length of the main hull mass, plus one cross deck in any secondary mass big enough to hold one. Two to three decks total, never a room layout. The Nov 1 synthesis is explicit: interiors must be dark, not lit like the exterior, and darkness is the fix, not more rooms.
- One bulkhead at each authored break plane. The bulkhead is structural in the fiction and practical in the build: it is the backing plate the cap face sits on (section 3), so a broken piece never shows a hollow tube.
- Ribs as a texture and a few large silhouette shapes only: repeated frame ribs baked into the interior material's normal and AO masks, with at most a handful of real rib boxes near each break opening where the camera looks straight in. INFERRED cost: a few hundred triangles per opening.
- No interior lights. Ember points and the cooling hot edge belong to the #167 shader layer, not to modelled lights in the build.

## 3. Authored break lines, caps and damage textures

- Two lines on small hulls, three on capitals and flagships, INFERRED as the count that reads as break-up rather than confetti at battle distance; the ship-kit rule itself fixes the range at two or three.
- Place each line at a natural section change or a narrow cross-section, roughly perpendicular to the spine, and store it in the build script as a named plane with its position and angle as data, so #169 and later hulls reuse the same mechanism and the game receives the same lines the build used.
- Cut per piece with a scripted bisect or boolean against the stored plane. Give the cut edge a slight irregular displacement so the two sides do not read as a laser slice, INFERRED as a small noise displacement on cap vertices only, never on the exterior silhouette.
- Cap each open face with the bulkhead plate, displaced inward slightly, wearing the damage material: three bands per the Nov 1 slag cap language (armour band, structural band, hot core band that the #167 shader cools). The cap is a real face, so the piece is solid from every angle, which is the R98 complaint answered directly: "the broken open pieces are visibly empty" (FINDINGS.md:126).
- Damage textures come from the existing paint system, not a new one: the R96 route is baked-mask procedural materials (curvature, AO, edge wear) plus trim and decals (FINDINGS.md:124). The cap and rim reuse that bake with a scorch-heavy mask variant, soot darkening toward the cut, scorch and torn-edge detail in texture. No projected concept art, per R96.

## 4. Export so Godot can swap the pieces in at death

- One .glb per hull variant set, exported from the same script run as the intact hull, containing named objects: the intact mesh, one object per break piece, and the interior kit merged into its piece. Godot's glTF import brings a multi-object file in as a scene whose objects arrive as separate nodes, and an inherited scene gives per-part control, so the death code can hide the intact node and show or release the piece nodes without a second file or a load hitch. Sources: https://forum.godotengine.org/t/importing-multiple-parts-from-blender/128940 and Godot docs on glTF as the recommended format, https://docs.godotengine.org/en/4.2/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html
- Every piece object gets its origin at the piece's own centre of mass, computed in the script, so a tumbling piece rotates around itself the moment Godot animates it, with no code-side pivot maths. INFERRED: centre of mass from Blender's origin-to-centre-of-mass operator is close enough for a tumbling wreck; exact mass properties are not a visual problem.
- Piece names carry the break line ids from the build script (for example piece A is bow side of line 1), so the #167 and death code can match a damaged-but-alive hole or a staged break to the authored line instead of cutting generically, which is exactly what #169's done-when asks for.
- Static geometry merges at export per piece and per material slot, following the standing ship-kit export rule. The intact export path (triangle count reimport check in the ship-kit audit) runs on the intact mesh and on each piece.

## 5. Cost against the R96 ceiling

Ceiling (FINDINGS.md:124): about 306k triangles and about 3.9 ms at 20 ships. Measured anchors (docs/shots/ship_pipeline/pyre_round4/README.md): stage 5 hull 305,857 triangles; V1 with markings 307,477 triangles at 3.887 ms for 20 ships in the isolated test scene; today's ship 256,468 triangles at 2.681 ms.

INFERRED estimates, arithmetic shown, none measured:

- Intact ship: exterior unchanged, plus the decimated dark inner shell at roughly 4 to 6 percent of exterior triangles. Pyre-Barge: about 12k to 18k extra triangles, which puts the intact flagship over the 306k ceiling unless the same count is trimmed from the exterior during repair. Smaller hulls sit far below the ceiling and absorb it. This is the one real budget fight in the method, and it belongs on the flagship only.
- Broken variants: pieces reuse the exterior triangles (the same surface, split), so the split itself adds only rim, cap and interior geometry: bulkheads and caps about 1k to 3k triangles per break line, decks about 2k to 5k per hull, ribs near openings under 1k. Total added per hull roughly 10k to 25k triangles, carried only by wrecks on screen, not multiplied by 20 intact ships.
- Draw calls: intact stays at its current merged count. A wreck is 3 pieces times up to 3 material surfaces, so at most about 9 draws per wreck, INFERRED, and only for ships that have died and not yet been cleaned up. The risk is not the fleet, it is a screen full of simultaneous capital deaths, which the staged death timing already spreads out.

## 6. Chorus organic hulls

The ship-kit rule fixes the principle: Chorus hulls get flesh and bone inside instead of metal (.claude/skills/ship-kit/SKILL.md). Applied to this method:

- No decks, no bulkheads, no right angles. The inner shell becomes flesh: a dark red-brown, wet-look interior material (roughness low, colour dark per the Nov 1 darkness rule), with vein and fibre detail in texture, not geometry.
- Bulkheads become bone or cartilage walls: the cap at a break line is a bone plate with a flesh rim, displaced more irregularly than a metal cap, because a Chorus piece tears rather than slices. INFERRED: reuse the same cap mechanism with a larger displacement amplitude and the organic material set; no second code path.
- Ribs are literal here: a few curved bone arcs inside each break opening, grown along the hull's own curvature, are the one place Chorus gets more real geometry than a metal hull, INFERRED at 1k to 3k triangles per opening, paid only on wrecks as with the metal kit.
- Break lines follow segment joints in the organic form rather than perpendicular planes, but they are still authored, named and exported the same way, so the death code does not care which faction a piece came from.
- Membranes: a thin membrane can span a damaged-but-alive opening (stretched, dark, slightly glossy), which gives Chorus a wound read no metal hull has. INFERRED as a texture and material state on the inner shell, not new geometry.

## 7. How shipped space games author this, early read

- Homeworld 3 is the strongest sourced case and the closest to this job. Blackbird built a procedural Ship Breaking tool in Houdini that simulates how a hull collapses under an internal explosion and also models the internal rooms and mechanisms of a ship, then warps and crinkles them so they bulge outward; larger ships also carry damage sockets that spawn damage effects, and its Splat Damage alters surface geometry at impact points rather than pasting decals. The transferable lesson for a Blender shop with no Houdini licence in scope: the interiors are authored or generated offline and baked into the wreck, not simulated at runtime, which is the same shape as the method above (build-side pieces, game-side swap). Source: https://gamingtrend.com/news/homeworld-3-devs-release-new-blog-post-discussing-weapon-and-unit-damage/
- The Nov 1 project synthesis already screened the rest, and I record its verdicts here as project record, not as fresh sourcing: EVE Online's 2025 fire system scales visible damage by ship class and is the distance-readability model; Sins of a Solar Empire 2 barely changes hulls when hit and pops ships at death, the cautionary case; Battlefleet Gothic: Armada proves the whole dark drifting hulk as a cheap, readable kill (contrib/muse/research/destruction_2026_11/synthesis.md). The writer legs must bring fresh primary sources for EVE, Sins and Armada rather than leaning on this paragraph.

## 8. Hours per hull once scripted

INFERRED, benchmarked against the round 4 repeatable-pass estimates of 3 to 6 hours for a repair-route pass on an already repaired hull (docs/shots/ship_pipeline/pyre_round4/README.md): once the breakable stage exists in the hull_repair chain, about 2 to 4 hours per flagship or capital (choosing break lines, checking caps at close zoom, fixing Chorus or faction variants), and about 1 to 2 hours per smaller hull where the script's default line placement holds. The first hull (the Pyre-Barge in #169) carries the script-writing cost and is not in these numbers.

## 9. Proposed step list for #169 (blind draft, chair to finalise)

1. Take the kept round 5 hull as the script input; confirm its triangle count against the R96 ceiling before any interior work.
2. Add a breakable stage script in tools/blender/hull_repair/ that takes break line positions as data and runs unattended from the existing runner pattern.
3. Cut the three authored pieces, solidify rims inward, build the decimated dark inner shell, decks and bulkheads, cap every opening with the banded damage material.
4. Export one glb with the intact mesh and named pieces; run the ship-kit audit and the reimport triangle check on every object.
5. Record the before and after death and damaged-alive captures at battle camera and close zoom that #169 requires, plus the 20-ship frame check.

## Owner questions (blind picks)

1. Should the intact ship carry the thin dark inner shell (small cost on every hull, breaches never show sky), or should interiors exist only in broken variants (zero intact cost, breaches on live ships stay with the #167 fallback alone)? My pick: carry the thin shell; it is the only version that fixes damaged-but-alive holes at build level.
2. Break lines fixed at three for every hull, or two for small hulls and three for capitals and flagships? My pick: by class, two and three.
3. Should the flagship's inner shell cost be paid by trimming exterior triangles during repair to stay under the R96 ceiling? My pick: yes, the ceiling is a ruling, not a target to drift past.
4. Chorus membranes as a material state on the inner shell, or real membrane geometry? My pick: material state first, geometry only if the close zoom proves it thin.
5. Should #169's script be a new stage inside tools/blender/hull_repair/, or a separate breakable tool folder? My pick: a stage inside hull_repair, where the runner, checks and probes already live.

## Not checked

Blender API specifics for scripted bisect, boolean and Solidify in 4.5 (the writer legs must cite the current manual); Cell Fracture and other free add-ons (not assessed here); EVE, Sins and Armada primary sources (flagged in section 7); any measured triangle or frame cost (all costs above are INFERRED estimates); the Godot death code's current node structure (no code was read for this blind leg).
