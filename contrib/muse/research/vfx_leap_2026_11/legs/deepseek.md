Headline and ranked leaps

The three highest-leverage moves, in owner order:

1. Deaths and hits: stop treating the death as a single explosion event and build a staged structural break-up chain ,  flash -> venting plumes -> pre-fractured hull separation -> momentum-preserving tumble -> blackbody cooling ,  with offline-baked volumetric flipbooks replacing the single raymarched fireball as the default gas language. The raymarched fireball is not the problem; it is the only photoreal element in a stylized scene, and it is doing the wrong job. Homeworld 3's biggest jump came from procedural mesh breaking and damage sockets, not from more volumetrics. [reference:1]

2. Nebulas and storms: replace the MultiMesh billboard body with local FogVolumes running a custom fog shader that samples a baked 3D noise texture, keeps the R82 violet ramp and 25% faction-tint cap, and accepts local light injection (lightning, ship lights, explosion flashes). Keep the existing billboard veils as a high-frequency edge layer so ships stay crisp inside gas. This is the one area where the Opus hypothesis is most clearly correct.

3. Planets (terran and rocky first): the resolution is already sufficient; the surface model is not. Replace the single-channel FBM value-noise bake with a multi-layer offline terrain stack ,  continental/tectonic mask, hydraulic-erosion ridge layer, biome/climate mask, crater/river detail ,  and ship normal, AO, and curvature alongside albedo. Bake in Blender with free tools; use CC0 rock/sand/scree textures for close-frequency detail. Elite Dangerous and Star Citizen both show that the perceived quality comes from feature structure and material response, not texel count. [reference:144] [reference:145]

Hypothesis verdict (Opus, to test and not confirm)

Where it holds: the nebula billboard model is the exact failure case Opus describes ,  flat quads sampling a noise field, no true volume and no internal light transport. Moving to FogVolume with a custom fog shader is a genuine engine-feature leap, not tuning. The planet surface is also a code-made FBM texture with no geological feature structure; offline erosion and biome baking is the right jump. For weapon hits, moving from capped decals to baked wound-mask atlases and local breach effects is also an offline-asset leap.

Where it does not hold: the death system is not "mostly flat sprites and code-made textures." The fireball at fx_shaders.gd:1626 is a raymarched volumetric and is already the most photoreal element in the scene. The owner's complaint is therefore not "we lack volumetrics" but "the volumetric we have is at a different fidelity and does not obey a space-death grammar." Adding more raymarched volumetrics everywhere would make the mismatch worse. The jump is art-directed offline gas plus structural geometry ,  pre-fractured hulls, event sequencing, and a deliberate reduction in detail frequency ,  not a wholesale conversion to real-time volumetrics.

Also missed by the hypothesis: Homeworld 3's signature destruction leap came from a Houdini procedural Ship Breaking tool that generated debris meshes and modelled internal rooms and mechanisms, not from a shader. Geometry and event choreography matter as much as volumetrics. The existing worker-thread break-up cuts in fx_death.gd are an asset; the leap is to make them the visual spine rather than a hidden optimisation. [reference:1]

1. Ship deaths and weapon hits

1.1 What the best shipped space games actually do

Homeworld 3 (Blackbird Interactive). The most directly relevant reference because it is an RTS at a comparable camera distance. Senior FX Artist Tim O'Connell's breakdown describes four distinct weapon damage types (Kinetic, High Explosive, Energy, Ion), each with its own visual treatment, and a "Splat Damage" system that does not just place decals: it creates dynamic impact points that alter the surface geometry and material properties of the hull in the exact area hit, with a per-ship dynamic damage texture that transitions from surface scars to hull breaches and burn marks. Fighters use a camera-facing smoke sprite at low speed and switch to an inky ribbon trail at high speed to avoid the "popcorn" puff problem; larger ships use damage sockets placed around the hull and damage stages (light, heavy, critical, destroyed) to spawn smoke, fire, breach FX and sparks. The wreckage system is a procedural Houdini Ship Breaking tool that simulates how a hull collapses under an explosion, models internal rooms and mechanisms, warps and crinkles them so they bulge outward, and generates debris meshes dynamically rather than hand-modelling them. Persistent wrecks are a gameplay object (salvage) as well as a visual one. [reference:1]

EVE Online (CCP Games). The GDC 2024 talk "Reigniting Stars: A Decade of VFX in EVE Online" by Andre Bragason documents the 2015 visual damage system and the 2016 explosion system: explosions spread according to the ship's damage locations, and the team moved from a classical centre-flare-plus-point-light approach to 3D explosions built from multiple parts that read well from close and from up to 600 km away. The explosion language is tonnage-scaled: a frigate gets a fast flash of the reactor going up, shock rings and debris; a battleship gets a slower, larger bi-directional flash (described as looking like a bright planetary nebula), big shock rings and debris. Damage-type colour is also differentiated (thermal red, kinetic standard plus more particles). [reference:25] [reference:26] [reference:29]

Sins of a Solar Empire II (Ironclad/Stardock). The Ruins of War update added custom wreckage for every capital ship, titan and starbase, collectable by the victor, replacing generic large-unit wreckage. The sound design deliberately rejects vacuum realism and lets explosions be cinematic. But the player record is a cautionary tale: hull hits were criticised for barely changing the ship (no bullet holes, burn holes, sparks or system failures), destroyed ships simply disappeared, and capital-ship deaths caused frame rates to drop from a stable 45 fps to 20-25 fps. The lesson is that wreckage alone is not enough; the hit feedback and the death performance envelope matter at RTS scale. [reference:11] [reference:17]

Battlefleet Gothic: Armada 2 (Tindalos). The documented language is a massive engulfing final explosion, with shields bursting back into life on recharge and a very heavy particle density across the battle. The technique appears to be sprite/particle-based rather than mesh-breaking, and the reviews consistently praise the spectacle rather than the physicality. It is a useful reference for scale of flash and shield-impact readability, not for structural break-up. [reference:19]

The Expanse (visual reference, not a game). The show's language is the strongest anchor for the owner's "does fire work like that in space?" question. Its explosions are dominated by blue plasma clouds from the Epstein drive, not sustained yellow-orange combustion; sustained flame appears where oxygen is present, such as an electrical fire inside a pressurized shuttle. Ships routinely vent atmosphere before combat so a hull breach is limited to the projectile's diameter rather than explosive decompression. The show also uses a destruction language where a ship appears to "explode" outward into its component parts, like it was disassembled rather than torn apart by a conventional blast. That is the visual grammar to steal: venting, flash-and-snuff, component separation and momentum, not a long-burning fireball. [reference:33] [reference:34] [reference:36]

1.2 The technique that gives a 50-75% jump

The leap is not a better fireball shader. It is a two-part change:

Technique A ,  offline-baked volumetric flipbooks as the default gas language, with the raymarched fireball demoted to a rare reactor-critical event. Bake high-resolution fire/smoke/plasma simulations in Blender Mantaflow (gas domain, smoke + fire, low-res test then high-res bake) and render them as flipbook atlases (e.g. 8x8 frames at 10242 or 20482 per frame). Import into GPUParticles3D with soft particles, depth fade and flipbook animation. Godot's documentation explicitly recommends Blender or EmberGen for pre-rendered particle flipbooks for smoke, fire and explosions. This gives film-quality gas shapes at a fraction of the per-pixel cost of a raymarch, and ,  critically ,  it lets the FX artist art-direct the shape of the flash-and-snuff rather than relying on a procedural volume to be both physically plausible and stylistically coherent. The raymarched fireball at fx_shaders.gd:1626 can be retained for the one event where a volumetric is worth it (a reactor breach or capital-core detonation), but it should no longer be the default hull-death effect. Keeping it everywhere is the fidelity mismatch the owner is reacting to. [reference:52]

Technique B ,  a staged structural break-up chain driven by pre-fractured geometry and a single explosion epicentre. Pre-fracture each capital hull in Blender into 4-8 logical chunks (cell fracture plus manual cuts along existing seams), assign each chunk a mass and a pre-authored impulse response, and drive a timed event graph: (1) a sub-frame white flash and a fast-expanding shock ring; (2) venting plumes from breach points; (3) hull separation along the existing worker-thread cut planes, with chunks inheriting the parent's linear and angular momentum plus a radial impulse from the epicentre; (4) tumbling and collision with Jolt; (5) blackbody cooling on the wreck material. This is the direct analogue of Homeworld 3's Houdini Ship Breaking insight ,  model the internal structure and let the break be a structural event, not a particle pop ,  and of The Expanse's "disassembled outward" language. The existing fx_death.gd already computes break-up cuts on a worker thread and splits capitals into two sealed halves; the leap is to make that the visible spine, increase the chunk count for capitals, and choreograph the reveal over 1.5-3 seconds instead of a sudden swap. [reference:1] [reference:34]

Secondary technique for weapon hits ,  "Splat-lite." Homeworld 3 alters surface geometry at impact points. We cannot afford runtime geometry deformation at 360 debris, but we can move from "12 decals per ship" to a baked per-section wound-mask atlas (albedo, normal, roughness, emissive heat) plus a short-lived decal for the freshest hit, a local point light, a spark burst, and a brief breach plume. The material response changes, not just the sticker. This is the 50-75% jump over the current capped decal system at fx_breach.gd and fx_ship.gd. [reference:1]

1.3 How we build it here (Godot 4.7, free tools, RTX 5080)

Blender flipbook pipeline.

Create a gas domain, emitter shaped like the breach or hull volume, low-res bake to validate timing, then high-res bake. Render the volume with a transparent film and a fixed orthographic camera into an 8x8 atlas. Export as PNG/EXR, import to Godot as a texture. Use GPUParticles3D with a ShaderMaterial that steps UV through the atlas per particle lifetime; set fixed_fps to 30 for background/ambient deaths to halve particle update cost (documented Godot optimisation). [reference:135]

Author three atlases per death class: a short white-hot flash, a venting gas plume, and a cooling smoke wisp. This is the art-directed language, not a generic fireball.

Pre-fracture pipeline.

In Blender, cell-fracture one representative hull per class into 5-8 chunks; keep the existing in-engine cut planes as the coarse split. Export each chunk as a separate mesh with a convex-hull collision shape. Bake a per-vertex heat mask (distance from the epicentre) into vertex colour or a UV channel. The existing fx_death.gd debris pool (capped at 360, 4 variants) can be extended to 6-8 variants for capitals without changing the cap.

Event graph.

A small Resource-driven timeline per death class: flash, vent, break, tumble, cool. Each step is independently shippable and screenshot-judgeable. The flash budget at fx.gd:22-25 (3 counted flashes per rolling second) is respected by making the flash a single counted event per death and keeping the vent/tumble steps uncounted.

Weapon hits.

Use Godot Decal nodes for the freshest impact (Forward+ supports decals; they can be moved every frame and faded with an AnimationPlayer, then queue_free()d). Bake wound masks into the three damage sections in fx_ship.gd so old marks persist without active decals. Respect the 512 clustered-element limit: decals count against that budget, so 20 ships x 36 decals would exceed it; fading and merging old marks into the section atlas is mandatory. [reference:161] [reference:167]

Quality tiers.

Max: flipbook deaths + full chunk count + local FogVolume venting + decals for fresh hits.

High: flipbook deaths + reduced chunk count + sprite venting.

Low: existing sprite/ribbon path with a single flash and no volumetrics. The scene volumetric fog is already disabled at low in battle.gd:333-360; keep that.

1.4 Frame cost against 60 fps at 4K (cost drivers and rough budgets, not invented benchmarks)

Flipbook particles: a 10242 8x8 RGBA atlas is 64 MB uncompressed, 16 MB in BC3. Sampling one texture per particle is cheap; the cost is overdraw. Large soft particles at 4K are fill-rate heavy. Budget 200-400 large particles for a capital death, with soft-particle depth fade and a distance-based size clamp. Rough budget: 1-2 ms GPU for the first 1-2 seconds of a capital death, near zero after the particles fade. INFERRED.

Pre-fractured chunks: 5-8 chunks per capital plus the existing 360-body cap. Jolt handles the bodies; the cost is draw calls and physics, not shading. Current cap is fine; the leap is spending more geometry in the first 2 seconds and letting distant wrecks sleep. Rough budget: <0.5 ms additional physics for a typical 10-20 ship battle. INFERRED.

Local FogVolume venting: Godot's docs state FogVolume performance scales directly with relative screen size and material complexity, and recommend keeping them small and simple. Use 3-5 small volumes (a few metres) per death, not a scene-scale volume. Rough budget: 0.5-1 ms at max tier. INFERRED. [reference:43]

Decals: the 512 clustered-element limit is the hard constraint. Keep active decals under ~100 in a 20-ship fight by fading old marks into section atlases. Decal rendering itself is cheap; the limit is the risk.

Flash budget: keeping 3 counted flashes/sec means the new flash must be a longer, dimmer, coloured event, not a brighter pop. No additional frame cost; it is a discipline constraint.

1.5 Build order (each step independently shippable and screenshot-judgeable)

Define the death grammar and capture references. Write a one-page event timeline (flash -> vent -> break -> tumble -> cool) and a palette card. Capture Homeworld 3, EVE and The Expanse frames as the visual target. No code.

Bake one flash and one venting plume in Blender Mantaflow; import as a GPUParticles3D flipbook. Replace the raymarched fireball in fx_death.gd at max tier for one ship class. Screenshot the same death before/after.

Pre-fracture one capital hull into 5 chunks; wire the existing worker-thread cuts to the staged event graph. Add heat masks and a blackbody cooling ramp. Verify momentum inheritance and tumbling.

Add local FogVolume venting at breach points and GPU spark/debris bursts. Cap by distance and quality tier.

Replace decal-only weapon marks with the wound-mask atlas + freshest-hit decal hybrid. Test a 20-ship battle at 4K; confirm the decal count stays under the clustered limit.

Art-direction pass: compare death, gas and planet frames side-by-side with ship frames; reduce detail frequency where the effect out-resolves the hull.

1.6 Current-code anchors

godot/fx/fx_death.gd (1,388 lines): capital break-up cuts, sealed halves, 14 s cooling wrecks, debris physics bodies, 360 cap, 4 variants.

godot/fx/fx_shaders.gd:1626: raymarched fireball / venting plume shader ,  the fidelity-mismatch suspect.

godot/fx/fx_ship.gd: 3 damage sections per ship, damage ladder.

godot/fx/fx_breach.gd (1,844 lines): wound shader, marks capped at 12 per ship.

godot/fx/fx_weapons.gd (1,170 lines): volleys, muzzle sprites, torpedo meshes, streaks.

godot/fx/fx.gd:22-25: at most 3 counted flashes per rolling second.

godot/scenes/battle/battle.gd:333-360: max/high/low quality tiers; volumetric fog disabled at low.

2. Nebulas and ion storms

2.1 What the best shipped space games actually do

Homeworld 3. The modding guide exposes the shipped architecture: nebulae are BP_VolumetricNebula actors built from a volume mesh and a material instance, with a density threshold that determines when a ship is considered "inside" the gas for gameplay effects. The developers describe using fractal volume density near the core to create interest and shape, and "clouds of realistically simulated gas" rather than a flat backdrop. The game also uses advanced real-time lighting and fog so ships can hide inside gas clouds. This is a true volumetric representation with gameplay-coupled density, not a billboard field. [reference:61] [reference:67]

EVE Online. The GDC talk focuses on ship VFX and damage rather than nebula rendering; I found no sourced technical breakdown of EVE's nebula volume. INFERRED: EVE's nebulae read primarily as backdrop/skybox phenomena plus local light scattering, and the talk does not provide a transferable volumetric-gas technique. Do not cite EVE as a nebula-volume reference without further evidence.

Sins of a Solar Empire II. No sourced nebula-volume breakdown. Its gas/ion effects read as 2D layer composites and particle storms at RTS distance; not a strong reference for true volumetrics.

The strongest shipped reference is therefore Homeworld 3: volume mesh + material + density threshold + local lighting, with the gas participating in gameplay.

2.2 The technique that gives a 50-75% jump

Replace the MultiMesh billboard body in world_living.gd with local FogVolumes running a custom fog shader that samples a baked 3D noise texture and accepts local light injection. Godot 4.x FogVolume is designed exactly for this: it adds localized fog into the global volumetric fog, can use a built-in FogMaterial or a custom ShaderMaterial, and its performance scales with screen size and material complexity. Fog shaders are compute shaders called once per froxel touched by the volume's AABB, with WORLD_POSITION, OBJECT_POSITION and UVW built-ins for 3D texture mapping. This is the engine-feature leap Opus identified. [reference:43] [reference:45]

Do not use one map-spanning FogVolume. A single giant volume is the worst case for froxel cost and will destroy the 4K budget. Use a hybrid: several medium FogVolumes covering the gameplay-relevant gas bodies, with the existing billboard veils retained as a high-frequency edge layer to preserve ship silhouette crispness (the R82 rule). The volume provides internal light transport, parallax and true depth; the billboards provide the fine, high-contrast edge detail that froxels cannot resolve at 4K. This hybrid is the honest 50-75% jump, and it is the only way to satisfy both the fidelity goal and the crisp-ships-inside-gas ruling.

Shader requirements:

Keep the four-stop violet ramp (dark, shadow, lit, glow) and the 25% faction-tint cap at the ramp ends, exactly as the current shader comments require. The colour design is settled; do not reopen it.

Sample a baked 3D FBM noise texture (e.g. 1283 R8, tileable) with two scales and a domain-warp offset for shear. This replaces the per-vertex world-space noise sampling with a true 3D field.

Accept local lights: lightning bolt lights, ship running lights, explosion flashes. Godot's volumetric fog interacts with lights and shadows; the current deliberate exclusion of lightning from scene fog is the thing to remove at max tier. [reference:89]

Add a depth-aware density falloff near the camera and near ship silhouettes to avoid the "soup" look and keep ships crisp.

Storms: use a separate fog-shader variant with an emissive density term for the glow cores and ribbon lightning driven by the same 3D noise field, rather than billboard ribbons. The shield-tick flare can remain a decal/sprite because it is a surface event, not a volume event.

2.3 How we build it here

Bake a tileable 3D noise texture. Blender can bake a 3D texture from a noise node tree, or write a small Godot compute shader to generate FBM into an ImageTexture3D. 1283 R8 is 2 MB; 2563 is 16 MB. Prefer 1283 with a second octave added in the shader.

Author the custom fog shader. Start from God's fog shader template; use UVW to sample the 3D texture, WORLD_POSITION for world-space shear, and OBJECT_POSITION for volume-local falloff. Keep the violet ramp constants in one uniform block so the R82 values are auditable.

Prototype one nebula patch. Replace one patch's MultiMesh with a FogVolume (box or ellipsoid shape) and compare at 4K. Tune density, falloff and light response against the billboard version. This is the screenshot-judgeable step.

Add local lights. Enable lightning and explosion flashes to affect the volume at max tier; disable at high/low. Verify the R82 crisp-ship rule with a depth-aware composite pass.

Storms. Clone the fog shader into a storm variant with emissive cores and noise-driven lightning ribbons; keep the shield-tick flare as a sprite.

Quality tiers. Max/high: FogVolumes + billboard edge layer. Low: existing billboard-only path. The transition must be invisible at normal camera distance.

2.4 Frame cost against 60 fps at 4K

FogVolume froxel cost scales with screen coverage and volume depth. A medium volume covering ~20-30% of a 4K frame with a simple custom shader is the realistic target; a map-spanning volume is not. Rough budget: 1-3 ms GPU for 2-3 medium volumes at max tier, <0.5 ms at high. INFERRED.

Temporal reprojection significantly reduces the samples needed for smooth fog; enable it as the default volumetric fog filter. This is the main lever for keeping the 4K cost down. [reference:44]

3D texture sampling is cheap relative to the froxel cost; the dominant cost is the number of froxels and the number of local lights interacting with them. Cap lightning lights to 1-2 simultaneous shadowed lights at max tier.

Billboard edge layer remains cheap (the current MultiMesh path) and should stay enabled at all tiers as the crispness guarantee.

2.5 Build order

Bake the 3D noise texture and author the fog shader with the R82 ramp constants. No scene change.

Replace one nebula patch with a FogVolume; capture 4K before/after and verify colour parity.

Add local light injection (lightning, ship lights, explosion flashes); verify crisp ships inside gas.

Convert storms to the storm fog-shader variant.

Wire quality tiers: max/high volumes, low billboards. Profile a full battle at 4K.

Art-direction pass: match gas detail frequency to the painterly ships; the gas should read as large soft masses with sparse high-frequency accents, not photoreal turbulence.

2.6 Current-code anchors

godot/world/world_living.gd (1,008 lines): MultiMesh billboard quads, 5 puffs per terrain hex plus tying veils, one world-space 3D noise field, per-patch mask texture, four-stop violet ramp, NEBULA_FACTION_END_WEIGHT comment for the R82 25% cap.

Storms share the gas path: near-black body, glow cores, ribbon lightning, shield-tick flare.

godot/scenes/battle/battle.gd:333-360: volumetric fog disabled at low; the new volumes must follow the same tier logic.

3. Planets, especially rocky and terran

3.1 What the best shipped space games actually do

Elite Dangerous (Frontier). The most technically documented planetary system. Doc Ross's 80.lv breakdown explains that planets start as cubes of square patches, are spherified by a mathematical function, and the terrain is generated from noise graphs whose inputs include the planet's position and unique ID. The top-down Stellar Forge simulation determines planet classification, tectonic activity, volcanism, basins, mountains, fissures, craters, perma-ice and snow, and those parameters modulate the noise functions that form geological shapes. Artist-generated textures for rock, sand and scree are blended by terrain gradient, so the surface has material response, not just albedo. The Frontier developer discussion confirms the cube-to-sphere patch approach and the use of two main noise graphs, with rocky-ice worlds using a separate icy graph. [reference:151] [reference:154] [reference:155]

Star Citizen (Cloud Imperium). Planet Tech V5 is described as a complete rework of how planets are built, populated and rendered, with emergent biomes driven by realistic physical properties, terrain shading across materials (sand, rock, etc.), procedural scattering, rivers driving terrain modification, and tessellation/hardware displacement. The key transferable idea is the biome/material rule layer on top of the height field, not the specific technology. [reference:144] [reference:145]

The lesson for a backdrop planet at 4096x2048: the perceived quality comes from feature structure ,  continents with coasts, mountain ranges with erosion, river networks, biome boundaries, and a material response that changes with slope and altitude ,  not from more noise octaves or a larger texture. The current world_planet.gd bake has value-noise continents with no ranges, coasts, rivers or biome detail, and a single baked relief channel. That is the gap.

3.2 The technique that gives a 50-75% jump

Replace the single-pass FBM bake with a multi-layer offline terrain stack, baked once per planet kind in Blender:

Continental/tectonic mask: low-frequency noise shaped into plates or hand-authored continent silhouettes. This gives coherent landmasses and coasts rather than noise blobs.

Erosion/ridge layer: hydraulic erosion or ridged multifractal noise to produce mountain ranges, valleys and sediment fans. Blender's geometry-nodes erosion or a heightfield erosion simulation can bake this; free terrain tools such as Gaea and World Machine also provide erosion and mask outputs, though their licensing and resolution limits need checking for commercial use. Blender is the safest free-tool anchor. [reference:104]

Biome/climate mask: latitude + altitude + moisture rules to place deserts, forests, tundra, ice caps, and river networks. This is the Star Citizen "emergent biomes" idea reduced to a bake-time rule set. [reference:144] [reference:145] [reference:146]

Detail layer: crater field for barren/rocky worlds, river channels and coastal detail for terran, and a high-frequency rock/sand/scree detail texture blended by slope. Use CC0 textures from ambientCG or Poly Haven for the close-frequency material detail; this is the free-texture equivalent of Elite's artist-generated rock/sand/scree maps. [reference:155]

Bake outputs: albedo, height, normal, AO, roughness, ocean mask, cloud mask, biome mask. The sphere shader then uses normal mapping, AO and slope-based detail blending, plus a parallax/displacement silhouette on the limb at high tier to give real relief at grazing angles. The 4096x2048 resolution is sufficient; the jump is the feature structure and the material response.

3.3 How we build it here

Blender bake rig: a subdivided sphere (or cube-sphere) at 4096x2048-equivalent resolution, with a node graph for continents, erosion, craters, rivers and biome masks. Bake to equirectangular textures with Cycles or Eevee. Keep the bake deterministic per planet seed.

Erosion: Blender geometry-nodes erosion or a heightfield erosion node group; if the result is too soft, add a ridged multifractal layer and a slope-aware mask. Bake at 2x resolution and downsample for anti-aliasing.

Detail textures: download CC0 rock/sand/scree/vegetation atlases, tile them in the sphere shader by slope and biome, and blend with the baked albedo. This is the free-asset equivalent of Elite's artist textures.

Sphere shader: extend the existing shader in world_planet.gd with normal mapping, AO, roughness, slope-based detail, and optional parallax on the limb. Keep the existing terminator, cloud shadows, ocean glint, night lights, lava and ring shadows ,  those are already good.

Scope: do terran and rocky/barren first (the owner's complaint), then volcanic desert. Gas giants and ice giants can stay on the existing path if they read acceptably; their surfaces are dominated by banding and storms, not erosion.

Bake size ruling: keep the Job 10 sizes ,  4096x2048 backdrop planet, moons 1024x512. Do not reopen.

3.4 Frame cost against 60 fps at 4K

Runtime cost is trivial. A backdrop planet is one sphere with a baked texture set. Adding normal, AO, roughness and a few detail texture samples adds 3-6 texture fetches; at 4K, with the planet covering perhaps 1-2 million pixels, this is well under 0.5 ms on an RTX 5080. Parallax on the limb adds a few extra samples only at grazing angles; tessellation/displacement can be restricted to the closest LOD. INFERRED.

Offline cost is the real budget. Erosion simulations at 4096x2048 can take minutes to hours per planet kind. This is a one-time bake per kind, not per instance. Budget artist/technical time for the rig and iteration, not runtime frame time. INFERRED.

Memory: a 4096x2048 RGBA albedo is 32 MB uncompressed; normal/AO/roughness add more. With BC7/BC5 compression, a planet set is roughly 40-80 MB. On a 16 GB card with a fleet battle, this is acceptable for a handful of unique planet kinds; share texture sets across instances of the same kind.

3.5 Build order

Build the Blender terrain bake rig for one terran planet: continents, erosion, rivers, biome masks. Bake albedo, height, normal, AO, roughness, ocean mask.

Import and render one planet in Godot with the extended sphere shader (normal + AO + slope detail). Compare side-by-side with the current bake at 4K.

Add CC0 detail textures and slope/biome blending; verify no tiling artefacts at the camera distance.

Repeat for rocky/barren with the crater field and a separate detail palette; then volcanic desert if time allows.

Add limb parallax/displacement at high tier; confirm the silhouette reads as relief at grazing angles.

Art-direction pass: match the planet's detail frequency and palette to the painterly ships; avoid photoreal terrain that out-resolves the fleet.

3.6 Current-code anchors

godot/world/world_planet.gd (351 lines): sphere shader with terminator, cloud shadows, ocean glint, night lights, lava, limb haze, ring shadows.

godot/world/world_bake.gd:10: 4096x2048 planet bake, moons 1024x512; FBM value noise up to 8 octaves, 3D cell crater field, six planet kinds.

The bake channels already carry albedo, ocean mask, clouds, city lights, relief and lava glow; the leap is to enrich the relief and add material channels, not to change the resolution.

4. Shared art direction

One set of rules so deaths, gas and planets sit at the same fidelity as the painterly ships.

Palette.

Gas: the settled four-stop violet ramp (dark, shadow, lit, glow), faction tint capped at 25% at the ramp ends. Do not introduce new nebula hues.

Hot metal: white (about 1500 K+) -> yellow-orange -> red -> black. Use a blackbody ramp, not an artist-picked orange.

Plasma: reserve blue/cyan for drive plasma and reactor events, following The Expanse's blue Epstein-drive clouds. Hull damage should not default to blue. [reference:36]

Shadows in effects should pick up the violet ambient of the scene, not neutral black, so effects sit in the same colour world as the gas.

Contrast.

Ships are mid-contrast and painterly. Effects must not be HDR-blown photoreal. Cap the brightest flash at roughly 4-8x the ship's lit value, not 100x. The current raymarched fireball is likely exceeding this and is the visible mismatch.

Use a filmic tonemap and verify the death frame against a ship frame at the same exposure.

Detail frequency.

Ships have broad painted shapes with moderate detail. Effects should use large soft shapes (flipbook gas, volume) and sparse high-frequency accents (sparks, debris, lightning ribbons). Do not use dense photoreal smoke turbulence that out-resolves the hull. The fix for the fireball is partly to reduce its detail frequency and colour temperature, not only to replace it.

Gas volumes should read as soft masses with fractal edges; planets should have feature-scale structure (ranges, coasts) with material detail at a frequency below the ship's panel lines.

Motion language.

Everything inherits momentum. No effect should "pop" in place. Deaths are a chain: flash -> vent -> break -> tumble -> cool. Gas drifts and shears; sparks fly straight and fade; debris tumbles slowly with angular momentum. Use ease-out curves and long tails.

The Expanse anchor: venting atmosphere, flash-and-snuff, and component separation are the grammar; sustained flame is the exception, not the default. [reference:33] [reference:36]

Should fire burn like that in space?

No, not as the default. Sustained orange flame requires an oxidiser; in vacuum, the dominant visual is a brief flash, an expanding shell of gas/plasma, hot metal cooling, and sparks. The Expanse's blue plasma clouds and venting are the physically motivated reference. Homeworld 3 still uses stylized fire and smoke, but it is art-directed and damage-staged rather than a generic fireball. Recommendation: no long-burning orange fireballs on hull hits; use flash + venting + cooling metal + sparks, with fire reserved for pressurized compartments or drive/reactor events. [reference:1] [reference:36]

5. Owner questions (five, with picks)

Q1. Nebula fidelity vs. crisp ships: hybrid (FogVolume body + billboard edge layer) or all-volume?
Pick: hybrid. The R82 ruling requires ships stay crisp inside gas; a pure FogVolume at 4K will either soften silhouettes or require a froxel resolution that eats the frame budget. Cost of all-volume: either a visible crispness regression or a large performance cost. The hybrid is the only option that satisfies both.

Q2. Do we replace the raymarched fireball entirely, or keep it for rare events?
Pick: keep it only for reactor-core / capital-critical detonations at max tier; use baked flipbooks for all other deaths and vents. Cost of keeping it everywhere: the fidelity mismatch the owner identified persists, and the raymarch cost is spent on the wrong events. Cost of removing it entirely: we lose the one genuinely volumetric hero moment. The rare-event compromise is the best value.

Q3. Death frame budget: spend it on the first 2 seconds (flash/vent/break) and simplify the 14 s cooling tail, or keep the long tail?
Pick: spend on the first 2 seconds; make the tail a cheap shader. At RTS distance the player reads the break and the initial tumble, not the 14 s cooling. A cheaper tail buys budget for the structural chain that actually sells the death.

Q4. Planet re-bake scope: all six kinds, or terran + rocky first?
Pick: terran and rocky/barren first, then volcanic desert. These are the owner's named complaint and the highest-visibility surfaces. Gas giants and ice giants are dominated by banding and storms, not erosion; they can stay on the existing bake until the new pipeline is proven. Cost of all six: more bake time and a higher risk of delaying the visible win.

Q5. Lightning and storm lights: allow them to interact with the new FogVolume at max tier, or keep them out of the fog?
Pick: allow interaction at max tier, disable at high/low. The current exclusion of lightning from scene fog is a fidelity ceiling; letting the bolts light the gas is a visible jump. The cost is a few more shadowed lights in the froxel grid, which is affordable on the 5080 at max tier but not at high/low.

6. Not checked / limits

I did not find a checkable technical breakdown of Battlefleet Gothic: Armada 2's explosion rendering; the claims about its visual language are from reviews, not a developer talk or art breakdown.

I did not find a nebula-specific volumetric breakdown for EVE Online; the GDC talk covers ship VFX, damage and stars, not nebula volumes. Do not cite EVE as a nebula-volume reference.

I did not find a developer breakdown for Sins of a Solar Empire II's ship-death rendering; the evidence is patch notes, player reports and sound-design journals, not an FX talk. Its value is as a cautionary performance/readability reference, not a technique reference.

Frame-cost figures are INFERRED cost-driver budgets, not measured benchmarks. They should be validated with a GPU profiler on the target 5080 at 4K before the build order is committed.

Blender Mantaflow bake times and erosion bake times are INFERRED; they depend on resolution and iteration count and should be scoped with a small test bake first.

The Godot documentation cited is 4.x (4.1-4.4), while the project is on 4.7. FogVolume, custom fog shaders and decals are present in the 4.x line, but the exact 4.7 property names and defaults should be checked against the 4.7 class reference before implementation.
