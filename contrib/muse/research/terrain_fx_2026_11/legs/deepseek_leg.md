Board issue 81 research leg report: terrain effects

Scope note: this report stays on the board. Sky, backdrop planet, moons, backdrop station and backdrop rock scale are Job 10 scope and are not redesigned here. Where an idea touches them I give one hand-off line only.

1. Per-game findings

1.1 Homeworld 3

Documented. Blackbird Interactive built a custom volumetric nebula system rather than using Unreal Engine's ray-marched cloud system unchanged. The team says it started from Unreal's ray-marched clouds, found them too limited for NASA-like nebulae, and built its own system so it could adjust density, movement and colour. The method is per-pixel ray marching through the gas volume: for each screen pixel, a ray steps through the volume at set intervals and accumulates density measurements at different depths, then uses the accumulated density to derive lighting and colour. Low-density regions blend wisp-like shapes with more movement; high-density regions, toward the core, use a fractal volume density effect to create shape and interest. The result reacts to different light sources and hides ships based on both the gas density and the ship's depth inside the cloud.

Documented gameplay coupling. Homeworld 3 exposes the nebula as a gameplay volume, not only a look. A density threshold defines when a ship is "inside": the default threshold is 0.5, and when nebula density is greater than that value the ship counts as inside. The standard nebula status effect applies Primary Sensors Range -0.5 and Visual Range -0.5. A data asset can also set a damage multiplier and a status effect for ships in the volume. The public developer update states that nebulae both obscure vision and mask sensor data from ships travelling within them, and that the gas can hide ships based on density and depth.

Documented lighting context. Homeworld 3 uses Unreal Engine 4 PBR with dynamic lighting, realtime surface reflections, shadows and global illumination, so ships react to the lighting environments they fly through. The same update notes that nebulae were a visual fidelity priority and that the team studied Hollywood space-ship lighting for hull response. This matters for terrain because any internal light in a gas volume will show on nearby hulls if the hull is PBR lit.

Documented performance character. The team describes ray marching as powerful but resource intensive, and notes that the density and colour work is done for every pixel of visible nebula every frame. No public source gives a layer count, sample count, or the number of embedded light sources. Those details are not documented.

INFERRED. The visible layered read in Homeworld 3 is likely produced by density-graded extinction and single-scattering approximations along the view ray rather than by a fixed stack of billboard layers. Star occlusion is likely handled by transmittance through the density field, so stars dim gradually rather than switching off at a boundary. Motion is likely 3D noise advection through the volume. These are reasonable inferences from the described method, not developer statements.

Mapping to our board. The density-threshold and depth-based concealment model maps directly onto our nebula hexes: the pack already gives nebula hexes a hit-chance effect at battle.js:649, and the visual can use a continuous density field masked by the patch footprint so the gameplay boundary is not a hard visual wall. Homeworld 3's per-pixel ray march is probably too expensive for every gas hex at our scale, but the density-graded colour and depth-based occlusion behaviour are the transferable ideas.

1.2 Sins of a Solar Empire 2

Documented. Sins of a Solar Empire 2 uses Iron Engine 3, with dynamic lighting, physically based rendering and higher-resolution textures. The official store description highlights orbiting planets, a slowly changing galaxy and PBR lighting, not in-play volumetric gas. The public modding surface includes skyboxes and a console variable named main_view.render_gravity_well_prop_clouds, which toggles a small cloud effect around gravity wells and is described by players as a 3D-feel addition. That is a backdrop or gravity-well prop effect, not a tactical gas volume with density and concealment. Community modding discussion is mostly about skybox replacement, not about authoring in-play nebula or storm volumes.

Documented gameplay. The published record does not document board-level nebula or ion storm gas in Sins 2 the way Homeworld 3 does. Sins 2's public identity is a large-scale strategy map with orbiting bodies and skybox nebulae; no citable developer source describes tactical gas clouds that ships enter and hide inside.

INFERRED. Sins 2's nebula read is primarily a skybox or backdrop treatment, not a per-hex volumetric effect. If there is any local gas or storm visual, the technique is most likely particle planes or shader billboards over a backdrop, because the engine's documented strengths are PBR lighting and large-scale orbital simulation, not ray-marched volumetrics. This is inference from public materials and should not be presented as an Ironclad statement.

Mapping to our board. Sins 2 offers little directly transferable in-play gas technique. Its relevant lesson is compositional: a strong skybox nebula can carry the "we are in a nebula" read while the board itself stays clean. For us that is a backdrop hand-off, not a terrain change.

1.3 Battlefleet Gothic: Armada 2

Documented gameplay. Gas clouds are localized zones on the battlefield. A ship inside a gas cloud enters a stealth or hiding state and can ambush from it; being inside also gives immunity to solar winds. Asteroid fields damage ships over time. This is a clear gameplay distinction: gas conceals, asteroids damage. The first game's gas clouds work the same way in broad terms: blue cotton-like gas clouds hide a ship's signature at long range, but the enemy can still find it at closer scan range; brown asteroid belts damage hull over time.

Documented environment tooling. Tindalos wrote a public dev diary about procedural environment authoring for space combat. The tool exposes dust clouds, debris fields, background scene objects such as planets, suns, derelict ships and skybox, post-processing effects, skylights and fog effects. Each element exposes properties for colour, scale, position, rotation and quantity so environment designers can author a scene and save it as a mission template. The example given is an asteroid-field mission in the Hydra nebula generating asteroids with a green nebula backdrop. This documents a backdrop and environment-dressing pipeline, not the internal rendering of the in-play gas cloud zones.

Not documented. No citable developer source found for how the in-play gas clouds are rendered: layer count, shader type, lighting model, star occlusion behaviour and motion cadence are not in the public record. The record is thin.

INFERRED. The in-play gas zones read as soft, semi-transparent volumes with a clear boundary against asteroids. They likely use layered billboard planes or particle cards with depth-softened edges, because that is the common real-time approach for localized concealment volumes and fits the game's scale. Concealment appears to be a gameplay state with a visual soft edge rather than a physically simulated density field. These are inferences from the game's look and public gameplay descriptions, not from a Tindalos technical talk.

Mapping to our board. BFG Armada 2 is the closest gameplay analogue to our nebula: a localized zone that conceals. Its readability lesson is that the player must recognize the zone boundary and the concealment state quickly. Its visual technique is not documented well enough to copy.

1.4 Stellaris

Documented pipeline. Stellaris VFX artist Erik Forsström describes system effects as a mix of particles and 3D models. The sheer size of system-scale effects requires more complex shapes than particles alone can give, so the team uses meshes with animated shaders to create movement in the textures, then adds particles on top. Nebulae, space storms and crisis system effects are all in this family. The Aetherophasic Engine effect is built from meshes plus animated shaders plus particles, and it changes through stages to communicate escalation. The article is a pipeline description, not a shader or lighting deep dive. Exact particle counts, layer counts and lighting models are not documented.

Documented gameplay. A nebula blocks all sensor coverage originating from other systems, so an empire cannot see what is within or beyond a nebula's hyperlanes without a ship or station inside, or a full Sentry Array. Nebulae are named and visible on the galaxy map from the start. Systems within a nebula have a small chance of being ionized; ionization is visible as occasional lightning strikes in the system, disables shields, applies -50 percent sublight speed and grants +30 percent evasion. Cosmic storms are also visible on the galaxy and system maps and block sensor coverage from other systems.

INFERRED. Stellaris's in-system nebula read is likely a large mesh or volume shell with an animated shader, layered with soft particle cards for depth and colour variation. Lightning is likely a particle or ribbon effect with a brief light flash, timed to the ionization state. Star occlusion is likely handled by the mesh or shader alpha rather than by a density field. These are inferences from the documented mesh-plus-particle workflow and from the game's visual grammar.

Mapping to our board. Stellaris is a strategy-map presentation, not a tactical camera at 170 units, so its scale cues do not transfer directly. Its useful lesson is the deliberate split between a large shape mesh and small moving particles: that is a cheap way to get layered structure without a full volumetric. Its gameplay lesson is that lightning is used as the visible marker of an ionized, damaging state, which matches our storm's need to "threaten and be visibly active."

1.5 EVE Online

Documented backdrop system. EVE's 2011 nebula update replaced 30 reused backgrounds with 68 unique region-level backdrops. The nebulae are computer generated, inspired by real-world imagery. They occupy parts of the sky rather than engulfing every system, with more dark patches in low-security and null-security space, cooler palettes there, warmer and more saturated palettes in high security, and ship reflections changing with the local nebula. The design intent is location legibility and scale, not tactical concealment.

Documented volumetric cloud pipeline. For newer volumetric clouds, CCP's engine team implemented base-level volumetric rendering. Artists author clouds in EmberGen, export VDB volumetric data, and a shader consumes that data in the engine. Full-quality DDS texture data was 300 to 400 megabytes per cloud, too large to ship, so CCP implemented in-house compression using re-digitizing, run-length encoding and zlib, giving roughly a 10x decrease, with data uncompressed onto graphics card memory. Low-quality settings ship half-resolution textures for cards with less memory. The studio says this let a small team deliver a mix of assets for the Viridian expansion.

Documented gameplay. EVE has gas cloud sites, including nebula sites with unsymmetrical gas volumes that players harvest. These are gameplay locations with visible clouds, not only skybox backdrops. No public source gives the exact rendering technique for the harvestable gas clouds themselves; the volumetric pipeline above is documented for cloud visuals generally.

INFERRED. EVE's volumetric clouds are likely rendered by ray marching or slice sampling through the VDB, with transmittance controlling how much of the starfield and distant objects show through. Internal light is likely a combination of emissive VDB density and local light sources. The half-resolution fallback is a useful precedent for our quality scaling: gas can drop resolution before it drops presence.

Mapping to our board. EVE's VDB workflow is too heavy for our procedural, texture-free terrain pipeline, and the pack says there are no hand-painted terrain textures. The transferable ideas are the compression and half-resolution LOD mindset, and the principle that a gas cloud should change what you see through it, not just add a flat layer on top.

2. Per-kind look spec for our terrain

The spec below is grounded in the pack's verified facts: TERRAIN_INFO at battle.js:8-15, effects at battle.js:649, battle.js:650, battle.js:398 and battle.js:651, the living-terrain implementation in world_living.gd, the old cloud path in world.gd, the tactical tint at board.gd:325, and the faction nebula colours at faction_look.gd:15 and :47. Where the pack is silent on exact uniforms or line-level details, the task says so rather than inventing names.

Common readability rules for all four kinds:

At 4K and the default camera, a ship must remain visible as a silhouette and its selection UI must remain legible. The effect may reduce contrast and hide detail, but must not erase the ship or its UI.

The effect must read as its gameplay effect at a glance: nebula conceals, storm threatens and is visibly active, debris is light physical cover, the well is a hazard centre.

The footprint must stay honest to the hexes it covers. Use the existing footprint mask at world_living.gd:298 rather than drawing hex-shaped blobs. The edge should feather over roughly one hex, not hard-cut on hex borders.

2.1 Nebula (neb)

Layer stack. Three visual layers plus the footprint mask.

Body layer at the current low band, y -4 to 5.5, using the existing 5 puffs per hex at 24 to 34 units and the broad tying puff per 3 hexes at 36 to 46 units. This layer carries most of the colour and density.

Mid veil at y 6 to 12, with fewer, larger, lower-alpha puffs, roughly 40 to 55 units, drifting more slowly than the body. This layer separates the gas from the ships' feet and gives vertical structure.

Foreground wisps at y 8 to 16, sparse and small, roughly 12 to 20 units, moving faster than the body to create parallax. These should be low alpha and never dense enough to obscure ship UI.
The footprint mask stays as it is at world_living.gd:298 so the patch reads as one body.

Colour behaviour. The base must be the legend violet #b07cff, pulled toward the faction nebula colour as today at world_living.gd:273-282. Replace the current two-flat-colour treatment with a three-band gradient across one cloud: a dark core at base times 0.18, a mid body at base times 0.45, and a lit rim at base times 0.72. Glow cores at base times 0.62 should be pushed slightly toward the faction sky nebula hue at faction_look.gd:15 and :47 so the cloud has an internal warm-cool contrast rather than a single violet wash. At least 15 percent of the patch should carry a secondary hue shifted toward magenta-blue, so the eye reads colour variation across the cloud. The legend colour must remain recognisable as violet at a glance; do not let the secondary hue dominate.

Internal light. Add 3 to 5 embedded glow cores per patch, each a small emissive sprite or mesh at low to mid height, warm white-violet. These are emissive, not dynamic lights, to keep cost predictable. At most one low-energy OmniLight3D per patch may be used to catch nearby ship hulls, but the pack does not document an existing per-patch light for nebula, so this is a new addition to be judged in playtest. Do not add per-puff lights.

Motion. Keep the existing GAS_SHADER drift at world_living.gd:31, roughly TIME times 0.012, 0.004, 0.007. Add a slow mask rotation, on the order of one degree per second, and a vertical churn on the mid veil. Foreground wisps move at roughly twice the body drift rate. The motion should read as churn, not as a sliding texture.

Occlusion behaviour. Stars behind the nebula must dim by density, not vanish at a hard boundary. Low-density areas should let stars twinkle through; dense core areas should nearly extinguish them. Ships inside the patch remain visible as rim-lit silhouettes: the glow cores and lit rim provide edge light, and the UI stays on top. The patch must not occlude the tactical hex tint completely; the tint at board.gd:325 should read through the gas at reduced strength.

Readability rules. The nebula must read as concealing, not as smoke. The player should see a soft violet body with internal light and a density gradient, and should be able to tell that a ship inside is still there but harder to hit. At ryan_c07's camera, the patch should no longer look like flat light-grey puffs following hex edges.

2.2 Ion storm (storm)

Layer stack. Four layers.

Dark body at y -4 to 5.5, using the existing _gas path with storm true, near-black base and violet glow cores.

A thin high veil at y 6 to 12, very low alpha, dark violet-grey, to give the storm a top.

Glow cores, sparse and violet, at the current world_living.gd:262-271 colours, but with a slightly brighter rim so the storm reads as active even between bolts.

Lightning ribbons from _bolts at world_living.gd:344, with the bright core and jagged shape already in place.

Colour behaviour. The body must stay near black, as recorded at world_living.gd:262-271: c_dark 0.003, 0.003, 0.006 and c_lit 0.035, 0.028, 0.06, with violet glow cores 0.3, 0.17, 0.62. The legend yellow #ffe866 should appear in the tactical tint and in UI, and in brief bolt-lit highlights, but not as the body colour. The step-2 comment at world_living.gd:265-267 records why: a dark violet still read pale and lavender over near-black skies. Keep that discipline. A desaturated blue-grey rim on the high veil will separate the storm from the nebula without making it pale.

Internal light. Keep the existing bolt lights: the first 4 bolts carry an OmniLight3D with light_energy up to 3.2, catching ships, rocks and gas. Keep the cadence at roughly every 2.2 to 6.5 seconds with a roughly one-third-second envelope, as recorded at world_living.gd:430 and _process at world_living.gd:447-465. Add a low ambient pulse synchronized to each bolt so the whole storm patch briefly lifts in brightness, then falls back. This makes the storm visibly active even when the player is looking at the patch edge.

Motion. Bolts remain jagged ribbons, about 1 per 2 storm hexes and at most 6. Gas churn should be faster than nebula churn, perhaps 1.5 to 2 times the nebula drift, to read as turbulent weather. The high veil should twist slowly, opposite the body drift.

Occlusion behaviour. Stars behind the storm should be mostly occluded, with brief windows during bolts. Ships inside should be dark silhouettes, lit by flashes, not fully invisible. UI stays readable. The storm is a threat, so it is acceptable for it to be visually heavier than the nebula, but it must not strobe the whole screen at 4K.

Readability rules. The storm must read as threatening and active at a glance. Yellow in the tactical tint, near-black body, violet glow, and regular lightning are the four cues. It must not be confusable with the nebula's violet body. The shield-loss and aim penalty at battle.js:398 and battle.js:651 are the gameplay facts the look must support.

2.3 Debris (debris)

Layer stack. Three layers.

Rock layer: 15 to 22 rocks per hex on the living path, mixed sizes, using the existing debris field logic at world_living.gd:469.

Wreck layer: 3 to 5 wreck pieces per hex from the four procedural types recorded at world_living.gd:549-556, some with hot torn edges.

Dust haze: a very low-alpha tan haze at low height, thin enough that stars and ships show through.

Colour behaviour. Base tan #d4bf86. Rock materials should follow the existing biome materials where the rock library supports it. Hot torn edges should be a warm orange-yellow emissive, not a full fire. Dust haze should be tan at roughly 0.05 to 0.08 alpha, low enough not to become smoke.

Internal light. Hot edges are self-emissive. No dynamic lights, or at most one faint flicker per patch if playtest shows the debris reads flat. The pack does not document a debris light today, so this is an optional addition, not a required change.

Motion. Rocks tumble slowly, as recorded in the living debris header at world_living.gd:10-12. Wreck pieces tumble at slightly different rates so the field does not look rigid. Dust drifts very slowly.

Occlusion behaviour. Stars remain visible through the gaps. Ships remain fully visible and readable; debris is light cover, not concealment. The tactical tint at 0.12 alpha should not need to change much, but it should be checked against the new rock density.

Readability rules. Debris must read as physical wreckage, not gas and not smoke. The player should see hard silhouettes, mixed sizes, and occasional hot edges. The contrast with nebula and storm should be obvious: hard, warm, sparse, and transparent between pieces.

2.4 Dead star gravity well

Layer stack. Three layers plus the existing sky treatment.

Lensing ring: the existing WELL_SHADER at world_living.gd:154, a ring of gravitational lensing and slow twist out to the pull range.

Inward ripples: faint concentric ripples running inward, as described in the living-terrain header at world_living.gd:13-14.

Centre glow: a very faint accretion glow or dark core, enough to mark the hazard centre without becoming a light source.

Colour behaviour. Cool blue-violet lensing, a dark centre, and a faint warm accent at the innermost ring. The well is a hazard centre, not a nebula, so it should not use the nebula violet body colour. The tactical tint should mark the pull range separately.

Internal light. A faint self-emissive centre, no dynamic light. The well is about distortion, not illumination.

Motion. Slow twist, with ripples moving inward at a readable speed. The motion should be slower than storm churn and slower than nebula drift, to read as gravity rather than weather.

Occlusion behaviour. Stars near the well should be visibly distorted or refracted, not simply dimmed. Ships inside the pull range should remain visible but should feel the distortion at the edge. UI stays readable. The sky side of the dead star remains backdrop scope and is a hand-off, not part of this task.

Readability rules. The well must read as a hazard centre with a clear pull range. It must not be confusable with the nebula or the storm. The distortion is the signature.

3. Build order as Codex tasks

The sequence puts the largest read improvement first. The pack's file:line facts are authoritative; where the pack is silent on a uniform name or a helper, the task says so.

Task 1: Nebula colour gradient and internal glow (biggest read win)

Files and lines: godot/world/world_living.gd, _gas at 227 to 295, especially the colour block at 273 to 282; godot/fx/faction_look.gd at 15 and 47, key "nebula".

Change: replace the current two-flat-colour treatment with the three-band gradient in section 2.1. Keep the existing density parameter at 0.5 and the existing footprint mask at world_living.gd:298. Add 3 to 5 emissive glow cores per patch at low to mid height. Push the glow-core colour toward the faction sky nebula hue from faction_look.gd:15 and :47, but keep the body recognisably violet.

Judged by: 4K screenshots at the default camera on the storm map and the belt map, compared side by side with ryan_c07. The patch must show a dark core, a mid body, a lit rim, and visible internal glow, and must not read as flat grey smoke.

Estimate: shader and colour work only, no new assets. 1 to 2 days for an experienced Godot shader developer, based on editing an existing shader and tuning colour constants. Playtest iteration is additional.

Task 2: Nebula layering, parallax and star occlusion

Files and lines: godot/world/world_living.gd, _gas at 231 to 246 for puff counts and sizes, GAS_SHADER at 31 for drift, and the render-priority line at 285.

Change: add the mid veil and foreground wisp layers described in section 2.1. Keep the existing body puffs and broad tying puffs. Add density-based star dimming in the shader so stars behind low-density gas twinkle through and stars behind dense core nearly extinguish. Do not change the render_priority blindly; the pack records -5 at world_living.gd:285, and the blend behaviour should be checked against the sky.

Judged by: 4K screenshots at the default camera on the nebula patch, including a view with a ship inside the patch and a view with stars behind it. The patch must read as one body with depth, not a flat card. The ship must remain visible as a rim-lit silhouette.

Estimate: shader and layer work, no new textures. 2 to 3 days, with shader iteration. This is the task most likely to need playtest tuning.

Task 3: Storm body, bolt cadence and active-read

Files and lines: godot/world/world_living.gd, _gas storm branch at 262 to 271, _bolts at 344 to 430, and _process at 447 to 465.

Change: deepen the storm body toward the recorded near-black values if the current build has drifted, add the thin high veil, add the synchronized ambient pulse, and tune bolt cadence and light energy within the recorded range. Keep the yellow legend colour in the tactical tint, not the body. Ensure the storm cannot be mistaken for the nebula.

Judged by: 4K screenshots on the storm map at the default camera, at three moments: between bolts, during a bolt, and just after a bolt. The storm must read as active and threatening, the ships inside must be lit by flashes, and the screen must not strobe.

Estimate: shader and timing work, no new assets. 1 to 2 days, plus playtest iteration for cadence.

Task 4: Debris material and wreck variety

Files and lines: godot/world/world_living.gd, _debris at 469 to 556, including the four wreck types at 549 to 556; rock materials from the existing library referenced by the pack.

Change: implement the three-layer debris stack in section 2.3. Add hot torn edges as emissive material, keep the dust haze very low alpha, and ensure the rock and wreck mix reads as physical wreckage at 4K. Do not turn the dust into smoke.

Judged by: 4K screenshots on the graveyard map at the default camera. The field must show hard silhouettes, mixed sizes, hot edges, and visible gaps. Ships must remain fully readable.

Estimate: mostly material and placement work, no new generated meshes required because the four wreck types already exist. 1 to 2 days.

Task 5: Dead star well distortion and hazard read

Files and lines: godot/world/world_living.gd, WELL_SHADER at 154, and the ripple description in the header at 13 to 14.

Change: strengthen the lensing ring and inward ripples, add the faint centre glow, and make star distortion visible at the edge of the pull range. Keep the well distinct from nebula and storm.

Judged by: 4K screenshots on the deadstar board shape at the default camera, including a view with a ship near the well. The distortion must be visible on stars, the centre must read as a hazard, and the UI must stay readable.

Estimate: shader only. 1 day, plus playtest.

Task 6: Tactical tint harmonisation

Files and lines: godot/render/board.gd, ZONE_TINT at 325.

Change: adjust the nebula, debris and storm tint alphas so the new gas does not fight the hex UI. The pack records nebula alpha 0.16, debris 0.12 and storm 0.13. The likely direction is to lower nebula and storm alpha slightly and let the gas itself carry the colour, but this should be judged against screenshots rather than guessed.

Judged by: 4K screenshots in tactical view with the new gas and the tint on. The hexes must remain readable as gameplay zones without turning the gas into flat coloured tiles.

Estimate: tuning only, half a day.

Task 7: Quality scaling and LOD pass

Files and lines: godot/world/world_living.gd, _gas at 227 to 246 where the pack records 5 puffs per hex at full quality and 3 at low quality, and the bolt count in _bolts.

Change: define a quality ladder that reduces puff counts and bolt light usage before it reduces presence. The pack already records a low-quality puff count, so this is an extension, not a new system. Do not reduce the density gradient or the glow cores at low quality, because those carry the read.

Judged by: frame-time capture on the storm and graveyard maps at 1080p and 4K, plus screenshots at low quality to confirm the effect still reads. The pack is silent on the frame-time budget, so the task should record measured frame time rather than assume a target.

Estimate: 1 to 2 days, with profiling.

4. Effort notes

All hour and day figures above are estimates. The basis is the scope of the existing functions named in the pack: _gas is already a working shader path, _bolts already exists, _debris already has four wreck types, and WELL_SHADER already exists. The work is therefore modification and tuning, not greenfield systems. No terrain gas texture assets are required; the pack states there are no texture files for terrain gas and everything is procedural. The only new assets are optional glow-core sprites or meshes, and those can be generated or authored as simple emissive geometry.

Shader-only: Tasks 1, 2, 3, 5, 6 and the shader portion of 7. Material and placement: Task 4. Playtest iteration: all tasks, especially 2 and 3. Performance profiling: Task 7. The estimates do not include the chair's synthesis time or the time to capture and review 4K screenshots.

5. Owner questions

Q1. Should the nebula stay physically dark, or should it carry a stylized violet glow so the legend colour is unmistakable at 4K?

Chair pick: stylized violet glow with a dark core. Trade-off: readability and legend consistency win over strict physical darkness; the risk is that the nebula looks less "realistic" and more game-like. The owner's complaint is that the current gas reads as grey smoke despite the violet legend, so a visible violet identity is the safer fix.

Q2. Should ships inside a nebula be fully hidden, or remain visible as rim-lit silhouettes?

Chair pick: rim-lit silhouettes, with the hit-chance penalty carrying the concealment. Trade-off: the player keeps tactical readability and can still select ships, but the nebula feels less like total concealment. Full hiding would be more dramatic but would fight the 4K readability rule.

Q3. Should storm lightning light the whole board, or stay local to the storm patch?

Chair pick: local, with a brief ambient pulse inside the patch only. Trade-off: local lightning preserves drama without strobing the whole screen or distracting from other battles; a board-wide flash would be more spectacular but risks readability and comfort at 4K.

Q4. Should debris get hot glowing torn edges, or stay cold and purely physical?

Chair pick: subtle hot edges on a minority of wreck pieces. Trade-off: hot edges add life and help debris read as recent wreckage rather than rocks, but too much glow turns debris into a light source and blurs the line with the storm. A subtle treatment keeps the "light physical cover" read.

Q5. Should the tactical hex tint stay strong under the new gas, or be reduced so the gas itself carries the terrain read?

Chair pick: reduce tint alpha and let the gas carry the read, while keeping a faint tint for gameplay zoning. Trade-off: reducing the tint makes the board more immersive and less like a board game, which addresses R70, but it weakens the at-a-glance hex boundary. The owner may prefer stronger zoning for competitive clarity, which is why this needs his call.

6. Not checked

Sins of a Solar Empire 2's internal rendering technique for in-play gas or storms is not documented in any source I could verify. I could not confirm whether Sins 2 even has board-level gas zones in the sense this job means; the public record is about skyboxes and backdrop clouds.

Battlefleet Gothic: Armada 2's in-play gas cloud rendering technique is not documented. I found gameplay descriptions and the procedural environment dev diary, but no shader, layer or lighting details. My account of its technique is labelled INFERRED.

Homeworld 3's exact layer count, ray-march sample count, and the number and type of light sources embedded in a nebula are not public. The documented statements cover the method and gameplay coupling, not the implementation constants.

EVE Online's exact rendering path for harvestable gas cloud sites is not documented separately from the general volumetric cloud pipeline. I could not verify whether the site clouds use the same VDB path as the newer volumetric clouds.

The pack does not state a frame-time budget or a target GPU for terrain effects, so the performance task should measure rather than assume.

The pack is silent on the exact uniform names and helper functions inside GAS_SHADER, CLOUD_SHADER and WELL_SHADER beyond what is cited. The build tasks name the functions and line ranges but do not invent uniform names.

I did not verify the current build's actual visual output against the screenshots. The per-kind spec is grounded in the pack's description of the code and the owner's screenshots, not in a fresh run of the game.
