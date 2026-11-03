Gate: Qwen3.8-Max verified in the model selector before the prompt was submitted, and the chat header still showed Qwen3.8-Max after generation and at completion. One response, no preference picker. Run from the main chat on 2026-11-03 after the Qwen sign-in was restored.

Research: How Studios Make Detailed Hard-Surface Ships Without Waves
Leg: Qwen (writer)
Issue: #112 - "Research: how studios make detailed hard-surface ships without waves (feeds #111)"
Prepared: 2026-11-04
Model gate: Qwen3.8-Max verified in selector before submission; header confirms Qwen3.8-Max post-generation.
Inputs: PACK.md (issue 112 leg pack) only, plus cited web sources. No other leg consulted.

1. Methods: How Shipped Games and Working Artists Keep Hard-Surface Ships Clean

1.1 Built Clean and Detailed in Parts (Part Splitting, Kit Parts, Greeble Kits)
What it is. The hull is never modelled as one continuous blob. It is assembled from discrete, flat or simply-curved panels, each modelled separately with clean topology, then snapped together on visible mounts. Small repeated details (vents, pipes, conduits, antenna clusters, access hatches) are modelled once as a "greeble kit" or "kit-bash set" and instanced across the hull.
What it fixes. Eliminates large-scale undulation because each part is individually planar or simply curved. The eye reads panel seams and part boundaries as intentional design, not as surface noise. Scale is sold by the density and variety of small parts, not by displacing the hull surface.
Cost per hull.
Metric | Estimate
Artist time | 3-6 days for a hero ship (≈60-100 kit parts placed); 1-2 days for a background/RTS-distance ship reusing an existing kit
Triangle budget | 8 k-30 k tris per hull at RTS distance; 40 k-120 k for close-up hero variants. Kit parts add 200-2 000 tris each but are instanced, so unique geometry stays low
Free tool | Blender (kit modelling, Array/Instance collections, snapping, boolean cleanup). No paid tool required
Studio evidence.
Sins of a Solar Empire II - Martin Danlos (ArtStation). The technical breakdown shows the ship built from a high-poly model of discrete parts, baked to a clean low-poly mesh. The wireframe shows quads laid out per panel, not one continuous surface. Source: https://martindanlos.artstation.com/projects/0lGmg8 (verified in pack source seeds). A companion post shows the in-game result with PBR texturing: https://martindanlos.artstation.com/projects/AZ8DRX
Sins of a Solar Empire (original) - Polycount art dump. The artist describes modelling high-res parts, baking to game-res with xNormal, 2048×4096 textures, and using "small details to sell ship scale." The parts are modelled separately and assembled. Source: https://polycount.com/discussion/comment/1561334#Comment_1561334
Polycount hard-surface spaceship thread. The consensus advice is: "model ships as separate parts and panels, not one block." Panel detail ranges from texture-only at distance to modelled high-poly up close, with mid-poly floater decals in between. Source: https://polycount.com/discussion/169587/spaceship-hardsurface-subdivision-polymodeling-learning-and-help
EVE Online - Art of Retribution dev blog. The redesign process starts with sketches, moves to 3D block-outs of major hull sections as separate volumes, and keeps the silhouette while reworking every ship. Parts are designed and modelled as distinct assemblies. Source: https://community.stratics.com/threads/developer-blog-the-art-of-retribution.287865/
Starsector. The game's ships are 2D sprite-based, so the "part splitting" principle manifests as layered sprite composition: hull base, weapon hardpoints, engine glows, and detail overlays are separate images composited at runtime. No 3D source to cite; INFERRED from the game's visible asset structure and the developer's blog posts on the Fractal Softworks site.
INFERRED: For Battlefleet Gothic: Armada 2 and Stellaris, no public art breakdown was located in this leg. Battlefleet Gothic: Armada 2 (Tindalos Interactive / Focus Entertainment) ships visibly use part-split construction with turrets, bridge modules, and engine blocks as separate meshes, but no developer talk or ArtStation post was found to cite directly. Stellaris (Paradox) ships are assembled from modular kit parts in-engine, consistent with the part-splitting method, but again no named public source was located. Both are marked INFERRED.

1.2 Subdivision or Bevelled Mid-Poly with Weighted Normals
What it is. The hull is modelled at a moderate poly count ("mid-poly") with subdivision surface or explicit bevels on hard edges, then a Weighted Normal modifier (or equivalent) is applied so that the shading normals on flat faces point perfectly outward, eliminating the pinching and waviness that standard auto-smooth produces on bevelled hard-surface geometry.
What it fixes. Without weighted normals, a bevelled edge on a flat panel causes the flat area to shade as slightly curved, producing visible waves under specular or environment lighting. Weighted normals force the large flat faces to shade perfectly flat while keeping the bevel rounded. This is the single most common fix for "waves on flat panels" in hard-surface work.
Cost per hull.
Metric | Estimate
Artist time | Adds roughly 10-20 % modelling time over unweighted normals (setting face sets / sharp edges, tuning the modifier). For a hull already built clean, a pass to add weighted normals is 2-5 hours
Triangle budget | Bevels add geometry: 1-3 segments per edge. A hull that was 5 k tris un-bevelled becomes 8-15 k with bevels. Weighted normals themselves add zero triangles; they only change shading
Free tool | Blender: Bevel modifier or manual bevel, then Weighted Normal modifier (set to "Face Area" or "Corner Angle" mode). Fully free, no add-on needed. Also available in 3ds Max (paid) and as a concept in any engine that supports custom normals
Studio evidence.
Polycount hard-surface thread (cited above). The thread discusses subdivision and mid-poly approaches and specifically mentions keeping flat faces flat via normal control. Source: https://polycount.com/discussion/169587/spaceship-hardsurface-subdivision-polymodeling-learning-and-help
Blender Weighted Normal modifier. Documented in the official Blender manual as a modifier that adjusts normals by face area or corner angle to prevent shading artefacts on hard-surface models. Source: https://docs.blender.org/manual/en/latest/modeling/modifiers/modify/weighted_normal.html (INFERRED that the exact URL path is current as of Blender 4.x; the feature has been present since Blender 2.80).
INFERRED - studio use. The weighted-normals technique is ubiquitous in hard-surface game art tutorials (e.g., the "hard surface modelling" courses on ArtStation Learning, various Polycount threads from 2019 onward). No single Sins/Homeworld/EVE source names "weighted normals" verbatim, but the visual result - perfectly flat panels with rounded bevels - is visible in the Sins II ArtStation breakdowns cited above. Marking the explicit studio endorsement as INFERRED.

1.3 High-to-Low Baking from a Clean Authored High Poly
What it is. An artist sculpts or models a high-resolution version of the ship (or of individual panels) by hand, with clean, intentional detail: panel lines, rivets, plate seams, vents. This high poly is then baked (normal map, AO, curvature, cavity) onto a clean low-poly game mesh. The key word is authored: the high poly is built deliberately, not generated by a noisy process.
What it fixes. Transfers fine surface detail into texture maps so the low-poly mesh stays clean and low-triangle. Because the high poly is authored, the artist controls exactly where detail goes and where surfaces stay flat. No stochastic waves, no blobs.
Cost per hull.
Metric | Estimate
Artist time | 2-5 days for a hero hull (modelling the high poly, UV-matching the low, baking, fixing projection errors). 0.5-1 day if baking small kit parts only
Triangle budget | High poly can be 500 k-2 M tris (never ships to game). Low poly stays at 8-30 k. The bake maps carry the detail at zero extra triangle cost at runtime
Free tool | Blender (Sculpt + Multires for high poly, bake panel for Normal/AO/Cavity/Diffuse). xNormal (free, Windows) for tangent-space normal baking. No Marmoset (paid)
Studio evidence.
Sins of a Solar Empire II - Martin Danlos. Explicitly shows "high poly modeling → low poly baked mesh (AO and Normal)." Source: https://martindanlos.artstation.com/projects/0lGmg8
Sins of a Solar Empire (original) - Polycount. "High res model baked to game res with xNormal, normal map and AO, 2048×4096 textures." Source: https://polycount.com/discussion/comment/1561334#Comment_1561334
EVE Online V3 overhaul. Every ship was redesigned to a new shader pipeline; the process involved reworking geometry and rebaking maps per ship. Source: https://www.engadget.com/2012-06-24-eve-evolved-the-great-ship-overhaul.html
Homeworld 3 - PC Gamer feature. Ships show per-weapon scarring and exposed internals on damage; the detail that reads at RTS distance is a combination of baked maps and geometry. The article is stronger on design intent than on exact bake pipeline, so the specific bake method is INFERRED. Source: https://www.pcgamer.com/inside-homeworld-3-how-blackbird-interactive-aims-to-make-you-feel-attached-to-your-fleet-as-you-see-the-history-of-battles-through-the-whole-campaign/

1.4 Trim Sheets
What it is. A single texture atlas (the "trim sheet") contains repeating strips of detail: panel lines, rivets, vents, grating, wear edges, hazard stripes. The artist UV-unwraps hull panels so they sample from the appropriate strip. One 2048×2048 or 4096×4096 trim texture can detail an entire fleet of ships.
What it fixes. Gives crisp, resolution-independent panel lines and edge detail without adding triangles. Because the strips are authored as straight, clean lines, they cannot introduce waves. They also enforce a consistent visual language across all hulls.
Cost per hull.
Metric | Estimate
Artist time | Creating the trim sheet: 1-2 days (one-time cost shared across all hulls). UV-mapping a hull to the trim sheet: 0.5-1 day per hull once the sheet exists
Triangle budget | Zero additional triangles. The hull mesh stays unchanged; all detail is in the UV layout
Free tool | Blender (UV editing, texture painting or importing a trim sheet made in GIMP/Krita). No paid tool needed
Studio evidence.
INFERRED - general industry practice. Trim sheets are a standard technique in game art, documented extensively in Polycount wiki articles and ArtStation tutorials. No single Sins/Homeworld/EVE source in the pack's seed list explicitly names "trim sheets," but the Sins II ArtStation post shows PBR texturing with repeating panel-line detail consistent with trim usage. Marking as INFERRED for the specific games cited.
Polycount hard-surface thread. Mentions "texture only" as the lowest-detail option for panel lines, which in practice means trim sheets or decal textures. Source: https://polycount.com/discussion/169587/spaceship-hardsurface-subdivision-polymodeling-learning-and-help

1.5 Mesh Decals and Floaters
What it is. Small detail meshes (decals, floaters) are placed slightly above or intersecting the hull surface. They carry their own geometry and sometimes their own small textures. Examples: access panels, warning labels, antenna dishes, pipe runs, conduit bundles. At RTS distance they read as surface variation; up close they add parallax and shadow.
What it fixes. Adds visual complexity without modifying the hull mesh, so the hull stays clean and planar. The decal geometry is modelled separately and can be as detailed as needed. No risk of introducing waves into the base surface.
Cost per hull.
Metric | Estimate
Artist time | 0.5-2 days to place 30-80 decals/floaters per hull from a pre-made kit. Creating the kit itself: 1-3 days
Triangle budget | 50-500 tris per decal. 50 decals ≈ 5-15 k tris added. At RTS distance, many can be culled or merged
Free tool | Blender (modelling the kit, snapping to surface with Shrinkwrap or manual placement). Export as separate objects or merge at export per FINDINGS R82 (static kit parts merged into hull mesh at export, rotating turrets separate)
Studio evidence.
Polycount hard-surface thread. Explicitly lists "mid-poly floater decals" as a detail tier between texture-only and full high-poly. Source: https://polycount.com/discussion/169587/spaceship-hardsurface-subdivision-polymodeling-learning-and-help
Sins of a Solar Empire II - Martin Danlos. The in-game shots show small detail parts (engine nozzles, antenna, panel frames) that read as separate meshes placed on the hull. Source: https://martindanlos.artstation.com/projects/AZ8DRX
Homeworld 3 - PC Gamer. Exposed internals and battle damage are described as layered detail on the hull, consistent with floater/overlay meshes. Source: https://www.pcgamer.com/inside-homeworld-3-how-blackbird-interactive-aims-to-make-you-feel-attached-to-your-fleet-as-you-see-the-history-of-battles-through-the-whole-campaign/

1.6 Texture-Only Detail at Distance vs. Geometry Detail Up Close
What it is. At RTS camera distance (hundreds to thousands of world-units), the eye cannot resolve individual triangles. Detail is conveyed entirely through normal maps, AO, curvature, and diffuse/albedo variation. As the camera moves in, geometry detail (bevels, kit parts, decals) becomes visible and takes over. Studios author both: a clean low-poly mesh with strong baked maps for distance, and enough geometric detail to reward close inspection.
What it fixes. Prevents the temptation to add triangles to "fix" a surface that looks wavy at distance. The wave is a shading problem, not a resolution problem; a normal map or a flat-shaded panel fixes it without extra geometry.
Cost per hull.
Metric | Estimate
Artist time | Baking and touching up maps: 0.5-1 day per hull if the high poly or trim sheet exists. Geometry detail for close-up: covered by methods 1.1-1.5 above
Triangle budget | Texture-only: 0 extra tris. Geometry close-up: per methods above
Free tool | Blender bake panel; GIMP or Krita for map touch-ups; xNormal (free) for dedicated normal baking
Studio evidence.
Sins of a Solar Empire (original) - Polycount. The art dump shows 2048×4096 normal and AO maps on a low-poly mesh, with "small details to sell ship scale" handled in the maps at distance. Source: https://polycount.com/discussion/comment/1561334#Comment_1561334
EVE Online V3. The ship overhaul moved to a new shader that leans heavily on texture-based detail (normal, specular, gloss maps) for the fleet view, with geometry kept moderate. Source: https://www.engadget.com/2012-06-24-eve-evolved-the-great-ship-overhaul.html
INFERRED - Stellaris. Paradox's ship renderer at galactic-zoom distance is essentially a textured billboard/impostor with minimal geometry; detail is almost entirely texture-driven. No developer art talk located. Marking INFERRED.

1.7 Planar Surfaces Kept Planar by Construction
What it is. The most fundamental rule in hard-surface modelling: if a panel is supposed to be flat, model it flat. Use quads aligned to the panel, keep vertices coplanar, and do not let curvature from adjacent surfaces bleed across. In Blender, this means using the "Flat" shade mode on those faces, or a Weighted Normal modifier, and avoiding unnecessary edge loops that introduce curvature.
What it fixes. Prevents the root cause of waves: a surface that should be flat but has been inadvertently curved by the modelling tool, by subdivision, or by noisy vertex positions.
Cost per hull.
Metric | Estimate
Artist time | 0 extra if done during initial modelling. 2-6 hours to flatten an existing wavy hull (select faces, scale to zero on the normal axis, or use "Make Planar" / "Flatten" tools)
Triangle budget | Often reduces triangles (removing unnecessary loops) or keeps them the same
Free tool | Blender: select faces → S → Z → 0 (flatten on axis), or Mesh > Transform > Make Planar. Also the "Flatten" brush in Sculpt mode with low strength for gentle correction
Studio evidence.
Polycount hard-surface thread. The foundational advice in the thread is to build panels flat and keep them flat; subdivision is used on curved sections only. Source: https://polycount.com/discussion/169587/spaceship-hardsurface-subdivision-polymodeling-learning-and-help
EVE Online - Art of Retribution. The block-out phase establishes flat panels and simple curves before any detail is added. Source: https://community.stratics.com/threads/developer-blog-the-art-of-retribution.287865/

2. Cleaning Up AI-Generated Meshes in Production
This section addresses the specific problem in issue #111: the project has AI-generated meshes with low-frequency waves and blobby detail that do not match the clean hard-surface look of shipped games. The question is how to salvage useful information from those meshes without carrying the waves forward.

2.1 High-to-Low Baking (from AI mesh as source)
Bake normal, AO, and curvature maps from the AI mesh onto a clean low-poly shell. The low shell must be authored by hand with flat planes where the hull should be flat and faired curves elsewhere (per issue #111 variant 2). The AI mesh serves only as the bake source, never as the final geometry.
Critical caveat: A straight tangent-space normal bake will transfer all surface variation from the source, including the low-frequency waves. This must be filtered. See 2.2.
Free tools: Blender bake panel, xNormal (free, Windows).

2.2 High-Pass or Cavity-Only Baking
The problem. AI meshes typically have low-frequency undulation (waves spanning several centimetres to decimetres in world space) superimposed on the fine detail (panel lines, rivets, small bevels). A normal bake transfers both. The result is a clean low-poly mesh that still looks wavy because the normal map encodes the waves.
The fix.
High-pass bake. After baking the tangent-space normal map, apply a high-pass filter in an image editor (GIMP, Krita, or Blender's compositor). The high-pass removes low-frequency normal variation (the waves) while preserving high-frequency detail (rivets, seams, scratches). In practice: duplicate the normal map, apply Gaussian blur at a radius matching the wave wavelength (typically 20-80 px at 2048²), subtract the blurred version from the original, re-centre to 0.5 grey. This is the "high-pass" step.
Cavity-only bake. Instead of a full normal map, bake only the cavity/crevice map (Blender's "Cavity" pass in the bake settings, or the Ambient Occlusion pass with a short ray distance). Cavity captures the fine recesses (panel lines, gaps between plates) without encoding broad surface curvature. Use the cavity map as a mask for dirt and wear, and combine it with a flat normal map (or no normal map) on the hull's large surfaces.
Combined approach. Bake full normal → high-pass it → combine with a separate AO/cavity bake. This gives fine detail without waves.
Free tools. Blender (bake, compositor for high-pass), GIMP or Krita (high-pass filter as a layer operation). No paid tool required.
INFERRED: The specific high-pass workflow for normal maps is widely discussed in Polycount threads and ArtStation tutorials on normal-map cleanup. No single source from the pack's seed list names it verbatim for AI mesh cleanup specifically, because AI mesh cleanup in game pipelines is a very recent topic (2024-2026). The underlying technique (high-pass filtering a normal map) is well-established. Marking the AI-specific application as INFERRED but the technique itself as sourced.

2.3 Planar Flattening
Select the faces on the low-poly shell that should be flat (hull plates, deck surfaces, engine housings) and flatten them: in Blender, select faces → S → axis → 0, or use Mesh > Transform > Make Planar. For gently curved surfaces that should be smooth but not wavy, use the "Flatten" sculpt brush with low strength and a large radius to average out the undulation while keeping the overall curve.
This is done before baking if the AI mesh is the bake source, or after if the low shell is being corrected directly.
Free tool: Blender.

2.4 Weighted Normals on the Cleaned Shell
After flattening and before texturing, apply the Weighted Normal modifier (Face Area mode) to the low shell. This ensures that any remaining minor vertex displacement does not create visible shading waves on flat panels. Cost: one modifier, zero extra triangles, seconds to apply.
Free tool: Blender (Weighted Normal modifier).

2.5 Trim Sheets over the Cleaned Shell
UV-map the flattened, weighted-normals shell to a trim sheet. Panel lines, plate seams, rivet rows, and wear edges come from the trim texture. This replaces any attempt to get panel-line detail from the AI mesh's geometry. The trim sheet is authored once and reused across all 36 hulls (per FINDINGS R82, the 36-hull fleet).
Free tools: Blender (UV mapping), GIMP/Krita (trim sheet authoring).

2.6 Decals and Greeble Kits on the Cleaned Shell
Place pre-made greeble kit parts (vents, pipes, access panels, antenna) onto the clean shell on visible mounts (per issue #111 house rules: parts snapped onto the real surface on visible mounts). Use mesh decals for flat detail (warning stripes, hull numbers, faction insignia). Per FINDINGS R82, static kit parts merge into the hull mesh at export; rotating turrets stay separate.
Free tool: Blender.

2.7 Part Splitting
If the AI mesh has regions that are genuinely good (a well-shaped engine block, a clean turret housing), cut those regions out as separate parts, clean their edges, flatten their mounting faces, and re-seat them on the clean shell as kit parts. This is issue #111 variant 3. The key step is that each extracted part gets its own flat mounting face and is placed on a visible mount, so no wave from the original mesh propagates into the assembly.
Free tool: Blender (knife cut, separate by selection, cleanup).

3. Direct Answer to Ryan's Question
"Is there alternative approaches we should consider along with A? Another way to approach meshing? More triangles and detail in the mesh to smooth out the waves? This can't be a singular problem with our meshes, how do others handle it?"
Does adding more triangles and detail to the mesh smooth out the waves?
No. Adding triangles to a wavy surface does not flatten it; it subdivides the wave into smaller waves. The low-frequency undulation is a positional problem (vertices in the wrong place) and a shading problem (normals pointing the wrong way), not a resolution problem. A 500-triangle flat quad and a 50 000-triangle flat quad both shade perfectly flat. A 500-triangle wavy quad and a 50 000-triangle wavy quad both shade as wavy; the higher-res version just has smoother wave crests.
The reason this is not a "singular problem" is that every studio avoids it by construction rather than by adding resolution:
They build in parts (method 1.1), so no single surface is large enough to wave.
They keep flat faces flat (method 1.7) and use weighted normals (method 1.2) to enforce flat shading.
They bake detail from a clean high poly (method 1.3), so the low-poly mesh never inherits noise.
They use trim sheets and decals (methods 1.4, 1.5) for detail that does not touch the hull surface.
They rely on texture detail at RTS distance (method 1.6), where the eye cannot resolve geometry anyway.
The AI-generated meshes have waves because the generation process does not enforce planarity or part boundaries. The fix is not more triangles; it is rebuilding the surface clean (variant 1), baking only the high-frequency detail from the AI mesh with a high-pass filter (variant 2), or cutting out the good chunks and re-seating them as kit parts (variant 3). All three variants in issue #111 are consistent with how shipped games handle this.
Alternative approaches along with A:
Trim sheet + decal pass over variant A geometry (already included in variant 1's spec).
Weighted normals on every flat surface (zero cost, immediate visual fix).
High-pass filtered bake from the AI mesh onto variant A's clean shell to recover fine detail without waves (bridges A and variant 2).
Greeble kit instancing to add density without touching the hull surface.
All of these are free-tool workflows in Blender.

4. Ranked Recommendation for Pyre-Barge Round 2 (Issue #111)
Based on the sources reviewed, the three proposed variants are ranked below, plus one additional alternative the sources support.
Rank 1 - Variant 1: A+ clean kit shapes + bevels, panel lines, greeble kit, decals, wear
Why first. This is the method used by Sins of a Solar Empire II (Danlos ArtStation), EVE Online (Art of Retribution block-out → part assembly), and the Polycount hard-surface consensus. It produces the cleanest result at both RTS distance and close-up. The Hullbreaker rust-and-bone palette, weighted normals on bevelled edges, and a greeble kit give the Pyre-Barge the "detailed but clean" look that shipped games have. Cost is the highest in artist time (3-6 days) but the result is the most controllable and the most consistent with the project's house rules (parts on visible mounts, guns forward, no projected concept paint).
Chair pick for the comparison sheet. This should be the "hero" variant that the other two are measured against.
Rank 2 - Variant 2: Clean shell + AI detail baked as maps (high-pass / cavity-only)
Why second. This is the fastest way to recover useful detail from the existing AI meshes without carrying the waves forward. The high-pass bake is a well-established technique (see §2.2). It directly answers Ryan's question about whether the AI detail can be saved. The before/after crop of a wavy panel is a strong proof point. Cost is moderate (1-2 days). The risk is that the baked detail may look "pasted on" if the UV layout and tangent frame are not clean, and it will not have the parallax of real geometry at close range.
Chair pick for the comparison sheet. This is the variant that most directly tests the AI-cleanup pipeline. If the high-pass bake reads well at RTS distance, it could be applied fleet-wide to all 36 hulls at low cost.
Rank 3 - Variant 3: Clean hull + reused AI chunks as kit parts
Why third. This is a pragmatic salvage method. It works when the AI mesh has isolated regions of good topology (an engine bell, a sensor dish, a turret housing) that can be cut out, cleaned, and re-mounted. The Polycount thread's advice on part splitting supports this. However, it is the most labour-intensive per part (each chunk needs edge cleanup, flattening of the mount face, and re-seating), and the result is only as good as the best chunks. If the AI mesh is mostly wavy, there may be few chunks worth saving.
Chair pick for the comparison sheet. Include it, but time-box the chunk selection. If fewer than 5-8 usable parts come out of the AI mesh, fold the good shapes into variant 1's greeble kit and drop variant 3 as a standalone.
Rank 4 (additional) - Trim-sheet-only detail pass over variant 1 or 2
Why here. The sources support a trim-sheet approach as a low-cost, fleet-wide detail layer. A single 4096×4096 trim sheet with panel lines, rivets, vents, and wear strips in the Hullbreaker palette could detail all 36 hulls with zero extra triangles and about 1 day of UV-mapping per hull. This is not a separate variant but a force multiplier for variants 1 and 2. It is ranked fourth because it does not stand alone (it needs a clean shell underneath) but it should be applied to whichever variant wins.
Chair pick. Apply the trim sheet to the winning variant as a final pass.

5. Per-Method Cost Summary Table
Method | Fixes | Artist time per hull | Triangle cost | Free tool
Part splitting / kit parts / greeble kit | Waves (no large continuous surface); adds scale detail | 3-6 d (hero); 1-2 d (kit reuse) | +200-2 000 tris per part, instanced | Blender
Bevelled mid-poly + weighted normals | Shading waves on flat panels; pinched bevels | +10-20 % modelling time; or 2-5 h retrofit | +50-100 % on bevelled edges; 0 for normals | Blender
High-to-low bake (authored high poly) | Replaces noisy surface with clean mesh + maps | 2-5 d (hero); 0.5-1 d (kit parts) | 0 extra tris at runtime | Blender, xNormal
Trim sheets | Panel lines, seams, wear without geometry | 1-2 d sheet creation (once); 0.5-1 d UV per hull | 0 tris | Blender, GIMP/Krita
Mesh decals / floaters | Surface variety without hull modification | 0.5-2 d placement per hull | +50-500 tris per decal | Blender
Texture-only at distance | Detail at RTS without triangles | 0.5-1 d bake + touch-up | 0 tris | Blender, GIMP/Krita
Planar flattening | Root-cause wave removal | 0 (by construction) or 2-6 h retrofit | 0 or negative (removes loops) | Blender
High-pass / cavity-only bake | Removes low-freq waves from AI bake | +2-4 h per hull over standard bake | 0 tris | Blender compositor, GIMP/Krita

6. Sources Cited
# | Source | URL | Used for
S1 | Martin Danlos - Sins of a Solar Empire II spaceship assets (technical breakdown) | https://martindanlos.artstation.com/projects/0lGmg8 | Part splitting, high-to-low bake, AO + Normal workflow
S2 | Martin Danlos - Sins of a Solar Empire II spaceships (in-game, PBR) | https://martindanlos.artstation.com/projects/AZ8DRX | Kit parts, decals, in-game result at RTS distance
S3 | Sins of the Solar Empire (original) art dump - Polycount | https://polycount.com/discussion/comment/1561334#Comment_1561334 | xNormal bake, 2048×4096 textures, small details for scale
S4 | EVE Online V3 ship overhaul - Engadget | https://www.engadget.com/2012-06-24-eve-evolved-the-great-ship-overhaul.html | Fleet-wide shader/texture rework, per-ship redesign
S5 | EVE Online - Art of Retribution dev blog (Stratics mirror) | https://community.stratics.com/threads/developer-blog-the-art-of-retribution.287865/ | Block-out process, silhouette-first design, part assembly
S6 | Homeworld 3 - PC Gamer feature | https://www.pcgamer.com/inside-homeworld-3-how-blackbird-interactive-aims-to-make-you-feel-attached-to-your-fleet-as-you-see-the-history-of-battles-through-the-whole-campaign/ | Detail at distance, battle damage as layered detail
S7 | Polycount - Spaceship hard-surface subdivision thread | https://polycount.com/discussion/169587/spaceship-hardsurface-subdivision-polymodeling-learning-and-help | Part splitting, panel detail tiers, flat-panel construction
S8 | Blender Manual - Weighted Normal modifier | https://docs.blender.org/manual/en/latest/modeling/modifiers/modify/weighted_normal.html | Weighted normals method (INFERRED exact URL current for 4.x)
Not found in this leg (flagged for follow-up or Argon review):
Battlefleet Gothic: Armada 2 - no public art breakdown or developer talk located.
Stellaris - no public ship-art pipeline talk located.
Starsector - 2D sprite-based; no 3D hard-surface source applicable.
Marmoset hard-surface cargo ship tutorial - exists but Marmoset is paid; cited for method awareness only per pack instructions, not recommended as a tool.

7. INFERRED Claims Log
All claims marked INFERRED in the body are collected here for the Rey chair screen:
Starsector's layered sprite composition as an analogue of part splitting (§1.1). No 3D source; inferred from visible asset structure.
Battlefleet Gothic: Armada 2 uses part-split construction (§1.1). Inferred from in-game visuals; no developer source found.
Stellaris uses modular kit parts for ships (§1.1). Inferred from in-game visuals; no developer source found.
Weighted normals are used by the cited studios (§1.2). The technique is visible in the results but no studio source names it verbatim.
Trim sheets are used in Sins II / EVE / Homeworld 3 (§1.4). Consistent with visible texture work but no source names "trim sheet" for these titles.
Stellaris at galactic zoom is essentially texture-driven (§1.6). Inferred from rendering behaviour; no developer source.
High-pass filtering of normal maps applied specifically to AI mesh cleanup (§2.2). The technique is established; its application to AI meshes is inferred because AI mesh cleanup in game pipelines is too recent for published case studies.
Blender manual URL for Weighted Normal modifier (§1.2, S8). Exact URL path inferred for current Blender 4.x documentation.

8. Not Checked
I did not run Blender to verify modifier names or bake settings in this session; tool names are from training data and the pack.
I did not verify whether the Polycount, ArtStation, Engadget, Stratics, and PC Gamer URLs are live as of 2026-11-04; they are reproduced verbatim from the pack's source seeds.
I did not test the high-pass bake workflow on an actual AI mesh; the steps are described from technique knowledge.
FINDINGS R83 route B (remesh + PBR) is noted as out for machine hulls per the pack; I did not re-evaluate it.
No Marmoset tool is recommended anywhere in this leg per the free-tools constraint.
End of Qwen leg. File to be placed at contrib/muse/research/ship_surface_methods_2026_11/legs/qwen.md.
