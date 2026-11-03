Ship pipeline research: fleet hull production at tactical camera

1. What the named games do

Battlefleet Gothic: Armada

Modelling (Q1). Tindalos built the ships in Unreal Engine 4 and rendered them "in obsessive detail", with players able to zoom down and inspect fine detail on hulls that are meant to be miles long (Game Developer, "Maxing out miniatures", 12 May 2016, staging.gamedeveloper.com). For the Tyranid faction, artist Ségolène Maurice records a sculpt-first route: ZBrush sculpt, retopology in TopoGun, UV mapping in 3ds Max, based on the physical Warhammer 40k miniatures and in-house concept art (40k.gallery, "Destroyer Vanguard"). That is not a kitbash-from-scratch route for organics; it is sculpt, retopo, UV, bake or texture. For the Imperial ships the public record is thinner. The same Game Developer piece describes the goal as capturing the feel of intricately painted miniatures, which suggests dense hard-surface detail rather than a small shared part library, but the exact sharing ratio is not publicly documented. INFERRED: the Imperial fleet likely reuses gothic trim and turret families across classes, because the tabletop range itself does.

Texturing (Q2). Public documentation is sparse. The Tyranid artist names a separate in-game shader made by another artist, which implies a material pass after the mesh (40k.gallery). No public trim-sheet or decal breakdown exists. INFERRED: Battlefleet Gothic uses unique unwraps for hero ships and shared material families for the gothic trim, because the art direction is cathedral-like repetition and the camera can get close.

Detail at distance (Q3). The game deliberately spends on detail that survives a close zoom, because the tactical camera allows it. The ships read through silhouette (cathedral spires, buttressed turrets) and through dense surface relief, not through flat texture noise. What they do not spend on is animation or interior detail; the ships are static models with turret and engine effects.

Fleet economics (Q4). The studio is an indie, Tindalos Interactive, based in Paris (Game Developer). No public per-ship cost exists. INFERRED: the team kept consistency by working from the physical miniature range and a small set of faction shape rules, not by building every hull from zero.

Homeworld 3

Modelling (Q1). Blackbird's art director Karl Gryc describes ship design as shape-language driven: "how shapes feel and how lines flow", with a focus on iconic silhouettes from multiple angles (Aftermath, "From The Sketchbook To The Stars: The Art Of Homeworld 3", 9 July 2024, aftermath.site). The Hiigaran Carrier was built through repeated sketch, model, texture and polish passes, and an earlier pirate carrier was dropped after it read as "too derivative" (GamingTrend, "Homeworld 3 unveils a new ship, the Hiigaran Carrier", 6 Oct 2022, gamingtrend.com). The public modding guide shows the shipped asset format: three UV channels per ship (UVMap0 for standard textures and mirroring, UVMap1 for badge projection, UVMap2 non-mirrored for team colour and SPLAT damage), plus separate Base Color, Emissive, Normal, ARM (AO/Roughness/Metallic/Height), MASK and TEAM maps (mod.io, "Modding: Advanced Ship Creation"). That multi-channel, mask-driven setup is evidence of a modular texture authoring pipeline, not a single baked concept projection.

Texturing (Q2). The mask channels (Dust/Dirt, Engine Mask, Panel Mask, Team Color) show that panel lines and wear are authored as masks and materials, not painted into one albedo. The ARM map packs AO, roughness, metallic and height, which is the standard PBR trim-and-tile approach. INFERRED: Homeworld 3 uses tileable PBR materials and mask-driven decals, with team colour as a separate channel.

Detail at distance (Q3). The carrier blog and Gryc interview both stress silhouette and multi-angle shape read. At the tactical camera the game spends on distinctive outlines, large value blocks and emissive engines. The mask-driven texture system keeps panel and dirt detail controllable at distance, but the public interviews do not claim per-rivet close-up detail.

Fleet economics (Q4). No sourced per-ship cost. The modding guide's three-UV and multi-map standard implies a shared material and import pipeline, which keeps per-hull art cost down. INFERRED: a small set of material masters and team-colour masks is reused across a faction, and unique work goes into silhouette and large forms.

Sins of a Solar Empire II

Modelling (Q1). The primary 3D artist, Paul Kiesling ("Set"), documents the ship pipeline in Dev Journal 21 (Stardock, 20 Nov 2024, stardock.net). The route is hard-surface from scratch in quads: clean quad topology, holding edges selected and bevelled, subdivision to a high poly, then alignment of low and high before baking. Tris are minimised, n-gons discouraged. There is no public statement of a shared kitbash library, but the emphasis on quad topology and weighted normals suggests each hull is built as a clean hard-surface mesh rather than assembled from a modular kit. INFERRED: faction identity comes from repeated shapes and materials rather than a shared part library.

Texturing (Q2). The same journal documents high-to-low baking of Normal, Curvature and AO in Marmoset, with UV padding and margin rules for mipmaps, 70 to 80 percent UV utilisation, and weighted normals to concentrate shading at edges. The bake is the bridge from high-poly detail to the low-poly game mesh. The journal does not name trim sheets or decals explicitly, but the curvature map is used for edge wear, which is the standard route to decal and wear masks. INFERRED: Sins II uses baked curvature as the edge-wear driver and tileable or trim-based materials for surface detail, not a projected concept painting.

Detail at distance (Q3). The journal's concern with mipmaps and padding is explicitly about how the ship looks when it shrinks with distance. At the tactical camera the game relies on silhouette, large bevels that catch light, and baked normal and curvature detail that survives mip reduction. It deliberately does not spend on detail that only reads at 4K close-up, because the capital ships un-render before hitting a mip level where padding bleed matters (Stardock journal).

Fleet economics (Q4). Stardock is a mid-size studio and the journal is written as a modder-facing tutorial. The pipeline is standardised and teachable, which is how it scales: one artist documents a repeatable bake and UV standard that others can follow. No per-ship hour count is published.

Battlestar Galactica Deadlock

Modelling (Q1). Forge Studios records that they handled "highpoly modeling, lowpoly and baking" for many Deadlock spaceships, with final texture done by Black Lab Games artists (Forge Studios ArtStation, forgestudios.artstation.com). That is an outsourced high-poly and bake route: a specialist studio makes the detailed source and the game-ready low, and the developer authors the final materials. INFERRED: the ships are built as unique hard-surface models per class, not from a large shared kit, because the Battlestar aesthetic depends on specific hull profiles (Jupiter, Manticore, Ranger) rather than generic modules.

Texturing (Q2). The split between Forge Studios' bake and Black Lab's final texture implies a high-to-low normal and AO bake followed by in-house material authoring. No public trim-sheet breakdown exists. INFERRED: Black Lab uses tileable armour plates and decal-like insignia, because the source show's hulls are panel-heavy and the game camera is tactical.

Detail at distance (Q3). Deadlock is a tactical, zoomable game. The high-poly bake carries armour plate and greeble detail into the normal map, while the silhouette carries the class identity. INFERRED: the game does not spend on close-up interior detail or per-rivet geometry, because the camera stays at fleet scale.

Fleet economics (Q4). Outsourcing high-poly and bake to Forge Studios is itself the economic answer: the developer buys capacity and keeps final material control in-house. No per-ship cost is public.

Starsector (2D contrast)

Modelling and texturing (Q1 and Q2). Starsector is 2D sprite art, not a 3D pipeline. Fractal Softworks documents the sprite method: block out a base area with a 100 percent brush, then add detail and texture with a 1 to 2 pixel brush at very low opacity, sampling colours from the sprite itself (Fractal Softworks, "Let Me Draw You A Starsector Ship, Part 2", 22 May 2014, fractalsoftworks.com). There is no mesh, no UV, no bake. The "modelling" is drawing, and the "texturing" is painting.

Detail at distance (Q3). The tactical read is carried entirely by silhouette, value contrast and colour blocking. At Starsector's zoom level a few pixels of contrast decide whether a ship reads as a frigate or a cruiser. The game deliberately does not spend on 3D surface detail because there is no 3D surface.

What transfers and what does not. Starsector's lesson transfers at the level of read discipline: decide what the camera must see and spend only on that. Its hand-authored silhouettes and value blocking are a useful benchmark for our hulls. Its actual pipeline does not transfer to a 3D fleet, and should not be cited as a route for us.

2. The cleanup pipeline from AI or photogrammetry mesh to game asset (Q5)

The standard small-team route, in the order a small team would actually run it:

Step 1: Audit and repair the source. Import the AI or scan mesh and inspect for interior faces, disconnected islands, non-manifold edges and inverted normals. Merge by distance and recalculate normals. The StraySpark guide to AI model cleanup treats this as the first pass before any remesh (strayspark.studio, "How to Reduce an AI 3D Model's Polycount in Blender"). Photogrammetry pipelines describe the same stage as mesh simplification and repair before retopology (arXiv, "From Reality to Virtual Worlds: The Role of Photogrammetry in Game Development").

Step 2: Voxel remesh to a clean manifold surface. In Blender, Object Data Properties, Remesh, Voxel. Voxel remesh rebuilds the surface from a 3D grid and removes high-frequency noise and self-intersections. The important setting is voxel size: smaller voxels keep more detail, larger voxels smooth more. The Blender manual describes the voxel remesher as rebuilding the geometry with more uniform topology (docs.blender.org, "Remesh"). StraySpark recommends voxel remesh as the standard cleanup for "broken or intersecting meshes" and for generator output that needs clean quads (strayspark.studio). A typical starting voxel size for a ship hull is 0.05 to 0.1 in Blender units, then adjust to preserve silhouette while killing bumps.

Step 3: Retopology to a game mesh. Two routes. Automatic: Blender's QuadriFlow remesh (Ctrl+Alt+R) produces even quads but does not give designed edge loops (Blender manual; StraySpark, "Why QuadriFlow Rejects AI Meshes"). Manual: draw the low-poly cage over the remeshed surface using the Poly Build tool or Shrinkwrap, so that edge loops follow the hull's form and the silhouette is protected. Hybrid: automatic QuadriFlow for the bulk, manual cleanup at the bow, stern and kit attachment points. The Sins II journal is explicit that the low must align with the high before baking, and that holding edges and bevels are what make the bake read (Stardock Dev Journal 21).

Step 4: UV unwrap for trim and tileable materials. Do not rely on a box projection. Unwrap the low with non-overlapping islands, leave margin for mipmaps (Sins II uses 4 pixels margin at 1k, 8 pixels padding, and 16 pixels at 4k), and aim for 70 to 80 percent UV utilisation (Stardock Dev Journal 21). For a hull that will carry trim, straighten the UV islands along the hull's main axes so that trim sections map cleanly. For tileable PBR, use a separate UV set or a world-space triplanar projection in the shader, as TEXTURE_PASS.md already proposes.

Step 5: High-to-low bake with a cage. Keep the repaired, detailed source as the high poly. Bake Normal, AO and Curvature from high to low in Blender Cycles or Marmoset. Use Selected to Active with a cage that fully encloses the high poly, to stop skewed rays on curved surfaces (strayspark.studio, "Bake a High-Poly Mesh Down to PBR Texture Maps in Blender"). Sins II bakes normals, curvature and AO in Marmoset at 4k, 64 samples, 16-bit, Mikk tangent space (Stardock Dev Journal 21). Curvature is the map that drives edge wear and dirt masks later.

Step 6: Author materials, not a projected painting. Build faction PBR materials in FAC3D. Use the baked AO and curvature as masks for grime, edge wear and cavity dirt. Use trim sheets for repeated panel and greeble detail, and decals for faction insignia. This is the step that replaces the projected concept paint. Homeworld 3's mask channels (Dust, Panel, Team) are a public example of this authoring logic (mod.io, "Modding: Advanced Ship Creation").

Where small teams cut corners at a tactical camera. They reduce retopo density on the underside and rear, because the tactical camera rarely sees them. They bake at 2k instead of 4k for escorts. They use trim sheets and decals instead of unique 4k unwraps for every hull. They skip high-frequency sculpt detail that would vanish at 170 units. They spend the saved budget on silhouette and on the hero ships that the owner inspects closely. All of these are INFERRED from the camera constraint, not from a published postmortem.

3. What causes each defect and what step removes the cause (Q6)

(a) Waviness. Low-frequency surface undulation from the generator. The generator fits a smooth surface through the multi-view images, and that surface is not faired. The cause is the AI mesh's own large-scale shape. The step that removes the cause is the clean shell loft: measure sections off the wavy AI hull and loft a fresh, faired shell, then demote the AI mesh to a measuring guide. This is exactly the C19_51 pattern already on file (pack section 3.2, step 5). If a clean loft is not used, voxel remesh at a coarser voxel size followed by a smooth pass and retopo reduces the waviness, but it does not remove the low-frequency error because the remesh follows the wavy surface. Route A removes the cause; route B reduces it.

(b) Bumps. High-frequency surface noise from the generator or from a noisy normal bake. Voxel remesh is the step that removes the cause: the voxel grid rebuilds the surface and discards sub-voxel noise, and a slightly larger voxel size smooths the bumps before retopo (Blender manual; StraySpark). A second cause is baking a noisy high-poly normal onto a low without a cage, which produces smeared or ghosted bump detail. The cage and a clean high-low alignment remove that cause (strayspark.studio baking guide; Stardock journal). Route B removes bumps at the remesh step; route A removes them because the shell is lofted clean and the kit parts are bevelled from scratch.

(c) Grid-like texture. The pack names two suspects: the box-projected runtime UVs at ships3d.js:753 ("about three panels per hull length") and the projected concept paint's own layout. A regular box projection produces a regular grid because the projection direction is axis-aligned. The step that removes the cause is a proper UV unwrap with trim-sheet mapping: the hull is unwrapped along its own form, trim sections are straightened, and panel lines come from the trim sheet or decal layer rather than from the projection grid. Route B removes the cause by replacing box projection with authored UVs. Route A removes it by building clean UVs from the start. The do-nothing baseline leaves it, because the runtime box projection stays.

(d) Odd paint. Projected concept art carries the concept's own lighting, noise and layout into the albedo. The paint reads as mottled camouflage because the projection is not a material, it is a photograph of a painting. The step that removes the cause is to stop projecting concept paint and author faction PBR materials in FAC3D, using baked AO and curvature only as wear and grime masks. This is route B's core bet. Route A also removes it, because the procedural paint in the C19 chain is authored from vertex colours and FAC3D, not projected. The do-nothing baseline leaves it, and the Nov 1 repaint proved that more paint passes on the same projected albedo do not fix it (pack section 5, G-14).

4. Organic hulls (Q7)

The Ninefold Maw (B16_23) is a Chorus bio-titan. Its problem is partly a category error: machine texture language (panel lines, hard flat panels, hexagonal turret-like pieces) sits on a creature that should read as flesh (pack section 2, ryan_c05). A machine cleanup route that fixes the metal fleets and leaves the Maw looking like lumpy rock is incomplete.

The cleanup differs in four ways.

First, the surface read is organic, not panel-based. There are no panel lines to hide behind, so the normal map and albedo must carry skin, pores, veins, wetness and subsurface colour variation. The reference workflow is a creature pipeline: sculpt the organic form in ZBrush, retopologise with edge loops that follow the muscle and skin folds, unwrap, and bake skin detail (Gnomon Workshop, "Creature Modeling for Production", Ben Erdt; CG Channel, "Gnomon releases Creature Modeling for Production"). Battlefleet Gothic's Tyranid artist used exactly this sculpt, TopoGun retopo and UV route for organic spaceships (40k.gallery).

Second, the hard machine parts must be removed or converted. The pack says Chorus ships are living bio-ships with veins and sacs that glow, and no bolt-on guns (CLAUDE.md rules, pack section 6). The hexagonal turret and flat panels on B16_23 should be cut out and replaced with organic growths or glowing sacs, not retained as machine kit.

Third, the material is not a metal PBR set. Use subsurface scattering or a cheap approximation, wet specular, and emissive veins. The albedo comes from FAC3D, but the colour range is flesh and bio-luminescence, not faction metal. TEXTURE_PASS.md's plan to blend real material sets by triplanar projection is a metal-hull plan and does not directly fit the Maw; the Maw needs a dedicated organic material library.

Fourth, the retopo density and bake budget are different. Organic surfaces deform visually through normal and displacement detail, not through hard bevels. A slightly denser low poly with smooth normals and a strong baked normal map reads better than a heavily decimated hard-surface cage. The tactical camera still limits how much pore-level detail is worth baking, but the Maw is a hero unit and the owner has inspected it at extreme close zoom (pack section 2), so it needs more close-up budget than an escort.

Route B as written in issue 75 is a machine pipeline and does not fit the Maw. The strongest route for organics is a dedicated creature sub-route: sculpt or repair the organic form, retopo for smooth deformation, bake skin and vein detail, author an organic FAC3D material with emissive veins, and delete machine parts. This is route C's organic leg.

5. Routes for our fleet, priced

Scope and units

The verified fleet is 36 hull meshes: 30 faction capital hulls, 3 squadron craft (S1_51 fighter, S2_23 bomber, B23_51 spore) and 3 objective structures (O1_37 station, O2_37 transport, O3_11 beacon) (pack section 3.1). The issue text's "28 hulls" is a known error. Every effort figure below prices the real fleet and states its unit. "Agent hours" means scripted Blender work run on the owner's PC. "Owner hours" means manual Blender review and decisions. "Measured" means a number exists on file; "INFERRED" means I am estimating from the pipeline steps and the single completed C19 case. No measured per-hull number exists for any route, because issue 75 is blocked and the bake-off has produced nothing.

Route A: C19-pattern kitbash rebuild with clean shell loft and trim sheet

What it is. For each hull: measure sections off the AI mesh, loft a clean faired shell, cut out mangled AI regions, build kit parts with tools/blender/hs/<code>_kit.py, bake procedural paint from vertex colours and FAC3D, pack with pixal_to_game.py and vsm_pack.mjs. This is the only route with a completed example on file: C19_51 (pack section 3.2).

Per-hull effort. INFERRED from the C19_51 single case: 40 to 80 combined agent and owner hours per capital hull. The shell loft and kit scripts are agent work; the shape approval and kit placement review are owner work. The C19 chain was not repeated, so this is an estimate, not a measurement.

Total across the priced scope. 30 capital hulls at 40 to 80 hours each is 1,200 to 2,400 hours. The 3 squadron craft and 3 structures are simpler but still need shells and kit; add 6 at 10 to 20 hours each, so 60 to 120 hours. Total route A for the whole fleet: roughly 1,260 to 2,520 hours. In plain words: this is a multi-month route for one person with agent help.

Which hulls it does not fit. The Ninefold Maw and the other Chorus organics do not fit route A as written, because the kit is a machine kit and the Maw needs flesh. The three objective structures may fit, but a station or beacon may be cheaper under route B because it has less unique silhouette pressure.

Four defects. Waviness: removes the cause, because the shell is lofted clean. Bumps: removes the cause, because the shell and kit parts are clean. Grid texture: removes the cause, because UVs are authored for trim and the procedural paint does not use box projection. Odd paint: removes the cause, because paint is procedural from FAC3D, not projected.

Risks. FAC3D stays the colour source, so no violation if the kit scripts and procedural paint read FAC3D. R73 break-up work: route A changes hull geometry, so the clip-and-plug break-up prototypes must be re-checked against the new shells. Damage surface work: new geometry means new damage points; coordinate with issue 51. Godot conversion: route A outputs to hulls/ and hulls_hi/, and build_assets.gd reads those directories (build_assets.gd:106), so the conversion still works if the output paths are kept. Blob sweep gate: every new shell must pass the 9-cell review (CLAUDE.md:21-28); this route can pass it because the shell is fair.

Route B: voxel remesh, retopo, baked detail, faction PBR

What it is. For each hull: voxel remesh the AI mesh to a clean manifold surface, retopo to a game low, unwrap for trim and tileable materials, bake Normal/AO/Curvature from the remeshed high to the low, and replace projected concept paint with FAC3D PBR materials driven by curvature and AO masks. This is the machine route described in issue 75 and in the StraySpark and Sins II sources.

Per-hull effort. INFERRED from the step costs: voxel remesh and QuadriFlow are minutes per mesh, but manual retopo, UV and material authoring are hours. I price 8 to 16 combined agent and owner hours per capital hull. The agent does the remesh and bake scripts; the owner reviews retopo quality, UV layout and material look.

Total across the priced scope. 30 capital hulls at 8 to 16 hours each is 240 to 480 hours. The 3 craft and 3 structures at 4 to 8 hours each add 24 to 48 hours. Total route B for the whole fleet: roughly 264 to 528 hours. This is the cheapest route that addresses all four defects.

Which hulls it does not fit. The Ninefold Maw and other Chorus organics, because the machine PBR route does not produce flesh. It fits the metal fleets and probably the structures. It may not fit the most iconic flagships if the owner wants the C19 level of bespoke kit; that is a judgement call for route C.

Four defects. Waviness: reduces it, because voxel remesh follows the wavy surface at a coarse voxel size and a smooth pass can take out some undulation, but the low-frequency error remains. Bumps: removes the cause at the remesh step, because voxel remesh discards sub-voxel noise. Grid texture: removes the cause, because the runtime box projection is replaced by authored UVs with trim and tileable mapping. Odd paint: removes the cause, because projected concept paint is replaced by FAC3D PBR with curvature and AO masks.

Risks. FAC3D is the single colour source; route B must author all base colours in FAC3D and use the PBR textures only for roughness, metal, normal and masks, not for a second colour authority. The pack's constraint is explicit: baked finish maps are wear and grime masks, not a second colour authority (pack section 6, citing the deepseek review). R73 break-up: route B changes the mesh, so the clip-and-plug break-up must be re-checked. Damage work: new low meshes need new damage points; coordinate. Godot conversion: route B outputs to the same hulls/ and hulls_hi/ directories, so build_assets.gd still reads them. Blob sweep: the remeshed and retopoed hull must pass the 9-cell review; voxel remesh can leave a soft bow, so the bow must be checked and faired.

Route C: hybrid (the strongest further route)

What it is. Split the fleet by hull type and camera importance. Flagships and the most iconic capital hulls (C19_51, the Eclipse cruisers, perhaps 6 to 8 hulls) get route A: clean shell loft and kitbash, because the owner inspects them closely and they carry faction identity. The remaining metal capital hulls and the structures get route B: remesh, retopo, bake, PBR, because it is fast and fixes all four defects. The Chorus organics get a dedicated creature sub-route: sculpt or repair the organic form, retopo for smooth deformation, bake skin and vein detail, author an organic FAC3D material, delete machine parts, add emissive veins. The 3 squadron craft can follow route B with simplified budgets.

Per-hull effort. Route A hulls at 40 to 80 hours each. Route B hulls at 8 to 16 hours each. Organic hulls at 20 to 40 hours each (INFERRED from the creature pipeline; there are 5 Chorus capital hulls, and the Maw is the hardest). Structures at 4 to 8 hours each.

Total across the priced scope. If 8 hulls go route A (8 x 40 to 80 = 320 to 640 hours), 22 metal capitals go route B (22 x 8 to 16 = 176 to 352 hours), 5 organics go creature route (5 x 20 to 40 = 100 to 200 hours), and 6 craft and structures go route B (6 x 4 to 8 = 24 to 48 hours), the total is roughly 620 to 1,240 hours. That is half or less of pure route A, and it handles the Maw properly.

Which hulls it does not fit. No hull is excluded in principle. The split is a budget and priority decision, not a technical limit. If the owner wants every capital hull at C19 quality, route C collapses into route A and the cost rises.

Four defects. For route A hulls: all four causes removed. For route B hulls: bumps, grid and odd paint removed, waviness reduced. For organics: bumps reduced by remesh or sculpt smoothing, grid and odd paint removed by the organic material route, waviness handled by the sculpt or shell, and the machine-parts category error removed by deleting the hard kit. Route C therefore covers all four defects across the whole fleet, with waviness as the only defect that is reduced rather than removed on route B hulls.

Risks. Same as routes A and B individually, plus one new risk: two pipelines mean two sets of scripts and two QA gates. The Godot conversion still reads the same output directories, so the build is unaffected if both routes write to hulls/ and hulls_hi/. FAC3D remains the colour source for both. The blob sweep gate applies to every hull regardless of route. R73 break-up must be checked for both the new shells and the remeshed hulls.

Do-nothing baseline: keep polishing the current chain

What it is. Continue the current projected concept paint and runtime box-projected UVs, with more repaint passes and more normal-map tweaks.

Cost. The Nov 1 repaint of 36 hulls (commit fc9b347, pack section 5, G-14) already proved that more paint passes on the same meshes do not fix the complaint. The baseline therefore has a known cost with no expected benefit. It also leaves the box-projection grid and the projected paint's lighting in place.

Four defects. Waviness: leaves it. Bumps: leaves it or covers it with more noise. Grid texture: leaves it, because the runtime box projection is unchanged. Odd paint: leaves it, because the albedo is still projected concept art.

Risks. No new technical risk, but the owner's complaint recurs and the fleet stays below the quality bar set by R16 ("more realistic and cinematic" next to BattleTech, Sins of a Solar Empire and Rogue Trader).

6. Risk to ruled and built things

FAC3D as the single colour source. Routes A and B must author base colour in FAC3D. Route B's PBR material authoring is the highest risk of accidentally creating a second colour authority; the mitigation is to treat all baked maps as masks and roughness/metal/normal only, and to keep base colour driven by FAC3D. Route A's procedural paint already follows this law.

R73 break-up work. Any route that changes hull geometry (A, B and C) must re-check the clip-and-plug break-up prototypes against the new meshes. The break-up work is a separate thread, but a route that ignores it will break it. The mitigation is to run the break-up check as a gate after each hull's new mesh lands.

Damage surface work (R76). Damage reads are a separate ruled thread. New hull geometry means new damage points and new surface response. The mitigation is to coordinate with issue 51 and to keep the damage surface work on its own track, not re-scope it into this research.

Godot conversion. godot/render/build_assets.gd reads hulls_hi/ and hulls/ and writes res://gen/hulls/<code>.res (build_assets.gd:106, 228). Any route that keeps those output directories works with the existing conversion. If a route changes the file format or directory, the Godot build needs a matching change. Route A's C19 path already outputs to assets/ships/C19_51/ and also to the packed directories, so the pattern exists.

Blob sweep gate. Every ship must pass the 9-cell review (bow, midship, stern from top, side and below) before being shown (CLAUDE.md:21-28). Route A's clean shell is the easiest to pass. Route B's voxel remesh can leave a wavy bow, so the bow must be checked and faired before the gate. The organic route must pass the same gate on its own terms: the Maw's bow and flanks must read as flesh, not as lumpy rock.

7. Recommendation

I recommend route C, the hybrid, with the following split:

Flagships and iconic capitals (about 8 hulls): route A. These are the hulls the owner zooms in on and the hulls that carry faction identity. The clean shell loft and kitbash remove all four defects at the cause, and the C19_51 example proves the route works on one hull. The cost is high per hull, which is why it is limited to the ships that earn it.

Remaining metal capitals and structures (about 22 capitals plus 3 structures): route B. Voxel remesh, retopo, bake, and FAC3D PBR remove bumps, grid texture and odd paint, and reduce waviness. This is the only route that scales to the bulk of the fleet at a cost the project can absorb.

Chorus organics (5 capitals including the Maw): dedicated creature sub-route. Sculpt or repair the organic form, retopo for smooth deformation, bake skin and vein detail, author an organic FAC3D material with emissive veins, and delete the machine parts. This is the only route that fixes the Maw's category error.

Squadron craft (3): route B with reduced budgets, because they are small at the tactical camera and do not need bespoke kit.

The reasoning is that no single route fits the whole fleet. Pure route A is the quality ceiling but costs 1,260 to 2,520 hours, which is not realistic for one person's project with agent help. Pure route B is affordable but leaves the Maw as a machine-textured creature and reduces rather than removes waviness. Route C spends the bespoke effort where the camera and the owner actually look, and uses the scalable route everywhere else. It also keeps FAC3D as the colour source, outputs to the existing Godot directories, and can be checked against the blob sweep gate hull by hull.

When the issue 75 bake-off pictures land, the owner can judge route C on three questions. Does route A on the Pyre-Barge look better than route B on the same hull? Does route B on the Eclipse and the Maw look acceptable next to route A? Does the organic sub-route make the Maw read as flesh rather than as rock? If route B's pictures are close enough to route A's, the split can move more hulls to route B and cut the cost. If route B is clearly worse, the split moves toward route A and the cost rises. The recommendation is designed to be adjustable against those pictures.

8. Owner questions

Question 1: Should the fleet be split by hull importance, or should every capital hull get the same treatment?

Pick: split by hull importance (route C). Cost in plain words: about 620 to 1,240 hours across the fleet, with the bespoke hours going to roughly 8 flagships and the rest on the faster remesh route.

Option B: every capital hull route A. Cost: 1,260 to 2,520 hours. Higher quality ceiling, much longer wait.

Option C: every capital hull route B. Cost: 264 to 528 hours. Fastest, but the Maw and the flagships stay below the C19 bar.

Question 2: How should the Chorus organics be handled?

Pick: a dedicated creature sub-route with organic materials and no machine kit. Cost: about 20 to 40 hours per organic hull, 100 to 200 hours for the 5 Chorus capitals. The Maw gets the most time.

Option B: route B with a green-brown paint variation. Cost: 8 to 16 hours per hull. Cheaper, but the Maw still reads as a machine-textured creature and the category error remains.

Option C: leave the organics until the metal fleet is done. Cost: zero now, but the Maw stays in the complaint list and the owner's close-zoom screenshots stay unresolved.

Question 3: Should the runtime box-projected UVs be replaced on every hull, or only on the hulls that get a new mesh?

Pick: replace them on every hull that goes through route A or B, which is the whole fleet under route C. Cost: included in the per-hull estimates. The grid texture disappears because the projection disappears.

Option B: keep box projection and try to mask the grid with more texture noise. Cost: near zero, but the pack already records that more paint passes do not fix the complaint, and a projection grid is a structural pattern that noise does not remove.

Question 4: Should the flagships get route A even if the bake-off shows route B is close?

Pick: wait for the bake-off pictures, then decide. Cost: the bake-off is already running under issue 75; no new cost. If route B is close, moving flagships to B saves roughly 32 to 64 hours per flagship. If route B is clearly worse, keep route A for the flagships.

Question 5: What is the first hull to run through the chosen route after the bake-off?

Pick: C19_51 first, because it already has the full chain and the owner's shape and paint approvals (R13, R14), then the Eclipse zenith cruiser, then the Maw. Cost: the first hull is the calibration hull; its hours set the real per-hull number for the rest. The Eclipse tests route B on a metal capital. The Maw tests the organic sub-route and settles whether the creature pipeline works before it is applied to the other four Chorus hulls.

9. Not checked

No measured per-hull effort number exists for route A beyond the single C19_51 case. The 40 to 80 hour figure is INFERRED, not measured. Issue 75 is blocked and has produced no bake-off pictures or frame costs, so no route can be priced against a measured comparison.

The public record for Battlefleet Gothic: Armada's Imperial ship modelling and texturing is thin. The Tyranid route is documented by the artist, but the Imperial trim-sheet and kitbash ratio is INFERRED from the miniature range and the art direction, not sourced.

Homeworld 3's exact modelling route (scratch versus kitbash versus modular sections) is not stated in the public interviews I found. The three-UV and mask-driven texture setup is sourced from the modding guide; the mesh authoring route is INFERRED from the shape-language interviews.

Battlestar Galactica Deadlock's final material authoring is not publicly documented beyond the Forge Studios credit. The trim-sheet and decal claim is INFERRED.

I did not find a public per-ship cost or team-size figure for any of the five games. The fleet economics answers are qualitative and, where marked, INFERRED.

I did not verify the exact Godot build_assets.gd line behaviour beyond the pack's citations. The pack's file:line facts are treated as verified; I did not re-open the file.

I did not test any of the Blender settings (voxel size, cage extrusion, bake samples) on our hulls. The settings are sourced from the Blender manual, StraySpark and the Sins II journal, but they are starting points, not validated for our meshes.

The organic sub-route is the least sourced part of the report. The creature pipeline is documented for characters and for Battlefleet Gothic's Tyranids, but I did not find a public postmortem of a game that turned an AI-generated organic spaceship into a clean creature hull. The application to the Maw is INFERRED from those adjacent workflows.
