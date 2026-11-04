Chair screening note (Rey): Argon ran at Argon High, verified in the picker and prompt bar before sending and in the prompt bar after. This review is used in large part, which is unusual for Argon, because its central claims are checkable and specific. Its source audit is the backbone of the chair screening: it verifies DeepSeek's bibliography item by item with dates and names, and it identifies Qwen's citations as fabricated, which matches the chair's own spot checks (the two legs name different people and talks for the same games, and Qwen's attributions collapse under Argon's named counter-evidence). Two limits are recorded. First, Argon's "Verified" stamps are Argon's own verification; the chair carries the shared substance where the legs and the review agree, and marks Argon-only specifics (for example the Sins II "Picturesque Planets" patch) as Argon-sourced in the synthesis. Second, Argon's recommended synthesis direction is advice, not a ruling; the chair adopted most of it and says where. Its engine corrections (froxel grid, fog shader outputs, burst versus steady-state budgeting, polar pinching in equirect normal generation, R80 bleed in Qwen's beat placement) were checked by the chair against the code and Godot's documented behaviour and are carried. Its missed-technique additions (optical-flow flipbook blending, directional lightmap baking for flipbooks, gradient-normalized coastal shelves, spherical Voronoi plates, derivative pseudo-erosion, camera near-plane and fog-length tuning) are carried as INFERRED techniques for the build order; the near-plane and fog-length items were verified against the code by the chair (camera_rig.gd:33 near = 0.5; backdrop.gd:53 volumetric_fog_length = 400.0).

---

1. Audit of Shipped-Game Claims and Sources

The two writer legs differ sharply in evidentiary reliability. DeepSeek (deepseek.md) grounded every primary game reference in real, checkable developer breakdowns, GDC lectures, and patch notes, whereas Qwen (qwen.md) fabricated almost its entire bibliography, inventing speaker names, conference talk titles, magazine interviews, and developer diaries to back otherwise plausible visual observations. The chair synthesis must strip Qwen's fabricated citations before merging any of its technical proposals.

DeepSeek Leg: Sourced and Checkable

Homeworld 3, Tim O'Connell ("Weapons and Unit Damage in Homeworld 3", Feb 15, 2023): Verified. Blackbird Interactive Senior FX Artist Tim O'Connell published this breakdown on Steam and official channels on February 15, 2023. It confirms the three-stage breakdown (weapon damage, ship damage, wreckage), the "Splat Damage" system altering hull surface appearance beyond flat decals ("with Splat Damage you see how an incoming salvo rips through the armor of your precious Destroyer"), damage sockets on hulls (such as the Raiders Carrier), and the Houdini procedural "Ship Breaking" tool that replaced hand-modeled Maya/Blender debris meshes.

Homeworld 3, Volumetric Nebulae: Verified. Homeworld 3 uses localized volumetric nebula actors and density thresholds in Unreal Engine 4/5 so ships physically enter and exit 3D gas structures rather than flying past 2D skybox cards.

EVE Online, Andre Bragason ("Reigniting Stars: A Decade of VFX in 'EVE Online'", GDC 2024 Visual Effects Summit & GDS Prague 2024): Verified. CCP Games' Andre B. Bragason presented this talk at GDC 2024 on March 18, 2024 (and later at GDS Prague 2024). DeepSeek's summary of EVE's damage-location propagation, tonnage-scaled multi-part 3D explosions readable up to 600 km, and DeepSeek's explicit refusal to cite the talk for nebula volumes (since the talk covers ship VFX, damage, and stars rather than nebula volumes) are accurate.

Sins of a Solar Empire II, "Ruins of War" Update (v1.30, Nov 21, 2024): Verified. Released November 21, 2024, this update replaced generic large-unit debris with custom persistent wreckage for every TEC, Advent, and Vasari capital ship, titan, and starbase. DeepSeek also missed a useful follow-up patch from the same game: the January 30, 2025 v1.32 "Picturesque Planets" update, which specifically overhauled planet textures (terran, oceanic, desert, ferrous, crystalline) and cloud layers.

Elite Dangerous, Dr. Anthony "Doc" Ross ("Generating The Universe in Elite: Dangerous", 80 Level, April 5, 2018): Verified. Interview conducted by Kirill Tokarev with Frontier Developments' Lead Render Programmer Dr. Anthony Ross. It confirms that StellarForge simulates planetary mass, volcanic parameters, crust/mantle/core temperature differentials, and tidal heating to drive GPU noise buffers for basins, mountains, fissures, craters, and ice, rendered on subdivided cube-sphere quadtree patches ("landable" Horizons worlds) or normal-mapped spheres (initial release worlds).

Star Citizen, Genesis Planet Tech V5: Verified. Cloud Imperium Games' Genesis Planet Tech V5 replaces hand-placed planetary rules with physically driven emergent biomes, layered PBR terrain shading (substrate, soil, scree, bedrock, sand), virtual terrain tile atlases, and GPU scattering.

Qwen Leg: Invented or Misattributed Citations

Homeworld 3, "Jonathan Gafwe, VFX Director, GDC 2024 round-table 'Homeworld 3: Art & VFX of a Space Opera'": Invented. Neither a VFX director named "Jonathan Gafwe" nor a GDC 2024 session titled "Homeworld 3: Art & VFX of a Space Opera" exists in the GDC 2024 Vault. Homeworld 3's art direction was led by Karl Gryc and FX by Tim O'Connell.

Sins of a Solar Empire II, "Ironclad Dev Diary #7, 'Making Combat Readable,' 2023" and "Ironclad Dev Diary #5, 'Planet Rendering,' Steam, 2023": Invented. While Blair Fraser is a real co-founder/director at Ironclad Games, Sins II was in Epic Games Store Technical Preview during 2023 (releasing on Steam in August 2024), and neither the numbered Steam dev diaries nor the quote "The explosion is the punctuation mark, not the sentence" exist.

Battlefleet Gothic: Armada 2, "80 Level interview ('The VFX of Battlefleet Gothic: Armada 2,' April 2019)": Invented. No such April 2019 80 Level interview exists; DeepSeek correctly noted that no primary developer VFX breakdown for BFG:A2 is publicly archived.

EVE Online, "SIGGRAPH 2023 booth talk 'Explosions in EVE: From Sprite Soup to Volumetric Fire'" and "2021 CCP dev blog 'Planetary Interaction Visual Update'": Invented. CCP's actual retrospective VFX talk is Andre Bragason's GDC 2024 lecture. Furthermore, Qwen's claim that EVE uses a live raymarched volumetric fireball inside a bounding sphere that falls back to billboards at 200+ ships appears to reverse-project Voidsworn's own fx_shaders.gd:1626 implementation onto EVE.

The Expanse, "VFX supervisor for S1-S3, Lawson Deming, 2017 interview with Art of VFX ('The Expanse - Season 2')": Misattributed / Invented. The Senior VFX Supervisor for The Expanse Seasons 1-2 (and Producer on Seasons 3-4) was Robert (Bob) Munroe, alongside VFX Supervisors Bret Culp (Seasons 2-6) and Kyle Menzies. Lawson Deming is the VFX supervisor co-founder of Barnstorm VFX (Silicon Valley, The Man in the High Castle, Star Trek: Picard), not The Expanse. Art of VFX published a Season 2 breakdown reel by Oblique FX in December 2017, not an interview with Lawson Deming. However, Qwen's visual observations of The Expanse's combat grammar (flash-and-snuff venting, progressive bulkhead failure, zero-drag debris, incandescent spark showers) remain visually accurate and align with the show.

No Man's Sky & Inigo Quilez: Partially Real / Misattributed. Inigo Quilez's "Domain Warping" article (iquilezles.org) is real and standard. Hello Games did present at GDC 2017, though under the titles "Building Worlds Using Math(s)" (Sean Murray) and "Continuous World Generation in 'No Man's Sky'" (Innes McKendrick) rather than Qwen's combined title. Note also that No Man's Sky generates terrain in real time on the GPU rather than baking offline hydraulic erosion in an external toolchain as Qwen claims.

2. Where the Two Legs Disagree & Which Side the Evidence Supports

1. Raymarched Fireball (fx_shaders.gd:1626). DeepSeek Position: Demote the raymarched fireball to rare capital-reactor criticals at max tier; use Blender Mantaflow flipbooks for standard deaths and vents. Qwen Position: Delete the raymarched fireball completely (D1); use Mantaflow flipbooks + GPUParticles3D directional cones across all tiers. Evidence-Supported Verdict: Qwen's full replacement (or converting type 0 exclusively to a fast-snuffing plasma flash). The pack states that fx_shaders.gd:1626 ("type 0 a fireball rolling into dark smoke") is the exact suspect for Ryan's complaint that fire is photoreal, mismatched with stylized ships, and physically wrong in space. Keeping an atmospheric rolling-smoke raymarch even for rare capital deaths preserves the exact fidelity and physics clash Ryan rejected.

2. Structural Hull Break-Up (fx_death.gd). DeepSeek Position: Pre-fracture capital hulls offline in Blender into 4-8 chunks with convex collision shapes and vertex heat masks. Qwen Position: Keep the existing runtime worker-thread two-half clip-and-plug split (fx_death.gd), but sequence it into a 4-beat DeathTimeline resource (Power loss -> Vent -> Break -> Drift/Cool). Evidence-Supported Verdict: Combine Qwen's 4-beat sequencer with an extension of fx_death.gd's runtime slicer (not offline Blender cell-fracture). fx_death.gd already has 1,388 lines of working worker-thread clip-and-plug geometry slicing and a 360-body Jolt debris pool. Offline pre-fracturing every ship hull in Blender duplicates asset maintenance across all six factions. Extending the existing runtime worker thread from 1 cut (2 halves) to 2-3 staged cuts (3-4 hull sections) sequenced over a 2-3 s timeline delivers the Homeworld 3 / Expanse structural chain without breaking the asset pipeline.

3. Weapon Hits & Wound System (fx_breach.gd). DeepSeek Position: Replace the 12-mark wound system with a "Splat-lite" baked section atlas + temporary Godot Decal nodes (managing the 512 clustered limit). Qwen Position: Leave fx_breach.gd and fx_ship.gd untouched (per R80 standing ruling); upgrade fx_weapons.gd muzzle/impact sprites and torpedo trails to small flipbooks + directional sparks. Evidence-Supported Verdict: Qwen. PACK.md explicitly states: "Standing rulings this research must NOT reopen: the R80 damage ladder (stages 1 to 4, first open break at stage 4, wound variants per faction, mark caps)". DeepSeek's proposal to overhaul fx_breach.gd with Decal nodes violates the R80 constraint and introduces Forward+ clustered-decal overhead. Focusing weapon-hit work on fx_weapons.gd transient impact plumes, sparks, and short-lived contact flashes respects R80.

4. Nebula Architecture (world_living.gd). DeepSeek Position: Hybrid: Medium FogVolume nodes for volumetric body and light scattering + retain existing MultiMesh billboard veils as a high-frequency edge layer so ships stay crisp inside gas. Qwen Position: Pure Volume (at Max/High): Delete MultiMesh billboards at max/high tiers; rely on low fog density (or an 8-ship position uniform array) to keep ships crisp. Evidence-Supported Verdict: DeepSeek's Hybrid. Godot 4.7's volumetric fog uses a frustum-aligned 3D froxel grid whose default resolution is volume_size = 64 and volume_depth = 64. Froxels cannot resolve crisp, painterly edges at 4K (15.4 px/world unit). Deleting the MultiMesh veils entirely will turn the nebulas into blurry low-frequency pillows, whereas keeping a reduced veil layer over the FogVolume body gives both volumetric parallax/lighting and high-frequency silhouette crispness.

5. Nebula & Storm Lighting. DeepSeek Position: Allow lightning bolt lights, explosion flashes, and ship lights to inject into the FogVolume at max tier (removing the current exclusion of lightning from scene fog). Qwen Position: Add one unshadowed OmniLight3D per patch; keep lightning bolts excluded from scene fog and pulse a storm_flash density uniform instead. Evidence-Supported Verdict: DeepSeek (with Qwen's uniform pulse as the high-tier fallback). PACK.md notes that the current billboard model lacks internal light transport partly because lightning bolt lights are deliberately kept out of scene fog. Allowing 1-2 active lightning/explosion lights to scatter inside FogVolume via light_volumetric_fog_energy (LIGHT_PARAM_VOLUMETRIC_FOG_ENERGY) at max tier is the single biggest visual payoff of switching to FogVolume.

6. Planet Pipeline (world_bake.gd vs. Offline Blender). DeepSeek Position: Build an offline Blender terrain/erosion bake rig outputting static equirectangular texture sets (albedo, normal, AO, roughness, masks) per planet kind + tile CC0 detail maps. Qwen Position: Keep the existing load-time GPU bake in world_bake.gd (4096x2048), rewriting the procedural shader to add domain-warped FBM, ridge-noise mountains, coastal shelves, biome ramps, and a computed tangent-space normal map. Evidence-Supported Verdict: Qwen's GPU bake architecture (world_bake.gd) enriched with DeepSeek's geological feature set. world_bake.gd already bakes 4096x2048 equirectangular channels on the GPU once per battle load. Moving to offline Blender bakes throws away procedural seed variety and bloats repo/VRAM storage with static 4K texture sets. Instead, upgrading the world_bake.gd GPU shader to compute tectonic plates, domain-warped continents, analytical erosion/ridge chains, normal + roughness maps, and blending CC0 micro-detail textures in world_planet.gd gets both infinite seed variety and high geological structure at near-zero runtime cost.

3. Risks in Build Orders and Frame Cost Reasoning

Technical & Engine Misconceptions in qwen.md

False Godot 4.7 Volumetric Fog Architecture (qwen.md section 2d):

The Error: Qwen claims Godot 4.7 raymarches volumetric fog at half-screen resolution (1920x1080 at 4K) with 128 temporal steps.

The Reality: Godot 4.7 Forward+ volumetric fog does not raymarch at half viewport resolution; it evaluates a frustum-aligned 3D froxel buffer configured in ProjectSettings under rendering/environment/volumetric_fog/volume_size (default 64) and rendering/environment/volumetric_fog/volume_depth (default 64). Frame cost scales with froxel grid resolution, active FogVolume AABB overlap in froxel space, and light count, not 1080p pixel count.

Why it matters for the build order: At default 64x64 froxel resolution, a localized FogVolume at 170 units away has coarse spatial cells. On an RTX 5080 at max tier, the build order should test bumping volume_size to 128 and volume_depth to 128 (with temporal reprojection enabled via rendering/environment/volumetric_fog/use_filter) alongside DeepSeek's billboard edge veils.

Invalid Lighting Math Inside a Godot fog Shader (qwen.md section 2b):

The Error: Qwen proposes computing dot(normal_approximation, sun_dir) inside nebula_fog.gdshader to pick a stop from the 4-stop violet ramp and outputting that as the fog colour.

The Reality: In Godot 4.x shader_type fog;, the shader only outputs DENSITY, ALBEDO (single-scattering color), and EMISSION per froxel. As documented in FogMaterial (class_fogmaterial.html), ALBEDO is multiplied by incoming scene light during the engine's froxel light-integration pass, while EMISSION adds unlit self-illumination that does not cast light on other objects. If you bake the lit/dark ramp exclusively into ALBEDO, dynamic lights (lightning, explosions) will multiply against already-darkened shadow colors; if you put the ramp into EMISSION, it ignores shadows and lights.

Fix: Split the R82 4-stop violet ramp across both outputs: map the dark and shadow stops to EMISSION (ambient self-glow so gas never goes pitch-black) and map the lit and glow stops to ALBEDO + density-gradient emission so directional/omni lights and lightning naturally drive the bright violet stops.

Burst-vs-Steady-State Frame Budget Fallacy (qwen.md section 1d, section 2d, section 6):

The Error: Qwen argues that removing 2-3 concurrent raymarched fireballs saves 4-8 ms (or 6-9 ms), and uses that "saving" to justify adding +1.5-3.0 ms of continuous FogVolume cost for nebulas, concluding a net frame-time change of -2 to -5 ms.

The Risk: Nebulas are on screen 100% of the battle (steady-state cost). Capital ship deaths are rare, 1.5-second burst events. Removing a burst spike prevents frame drops during capital kills (the exact Sins II failure mode DeepSeek noted), but it does not create 6 ms of baseline headroom during normal combat when no capital ship is exploding. Steady-state costs (Nebula FogVolumes + Planet shaders) must be budgeted independently against the current steady-state frame time at 4K.

Equirectangular Polar Pinching & Seam Artifacts in Normal Map Generation (qwen.md Step P5):

The Risk: Qwen Step P5 computes a tangent-space normal map in world_bake.gd using a simple central-difference gradient in equirectangular UV space. Because equirectangular longitudinal texel spacing shrinks by cos(theta) toward the poles (theta -> +/-/2), an uncorrected UV-space gradient severely exaggerates east-west normal slopes near the poles and produces a hard lighting seam across the u = 0 / u = 1 wrap boundary if the height field is not evaluated purely in 3D unit-sphere coordinates p in  S2.

Fix: Evaluate all procedural height functions h(p) on the 3D unit sphere vector p = (costheta cosphi, sintheta, costheta sinphi) and compute the surface gradient along the orthonormal tangent basis (e_phi, e_theta) on the sphere (scaling the phi step by 1/costheta or sampling p +/- e_phi directly in 3D space) so normals are seamless across u = 0/1 and distortion-free at the poles.

R80 Damage Ladder Bleed (qwen.md section 1b):

The Risk: Qwen suggests playing Death Beats 1 and 2 (power loss and directional gas venting) during R80 damage stages 2-3 as escalating damage cues before triggering Beat 3 at stage 4.

Fix: Keep R80 stages 1-3 strictly in fx_ship.gd / fx_breach.gd as persistent damage state. Trigger all 4 beats of the DeathTimeline after lethal damage (when the ship enters fx_death.gd), over a compressed 1.5-2.5 s window, so the player clearly distinguishes "damaged ship still fighting" from "ship is dying."

Technical & Pipeline Risks in deepseek.md

Worker-Thread Slicer vs. Pre-Fractured Mesh Contradiction (deepseek.md section 1.2, section 1.3, section 1.5 Step 3):

The Risk: DeepSeek proposes pre-fracturing capital hulls in Blender into 5-8 static chunks with convex collision shapes, while simultaneously stating "wire the existing worker-thread cuts to the staged event graph". In fx_death.gd, the worker-thread clip-and-plug system dynamically slices the intact runtime ship mesh along cut planes into two sealed halves. You cannot seamlessly use both an offline Blender cell-fractured mesh replacement and runtime dynamic plane slicing without deciding which system owns the hull geometry at death.

Fix: Keep the runtime worker-thread clip-and-plug system in fx_death.gd as the geometry owner, either keeping the 2 major sealed halves and spawning 4-6 pre-authored internal structure/armor plate chunks from the cut plane, or extending the worker thread to perform 2 planar cuts (yielding 3-4 sealed hull sections) that separate sequentially over 0.8 seconds.

Offline Blender Planet Bake Scalability (deepseek.md section 3.2, section 3.3):

The Risk: DeepSeek's build order moves planet generation out of world_bake.gd into an offline Blender Cycles/Eevee bake rig ("minutes to hours per planet kind"). That sacrifices world_bake.gd's fast GPU procedural generation, locks the game to a handful of static pre-baked planet textures on disk, and increases download/VRAM footprint.

Fix: Implement DeepSeek's multi-layer terrain stack (continental mask, ridged multifractal + analytical erosion approximation, latitude/altitude/moisture biome mask, normal/roughness output) inside the existing world_bake.gd GPU bake shader.

4. Major Techniques and References Both Legs Missed

Optical-Flow / Motion-Vector Flipbook Blending (Reducing Atlas Bloat While Preventing 60 fps Stepping)

The Gap: Qwen proposes 8x8 or 10x10 flipbook atlases at 4096x4096 (30-48 frames) played back via frame = floor(time * fps). Over a 1.5-2.0 s capital vent, stepping through 30 frames at a 60 fps frame rate holds each frame for 2-4 display refreshes, creating visible stroboscopic stepping against smooth 60 fps ship motion, or ghosting if simple alpha cross-fading is used.

The Technique: Bake a 2-channel optical flow (motion vector) texture alongside the Mantaflow RGBA atlas (supported natively by EmberGen, SideFX Labs, or a simple Blender compositor vector pass / Python optical-flow baker) and distort UV lookups between frame_a and frame_b in the flipbook shader (a technique popularized in real-time VFX by Klemen Lozar and Guerrilla Games). With optical-flow blending, a 4x4 (16-frame) or 5x5 (25-frame) atlas at 2048x2048 looks smoother at 60 fps than an unblended 8x8 4096x4096 atlas, cutting VRAM by 75% (from 16 MB BC7 down to 4 MB per atlas).

6-Point Directional Lightmap / Thickness Baking for Stylized Flipbooks (EA Frostbite / Medericasure Technique)

The Gap: Both legs propose replacing the raymarched fireball with a 2D flipbook quad, but neither addresses how a flat flipbook responds to dynamic lighting (the thermal tear flash, secondary breach pops, or the R82 violet ambient) without looking like a pasted 2D sticker.

The Technique: In Blender, render the Mantaflow simulation once for Emission + Alpha (fire/plasma core) and once with a 3-axis tangent/world normal + optical thickness approximation (or 6-point directional rigs packed into two RGB channels). In the Godot particle shader, shade the smoke/gas plume dynamically using the breach normal, the sun direction, and the R82 4-stop violet ramp, and clamp the emission tail so the hot plasma core snuffs out in < 0.4 s, leaving only expanding, adiabatically cooling dark-violet vapor that disperses on a ballistic vector without buoyant mushroom-cloud rise.

Analytical Gradient Normalization & Spherical Voronoi Plate Boundaries in world_bake.gd

The Gap: Qwen proposes adding a "distance-to-coast mask" (P3) and ridge noise (P2) in world_bake.gd, while DeepSeek notes that real planetary structure requires tectonic plates and erosion valleys. However, in a single-pass GPU bake shader, smoothstep(sea_level, sea_level + 0.02, h) produces a coastal shelf that is miles wide on flat plains and vanishes on steep cliffs, because height threshold width is not spatial distance.

The Technique:

Constant-Width Coastal Shelves via Gradient Normalization: Since world_bake.gd already needs height derivatives grad h to build the normal map, divide the height above/below sea level by the gradient magnitude: d_coast about  (h - h_sea) / max(|grad h|, ). This yields a geometrically uniform coastal shelf and surf/littoral zone in a single pass with zero extra texture fetches.

3D Spherical Voronoi Tectonic Plates: Evaluate a low-frequency 3D Voronoi cell field (8-14 cells on the unit sphere), assigning each cell a random tangent drift vector v_i. Along cell boundaries, the dot product (v_i - v_j)  n_ij classifies the boundary as convergent (spawn arcuate coastal/continental mountain belts like the Andes/Himalayas) or divergent (spawn rift valleys and volcanic chains).

Derivative-Based Pseudo-Erosion (Inigo Quilez / Musgrave): Accumulate the analytical derivative sum sum d_i across the FBM loop and damp higher-octave amplitudes by 1 / (1 + k|sum d_i|2). This carves flat-bottomed alluvial valleys and sharp dendritic ridges directly in the GPU bake shader in < 2 ms at load time, delivering DeepSeek's hydraulic-erosion look inside Qwen's single-pass world_bake.gd architecture.

Camera Near-Plane & Froxel Grid Stability in Godot 4.7

The Gap: Neither leg notes how Godot's froxel distribution interacts with the RTS battle camera at ~170 units.

The Technique: Godot distributes its volume_depth (64 or 128 slices) logarithmically between the camera's near plane and Environment.volumetric_fog_length. If the RTS camera has a very small near clip (e.g., 0.05 or 0.1 units) while the battle sits at 140-200 units, over half of the froxel depth slices are wasted in empty space between 0.05 and 20 units in front of the lens! Pushing the battle camera's near plane out to a tighter bound (e.g., 5.0-15.0 units, or dynamically clamping it based on zoom height without changing it per-frame during rotation, which would invalidate temporal reprojection) and setting volumetric_fog_length tightly around the battle plane (~220-250 units) triples the effective froxel Z-resolution inside the nebula hexes at zero extra GPU cost.

5. Recommended Synthesis Direction for the Chair (synthesis.md)

Citations: Adopt DeepSeek's verified bibliography (Tim O'Connell's Feb 15, 2023 Homeworld 3 damage blog; Andre Bragason's GDC 2024 EVE Online VFX talk; Sins II Nov 2024 "Ruins of War" and Jan 2025 "Picturesque Planets" updates; Dr. Anthony Ross's April 2018 Elite Dangerous 80.lv breakdown; Star Citizen Genesis Planet Tech V5), plus Innes McKendrick's GDC 2017 No Man's Sky talk, Inigo Quilez's domain-warping/derivative-noise articles, and Bob Munroe / Bret Culp as the verified VFX supervisors for The Expanse. Discard all of Qwen's fabricated citations.

Area 1 (Deaths & Hits): Use Qwen's 4-beat DeathTimeline sequencer (fx_death.gd) and complete removal of the atmospheric rolling-smoke raymarch (fx_shaders.gd:1626), combined with Blender Mantaflow fast-snuffing plasma/gas flipbooks (using optical-flow UV blending and R82 violet-tinted smoke dispersion), directional GPUParticles3D venting cones + zero-drag incandescent sparks along the thermal-tear normal, and an extension of the existing runtime worker-thread clip-and-plug slicer (keeping R80 fx_breach.gd untouched and upgrading fx_weapons.gd transient impacts/streaks).

Area 2 (Nebulas & Storms): Use DeepSeek's Hybrid FogVolume + Billboard Edge Veil architecture (world_living.gd), porting the R82 4-stop violet ramp and 25% faction-tint cap into a custom fog shader (dark/shadow in EMISSION, lit/glow in ALBEDO), enabling local light injection from lightning bolts and explosions at max tier (light_volumetric_fog_energy), and optimizing the camera near / volumetric_fog_length range so froxel slices concentrate on the battle plane.

Area 3 (Planets): Use Qwen's in-engine world_bake.gd GPU bake pipeline (preserving the Job 10 4096x2048 / 1024x512 sizes and seed variety), upgraded with DeepSeek's geological feature stack implemented procedurally in the shader: 3D spherical Voronoi tectonic boundaries, domain-warped continents, derivative-damped pseudo-erosion ridges, gradient-normalized coastal shelves, latitude/moisture biome ramps, spherical-tangent normal + roughness generation, and slope-blended CC0 micro-detail maps in world_planet.gd.

For a checkable primary reference on procedural planetary terrain generation discussed in Section 1 and Section 3, see Hello Games' GDC 2017 session Continuous World Generation in No Man's Sky, where Innes McKendrick breaks down how layered noise, domain warping, and spherical terrain mapping create structured planetary surfaces.
