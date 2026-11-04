DeepSeek leg: ship look round 3 research

Scope and working constraints

This leg answers the four issue questions with a ranked recommendation each, then proposes a concrete Pyre-Barge round 4 under R92. It respects the binding rulings: no projected concept paint, no Route B remesh for machine hulls, repair-in-place is the current direction, hand parts are the round 3 default, and the refreshed Hullbreaker look is the round 4 target. Cost figures are human hours unless marked machine hours; figures marked INFERRED are extrapolations from the round data in the pack and are not sourced.

Q1. Painting and materials

Why the old projection produced a grid and double lighting

The old route projected a painted concept image onto the hull through a camera or planar projection and baked it into the albedo. That creates two distinct failures.

The grid is the projection lattice showing through. A 2D image projected through a frustum onto a curved, faceted hard-surface mesh cannot maintain uniform texel density. Surfaces oblique to the projection direction stretch texels; surfaces at UV island borders or hard creases break the mapping. The result is visible seams, stretching, and a lattice-like pattern following the projection/UV layout, not a property of the concept art. This is the standard failure mode of projected textures without a proper UV parameterization; Blender's own documentation and community fixes describe seam and projection artefacts at UV borders. If the concept image itself carried a visible grid or panel lattice, projection paints it on as well. The "grid" is therefore a geometry/UV problem, not a paint problem.

Double lighting is baked illumination meeting real-time illumination. A painted concept contains its own light direction, shadows, highlights, and ambient occlusion. Projecting that into albedo bakes painted lighting into base colour. A PBR engine then calculates all lighting at runtime and adds it on top. The result is "double-dipping": shadows go too dark, highlights blow out, and the asset cannot be relit correctly. This is explicitly documented as a critical texture-authoring error: PBR engines calculate all lighting at runtime; baked lighting in albedo causes double-lighting artefacts. The AI normal map compounds the problem because it carries low-frequency shading from the AI mesh; flattening the geometry does not remove the waves, because the waves live in the normal map and the projected paint, as R86 already observed.

The correct target is therefore: flat, evenly lit albedo; roughness/metallic as separate physical maps; normal detail that is high-frequency only; and wear driven by curvature/AO/edge masks rather than painted shadows. The material routes below are ranked by how well they achieve that on a 36-hull fleet maintained by a small team.

Ranked material routes

Rank 1: Blender procedural smart materials plus shared trim sheets and decal atlases (fleet default).
Use Blender's Shader Editor with Geometry Pointiness as a curvature proxy, the Ambient Occlusion shader for cavity masks, and ColorRamps to drive edge wear, cavity dirt, rust break-up, and bare-metal exposure. Blender's manual explicitly describes the AO shader for procedural weathering at corners, and Pointiness as the cheaper curvature alternative. Build one shared trim sheet per faction and a decal atlas for markings, hazard stripes, trophy plates, and faction insignia. Material Maker is a free, MIT-licensed procedural material authoring tool that can produce the PBR graphs and export textures compatible with Blender/Godot/Unreal.

What it fixes in our sheets: removes grid and double lighting; gives soot/rust/bare-metal separation; adds panel lines without geometry; puts wear on edges and dirt in cavities; carries the Hullbreaker palette and trophy plates.
Cost: one-time faction material/trim/decal library 60 to 100 human hours (INFERRED); 4 to 8 human hours per new hull to instantiate and tune (INFERRED). This is the only route that is deterministic, batchable, and does not reintroduce per-hull AI variance.

Rank 2: Open-source painters (Material Maker and ArmorPaint) for hero hulls and unique plates.
Material Maker can paint 3D models as well as author procedural graphs; ArmorPaint is a GPU-accelerated PBR painter whose source is free to compile, though distributed binaries are paid. These are the right tools for hand-painted trophy plates, unique flagship wear, hand-lettered insignia, and art-directed damage that procedural masks cannot plausibly invent.

What it fixes: bespoke flagship character, trophy plates, painted decals that need brush-level control.
Cost: 8 to 16 human hours per hero hull; 4 to 6 per simple hull (INFERRED). Not efficient as the fleet default, but valuable as a hero pass on top of Rank 1.

Rank 3: Local AI texturing (StableProjectorz, Hunyuan3D-Paint) for proposal base colour and roughness, not fleet default.
StableProjectorz is a free, open-source (AGPL-3.0) desktop tool that projects Stable Diffusion generations onto a mesh while preserving UVs, using depth and view-space normals through ControlNet, with up to six view arrangements and depth-aware rejection of projection leaks. Hunyuan3D-Paint 2.1 can texture an existing hand-built mesh, not just its own generated mesh, and outputs PBR base colour and metallic-roughness. These tools can propose a rich base-colour/roughness pass quickly, but they reintroduce exactly the two risks we are trying to kill: painted lighting in albedo and projection seams. They are acceptable only with a deliberate delighting step (strip highlights/shadows, rebuild flat albedo, multiply AO separately), strict albedo value checks (50 to 240 sRGB, evenly lit), and human cleanup.

What it fixes: fast base-colour/roughness ideation on a hero hull, painterly wear variation.
Cost: 1 to 3 machine hours plus 4 to 8 human cleanup hours per hull (INFERRED). Not recommended for the 36-hull fleet default.

What shipped space games actually use at RTS distance

The shipped practice is not projected concept paint. It is shared material maps, masks, trim/atlases, decals, and procedural damage.

Homeworld 3 uses three UV channels per ship: UVMap0 for standard textures, UVMap1 for badge projection, UVMap2 non-mirrored for team colour and Splat Damage. Its texture set is Base Color, Emissive, Normal, ARM (R=AO, G=Roughness, B=Metallic, A=Height), MASK (R=Dust/Dirt, G=Engine, B=Panel, A=Team Colour), and TEAM maps. Ships also carry a dynamic Splat Damage texture that procedurally adds damage in the hit area. This is a mask/trim/atlas pipeline with dynamic damage, not unique painted projections.

EVE Online's V5++ reworked all ship texture maps into PBR: albedo, roughness, a four-tone-greyscale material map, a new dirt map, and an AO map on every ship. The material map expands the number of materials per hull and gives controlled rust and metal behaviour. Again, the emphasis is packed material maps and masks, not projected concept lighting.

The implication for a 36-hull RTS fleet is clear: shared faction trim sheets, mask-driven wear, decal atlases, and procedural damage are the scalable shipped-game pattern. Unique projected paint is the outlier that produced our grid and double lighting.

Q2. Mixing AI mesh and hand-built

Ranked splits

Rank 1: AI-generated greeble/part libraries, reviewed once and reused.
Generate candidate small parts from isolated concept crops or text prompts, review them once for shape, mounting, and frame, then put the approved parts into a per-faction kit library. Round 3 tested AI parts generated one at a time and hand parts won, but that was per-part generation without a library and review pipeline. A reviewed library changes the economics: the human review cost is paid once, and the approved parts are reused across many hulls. This is also the closest fit to how small teams actually use AI 3D in production, as a kitbash/ideation source, not as an unreviewed final asset. Tripo's own workflow guidance frames AI generation and kitbashing as complementary rather than exclusive.

Tools: TRELLIS.2 or Hunyuan3D 2.1 for candidate generation; Blender for cleanup, mounting-face seating, and kit assembly.
Cost: 20 to 40 machine hours plus 40 to 60 human review hours one-time; 2 to 4 human hours per hull reuse (INFERRED).
What it fixes: greeble density, small fittings, engine/gun/bridge variety, and the "sparse kit" problem from round 1, without hand-modelling every small part. Hero shapes stay hand-built.

Rank 2: AI mesh as the hull body, hand-built parts as hero parts (the round 3 split).
This is the fastest way to get a blockout with irregular bulk, and it is what round 3 actually did. It is acceptable for non-hero hulls or as a base mesh, but the AI hull carries low-frequency waves, fused guns/tanks, and wrong part contours; repair-in-place is mandatory. Round 3's own result showed the AI engine crop expanded into a stern assembly, the bridge retry invented a tall stepped tower, and the gun read as disconnected masses.
Cost: 0.1 to 0.5 machine hours per generation; 10 to 20 human cleanup hours per hull (INFERRED).
What it fixes: silhouette bulk and irregular detail. Risk: reintroduces the waves and fused-part problems unless the AI hull is treated as a rough blockout.

Rank 3: Hand-built primary masses with AI detail baked on.
Baking AI normal/AO onto hand-built masses can add micro-detail without AI geometry, but the AI normal carries low-frequency waves and the bake can ghost medium-scale donor machinery. Round 2 variant 2 already showed ghosting when donor detail was copied; baking AI detail is the same failure mode with a different source. This is usable only for micro-detail on flat panels, not for structural detail.
Cost: 6 to 12 human hours per hull (INFERRED).
What it fixes: surface micro-detail without extra triangles. Risk: ghosting, soft edges, double detail.

Rank 4: Part-aware generation.
Part-aware models are the most interesting research direction, but they are not production-ready for a 16 GB card and a small team. Part3DGen runs in a low-VRAM mode at about 15 GB with no more than 10 parts, and 24 GB for non-low-VRAM. PartCrafter reports 8 to 16 GB and is research code; part completion can over-complete, and some parts may not be textured because of occlusion. Use these to propose part decompositions and candidate splits, not to produce final geometry.

Cost: 1 to 3 machine hours plus 10 to 20 human cleanup hours (INFERRED).
What it fixes: part-separation proposals and part-library seeding. Risk: unstable part counts, manual merging, research-grade tooling.

What has worked for small teams

The pattern that keeps appearing is: AI generates candidates at the edges of the pipeline, humans own the hero shapes and the review gate. AI is used for reference/image generation, kitbash candidates, and low-poly background assets; final hero parts are hand-built or hand-cleaned. A batch pipeline can generate hundreds of low-poly assets with embedded PBR maps, but it still needs quality gates and retopo. The round 3 result, AI parts losing to hand parts when generated one at a time, is not an argument against AI parts in principle; it is an argument against unreviewed per-part generation. A reviewed library is the correct way to use AI parts without repeating that result.

Q3. AI mesh models

Model survey

TRELLIS.2 (4B). Licence: MIT, ungated. VRAM: Official 24 GB or more; ComfyUI low-VRAM minimum 8 GB, recommended 16 GB+. Input: Single image; multi-view workflows in ComfyUI. Output: PBR-textured GLB; Gaussians + mesh. Hard-surface notes: Strong hard-surface, sharp edges, nested/open topology; PBR in one pass. 16 GB fit: Yes, with low-VRAM/tiled decode; 16 GB is the recommended floor, not headroom. Part separation: No native part-aware output; split after generation. Rank: 1.

Hunyuan3D 2.1. Licence: Tencent Hunyuan Community Licence: free commercial under 1M MAU, excludes EU/UK/South Korea. VRAM: 10 GB shape; about 29 GB full shape+texture. Input: Single image and multi-view (mv_image_front/back/left/right). Output: Shape + PBR texture; Paint 2.1 can texture an existing mesh. Hard-surface notes: Best-in-class flat planes, symmetry, clean part seams; topology weak on complex hard-surface mechanical parts. 16 GB fit: Shape-only yes (10 GB peak on RTX 5080); full texture pipeline no. Part separation: No native part-aware output. Rank: 2 (shape comparison only).

TRELLIS 1 (image-large). Licence: MIT. VRAM: about 16 GB. Input: Single image. Output: Textured GLB / Gaussians. Hard-surface notes: Good baseline, lower fidelity than TRELLIS.2; at the 16 GB floor. 16 GB fit: At the floor; workable but tight. Part separation: No. Rank: 3.

Hi3DGen. Licence: MIT. VRAM: about 24 GB conservative workstation floor. Input: Single image, 1024 preprocess. Output: Geometry only (no texture pipeline). Hard-surface notes: Normal-bridged high-fidelity geometry; good for hard-surface shape study. 16 GB fit: Not comfortably on 16 GB. Part separation: No. Rank: 4.

Step1X-3D. Licence: Apache 2.0. VRAM: 27 to 29 GB. Input: Single image. Output: Textured 3D mesh. Hard-surface notes: High-fidelity geometry + texture alignment; too heavy for 16 GB. 16 GB fit: No. Part separation: No. Rank: 5.

Pixal3D. Licence: Tencent academic/non-commercial; explicitly not for EU use. VRAM: 16 GB minimum, 24 GB+ recommended. Input: Single image. Output: PBR-textured mesh. Hard-surface notes: Good PBR output, but licence blocks production use. 16 GB fit: Yes at minimum, but licence is disqualifying. Part separation: No. Rank: 6 (licence).

Part3DGen / PartCrafter (part-aware research). Licence: Research code; check repository licence. VRAM: Part3DGen about 15 GB low-VRAM; PartCrafter 8 to 16 GB. Input: Single image. Output: Part-level meshes. Hard-surface notes: Promising part decomposition, but unstable part counts and manual merging. 16 GB fit: Part3DGen marginal; PartCrafter possibly. Part separation: Yes, but research-grade. Rank: 7 (experiment only).

Ranked recommendation for the Pyre-Barge work

Rank 1: TRELLIS.2. It is the best combination of licence safety (MIT), hard-surface quality (sharp edges, complex topology, PBR in one pass), and a practical 16 GB path through ComfyUI low-VRAM/tiled decode. It is the model to use for Route 2's full-resolution regeneration experiment and for the AI part-library candidates.

Rank 2: Hunyuan3D 2.1 shape-only, for comparison. It has the best flat-plane and part-seam behaviour in current tests, and multi-view input is supported. But the community licence is not OSI-open, excludes the EU/UK/South Korea, and the full texture pipeline needs about 29 GB. On a 16 GB card it is a shape-proposal tool, not a full pipeline. Use it only as a comparison against TRELLIS.2, and only if the licence geography is acceptable.

Rank 3: TRELLIS 1. A useful baseline when TRELLIS.2's low-VRAM path is unstable, but it is lower fidelity and already at the 16 GB floor.

Do not use for production: Pixal3D (non-commercial licence), Step1X-3D (27 to 29 GB, no 16 GB path), Hi3DGen (24 GB floor, geometry only). Part-aware models are experiment-only until they produce stable part counts and texture all parts without manual repair.

How to prepare reference views to get flat panels and separate parts

The single most important practical finding is: do not feed a composite character sheet to an image-to-3D generator. A sheet with four views in one image is interpreted as four fused figures or a statuette, not as four views of one object. Feed separate, single-view images instead.

For flat panels and separate parts:

- Use orthographic views, not perspective. Front, back, left, right, top, and one 3/4 beauty view for the hand modellers.
- Keep a clean neutral grey background, consistent scale, and consistent lighting across views.
- For multi-view models, use 4 to 6 separate views (Hunyuan3D 2.1 supports up to 6 to 9 views in its paint stage; TRELLIS.2 ComfyUI workflows accept multi-view inputs).
- Include detail crops of the bow hunting gear, boarding claws, chains, trophy plates, engine bells, and weapon clusters as separate images. These are the hero parts that must not be hallucinated into neighbouring structures.
- Prompt for "orthographic product shot, flat even lighting, no shadows, grey background, single object" rather than "concept art" or "oil painting." Concept-art prompts produce painterly lighting that the model bakes into albedo.
- Expect 1 to 25 million native triangles from a full-resolution generation. Plan for retopo/decimation and part splitting; do not import the raw mesh into the hull.

Q4. The reference

Reference sheet design

Build a master reference sheet for humans and a separate set of single-view images for generators. The master sheet should contain:

- orthographic front, back, left, right, and top views at consistent scale;
- one 3/4 view for silhouette and mass read;
- material-zone callouts: soot rust plate, dried blood red, hot red, bare metal, engine glow, dim red running lights;
- detail callouts: listening dishes, wake sniffer scoops, boarding claws, chains, trophy plates (flagship only), armoured belly with chines, sensor housings, antenna arrays, equipment pods, recessed lights, thruster pods, docking hatches, heat radiators, scrap gun turrets, rocket pod clusters, chaff guns;
- a scale bar and a one-line silhouette rule: low, heavy, lopsided, bulk/asymmetry/red light at battle distance.

The generator set should be the same views as individual 1024x1024 images, grey background, no perspective, no composite sheet. This avoids the fused-figure failure and gives the model unambiguous view constraints.

Whether to regenerate concepts for the whole fleet first

No. Lock the Pyre-Barge reference first. Round 4 is explicitly a three-way comparison against the refreshed Hullbreaker look, and the new reference has not yet been tested against any route. Regenerating 36 hulls before the round 4 result would multiply an unproven reference across the fleet and repeat the C19_51 problem at scale. The calibration set remains the three issue #75 hulls (Pyre-Barge, Eclipse zenith, Ninefold Maw), with the Pyre-Barge as the flagship test. Once one route wins on the Pyre-Barge against the new reference, then create a faction template and propagate.

Reference production procedure and cost

1. Block out the Pyre-Barge proportions in Blender from the faction look rules (low, heavy, lopsided; bow hunting gear forward; chains between hull sections; armoured flat belly). 4 to 6 human hours (INFERRED).
2. Render five orthographic views plus one 3/4 view at 1024x1024 with a neutral grey background and flat lighting. 2 to 3 human hours (INFERRED).
3. Paint over the renders with material zones, palette swatches, and detail callouts. 8 to 12 human hours (INFERRED).
4. Export separate single-view PNGs for generators; keep the composite sheet for hand modellers. 1 to 2 human hours.
Total first-ship reference: 16 to 24 human hours (INFERRED). Subsequent hulls using the same template: 4 to 6 human hours each (INFERRED).

Concrete round 4 proposal for the Pyre-Barge (issue #146, under R92)

R92 defines three compared routes. The proposal below keeps all three, but sequences them so the owner gets a decision with the least wasted work.

Route 1: #129 stage 5 plus a full texture, material, and paint pass

What to keep from rounds 1 to 3: stage 3 separation (176 regions, grooves, worn-edge strips) and the stage 5 hand parts (engine, gun pair, bridge) plus weighted normals at 305,857 tris. Do not re-run stage 5 against the old C19_51 concept; that target is dead.

What to change: rebuild the material stack from scratch against the new Hullbreaker reference. Use Blender procedural smart materials (Pointiness/AO masks) plus a shared Hullbreaker trim sheet and decal atlas. Strip any projected paint and any AI normal map that carries low-frequency waves; replace with high-frequency normal detail and flat albedo. Add trophy plates as decals on the flagship only. Add the soot/rust/dried-blood/hot-red palette and the dim red running lights/engine glow.

What it fixes in our sheets: the grid and double lighting disappear; material separation (soot plate vs rust vs bare metal vs engine glow) becomes controllable; the faction read at battle distance becomes testable against the new reference.
Cost: 6 to 10 human hours for the material/paint pass on top of the existing stage 5 (INFERRED).
Risk: stage 5 geometry was built against the old concept; its broad masses may still not match the new reference. This route tests materials, not silhouette.

Route 2: whole ship regenerated at full resolution from new reference views

What to change versus rounds 1 to 3: do not regenerate from a single concept crop. Use separate orthographic views from the new reference sheet and a multi-view-capable model. TRELLIS.2 is the primary candidate (MIT, hard-surface, 16 GB low-VRAM path); Hunyuan3D 2.1 shape-only is the comparison if licence geography allows. Generate 3 seeds per view set, retopo/cleanup, and split parts before assembly. Do not accept the raw 17 to 25 million-triangle output.

What it fixes in our sheets: tests whether a multi-view, high-resolution regeneration can match the new silhouette and produce flat panels and separate parts, the exact failure of the earlier single-crop AI parts.
Cost: 0.2 to 0.5 machine hours per generation seed; 10 to 20 human cleanup hours per candidate (INFERRED).
Risk: the AI hull still carries waves and fused parts; this route is only a winner if multi-view input demonstrably reduces both. If it does not, stop after one candidate and do not roll it out.

Route 3: hand-modelled against the new reference with kit parts at today's detail density

What to change versus rounds 1 to 3: build the primary masses by hand against the new low/heavy/lopsided reference, not the old C19_51. Use stage 3 separation and the stage 5 hand parts as the starting vocabulary. Use the current kit parts at today's detail density; R83 left the door open to an upgraded LOD, but round 4 should first test today's density so the comparison is fair. Add the bow hunting gear, chains, and boarding claws as hand-built hero parts.

What it fixes in our sheets: controlled shapes, no AI waves, exact faction silhouette.
Cost: 8 to 14 human hours with existing tools (extrapolated from round 1 Route A and round 3's 8 to 12 hour rollout estimate; INFERRED).
Risk: it can come out sparse and blocky, as round 1 Route A did. The battle-distance test is the guard against that.

Metrics the owner should judge by screenshots

Every route should be captured at the same three conditions:

- Battle distance: fleet-scale screenshot, no zoom, with the ship at the same on-screen size as in-game. Judge silhouette read: bulk, asymmetry, red light, bow hunting gear.
- Grazing crop: low-angle close crop on a large panel and on the bow. Judge panel flatness, wave residue, seam visibility, and whether the normal map is doing the work or the geometry is.
- Head-on material crop: straight-on crop of a soot plate, a rust patch, a trophy plate, and an engine bell. Judge albedo cleanliness (no baked shadows), material separation, and whether the palette reads as Hullbreaker.

Also report: triangle count, 20-ship GPU time, and human hours spent. A route that wins on beauty but doubles the draw cost or the cleanup hours is not a fleet route.

Recommendation

Run Route 1 first. It is the lowest-risk path to test the new reference, it directly attacks the material problems that the three rounds proved (grid, double lighting, flat albedo), and it reuses the stage 5 geometry that already exists. Run Route 3 in parallel or immediately after as the quality ceiling; if Route 1's silhouette fails against the new reference, Route 3 is the fallback. Run Route 2 as a bounded experiment, not a production route: one multi-view generation, one cleanup pass, and a hard stop if the waves or fused parts persist. This order gives the owner a material answer and a shape answer without betting the fleet on an unproven regeneration.

Owner questions (five, with chair picks)

1. Do we lock the Pyre-Barge five-view orthographic reference sheet before any route test?
Pick: yes. Without a single reference, the three routes are not comparable. The first reference costs 16 to 24 human hours; it is the cheapest way to avoid another C19_51 mismatch.

2. For Route 1, do we adopt Blender procedural smart materials plus shared trim/decal atlases as the fleet material default?
Pick: yes. It is the only route that is deterministic, batchable, and free of both grid and double lighting. Open-source painters stay as a hero pass; local AI texturing stays as an optional proposal tool with strict delighting.

3. For Route 2, do we stay on the 16 GB local card with low-VRAM/tiled decode, or allow one cloud 24 GB validation run?
Pick: stay local for the first candidate. If the local TRELLIS.2 result is close on silhouette and panel flatness, authorize one cloud 24 GB run to see whether the remaining gap is VRAM or model quality. Do not make cloud runs the default; the pipeline must be reproducible on the owner's card.

4. For Route 3, do we keep today's kit detail density or upgrade it?
Pick: keep today's density for the round 4 comparison; upgrade only hero parts afterward if Route 3 wins. R83's "upgraded LOD" question should be answered by the round 4 screenshots, not pre-emptively. Mixing a density upgrade into the comparison would confound the route result.

5. Which model leads the part-library and regeneration work: TRELLIS.2 or Hunyuan3D 2.1?
Pick: TRELLIS.2 as primary, Hunyuan3D 2.1 shape-only as comparison. TRELLIS.2's MIT licence and 16 GB low-VRAM path make it the only one that can be a production default. Hunyuan3D 2.1's flat-plane and part-seam quality is worth measuring, but its community licence and 29 GB full pipeline keep it in the comparison lane, not the default lane.

Label notes

Cost figures for new material libraries, part libraries, reference sheets, and cleanup are INFERRED from the round data and standard pipeline practice; they are planning estimates, not measured results.

The projection-grid mechanism is INFERRED from projection/UV mechanics and documented seam behaviour; the double-lighting mechanism is directly sourced. The grid may also be partly a visible lattice in the concept image, which cannot be confirmed without the original texture.

Model VRAM and licence claims are sourced from project pages and deployment guides; where the operational licence differs from the repository metadata (notably Pixal3D), the operational licence is treated as controlling.

The 16 GB fit assessments for TRELLIS.2 and Hunyuan3D 2.1 are based on low-VRAM/tiled workflows and shape-only modes; full texture pipelines on those models still exceed 16 GB in the general case.
