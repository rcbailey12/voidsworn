# Issue #135 chair synthesis: 50 to 75 percent graphics jumps for deaths and weapons, nebulas and storms, planets

Chair: Rey. Legs: DeepSeek and Qwen (writers), Argon (review). Grounding verified by the chair against main on 2026-11-03. Verdict: GO.

## 1. Headline and ranked leaps

Three leaps, in the owner's order. Each replaces a rendering model or a choreography, not a parameter.

1. Deaths and weapon hits: kill the raymarched fireball and choreograph the death. The fireball shader (godot/fx/fx_shaders.gd:1626, a raymarched volume of rolling fire and dark smoke) is removed from deaths entirely and replaced by art-directed flipbooks baked offline in Blender (fast-snuffing plasma and venting gas, optical-flow blended), plus directional venting cones and spark bursts from GPUParticles3D. The death itself becomes a four-beat sequence inside fx_death.gd (power loss, vent, structural break, drift and cool) over about 2 seconds, with the existing worker-thread slicer extended from one cut to two or three staged cuts. Weapon work stays in the transient layer of fx_weapons.gd; the R80 damage surfaces are untouched.
2. Nebulas and ion storms: hybrid volumes. Each gas patch gains a FogVolume body running a custom fog shader that carries the settled R82 colours, while a reduced layer of the existing billboard puffs stays on top as the crisp edge, so ships inside gas stay sharp. Lightning and explosion lights are allowed into the fog at the max quality tier. Two zero-cost engine fixes come first: the battle camera's near plane (0.5 units today, godot/render/camera_rig.gd:33) and the volumetric fog length (400 units, godot/render/backdrop.gd:53) currently waste most of the froxel depth grid on empty space in front of the battle.
3. Planets: keep the GPU bake, give it geology. The bake stays in world_bake.gd at the ruled 4096x2048, but the surface model changes from plain value-noise FBM to a structured stack: spherical Voronoi tectonic plates, domain-warped continents, derivative-damped pseudo-erosion ridges, gradient-normalized coastal shelves, latitude and moisture biome ramps, and a true normal map computed on the sphere. Terran and rocky first.

## 2. The hypothesis test

Opus's hypothesis was that the effects are mostly flat sprites and code-made textures tuned by numbers, and that the jumps come from real volumetrics, offline-baked assets, and one art direction. Verdict: it holds in one area, half holds in one, and fails as stated in the first.

- Nebulas: holds completely. The gas is billboard quads sampling one noise field, and the engine's real volumetrics are exactly the jump.
- Planets: half holds. The surface is code-made and tuned by numbers, but the fix is not offline baking or volumetrics; it is a better procedural model inside the existing GPU bake, which also preserves per-seed variety.
- Deaths: fails as stated. Deaths are already real split geometry with physics debris, and the fireball is already a real volumetric. The owner's complaints trace to two different faults: a fidelity mismatch (the one photoreal element in a painterly scene, using an atmospheric fire model in vacuum) and single-beat choreography (split, flash, done). The jump there is art-directed offline gas plus event sequencing, which is the hypothesis's third limb (one art direction) doing the work.

## 3. Area 1: ship deaths and weapon hits

### What the best do (sourced)

- Homeworld 3 (Blackbird): the strongest reference at our camera distance. Tim O'Connell's published breakdown (Feb 2023, verified by the Argon review) describes damage types with distinct treatments, a Splat Damage system that changes the hull surface at impact points rather than pasting decals, damage sockets on larger hulls that spawn smoke, fire, breaches and sparks by stage, and a procedural Houdini Ship Breaking tool that generates broken hull geometry and debris instead of hand-modelled wrecks. Fighters switch between a camera-facing smoke sprite at low speed and an inky ribbon trail at speed.
- EVE Online (CCP): Andre Bragason's GDC 2024 talk "Reigniting Stars" (verified by the Argon review) covers the move from centre-flare explosions to multi-part 3D explosions that spread from the ship's damage locations and read from close up to hundreds of kilometres, tonnage-scaled: frigates get a fast reactor flash, shock rings and debris; battleships get a slower, larger flash with big rings and debris. Damage-type colour is differentiated.
- Sins of a Solar Empire II: the cautionary tale. Its Ruins of War update (Nov 2024, verified) added custom persistent wreckage per capital, but the player record criticises weak hit feedback and capital deaths that dropped frame rates from a stable 45 to 20 to 25 fps. Wreckage alone is not enough; hit feedback and the death performance envelope decide the read. (Argon also surfaces a Jan 2025 Sins II update overhauling planet textures; carried as Argon-sourced, relevant to section 5.)
- Battlefleet Gothic: Armada 2: no checkable developer breakdown exists (both legs agree once Qwen's invented interview is stripped). Its reviewed language is spectacle-first: a massive engulfing final explosion and heavy particle density. Useful for flash scale, not for structure.
- The Expanse (visual reference): the grammar anchor for the owner's fire question. No sustained combustion in vacuum; breaches vent ignited gas in a cone that flashes and snuffs out in a second or two; structure fails progressively; debris keeps its vector forever; sparks are the dominant "fire" visual; the palette is blue-white cooling to deep red, not orange-yellow flame.

### The leap

Two linked changes. First, the gas language: remove the raymarched fireball from deaths (both its fireball and vent-plume types) and replace it with Blender Mantaflow flipbooks art-directed to the space grammar: a plasma flash that snuffs in under half a second, a directional venting plume, and cooling dark-violet vapour that disperses ballistically with no buoyant rise. Flipbooks get two production refinements neither leg had: an optical-flow (motion vector) channel so a 4x4 or 5x5 atlas at 2048 plays smoothly at 60 fps without strobing, and a directional lightmap or thickness bake so the plume shades against the sun and the scene's violet ambient instead of reading as a pasted sticker (both INFERRED techniques from the Argon review). Directional venting cones and zero-drag spark showers run as GPUParticles3D emitters driven by the thermal-tear normal fx_death.gd already computes.

Second, the choreography: a data-driven DeathTimeline in fx_death.gd, four beats after lethal damage: (1) power loss, running lights die section by section with a brief blue-white flicker along the tear; (2) vent, the cone and plume plus at most two small secondary flashes inside the existing 3-flash budget (godot/fx/fx.gd:22-25); (3) structural break, the slicer performs its cuts in sequence over about 0.8 s so the hull comes apart in stages, fracture faces carrying a decaying glow from the existing slag shader; (4) drift and cool, the existing wreck behaviour and 14 s cooling. All four beats live inside the death, after lethal damage. They do not bleed into the R80 damage stages, which stay persistent state in fx_ship.gd and fx_breach.gd (the Argon review's correction to Qwen, adopted).

Geometry ownership: the runtime worker-thread slicer stays the owner. It extends from one cut (two halves) to two or three staged cuts (three or four sealed sections), optionally shedding pre-authored internal chunks at the cut planes. DeepSeek's offline Blender pre-fracture of every capital hull is rejected: it duplicates the slicer, doubles asset maintenance across six factions, and the two systems cannot both own the hull at death (Argon review, adopted).

Weapon hits: the work is in fx_weapons.gd transients only. Muzzle and impact sprites become small flipbook bursts on the same atlas system, impacts gain a short directional spark burst, and torpedo and rocket streak trails become short flipbook trails for consistency. DeepSeek's "Splat-lite" proposal (replacing the 12-mark wound system with a baked atlas plus live Decal nodes) is screened out: the pack's own binding constraints put the mark caps and wound variants under R80, which this job must not reopen, and the clustered-decal budget it spends is a real Forward+ limit. Homeworld's splat idea is noted as the reference if R80 is ever revisited by the owner, not before.

### Frame cost (INFERRED throughout; profile before committing)

Budget burst and steady-state separately (the Argon review's correction to Qwen's net-savings arithmetic, adopted). Removing the raymarch removes a burst spike during capital deaths, which is worth having (it is the Sins II failure mode), but it does not fund steady-state costs. The replacement death load is small and bounded: a few flipbook quads and two particle emitters per death, well under half a millisecond in the legs' estimates. The cooling tail stays a cheap shader, which is where the death budget should not be spent (owner question 3).

### Build order (Codex)

D1. Death grammar sheet: the four beats, the palette card (blackbody cooling ramp, blue-white plasma reserved for drive and reactor events, violet-grey smoke), reference frames from Homeworld 3, EVE and The Expanse. No code.
D2. One Mantaflow vent-and-flash sim with optical-flow and lightmap channels; the flipbook shader (flow-blended UV, soft depth fade); wire it into fx_death.gd for one hull class in place of the fireball call. Before and after screenshots of the same death.
D3. Venting cone and spark emitters on the tear normal; DeathTimeline sequencer; staged slicer cuts; fracture-face glow decay.
D4. Remove the raymarch path from deaths entirely; small-hull sequence (flipbook pop, chunks, sparks, no ribbon).
D5. Remaining atlases per size class; quality-tier gating (high drops the fracture glow, low drops vent and sparks).
D6. Weapon pass in fx_weapons.gd: impact flipbook bursts, directional impact sparks, flipbook torpedo trails.
D7. Art-direction comparison pass: death frames against ship frames at the same exposure; cut detail frequency wherever an effect out-resolves the hull.

Anchors: fx_death.gd (1,388 lines, slicer, debris cap 360, WRECK_COOL 14.0); fx_shaders.gd:1626 (the VOL raymarch, removed from deaths by D4); fx_weapons.gd (1,170 lines); fx.gd:22-25 (flash budget, unchanged).

## 4. Area 2: nebulas and ion storms

### What the best do (sourced)

Homeworld 3 is the reference: volumetric nebula actors (a volume mesh plus material) with a density threshold that decides when a ship counts as inside the gas, fractal volume density for shape, and lighting and fog that let ships hide inside clouds (DeepSeek, from the game's modding documentation; Argon verifies the architecture). EVE's nebulae are backdrop and skybox phenomena, not gameplay volumes, and no sourced EVE nebula-volume technique exists; neither leg's EVE material is carried here beyond that negative finding. Sins II and BFG read as layered billboards and screen-space fog, which is the class of technique we already have.

### The leap

Hybrid volumes, one per gas patch, in world_living.gd:

- A FogVolume (box or ellipsoid fitted to the patch footprint) with a custom fog shader: density from a baked tileable 3D noise texture (128 cubed, two scales plus a domain-warp shear) multiplied by the existing per-patch mask, so the authored silhouette survives.
- The R82 colour design ports exactly, with one engine correction from the Argon review: a Godot fog shader outputs DENSITY, ALBEDO and EMISSION per froxel, and lights multiply ALBEDO during integration. So the ramp splits: the dark and shadow stops go to EMISSION (the gas never falls to pitch black), the lit and glow stops go to ALBEDO where the sun, lightning and explosions can drive them. Faction tint stays capped at 25 percent at the ramp ends (NEBULA_FACTION_END_WEIGHT).
- A reduced billboard layer stays: the broad tying veils and a thinned puff set remain as the high-frequency edge, because the froxel grid (default volume_size 64, volume_depth 64) cannot resolve crisp painterly edges at 4K. This is what keeps the R82 crisp-ships rule true while the volume supplies depth, parallax and internal light. Qwen's pure-volume variant, and its suggestion that ships sit at 70 to 80 percent visibility through the densest gas, are screened out: the first blurs the silhouette, the second contradicts the settled R82 position that ships stay crisp and the gas dims the sky, not the ships.
- Light injection by tier: at max, lightning bolt lights and explosion flashes get light_volumetric_fog_energy so they scatter inside the gas (today the bolt lights are deliberately kept out of the fog, world_living.gd:473-475, which caps the fidelity); at high, Qwen's cheaper storm_flash density pulse stands in; at low, the current billboard-only path runs unchanged. The existing "one optional patch light" carries over. Storms use a shader variant with emissive cores; the ribbon lightning and shield-tick flare stay as they are.
- Froxel preparation (chair-verified in code): camera_rig.gd:33 sets the battle camera near plane to 0.5 and backdrop.gd:53 sets volumetric_fog_length to 400.0, while the battle sits around 170 units away. Froxel depth slices are distributed logarithmically across that range, so most of the grid resolves empty space. Raising the near plane toward 5 to 15 units (fixed per zoom band, not per frame) and tightening the fog length toward 250 concentrates the slices on the battle plane at zero GPU cost. Test volume_size and volume_depth at 128 on the max tier with temporal reprojection on.

### Frame cost (INFERRED)

Steady-state, so it must fit the ordinary frame, not a death spike: the legs estimate 1 to 3 ms for two or three medium volumes at max tier on the 5080, dominated by froxel count and interacting lights (cap fog-active lights at 1 to 2). The froxel preparation step raises quality at the same cost. Validate with the GPU profiler on a full battle before the tier defaults are set.

### Build order (Codex)

N1. Froxel preparation: near plane and fog length as above; confirm no visual change on the current billboard gas. Screenshot check.
N2. Bake the 3D noise texture; prototype one patch as a FogVolume with the split-ramp fog shader; colour-parity screenshots against the current patch.
N3. Restore the reduced billboard edge layer over the volume; verify ships inside gas stay crisp at 4K.
N4. Light injection at max (bolts and flashes), storm_flash pulse at high, storm variant with emissive cores.
N5. Tier wiring and a full-battle 4K profile; profiler numbers filed back onto the issue.

Anchors: world_living.gd (1,008 lines; gas at :255 onward, GAS_SHADER ramp at about :44-51, bolt light exclusion at :473-475); battle.gd:333-360 (quality tiers); camera_rig.gd:33; backdrop.gd:53.

## 5. Area 3: planets, especially rocky and terran

### What the best do (sourced)

- Elite Dangerous (Frontier): the most documented system. Dr Anthony Ross's 80 Level breakdown (April 2018, verified by the Argon review) describes the Stellar Forge simulation setting classification, tectonics, volcanism, basins and ice, which then drive the noise graphs that form the terrain, with artist textures for rock, sand and scree blended by terrain gradient. The transferable lesson is the two-level structure: a simulation decides what features exist, then noise renders them.
- Star Citizen: Genesis Planet Tech V5 (verified by the Argon review) replaced hand-placed rules with physically driven emergent biomes and layered material shading (substrate, soil, scree, bedrock, sand). The transferable piece at backdrop distance is the biome and material rule layer over the height field.
- No Man's Sky (Hello Games): GDC 2017 talks by Sean Murray and Innes McKendrick (titles corrected by the Argon review) cover layered noise and domain warping for structured surfaces. Inigo Quilez's domain warping write-up is the standard recipe both legs lean on.
- EVE and Sins planet specifics from Qwen are not carried: its citations there were fabricated. The structural summary it converges on (warped continents, ridge ranges, shelves, biomes, computed normals) is independently supported by the Elite and No Man's Sky material and by DeepSeek's feature stack.

### The leap

Keep Qwen's architecture, adopt DeepSeek's feature set, add the Argon review's three shader techniques. Everything happens inside the existing GPU bake in world_bake.gd (which already evaluates the surface in 3D sphere coordinates, world_planet.gd's dir_of), preserving seed variety and the Job 10 sizes:

1. Tectonic plates: a low-frequency 3D spherical Voronoi field (8 to 14 cells), each cell with a drift vector; boundaries classified convergent or divergent, seeding arcuate mountain belts and rift or volcanic chains (Argon, INFERRED).
2. Continents: domain-warped FBM in place of plain FBM, so coasts curve and break like geology instead of noise blobs.
3. Ranges and valleys: ridge noise for the ranges plus derivative-damped pseudo-erosion (accumulated FBM derivatives damping the higher octaves), which carves flat-bottomed valleys and sharp ridges in a single pass, the in-shader approximation of the erosion look DeepSeek wanted from an offline rig (Argon, INFERRED; Quilez and Musgrave lineage).
4. Coastal shelves at constant width: divide height above or below sea level by the gradient magnitude, so the shelf is a spatial band rather than a height band that vanishes on cliffs (Argon, INFERRED).
5. Biomes: latitude plus altitude plus moisture ramps placing desert, temperate, tundra and ice, following the Star Citizen rule-layer idea at bake scale.
6. Normals on the sphere: compute the normal map from gradients along the sphere's tangent basis, never from raw equirect UV differences, which pinch at the poles and seam at the wrap (Argon correction to Qwen's P5, adopted; the current bake's 3D formulation makes this natural). Output normal and roughness alongside the existing channels; DeepSeek's CC0 micro-detail textures (ambientCG, Poly Haven) blend by slope in world_planet.gd for close-frequency material.
7. DeepSeek's offline Blender erosion rig is rejected as the primary path: it discards seed variety and ships static 4K texture sets per kind. It stays available as a one-off hero-planet option if a story planet ever needs hand art.

Scope: terran and barren/rocky first (the owner's complaint, and rocky already has the crater field to build on), then volcanic desert; gas and ice giants keep the banded path.

### Frame cost (INFERRED)

Runtime is effectively free: one sphere, a few extra texture samples and a normal lookup, well under 0.5 ms. The real cost is load time: the enriched bake adds several noise evaluations per texel at 4096x2048; the legs estimate the bake roughly doubling, still a load-time, not frame-time, cost. A full texture set per kind at BC compression is tens of MB, shared across instances.

### Build order (Codex)

P1. Domain warping for continents; before and after on one terran seed.
P2. Voronoi plates plus ridge ranges and derivative pseudo-erosion into the relief channel and albedo.
P3. Gradient-normalized coastal shelf and the biome ramps.
P4. Spherical normal and roughness output; world_planet.gd consumes them (terminator shows real topography); cloud-shadow offset by the normal.
P5. Slope-blended CC0 micro-detail; repeat P1 to P4 for barren/rocky, then volcanic desert.

Anchors: world_bake.gd:10 (PLANET_SIZE 4096x2048, moons 1024x512); world_planet.gd (351 lines; bake body with fb/rg noise and the crater field; sphere shader with terminator, glint, night lights, limb haze, ring shadows, all kept).

## 6. Shared art direction

One fidelity across ships, deaths, gas and planets:

- Palette: the R82 violet family governs gas and effect shadows; hot metal follows a blackbody ramp (white to yellow-orange to red to black); blue-white plasma is reserved for drive and reactor events; planet surfaces stay muted and desaturated. No pure white or pure black in any effect.
- Contrast: effects are bright at the core and quiet against the scene; the flash budget (3 counted flashes per rolling second) is the system-level enforcement, and death frames are checked against ship frames at the same exposure.
- Detail frequency: ships are broad painted shapes. Effects use large soft masses with sparse high-frequency accents (sparks, debris, lightning ribbons, range silhouettes). Nothing may out-resolve the hulls; the fireball failed exactly this rule.
- Motion: everything inherits momentum and nothing pops in place. Gas drifts and shears slowly; vented gas travels straight and fades; debris tumbles on its vector; deaths are sequenced beats, never simultaneous.
- Fire in space, the owner's question, answered plainly: no, not as the default. Sustained orange flame is an atmospheric behaviour. The space grammar is venting gas that flashes and snuffs, superheated metal cooling through the blackbody ramp, sparks, and brief electrical arcs. Flame survives only where a pressurised, oxygen-bearing interior is the explicit subject, which a hull exterior in vacuum is not.

## 7. Screening notes

- Qwen's bibliography is fabricated in almost every particular (invented names, talks, interviews, a dev diary series and a direct quote), as itemised in the Argon review and confirmed by the chair's cross-checks between the legs. Its technical proposals were therefore used only where they converge with DeepSeek, the pack, or the code, and its citations are stripped. Its visual observations of The Expanse match the show and are carried as observations, not citations.
- Qwen's volumetric fog description (a half-resolution raymarch with temporal steps) is wrong for Godot; the froxel account in sections 4 is the correct model. Its frame-cost table double-counts burst savings against steady-state costs; section 3 and 4 use the corrected split.
- Qwen's owner question on nebula density (ships at 70 to 80 percent visibility) contradicts the settled R82 crisp-ships position and was not put to the owner; its question on normal-map storage is an implementation detail for Opus and Codex, not an owner call.
- DeepSeek's Splat-lite weapon proposal conflicts with the pack's binding R80 constraint and was screened out on that ground, not on merit. Its offline pre-fracture and offline planet bake were rejected for pipeline reasons stated in sections 3 and 5. Its remaining content, including its source list, is carried.
- Argon's review is filed with a chair header recording its limits. Its extra specifics (Sins II planet update, Expanse supervisor names, GDC talk titles) are Argon-sourced; the chair did not independently re-verify each one, and the synthesis leans only on claims the legs corroborate.

## 8. Owner questions (chair picks first)

1. The fireball's fate. Chair pick: remove it from deaths entirely; the baked plasma flash is the hero moment. DeepSeek would keep the raymarch for rare reactor criticals at max tier, but that keeps the exact photoreal, atmospheric effect you flagged, just less often.
2. Flipbook art style. Chair pick: Mantaflow sims rendered with a stylised grade (posterised colour, reduced detail frequency), with a hand-painted pass only if a sim still reads too real. Hand-painted atlases from the start cost several extra weeks and a 2D animation skill the pipeline does not currently use.
3. Where the death frame budget goes. Chair pick: spend it on the first 2 seconds (flash, vent, break) and keep the 14 second cooling tail a cheap shader, because at battle distance the break and the first tumble are what read.
4. Lightning in the fog. Chair pick: allow bolt and explosion lights into the FogVolumes at max tier, use the density pulse at high, keep them out at low. That reverses a deliberate current exclusion, but only where the hardware pays for it, and it is the largest single payoff of the volume switch.
5. Planet scope. Chair pick: terran and barren/rocky first, volcanic desert next, gas and ice giants stay on the current bake. All six at once spends the bake time before the first visible win lands.

## 9. Not checked

- No Godot project was run; every frame-cost figure is an INFERRED budget from cost drivers, to be replaced by profiler numbers in build steps N5 and the D-series screenshots.
- The chair did not independently re-open every source URL; DeepSeek's citations were spot-checked for internal consistency and Argon's itemised verification is recorded in its filed review.
- Godot 4.7 fog shader property names and froxel defaults are stated from the 4.x documentation line and the Argon review; the N2 prototype is where they get confirmed against the actual 4.7 build.
- Moon surfaces (1024x512) were not separately researched; the planet pipeline changes apply to them by inheritance, unchecked.
