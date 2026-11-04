DeepSeek leg - breakable ships by design, the Blender build method (R98)

Leg: legs/deepseek.md
Writer: DeepSeek (DeepThink ON, Search ON)
Date: 2026-11-04
Inputs: PACK.md only, plus web sources cited below.
Grounding: R96 ceiling ~306k triangles / ~3.9 ms at 20 ships; intact Pyre-Barge already sits at that ceiling (305,857 tri; V1 307,477 tri, 3.887 ms). The method below therefore assumes interiors live only in the broken-piece variants; the intact ship carries only authored break-line thickness bands and a minimal interior liner, with any intact-ship triangle increase paid for by decimation elsewhere. This assumption is stated again in the cost section and must be confirmed before #169 starts.

1. Real hull thickness from a single-skin AI mesh

The AI hull is a single-sided surface. Thickness must be added inward only, so the exterior silhouette does not move. The exact operation is the Solidify modifier in Complex mode, applied as a script stage, not a hand edit.

Why Complex mode. Simple mode "does not work on geometry where edges have more than two adjacent faces" and fails where normals are not consistent, both common in AI-generated hulls. Complex mode "can handle every geometric situation to guarantee a manifold output geometry" and is explicitly able to solidify non-manifold, architectural-style layouts that Simple cannot. It is slower, so it is used only on the hull shell, not on every greeble. If the special cases are not present, the manual recommends Simple because Complex adds logic and cost; on AI hulls the special cases are present, so Complex is the correct default.

Script steps, in order.

Import and clean. Join hull parts that share a material, merge by distance, recalculate normals outside, delete loose vertices/edges, and fill open boundary loops with bmesh.ops.holes_fill before solidifying. If the hull has many disconnected shells, separate by loose parts and solidify each shell independently; a single Complex solidify over hundreds of overlapping shells is slower and can produce internal walls that are never seen.

Apply object scale. Solidify thickness is calculated in local vertex coordinates; a non-uniform object scale makes thickness vary on different sides. Apply scale before adding the modifier.

Add Solidify, set mode to COMPLEX. Use offset = -1 so the original surface stays exactly where it is and the new thickness grows inward; the offset range is -1 to 1 and the inside/outside is determined by face normals. This is the step that keeps thickness off the exterior silhouette. Thickness mode should be CONSTRAINTS for the most reliable result where up to three faces meet; EVEN is acceptable on simpler shells.

Assign interior and rim materials by material index. Solidify's Material Offset changes the material slot of the newly generated inner geometry, and Rim assigns a separate material to the rim faces. Put the interior structural material one slot below the exterior paint material and set the material offset accordingly. This gives the cut a different material band without a manual face-selection pass.

Apply and validate. Apply the modifier; then run a manifold check with bmesh (bm.edges where len(e.link_faces) != 2) and a triangle count. If the hull still has non-manifold edges, split those regions into separate objects and re-solidify; do not lower to Simple mode, because Simple will leave holes on exactly the geometry that caused the problem.

Thickness values. For a capital hull at the project's battle scale, 0.4-0.8 m is enough to read at close zoom and cheap at battle camera. The number is an art judgment and is INFERRED; it should be tuned against the Pyre-Barge's actual dimensions. Thickness is an approximation, not a structural simulation.

What "real hull thickness" means for the intact ship. A full-hull Complex solidify on a 305k-triangle mesh will roughly double the shell's triangle count and cannot fit inside R96 without a large decimation. The workable reading of the ship-kit rule is therefore: model thickness where the hull is designed to be opened, a 1-2 m band on each side of every authored break line, plus the break-line rim, and put the full thickness and interior structure in the break-piece variants. This is a chair-level interpretation and is labelled INFERRED; it needs Ryan's sign-off in the owner questions.

2. Internal decks and bulkheads sized for the battle camera

The battle camera does not resolve individual rooms. At the distances in the R96 test scene, a capital hull occupies a few hundred pixels; a deck line every 8-12 m and a bulkhead every 20-30 m is enough to read as structure, while smaller detail is wasted. These spacing figures are INFERRED from the R96 camera setup, not measured.

Counts per break piece.

3-5 deck planes, each a simple box or a solidified plane 0.2-0.3 m thick, spanning the piece's interior cross-section. One or two decks should be visibly broken or bent at the fracture face so the cut is not a clean architectural section.

4-6 bulkhead walls, simple boxes with a doorway-sized hole cut by a boolean or left as a gap between two panels. Bulkheads should be perpendicular to the ship's long axis and offset from the break line so the camera sees depth, not a flat wall immediately behind the cut.

One "dark liner" just inside the outer hull, so any hole that is not on an authored break line still shows a dark surface, not the far wall of the ship. This liner is a low-poly inward-offset copy of the hull, not a full solidify.

Darkness rule. Interiors must be dark, not lit like the exterior. Use an interior material with albedo around 0.01-0.03, roughness 0.8-1.0, and no emission except the hot-edge material handled by the #167 shader. The Nov 1 destruction synthesis is explicit that darkness is the fix, not more rooms; this section follows that rule. EVE's wreck pipeline similarly applies a dedicated "damaged interior" material and correct UVs to the capped cut faces rather than reusing the exterior paint.

Detail policy. Model the interior as ribs, deck edges and bulkhead silhouettes, not as rooms. A dark box with three lit-by-nothing deck lines reads better than a fully modelled corridor that the camera never sees, and it keeps the triangle cost low. This is INFERRED from the camera resolution and the R96 ceiling.

3. Two or three authored break lines with capped interior faces and damage textures

Line choice. Author two transverse lines and one longitudinal line per hull (three total), or two transverse lines for a smaller hull. Choose them:

between major modules (engineering block / habitat block / bow), not through engines, bridge or weapon hardpoints;

behind the main armour belt where the exterior silhouette is simple, so the cut does not destroy a recognizable feature;

where a break piece will have a stable centre of mass for physics.

Mark each line in Blender as an empty plus a named vertex group on the hull, so the script can find the cutters and the exported nodes can carry the line ID. The exact placement is INFERRED; there is no shipped-game source that gives a universal rule.

Cutting. Use a Boolean modifier with the Exact solver, Self Intersection enabled, and Hole Tolerant enabled for non-manifold AI geometry. The cutter should be a closed, beveled box or a jagged wedge, not a zero-thickness plane; a closed cutter produces capped faces on the difference result. EVE's wreck tool uses exactly this pattern: reusable "Cutter" volumes that are rotated, scaled and tweaked per ship, with the boolean process capping all mesh holes and applying the correct UVs and damaged-interior materials. For a strictly planar cut, bmesh.ops.bisect_plane is the scriptable alternative and gives a clean edge loop for capping.

Capping. After the boolean, check for open boundary loops and run bmesh.ops.holes_fill on any loop the boolean left open. Then triangulate the cap and assign material bands by face normal and region:

Exterior paint, the original hull material.

Exposed primer / armour edge, a thin band on the outer 0.1-0.2 m of the cut.

Scorched structural interior, the dark interior material, albedo 0.01-0.03.

Hot torn edge, an emissive material on the inner 0.05-0.1 m of the cap, handed to the #167 shader so the glow cools over time and does not add a new flash budget.

Solidify's material offset and rim material can create bands 1-3 automatically on the thickness geometry; the cap faces from the boolean need explicit material-index assignment. The four-band scheme is INFERRED from the project's #167 interior bands and EVE's damaged-interior practice.

Damage texture set with the project's baked-mask procedural paint. R96 fixes the paint method as baked-mask procedural materials plus trim and decals. The breakable stage should add a damage mask to that same material graph, not a second texturing system:

Build a mask from curvature (edge wear), ambient occlusion (crevices), a large-scale noise (soot patches), and hand-painted strokes along the break line.

Bake the mask to an image at the hull's existing texture resolution; use it to blend paint to primer to scorched metal to hot edge.

Author three variants per hull: soot (soft dark gradient around the cut), scorch (high-contrast burned paint), and torn (bare structure with edge debris). These are material variants, not new meshes.

Add edge debris by extruding the armour plating around the cut 0.2-0.5 m, assigning a debris texture, and painting the base vertices black so the damage fades into the hull. EVE does exactly this and describes the vertex-colour fade as the transition between hull and extruded armour.

Bake an AO map for the interior and cap faces on a unique UV set, as EVE does for its wrecks, so the dark interior has readable depth without extra lights.

Add damage decals as cube-map projections around breaches, matching EVE's "damage decals" step. This is a texture-space operation, not extra geometry.

What not to use. Blender's built-in Cell Fracture add-on is free and can produce debris chunks, but it is a random fracture tool: it "rarely does a full split," sometimes leaves pieces offset from the source, and creates gaps; it is also slow at high cell counts. It is not suitable for authored break lines. Use it only, if at all, for small loose debris chunks spawned after the authored cut.

4. Export so Godot can swap the pieces in at death

Format. Export one .glb per hull. glTF 2.0 is Godot's recommended 3D format, and binary .glb is the smallest of the three glTF export options. One file keeps the intact mesh, the break pieces and the material set together and makes the triangle-count check a single operation.

Scene structure and naming.

PyreBarge_root (empty at ship origin, 0,0,0)
PyreBarge_intact (mesh, origin at ship origin)
PyreBarge_break_root (empty at ship origin)
PyreBarge_break_A (mesh, origin at piece centroid)
PyreBarge_break_B (mesh, origin at piece centroid)
PyreBarge_break_C (mesh, origin at piece centroid)
PyreBarge_collision (optional, -col suffix)

The intact mesh origin stays at the ship origin, so it drops into the existing ship scene without a transform change.

Each break piece origin sits at its own fracture-face centroid, so a rigid body or a simple rotation pivots around the piece, not around the ship centre. The piece's local transform is still authored so that, with the parent at identity, the pieces reassemble the intact ship. This is INFERRED; it should be tested in Godot.

Use Godot's name suffixes where useful: -col for collision, -noimp to drop helper nodes, -rigid for a rigid body. Do not rely on suffixes for the break logic; use explicit node names.

What Godot receives. A .glb imports as one scene, and its objects arrive as separate nodes; an inherited scene or Save Branch as Scene gives per-part control. The death code therefore receives:

the intact node (hide on death);
the break root and its three child meshes (show on death);
the break-line IDs, encoded in node names (_A, _B, _C) or in glTF extras if the pipeline supports extras.

The death code does not run a boolean or a fracture at runtime. It hides the intact node, shows the pre-authored pieces, and hands the piece transforms to the debris/physics step. This matches EVE's shipped behaviour: the wreck is a static object loaded once the original ship mesh is removed, not an animated runtime break.

Static geometry merge caveat. The ship-kit procedure says static geometry merges at export. If the glTF exporter merges objects that share a material, the break pieces will collapse into one node. Keep each break piece as a separate object with a distinct object name, and if necessary a distinct material slot, and verify the node count on reimport. Do not join the pieces before export. This is INFERRED from the project's export rule and must be checked in the first #169 build.

Triangle-count check. Reimport the .glb and assert that the intact mesh triangle count and each break piece count match the Blender source. This is an existing ship-kit procedure fact and should be a hard fail in the build script.

5. Chorus organic variant

The same pipeline applies; only the interior vocabulary and material bands change.

Interior structure.

Bone ribs instead of decks: curved cylinders or tapered boxes running transversely, spaced 6-10 m, with visible joints and fractures at the break line.

Flesh masses instead of bulkheads: low-poly icospheres or metaball-derived blobs, dark red, high roughness, pressed against the inner hull. They are solid volumes, not planes, so they read as mass through a cut.

Membrane sheets instead of metal liner: solidified planes 0.1-0.3 m thick, translucent only in the sense of a dark wet surface; they must not be see-through to the void. The darkness rule still applies: the membrane's interior side is near-black.

Thickness. Bone 0.2-0.4 m, membrane 0.1-0.3 m, flesh masses solid. The Solidify Complex mode works the same way on membrane sheets; bone ribs are already closed volumes and need no solidify.

Break lines. Cut along joints between chitin plates and bone sutures, not along straight transverse planes. Use a jagged wedge cutter rather than a box, and let the cut follow the seam. Two or three lines are still enough; the organic silhouette does more of the work than the cut itself. This is INFERRED from the pack's Chorus description; there is no shipped-game source for organic capital-ship break authoring.

Damage textures. Wet flesh (dark red, high roughness), charred bone (off-white to black gradient), and glowing ichor on the torn edge (emission handled by the #167 shader, no new flash budget). Do not use metal soot or primer bands. The interior material bands are: membrane, raw flesh, charred bone, hot ichor. This is INFERRED.

Cost. Organic interiors are cheaper than metal interiors if the ribs are instanced and the membranes are single planes: 6,000-12,000 triangles per break piece, versus 8,000-15,000 for a metal piece with decks and bulkheads. This is an estimate, not a measurement.

6. Triangle and draw-call cost per hull against the R96 ceiling

Assumption restated: the intact ship carries only the authored break-line thickness bands and a minimal dark liner; the full decks, bulkheads and interior detail live in the break-piece variants. This is the only assumption that fits R96.

R96 anchors. Stage 5 repaired hull: 305,857 tri. V1 with markings: 307,477 tri, 3.887 ms GPU at 20 ships (RTX 5080, Godot 4.7.2 Forward+, 1080p, MSAA 4x, isolated scene). The ceiling is about 306k tri and about 3.9 ms at 20 ships. V3 at 622,570 tri and 5.250 ms is outside the ceiling and stays parked.

Configuration / Triangles per hull / Draw calls per hull / 20-ship total triangles / Verdict:
Intact today / 305,857 / 1 (merged) / 6.12M / At R96 ceiling
Intact + break-line bands + liner / +3,000-6,000 (net +0-2,000 after decimating hidden greebles) / +1-2 (interior material) / 6.12M-6.16M / Recommended; must offset with 3-6k decimation
Intact + full interior / +20,000-40,000 / +3-5 / 6.5M-6.9M / Fails R96; do not do
Break variant A / 8,000-15,000 / 2-3 / (only at death)
Break variant B / 8,000-15,000 / 2-3 / (only at death)
Break variant C / 8,000-15,000 / 2-3 / (only at death)
Three break pieces, one wreck / 24,000-45,000 / 6-9 / 0.48M-0.90M for 20 wrecks / Far below intact total

Interpretation.

The intact ship is already at the ceiling, so any interior carried by the intact ship must be paid for by decimation. A full interior on the intact ship adds 20k-40k triangles per hull and pushes 20 ships to 6.5M-6.9M triangles, a 6-12% overrun. That is not acceptable without a separate performance waiver.

The break variants are cheaper than the intact ship because the intact mesh is hidden at death. Twenty wrecks at 45k triangles each are 0.9M triangles, versus 6.12M for twenty intact ships. The triangle cost of wrecks is not the risk; the risk is draw calls and overdraw if many ships die in the same frame.

Draw calls are controlled by merging decks/bulkheads per material inside each break piece: three pieces x two materials = 6 draw calls per wreck, plus one for the hot-edge material if it is not merged = 7. Twenty wrecks = 140 draw calls. This is INFERRED and should be measured in the #169 Godot probe.

If the project cannot afford even the break-line bands on the intact ship, the fallback is to put the bands only in the break variants and rely on the #167 game-side interior fallback for intact-ship damage holes. That fallback is a competing system and should not be the primary method, but it is the zero-cost backstop.

The cost figures for the bands and break pieces are INFERRED estimates, not measurements. The first #169 build must replace them with actual counts.

7. How shipped space games author breakable ships

Game / Method / Source:
Homeworld 3 / Procedural Ship Breaking tool in Houdini simulates hull collapse under explosion pressure. The tool also models the internal rooms and mechanisms of the ship, then warps and crinkles them so they bulge out. Wrecks persist on the battlefield and can be salvaged. The older system hand-modelled debris meshes and was too slow for the number of ships; the procedural tool replaced it.
Homeworld 3 / Larger ships use damage sockets around the hull to spawn FX. Splat Damage creates impact points that alter the surface geometry and properties of the hull in the hit area, rather than applying a sticker. The modding documentation lists a third UV channel for team colour and SPLAT Damage.
EVE Online / Capital wrecks are pre-authored static objects, not runtime fractures. The wreck is loaded when the ship mesh is removed. The toolchain uses reusable Cutter volumes and complex booleans to break the ship apart, caps all mesh holes, applies correct UVs and damaged-interior materials, extrudes edge debris with UVs and a vertex-colour fade, bakes AO to a unique UV set, and adds damage decals. One 3D artist and one technical artist produced 27 capital wrecks after the tools were built.
EVE Online / CCP considered animated breakup but rejected it for capital ships because each wreck would add 30-50 bones, skinned shaders, and load the animation when the wreck spawns; in fleet fights that was not a good trade.
Battlefleet Gothic: Armada / Destroyed ships leave floating, smouldering wrecks with their own physics; wrecks can block line of fire and can be scuttled. Community descriptions also refer to drifting hulks and "drifting derelict" states. The evidence is community/player-level, not a developer blog; the project's Nov 1 synthesis already cites Armada as the "whole dark drifting hulk" case. (community sources; weaker)
Sins of a Solar Empire II / Hull hits produce hardly any visible change; ships simply disappear or "pop out of existence" at death. There are pre-placed derelicts that can be captured, but they are separate map objects, not authored death output. This is the cautionary case: no modelled interiors, no break pieces, no persistent wreck from the death event.

What the evidence supports.

The shipped-game norm is offline or pre-authored destruction, not runtime boolean fracture. EVE explicitly moved from hand-authored one-by-one wrecks to a procedural tool that still outputs a static wreck mesh. Homeworld 3's Houdini tool is also an offline generation tool: it builds the break and the interior, and the game ships the result.

The closest match to the project's "authored break lines with capped interior faces" is EVE's cutter + boolean + damaged-interior material pipeline. The closest match to "modelled internal rooms" is Homeworld 3.

Sins is the negative example the pack already flags: if the hull does not change when hit and the ship pops at death, the player sees an empty event. The build-side method exists to prevent that.

8. Hours per hull once the script exists

These are planning estimates and are INFERRED. They assume the tools/blender/hull_repair/ chain already has a working breakable_build.py stage and a reusable cutter library.

Phase / First hull / Repeat hull:
Script and pipeline setup / 30-40 h / 0 (reuse)
Hull cleanup and thickness bands / 8-12 h / 2-3 h
Break-line authoring and cutters / 10-15 h / 3-5 h
Interior decks/bulkheads or organic variant / 8-12 h / 3-5 h
Damage texture set and material bands / 8-12 h / 2-4 h
Export, Godot swap test, 20-ship timing / 6-10 h / 2-3 h
Total / 70-101 h / 12-20 h

Evidence that repeat hulls are cheap after tooling. EVE's team built the wreck tools, then one 3D artist and one technical artist worked through 27 capital wrecks for Rubicon 1.1. The blog does not give hours, but it is explicit that the tooling was the investment and the per-asset work dropped sharply. Homeworld 3 says the Ship Breaking tool took "many months" to develop, which is consistent with a large first-hull/tooling cost and a lower repeat cost. The project should expect the same shape: a high first-hull cost and a 12-20 h repeat cost once the Pyre-Barge stage is proven.

What makes repeat hulls cheap. The script stage reads a small per-hull config: hull name, scale, material slots, three cutter transforms, deck/bulkhead counts, and damage-texture set. The cutters are reusable volumes that are rotated and scaled, exactly as EVE describes its cutter library. No new code per hull.

9. Proposed step list for issue #169

This is the ordered list Codex can follow. It lands in tools/blender/hull_repair/ as a new stage, not a new tool elsewhere.

Freeze the hull. Take the kept round 5 hull from #163. Export the current intact mesh and record its triangle count and 20-ship frame time against R96. This is the baseline the breakable version must not exceed.

Add breakable_build.py to the existing chain. Read a per-hull config (hull name, scale, material slots, break-line count, deck/bulkhead counts, damage-texture set). Do not modify the existing round 4/5 scripts; call the new stage after the current export stage.

Clean the mesh. Merge by distance, recalculate normals outside, delete loose geometry, fill open boundary loops with bmesh.ops.holes_fill, and separate by loose parts if the hull has many overlapping shells. Apply object scale before any thickness operation.

Add break-line thickness bands. For each authored break line, select the 1-2 m band of hull faces on each side, Solidify in Complex mode, offset = -1, thickness 0.4-0.8 m, material offset for the interior, rim material for the cut edge. Apply and manifold-check. Keep the bands separate objects until export so the merge step does not weld them into the exterior.

Author the cutters. Create two transverse and one longitudinal closed cutter (beveled box or jagged wedge) aligned to the marked empties. Use Boolean Exact, Self Intersection, Hole Tolerant. For planar cuts, bmesh.ops.bisect_plane is the scriptable alternative. Apply the booleans, then separate by loose parts into intact piece and break pieces.

Cap and band the cuts. Run bmesh.ops.holes_fill on any open loops. Assign the four material bands (paint, primer, scorched interior, hot edge) by material index and face normal. Add the edge-debris extrusion and the vertex-colour fade to black, following EVE's pattern.

Build the interior. For the metal variant, add 3-5 deck planes and 4-6 bulkheads per break piece; for the Chorus variant, add bone ribs, flesh masses and membrane sheets. Use the dark interior material (albedo 0.01-0.03, roughness 0.8-1.0) and the darkness rule. Merge decks/bulkheads per material to keep draw calls down.

Build the damage texture set. Extend the R96 baked-mask procedural paint with a damage mask (curvature + AO + noise + hand-painted strokes). Bake it, create the soot, scorch and torn variants, and bake an AO map for the interior on a unique UV set. Add damage decals around breaches. Do not add new flash emitters; hot edges go through the #167 shader.

Export and validate. Export one .glb with PyreBarge_root, PyreBarge_intact, PyreBarge_break_root, and PyreBarge_break_A/B/C. Use shared-origin intact, centroid-origin pieces. Reimport and assert triangle counts match. Check that the pieces arrive as separate nodes in Godot and that the static-merge step has not collapsed them.

Implement the Godot death swap. Import the .glb as an inherited scene; hide the intact node and show the break pieces at death. Test at battle camera and close zoom, and record before/after 20-ship frame time against the R96 ceiling.

Document and gate. Write the step-by-step method into tools/blender/hull_repair/README.md and the prototype outputs into docs/shots/ship_pipeline/pyre_breakable/. Do not replace any shipping asset until Ryan approves. Record the actual triangle counts and frame time in the README so the next hull can reuse the numbers.

Owner questions (maximum five, with chair picks)

Q1. What does "real hull thickness" mean for the intact ship, given R96?
A. Full-hull Solidify on every new hull, and accept a performance waiver.
B. Thickness bands along the authored break lines only, with full interiors in the break-piece variants, chair pick.
C. Decimate the exterior aggressively so the full hull can be solidified inside R96.
Recommended: B. It preserves the R96 ceiling and still delivers modelled thickness and interiors where the player sees them.

Q2. How many authored break lines per hull?
A. Two transverse lines only.
B. Two transverse plus one longitudinal, chair pick.
C. Three radial lines from a single centre point.
Recommended: B. Three pieces give a readable breakup without turning the death into confetti, and the longitudinal line breaks the "clean slice" silhouette.

Q3. Export one .glb or separate files?
A. One .glb with a named root and named child pieces, chair pick.
B. One .glb per break variant.
C. Separate .glb per piece.
Recommended: A. Godot imports the .glb as one scene with separate nodes, and the triangle-count check stays a single operation. Separate files are only needed if per-piece import settings diverge.

Q4. How should the damage texture set be authored?
A. Extend the existing baked-mask procedural paint with a damage mask and three variants, chair pick.
B. Build a new UDIM damage atlas.
C. Shader-only procedural damage with no baked masks.
Recommended: A. It reuses the R96 paint method, keeps texture memory bounded, and is the only option that fits the existing pipeline without a second texturing system.

Q5. How dense should the Chorus organic interior be?
A. Bone ribs plus membrane sheets only, for cost, chair pick for the first hull.
B. Full organ masses and bone ribs.
C. A shared generic flesh kit reused across all Chorus hulls.
Recommended: A for the first hull, with the option to add one flesh mass per piece after the frame-time measurement. The organic variant should prove the pipeline cheaply before adding density.

Not checked

Exact triangle counts for the thickness bands, break pieces and interiors are estimates, not measurements. They must be replaced by actual counts in the first #169 build.

The behaviour of Complex Solidify on the actual Pyre-Barge mesh has not been tested in Blender 4.5.14. The script must include a manifold check and a fallback that splits non-manifold regions.

Godot 4.7.2's import of one .glb with four or more named child meshes has not been tested in this leg. The static-geometry merge rule may collapse pieces; verify node count on reimport.

Battlefleet Gothic: Armada evidence is community-level, not a developer blog. The claim that it "proves the whole dark drifting hulk" is carried from the project's Nov 1 synthesis, not independently verified here.

The Chorus organic method is INFERRED from the pack's Chorus description; no shipped space game with a sourced organic-capital-ship break pipeline was found.

The hours-per-hull figures are planning estimates, not measured. EVE's 27-capital run is evidence of amortization, not a per-hull time.

The baked-mask procedural paint details are taken from R96/R98; the exact node graph in the project was not inspected in this leg.
