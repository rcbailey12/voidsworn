# Ship pipeline research: how fleet games build ships, and how we fix ours (board issue 76)

Chair synthesis of four legs (Rey blind leg, DeepSeek, Qwen, Argon), grounded in the issue 76 evidence pack. FINDINGS rulings override every other doc. The pack's verified file:line facts win for code state. The Argon leg was used selectively and the Qwen leg was largely screened out; both screenings are documented in their own sections below, and nothing in this pack rests on either leg alone.

## Verdict and recommendation

GO WITH CONDITIONS.

The one condition: the flagship split inside Route C is confirmed against the issue 75 bake-off pictures when they land. Issue 75 is blocked and has produced no pictures, timings, or frame costs yet, so that confirmation cannot happen today. Everything else in this pack is actionable now.

The recommendation is Route C, a tiered hybrid, in the merged shape the legs converge on:

1. A universal foundation for all 36 hulls (section 4.1).
2. A machine branch for the 30 machine meshes: automated planar cage cleanup plus 5 shared faction kit libraries (section 4.2).
3. SHELL=1 lofted shells reserved for flagships and for bows that fail the blob sweep gate after planar cleanup (section 4.3).
4. A Chorus bio branch for the 6 organic meshes (section 4.4).

Route C is priced three different ways by the three usable legs, and the spread is real. Section 7 presents all three pricings with their units and assumptions side by side. There is no measured per-hull number for any route, and this pack does not invent one.

## 1. The problem, and what is already settled

The owner's complaint (Nov 2, 2026, after a 4K Godot playtest, screenshots ryan_c01 to ryan_c08): random waviness and bumpiness on ships, a weird grid texture, and odd painting, on most hulls. The four defects are the fixed target list for this pack:

- (a) Waviness: low frequency surface undulation from the generator.
- (b) Bumps: high frequency surface noise.
- (c) Grid like texture: a regular panel or projection pattern.
- (d) Odd paint: projected concept art carrying its own lighting and layout into the albedo.

Fleet scope, verified in the pack (section 3.1): 36 hull meshes, not the 28 the issue text claims. That is 30 faction capital hulls (Hegemony 5, Crusade 6, Hullbreakers 5, Chorus 5, Glasswrights 5, Eclipse 4), 3 squadron craft (fighter S1_51, bomber S2_23, spore B23_51), and 3 objective structures (station O1_37, transport O2_37, beacon O3_11). By surface family: 30 machine meshes (25 machine capitals, 2 machine craft, 3 structures) and 6 organic Chorus meshes (5 capitals plus the spore). Only one hull, C19_51 (the Warlord's Pyre-Barge), has completed the current pipeline end to end; its shape and paint steps are approved (R13, R14) and its final sign-off is still withheld (R16).

Settled technical points. These are the pack's position, not open questions:

- Route 0, keep polishing the current chain, is dead. It was proven by the Nov 1 repaint of all 36 hulls (G-14, commit fc9b347): the complaint postdates that repaint. More paint passes on the same meshes are a proven non-fix.
- Kit parts are the AI mesh fix, not decoration (contrib/muse/design/tool_guides.md line 21). The AI hull supplies the big form, shared kit parts supply the readable turrets, engines, radiators and sensors, and the bake makes it read dense. Any route that keeps the AI mesh's melted turret and engine blobs and only repaints them leaves a core defect in place.
- The grid texture's cause is twofold: the runtime box projection that decodeAIHull generates for hulls without atlas UVs, at about three panels per hull length (ships3d.js:753), plus diffusion panel grids carried in the projected concept paint. Both are regular patterns imposed on the hull rather than authored on it.
- The odd paint's cause is projected concept albedo (pipeline README step 4 and 5, ships3d.js:932). A concept painting is a lit illustration; projecting it bakes contradictory light, painterly noise and one camera's layout into the colour map, and a PBR renderer then lights it a second time. That is why ryan_c01 reads as mottled camouflage instead of a faction paint scheme.
- Waviness is only removed by planar collapse plus weighted normals, or by a lofted shell. Voxel remesh alone reduces it: a remesh fine enough to keep the ship's features follows the low frequency wave. Any route that bakes normals from the raw AI mesh re-imports both the waviness and the bumps into the normal map, whatever the geometry pass did. Raw AI normal baking is therefore banned in every route this pack recommends.

## 2. What the shipped games do, and how well it is sourced

Sourcing honesty first, because the legs differ sharply here. Only one of the five named games has a fully published ship pipeline: Sins of a Solar Empire 2. Homeworld 3's texture system is documented in its public modding guide. Battlefleet Gothic: Armada has one documented organic route and a thin record otherwise. Battlestar Galactica Deadlock has a documented production split and little else public. Starsector is 2D and is contrast only. Where a leg states per-game production specifics beyond these sources, this section does not adopt them; see the Argon screening section.

### 2.1 Sins of a Solar Empire 2 (fully published: Dev Journal 21)

Primary 3D artist Paul Kiesling (Set), in Sins II Dev Journal 21, "Baking with Set" (Stardock, 2024), documents the whole route:

- Modelling: hand built hard surface in clean quad topology that follows the silhouette in smooth sweeping curves, minimal triangles, n-gons discouraged. The high poly is made from the same model: holding edges are selected, a chamfer or bevel modifier creates a 45 degree face, and the mesh is subdivided. Bevel size is kept consistent across ships for consistency.
- UVs: unique unwrap per ship, islands straightened and oriented horizontally or vertically, 70 to 80 percent minimum use of the 0 to 1 space, padding and margin rules tied to texture size and mip level (at 1k, margin 4 and padding 8; at 2k, 8 and 16; at 4k, 16 and 16).
- Bake: high to low in Marmoset Toolbag at 4k, 64 samples, 16 bit, MikkT tangent space, baking normal, curvature and AO. Mesh normals use weighted normals, under the rule that not all seams have to be sharps, but all sharps have to be seams.
- Texturing: Substance Painter with the baked normal, curvature and AO loaded in; panel lines and edge wear come from modelled bevels caught by the bake, curvature driven wear, and AO in crevices. None of it comes from a projected painting.
- Distance: the bevel and bake effort exists to give the low poly the appearance of a higher triangle count at normal viewing distance, and mip padding discipline is treated as part of art quality, because capital ships un-render before hitting a mip level where padding bleed becomes troublesome.
- Economics: the journal is written by the team's primary 3D artist, singular, supplemented by outsource artists doing full high poly, low poly, UV and PBR passes per ship (contractor portfolios). No per-ship day count is published. The Rey and DeepSeek legs both infer, and the chair accepts as inference only, that this route is specialist work measured in days per capital ship. It is the correct order of operations to copy; it is not a per-hull method a one person project can run 30 times.

Sources: https://stardock.atlassian.net/wiki/spaces/SSEFW/pages/2162065455/Sins+II+Dev+Journal+21+-+Baking+with+Set ; contractor breakdowns at https://martindanlos.artstation.com/projects/AZ8DRX and https://martindanlos.artstation.com/projects/0lGmg8

### 2.2 Homeworld 3 (texture system documented in the public modding guide)

The public modding guide ("Modding: Advanced Ship Creation", mod.io) documents the shipped asset format: three UV channels per ship (UVMap0 for standard textures and mirroring, UVMap1 for badge projection, UVMap2 non-mirrored for team colour and SPLAT damage), plus separate Base Color, Emissive, Normal, ARM (AO, roughness, metallic, height), MASK and TEAM maps. The mask channels (Dust and Dirt, Engine Mask, Panel Mask, Team Color) show panel lines and wear authored as masks and materials, not painted into one albedo. That mask driven, multi-channel setup is the documented part, and it is the part that transfers to us.

Design process is documented in interview, modelling mechanics are not. Art director Karl Gryc describes iterative shape work ("shape tuning") on whole hulls, a fleet coherence test (a finished ship should sit next to the Mothership and read as the same fleet), and class coded striping as graphic identity: two stripes for a Torpedo class, one for an Assault Frigate, applied so a player can tell what kind of ship is attacking at a glance (Windows Central interview, 2024). Reuse is documented at whole ship level: a superseded Carrier design was reused as a pirate ship. INFERRED (both usable legs agree): the tactical read is carried by shape, striping, large simple paint shapes and weapon effects, not by fine surface texture.

Sources: https://www.windowscentral.com/gaming/pc-gaming/homeworld-3-art-director-discusses-redesigning-spacecraft-for-a-pc-rts ; mod.io, "Modding: Advanced Ship Creation".

### 2.3 Battlefleet Gothic: Armada (one documented route; the rest partly inferred)

Documented: the ships are recreations of the physical tabletop miniatures, kept as close to the source models as the real time format allowed (game director Romain Clavier, Game Developer, "Maxing out miniatures"). For the Tyranid faction, artist Segolene Maurice records a sculpt first route: ZBrush sculpt, retopology in TopoGun, UV mapping in 3ds Max, based on the miniatures and in-house concept art, with a separate in-game shader made by another artist (40k.gallery, "Destroyer Vanguard"). That sculpt, retopo, UV route is the documented Battlefleet Gothic pipeline, and it is an organic route; it is cited in section 5 for the Chorus branch.

INFERRED, and labelled as such wherever it appears: Imperial kitbash specifics. The Rey leg infers unique hero builds per class sharing an architectural language rather than shared meshes, because the brief was fidelity to a specific miniature per class. The DeepSeek leg infers reuse of gothic trim and turret families across classes, because the tabletop range itself reuses them. The legs disagree on the ratio and neither has a production source for it. The chair position: no claim about Imperial part sharing is load-bearing in this pack. What is documented and load-bearing is the fidelity brief and the Tyranid organic route.

Also documented and relevant: Armada deliberately spends on close zoom detail ("rendered in obsessive detail", players can "zoom way down", Game Developer, same source), because its camera lingers on a few large ships. That spend is a camera decision, not a fleet method, and it does not transfer to a 20 ship tactical camera at about 170 units.

Sources: https://www.gamedeveloper.com/design/maxing-out-miniatures-making-a-successful-tabletop-adaptation ; 40k.gallery, "Destroyer Vanguard".

### 2.4 Battlestar Galactica Deadlock (documented split; material specifics inferred)

Documented: Forge Studios handled high poly modeling, low poly and baking for many Deadlock spaceships, with final texture done by Black Lab Games artists (Forge Studios, ArtStation). The in-house credits show a single credited 3D Artist plus an Art Director and a Concept Artist (MobyGames credits), and the ships mix faithful recreations of the show's ships with invented classes approved by NBC Universal (Polygon, 2017). The documented economics lesson is the split itself: a small team buys high poly and bake capacity outside and keeps final material control in house.

INFERRED, labelled as such: Deadlock's material specifics. The DeepSeek leg infers tileable armour plates and decal like insignia from the show's panel heavy hulls and the tactical camera. No public trim sheet, UV or decal breakdown exists, and this pack makes no factual claim about Deadlock texturing. Deadlock is also weak evidence for detail budget: its battles are small and turn based with a cinematic replay the player can orbit, which justifies more per hull surface detail than our camera does.

Sources: Forge Studios, forgestudios.artstation.com ; https://www.mobygames.com/game/95476/battlestar-galactica-deadlock/credits/windows/ ; https://www.polygon.com/2017/6/28/15887180/battlestar-galactica-deadlock-ps4-pc-xbox-one-price-release-date

### 2.5 Starsector (2D contrast only)

Starsector is hand painted 2D sprite art by one artist, David Baumgart, in a two person team. Its house rules are documented: sprites are tiny paintings, not pixel art, with no black outlines, and a new ship's pixel mass is matched to its size class so it carries the same visual weight as its peers (Starsector wiki, Intro to Modding). There is no mesh, UV or bake pipeline, and nothing in its production method transfers directly.

What transfers is read discipline: because a sprite cannot rely on lighting, normals or parallax, the entire tactical read sits in silhouette, value contrast and colour blocking, and the game stays readable fully zoomed out. That is evidence that a fleet reads well with zero surface micro detail if those three are strong, and it is the argument for spending our limited hours on fair silhouettes and value blocking before panel detail. Its other transferable principle is strictness: a short list of fleet wide style rules, enforced on every hull, is what keeps a fleet coherent when there is no art department.

Sources: https://starsector.fandom.com/wiki/Intro_to_Modding ; Fractal Softworks blog, "Let Me Draw You A Starsector Ship" and "Zen and the Art of Battlestation Construction".

### 2.6 What the five games agree on

1. No named game builds fleet ships by projecting concept paintings onto generated meshes. Where the method is documented, albedo is built in a PBR texturing step after a bake, from baked normal, curvature and AO maps.
2. Where readability is discussed, it is carried by shape, silhouette, large paint shapes and effects, never by fine texture detail.
3. Where team size is visible, ship art is one or two core people plus overflow help. Consistency comes from shared process and shared rules, not hero effort per hull.
4. Close zoom surface richness is a deliberate spend tied to cameras that linger on a few ships. It is not evidence that a 20 ship tactical camera needs it on every hull.

## 3. The cleanup pipeline the routes share

The standard small team route from an AI generated or photogrammetry mesh to a clean game asset, in run order. AI generation and photogrammetry fail the same way for the same reason: a dense, irregular, non manifold surface with no designed topology, no designed UVs, and colour with light baked into it. Published scan to asset workflows prescribe the same hybrid order the legs converge on: keep the messy source as the detail reference, build a clean mesh over it, bake detail from high to low.

1. Freeze and repair. Keep the raw AI mesh untouched as reference (the owner approves silhouette first, and the raw mesh is the only record of it). Apply transforms, merge by distance, delete loose geometry and floating shells, fill small holes, recalculate normals, make the mesh manifold. Repair is a precondition: Blender's Quadriflow remesher needs a closed manifold surface and rejects typical generator output.
2. Voxel remesh to a watertight volume. Blender's voxel remesher (OpenVDB) rebuilds the surface with even topology and no self intersections. Voxel size is a filtering decision: a size near the wavelength of the high frequency noise removes that noise and also removes real small detail. Voxel remesh rebuilds topology; it does not fair a surface. Low frequency waviness survives any voxel size fine enough to keep the ship's features, which is why step 3 exists.
3. Fair the form. This is the step that removes waviness, and the step generic cleanup guides skip. Machine hulls: planar collapse (section 4.2). Failed regions and flagships: section fairing and lofting (section 4.3). Skipping fairing and baking the raw mesh is the most common cause of a clean looking retopo that still renders wavy, because the bake faithfully transfers the unfair surface.
4. Retopology or decimation to the game mesh. Ships do not deform, so retopology quality matters less than for a character; what matters is even distribution, held sharp edges, and a silhouette that matches the faired form. Our hulls_hi tier already ships at 20k to 38k triangles, and desktop detail is compressed with meshoptimizer, not decimated, with no artificial triangle limits, so targets are quality targets, not savings targets.
5. Authored UVs. Chosen before texturing, never inherited from the generator and never generated at runtime. Either a unique unwrap (straightened islands, consistent texel density, padding matched to texture size and mip behaviour, on the Sins II discipline) or trim and tileable mapping placed deliberately along edges and bands, or the hybrid the routes use. The runtime box projection at ships3d.js:753 is deleted by giving every hull an offline UV0.
6. Bake from a deliberate source, never from the raw AI mesh. Bake normal, AO and curvature from the faired, bevelled version of the clean mesh plus the modelled kit and detail parts (the Sins II method), with a cage that fully encloses the source. A normal map fakes relief; it cannot change the silhouette, so the low poly outline has to be right before baking.
7. Texture from masks, not from a picture of the ship. Base colour comes from FAC3D only. Curvature drives edge wear, AO drives grime in recesses, a material ID or vertex mask separates paint, bare metal, dark machinery and glow. Decals go on last for markings, numbers and faction insignia; Homeworld 3's class striping is the design model for what decals should do.
8. Pack, compress, gate. Export, compress with meshoptimizer into the existing .vsm path where a hull uses it, convert through godot/render/build_assets.gd as today, then run the blob sweep gate (the 9 cell region review: bow, midship, stern from top, side and below) before the hull is shown. Add two cheap automated checks: a flat lit turntable render at tactical distance and at close zoom, and a normals only render. Waviness and bump noise are far easier to see in those than in a painted beauty shot.

Where teams cut corners at a tactical camera: bake at the resolution the furthest common view needs with padding enforced for mips; put triangles into silhouette and skip interior and underside detail the camera rarely sees; reuse one material set and a handful of decals across a faction instead of authoring unique wear per hull; and do not hand retopologise rigid hulls, because automatic retopology is sufficient for non deforming assets and manual work is reserved for hero assets.

Principal tool sources: Blender Manual, Remesh and Retopology (https://docs.blender.org/manual/en/latest/modeling/meshes/retopology.html); StraySpark, MeshPrep devlog and AI cleanup guides (https://www.strayspark.studio/blog/introducing-meshprep-blender-ai-scan-mesh-cleanup), which names TRELLIS and Hunyuan3D exports as sources its analysis step recognises; Sins II Dev Journal 21 for bake discipline.

## 4. Route C in full

### 4.1 The universal foundation (all 36 hulls)

- Delete projected concept paint as albedo. Concept paintings retire to reference only: palette sampling, marking placement ideas, silhouette approval. This deletion, not an improvement to the projection step, is what removes the odd paint defect.
- Delete the runtime box projected UVs. Every hull ships an offline UV0, so the ships3d.js:753 fallback never runs. This is what removes the projection half of the grid defect.
- Never bake normals from the raw AI mesh. Bakes come from the faired clean mesh plus modelled detail, per step 6 above. This is what stops the waviness and the bumps being re-imported after the geometry pass removed them.
- FAC3D (ships3d.js:2) stays the single colour source on every hull. Baked maps are masks only: AO, curvature, thickness and wear or grime masks. No route in this pack authors colour outside FAC3D.
- The procedural paint grain layer is replaced by mask driven detail: grain only inside panel boundaries, wear only on curvature convex edges, grime only in AO recesses. Uniform procedural noise applied everywhere is the bump defect wearing a texture's clothes.

### 4.2 The machine branch (30 machine meshes)

Automated planar cage cleanup, scripted in headless Blender and run per hull:

1. Audit and landmark extraction: record bounding dimensions and ray cast the procedural landmark coordinates the game still uses (ships3d.js:840-841: muzzles, hard points, engine glows, bays).
2. Excise melted AI mounts: around every turret and engine landmark, cut away the AI mesh's blobby turret bumps and side gun boxes so clean mounting pads remain.
3. Voxel remesh to a watertight manifold, then Laplacian smoothing to strip high frequency bumps while holding macro form.
4. Planar decimation: collapse triangles that lie within a small angle of each other into single flat plates. This planar collapse, with weighted normals, is the step that removes waviness on machine hulls: it replaces an undulating triangle field with dead flat facets that shade flat up to their bevel seams.
5. Weighted normals (keep sharp, face influence), then a bevel shader bake so plate seams get crisp chamfered normal edges without modelled bevel geometry everywhere.
6. Offline UV0 unwrap and pack; bake AO and curvature from the cleaned cage plus kit, never from the raw mesh.

On top of the cage, 5 shared faction kit libraries, one per machine faction (Hegemony, Crusade, Hullbreakers, Glasswrights, Eclipse), replace the melted AI mounts: a small set of clean bevelled parts per faction (primary turret, secondary turret, engine bank, radiator array, sensor array, prow fitting), snapped onto the ships3d.js landmark sockets with the existing BVH ray cast placer pattern (tools/blender/hs/, worked example c19_kit.py), in matched symmetric pairs, guns aimed forward or out to the side, never backward. Hullbreakers are the junk exception under the ship rules, as today. This is the scaling move the whole recommendation turns on: C19_51 proved a bespoke per hull kit works and proved it does not repeat (SHIP_QUEUE.md marks every other hull not started); shared libraries give every machine hull the kit fix without 30 bespoke kit scripts. Kit parts are mapped to a shared faction trim sheet, designed before hull work begins, because re-laying UVs later is the most expensive rework in a trim workflow.

### 4.3 SHELL=1 lofted shells (flagships and failed bows only)

The clean shell option already in the pipeline (README step 5): measure cross sections off the wavy AI hull, loft a fresh faired shell through smoothed sections, demote the AI mesh to a measuring guide, then kit and paint on the shell. It is the most reliable waviness fix that exists in our own tooling, and the most expensive per hull, so Route C reserves it for:

- The 5 machine faction flagships, one per machine faction. C19_51, the Crusade flagship, is already built this way and keeps its approved shape and paint steps; it gets its further graphical upgrade here, which is what R16 asks for.
- Any individual bow that fails the 9 cell blob sweep gate after planar cleanup. The gate, not a guess, decides which bows join the loft list.

The flagship list is confirmed against the issue 75 bake-off pictures when they land; that is the verdict's one condition (see section 8 and the Dissents).

### 4.4 The Chorus bio branch (6 organic meshes)

The Ninefold Maw's problem is partly a category error, recorded in the pack: machine texture language (panel grids, flat panels, a hexagonal turret like piece, ring fittings) sitting on a creature that must read as flesh, with textures that look like they belong on an actual ship. The bio branch branches off at the start and never rejoins the machine steps:

1. Excise AI machine parts. Cut out the hexagonal turret pieces, flat panels and ring fittings baked into the Chorus meshes; no metal kit part and no detail plate is ever attached to a Chorus hull. Where the game needs a weapon or hard point, it is a grown feature: an organ, a horn, a spine, a sphincter like emitter, never a turret. Chorus ships are living bio ships with no bolt on guns; veins and sacs glow.
2. Shared bio kit growths. One small reusable Chorus bio kit (glowing venom or plasma sacs, puckered maw orifices, ridged chitin prows, gill vents, tendril clusters) snapped to landmarks with the same BVH ray cast math as the machine kits.
3. Fuse by voxel remesh and heavy smoothing. After the growths are placed, voxel remesh fuses them into the body like living tissue, followed by heavy Laplacian and corrective smoothing. No planar decimation and no weighted normals on organic hulls: flat facets are what make flesh read as chiselled rock. Fairing here is sculpting: lumps must have a cause in the anatomy (body mass, limbs or tendrils, a maw, sacs), because random lumps are the organic equivalent of panel noise.
4. Isotropic quad retopology (Quadriflow) with full smooth normals, and an offline UV0 so the box projection never runs on a creature either.
5. Anatomical bake: AO for deep creases, cavity and curvature to separate raised chitin crests from recessed vein channels, and a subsurface thickness bake (Cycles AO node, Inside) measuring how thin or fleshy each region is. The normal map is a clean two zone organic map: smooth taut skin in fleshy zones, subtle longitudinal striations along dorsal ridges.
6. Flesh material from Chorus FAC3D tokens only. Metallic 0.0 across the hull. A wet flesh versus matte chitin roughness split: fleshy membranes, maws and sacs at low roughness (about 0.15 to 0.25) so they catch tight wet specular highlights; raised dorsal carapace at higher roughness (about 0.55 to 0.70) and darker FAC3D values to read as bone and chitin. Subsurface thickness drives translucency so thin fins, maws and sacs transmit warm internal hues instead of shading like opaque stone, Godot 4.7 StandardMaterial3D supports subsurface scattering for this. Emissive veins and sacs are masked into recessed anatomical valleys through the inverted cavity map and across the bio sac domes. Skin colour variation is large, soft mottling at body scale placed by anatomy masks (belly lighter, sacs saturated, scar tissue pale), never the fine uniform grey brown grain that makes the Maw read as rock.

The documented precedent for the organic route is Battlefleet Gothic's Tyranid pipeline (sculpt, retopo, UV, separate shader) and standard creature practice (sculpted detail, skin zones separated by roughness, subsurface in thin areas). Applying that route to an AI generated organic hull is inference from adjacent workflows; no leg found a published postmortem of that exact conversion, and section 11 says so.

## 5. What each route does to the four defects

Route 0, keep polishing the current chain. Waviness: leaves it, geometry untouched. Bumps: leaves or worsens it, each pass adds grain. Grid: leaves it, UV generation unchanged. Odd paint: leaves it, projection retained. Proven by G-14; included only because the pack requires the baseline be stated.

Route A, C19 pattern kitbash rebuild with clean shell loft and trim sheet on every hull. Waviness: removes the cause, the loft replaces the primary surface. Bumps: removes the cause, detail is modelled parts and trim, not noise. Grid: removes it if the trim sheet is designed with varied panel scales; at risk of returning if trim is used lazily at one scale everywhere. Odd paint: removes it, procedural FAC3D paint replaces projection. Does not fit: Chorus organics (a lofted shell plus hard surface kit is the wrong language for a creature and repeats the Maw's category error in cleaner form), and it is wasteful on squadron craft. Its demonstrated throughput is the disqualifier at fleet scale: exactly one hull completed in the project's history.

Route B, voxel remesh, retopo, baked detail, faction PBR in place of projected paint, as scoped in issue 75. Waviness: reduces it only, unless a real fairing step is added; a batch that remeshes and bakes without fairing ships clean topology with the same waves in it, and if the bake source is the raw AI mesh the waves are copied straight back into the normal map. Bumps: removes the cause, provided the bake source is the faired clean mesh and not the raw AI mesh; that condition is a script setting, not a hope. Grid: removes it, authored UVs replace the box projection. Odd paint: removes it, projection deleted. Does not fit: flagships at the owner's ruled quality bar (R16: more realistic and cinematic, Barge sign off still withheld), because Route B makes a good fleet, not a hero ship; and Chorus hulls, because applied mechanically it produces a clean, panel free, still rock like creature. It also leaves melted AI turrets and engine blocks in place, which tool_guides.md line 21 rules out.

Route C, this pack's recommendation. Waviness: removed on flagships and failed bows (lofted shell) and on machine hulls generally (planar collapse plus weighted normals), removed on Chorus hulls by sculpt fairing and heavy smoothing. Bumps: removed on all 36 (bake source changed, voxel remesh plus smoothing, uniform grain deleted). Grid: removed on all 36 (offline UV0 everywhere, non grid detail plates). Odd paint: removed on all 36 (projection deleted, FAC3D through masks). Chorus category error: removed, on the only branch where it exists. Nothing in the fleet is left without a branch; machine escorts will look plainer than flagships at extreme close zoom, which is a deliberate, evidence backed choice (sections 2.2 and 2.5) and is put to the owner as question 1.

## 6. Build order

Automation first, so the fleet price is calibrated by doing, not by estimating:

1. Build the universal foundation: delete projected paint and runtime box UVs from the chain, write the FAC3D mask driven paint solve, the offline UV0 step, and the flat lit plus normals only QA renders.
2. Build clean_machine_cage (audit, excision, voxel remesh, smoothing, planar decimation, weighted normals, bevel bake) and prove it on the Eclipse zenith cruiser, a bake-off hull, so the comparison against issue 75 already exists.
3. Build the 5 shared faction kit libraries and the automated placer; prove on the same cruiser.
4. Build the Chorus bio branch (excision, bio kit, fuse and smooth, anatomical bake, flesh material) and prove it on the Ninefold Maw, the highest risk hull.
5. Run the SHELL=1 loft list: the remaining machine flagships, plus any bow the blob sweep gate fails after step 2.
6. Batch the remaining machine hulls through the cage plus kits, blob sweep as the gate per hull; batch the remaining Chorus hulls through the bio branch.
7. On the first hull through each branch, run the R73 break up recheck and, for kit carrying hulls, a 20 ship frame cost check at 4K on the RTX 5080 under Forward+ before rolling the branch out.

## 7. Effort, honestly

No measured per-hull number exists for any route. Issue 75 owes the first measured numbers and has produced none. The three usable legs price Route C very differently, because their units and automation assumptions differ. All three pricings are stated here with those units and assumptions. They are not averaged, and no total below is a measurement.

Argon leg: about 101 agent hours, plus 11 PC batch hours, plus 12.5 owner review hours, for all 36 hulls. Driving assumption: full automation. Its build prices per hull execution at 0.75 agent tuning hours, 0.3 PC batch hours and 0.35 owner review hours, with the upfront tooling, the 6 kit libraries and the flagship lofts carrying the rest. On the same unit count it prices pure Route A at 210 to 350 agent hours. If the automation works as assumed, this is the floor.

Rey leg: 155 to 325 hours total for Route C, mixing script hours (agent writing and running Blender Python on the owner's PC) and manual hours (a human working in Blender by hand), with manual work at roughly 100 to 230 of those hours. Driving assumptions: a scripted batch does the fleet tier at 1 to 3 manual hours per hull, flagships take 8 to 16 manual hours each on top of the batch pass, and Chorus hulls take 4 to 8 manual hours each, mostly sculpt fairing and flesh paint placement. Up front batch and kit library work is 55 to 95 hours, mostly script time. On its unit count, pure Route A across the fleet is roughly 490 to 900 hours, the great majority manual.

DeepSeek leg: 620 to 1,240 combined agent and owner hours for Route C. Driving assumption: manual retopology economics. It prices Route A at 40 to 80 combined hours per capital hull (1,260 to 2,520 across the fleet), Route B at 8 to 16 combined hours per capital hull (264 to 528 across the fleet), and the organic route at 20 to 40 hours per Chorus capital. If hulls are substantially hand worked rather than batch processed, this is the honest range.

Planning position: build automation first (the Argon build order, section 6), budget against the Rey leg range, and treat DeepSeek's as the manual worst case. Then calibrate: record per-hull hours on the first hull through each branch (first machine cage hull, first bio branch hull, first lofted flagship) and on the issue 75 timings when they land, and replace these estimates with measured numbers before committing the fleet batch. The spread between the three pricings is itself the finding: the route's cost is decided by how much of the per hull work the scripts absorb, which is exactly what the calibration hulls measure.

## 8. The issue 75 bake-off rubric

Issue 75 renders three hulls three ways (today; Route B; Route A on the Pyre-Barge only), at the battle camera and at close zoom, same lights and angles, with a frame cost per route and a one page effort note. When those sheets land, judge them on three checks, drawn from the Rey and Argon legs. What each outcome changes in the Route C split is stated with each check.

Check 1, the Eclipse zenith cruiser (Route B versus today). Look at the broadside armour under angled light and at the gun and engine blocks. Route B's paint should cure the mottled camouflage and the grid at once. The question is whether Route B leaves bow waviness or melted turrets. If the surface is clean textured but still wavy, the fairing in the bake-off was too weak: that is planar collapse and weighted normals doing their work in Route C, or a lofted bow if the blob sweep gate fails it, and it is not on its own a reason to abandon the machine branch. Ask which fairing setting was used before changing route. If Route B reads as an Eclipse ship at the battle camera from silhouette and FAC3D value blocking but looks plain at close zoom, that is the expected fleet tier result and it is acceptable. If the melted turret blocks survive Route B visibly, that confirms the shared kit libraries are load bearing, not optional garnish.

Check 2, the Pyre-Barge (Route A versus Route B). Compare the crispness of the kit built turrets, radiators and lofted bow on Route A against Route B's remeshed AI parts, at both zooms, with the frame cost figures issue 75 owes. The gap between those two pictures is the entire case for the flagship split. If the gap is large at close zoom and small at battle distance, the flagship split is exactly right: loft and bespoke attention for the 5 machine flagships, cage plus shared kits for the rest. If the gap is small at both distances, the split shrinks: drop SHELL=1 to the Barge alone and save the loft hours. If the gap is large at battle distance too, that is evidence for widening the loft list beyond the flagships, at flagship per hull cost for each added hull, and it should be argued from these pictures, not assumed.

Check 3, the Ninefold Maw (Route B versus today). Issue 75's Route B is a machine pipeline, so judge this sheet narrowly: are the machine parts still present (the hexagonal turret piece, flat panels, ring fittings), and does the surface still read as flesh versus rock, or rock only? Do not judge the final flesh read from this sheet, because the bio branch is not in the bake-off. If the machine parts are still sitting on the creature, or the hull still reads as dry matte rock, that confirms the bio branch is required and that no machine route, however clean, fixes the Maw. If Route B has unexpectedly removed the machine language and the lumpy rock read, the bio branch can be descoped to material work only, and its sculpt hours come back.

## 9. Risks

- FAC3D as single colour source. The highest risk in the PBR work is accidentally creating a second colour authority through imported PBR albedos or finish maps. Mitigation is structural: every baked map is a mask (AO, curvature, thickness, wear), all base colour is driven by FAC3D, and the paint solve takes colour from FAC3D only, written into the scripts rather than left to taste. Route A's existing procedural paint already follows this law.
- R73 break up. Ship break up is prototyped clip and plug first, plane cuts as fallback, and any route that changes hull geometry must not break it. Machine branch hulls stay single closed meshes close to their current form, which carries the existing prototyping over best. Lofted shells plus kit parts are the concentrated risk: the clip and plug prototype must be rechecked on the first lofted hull and the first kit carrying hull before those branches roll out. Whether kit parts merge into the hull mesh at export (owner question 3) changes this risk and is Opus's feasibility call.
- R80 damage surface coordination. Damage reads are a separate ruled thread (issue 51, Codex issue 66). New geometry, new normal and AO maps and new materials change how damage marks and holes sit. Coordination, not re-scoping: the damage work stays on its own track, and each branch owes it one retest hull so damage can be checked against the new surfaces.
- Godot conversion. The Godot build converts the same hull files: build_assets.gd reads hulls_hi/ and hulls/ (build_assets.gd:106) and writes res://gen/hulls/<code>.res (build_assets.gd:228), and the browser build shares the files. The conversion keeps working if every branch's outputs stay in hulls/ and hulls_hi/ in the existing file kinds. A route that changes file format or directory needs a matching build change and is out of scope here. Texture sizes and any second UV channel for decals must be confirmed through build_assets.gd on one hull per branch first.
- Blob sweep gate per hull. Every ship must pass the 9 cell review before being shown. Route C helps everywhere except one known soft spot: a voxel remeshed bow can stay wavy, so the gate is a real gate, not a formality, and its failures feed the SHELL=1 loft list under section 4.3.
- Two branch maintenance cost. Route C is two pipelines (machine and bio) on one foundation, plus a loft path. That is three sets of steps to document in docs/ship_pipeline and keep straight, against one pipeline under a pure route. The mitigation is the shared foundation: the branches differ only in what happens after the audit step, and the cleanup itself (repair, remesh, UV0, bake discipline, FAC3D solve, gate) is common. The cost is real and is the price of not putting panel lines on a creature.

## 10. Screenings

### 10.1 Qwen leg: screened, filed as a record

The Qwen leg passed both model gates (Qwen3.8-Max verified before sending and after generation) and returned a single response. On substance it is largely non-responsive to the leg prompt:

- It contains no sourced per-game research. The pack required every named game covered from sources, with unsourced claims marked INFERRED; the leg answers none of pack Q1 to Q4 for any game and cites no sources at all.
- It prices no route against the pack's routes. Routes A, B and C as the pack defines them are never evaluated; the leg instead recommends a staged single pipeline of its own framing, with no per-hull effort figures.
- It invents pack facts. It states the fighter S1_51's reference is a "Sword of Light" screenshot and builds a 2.5 m scale figure on it; no such reference exists in the pack. It names a ".vs" ship format alongside .vsm and defines their relationship by assumption; the pack knows .vsm only. It refers to "four core hulls" in the pack; the pack verifies 36 hulls and no core four. It treats a free-tools-only constraint as something the board might revisit by adding a paid tool through a separate cost decision, where the pack states free tools only as a standing constraint. In its fleet table it lists S2_23 as the destroyer; the pack lists S2_23 as the bomber squadron craft (pack section 3.1), and its own later text contradicts the table by calling S2_23 the destroyer and a bomber in different places.

It is filed as a record under legs/. Its only usable points are the ones where it converges with the other legs, and those are the only places this synthesis reflects it: measure per-hull cost on early hulls before committing the fleet (adopted in sections 6 and 7 as calibration); lock the shared UV and material numbers once rather than re-deciding them per hull (adopted in sections 3 and 4.1); and check FAC3D coverage for Chorus organic tones before the bio branch's texturing starts (adopted as a prerequisite in section 4.4's material step). Nothing in this synthesis rests on Qwen alone.

### 10.2 Argon leg: used selectively

The Argon leg passed both gates (model 4 Argon, Thinking level High; picker button and prompt bar verified before sending and after sending). What the chair uses from it: the Route C shape (shared faction socket kits, planar cage cleanup, flagship only shell lofts, a dedicated Chorus bio branch), the four defect cause table, and the issue 75 bake-off judging rubric, all of which converge with the Rey and DeepSeek legs.

What the chair does not rely on: per-game production specifics stated as sourced fact where the other legs' searches found the public record thinner, including Battlefleet Gothic kitbash ratios and percentages, studio headcounts, and per-hull day counts. Those are treated as unverified and do not appear as facts in this pack; section 2 states only what the documented sources support and labels the rest INFERRED. Its effort total of about 101 agent hours rests on full automation assumptions the other legs do not share and is not adopted as the price of Route C; it appears in section 7 as one of three pricings, with its assumptions attached. The leg also mislabels the damage surface ruling as R76; the damage spec is R80 (issue 51), and this pack uses R80.

## 11. Owner questions

Four questions, chair pick marked on each. Questions 1 and 2 should be ruled before the build order in section 6 starts; questions 3 and 4 can be ruled alongside it.

Q1. Adopt Route C as the fleet route (chair pick), versus pure Route B, versus pure Route A. Route C is the tiered hybrid in section 4: shared foundation, planar cage plus shared kits for the machine fleet, lofted shells for flagships and failed bows, a bio branch for Chorus. Pure Route B is cheaper, but waviness is only reduced, not removed, and the melted AI mounts remain, which the settled kit finding rules out. Pure Route A is the quality ceiling, at 210 to 350 agent hours on the Argon leg's unit count and far more on the DeepSeek leg's, and the organics do not fit it at all. The chair pick is Route C because it is the only route that removes all four defect causes across all 36 hulls at a price with any automation in it.

Q2. Drop projected concept paint permanently across all 36 hulls (chair pick: yes), versus keep trying to clean it up. The cleanup option is not untested: the Nov 1 repaint (G-14) already ran it, all 36 hulls were repainted through the same projection chain, and the complaint followed. Projected paint also double lights every hull by construction. Dropping it costs the fleet some distinctive painted details from the best concepts, which come back as decals where they earn it. The chair pick is yes, permanently, with concepts kept as reference.

Q3. Merge static kit parts into the hull mesh at export (chair pick), keeping only rotating turrets separate, versus keep a separate _kit.json per hull as C19_51 does today. Merging halves the per ship file and draw complexity, simplifies the build_assets.gd conversion, and gives the R73 break up one unified mesh to clip instead of a hull and a kit file that can desync. Keeping _kit.json preserves the pattern C19_51 already ships and keeps kit parts independently editable. The chair pick is merge, and the pick is explicitly subject to Opus's feasibility check, because it touches build_assets.gd and the R73 break up work; if Opus finds a blocker, the fallback is _kit.json per hull with no other change to Route C.

Q4. Use the three issue 75 bake-off hulls as the calibration set for Route C (chair pick: the Warlord's Pyre-Barge as the flagship reference, the Eclipse zenith cruiser as the first machine cage hull, and the Ninefold Maw as the first bio branch hull, with per-hull hours recorded on each to replace the estimates in section 7), versus starting calibration on a mid-fleet hull instead. The bake-off hulls are the only hulls with a same lights, same angles comparison already owed, one per branch, and the Barge is the only hull with an approved quality bar to calibrate against. A mid-fleet start would be cheaper per mistake but would calibrate nothing about flagships or the Maw, which are where the money and the risk are. The chair pick is the three bake-off hulls.

## Dissents and rejected positions

- Effort spread. The three usable legs price Route C at about 101 agent hours plus batch and review time (Argon), 155 to 325 mixed script and manual hours (Rey leg), and 620 to 1,240 combined agent and owner hours (DeepSeek). The causes are units and automation assumptions, not arithmetic errors: Argon assumes the scripts absorb nearly all per hull work, the Rey leg assumes a scripted batch with manual touch up and hand work concentrated on flagships and Chorus, and DeepSeek prices manual retopology and per hull authoring. The chair does not average them and does not pick one as the price. Planning position is in section 7: automation first build order, budget against the Rey range, DeepSeek as the manual worst case, calibrate on the first hulls.
- Flagship count. The Rey leg tiers 6 flagships (one per faction including Chorus, counted with the Pyre-Barge). DeepSeek puts about 8 hulls on the bespoke route (flagships and the most iconic capitals). Argon lofts the 5 machine faction flagships plus bow fixes driven by the blob sweep gate. Chair position: 5 machine flagships are named for SHELL=1 (one per machine faction, C19_51 among them), the Chorus flagship goes through the bio branch like the other Chorus hulls, and gate driven bow lofts are added by the blob sweep, not by a fixed count. The flagship list is confirmed by the bake-off pictures under check 2 in section 8; that confirmation is the verdict's one condition.
- Whether voxel remesh plus smoothing suffices for waviness. DeepSeek and Argon agree it does not remove the cause: the remesh follows the wavy surface, and smoothing reduces the wave without removing the low frequency error. The pack position follows them (sections 1 and 5): waviness is removed by planar collapse plus weighted normals on machine hulls, by lofted shells where the gate demands it, and by sculpt fairing on organic hulls. Any leg wording suggesting a remesh and retopo batch alone removes waviness is rejected.
- Qwen's staged single pipeline framing. The Qwen leg recommends one pipeline approved in stages, with a sculpting fallback where the generator fails, and no machine and bio split. Noted here as screened (section 10.1): its staging instinct converges with the calibration position in sections 6 and 7, but its single pipeline framing is rejected, because it is built on invented pack facts and would run Chorus hulls through a hard surface pipeline.

## Not checked

- No bake-off pictures, timings, or frame costs exist yet. Issue 75 is blocked and has produced nothing; every statement in this pack about how Routes A and B will look rests on the legs' reasoning, not on the comparison sheets. The rubric in section 8 is written to be applied when they land.
- No Blender setting named in this pack (voxel size, planar angle limit, Laplacian repeat counts, bake samples, cage offsets) has been validated on our hulls. The settings are sourced starting points from the Blender Manual, StraySpark and Dev Journal 21, not measured values for Voidsworn meshes.
- Studio per-hull costs are not public for any named game. No leg found a published per-ship day count or dollar cost for Battlefleet Gothic, Homeworld 3, Sins 2, Deadlock or Starsector, and none is claimed here; team shape evidence is cited where it exists and cost inferences are labelled INFERRED.
- Screenshots ryan_c02 to c04 and ryan_c06 to c08 were grounded from the pack summary, not read closely by every leg. The pack's chair read covers c01 and c05 closely and treats the four named defects as the fixed target list for the rest; no leg re-derived the defect list from the full screenshot set.
- The Godot conversion and the browser build were not re-run against a Route C output. Section 9 states the condition under which the conversion keeps working (outputs stay in hulls/ and hulls_hi/ in the existing file kinds) from the pack's verified citations; no hull has yet been pushed through build_assets.gd on the new chain.
- The damage surface work (R80, issue 51, Codex issue 66) and the R73 break up prototype were treated as constraints with named retest points, per the pack. Neither was re-audited for this research.
- Whether Blender's built in baker matches Marmoset quality closely enough on our hulls is unmeasured. Dev Journal 21 prefers Marmoset and names Blender as workable; Marmoset is paid and sits outside the free tools rule unless the owner changes that rule.
- The three objective structures as a design problem in their own right. They are priced inside the machine branch in every leg, but no research was done on station or beacon art specifically, and structures are large, static and viewed from all sides, so they may deserve a separate look.

## Owner rulings (Ryan, Nov 3, 2026)

Ryan agreed with the chair picks on Q2 (drop projected paint permanently), Q3 (merge static kit parts at export, subject to the Opus feasibility check) and Q4 (calibrate on the three issue 75 hulls) (FINDINGS R82). Q1, the fleet route, is held until the issue 75 comparison sheets land so Ryan can judge by eye.

Ryan, Nov 3 after the issue 75 sheets (FINDINGS R83): route B is out for machine hulls; Q1 stays open until a second Pyre-Barge comparison of three variants (A+ rich surface, clean shell plus baked AI detail, clean hull plus reused AI parts) lands.
