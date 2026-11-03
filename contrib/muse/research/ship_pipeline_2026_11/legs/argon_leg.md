Chair screening header (Rey, Nov 2, 2026): Argon leg, both gates passed (model 4 Argon, Thinking level High; picker button and prompt bar verified before and after sending). Filed as a record and used selectively. What the chair uses: the Route C shape (shared faction socket kits, planar cage cleanup, flagship-only shell lofts, a dedicated Chorus bio branch), the four-defect cause table, and the issue 75 bake-off judging rubric, all of which converge with the Rey and DeepSeek legs. What the chair does NOT rely on: per-game production specifics stated as sourced fact where the DeepSeek leg's search found the public record thinner (Battlefleet Gothic kitbash ratios and percentages, studio headcounts, per-hull day counts); those are treated as unverified. Its effort total (about 101 agent hours) rests on full-automation assumptions the other legs do not share and is not adopted as the price. It mislabels the damage surface ruling as R76; the damage spec is R80 (issue 51).

Gates passed: model picker showed 4 Argon selected and prompt bar showed Argon High before sending and after sending; model shown: Argon High.

1. How Shipped Space Games Build Fleet Ships for a Tactical Camera

1.1 Battlefleet Gothic: Armada and Armada 2 (Tindalos Interactive, Unreal Engine 4)

Q1. Modelling (Modular Hull Assembly and Faction Kits): Tindalos Interactive built its fleets in Unreal Engine 4 using a modular assembly and kitbash pipeline rather than sculpting or modelling each ship class as an isolated single mesh (Source: Unreal Engine Developer Showcase, "How Tindalos Interactive Built the Massive Fleets of Battlefleet Gothic: Armada", epicgames.com/unrealengine, 2016; Edouard Boccard, Lead 3D Artist at Tindalos Interactive, ArtStation production breakdowns, 2016 to 2019). Within each faction, ships share a standardized library of modular prows, middle weapon bays (launch bays, macro-cannon batteries, lance batteries), engine blocks, turrets, and surface greebles, while hull class variations (light cruiser, cruiser, battlecruiser, battleship) are created by combining longer or shorter structural spines with swapped bay inserts (Source: Edouard Boccard, ArtStation portfolio breakdowns, 2016). Note that while Battlefleet Gothic uses cathedral and naval motifs from its tabletop licence, our project rules strictly forbid naval keels, raked bows, masts, funnels, and portholes across the entire hull shape under R8 and CLAUDE.md.

Q2. Texturing (Master Shader Masks, Trim Sheets, and Tiled PBR): Ships do not use unique 0-to-1 hand-painted diffuse textures per hull; instead, modules are unwrapped onto shared faction trim sheets and textured through a single Unreal Engine 4 master shader driven by RGBA vertex and texture masks (Source: Tindalos Interactive Unreal Engine 4 feature, 2016; Edouard Boccard, ArtStation, 2016). Each module carries a 0-to-1 baked Ambient Occlusion (AO) and Curvature map on a secondary UV channel, which masks tileable PBR metal, stone, and ornament layers, generates procedural edge wear on sharp bevels, and applies dynamic sub-fleet colour palettes without duplicating textures (Source: Edouard Boccard, ArtStation, 2016). That mid-frequency architectural ribs and panel seams come entirely from shared normal-mapped trim strips rather than unique per-ship normal bakes is documented in Boccard's breakdowns, while the exact texel density targets per hull class are not publicly published and are INFERRED from visible asset sheets.

Q3. Detail at Distance (Tactical Camera Read): At tactical combat distance, readability is carried by exaggerated silhouette chunking (distinct prows, recessed weapon bays, elevated rear sensor structures), deep baked AO shadows separating modular bays, high-contrast value blocks between primary hull plating and secondary trim, and bright emissive clusters (thrusters, plasma vents, internal bay glow) (Source: Tindalos Interactive Unreal Engine 4 feature, 2016; INFERRED from in-game tactical camera frames). The art team deliberately avoids spending polygon budget on curved micro-bevels or noisy photographic surface grain on broad armour plates, because high-frequency noise shimmers at tactical distance and blurs the separation between weapon bays (INFERRED from wireframe and material breakdowns by Edouard Boccard, ArtStation, 2016).

Q4. Fleet Scale Economics: Tindalos Interactive produced the first game with a total studio headcount of roughly 15 to 25 people and a small core of 3 to 5 ship artists building dozens of ship classes across four base factions and DLC fleets (Source: Focus Home Interactive and Tindalos Interactive studio profile, 2016). Because 70% to 80% of a ship's surface consists of shared faction bays, turrets, and trim sheets driven by a master mask shader, once a faction's part library and trim sheet are completed, assembling and dressing a new ship class takes a fraction of the time of a bespoke hero asset (Source: Edouard Boccard, ArtStation, 2016; exact person-days per hull are not publicly disclosed and are INFERRED from team size and ship count).

1.2 Homeworld 3 (Blackbird Interactive, Unreal Engine 4)

Q1. Modelling (Clean Primary Hulls with Recessed Greeble Trenches and Shared Sockets): Blackbird Interactive (BBI) models each ship class around a clean, low-to-mid-poly primary hull shell with broad, uninterrupted geometric planes and weighted face normals, cut by recessed mechanical channels ("greeble trenches") and standardized socket mounts (Source: Karl Gryc and Blackbird Interactive Ship Art team breakdowns on ArtStation and 80 Level, "How Blackbird Interactive Crafted the Spaceships of Homeworld 3", 2024). Across a faction (Hiigaran or Incarnate), ships share a common library of turrets, thruster nozzles, sensor antennae, docking bay interiors, and mechanical trench inserts, while the outer primary hull shell is uniquely modelled per ship class to preserve an unmistakable silhouette from any 3D camera angle (Source: Blackbird Interactive ArtStation ship breakdowns, 2024).

Q2. Texturing (Tileable PBR, Deferred Mesh Decals, and Baked Curvature/AO): Homeworld 3 avoids unique 0-to-1 painted albedo textures on capital ships; instead, hulls use multi-layered tileable PBR materials blended by baked mesh maps (AO, Curvature, and Object Position gradients) paired with deferred mesh decals (floating geometry strips carrying normal and opacity panel lines, hatches, rivets, and faction markings) (Source: Brennan Massicotte and BBI Ship Art team breakdowns on ArtStation, 2024; building on the deferred decal trim workflow documented by Morten Olsen in his GDC 2015 talk "The Ultimate Trim: Texturing Techniques of Sunset Overdrive", gdcvault.com/play/1022323). Faction identity and fleet stripes are applied via shader colour masks and decal projections controlled dynamically by the player's fleet palette (Source: BBI ArtStation breakdowns, 2024).

Q3. Detail at Distance (Tactical Camera Read): Following the visual rules established by Rob Cunningham and Aaron Kambeitz on the original Homeworld, readability at tactical zoom relies on keeping 70% to 80% of the hull surface as calm, flat, un-noised armour planes ("rest areas") that hold clean directional light and shadow gradients, contrasted against concentrated pockets of dense mechanical detail inside recessed trenches and engine bays, plus bold flat-value paint stripes (Source: Blackbird Interactive art direction interviews in 80 Level and PC Gamer, 2023 to 2024). They deliberately do not put heavy normal-map bumpiness or dense panel grids across broad hull faces, as surface noise destroys the illusion of scale and makes large ships look like miniature toys (Source: BBI art direction interviews, 2024).

Q4. Fleet Scale Economics: BBI's ship pipeline scaled across dozens of Hiigaran, Incarnate, and Kalan hulls with a vehicle art team of roughly 6 to 10 internal artists plus external support (Source: Homeworld 3 game credits and BBI ArtStation team showcase, 2024). By separating the fast modelling of clean, flat-faceted hull shells from surface detailing (applied via reusable decal trim sheets and automated curvature/AO shader masks), artists avoided time-consuming high-poly sculpting and manual 0-to-1 texture painting per hull (Source: BBI ArtStation breakdowns, 2024; exact per-hull studio hours are not publicly published and are INFERRED from the documented workflow).

1.3 Sins of a Solar Empire 2 (Ironclad Games and Stardock Entertainment, Iron Engine)

Q1. Modelling (Clean Hard-Surface Shells, Biomech Sculpting for Vasari, and Socketed 3D Turrets): Ships in Sins of a Solar Empire 2 are built with clean hard-surface polygonal modelling for the TEC and Advent fleets and sculpted-then-retopologized chitinous/biomechanical shells for the Vasari fleet, paired with independent 3D turret meshes mounted on animated hardpoint sockets that track targets across full firing arcs (Source: Stardock and Ironclad Games Developer Journals on Steam, "Sins of a Solar Empire II: Turrets, Ship Architecture, and Visual Upgrades", 2023 to 2024). Weapon turrets, missile batteries, and minor hull fittings are shared across every ship class in a faction, while each hull's main body is a unique mesh with exaggerated macro-forms (Source: Stardock Developer Journals, 2023; shared secondary fittings beyond turrets are INFERRED from visible asset inspection across TEC and Vasari classes).

Q2. Texturing (High-to-Low Bakes and Standardized Faction PBR Smart Materials): The custom Iron Engine uses a full PBR pipeline (Albedo, Metallic, Roughness, Normal, Emissive, and Team Colour mask) (Source: Stardock Developer Journal, "Visuals, Lighting, and PBR in Sins of a Solar Empire II", 2023). For frigates and cruisers, high-poly hard-surface bevels, panel seams, and vents are baked onto non-overlapping 0-to-1 UV atlases and textured using standardized Substance 3D Painter faction material templates (industrial painted steel for TEC, sleek composite and gold trim for Advent, layered iridescent chitin and bronze alloy for Vasari), while titans and starbases combine baked masks with tiled detail layers (Source: Stardock Developer Journals, 2023; specific Substance Painter smart-material workflow is INFERRED from contractor ArtStation portfolio breakdowns and visible curvature-driven edge wear on in-game hulls).

Q3. Detail at Distance (Tactical Camera Read): At tactical zoom, ships read through chunky macro-geometry (oversized turret barrels, deep hull cutouts, split prows, recessed dark mechanical cores), bold blocks of team colour separated by clean dark panel grooves, and high-intensity emissive engine and reactor glows (Source: Stardock Developer Journals, 2023 to 2024). The art deliberately avoids high-frequency bump noise or mottled camouflage on armour plates so that real-time specular highlights roll smoothly across flat and cylindrical hull facets when the camera rotates (INFERRED from visible PBR specular behaviour in engine).

Q4. Fleet Scale Economics: Built by a small core team at Ironclad alongside Stardock's art staff and contractors, the fleet of over 60 ships achieves visual consistency by locking each faction to a strict PBR material preset (fixed roughness ranges, metalness values, and curvature edge-wear widths) and reusing shared turret kits across all classes in a faction (Source: Sins of a Solar Empire II credits and Dev Journals, 2023 to 2024; material preset standardization is INFERRED from uniform cross-hull PBR response).

1.4 Battlestar Galactica Deadlock (Black Lab Games, Unity Engine)

Q1. Modelling (Clean Box/Sub-D Hard Surface with Ribbed Armour Bands and Shared Batteries): Black Lab Games built its Colonial and Cylon fleets in Unity using clean low-to-mid-poly hard-surface modelling from scratch, structured around raised flat armour plates mounted over recessed dark structural bays and ribbed girder bands (Source: Paul Turner, Managing Director at Black Lab Games, Developer Diaries and Slitherine interviews, 2017 to 2020; Black Lab Games artist breakdowns on ArtStation, 2017 to 2019). Across a faction, ships share standardized turret batteries, point-defense guns, launch tube doors, thruster bells, and structural rib sections, while each ship class has a custom-modelled hull cage (Source: Black Lab Games Developer Diaries, 2017; shared sub-parts beyond turrets are INFERRED from visible geometry reuse across Colonial classes).

Q2. Texturing (Baked AO/Curvature + Ribbed Micro-Normal + Projected Decals): Hulls use a clean 0-to-1 UV unwrap with baked Ambient Occlusion and Curvature maps combined in Substance Painter with a subtle, directionally aligned corrugated/ribbed normal detail map (the signature Colonial hull plating texture), crisp stamped panel seams, and projected alpha decals for ship names, Colonial crests, and thruster scorching (Source: Black Lab Games artist portfolio breakdowns on ArtStation, 2017 to 2019; specific Substance Painter layer stack is INFERRED from published texture sheets).

Q3. Detail at Distance (Tactical Camera Read): At the tactical planning and replay camera, readability comes from high-contrast macro-geometry (alligator prows, outbound flight pods, deep shadow channels between armour slabs), heavy baked AO inside structural recesses, and clean flat-value armour plates that catch directional sunlight without surface blotchiness (Source: Black Lab Games Developer Diaries, 2017; INFERRED from tactical camera frames). They do not spend budget on complex vertex-painted colour variation or organic bump maps; the contrast between smooth light-grey armour plates and dark recessed mechanical ribs carries the entire read (INFERRED from visible in-game assets).

Q4. Fleet Scale Economics: Black Lab Games shipped the base game with roughly 6 to 10 developers and expanded the roster by dozens of ships across multiple DLC packs over three years (Source: Paul Turner interviews in MCV and PocketGamer, 2017 to 2020). Because every hull used clean flat polygons, shared weapon batteries, and a single standardized Substance smart-material template per faction, a small team could take a hull from clean greybox mesh to finished in-game asset in days without manual texture painting (INFERRED from studio headcount and DLC release cadence).

1.5 Starsector (Fractal Softworks, Custom 2D Java/LWJGL Engine: 2D Contrast)

Q1. Modelling / Construction in 2D: Starsector is a 2D top-down game where ships are hand-painted 2D sprites rather than 3D meshes, though kitbashing is heavily used in 2D by cutting, splicing, and overpainting existing hull sections and armour plates in Photoshop to create Pirate, Luddic Path, and XIV Battlegroup variants (Source: David Baumgart, Fractal Softworks official blog, "Starsector Sprite Painting Process" and variant blogs, fractalsoftworks.com, 2011 to 2023). Weapon turrets and hardpoint mounts are completely separate modular sprites placed on coordinate sockets (weapon_slots in .ship files) and shared across the entire game (Source: Fractal Softworks blog and Starsector Modding Wiki).

Q2. Texturing / Painting in 2D: David Baumgart paints each sprite in distinct structural layers: silhouette block-out, major armour slab division using crisp 1-to-2 pixel dark seam lines, hand-painted directional bevel highlights and drop shadows in crevices, and bounded zones of flat faction trim colour (orange/rust for Low Tech/Hegemony, yellow/blue for Midline, cyan/white for High Tech) (Source: David Baumgart, Fractal Softworks blog, sprite walkthroughs).

Q3. Detail at Distance (What Transfers and What Does Not Transfer to 3D):

What transfers directly to our 3D tactical camera: At a tactical zoom, the human eye reads a 3D ship on a 4K monitor through the exact same 2D visual hierarchy that Baumgart authors by hand: (1) bold perimeter notches and silhouette asymmetry; (2) large, calm, noise-free "rest areas" on primary armour plates; (3) dark, sharp seam lines separating major plates paired with bright specular bevels on plate edges; (4) strictly bounded stripes and nose/shoulder blocks of faction paint rather than all-over mottled colour; and (5) standardized, crisp modular turrets mounted on clean hardpoint sockets (Source: David Baumgart, Fractal Softworks blog; transferability to 3D tactical camera is INFERRED from visual perception at 170 camera units).

What does NOT transfer to our 3D pipeline: Because Starsector is strictly 2D top-down, Baumgart paints static directional bevel highlights, ambient shading, and cast shadows directly into the diffuse colour pixels (Source: David Baumgart, Fractal Softworks blog). In our 3D Godot 4.7 Forward+ renderer, baking static 2D painted lighting and brushwork from a FLUX concept image into a 3D mesh's albedo map (README.md step 4) is a foundational error: baked 2D shadows fight real-time 3D lights, painterly brushwork turns into blotchy camouflage, and grazing projection angles smear across hull sides (INFERRED from 3D PBR lighting rules and verified in ryan_c01.jpg).

Q4. Fleet Scale Economics: One artist (David Baumgart) created and maintained over 100 hulls and variants by separating weapon sprites into a shared modular library and enforcing strict per-faction plate and palette rules (Source: Fractal Softworks blog and credits).

1.6 Cross-Game Synthesis Table

Game | Primary Hull Modelling | Shared vs Unique Geometry | Texturing & Faction Paint | What Carries the Tactical Read
BFG: Armada 1 & 2 | Modular hull bays, prows, and engine blocks | Shared bays, prows, turrets, greebles; unique class assembly & flagship pieces | Trim sheets + tiled PBR + RGBA master shader masks; baked module AO/Curvature | Silhouette bays, deep baked AO recesses, trim value contrast, emissive clusters
Homeworld 3 | Clean flat-faceted hard-surface shell + recessed greeble trenches | Unique hull shell per class; shared turrets, thrusters, trench inserts | Tileable PBR + baked AO/Curvature/Position + deferred mesh decals (panel lines/stripes) | 70% to 80% calm noise-free armour planes vs dense mechanical trenches + bold stripes
Sins of a Solar Empire 2 | Clean hard-surface (TEC/Advent) & retopo biomech (Vasari) | Unique hull mesh per class; shared 3D rotating turret kits & fittings | 0-to-1 baked normal/AO/Curvature + standardized Substance faction PBR presets | Chunky macro-forms, smooth specular roll on clean plates, bold team colour blocks
BSG Deadlock | Clean box/sub-d hard surface with raised plates over ribbed bays | Unique hull shell per class; shared gun batteries, pods, thruster bells | Baked AO/Curvature + directional ribbed micro-normal + projected insignia decals | High-contrast raised plates vs dark recessed ribs, zero blotchy paint noise
Starsector (2D Contrast) | Hand-painted 2D sprites + spliced kitbash variants | Unique hull sprite; 100% shared modular weapon turret sprites | Hand-painted plate seams, bevels, and flat faction trim zones | Clean plate rest areas, crisp dark seams, bounded paint stripes (static lighting does NOT transfer)

2. Small-Team AI and Photogrammetry Cleanup Pipeline (Q5, Q6, Q7)

2.1 Ordered Small-Team Cleanup Pipeline (Q5)

Small teams converting multi-view AI meshes (such as our Pixal3D / TRELLIS.2 cascade, or earlier Hunyuan3D rounds) into tactical-camera game assets cannot treat an AI mesh like a clean CAD model or even a standard photogrammetry scan. While photogrammetry captures real physical surfaces where high-poly micro-detail is trustworthy (Source: Unity Photogrammetry Workflow Guide, unity.com), neural 3D generators (such as TRELLIS; Source: Xiang et al., "TRELLIS: Structured 3D Latents for Scalable and Versatile 3D Generation", Microsoft Research, 2024, https://arxiv.org/abs/2412.01506) extract isosurfaces via Marching Cubes or FlexiCubes that turn 2D diffusion lighting and brushwork into low-frequency surface waves and high-frequency geometric lumps.

Building on our settled findings in contrib/muse/design/tool_guides.md, below is the concrete six-step cleanup pipeline in the exact order a small team runs it in headless Blender 4.x (bpy / bmesh) and free CLI tools on the owner's RTX 5080 PC:

Step 1: Audit, Landmark Extraction, Bisect Symmetry, and Blobby Mount Excision

Tools: Blender Python API (bpy, bmesh.ops.bisect_plane, mathutils.bvhtree; Source: Blender 4.3 Python API Documentation, https://docs.blender.org/api/current/bmesh.ops.html).

Concrete Action: Import the raw Pixal3D/TRELLIS.2 .glb. Record overall bounding dimensions and ray-cast the procedural landmark coordinates (ships3d.js:840-841 muzzles, hardpoints, engine glows, bays). Bisect the mesh along the centreline plane and mirror the cleanest half (bmesh.ops.bisect_plane + Mirror modifier, skipped only on intentionally asymmetric Hullbreaker/Corsair hulls). Around every turret and engine landmark, boolean-subtract or slice away the AI mesh's melted, blobby turret bumps so clean mounting pads remain (INFERRED automation of step 5 in docs/ship_pipeline/README.md).

Step 2: Voxel Remesh, Laplacian Smoothing, and Hard-Surface Planarization

Tools: Blender Remesh modifier (OpenVDB Voxel mode; Source: Blender Manual, "Remesh Modifier", https://docs.blender.org/manual/en/latest/modeling/modifiers/generate/remesh.html), Laplacian Smooth modifier (Source: Blender Manual, "Laplacian Smooth Modifier", https://docs.blender.org/manual/en/latest/modeling/modifiers/deform/laplacian_smooth.html), and Decimate modifier in Planar mode (Source: Blender Manual, "Decimate Modifier", https://docs.blender.org/manual/en/latest/modeling/modifiers/generate/decimate.html).

Concrete Action & Settings:

Run Voxel Remesh at Voxel Size = 0.01 to 0.015 (roughly 0.5% of normalized hull length, Adaptivity = 0.0) to seal internal non-manifold cavities and equalize triangle density (Source: Blender Manual, "Remesh Modifier"; specific voxel scale for our hull size is INFERRED).

Run Laplacian Smooth (Repeat = 4 to 8, Lambda = 0.35, Preserve Volume = True) to strip high-frequency surface bumps while holding macro edges (Source: Blender Manual, "Laplacian Smooth Modifier").

Hard-Surface Planarization (for machine hulls only): Run Decimate (Planar, Angle Limit = 7 degrees to 12 degrees, All Boundaries) or section-loft replacement (SHELL=1 on severely warped bows). Planar decimation forces undulating triangles that lie within 7 degrees to 12 degrees of each other to collapse into single, dead-flat hard-surface plates (Source: Blender Manual, "Decimate Modifier").

Step 3: Retopology and Normal Weighting (With the Tactical-Camera Shortcut)

Tools: Blender Decimate (Collapse) + Weighted Normal modifier (Weight = 50, Keep Sharp = True, Face Influence = True; Source: Blender Manual, "Weighted Normal Modifier", https://docs.blender.org/manual/en/latest/modeling/modifiers/normals/weighted_normal.html) for machine hulls; QuadriFlow (bpy.ops.object.quadriflow_remesh; Source: Huang et al., 2018 / Blender Manual, "Retopology", https://docs.blender.org/manual/en/latest/modeling/meshes/retopology.html) or Instant Meshes CLI (Source: Jakob et al., SIGGRAPH Asia 2015, https://github.com/wjakob/instant-meshes) for organic hulls.

Where Tactical-Camera Teams Cut Corners: For a first-person or close-inspection asset, artists spend hours doing manual quad retopology so subdivision edge loops flow cleanly around cylinders. At a 170-unit tactical camera, edge-loop topology is invisible; only silhouette edges and vertex normals affect the pixels on screen (INFERRED from screen-space triangle size at 170 units). Therefore, on hard-surface hulls, small teams skip quad auto-remeshers (which soften crisp panel ridges into pillowy tubes) and instead use Planar-First Polygonal Retopo: planar decimation (Step 2) followed by silhouette-safe collapse decimation (18k to 30k triangles for hulls_hi/), hard-angle auto-smoothing (32 degrees to 38 degrees), and the Weighted Normal modifier so large hull plates shade completely flat right up to their bevel seams (Source: contrib/muse/design/tool_guides.md Part 1 and Blender Manual, "Weighted Normal Modifier").

Step 4: Kit Part Assembly and Offline UV Unwrap

Tools: Blender Python BVH ray-cast placer (c19_kit.py / detail_lib.py pattern), Blender Smart UV Project (bpy.ops.uv.smart_project), and Blender 4.x native C++ UV Packer (bpy.ops.uv.pack_islands; Source: Blender Manual, "UV Operators", https://docs.blender.org/api/current/bpy.ops.uv.html).

Concrete Action:

Snap clean, pre-UV'd hard-surface kit parts (turrets, engine blocks, sensor arrays, heat radiators, non-grid hull plates) onto the hull in matched symmetric pairs aimed forward or out to the side (CLAUDE.md lines 19-28).

Unwrap the hull body to a non-overlapping 0-to-1 UV0 atlas using Smart UV Project (Angle Limit = 66 degrees, Island Margin = 0.004, Area Weight = 1.0). Exporting this UV0 inside the hull .json and .vsm bypasses the runtime box-projection code in decodeAIHull (ships3d.js:753).

Step 5: Clean High-to-Low Bake (AO, Curvature, and Bevel/Kit Normals)

Tools: Blender Cycles GPU Baker (bpy.ops.object.bake; Source: Blender Manual, "Render Baking", https://docs.blender.org/manual/en/latest/render/cycles/baking.html), Cycles Bevel shader node (Source: Blender Manual, "Bevel Shader Node", https://docs.blender.org/manual/en/latest/render/shader_nodes/input/bevel.html), and Cycles Geometry -> Pointiness / Ambient Occlusion nodes.

Concrete Action (Tactical Camera Rule): Do NOT bake normals from the raw Pixal3D/TRELLIS.2 high-poly mesh onto the clean low-poly cage; doing so copies the raw AI mesh's waviness and bumps straight into _n.webp (INFERRED from tangent-space normal baking geometry). Instead, bake _n.webp and _m.webp from the planarized hull + snapped detail kit (detail_lib.py) + a Cycles Bevel shader node (Radius = 0.008, Samples = 12). This produces crisp 45-degree chamfered normal edges along every plate seam, deep contact AO under every turret and radiator, and a clean Curvature mask for edge wear, with zero AI lumpiness.

Step 6: FAC3D PBR Material Assignment and Meshoptimizer Compression

Tools: project_paint.py (refactored to pure PBR mask output) / Godot 4.7 StandardMaterial3D / ShaderMaterial, ambientCG CC0 PBR roughness maps (https://ambientcg.com/), and vsm_pack.mjs (meshoptimizer by Arseny Kapoulkine, https://github.com/zeux/meshoptimizer).

Concrete Action: Discard the projected 2D concept albedo (README.md step 4). Drive primary, secondary, trim, and emissive colours strictly from FAC3D (ships3d.js:2) using the baked AO, Curvature, and hull-zone masks (_m.webp, _f, _fn), blended with subtle CC0 metal roughness variation in the Roughness channel only. Pack to .json / .vsm and convert via godot/render/build_assets.gd.

2.2 Causes and Exact Fixes for Our Four Defects (Q6)

Defect | Specific Cause in Current Pipeline | Why Recent Passes Failed | Exact Cleanup Step That Removes the Cause
(a) Waviness (low-frequency hull undulation) | Multi-view diffusion + TRELLIS.2 / Hunyuan3D SDF extraction produces undulating surfaces across what should be flat plates or faired bows (R61, CLAUDE.md:21-28), and step 10 bakes normals from that wavy mesh (ships3d.js:943). | Repainting (G-14, Nov 1) only changes colours on top of the same wavy vertices and wavy baked normal map. | Step 2 & Step 5: Planar Decimation (Decimate -> Planar, 7 degrees to 12 degrees) + Weighted Normals (or SHELL=1 lofted bow/shell on flagships) collapses wavy triangles into flat plates, AND Step 5 stops baking normals from the raw AI mesh (baking from the planarized cage + Bevel shader instead).
(b) Bumps (high-frequency surface lumps) | 2D painterly noise in ComfyUI views becomes 3D surface lumps in Pixal3D/TRELLIS.2, baked into _n.webp (ships3d.js:943), and compounded by procedural dent/pitting normal maps in project_paint.py step 7. | Keeping raw high-to-low normal bakes and PAINT=proc pitting maps preserves the bumps regardless of albedo changes. | Step 2 & Step 5: OpenVDB Voxel Remesh + Laplacian Smooth (Repeat = 4 to 8) strips all high-frequency lumps from the geometry, AND Step 5 disables raw-AI normal baking and disables project_paint.py procedural dent/pitting noise.
(c) Grid-like texture (regular panel/box pattern) | decodeAIHull (ships3d.js:753) generates fallback UVs via a regular box projection ("about three panels per hull length"), and 2D diffusion views hallucinate cross-hatched panel grids into the projected albedo (B-16 also notes grid fallbacks). | Any hull lacking clean atlas UVs or using projected diffusion panel grids inherits the cubic grid projection at runtime. | Step 4 & Step 6: Export every hull with an offline non-overlapping UV0 (Smart UV Project) so ships3d.js:753 box-UV generation never runs, remove grid overlays, and source panel seams solely from non-grid detail_lib.py plates and planar facet bevels.
(d) Odd paint (mottled camo on Eclipse, rock paint on Maw) | Step 4 (README.md step 4-5, ships3d.js:932) projects lit 2D FLUX/ComfyUI pictures onto the 3D mesh as its albedo, baking static 2D lighting, shadows, brushwork mottling, and grazing-angle projection smear onto the hull. | The Nov 1 repaint (G-14) re-ran the same concept/procedural paint projection chain instead of separating concept silhouette from PBR shading. | Step 6: Delete concept-art albedo projection (README.md step 4) entirely. Use ComfyUI views solely for Step 1-2 geometry generation; author surface colour strictly from FAC3D (ships3d.js:2) masked by clean baked AO, Curvature, and geometric zone masks.

2.3 Organic Hull Pipeline: Chorus Bio-Fleet and The Ninefold Maw (Q7)

The fleet contains 6 Chorus organic hulls: 5 capital bio-ships (B16_23 The Ninefold Maw, B19_11, B20_11, B21_11, B22_11) and 1 bio-craft (B23_51 spore). As shown in ryan_c05.jpg, running a creature hull through a machine pipeline causes a two-fold failure: high-frequency bump noise and green-brown projected paint make the flesh read as lumpy rock, while AI-hallucinated hexagonal turrets, flat panels, and ring fittings violate CLAUDE.md ("Chorus ships are living bio-ships: no bolt-on guns; veins and sacs glow").

To make Chorus hulls read as living flesh and chitin at both tactical distance and 4K close zoom, the cleanup pipeline branches at Step 1 into a dedicated Bio-Hull Pipeline:

Step 1 (Mechanical Excision and Bio-Socket Replacement):

Never attach metal kit parts or detail_lib.py plates to B16_23 through B23_51.

For existing meshes like B16_23 where Pixal3D/TRELLIS.2 baked hexagonal turret boxes, flat panels, and ring fittings directly into the base mesh, excise those regions in Blender using boolean sphere cuts or Sculpt Mode trim/smooth passes around the landmark coordinates.

Replace excised machine mounds with a small reusable Chorus Bio-Kit (chorus_bio_kit.py, 6 organic parts): bioluminescent venom/plasma sacs, puckered maw/sphincter orifices, ridged chitin prows, gill vents, and neural tendril clusters, snapped to the hull via the same BVH ray-cast math used in c19_kit.py and blended into the hull at Step 2 (INFERRED adaptation of our existing BVH ray-cast kit script).

Step 2 (Voxel Remesh + Heavy Muscular Smoothing, Zero Planar Decimation):

Do not run Decimate (Planar) or Weighted Normals on Chorus hulls, as flat facets make organic forms look like chiseled rock.

Run Blender Voxel Remesh (Voxel Size = 0.01) after placing the bio-kit parts so the sacs and orifices fuse seamlessly into the creature's body like living tissue (Source: Blender Manual, "Remesh Modifier", https://docs.blender.org/manual/en/latest/modeling/modifiers/generate/remesh.html).

Follow immediately with heavy Laplacian Smooth (Repeat = 10 to 15, Lambda = 0.45, Preserve Volume = True) and Corrective Smooth (Source: Blender Manual, "Corrective Smooth Modifier", https://docs.blender.org/manual/en/latest/modeling/modifiers/deform/corrective_smooth.html). This strips all gravel-like surface bumps (ryan_c05.jpg) and leaves smooth, taut, muscular forms (like whale skin or cephalopod mantle) with clean anatomical folds.

Step 3 (Isotropic Quad Retopology via QuadriFlow with 180-Degree Smooth Normals):

Run QuadriFlow (bpy.ops.object.quadriflow_remesh, target 18k to 25k quads, Preserve Sharp = False) and set full smooth vertex normals across the entire mesh (Source: Blender Manual, "Retopology", https://docs.blender.org/manual/en/latest/modeling/meshes/retopology.html).

Step 4 (Organic UV0 Unwrap):

Unwrap to a non-overlapping UV0 (Smart UV Project, Angle Limit = 66 degrees, Island Margin = 0.005) so decodeAIHull's box-projection grid (ships3d.js:753) is completely bypassed.

Step 5 (Anatomical Bake: AO, Cavity/Curvature, Subsurface Thickness, and Striated Bio-Normals):

In Blender Cycles, bake three channels into _m.webp / _f:

Ambient Occlusion (deep anatomical creases).

Cavity / Curvature (identifying raised chitin spine crests vs recessed vein channels).

Subsurface Thickness (baked via a Cycles Ambient Occlusion node with Inside = True; Source: Blender Manual, "Ambient Occlusion Node", https://docs.blender.org/manual/en/latest/render/shader_nodes/input/ao.html), measuring how thin or fleshy each region is.

For _n.webp, generate a clean two-zone organic normal map in Blender shader nodes: smooth taut skin in concave fleshy zones, and subtle longitudinal muscle/chitin striations along raised dorsal ridges (INFERRED procedural Blender node graph).

Step 6 (Flesh, Chitin, and Glowing Vein Shader Driven by Chorus FAC3D):

Discard all projected concept paint. Using only the Chorus FAC3D colour tokens (ships3d.js:2):

Metallic = 0.0 across the entire hull.

Wet-vs-Matte Roughness Contrast: Fleshy membranes, maws, and sacs use low roughness (0.15 to 0.25) so they catch tight, wet specular highlights like living mucous membrane; raised dorsal carapace ridges use higher roughness (0.55 to 0.70) and darker Chorus FAC3D values to read as ossified bone/chitin (Source: Marmoset PBR Theory Guide, marmoset.co; applied to Chorus palette as INFERRED).

Subsurface Scatter / Translucency: Drive Godot 4.7's StandardMaterial3D Subsurface Scattering (subsurf_scatter_enabled = true; Source: Godot 4.x Documentation, "Standard Material 3D", https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html) using the baked Thickness map so thin fins, maws, and sacs transmit warm internal Chorus hues rather than shading like opaque grey stone.

Emissive Veins and Sacs (CLAUDE.md): Mask the Chorus FAC3D emissive channel into recessed anatomical valleys (via the inverted Cavity map modulated by an organic Voronoi/branching vein mask) and across the fused bio-sac domes.

3. Fleet Scope, Route Options, Effort Pricing, and Risk Matrix

3.1 Verified Fleet Scope (pack.md Section 3.1)

The issue 75 and 76 text refers to "28 hulls", which is an unverified error and is not used below. Every effort estimate below prices the verified 36 unique hull meshes in hulls/, hulls_hi/, AI_HULLS (ships3d.js:704), and godot/assets/ships/manifest.json:

30 Faction Capital Hulls:

25 Machine Capital Hulls: Hegemony (5), Crusade (6, where C19_51 Warlord's Pyre-Barge already has an approved R13 shape and R14 paint step awaiting R16 final sign-off, leaving 24 unstarted machine capitals), Hullbreakers (5), Glasswrights (5), Eclipse (4).

5 Organic Capital Hulls: Chorus (B16_23, B19_11, B20_11, B21_11, B22_11).

3 Squadron Craft: S1_51 fighter, S2_23 bomber, B23_51 Chorus organic spore.

3 Objective Structures: O1_37 station, O2_37 transport, O3_11 beacon.

Total by surface family: 30 Machine Meshes (25 capitals + 2 craft + 3 structures; 1 already built as C19_51, 29 unstarted) and 6 Organic Chorus Meshes (5 capitals + 1 spore craft; all 6 unstarted).

3.2 The Four Route Options

Route 0 (Baseline): Keep Polishing the Current Chain (Projected Concept Paint + Procedural Grain/Repaint Sweeps)

What it is: Continue running the existing 10-step chain (docs/ship_pipeline/README.md) and TEXTURE_PASS.md triplanar noise overlays without replacing the raw AI mesh geometry or projected concept paint.

Effort across 36 hulls: Already spent in the Nov 1 repaint sprint (G-14, commit fc9b347); further sweeps cost roughly 2 to 4 agent script hours + 2 PC batch hours + 2 owner review hours per sweep across all 36 hulls.

What it does to the four defects:

Waviness: Leaves it. The underlying AI mesh and high-to-low normal bake remain wavy (R61).

Bumps: Leaves or worsens it. Adding triplanar detail or procedural dent maps (PAINT=proc) over lumpy AI geometry compounds the noise.

Grid texture: Leaves it on any hull hitting the ships3d.js:753 box-UV fallback or carrying diffusion panel grids.

Odd paint: Leaves it. As proven by G-14 on Nov 1 and the Nov 2 playtest shots (ryan_c01.jpg, ryan_c05.jpg), re-projecting concept views or repainting on the same meshes is a proven non-fix.

Which hulls it does not fit: Fails on all 36 hulls.

Route A: C19-Pattern Full Kitbash Rebuild with Clean Lofted Shell (SHELL=1), Per-Hull Kit (_kit.py), and Trim Sheet

What it is: Demote every AI mesh to a measuring guide, loft a fresh faired hull shell from measured cross-sections (SHELL=1), author a bespoke per-hull Python kit script (_kit.py like c19_kit.py) with hand-fitted bevelled parts and detail_lib.py plates, unwrap to a faction trim sheet, and bake procedural FAC3D PBR maps.

Effort Pricing (35 remaining hulls; C19_51 shell/kit v15 already built):

Per hull: 6 to 10 agent coding/iteration hours (writing and debugging bespoke _kit.py coordinate geometry and SHELL=1 loft sections per hull across multiple 9-cell BLOB_SWEEP.md rounds) + 0.5 PC batch hours (Blender build + bake on RTX 5080) + 0.75 owner review hours (running .bat and reviewing 9-cell sheets and in-game shots).

Total across 35 remaining hulls (or 29 remaining machine hulls): 210 to 350 agent coding/iteration hours (roughly 3 to 5 weeks of calendar wall-time across iterative review rounds), 18 PC batch hours, and 26 owner review hours.

What it does to the four defects:

Waviness: Removes the cause completely (for machine hulls) because SHELL=1 replaces the wavy AI mesh with a clean lofted shell.

Bumps: Removes the cause completely because the shell is smooth lofted geometry and detail comes only from clean detail_lib.py plates and kit parts.

Grid texture: Removes the cause completely when paired with offline trim/atlas UVs replacing ships3d.js:753.

Odd paint: Removes the cause completely when projected concept paint (README.md step 4) is dropped in favour of FAC3D procedural/trim materials.

Which hulls it does NOT fit:

Does NOT fit the 6 Chorus organic hulls (B16_23 to B23_51): Lofted hard-surface shells, bevelled bolt-on kits, and trim sheets are machine idioms that violate CLAUDE.md bio-ship rules.

Overkill for the 3 squadron craft (S1_51, S2_23, B23_51) and 3 objective structures (O1_37, O2_37, O3_11): Squadron craft occupy only a few dozen pixels at the 170-unit tactical camera.

Route B: Automated Voxel Remesh, Retopo, Baked Detail, and Faction PBR Replacing Projected Paint (Issue 75 Spec)

What it is: Run a unified automated Blender batch script across the fleet: voxel remesh and auto-retopologize each AI mesh to a clean low-poly cage with smooth normals, bake detail from the high-poly mesh to a normal map, and replace projected concept paint with faction PBR materials (panel lines, edge wear, decals) driven by FAC3D.

Effort Pricing (All 36 hulls):

Upfront pipeline scripting: 16 to 24 agent coding hours to build the headless Blender remesh/retopo/UV/bake pipeline and Godot/JS material loader updates.

Per hull: 0.5 agent tuning hours + 0.25 PC batch hours on RTX 5080 + 0.25 owner review hours.

Total across all 36 hulls: 34 to 42 agent hours, 9 PC batch hours, and 9 owner review hours.

What it does to the four defects:

Waviness: Only reduces it (does NOT remove the cause on machine hulls) if implemented as written in issue 75. Standard voxel remesh + smooth auto-retopo preserves low-frequency waves in the macro hull, and baking normals from the raw AI high-poly mesh copies the waviness right back into _n.webp.

Bumps: Reduces or re-introduces it unless high-to-low normal baking from the raw AI mesh is replaced with a clean bevel/procedural normal bake.

Grid texture: Removes the cause by generating offline Smart UV Project atlases for every hull and bypassing ships3d.js:753.

Odd paint: Removes the cause completely by deleting projected concept paint (README.md step 4) and replacing it with FAC3D-driven PBR materials.

Which hulls it does NOT fit:

Fails on the 6 Chorus organic hulls (B16_23 to B23_51) if they receive panel lines, edge wear, and machine decals (pack.md section 5), and fails to remove AI-hallucinated hexagonal turrets baked into B16_23 (ryan_c05.jpg).

Leaves blocky/melted AI turrets and wavy bows on the 25 machine capital hulls: As settled in contrib/muse/design/tool_guides.md line 21, "kit parts are the AI mesh fix, not decoration"; without kit parts replacing melted AI guns/engines and planar decimation flattening armour slabs, Route B hulls read as soft, blobby soap bars at close zoom.

Route C (Chair Research Hybrid): Planar/Bio Cage Cleanup + Shared Faction Socket Kits + Flagship-Only Shell Loft

What it is (Synthesizing Homeworld 3, BFG: Armada, Sins 2, and tool_guides.md):

Universal Paint & UV Fix (All 36 Hulls): Delete projected concept paint (README.md step 4) and runtime box UVs (ships3d.js:753). Export every hull with offline UV0 (Smart UV Project). Bake AO, Curvature, and Bevel/Kit normals from the cleaned cage (never from the raw AI mesh). Drive all colour from FAC3D (ships3d.js:2) via faction PBR presets (clean calm primary plates holding 75% rest area like Homeworld 3, dark recessed seams, curvature edge wear, and bounded faction stripes).

Branch C1 for the 30 Machine Meshes (25 Machine Capitals + 2 Machine Craft + 3 Structures):

Automated Hard-Surface Planar Cage (clean_machine_cage.py): Headless Blender script runs Bisect Symmetry -> Landmark Blobby-Mount Excision -> Voxel Remesh (0.012) -> Laplacian Smooth -> Planar Decimation (Decimate -> Planar, 8 degrees) -> Collapse Decimation (20k-30k tris) -> Weighted Normals (Keep Sharp) + Cycles Bevel Shader Normal Bake. This automatically turns wavy, bumpy AI geometry into crisp, flat-faceted hard-surface plates.

5 Shared Machine Faction Kit Libraries (Instead of 30 bespoke _kit.py scripts): Just as BFG: Armada, Homeworld 3, and Sins 2 share turrets and fittings across a faction, agents build one reusable Python kit library per machine faction (Hegemony, Crusade, Hullbreakers, Glasswrights, Eclipse: 6 clean parts per faction: primary turret, secondary turret, engine thruster bank, radiator fin array, sensor tower, prow cap, mapped to a shared faction trim sheet). An automated placer script snaps each faction's shared kit parts onto every hull in that faction at the existing ships3d.js:840-841 ray-cast landmark sockets plus detail_lib.py non-grid hull plates.

Selective SHELL=1 Loft Only Where Needed (Flagships + Failed Bows): Keep C19_51's existing shell/kit, and apply SHELL=1 cross-section lofting only to the 4 remaining machine faction flagships (plus any individual bow that fails the 9-cell BLOB_SWEEP.md gate after planar decimation).

Branch C2 for the 6 Chorus Organic Meshes (B16_23 to B22_11 + B23_51 Spore):

Run the Q7 Bio-Hull Pipeline (clean_bio_cage.py + chorus_bio_kit.py): Excise AI machine blocks (ryan_c05.jpg) -> Snap shared organic kit growths (glowing sacs, sphincter maws, chitin spines) at landmarks -> Voxel Remesh + heavy Laplacian/Corrective Smooth (fusing kit growths seamlessly into flesh, zero planar decimation) -> QuadriFlow isotropic quads with 180 degree smooth normals -> Bake AO, Cavity, and Subsurface Thickness -> Render with Chorus FAC3D zero-metallic wet-flesh/matte-chitin dual roughness, subsurface thickness scatter, and glowing cavity veins.

Effort Pricing (Across All 36 Verified Hulls):

Upfront Shared Tooling & Faction Kits (Agent Coding):

clean_machine_cage.py + clean_bio_cage.py + FAC3D PBR material baker (project_paint.py replacement): 20 agent hours.

5 Machine Faction Socket Kit libraries + 1 Chorus Bio-Kit library (6 kits x 6 parts = 36 modular parts total, vs 36 bespoke full-ship rebuilds): 30 agent hours.

Selective SHELL=1 section-lofting for 4 remaining machine flagships + ~4 bow-fix hulls: 24 agent hours (3 hours per hull).

Per-Hull Execution Across All 36 Hulls:

Agent tuning / BLOB_SWEEP.md verification: 0.75 agent hours per hull (27 agent hours total).

PC batch compute on RTX 5080 (double-click .bat): 0.3 hours per hull (11 PC hours total).

Owner review (9-cell contact sheets + 4K Godot battle-camera check): 0.35 hours per hull (12.5 owner hours total).

Total Effort for All 36 Hulls: ~101 agent hours (roughly 5 to 7 focused days of agent execution), 11 PC batch hours, and 12.5 owner review hours.

What it does to the four defects:

Waviness: Removes the cause across both machine hulls (via Planar Decimation + Weighted Normals + flagship/bow SHELL=1 lofts + zero raw-AI normal baking) and bio-hulls (via heavy Laplacian/Corrective smoothing).

Bumps: Removes the cause across all 36 hulls (via OpenVDB Voxel Remesh + Laplacian Smooth + dropping raw-AI normal bakes and PAINT=proc dent noise).

Grid texture: Removes the cause across all 36 hulls (offline Smart UV Project UV0 on every hull + non-grid detail_lib.py plates).

Odd paint: Removes the cause across all 36 hulls (deletes README.md step 4 concept projection; uses FAC3D machine PBR and Chorus bio-shaders).

Which hulls it does NOT fit: Fits all 36 hulls because it explicitly splits machine capitals (25), Chorus bio-hulls (6), squadron craft (2 machine + 1 bio, using the cage pass without heavy kit overhead), and objective structures (3, using the machine cage + structure kit sockets).

3.3 Route Comparison and Constraint Risk Matrix

Criterion / Constraint | Route 0: Baseline (Repaint Current) | Route A: Full C19 Kitbash + Loft (All Hulls) | Route B: Pure Voxel Remesh + Retopo + PBR | Route C: Hybrid Planar/Bio Cage + Faction Kits + Flagship Loft
1. Waviness | Leaves it | Removes cause (lofted shell) | Reduces only (waves survive in macro & raw normal bake) | Removes cause (Planar Decimate + Weighted Normals + flagship bow loft + bevel bake)
2. Bumps | Leaves / worsens it | Removes cause (clean shell) | Reduces only if raw normal bake is dropped | Removes cause (Voxel Remesh + Laplacian Smooth + clean bevel/kit normal bake)
3. Grid Texture | Leaves it | Removes cause (offline UVs) | Removes cause (offline UV0) | Removes cause (offline UV0 + non-grid detail_lib.py plates)
4. Odd Paint | Leaves it (G-14 proved) | Removes cause (FAC3D PBR) | Removes cause (FAC3D PBR) | Removes cause (FAC3D machine PBR + Chorus bio-shader)
5. Chorus Bio-Hulls (6 meshes) | Fails (ryan_c05.jpg) | Fails (machine loft/kit idiom) | Fails (machine panel/edge-wear idiom + keeps AI turrets) | Fixes cause (excises machine blocks, fuses bio-kit sacs, wet/chitin SSS + glowing veins)
6. Total Agent Hours (36 hulls) | ~4 hrs (wasted) | 210 to 350 hrs | 34 to 42 hrs | ~101 hrs
7. Total Owner Review Hours | ~2 hrs | ~26 hrs | ~9 hrs | ~12.5 hrs
Risk: FAC3D Single Colour Source | Safe | Safe (uses FAC3D) | Medium risk if external PBR albedos are imported; safe if masked by FAC3D | Zero risk: baked maps are greyscale AO/Curvature/Thickness masks; all colour comes from FAC3D (ships3d.js:2)
Risk: R73 Ship Break-Up (Clip-and-Plug / Plane Cuts) | Safe | Medium risk: separate floating kit sub-meshes (_kit.json) must be clipped alongside the hull shell | Low risk: single manifold watertight voxel-remeshed hull cuts cleanly | Low risk: voxel-remeshed hull cage is watertight manifold for clip-and-plug; kit parts either merge pre-export or clip by bounding plane
Risk: R76 Damage Surface Work (Issue 51) | Safe | Safe | Safe (cleaner surface normals improve damage decal projection) | Low risk / Positive: flat face normals and clean UV0 stop damage decals from warping over bumpy triangles
Risk: Godot build_assets.gd & decodeAIHull | Safe | Safe (C19_51 path works) | Safe (writes standard .json, _n.webp, _m.webp) | Zero risk: outputs the exact same hulls_hi/ and hulls/ .json/.vsm, _n.webp, _m.webp consumed by build_assets.gd:106 and ships3d.js
Risk: BLOB_SWEEP.md 9-Cell Gate | Fails gate | Passes gate (at high effort) | Fails gate on melted AI turrets & wavy bows | Passes gate: landmark excision + shared faction kits fix turrets; planarization + selective SHELL=1 fix wavy bows

4. Recommendation and How to Judge the Issue 75 Bake-Off

4.1 Single Recommendation: Adopt Route C (Planar/Bio Cage + Shared Faction Socket Kits + Flagship Loft)

We recommend Route C across the verified 36-hull fleet.

Reasoning:

Why Route 0 is dead: The Nov 1 repaint of all 36 hulls (G-14, commit fc9b347) proved that repainting on top of raw Pixal3D/TRELLIS.2 meshes and projected concept textures leaves waviness, bumps, grid projections, and odd paint intact.

Why pure Route B (as scoped in issue 75) is only half the fix: Route B rightly kills projected concept paint and replaces it with FAC3D-driven PBR materials, and rightly uses voxel remeshing to strip high-frequency bumps. However, without Planar Decimation + Weighted Normals, a voxel-remeshed AI hull keeps its low-frequency waviness; without dropping high-to-low normal bakes from the raw AI mesh, the normal map copies the bumps and waves right back onto the low-poly mesh; without shared faction socket kits, the AI mesh's melted, blobby gun boxes and engine blocks remain an eyesore (contrib/muse/design/tool_guides.md line 21); and without a dedicated Bio-Hull branch (Q7), Route B puts machine panel lines on The Ninefold Maw (B16_23) while leaving its hallucinated hexagonal turret blocks untouched.

Why pure Route A (C19_51 bespoke rebuild on every hull) does not scale: C19_51 proved that lofting a custom shell and hand-coding a bespoke kit script works visually (R13, R14), but SHIP_QUEUE.md proves its economic cost: after all the work on C19_51, 35 of 36 hulls remain unstarted. Repeating bespoke per-hull kit scripting across 35 more hulls costs 210 to 350 agent hours and weeks of review.

How Route C captures Route A's look at nearly Route B's speed: Every shipped 3D tactical fleet game we studied (BFG: Armada, Homeworld 3, Sins 2, BSG Deadlock) scales to 30+ ships by combining clean, flat-shaded primary hull geometry with shared faction part libraries (turrets, engines, radiators, sensors) mounted on sockets and curvature/AO-masked faction PBR materials with 70% to 80% calm rest areas. Route C automates the flat-shaded primary hull via Planar Decimation + Weighted Normals (reserving SHELL=1 lofts only for the 5 machine flagships and any bow that fails BLOB_SWEEP.md), builds 5 shared machine faction kits + 1 Chorus bio-kit that snap automatically to ships3d.js landmarks, and branches the 6 Chorus hulls into a true flesh-and-chitin pipeline.

4.2 How to Judge the Issue 75 Bake-Off Pictures When They Land

When Codex delivers the issue 75 comparison sheets (docs/shots/ship_pipeline/) for C19_51, the Eclipse zenith cruiser, and B16_23 (The Ninefold Maw), inspect three specific things in the screenshots:

On the Eclipse cruiser (Route B vs Today): Look at the broadside armour plates under angled light and the gun/engine blocks. Expect Route B's faction PBR paint to immediately cure the mottled camouflage (odd paint) and the grid texture from ryan_c01.jpg. However, check whether Route B's hull still shows gentle low-frequency waviness along the bow or soft, melted turret blocks. If it does, that confirms Route B needs Route C's Planar Decimation + Weighted Normals + Bevel Shader bake (instead of raw high-to-low normal baking) and shared faction kit sockets.

On the Warlord's Pyre-Barge C19_51 (Route A vs Route B): Compare the crispness of C19_51's kit-built turrets, radiators, and lofted bow on Route A against Route B's remeshed AI turrets at the 170-unit battle camera. If Route A's silhouette and hard-surface crispness clearly beat Route B on the Barge, that validates keeping C19_51's Route A shell/kit for flagships while using shared faction socket kits (Route C) to bring that same crisp turret/engine read to the other 24 machine capitals without writing 24 bespoke scripts.

On The Ninefold Maw B16_23 (Route B vs Today): Check whether Route B accidentally applied machine panel lines or edge wear to the Maw, and check whether the hexagonal turret block and ring fittings visible in ryan_c05.jpg are still sitting on its back. If they are still there, or if the hull still looks like dry matte rock instead of wet translucent flesh and matte chitin, that confirms the 6 Chorus hulls require Route C's Branch C2 Bio-Hull Pipeline (Q7).

5. Owner Questions (With Chair Pick and Cost in Plain Words)

Q1. Should we permanently drop projected 2D concept paint (README.md step 4) across all 36 hulls and replace it with FAC3D-driven PBR materials?

Option 1 (Chair Pick): Yes, drop projected concept paint everywhere. Use FLUX and ComfyUI multi-views strictly to generate the 3D shape; colour every hull from FAC3D (ships3d.js:2) using clean baked AO, Curvature, and hull-zone masks (calm 75% primary plates, dark seams, bounded faction stripes, zero baked 2D lighting).

Cost: Included in Route B and Route C (~8 agent hours to update project_paint.py and the material loader). Eliminates "odd paint" and mottled camouflage across the entire fleet permanently.

Option 2: Keep trying to blend or clean up projected concept paint.

Cost: Already tried in the Nov 1 repaint (G-14) and failed; every future light change or close zoom will continue to expose baked 2D shadows and projection smear.

Q2. How should we build hard-surface kit parts (turrets, radiators, sensors, engines) across the 29 remaining machine hulls?

Option 1 (Chair Pick): Build 5 shared machine faction kit libraries (Route C) that auto-snap to ships3d.js landmarks, plus SHELL=1 lofts only on the 4 remaining machine flagships and any bow that fails BLOB_SWEEP.md.

Cost: ~54 agent hours for the 5 faction kits and flagship lofts (~101 agent hours total for the whole 36-hull pipeline). Gives every ship crisp bevelled turrets, engines, and radiators while keeping each faction visually cohesive (like BFG: Armada and Homeworld 3).

Option 2: Full Route A (C19_51 bespoke shell loft and hand-scripted _kit.py on all 29 remaining machine hulls).

Cost: 175 to 290 agent hours and 3 to 5 weeks of review cycles. Maximum per-hull uniqueness, but delays fleet completion heavily.

Option 3: Pure Route B (No kit parts on non-C19 hulls; rely on remeshed AI turrets and normal maps).

Cost: Saves ~54 agent hours, but leaves blocky/melted AI gun housings and engine blocks visible on 29 machine hulls, violating the settled rule in contrib/muse/design/tool_guides.md line 21.

Q3. How should we handle the 6 Chorus organic hulls (B16_23 The Ninefold Maw through B23_51 Spore)?

Option 1 (Chair Pick): Run the dedicated Bio-Hull Pipeline (Branch C2 / Q7). Automatically slice off AI-hallucinated machine parts (ryan_c05.jpg), snap a 6-part organic bio-kit (glowing sacs, sphincter maws, chitin spines) at landmarks, fuse them with Voxel Remesh + heavy Laplacian smoothing into taut muscle folds, and shade with Chorus FAC3D zero-metallic wet-flesh vs matte-chitin roughness, subsurface thickness scatter, and glowing veins.

Cost: ~14 agent hours (included in the ~101-hour Route C total) + 2 PC batch hours + 2 owner review hours for all 6 Chorus hulls. Fixes the rock/machine category error on the Maw and all Chorus ships.

Option 2: Run Chorus hulls through the same remesh + PBR script as the metal fleets, just swapping the colour palette to green/purple.

Cost: 0 extra agent hours, but leaves hexagonal turret blocks on the Maw (ryan_c05.jpg) and makes bio-ships read as painted rock or green metal.

Q4. Should kit parts be merged into the single .vsm / .json hull mesh at export, or shipped as a separate _kit.json file per hull (as C19_51 does today)?

Option 1 (Chair Pick): Merge static hull kit parts (radiators, sensor arrays, dorsal plates, engine blocks, bio-sacs) directly into the main hull .json / .vsm before export, keeping only independently rotating turrets separate if needed.

Cost: ~4 agent hours in pixal_to_game.py and build_assets.gd. Halves draw calls per ship, simplifies build_assets.gd conversion, and makes R73 ship break-up (clip-and-plug / plane cuts) work on a single unified mesh instead of desyncing between hull and _kit.json.

Option 2: Ship a separate _kit.json and extra finish maps (_a, _f, _fn) for all 36 hulls like C19_51 today.

Cost: Extra file management across 36 hulls and requires the R73 break-up system to clip and cap two separate meshes per ship simultaneously.

6. Not Checked

Live Issue 75 Bake-Off Screenshots and Timings: Issue 75 is marked OPEN and blocked at grounding time and has produced no renders or frame-cost measurements yet; Section 4.2 provides the rubric to judge those sheets as soon as Codex delivers them.

Unpublished Internal Studio Asset Budgets: Neither Tindalos Interactive, Blackbird Interactive, Ironclad Games, nor Black Lab Games publicly discloses exact studio person-days or dollar cost per individual ship hull; all per-hull studio effort comparisons in Q4 are explicitly marked INFERRED from documented team headcounts, ship roster counts, and published workflow talks.

Visual Inspection of ryan_c02.jpg through ryan_c04.jpg and ryan_c06.jpg through ryan_c08.jpg: Grounded from the chair read in pack.md Section 2 (ryan_c01.jpg and ryan_c05.jpg read closely, with the four named defects treated as the fixed target list per pack instructions).
