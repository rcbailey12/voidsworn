DeepSeek leg  -  how shipped space games and working hard-surface artists make detailed ships that stay clean

Scope. This leg works from the pack only, plus public sources found and cited below. It answers Ryan's question directly, gives a per-method cost table, covers studio evidence for the named games, and ends with a ranked recommendation for the Pyre-Barge round 2 in #111. Anything not directly supported by a named source is marked INFERRED.

1. Bottom line, including Ryan's question

Adding more triangles and more detail to a wavy mesh does not smooth the waves out. It makes the waves more accurately wavy.

The reason is structural. A wave in an AI-generated hull is low-frequency displacement: the surface itself is in the wrong place. Subdividing or triangulating that surface gives you more vertices on the same wrong surface. More triangles improve the curvature of the wave and the shading of the wave, but they do not move the surface back to flat. A normal map behaves the same way: it changes the normal used by the lighting equation, not the vertex positions, so it cannot flatten a silhouette or a grazing-angle surface. If you bake a wavy high-poly onto a clean low-poly without filtering, the bake carries the low-frequency wave across as well as the fine detail, because the bake is recording the high-poly surface angles. [76] [183] [227]

The fixes that actually work in the sources are all variations on one principle: separate the low-frequency form from the high-frequency detail, rebuild the low-frequency form cleanly, and only transfer the high-frequency part. That is exactly what the Sins of a Solar Empire II art pipeline does when it builds a quad low-poly, bevels and subdivides it into a high-poly, then aligns the low and high before baking. It is also what a high-pass or cavity-only bake is for: keep the small edges, recesses and surface noise; reject the broad slow wave. [42] [322] [374]

So the answer to Ryan is: more triangles is not an alternative meshing approach for this problem; it is more resolution on the same problem. The alternative approaches are clean construction, part splitting, authored high-to-low baking, and high-pass/cavity-only transfer.

2. Per-method table

Costs are per hull. Triangle anchors come from published Sins of a Solar Empire II targets: fighter ~1,500; frigate ~12,500; cruiser ~25,000; capital ~75,000; titan ~225,000. Artist-time figures are INFERRED estimates from the scope of the cited workflows; no studio publishes per-hull hours. [361]

Method | What it fixes | Artist time per hull | Triangle cost | Free tools

Part splitting / kit parts / greeble kits | Prevents one continuous wavy shell; lets panels, frames, pipes and guns sit on clean mounts; makes silhouette and shading readable at distance | INFERRED 0.5-2 days for a kitbash pass; more if parts must be cleaned | Low to moderate; separate parts can be reused, but draw calls rise. Kitbash packs range from <100 to several thousand faces per part [61] | Blender (Asset Browser, collection instances), free kitbash/greeble packs, xNormal for any baked parts

Subdivision + bevel + weighted normals (mid-poly) | Gives clean rounded edges and controlled highlight width; removes the “soft blob” look of a noisy mesh; holds shape under subdivision | INFERRED 1-2 days per hull for a disciplined bevel/holding-edge pass | Moderate; bevels add loops, but the low-poly stays far below a sculpt. Sins capital target 75k tris [361] | Blender Bevel modifier, Subdivision Surface modifier, Weighted Normal modifier [316] [317] [365]

Authored high-poly → low-poly bake | Transfers crisp panel lines, bolts, vents and wear into normal/AO/curvature maps without carrying the high-poly triangles | INFERRED 3-7 days per hull for a clean high-poly and a well-matched low-poly | Low-poly target 25k-75k for cruiser/capital; high-poly can be millions but is discarded [361] | Blender Cycles bake (Selected to Active, Cage); xNormal (free) for normal/AO [129] [318]

Trim sheets | Replaces unique panel-line geometry and unique textures with a reusable atlas; keeps style consistent and cuts texture sets | INFERRED 2-4 days per sheet, amortised across the fleet; much cheaper per hull after the first | 0 extra triangles; the detail lives in the normal/trim texture [47] | Blender UVs, Krita/GIMP/Inkscape for the sheet, xNormal or Blender for the trim normal

Decals and floaters | Adds stencils, hazard stripes, numbers, rust streaks and small raised plates without modelling every mark | INFERRED 0.5-1 day per hull | Decals: 0-50 tris each if texture decals; floaters: tens to hundreds of tris each [90] | Blender (mesh decals, shrinkwrap), Inkscape/Krita for vector/raster decals, free alpha-test workflow [170]

Texture-only detail at distance vs geometry up close | Cheaply sells scale at RTS distance; geometry is reserved for silhouette and close-up | INFERRED 0.5-1 day to author the texture detail; geometry cost avoided | The normal-map lab's demo: 2 triangles + 256² normal map looks nearly identical head-on to 18,432 triangles, but the silhouette and grazing angle expose the fake [183] | Blender, xNormal, Krita/GIMP

Planar construction / flattening | Removes slow waves from surfaces that should be flat; gives the bake a clean plane to receive detail | INFERRED 0.5-1 day for a cleanup pass on a hero hull | Often reduces triangles, because flat surfaces need fewer vertices | Blender Flatten operator (Best Fit / Normal plane); Decimate Planar for cleanup [364]

2D sprite / painted ship (Starsector alternative) | Avoids 3D mesh waves entirely; extremely readable at RTS distance; cheap per ship | INFERRED 1-3 days per sprite | 0 3D triangles; the cost is in the painted sprite | Krita, Aseprite, GIMP, Inkscape

3. Method detail

3.1 Part splitting, kit parts and greeble kits

The strongest hard-surface modelling advice in the sources is not “subdivide harder”; it is “stop modelling the ship as one mesh.” On Polycount, the response to a spaceship subdivision problem is blunt: modelling everything from a single part is asking for trouble with sub-D; break the ship into panels, break the wings away, and model the window frames and glass as separate geometry. The same thread later describes plating as splitting the model into several objects, shelling each one, rather than trying to flow one continuous surface across the whole hull. [90]

That is the direct fix for waves and blobs: a wave is a property of a continuous surface. Once the hull is split into panels and kit parts, each part can be planar, bevelled and mounted cleanly, and the eye reads the assembly as intentional structure rather than a soft continuous shell.

Greebles and kitbashing are the production vocabulary for this. Greebles are small relief details used to give visual complexity and an illusion of scale; in Star Wars, simple shapes were given complexity by attaching greebles taken from commercial model kits. Kitbashing is the practice of making a new model by taking pieces out of kits, and commercial kits are a ready source of identical, mass-produced detailing components. For a game hull, the equivalent is a reusable library of vents, pipes, hatches, frames and turret bases that snap onto the clean surface on visible mounts. This is also the production logic behind variant 3 in #111: cut the good AI chunks out, clean them, and re-seat them as kit parts rather than letting the AI mesh define the hull. [143] [144]

Cost. INFERRED 0.5-2 days per hull for a kitbash pass, depending on how much cleaning the parts need. Triangles are not the main cost; draw calls and material slots are. The triangle cost is low per part, but a hull with 50 kit parts can add thousands of triangles and several draw calls if the parts are not merged or instanced.

Free tools. Blender Asset Browser and collection instances; free greeble/kitbash packs (many are CC0 or free for commercial use, but check licences); xNormal if the kit parts are baked into a low-poly hull.

3.2 Subdivision, bevels and weighted normals

The Sins II art journal describes the clean version of this pipeline. Start with a quad-dominant low-poly with “globe-like” topology following the silhouette; select holding edges; bevel or chamfer those edges; subdivide to create the high-poly; then use the high-poly as a reference to adjust the low-poly so the bake captures as much detail as possible. The journal explicitly says the bevel “will bake down and rid the model of hard, unrealistic sharp edges”. That is the opposite of adding random triangles to a wavy AI mesh: the shape is controlled by holding edges and bevel width, not by density. [374]

Weighted normals are the shading half of the same method. Blender's Weighted Normal modifier changes custom normals to make faces appear flat during shading and can preserve sharp edges. The Bevel modifier has a Harden Normals option that adjusts the bevel faces to match the surrounding faces so the flat surfaces stay flat. This is how you get a clean, crisp hard-surface read at RTS distance without the shading looking soft or melted. [316] [365]

Cost. INFERRED 1-2 days per hull. Triangle cost is moderate: bevels add loops, but the low-poly stays well under a sculpt. A Sins capital target of 75k tris is a useful upper anchor. [361]

Free tools. Blender Bevel modifier, Subdivision Surface modifier, Weighted Normal modifier. [316] [317] [365]

3.3 Authored high-poly → low-poly baking

This is the production standard in the sources. The Sins II artist models a clean high-poly, aligns the low-poly to it, then bakes. The journal warns that if the low-poly geometry does not match the high-poly, the bake will fail; the fix is to add a subdivision level only to the faces that do not match, then clean up the resulting n-gons. The low-poly is triangulated for baking and the tri count is reduced as much as possible. [374]

The original Sins of a Solar Empire art dump shows the same pipeline at an earlier era: the artist modelled the high-resolution ship, baked the normal map and ambient occlusion in xNormal, textured in Photoshop, and used 2048×4096 textures. The explicit reason was that they “needed a lot of small details to sell the idea that these ships are huge”. That is the key production insight for #111: the detail that sells scale is in the bake, not in the hull's triangle count. [129]

Blender's bake supports this directly. Selected to Active casts rays from the low-poly inwards to the high-poly; a cage is a ballooned-out version of the low-poly that gives control over the ray start, and the manual warns that hard splits and edge-split modifiers produce non-smooth normals around edges. [318]

Cost. INFERRED 3-7 days per hull for a clean high-poly plus a matched low-poly. Low-poly target 25k-75k for cruiser/capital; high-poly is discarded. [361] The cost is front-loaded; once the high-poly exists, the bake is fast and repeatable.

Free tools. Blender Cycles bake (Selected to Active + Cage); xNormal for normal/AO. [129] [318]

3.4 Trim sheets

Trim sheets are reusable texture atlases containing strips, panels and detail bands that can be mapped onto many hard-surface assets. The 80.lv breakdown describes using trim sheets to texture a lot of assets while using as few texture sets as possible, which saves time and keeps the art style consistent. On Polycount, the trim is described as a normal map with bevel detail specifically designed to stretch, avoiding fine noise-like detail that would make stretching obvious. [47] [116]

For the Pyre-Barge, trim sheets are the cheapest way to get repeated panel lines, bolts, seams and worn edges across three variants without modelling them three times. They also give the clean low-poly something to wear after the AI wave has been removed.

Cost. INFERRED 2-4 days per sheet, amortised across the fleet. 0 extra triangles; the detail is in the normal/trim texture. This is one of the best triangle-per-detail trades in the table.

Free tools. Blender UVs, Krita/GIMP/Inkscape for the sheet, xNormal or Blender for the trim normal.

3.5 Decals and floaters

Decals are commonly used for bullet marks, graffiti, broken edges and tire tracks; for hard-edged decals, alpha test is cheaper to render than alpha blend. In the 80.lv vehicle breakdown, decals are made in vector form so they can be scaled without losing detail. For spaceship hulls, decals carry stencils, hazard stripes, registry numbers, rust streaks and faction marks that would be wasteful to model. [170] [321]

“Floaters” are small mesh pieces that sit above the surface and are either baked into the normal map or kept as real geometry. The Polycount spaceship thread lists mid-poly modelling with floater decals as a middle option: no full high-poly is needed, only the floaters themselves. [90]

Cost. INFERRED 0.5-1 day per hull. Texture decals cost 0-50 tris each; mesh floaters cost tens to hundreds of tris each. The real cost is UV space and overdraw, not triangles.

Free tools. Blender (mesh decals, shrinkwrap), Inkscape/Krita for vector/raster decals.

3.6 Texture-only detail at distance vs geometry detail up close

The normal-mapping lab gives the cleanest cost/benefit statement in the sources. A 2-triangle quad with a 256² normal map looks nearly identical head-on to 18,432 triangles of real geometry, and costs one texture fetch. But the normal map cannot move a vertex: at a grazing angle the silhouette stays a straight line while the real geometry is ragged. That is the trade in one sentence. [183]

For an RTS camera, texture-only detail is the correct default for most surface noise, panel seams, vents and wear. Geometry should be reserved for anything that changes the silhouette or is seen close-up: gun barrels, armour edges, engine bells, sensor arrays, exposed frames. The Sins II triangle targets show this trade in practice: a frigate is targeted at ~12,500 tris, a cruiser at ~25,000, and a capital at ~75,000, while the detail that sells scale is baked. [129] [361]

Cost. INFERRED 0.5-1 day to author the texture detail; geometry cost avoided. The normal-map lab quantifies the geometry avoided at 18,432 tris for a small demo surface. [183]

Free tools. Blender, xNormal, Krita/GIMP.

3.7 Planar construction and flattening

The most direct fix for a wavy panel is to make the panel planar again. Blender's Flatten operator takes selected vertices and moves them toward a target plane while preserving their relative positions along the unlocked axes; the plane can be Best Fit, averaged Normal, or View. This is the cleanup pass that turns a wavy AI surface into a construction plane that can accept a bevel, a trim and a normal bake. [364]

Planar construction is not just a cleanup; it is a modelling rule. If a hull surface is meant to be flat, build it flat and keep it flat. Curves should be deliberate faired curves, not slow noise. This is the difference between “clean shell with flat planes where the hull should be flat and faired curves elsewhere” (variant 2 in #111) and “the AI mesh with more triangles.”

Cost. INFERRED 0.5-1 day for a cleanup pass on a hero hull. Often reduces triangles, because flat surfaces need fewer vertices.

Free tools. Blender Flatten, Decimate Planar, Shrinkwrap for projected details.

3.8 The 2D sprite alternative (Starsector)

Starsector is the outlier in the source set: its ships are 2D painted sprites, not 3D meshes. The developer's art blog documents “drawing a ship sprite” and notes that the methods have changed since the early days. The modding wiki describes Starsector sprites as tiny paintings, with painting techniques doing most of the work and pixel art used only to bring out fine details. Modders kitbash bits of existing sprites over an outline to get detail and shading. [153] [245]

This is a genuine alternative approach to meshing, and it is worth naming because Ryan asked for alternatives. It eliminates mesh waves by eliminating the mesh. But it does not survive close-up 3D inspection and cannot be rotated freely. For Pyre-Barge, the realistic use is not “replace the 3D ship with a sprite”; it is “use the sprite discipline as a LOD/impostor or as a texture-only detail target at RTS distance.” INFERRED.

Cost. INFERRED 1-3 days per sprite. 0 3D triangles; the cost is in the painted sprite.

Free tools. Krita, Aseprite, GIMP, Inkscape.

4. Studio evidence by game

Sins of a Solar Empire II  -  the strongest technical evidence

The Martin Danlos ArtStation breakdown shows the production triangle: high-poly modelling, low-poly baked mesh with AO and normal, and the low-poly wireframe. The companion in-game breakdown lists high-poly modelling, low-poly modelling, UV layout and PBR texturing as the artist's contribution. [76] [77]

The Sins II dev journal is the most useful public description of the actual bake pipeline. It describes quad topology, holding edges, bevel/chamfer, subdivision to a high-poly, alignment of low and high, UV padding for mips, and a bake that transfers the high-poly detail down. The published triangle targets give a concrete budget: 12,500 for a frigate, 25,000 for a cruiser, 75,000 for a capital, 225,000 for a titan. [361] [374]

The original Sins art dump adds the scale insight: high-resolution model baked to game resolution with xNormal, normal map and AO, 2048×4096 textures, and “a lot of small details to sell the idea that these ships are huge”. [129]

What this confirms for #111: variant 2 is the closest to a shipped RTS pipeline. Clean low shell + authored or donor high-poly + bake is exactly how Sins II gets crisp ships at RTS distance without carrying sculpt triangles.

Battlefleet Gothic: Armada 2  -  sculpt, retopo, bake

The BFG Armada 2 artist breakdown for the Tyranid Destroyer Vanguard states: sculpted in ZBrush, retopology in TopoGun, UV mapping in 3ds Max, based on the Warhammer 40k tabletop figurines and the concept art of a colleague. [10]

What this confirms for #111: even a highly detailed, miniature-derived ship is shipped as a retopologised low-poly with baked detail, not as a dense sculpt. The lesson applies directly to cleaning up AI chunks: sculpt-like detail is a bake source, not a shipping mesh.

Stellaris  -  concept discipline and a shared ship-set language

The Stellaris art diary describes the front end of the pipeline in detail: theme, reference gathering from architecture and objects, wide sketching, narrowing to a direction, then developing the style and producing an asset sheet for the 3D artist with material assignments. The diary for the Nomads art set notes 682 days of art creation for 187 workdays, and three ship categories with distinct visual identities. [11] [204]

The Stellaris sources are weaker on modelling method than Sins or BFG; they are strongest on design consistency and the handoff from concept to 3D. INFERRED: the asset-sheet handoff is a production control that prevents the 3D artist from inventing surface noise, because the material and detail zones are decided before modelling.

EVE Online  -  complete per-ship redesign around a new shader

The EVE V3 project was a complete graphical redesign of every ship, station and object, with every object model upgraded to a new shader. The official Tech3 art post describes the process as sketches → blockout models → paintovers → finished assets. The Art of Retribution redesign discussion describes overhauling iconic hulls “without changing too much in terms of the overall silhouette”. [142] [404] [421]

What this confirms for #111: EVE treats the silhouette as the identity anchor and does the detail work inside that silhouette. For a Pyre-Barge variant, the clean shell should preserve the donor silhouette and masses, then add detail. That is exactly variant 2's brief.

Homeworld 3  -  detail that reads at distance, and damage as surface history

Homeworld 3's team describes ships as the characters of the game, and the technical art director describes exposing the ship's guts when it takes damage plus a weapon-scarring system that leaves permanent marks on the hull, with each weapon type having a specific scarring-capable element. This is strong evidence that surface detail at RTS distance is about readable history and function, not about raw triangle density. [80]

The source is weaker on modelling method; it does not describe the high-to-low pipeline. INFERRED: the scarring system implies a modular surface with distinct material zones and decal/normal layers, because per-weapon scarring needs to be applied selectively rather than baked into one unique texture.

Starsector  -  the 2D control case

Starsector's ships are painted 2D sprites, and the developer's blog documents the sprite-drawing process. The modding guidance describes sprites as tiny paintings and recommends kitbashing bits of existing sprites for detail. [153] [245]

What this confirms for #111: there is a legitimate non-3D approach that completely avoids mesh waves. It is not a drop-in replacement for a 3D Pyre-Barge, but it is a useful fallback for distant LODs and a useful reminder that readability at RTS distance is a texture/paint problem as much as a geometry problem.

5. Cleaning up AI-generated meshes in production

This section is partly sourced and partly INFERRED from the bake and hard-surface sources. The exact phrase “AI mesh cleanup” is not in the sources; the production logic is.

5.1 Do not treat the AI mesh as the shipping surface

The AI mesh is a donor of detail and masses, not a valid low-poly. The Sins II journal's rule applies: the low-poly must have clean quad topology and holding edges before subdivision, and the low and high must be aligned before baking. An AI mesh with slow waves fails both tests: its topology is not authored for holding edges, and its low-frequency form is wrong. INFERRED. [374]

5.2 Build a clean low shell first

Use the AI mesh as reference for silhouette and mass placement, then build a clean low shell with flat planes where the hull should be flat and faired curves elsewhere. Flatten the wavy panels with Blender's Flatten operator. Add holding edges and bevels where the silhouette needs to read. Use Weighted Normal / Harden Normals to keep the flat faces flat and the bevel highlights tight. [316] [364] [365]

5.3 Use the AI mesh only as a bake source

Once the clean shell exists, bake the AI mesh's high-frequency detail onto it. Use Selected to Active with a cage so the rays start from a controlled ballooned low-poly and do not skew on edges. Keep the low-poly triangulated for the bake and reduce the tri count where the detail does not need geometry. [318] [374]

5.4 High-pass or cavity-only so the waves do not transfer

A normal bake records the surface angle difference between high and low. If the AI mesh has a slow wave, that wave is part of the angle difference and will transfer unless you filter it out. The fix is to bake only the high-frequency component:

Cavity/edge-only bake: a pass that outputs a greyscale map of cavities or edge locations, or a normal map containing only the beveled areas, by construction excludes broad height changes. Use this for panel seams, recessed vents and edge wear. [42]

High-pass bake: a high-pass filter attenuates frequencies below a cutoff and passes the higher frequencies; in image filtering, low-frequency coefficients are excluded. Applied to a normal/height bake, this keeps the small detail and rejects the slow wave. INFERRED for the exact Blender node setup; the principle is sourced. [319] [322]

Bevel normal pass: a normal map containing only the beveled areas is a practical way to get crisp edge highlights without transferring the donor's broad form. [42]

Prove it with a before/after crop of a wavy panel, as #111 requires: same lighting, same camera, one crop with the raw bake and one with the high-pass/cavity-only bake. If the wave is still visible in the silhouette or the grazing-angle shading, the bake did not solve the problem; the low shell is still wavy.

5.5 Planar flattening

Flatten is the direct geometry fix. Select the wavy panel, choose a Best Fit or averaged Normal plane, and pull the vertices to it. Do this before the bevel and before the bake. A planar panel with a good trim and a clean normal bake will read better than a dense wavy panel at every distance. [364]

5.6 Weighted normals

Weighted normals fix the shading of the cleaned surface. The modifier changes custom normals to make faces appear flat and to preserve sharp edges. The practical rule from the Polycount thread is to set the smooth angle appropriately and either mark few sharp edges manually or keep every edge beveled; otherwise the “smooth by angle” modifier makes the bevels sharp again. [30] [365]

5.7 Trim sheets, decals, greeble kits, part splitting

These are the detail layers that go on top of the clean shell:

Trim sheets carry repeated panel lines, seams, bolts and worn edges across the fleet, with no extra triangles. [47]

Decals carry stencils, numbers, hazard marks and rust streaks; hard-edged decals use alpha test. [170]

Greeble kits carry vents, pipes, hatches and mechanical clutter that imply function and scale. [143]

Part splitting keeps the hull from being one continuous surface, so each panel can be planar or deliberately curved. [90]

5.8 Cut out the good AI chunks and re-seat them

For variant 3, select the AI chunks that actually read well  -  a complex engine housing, a gun mount, a sensor array  -  clean them, retopologise if needed, and seat them on the clean shell with visible mounts. This is kitbashing with the AI mesh as the donor kit. Keep the donor chunk as a separate part so it can be baked or kept as geometry depending on distance. [144]

6. Ranked recommendation for the Pyre-Barge round 2 (#111)

Rank 1  -  Variant 2: clean shell + high-pass/cavity-only bake from the AI donor

Why first. It is the closest to the shipped Sins II pipeline, it directly targets the wave problem, and it preserves the AI detail that is worth keeping. The clean low shell fixes the silhouette and the planar surfaces; the bake transfers the small detail; the high-pass/cavity-only step is the explicit mechanism that stops the low-frequency wave from coming across. The normal-map lab shows why this is the right trade: texture detail is cheap and nearly identical head-on, and only the silhouette needs real geometry. [183]

What it costs. INFERRED 3-7 days per hull for the clean shell and bake. Low-poly target 25k-75k for a cruiser/capital; the AI high-poly is discarded. [361]

What to watch. The clean shell must be genuinely clean. If the low-poly still has the wave, the bake will faithfully transfer the wave's small-scale roughness and the silhouette will still be wrong. The before/after crop of a wavy panel is the acceptance test.

Rank 2  -  Variant 1: A+ clean kit shapes + bevels + panel lines + greeble kit + decals + wear

Why second. It is the highest-control option and the best close-up option. Part splitting, bevels, weighted normals, trim sheets and greebles are all sourced production methods. It also gives the strongest silhouette because the detail is real geometry where it matters. But it is the most expensive per hull, and it does not exploit the AI donor at all. It is the right choice for a hero ship or a close-up variant, not the cheapest way to fix three variants. [47] [90]

What it costs. INFERRED 3-6 days per hull for the kitbash/bevel/greeble pass, plus texture time. Triangle cost can be kept at the Sins capital target of 75k if kit parts are reused and merged. [361]

Rank 3  -  Variant 3: clean hull + reused AI chunks as kit parts

Why third. It is a sensible middle path, and it follows the kitbash/greeble logic. The risk is that cut-out AI chunks carry their own wavy surfaces and do not match the clean shell's scale or topology. It works best when the chunks are small, hard-edged and mounted on visible hardpoints, not when large hull sections are reused. Treat it as a detail-source variant, not a hull-construction variant. [143] [144]

What it costs. INFERRED 2-4 days per hull for cutting, cleaning, retopologising and seating the chunks. Triangle cost depends on how many chunks are kept as geometry; bake the rest.

Alternative worth keeping on the table  -  2D sprite / painted LOD

Starsector proves that a painted 2D ship can be highly readable at RTS distance and completely avoids mesh waves. It is not a replacement for a 3D Pyre-Barge, but it is a legitimate alternative for distant LODs or for a “concept paint” read. INFERRED: if the RTS camera spends most of its time at a distance where the ship is a few hundred pixels tall, a painted impostor may beat a 3D hull on both cost and cleanliness. [153] [245]

Alternative explicitly rejected  -  “more triangles to smooth out the waves”

This is not a variant. It does not fix the low-frequency displacement; it increases the resolution of the displacement. The normal-map lab's silhouette test and the bake principle both show why: the wave is in the geometry, and neither more triangles nor a normal map moves the geometry back to flat. Adding detail can mask the wave at distance in a still frame, but it will not survive a grazing angle or a close-up. [183]

7. What this changes or confirms for #111

Confirms that variant 2 is the correct primary comparison. It matches the Sins II high-to-low bake pipeline and directly addresses the wave problem.

Confirms that variant 1 should be the close-up/hero comparison, not the mass-production solution. Its strength is silhouette and real geometry; its cost is artist time.

Changes the framing of variant 3: it should be treated as a kitbash/detail-source variant, not as a hull-construction variant. Reused AI chunks are only safe when they are small, cleaned and mounted.

Changes the “more triangles” idea from a possible fix to a non-fix. The correct use of extra triangles is to support bevels, holding edges and silhouette geometry, not to subdivide a wave.

Adds a concrete acceptance test: a before/after crop of a wavy panel, with the high-pass/cavity-only bake, viewed at a grazing angle as well as head-on. If the silhouette is still wavy, the fix failed.

8. Limits and INFERRED register

No studio publishes per-hull artist hours. All time figures are INFERRED from the scope of the cited workflows and should be treated as planning ranges, not quotes.

The exact Blender node setup for a high-pass normal bake is INFERRED. The principle (high-pass attenuates low frequencies; cavity/edge passes exclude broad height) is sourced. [42] [319] [322]

The claim that AI meshes specifically carry low-frequency waves is INFERRED from the behaviour of normal bakes and the geometry of the problem; the sources describe the bake behaviour, not the AI generator.

The Starsector 2D sprite workflow is sourced, but applying it as a LOD/impostor strategy for a 3D RTS is INFERRED.

Homeworld 3 and Stellaris are weaker on modelling method than Sins, BFG and EVE. They are used for intent and readability, not for a step-by-step pipeline.

Marmoset is not recommended. A useful hard-surface tutorial exists there, but the issue says free tools only; Blender, xNormal, Krita, GIMP and Inkscape cover every method in this leg.

9. Sources

Martin Danlos, Sins of a Solar Empire II - Spaceship Assets (Technical Breakdown), ArtStation: https://martindanlos.artstation.com/projects/0lGmg8 [76]

Martin Danlos, Sins of a Solar Empire II - Spaceships (In-Game), ArtStation: https://martindanlos.artstation.com/projects/AZ8DRX [77]

Sins II: Dev Journal 21 - Baking with Set, Stardock Confluence export: https://stardock.atlassian.net/wiki/exportword?pageId=2162065455 [374]

Sins of a Solar Empire II/Modding, StrategyWiki (mesh triangle targets): https://strategywiki.org/wiki/Sins_of_a_Solar_Empire_II/Modding [361]

Sins of a Solar Empire (intro and art dump), Polycount: https://polycount.com/discussion/97344/sins-of-a-solar-empire-intro-and-art-dump [129]

Spaceship, Hardsurface, subdivision polymodeling learning and help, Polycount: https://polycount.com/discussion/169587/spaceship-hardsurface-subdivision-polymodeling-learning-and-help [90]

Blender Weighted Normals, Polycount: https://polycount.com/discussion/238110/blender-weighted-normals [30]

Battlefleet Gothic Armada 2 - Tyranid Destroyer Vanguard, Ségolène Maurice, ArtStation: https://sgln_maurice.artstation.com/projects/k4Gr16 [10]

Stellaris Dev Diary #186: Necroid Ships & the Art process, Steam: https://store.steampowered.com/news/app/281990/view/2858054954391944551 [204]

Stellaris Dev Diary #426 - The Art of Stellaris: Nomads, Steam: https://store.steampowered.com/news/app/281990/view/689761349249532332 [11]

EVE Evolved: The great ship overhaul, Engadget: https://www.engadget.com/2012-06-24-eve-evolved-the-great-ship-overhaul.html [142]

Art - Tech3 and the Renovated Effects, EVE Online: https://www.eveonline.com/news/view/art-tech3-and-the-renovated-effects [421]

[Devblog] The Art Of Retribution, Failheap Challenge mirror: https://failheap-challenge.com/showthread.php?12345-Devblog-The-Art-Of-Retribution [404]

Inside Homeworld 3, PC Gamer: https://www.pcgamer.com/inside-homeworld-3-how-blackbird-interactive-aims-to-make-you-feel-attached-to-your-fleet-as-you-see-the-history-of-battles-through-the-whole-campaign/ [80]

Starsector - Let Me Draw You A Starsector Ship, Part 1, Fractal Softworks: https://fractalsoftworks.com/2014/05/16/let-me-draw-you-a-starsector-ship/ [153]

Starsector - Intro to Modding, Starsector Wiki: https://starsector.wiki.gg/wiki/Intro_to_Modding [245]

Greeble, Wikipedia: https://en.wikipedia.org/wiki/Greeble [143]

Kitbashing, Wikipedia: https://en.wikipedia.org/wiki/Kitbash [144]

How to Model & Texture a Gloomy Ironclad Workshop Scene (trim sheets), 80.lv: https://80.lv/articles/how-to-model-texture-a-gloomy-ironclad-workshop-scene [47]

Modeling Vehicles for AAA Games (decals, poly budget), 80.lv: https://80.lv/articles/modeling-vehicles-for-aaa-games/ [321]

Decal, Polycount Wiki: https://wiki.polycount.com/wiki/Decal [170]

Normal mapping lab, University of the Witwatersrand: https://lamp.ms.wits.ac.za/~alex/normalmapping/ [183]

High-pass filter, Wikipedia: https://en.wikipedia.org/wiki/High-pass_filter [319]

Optimized OpenCL kernels for frequency domain image high-boost filters, Springer (search snippet): https://rd.springer.com/article/10.1007/s42452-019-1354-2 [322]

Render Baking, Blender Manual: https://docs.blender.org/manual/en/latest/render/cycles/baking.html [318]

Bevel Modifier, Blender Manual: https://docs.blender.org/manual/en/latest/modeling/modifiers/generate/bevel.html [316]

Subdivision Surface Modifier, Blender Manual: https://docs.blender.org/manual/en/latest/modeling/modifiers/generate/subdivision_surface.html [317]

Weighted Normal Modifier, Blender Manual: https://docs.blender.org/manual/en/latest/modeling/modifiers/normals/weighted_normal.html [365]

Flatten, Blender Manual: https://docs.blender.org/manual/en/latest/modeling/meshes/editing/mesh/transform/flatten.html [364]

Bake Passes, Bake Wrangler documentation (method reference only; not a recommended paid tool): https://bake-wrangler.readthedocs.io/en/latest/bake_passes.html [42]

Texture Baking, Polycount Wiki (search snippet): https://wiki.polycount.com/wiki/Texture_Baking [227]

Trim Sheets, Polycount discussion (search snippet): https://polycount.com/discussion/comment/1561334 [116]
