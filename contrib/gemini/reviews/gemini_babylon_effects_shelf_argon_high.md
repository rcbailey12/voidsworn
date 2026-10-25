# Babylon 9.30 effects and shader idea shelf (Gemini leg, Argon High, Oct 25, 2026)

Filed verbatim from a fresh Gemini chat at https://gemini.google.com/app/3e7cda076053bbef, titled "Babylon 9.30 VFX Idea Shelf". Ran Oct 25, 2026, 3:11-3:16 PM CDT (runtime-measured).

Model verification (required by the assignment): the mode picker showed "Selected 4 Argon Complex tasks" (Argon, Gemini 4 Argon), already selected; the Thinking level submenu showed Low/Medium/High with Low selected, so High ("High Extra thorough") was selected. After the change the picker button read "Open mode picker, currently Argon High" and the input row showed "Argon High". Both Argon and High were confirmed in place before the prompt was pasted. No fallback model was used. The Google AI Pro session was already signed in as rcbailey12@gmail.com (Pro badge); no sign-in was needed. No usage-cap notice, upgrade prompt, or payment screen appeared at any point. The reply was complete, not truncated, covering all 8 requested sections plus a Sources section. Research only: no code written, nothing bought, nothing posted, no other chat opened or referenced.

Chair note on process (not part of Gemini's shelf): the first paste attempt hit a transient page-unresponsive state and did not apply (input confirmed empty), so it was re-pasted once after the page recovered; no duplicate message was sent. See the screening note for the chair's flags. This shelf is leads only, in line with Gemini's standing lane (lead and idea only, never a verifier). It does not override the engine-neutral Job A effects sheets synthesis, and it does not decide the engine call.

## Babylon 9.30 VFX Idea Shelf (Gemini reply, verbatim)

This document is an idea shelf only, prepared for the scenario where Babylon 9.30 wins the engine evaluation for Voidsworn. It is not a specification, and it does not override the engine-neutral Job A effects sheets. Every entry below is a lead or proposal for a human builder to test against the R16 visual bar (BattleTech, Sins of a Solar Empire, Warhammer 40,000: Rogue Trader).

All Babylon capabilities referenced below distinguish between 8.20 legacy/stable features (which carry forward into 9.30), 9.0 to 9.30.0 stable additions (Clustered Lighting, Frame Graph, Node Particles, Particle Flow Maps and Attractors, Frame Graph Volumetric Lighting, and 9.30.0 WebGPU canvas tone-mapping/color-space exposure), and custom builder proposals (tagged as [Proposal]). No Godot features (such as AgX) are imported here.

### 1. Particle Systems per Weapon Kind and 9.x Node Particles

What Changes in Babylon 9.30 vs 8.20

In Babylon 8.20 (Stable), particle effects rely on imperative ParticleSystem (CPU) and GPUParticleSystem setups, using property gradients, SubEmitter arrays, and custom updateFunction callbacks.
In Babylon 9.0 to 9.30 (Stable), three major particle additions change how effects are authored and simulated:

Node Particle System (NodeParticleSystemSet and Node Particle Editor / NPE): Allows building modular particle graphs visually or via JSON (NodeParticleSystemSet.Parse) with System blocks, shape emitters (Point, Cylinder, Mesh Shape using cached barycentric triangle sampling), Update blocks (separate X/Y stretch), and onStart / onEnd sub-emitter triggers (Node Particle Editor Docs).

Particle Attractors (Attractor): Added in 9.0 to both ParticleSystem / GPUParticleSystem and NPE (Update Attractor block). Attractors pull (positive strength) or repulse (negative strength) particles toward a 3D point (GPUParticleSystem Docs).

Particle Flow Maps (FlowMap): Added in 9.0, sampling an RGB texture as XYZ directional forces (NPE Blocks Docs).

9.30.0 Patch Fix: Babylon 9.30.0 specifically fixed a GPUParticleSystem state leakage / attribute divisor bug in WebGPU/WebGL (Babylon 9.30.0 Release Notes), making mixed instanced meshes and GPU particles safer in the same pass.

Weapon Particle Leads and Proposals (Test Ranges)

All weapon systems should pull linear RGB faction colors via a shared ParticleInputBlock (in 9.30 NPE) or material/system uniform:
Voidsworn: (1.0, 0.45, 0.15)
Hegemony: (0.55, 0.82, 1.0)
Corsair: (0.95, 0.22, 0.10)
Chorus: (0.85, 0.90, 0.30)
Ithar: (0.75, 1.0, 0.88)
Deathless: (0.20, 1.0, 0.38)

Battery (Muzzle, Tracer, Impact):
Lead (9.30 NPE + 8.20 Stretched Billboard): Use a cone emitter for the muzzle flash (lifetime 40 to 90 ms, capacity 16 to 32 per barrel). For tracers, use ParticleSystem.BILLBOARDMODE_STRETCHED or BILLBOARDMODE_STRETCHED_LOCAL (ParticleSystem Docs) with separate X/Y scale (0.15 to 0.35 width, 2.5 to 6.0 length stretch).
Impact Lead: Trigger an onEnd sub-emitter on impact that spawns 15 to 40 hot hull spall sparks (250 to 600 ms lifetime) with high initial velocity (8.0 to 18.0 units/s) and rapid drag.

Flak (Airburst):
Lead (9.30 Attractor + Sprite Sheet): Two-stage burst. Stage 1 is a tight core flash (50 to 110 ms, clamp luminance under accessibility rules) plus an expanding shrapnel ring (20 to 50 stretched spark particles over 150 to 350 ms). Stage 2 is a dark, gritty puff of flak smoke (600 to 1400 ms lifetime, STANDARD blend mode) using an animated sprite sheet (isAnimationSheetEnabled = true) and a short-lived negative Attractor (-5.0 to -15.0 strength for 80 to 150 ms) to blast the smoke outward before stalling in vacuum.

Lance (Beam Contact):
Lead (9.30 NPE + FlowMap): While the beam is a mesh/ribbon (Section 3), the contact point needs a continuous particle fountain (80 to 200 particles/sec while active). Use a 9.30 FlowMap block or hemisphere emitter aligned to the hit normal to curl molten slag droplets and plasma vapor away from the trench (300 to 800 ms lifetime), transitioning color from white-hot core to faction weapon RGB, then cooling to dark ember (0.15, 0.03, 0.01).

Torp (Plume and Telegraph / Interception):
Plume Lead: Continuous GPUParticleSystem for the propellant exhaust (120 to 300 particles/sec, lifetime 400 to 900 ms), paired with a ribbon core (Section 4).
Telegraph Lead ([Proposal]): For the open A5 torpedo telegraph (two-stage warning, 700 to 900 ms ramp to white around the 800 ms target), use a NodeParticleSystemSet on the torpedo nose: Stage 1 (0 to 450 ms) pulses a faction-colored targeting halo; Stage 2 (450 to 850 ms) ramps an inward-pulling positive Attractor (4.0 to 10.0 strength) and lerps particle color to linear white (1.0, 1.0, 1.0) right before impact or the point-defense interception call. If intercepted, trigger an onEnd burst of tumbling warhead debris (300 to 700 ms) without the hull-breach flash.

Bio (Splat):
Lead (9.30 Mesh Shape Emitter + FlowMap): On impact, spawn a burst of 25 to 60 viscous globules (400 to 900 ms) using a custom FlowMap so droplets slide across the target hull surface rather than bouncing straight off like metal sparks. Follow with a Mesh Shape emitter (NPE Blocks Docs) bound to the affected hull zone that bubbles corrosive spore mist (1.5 to 3.5 s decay) in Chorus (0.85, 0.90, 0.30) or Deathless (0.20, 1.0, 0.38) hues.

Gauss (Streak):
Lead (9.30 Attractor + Stretched Particles): Hyper-velocity slug leaves a rail ionization wake. Spawn particles along the raycast segment with zero initial outward velocity, then apply a positive Attractor (8.0 to 20.0 strength for 50 to 120 ms) to pinch the wake inward, followed by a negative Attractor (-3.0 to -8.0 strength over 200 to 450 ms) so the plasma ring snaps outward and dissipates.

Strike-Craft (sq) Deaths:
Lead (8.20/9.30 SubEmitters): Avoid disappearing pop-outs. When an sq unit dies, spawn a tumbling rigid-body or particle proxy with an attached sub-emitter (400 to 1100 ms spiral trail of fire and black smoke) ending in a micro-detonation (80 to 160 ms flash, 15 to 30 micro-debris chunks).

### 2. Shield Shader and Hull-Hit Handling

Material Choice in Babylon 9.30
Proposal: Use NodeMaterial (NodeMaterial Docs) or ShaderMaterial (ShaderMaterial Docs) for the shield bubble/conformal shell mesh, and use a MaterialPluginBase (Material Plugins Docs) attached to the ship's PBRMaterial (PBRMaterial Docs) for Chorus and Deathless hull-hit reactions.
Why: A standalone ShaderMaterial or NodeMaterial with alphaMode = Constants.ALPHA_ADD (or ALPHA_COMBINE) and forceDepthWrite = false avoids full PBR lighting overhead on transparent shield shells while giving direct control over Fresnel and hit-sphere arrays. Meanwhile, MaterialPluginBase injects custom uniform buffers and fragment logic directly into the ship's existing PBRMaterial without duplicating draw calls for shieldless factions.

Shield Shader Leads (Voidsworn, Hegemony, Corsair, Ithar)

Fresnel Ripple + Hex/Panel Mask (NodeMaterial or ShaderMaterial):
Use the built-in FresnelBlock in NodeMaterial (or pow(1.0 - saturate(dot(normalW, viewDirectionW)), exponent) in ShaderMaterial) with exponent range 2.0 to 4.5 and bias 0.02 to 0.08 so the shield is nearly invisible head-on and glows along grazing silhouettes.
Pass a uniform array of recent impacts (vec4 hitPositionsAndTime[4] or [8] in local ship space). For each hit, compute spherical distance d = length(localPos - hitPos.xyz) and expand a ring wave over 250 to 600 ms with ring width 0.4 to 1.2 ship-scale units.
Multiply the ripple mask by a triplanar or UV-mapped hex/panel grid texture so only panels inside the expanding wave light up.

Faction Shield Colours (Linear RGB Uniforms):
Voidsworn: (1.0, 0.46, 0.16)
Hegemony: (0.38, 0.68, 1.0)
Corsair: (0.85, 0.16, 0.10)
Ithar: (0.72, 1.0, 0.86)
Note on UI vs World: Keep world-space shield shaders strictly in these linear RGB faction values; keep interface shield bars cyan in the GUI layer as required.

Patchy, Flickering Corsair Variant (ShaderMaterial / NodeMaterial Lead):
Feed a 3D Simplex/Worley noise block (or scrolling 2D noise texture) into an alphaTest / smoothstep discard threshold (0.25 to 0.55) so entire ragged patches of the Corsair shield bubble appear missing or starved of power.
Modulate overall opacity with a stepped high-frequency quantized time curve (quantized to 8 to 14 Hz low-amplitude jitter of 10 to 25 percent intensity, staying strictly below the accessibility full-flash luminance delta threshold) so the red (0.85, 0.16, 0.10) barrier sputters on hit recovery (300 to 700 ms unstable recharge tail).

Hull-Hit Handling for Chorus and Deathless (PBRMaterial + MaterialPluginBase)
No-Shield Rule: Chorus and Deathless have no shield; hits land directly on hull geometry.
Lead (MaterialPluginBase on PBRMaterial):
Register a custom HullImpactPlugin extending MaterialPluginBase on the ship's PBRMaterial.
When a weapon hits Chorus or Deathless, pass the local hit coordinate, radius (0.5 to 2.5 units), and timestamp into the plugin's UniformBuffer.
Inside CUSTOM_FRAGMENT_UPDATE_ALBEDO and CUSTOM_FRAGMENT_BEFORE_LIGHTS, render a localized shock-absorption and thermal/necrotic flare directly on the hull armor for 200 to 550 ms, paired with immediate decal stamping (Section 5) and spall particles (Section 1).

### 3. Beam Shaders (Lance Core, Glow Shell, Shimmer, Molten Trench)

Beam Geometry and Shader Setup in Babylon 9.30
Geometry Lead (8.20/9.30 Stable): Use CreateGreasedLine (GreasedLine Docs) with ribbonOptions (which creates a camera-facing GreasedLineRibbonMesh) or two concentric dynamic cylinders/ribbons (CreateRibbon). GreasedLine in 9.30 uses a material plugin under the hood and handles camera-facing billboarding along a 3D segment automatically.

Lance Core + Glow Shell (ShaderMaterial or GreasedLine Custom Shader):
Inner Core: Overbright linear white (2.0 to 4.0, 2.0 to 4.0, 2.0 to 4.0) mixed with 15 to 30 percent faction weapon RGB, occupying the center 20 to 35 percent of the ribbon UV width (abs(vUv.y - 0.5) * 2.0).
Outer Glow Shell: Faction weapon RGB (e.g., Voidsworn (1.0, 0.45, 0.15), Ithar (0.75, 1.0, 0.88), Deathless (0.20, 1.0, 0.38)) with soft exponential edge falloff (pow(1.0 - edgeDist, 2.0 to 3.5)) and high-speed axial UV scrolling (3.0 to 8.0 UV units/sec) of plasma noise to convey energy throughput over a 400 to 1200 ms firing duration.

Heat Shimmer ([Proposal] via 9.30 Frame Graph or Scene Copy Texture):
Render an outer distortion ribbon (1.5 to 2.5x the width of the glow shell) in a post-opaque refraction pass. Using a 9.30 FrameGraph copy task (FrameGraphCopyToTextureTask, Frame Graph Task List), sample the scene color buffer with a UV offset driven by animated normal/noise (0.002 to 0.008 screen UV displacement) so stars and enemy hulls behind the lance visibly warp.

Molten Trench with Cooling Edges Tied to the Damage Ladder ([Proposal]):
As the lance sweeps across a hull, feed the contact path into the target ship's MeshUVSpaceRenderer decal map (Decals Docs) or MaterialPluginBase.
Stamp a continuous multi-channel mask where:
Red channel = fresh thermal heat (decays over 1.5 to 4.0 seconds from white-yellow (1.0, 0.85, 0.4) through molten orange (1.0, 0.25, 0.02) to dark slag).
Green channel = permanent trench depth / normal map indentation.
Blue channel = charred lip mask around the trench edges.
Tie the visual output directly to the target section's current damage ladder state:
Intact / Scorched: Shallow glowing scar that cools into black carbon scoring (1.0 to 2.0 s cooling).
Dented / Exposed Structure: Trench shader reveals a secondary triplanar interior sub-layer (parallax-mapped ribs and conduits) underneath the melted armor skin, with lingering ember spots (3.0 to 6.0 s).
Hull Breach: Center of the trench alpha-clips or masks to deep interior cavity darkness with persistent internal fire particles streaming out of the gash.

### 4. Engine Trail Ribbons, Shock Diamonds, and High-Speed Spawn Pitfalls

The Four-Layer Engine Architecture in Babylon 9.30
To hit the R16 cinematic bar without looking like flat cones, combine static attached meshes at the thruster bell with dynamic ribbons and particles:

Layer 1 - Nozzle Glow (Mesh + PBRMaterial Emissive / GlowLayer):
Inside the thruster bell, use a dedicated emissive sub-mesh or PBRMaterial emissive texture driven by throttle (0.2 to 1.0 idle, 1.5 to 3.5 linear HDR intensity under thrust) tinted by faction engine RGB:
Voidsworn: (1.0, 0.50, 0.16)
Hegemony: (0.45, 0.72, 1.0)
Corsair: (1.0, 0.38, 0.16)
Chorus: (0.80, 0.90, 0.28)
Ithar: (0.62, 1.0, 0.84)
Deathless: (0.15, 1.0, 0.35)

Layer 2 - Core Plume (ShaderMaterial on Crossed Quads or Cylinder):
Attached directly to the nozzle (length 0.5 to 2.5x nozzle diameter). Renders the tight, high-pressure plasma jet with view-angle fade (abs(dot(viewDir, localNormal))) so crossed planes never show a hard X-seam.

Layer 3 - Outer Plume and Haze (CreateRibbon or CreateGreasedLine):
Soft additive shell (ALPHA_ADD) wrapping the core plume and extending 2.0 to 6.0x ship lengths behind the thruster during maneuvers.

Layer 4 - Wake (CreateRibbon + 9.30 NodeParticleSystemSet):
Long-lived (1.0 to 3.5 s), wide, low-opacity (0.05 to 0.20) heat/ion ribbon with scrolling distortion or faint ion dust particles.

Corsair Sputter and Soot Lead: For Corsair engines (1.0, 0.38, 0.16), modulate the Layer 2/3 shader thrust uniform with a stochastic Perlin/sawtooth stutter function (dropping plume length by 30 to 70 percent for 60 to 180 ms intervals) and trigger a synchronized NodeParticleSystemSet burst of dark, non-emissive soot puffs (STANDARD alpha blend, 800 to 1800 ms lifetime, color (0.06, 0.05, 0.05)) whenever the thruster coughs.

Shock-Diamond Banding (ShaderMaterial / NodeMaterial Lead)
Inside Layer 2 (Core Plume), avoid static painted stripes. Compute procedural Mach disks in the fragment shader along the axial UV coordinate u (0.0 at nozzle to 1.0 at tip):
float wave = max(0.0, sin(u * frequency - time * speed)); where frequency ranges from 12.0 to 28.0 (scaled by thrust) and speed is 15.0 to 35.0.
Pinch the radial UV coordinate v by wave so each bright compression node narrows into a diamond cone, damped by (1.0 - u) toward the plume tail.

Solving the High-Speed Spawn Tick-Rate Pitfall
When strike craft (sq), torpedoes, or fast corvettes move at high velocity relative to the frame rate, standard TrailMesh (TrailMesh Docs) or per-frame particle emitters leave discrete "stepping stones" or jagged polygonal kinks. Two concrete Babylon 9.30 solutions to test:

Stretched Ribbon with Catmull-Rom / Hermite Sub-Stepping (CreateRibbon / GreasedLine Lead):
Maintain a ring buffer of the last 8 to 16 thruster world transforms (position, tangent, timestamp).
Before calling CreateRibbon(null, { pathArray, instance: existingRibbon }) (Dynamic Mesh Morph Docs) or updating a GreasedLineRibbonMesh (updatable: true), evaluate a Catmull-Rom spline between the previous frame's nozzle position Pt-1 and current nozzle position Pt, inserting 3 to 6 intermediate ribbon vertices along the swept arc.
Note: If a projectile or ship teleports or respawns from a pool, always call trail.stop() and trail.reset() (TrailMesh Docs) or flush the ring buffer so a streak does not stretch across the map.

Swept-Segment Particle Spawning (8.20 startPositionFunction / 9.30 Custom Emitter Lead):
For particle wakes (like Corsair soot or torpedo smoke), do not emit all frame particles at the current emitter.position.
In ParticleSystem, override startPositionFunction = (worldMatrix, positionToUpdate, particle, isLocal) => { ... } to linearly (or spline) interpolate between prevEmitterWorldPos and currentEmitterWorldPos using a random scalar t = Math.random() (and pre-age the particle by (1.0 - t) * deltaTime). This distributes particles smoothly across the entire distance traveled during the frame.

### 5. Damage Decals and the Staged Damage Ladder (R16 Bar)

The R16 visual bar strictly requires that damage reads as holes with streaming parts, fire, and physical trauma, not orange lines.

Babylon 9.30 Decal Architecture
Babylon 9.30 provides two distinct built-in decal systems (Decals Docs):
Decal Maps (MeshUVSpaceRenderer + PBRMaterial.decalMap): Introduced in 5.49 and stable in 8.20/9.30. Projects textures directly into a mesh-specific UV render target via decalMap.renderTexture(texture, position, normal, decalSize). Zero extra geometry draw calls per hit, and supports uvEdgeBlending: true. Important Babylon rule: material.decalMap.isEnabled = true must be accessed/set before the material's first render so the internal DecalMapConfiguration material plugin attaches (Decals Docs).
Mesh Decals (MeshBuilder.CreateDecal): Clones and clips a subset of triangles offset slightly from the hull (localMode: true so it moves with the ship). Higher draw-call cost, but supports its own completely separate shader (such as deep parallax interior holes).

Mapping the Staged Damage Ladder in Babylon 9.30
Proposal: Combine a MaterialPluginBase on the ship's PBRMaterial, MeshUVSpaceRenderer, and selective CreateDecal / sub-mesh swaps across the six ladder states:

| Damage Ladder Stage | Babylon 9.30 Implementation Lead / Proposal | Visual Read (R16 Compliance) |
|---|---|---|
| 1. Intact | Base PBRMaterial with decalMap initialized (isEnabled = true) and empty damage mask. | Clean faction livery and specular hull panels. |
| 2. Scorched | Decal Map (MeshUVSpaceRenderer) + Procedural Shader Scorch: Stamp carbon soot decals on impacts AND blend a triplanar noise mask in MaterialPluginBase that darkens albedo (0.05 to 0.15 linear) and raises roughness (0.75 to 0.95) around hit clusters. | Blistered paint, matte soot rings, zero glowing orange stripes. |
| 3. Dented | Dent Normal-Map Blending (MaterialPluginBase): In CUSTOM_FRAGMENT_UPDATE_BUMP, blend a secondary high-frequency crumpled/warped normal map and cavity occlusion mask weighted by per-vertex or UV-splat damage weights (0.3 to 0.7 bump strength). | Buckled hull plating catching harsh key/fill light angles. |
| 4. Exposed Structure | Multi-Layer Shader Reveal (MaterialPluginBase or NodeMaterial): Where the damage mask exceeds 0.55 to 0.70, replace the outer hull albedo/normal with an interior structural texture set (trusses, pipes, dark metallic cavities) using Parallax Occlusion Mapping (useParallax = true, useParallaxOcclusion = true on PBRMaterial, parallaxScaleBias 0.03 to 0.08). Attach 9.30 NodeParticleSystemSet emitters streaming loose plating bits and venting atmosphere/coolant (10 to 30 particles/sec). | Torn outer armor skin showing recessed 3D ribs and streaming debris. |
| 5. Hull Breach | Breach Geometry vs Parallax Decal Hybrid: For major breaches, swap the damaged hull zone sub-mesh to a pre-modeled breach geometry inset (or stamp a CreateDecal(..., { localMode: true }) mesh decal with an interior raymarched/parallax cubemap shader and alpha-clipped jagged torn-metal rim). Spawn persistent local fire (billboard / sprite sheet particles) and streaming micro-parts (Mesh Shape emitter) from inside the cavity. | Real physical cavities with depth, interior fire, and streaming hull fragments. |
| 6. Wreck | Disable ship engines/shields, swap to burned-out albedo/roughness override (roughness 0.85 to 0.98), extinguish 70 to 90 percent of internal emissives, and transition breach fires to slow-cooling ember/smoke emitters (3.0 to 10.0 s decay). | Dead, drifting, blackened hulks with residual smoldering holes. |

Bio Corrosion Skin Variant (PBRMaterial Plugin Lead)
When hit by Bio weapons (or Chorus/Deathless bio loads), stamp into a dedicated corrosion channel (A channel of a damage splat map or separate MeshUVSpaceRenderer).
In the MaterialPluginBase, use the corrosion mask to shift hull albedo toward organic pitted green-yellow/necrotic hues, apply a bubbly organic normal map, set PBRMaterial.iridescence.isEnabled = true (PBRIridescenceConfiguration Docs) over the slime/acid film (intensity 0.3 to 0.7, indexOfRefraction 1.3 to 1.5), and slowly expand the mask radius over 1.5 to 4.0 seconds after impact.

Wreck-Field Persistence Lead
To keep wrecks and floating debris on the hex board throughout a tactical battle without tanking frame times:
Once a wreck settles (4.0 to 8.0 seconds after death), freeze its world matrix (mesh.freezeWorldMatrix()) and convert small floating hull chunks into Thin Instances (mesh.thinInstanceAdd(...), Thin Instances Docs) updated in bulk or left drifting via a single vertex-shader drift uniform (position += velocity * time).

### 6. Ship Death and Wreck Sequence

Timeline-Driven Cook-Off (AnimationGroup + Observables)
In Babylon 8.20 and 9.30 (Stable), use AnimationGroup (AnimationGroup Docs) combined with AnimationEvent triggers on specific keyframes to choreograph multi-stage ship deaths:

Stage 1 - Internal Cook-Off (0.0 to 1.8 seconds):
An AnimationGroup drives ship roll/pitch list (5 to 25 degrees) and flickers interior window/breach emissives.
Attach AnimationEvent callbacks at staggered frame intervals (every 150 to 400 ms) that fire internal compartment blowouts from existing Hull Breach and Exposed Structure sockets: directional jets of fire, escaping atmosphere, and spinning structural parts (NodeParticleSystemSet).

Stage 2 - Break-Up into Sections (1.2 to 2.8 seconds):
At the structural failure keyframe, hide the intact hull root and enable 2 to 5 pre-authored wreck section sub-meshes (bow, midships, drive section) at matching world transforms.
Drive their separation either deterministically via AnimationGroup translation/rotation curves (drift speed 0.5 to 2.5 units/s, angular tumble 2 to 12 deg/s) or via lightweight impulse velocities in @babylonjs/havok with collision disabled between micro-debris.
Across the torn cross-sections where the hull snapped, attach a short-lived (600 to 1500 ms) arcing electrical/plasma particle system and glowing severed-conduit decals.

Stage 3 - Optional Final Reactor Blast for Heavy Ships (2.0 to 3.5 seconds):
For cruisers/capitals where the final blast triggers: spawn an expanding shockwave sphere/ring (ShaderMaterial with Fresnel + scene refraction distortion over 400 to 900 ms), a high-density debris cloud (50 to 150 instanced hull plates), and a clamped core flash (strictly obeying Section 8 flash-rate and luminance caps).

Optional Camera Shake and Slow-Motion (Off by Default)
Rule Compliance: Both camera shake and slow-motion must be strictly optional and false by default in settings.
Camera Shake Lead: If enabled by the player, do not animate camera.position directly (which fights tactical camera panning). Instead, apply a damped Perlin/sinusoidal offset (0.05 to 0.25 units amplitude, 150 to 400 ms decay) to a parent TransformNode pivot or camera.targetScreenOffset (on ArcRotateCamera).
Slow-Motion Lead: If enabled by the player for a final boss/heavy ship kill, modulate scene.animationTimeScale (in 8.20/9.30 Scene) and AnimationGroup.speedRatio (0.25 to 0.50 for 400 to 900 ms real time, ramping smoothly back to 1.0 over 300 ms).

### 7. Lighting and Post-Processing in Babylon 9.30

Order of Operations: Lighting First, Then Materials, Then Post
Follow the open A5 workflow rule strictly: calibrate scene lighting and IBL in linear space with post-processing disabled (except tone mapping), dial in PBR hull materials next, and only then turn on GlowLayer and DefaultRenderingPipeline bloom.

1. Tone Mapper Test: ACES vs Khronos PBR Neutral (No AgX)
In Babylon 8.20 and 9.30, tone mapping is configured on scene.imageProcessingConfiguration (ImageProcessingConfiguration Docs) or inside DefaultRenderingPipeline.imageProcessing:
ImageProcessingConfiguration.TONEMAPPING_ACES (1): High contrast toe and filmic highlight rolloff, but notorious for hue shifting bright saturated colors (for example, pushing Voidsworn orange (1.0, 0.45, 0.15) or Corsair red (0.95, 0.22, 0.10) aggressively toward yellow, and shifting Deathless green (0.20, 1.0, 0.38) or Hegemony blue (0.55, 0.82, 1.0) toward cyan/white at moderate HDR intensities).
ImageProcessingConfiguration.TONEMAPPING_KHR_PBR_NEUTRAL (3): Implements the Khronos PBR Neutral specification (Khronos PBR Neutral Spec). It guarantees 1:1 linear base-color reproduction up to 0.8 linear reflectance and compresses HDR highlights (> 0.8) cleanly along the plane to [1, 1, 1] with zero hue shift (0 degrees rotation around the white axis).
9.30.0 Specific Addition: Babylon 9.30.0 added support for exposing WebGPU canvas tone mapping and color space options (Babylon 9.30.0 Release Notes). When testing in 9.30.0 on WebGPU, verify that the WebGPU canvas toneMapping mode is left standard (SDR) when ImageProcessingConfiguration handles tone mapping, so tone mapping is not double-applied.
Test Proposal for Builder: Run an A/B split-screen or toggle test in 9.30 with all 6 faction palettes firing simultaneously. Expect TONEMAPPING_KHR_PBR_NEUTRAL to preserve exact faction identity across shields and engines while still desaturating 3.0+ HDR lance cores to white.

2. Emissive on Its Own Slot, Glow Before Tone Mapping, and Bloom Threshold
Emissive on Its Own Slot: On PBRMaterial, use material.emissiveTexture + material.emissiveColor + material.emissiveIntensity (1.0 to 4.0) (PBRMaterial Docs). For custom effects or selective glow, use GlowLayer.customEmissiveColorSelector and customEmissiveTextureSelector (GlowLayer Docs) so only true emissive slots feed the glow pass, never lit base albedo.
Glow Before Tone Mapping:
Both GlowLayer (when rendered into an HDR scene texture) and DefaultRenderingPipeline (hdr: true) execute bloom/glow composition before the ImageProcessingPostProcess tone-mapping step.
In Babylon 9.30 Frame Graph (Frame Graph Task List), this ordering is explicit and guaranteed by wiring FrameGraphObjectRendererTask -> FrameGraphGlowLayerTask -> FrameGraphBloomTask -> FrameGraphImageProcessingTask on a HALF_FLOAT (TEXTURETYPE_HALF_FLOAT) render target.
Bloom Threshold (0.5 to 1.0):
In DefaultRenderingPipeline (DefaultRenderingPipeline Docs):
pipeline.bloomEnabled = true;
pipeline.bloomThreshold = 0.5 to 1.0; (Proposal: test 0.75 to 0.95 under TONEMAPPING_KHR_PBR_NEUTRAL so specular dielectric hull highlights below 0.8 do not bloom, while emissive engines/weapons set to 1.2 to 4.0 bloom cleanly).
pipeline.bloomWeight = 0.15 to 0.45;
pipeline.bloomKernel = 48 to 96;

3. Prefiltered Environment Map + Single Key, Cool Fill, and Fresnel Rim
Prefiltered Environment Map:
Use CubeTexture.CreateFromPrefilteredData("path/to/voidsworn_space.env", scene) (HDR Environment Docs) assigned to scene.environmentTexture with scene.environmentIntensity = 0.35 to 0.75.
8.20/9.30 Feature Note: Since Babylon 7.48+, if generating from raw .hdr/.exr, prefilterIrradianceOnLoad and prefilterUsingCdf are available for higher dynamic range diffuse IBL, though pre-baked .env files remain best for fast startup.
Single Key + 25 to 40 Percent Cool Fill + Fresnel Rim:
Key Light: One DirectionalLight (intensity 1.8 to 3.2, warm-neutral star tint (1.0, 0.96, 0.90)).
Cool Fill (25 to 40 percent of Key): Either a HemisphericLight (intensity set to 0.25 to 0.40 of key light intensity, diffuse = (0.35, 0.50, 0.75), groundColor = (0.08, 0.12, 0.22)) OR opposing directional/environment fill so shadowed hull flanks remain readable against dark space.
Fresnel Rim: Inject via a lightweight MaterialPluginBase or NodeMaterial on ship PBRMaterial: compute pow(1.0 - saturate(dot(N, V)), 3.0 to 5.0) * saturate(dot(N, -keyLightDir)) and add a subtle cool-white or environment-tinted rim (0.15 to 0.40 linear intensity) so dark ships never vanish into the starfield.

4. Screen-Size Effect LOD (With Active Check) and VFX Importance Band
Screen-Size Mesh LOD (8.20/9.30 Stable):
Babylon's Mesh natively supports screen-coverage LOD (LOD Docs):
TypeScript
effectCarrierMesh.useLODScreenCoverage = true;
effectCarrierMesh.addLODLevel(0.08, mediumEffectMesh);
effectCarrierMesh.addLODLevel(0.015, lowEffectMesh);
effectCarrierMesh.addLODLevel(0.003, null); // Cull below 0.3% screen area

Mandatory Check That It Is On ([Proposal]): Add an automated assertion / diagnostic hook in scene.onBeforeRenderObservable (or a post-spawn validator) that iterates registered VFX carrier meshes and asserts mesh.useLODScreenCoverage === true && mesh.getLODLevels().length > 0. For NodeParticleSystemSet and GPUParticleSystem (which do not use Mesh.addLODLevel directly), compute bounding-sphere screen coverage C = πr² / (d·tan(fov/2))² every 4 to 8 frames and scale emitRate (100 percent above 0.05 coverage, 25 to 50 percent between 0.01 and 0.05, 0 percent below 0.003), logging a console/telemetry warning if the scaler is bypassed.

VFX Importance Band ([Proposal]):
Assign every spawned effect a priority tier (Band 0: Critical Gameplay/Telegraphs like the 800 ms torpedo warning and lance beams; Band 1: Primary Combat like player/target ship breaches and heavy impacts; Band 2: Ambient/Secondary like distant flak smoke, stray sparks, and strike-craft trails).
Cap total active particle/decal budgets per frame. When GPU frame time exceeds 10.0 to 14.0 ms, throttle Band 2 emission rates by 50 to 80 percent while keeping Band 0 untouched.

5. What Babylon 9.0 to 9.30 Clustered Lighting, Volumetric Lighting, and Frame Graph Mean in Practice
Clustered Lighting (ClusteredLightContainer - 9.0 Stable):
Docs: Clustered Lighting Docs.
What it means for A5: In 8.20, standard PBRMaterial capped per-mesh lights (default maxSimultaneousLights = 4), meaning muzzle flashes, torpedo plumes, and hull fires could not all cast real dynamic point lighting on nearby ships without shader recompilation or light-popping. In 9.30, you can pre-allocate a pool of 64 to 256 PointLight and SpotLight instances inside a new ClusteredLightContainer("vfxLights", lightPool, scene) (verticalTiles: 32 to 64, horizontalTiles: 32 to 64, depthSlices: 32 to 64). Every torpedo, lance impact, muzzle flash, and hull breach fire can claim a real dynamic point light (with a tight light.range of 2.0 to 15.0 units so clustering stays fast) that illuminates ship armor and dent normal maps at high frame rates.
Limitations to watch: Only point/spot lights with FALLOFF_DEFAULT and no shadow maps/projection textures can go inside ClusteredLightContainer; keep the main DirectionalLight key light outside the container.
Volumetric Lighting (FrameGraphVolumetricLightingTask - 9.0 Stable):
Docs: Volumetric Light Scattering / Volumetric Lighting Task Docs.
What it means for A5: Babylon 9.0 added a true volume-based FrameGraphVolumetricLightingTask (distinct from the older 8.20 2D screen-space VolumetricLightScatteringPostProcess mesh god-rays). It works best on WebGPU (where a compute shader updates the lighting volume; WebGL falls back to CPU readback). For Voidsworn, full-screen volumetric fog can wash out deep space contrast, so test it selectively for nebula sector maps or dense wreck/flak smoke clouds (phaseG 0.05 to 0.35), and disable it on clear vacuum maps.
Frame Graph (FrameGraph / NodeRenderGraph - 9.0 Stable):
Docs: Frame Graph Docs.
What it means for A5: Replaces or augments the fixed Scene.render loop with an explicit DAG of render tasks. For the A5 effects pass, FrameGraph lets you:
Enforce the exact render order: Opaque Ships -> Decal Maps -> Transparent Shields/Ribbons -> FrameGraphGlowLayerTask -> Bloom -> Tone Mapping (TONEMAPPING_KHR_PBR_NEUTRAL).
Run a FrameGraphComputeShaderTask or FrameGraphMinMaxReducerTask (Frame Graph Task List) on a downsampled luminance buffer for the luminance background scan and accessibility flash counter (Section 8) without stalling the main render pipeline.
Gotcha to note: When scene.frameGraph replaces the render loop, scene.activeCamera is null outside task execution; always set scene.cameraToUseForPointers for hex-grid picking (Frame Graph Basic Concepts).

### 8. Accessibility Implementation in Babylon 9.30 (<= 3 Flashes/Sec & Reduce-Flashing)

Note: Babylon's @babylonjs/accessibility package (NPM @babylonjs/accessibility) is an HTML twin generator for screen readers, not a photosensitivity flash limiter. Photosensitivity compliance (at most 3 flashes per second anywhere on screen, plus a reduce-flashing option and the open A5 luminance background scan) must be built into the VFX governor and post-pipeline ([Proposal]).

1. Global Flash Counting and the Luminance Background Scan ([Proposal])
Implement a two-layer defense (a proactive CPU governor + a reactive GPU verification pass):
Layer A - Proactive CPU Spatial-Temporal Flash Governor:
Divide the viewport logically into an 8x8 or 16x9 screen-space grid.
Every transient bright event (muzzle flash, flak airburst, gauss snap, torpedo detonation, strike-craft death, Corsair shield flare) must request a flash token from FlashGovernor.requestFlash(worldPos, radius, peakLuminance, durationMs) before spawning its peak-brightness component.
Project worldPos to screen grid cells. Each cell tracks a sliding 1000 ms window of flash timestamps (pairs of opposing luminance transitions above 0.1 to 0.2 relative luminance delta).
Hard Cap: If a cell (or its 1-cell neighborhood) has already recorded 2 flashes within the last 1000 ms (or if the time since the last flash ends is under 333 ms for unmerged pulses), the governor clamps the new effect's peak emissive/light multiplier to 15 to 25 percent so it cannot create a 3rd/4th high-contrast oscillation within that 1-second window.
Layer B - GPU Luminance Background Scan & Verification (9.30 FrameGraph Lead):
Use a downsampled render target (64x36 or 32x18) or a 9.30 FrameGraphComputeShaderTask / FrameGraphMinMaxReducerTask (Frame Graph Task List) that computes relative luminance Y = 0.2126R + 0.7152G + 0.0722B per screen tile every frame.
This simultaneously satisfies the open A5 luminance background scan (auto-adjusting torpedo telegraph contrast and UI/effect readability when firing over a bright nebula vs dark void) and acts as a hardware safety monitor that logs an error (and dynamically lowers post-exposure/bloom weight) if any screen tile exceeds 3 luminance reversals per second.

2. Merge Window for Concurrent Flashes ([Proposal])
When multiple weapons fire or impact nearly at once, discrete micro-flashes 40 to 120 ms apart will violate the 3 Hz rule.
Coalescing / Merge Window (90 to 160 ms):
If a second flash request arrives in the same screen tile within 90 to 160 ms of an active flash, do not dip to dark and flash again.
Instead, merge the events into a single sustained plateau: extend the current flash's hold duration by 60 to 140 ms and smooth its decay tail (250 to 450 ms exponential fade-out) while capping total combined intensity via soft logarithmic compression: I_merged = I_max ⋅ (1 − e^(−∑I_i / I_max)).
Result: A salvo of 8 flak bursts within 120 ms reads as 1 continuous rolling illumination wave (1 flash in the 1-second window) rather than 8 rapid strobes.

3. Reduce-Flashing Option Replacements ([Proposal])
When the player enables Reduce Flashing in accessibility settings, set a global uniform uReduceFlashing = 1.0 and swap behaviors across the shelf:
Peak Luminance Clamp: Clamp all transient particle/shader emissive spikes to 1.0 to 1.25 linear max, and reduce ClusteredLightContainer point-light transient intensities by 60 to 80 percent.
Envelope Smoothing: Replace sharp 10 to 40 ms attack envelopes on muzzle flashes, flak cores, and ship explosions with soft 150 to 300 ms fade-in / 400 to 700 ms fade-out thermal glows.
Corsair Shield Flicker Replacement: Disable the temporal 8 to 14 Hz opacity jitter on Corsair shields (0.85, 0.16, 0.10). Replace it with a slow, smooth scrolling spatial noise mask (0.3 to 0.8 Hz drift) so the shield still looks ragged and patchy without temporal strobing.
Torpedo Telegraph (~800 ms Ramp to White) Replacement: Keep the two-stage 700 to 900 ms ramp to white smooth and monotonic (zero rapid blinking during Stage 2), relying on a widening geometric ring and chromatic shift to linear white (1.0, 1.0, 1.0) rather than a strobe.

4. How to Test a Worst-Case Mixed Salvo in Babylon 9.30 ([Proposal])
Build a deterministic automated stress scene (A5_WorstCaseSalvoTest) in Babylon 9.30 that fires all four worst-case elements into the same camera frustum over a 3.0 to 5.0 second window:
Heavy Gauss Volley: 6 to 12 staggered gauss streaks (30 to 70 ms apart) crossing the center hexes.
Heavy Torp Volley: 8 to 16 torpedoes completing their 700 to 900 ms white telegraph ramp, with half intercepted by point defense and half detonating on a capital hull.
Mass Strike-Craft (sq) Deaths: 12 to 24 strike craft dying within 1.0 to 2.0 seconds inside the same screen quadrant.
Flak Screen: Continuous overlapping flak airbursts (15 to 30 bursts/sec) blanketing the same airspace.
Verification Pass Criteria for the Builder:
Run the 64x36 tile luminance recorder at 60 and 120 FPS under both TONEMAPPING_KHR_PBR_NEUTRAL and TONEMAPPING_ACES, with Reduce Flashing both OFF and ON.
Assert in an automated test script that for every tile (x, y) and every sliding 1000 ms window, the count of relative luminance transitions exceeding 0.10 delta is strictly <= 3 (<= 1 when Reduce Flashing is ON).
Verify simultaneously in the Babylon Inspector (Babylon Inspector Docs) that useLODScreenCoverage is active, Band 2 particles throttle smoothly if frame times approach the budget limit, and hull breaches remain readable as physical holes with fire and streaming parts rather than blown-out white/orange blobs.

Sources

Babylon.js 9.0 Release Announcement (Clustered Lighting, Volumetric Lighting, Frame Graph, Node Particles, Attractors, Flow Maps): https://babylonjs.medium.com/welcome-to-babylon-js-9-0-c3edc9ee6428
Babylon.js What's New Documentation (9.x Changelog): https://doc.babylonjs.com/whats-new
Babylon.js 9.30.0 Release Briefing (WebGPU Canvas Tone Mapping & Color Space, GPUParticleSystem Divisor Fix): https://gamedev.net/news/6298-babylonjs-9300-released/
Babylon.js NPM Package Registry (9.30.0 Packages): https://www.npmjs.com/~babylonjs
Node Particle Editor (NPE) Documentation: https://doc.babylonjs.com/toolsAndResources/npe/
Node Particle Editor Blocks (System, Mesh Shape, Cylinder, Point, FlowMap, Attractor): https://doc.babylonjs.com/toolsAndResources/npe/npeBlocks
NodeParticleSystemSet API Reference: https://doc.babylonjs.com/typedoc/classes/BABYLON.NodeParticleSystemSet
ParticleSystem API Reference: https://doc.babylonjs.com/typedoc/classes/BABYLON.ParticleSystem
GPUParticleSystem API Reference: https://doc.babylonjs.com/typedoc/classes/BABYLON.GPUParticleSystem
ShaderMaterial API Reference: https://doc.babylonjs.com/typedoc/classes/BABYLON.ShaderMaterial
Node Material and PBR Documentation: https://doc.babylonjs.com/features/featuresDeepDive/materials/node_material/NMEPBR
PBRMaterial API Reference: https://doc.babylonjs.com/typedoc/classes/BABYLON.PBRMaterial
PBRIridescenceConfiguration & MaterialPluginBase API Reference: https://doc.babylonjs.com/typedoc/classes/BABYLON.PBRIridescenceConfiguration
GreasedLine Documentation (CreateGreasedLine): https://doc.babylonjs.com/features/featuresDeepDive/mesh/creation/param/greased_line
TrailMesh Documentation: https://doc.babylonjs.com/features/featuresDeepDive/mesh/trailMesh/
CreateRibbon API Reference: https://doc.babylonjs.com/typedoc/functions/BABYLON.CreateRibbon
Dynamically Morph a Mesh (Updatable Ribbons): https://doc.babylonjs.com/features/featuresDeepDive/mesh/dynamicMeshMorph/
Decals Documentation (CreateDecal and MeshUVSpaceRenderer Decal Maps): https://doc.babylonjs.com/features/featuresDeepDive/mesh/decals
Grouping Animations (AnimationGroup) Documentation: https://doc.babylonjs.com/features/featuresDeepDive/animation/groupAnimations
AnimationGroup API Reference: https://doc.babylonjs.com/typedoc/classes/BABYLON.AnimationGroup
ImageProcessingConfiguration API Reference (TONEMAPPING_ACES, TONEMAPPING_KHR_PBR_NEUTRAL): https://doc.babylonjs.com/typedoc/classes/BABYLON.ImageProcessingConfiguration
Khronos PBR Neutral Tone Mapper Specification: https://github.com/KhronosGroup/ToneMapping/blob/main/PBR_Neutral/README.md
DefaultRenderingPipeline API Reference: https://doc.babylonjs.com/typedoc/classes/BABYLON.DefaultRenderingPipeline
GlowLayer Documentation (Making Meshes Glow): https://doc.babylonjs.com/features/featuresDeepDive/mesh/glowLayer
GlowLayer API Reference: https://doc.babylonjs.com/typedoc/classes/BABYLON.GlowLayer
Using an HDR Environment for PBR (CreateFromPrefilteredData, .env): https://doc.babylonjs.com/features/featuresDeepDive/materials/using/HDREnvironment
Levels of Detail (LOD) Documentation (useLODScreenCoverage, addLODLevel): https://doc.babylonjs.com/features/featuresDeepDive/mesh/LOD
Clustered Lighting Documentation (ClusteredLightContainer): https://doc.babylonjs.com/features/featuresDeepDive/lights/clusteredLighting/
Volumetric Light Scattering & 9.0 Volumetric Lighting Task Documentation: https://doc.babylonjs.com/features/featuresDeepDive/lights/volumetricLightScattering/
Frame Graph Overview and Basic Concepts: https://doc.babylonjs.com/features/featuresDeepDive/frameGraph/frameGraphBasicConcepts/
Frame Graph Task List (FrameGraphGlowLayerTask, FrameGraphVolumetricLightingTask, FrameGraphMinMaxReducerTask): https://doc.babylonjs.com/features/featuresDeepDive/frameGraph/frameGraphClassFramework/frameGraphTaskList

End of Gemini reply. Gemini's follow-up suggestion buttons (to prototype or test leads: tone mapper and ClusteredLightContainer test harness; MaterialPluginBase damage ladder and hull-hit GLSL/WGSL draft; 3 Hz FlashGovernor and worst-case salvo test script) are not part of the shelf and are not adopted here; they are recorded in screening only as the model's own suggestions.
