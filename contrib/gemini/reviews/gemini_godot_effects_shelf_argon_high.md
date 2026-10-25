# Godot 4.7 effects and shader idea shelf (Gemini leg, Argon High, Oct 25, 2026)

Filed verbatim from a fresh Gemini chat at https://gemini.google.com/app/7cffa9690bf4d061. Ran Oct 25, 2026, 3:10-3:20 PM CDT (runtime-measured).

Model verification (required by the assignment): the model picker in the fresh chat offered 3.5 Flash-Lite, 3.8 Flash (then selected), 3.1 Pro, and 4 Argon (Complex tasks); 4 Argon was selected. The Thinking level submenu offered Low (Quick and efficient, then selected), Medium (Balanced depth), and High (Extra thorough); High was selected. Final picker state before submitting read "Open mode picker, currently Argon High" and the prompt bar dropdown showed "Argon High". Both Argon and High were confirmed in place before the prompt was pasted. No fallback model was used. The Google AI Pro session was already signed in as rcbailey12@gmail.com; no sign-in was needed. No usage-cap, limit, or payment prompt appeared at any point, and no upgrade was offered or taken. The reply was complete, not truncated, covering all 8 requested sections plus a Sources section (35 links). Completion was confirmed by the presence of Good response / Bad response / Redo / Copy response buttons and the absence of a Stop response button. The reply obeys the no-em-dash rule (hyphens only) and gives feel and timing values as ranges. Citation UI chips and code-block language badges are omitted as page chrome; reply text is otherwise unedited.

Chair note on process (not part of Gemini's shelf): pasting the long prompt via the paste entry mode hung the page twice (page_unresponsive); entering it with the default fill path worked. No other anomalies. Nothing was written to any repo, bought, or posted. The sidebar listed other pre-existing chats (including a "Babylon 9.30 VFX Idea Shelf" chat); none of them was opened or referenced. See the screening note for the chair's flags. This shelf is leads only, in line with Gemini's standing lane (lead and idea only, never a verifier). It does not override the engine-neutral Job A effects sheets synthesis, and it does not decide the engine call.

## Godot 4.7 Effects Idea Shelf (Gemini reply, verbatim)

This document is an idea shelf only for the Voidsworn A5 effects pass, written for the case where Godot 4.7 wins the pending engine call over Babylon 9.30. It is NOT a specification and it does NOT override the engine-neutral Job A effects sheets. Every item below is labeled as a [Lead], [Proposal], or [UNSURE] for a human builder to test and validate in-engine.

Engine Version Baseline:

Godot 4.7 Stable (June 2026): Ships with GPUParticles3D, RibbonTrailMesh, TubeTrailMesh, Decal, ShaderMaterial, Environment (including AgX and Neutral tone mappers), plus 4.7 additions documented in the Godot 4.7 release overview and CG Channel 4.7 feature summary: DrawableTexture2D (direct texture blitting without viewport overhead), AreaLight3D (rectangular real-time lights), desktop HDR output, inline shader editor previews, collapsible AnimationPlayer track groups, and 3D particle scaling and angular-velocity fixes.

Godot 4.8 Beta 1 (October 2026 - Out of Scope for 4.7 Stable): Features such as the native Trail3D node, built-in animated Decal properties, and screen-space contact shadows belong to Godot 4.8 beta 1 (https://godotawesome.com/godot-4-8/) and are explicitly called out below so a 4.7 builder does not rely on them.

### 1. GPUParticles3D Setups per Weapon Kind

Shared Architecture [Lead / Proposal]:
Use GPUParticles3D driven by ParticleProcessMaterial and chained via Particle sub-emitters. Godot 4.7 improves 3D particle rotation, scaling, and angular velocity handling (Godot 4.7 overview). To avoid duplicating particle materials per faction, bind a per-instance shader parameter via GeometryInstance3D.set_instance_shader_parameter() holding the faction linear RGB weapon colour:

Voidsworn: (1.0, 0.45, 0.15)

Hegemony: (0.55, 0.82, 1.0)

Corsair: (0.95, 0.22, 0.10)

Chorus: (0.85, 0.90, 0.30)

Ithar: (0.75, 1.0, 0.88)

Deathless: (0.20, 1.0, 0.38)

To hit the R16 visual bar (BattleTech, Sins of a Solar Empire, Warhammer 40,000: Rogue Trader), every impact setup below pairs an energy/fire pass with a physical debris pass (spinning hull shards, torn plates, and vented gas) rather than flat orange lines [Proposal].

Weapon Kind	Muzzle & Launch [Proposal]	Tracer / In-Flight [Proposal]	Impact / Detonation [Proposal]
Battery (battery)	one_shot = true, explosiveness 0.85 to 0.98, 8 to 20 particles over 0.08 to 0.18 s. Cone emission (15 to 30 degrees) venting propellant gas plus a short anisotropic muzzle spike.	Stretched billboard quad (PARTICLE_FLAG_ALIGN_Y_TO_VELOCITY) or short TubeTrailMesh (trail_lifetime 0.05 to 0.14 s). Core boosted to 2.5 to 4.5 HDR energy in faction weapon RGB.	Two-pass GPUParticles3D: Pass 1 ejects 12 to 32 low-poly hull fragments (angular_velocity 4.0 to 14.0 rad/s, lifetime 0.45 to 1.20 s); Pass 2 spawns a turbulent fire and soot puff (0.25 to 0.60 s) with hot sparks cooling from faction RGB to dark ember.
Flak (flak)	Rapid low-count bursts: 4 to 10 particles per barrel over 0.05 to 0.12 s, low HDR energy (1.2 to 2.2) to preserve the flash budget during salvo fire.	Fast micro-slugs with thin 2-to-4-section RibbonTrailMesh smoke wakes (trail_lifetime 0.08 to 0.20 s).	Flak airburst: explosiveness 0.92 to 1.0 at detonation point. Expanding dark-grey flipbook smoke cloud (lifetime 0.45 to 1.10 s, soft depth proximity fade 0.3 to 0.8 units in StandardMaterial3D) pierced by 18 to 45 high-velocity shrapnel streaks (velocity-aligned quads) that cool from white-hot to black slag in 0.10 to 0.25 s.
Lance (lance)	Pre-fire charge ring pulling particles inward (radial_accel -3.0 to -8.0 units/s^2 over 0.20 to 0.45 s), followed by a continuous nozzle plasma halo while the beam is active.	Handled by continuous beam mesh shaders (see Section 3) rather than discrete projectile particles.	Lance beam contact: Continuous emitter (emitting = true while beam dwells on target) locked to the raycast hit point. Pass 1 sprays 20 to 50 molten slag droplets and sheared armor chunks per second along the surface reflection vector (lifetime 0.35 to 0.95 s); Pass 2 uses Particle turbulence (turbulence_noise_strength 1.5 to 4.0) to curl boiling plasma and fire off the hull.
Torpedo (torp)	Cold-gas ejection puff (6 to 14 grey vapor quads over 0.15 to 0.35 s, initial speed 1.0 to 3.0 units/s) followed by main motor ignition 0.10 to 0.25 s after clearing the tube.	Torp plume: Continuous RibbonTrailMesh (trail_lifetime 0.50 to 1.40 s, 5 to 10 sections) paired with a cinder sub-emitter. Includes the two-stage torpedo telegraph (detailed below).	Direct hit: Heavy multi-stage blast (0.60 to 1.50 s) throwing 25 to 60 spinning hull plates, internal fire plumes, and an expanding shock ring. Interception call: Replaces warhead detonation with a low-flash propellant deflagration (0.20 to 0.45 s, tumbling casing chunks and cold vapor mist).
Bio (bio)	Peristaltic spore/acid ejection burst: 8 to 18 viscous droplets (damping 4.0 to 10.0, lifetime 0.20 to 0.45 s) tinted to Chorus (0.85, 0.90, 0.30) or Deathless (0.20, 1.0, 0.38) weapon RGB.	Pulsing organic glob mesh (vertex shader wobble at 4.0 to 9.0 Hz) spawning a constant sub-emitter trail of 5 to 12 acid droplets per second.	Bio splat: High-damping (damping 10.0 to 22.0) splatter of 15 to 35 adhesive blobs that cling and slide along the surface normal over 0.40 to 0.90 s, paired with a lingering caustic spore haze (lifetime 1.20 to 2.80 s, alpha 0.15 to 0.35) and a corrosion decal trigger (Section 5).
Gauss (gauss)	Rail-discharge arc: 6 to 16 anisotropic plasma streaks snapping along the barrel axis over 0.05 to 0.12 s, high initial velocity (15.0 to 35.0 units/s) with heavy damping (20.0 to 40.0).	Gauss streak: Stationary box-emission GPUParticles3D stretched along the firing segment. Spawns 20 to 50 ionized wake rings and helical plasma wisps that expand radially (0.4 to 1.5 units/s) and dissolve over 0.25 to 0.65 s.	Kinetic over-penetration punch: narrow forward spall cone plus reverse entry splash, flinging 20 to 45 white-hot kinetic fragments (initial_velocity 8.0 to 22.0 units/s, lifetime 0.30 to 0.85 s) and tearing an immediate structure/breach hole.
Strike Craft (sq)	Micro-muzzle bursts: 2 to 5 particles per shot, lifetime 0.04 to 0.09 s, using unshaded billboard quads.	Short velocity-stretched spark quads (length 0.3 to 0.8 units) with no sub-emitters to keep per-squadron GPU cost minimal.	Strike-craft deaths: Chained sub-emitter (SUB_EMITTER_AT_END). Stage 1 spirals the craft for 0.30 to 0.75 s trailing a thin RibbonTrailMesh of black oil-smoke and fire; Stage 2 pops into 6 to 14 micro-debris pieces and a brief ember puff (0.15 to 0.30 s, HDR energy capped at 1.2 to 2.0).

Torpedo Telegraph (Two-Stage Warning) and Interception Call [Proposal]:

Stage 1 (Launch / Cruise Telegraph): An unshaded billboard ring or flare attached to the torpedo nose pulses smoothly in the firing faction's weapon RGB at 1.0 to 1.8 HDR energy (pulse rate 1.5 to 2.5 Hz).

Stage 2 (Terminal Warning Ramp to White): When the torpedo enters terminal approach, an AnimationPlayer or tween drives a shader uniform telegraph_ramp from 0.0 to 1.0 over 750 to 850 ms (targeting the context's about 800 ms ramp to white). The shader interpolates ALBEDO and EMISSION from the faction weapon colour to pure white (1.0, 1.0, 1.0) at 2.0 to 3.5 HDR energy while contracting a crisp lock-on ring around the warhead.

Interception Call: If point-defense or flak intercepts the torpedo during Stage 1 or Stage 2, immediately abort the white ramp, spawn a non-strobing propellant puff (cool grey-blue smoke + 4 to 8 tumbling warhead casing fragments over 0.20 to 0.45 s), and play a distinct damped fizzle curve so the player never confuses an intercepted torpedo with a hull-damaging hit.

### 2. ShaderMaterial Shield Fresnel Ripple

Core Setup in Godot 4.7 [Lead / Proposal]:
Build a custom spatial ShaderMaterial using Godot's Spatial shaders (render_mode blend_add, depth_draw_never, cull_back, unshaded;). Useful community starting points on Godot Shaders include the Fresnel snippet, Glowing shield/beam/buble/magic/frost Fresnel, Shield Shader with Intersection Highlight, Hexagon Shield, and Procedural Hex Barrier for Godot 4.

Hex or Panel Masked Pulse [Proposal]:

Keep the shield bubble nearly invisible at rest (ALPHA 0.0 to 0.04) so ship hull details stay sharp.

Compute a grazing-angle Fresnel rim term pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), fresnel_power) (Fresnel snippet) with fresnel_power set between 2.5 and 5.0.

Generate a procedural hex or armor-panel grid in object-local triplanar coordinates (adapting the cell distance math from Procedural Hex Barrier for Godot 4).

Pass a ring buffer of recent impacts via uniform array (uniform vec4 hit_ripples[8];, where xyz is local hit position and w is normalized ripple age from 0.0 to 1.0 over 0.25 to 0.60 seconds). For each active hit, compute a spherical shell wave smoothstep(wave_width, 0.0, abs(distance(local_vertex, hit_ripples[i].xyz) - ripple_radius * hit_ripples[i].w)) with wave_width between 0.15 and 0.45 units. Multiply the hex cell border mask by this wave so individual hexes/panels light up along the expanding impact ring and fade back to zero.

Faction Colour vs Interface Cyan [Proposal]:

Drive the 3D shield mesh via instance uniform vec3 shield_rgb : source_color; using GeometryInstance3D.set_instance_shader_parameter() set to the game's linear RGB shield values:

Voidsworn: (1.0, 0.46, 0.16)

Hegemony: (0.38, 0.68, 1.0)

Corsair: (0.85, 0.16, 0.10)

Ithar: (0.72, 1.0, 0.86)

Keep all 2D/3D HUD shield bars bound to a separate UI theme constant locked to cyan so interface readability never shifts with faction allegiance.

Patchy, Flickering Corsair Variant [Proposal]:

For Corsair shields (0.85, 0.16, 0.10), sample a 3D Voronoi/Perlin noise texture (NoiseTexture3D) in local coordinates and threshold it (smoothstep(0.30, 0.55, noise_val)) to carve ragged, unshielded "dead patches" across the hull envelope.

Add an bright rim along the border of each dead patch (abs(noise_val - patch_threshold) less than 0.03 to 0.07) to read as unstable emitter arcing.

Modulate overall opacity with a compound low-amplitude stutter wave (combining a 4.0 to 8.0 Hz sine drift with a quantized noise step that drops opacity by 15 to 35 percent for 0.08 to 0.20 seconds when hit) so it reads as jury-rigged hardware without crossing the 3-flashes-per-second accessibility limit.

Hull-Hit Handling for Chorus and Deathless [Proposal]:

Chorus and Deathless have no shield (hull hits). On these ship archetypes, disable or omit the shield MeshInstance3D node entirely.

In the combat hit resolver, route Chorus and Deathless impacts straight to the surface contact pipeline: trigger immediate hull-spall GPUParticles3D bursts (tinted partially by the attacker's weapon RGB and the defender's hull material [UNSURE - exact Chorus/Deathless hull material palette beyond no-shield rule]), stamp an immediate damage decal (Section 5), and skip the shield ripple shader update.

### 3. Beam Shaders

Lance Core plus Glow Shell [Lead / Proposal]:
In Godot 4.7, author lance beams using two coaxial CylinderMesh instances (or camera-aligned quad ribbons) scaled dynamically along their local Z/Y axis to match the muzzle-to-target distance, using inline shader previews (Godot 4.7 dev 5 notes) to tune falloff curves:

Inner Core Mesh: Radius 0.08 to 0.22 units. Uses an unshaded additive Spatial shader. Mix 65 to 85 percent pure white with the firing faction's weapon linear RGB at 3.0 to 6.0 HDR energy so the core burns bright white under tone mapping while carrying faction tint at its boundary. Scroll a high-speed 1D/2D noise texture along UV.y - TIME * (8.0 to 18.0) to create high-velocity plasma striations.

Outer Glow Shell: Radius 2.0 to 3.5 times the inner core radius. Apply an inverted silhouette Fresnel curve (Fresnel snippet and Glowing shield/beam Fresnel): pow(clamp(dot(NORMAL, VIEW), 0.0, 1.0), 1.5 to 3.0) so the shell is thickest near the core and feathers smoothly to zero at its outer silhouette. Colour this shell in pure faction weapon RGB at 1.0 to 2.4 HDR energy.

Heat Shimmer [Proposal]:

Wrap the beam in a slightly wider distortion cylinder (radius 3.0 to 5.0 times core radius) using uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear_mipmap; as documented in Screen-reading shaders.

Sample a dual-scrolling normal map along the beam axis to offset SCREEN_UV by 0.002 to 0.010 screen UV units, masked by a soft radial falloff and depth fade (hint_depth_texture). After the lance stops firing, decay the shimmer distortion over 0.20 to 0.45 seconds to sell residual thermal wash.

Performance guardrail from Godot docs: Because hint_screen_texture triggers a back-buffer copy (Screen-reading shaders), assign all heat-shimmer meshes to the same render_priority value (e.g., render_priority = 10 to 12) so Godot batches them into a single back-buffer copy per frame.

Molten Trench with Cooling Edges Tied to the Damage Ladder [Proposal]:

As the lance contact point traverses a target hull, stamp overlapping Decal nodes along the sweep path or draw a continuous stroke into a per-ship Godot 4.7 DrawableTexture2D splatmap.

Drive a local thermal decay timer (1.5 to 4.5 seconds cooling curve):

Center of cut (0.0 to 0.8 s after contact): White-yellow molten core ((1.0, 0.85, 0.50) at 2.5 to 4.5 HDR emission) bordered by cooling orange-red slag ((1.0, 0.25, 0.05) at 0.8 to 1.8 HDR emission) and a rough black carbon rim.

Tied to the Damage Ladder:

Intact / Scorched: The trench cools over 1.0 to 2.0 seconds into a dark matte carbon scar (roughness 0.85 to 0.98) with zero lingering orange lines (satisfying R16).

Dented: Enables a deep normal-map groove (normal_scale 1.2 to 2.0) that catches key and rim light along buckled trench lips.

Exposed Structure / Hull Breach: Where the beam crosses a section at exposed structure or hull breach, the trench mask opens an alpha cutout or interior parallax layer revealing charred structural ribs, severed conduits, and a persistent low-rate GPUParticles3D emitter streaming spinning debris fragments, atmosphere vapor, and flickering internal fire out of the gash.

### 4. Engine Trail Ribbons

Four-Layer Thruster Architecture [Lead / Proposal]:
Bind each ship's engine material instance to its faction linear RGB engine colour via set_instance_shader_parameter():

Voidsworn: (1.0, 0.50, 0.16)

Hegemony: (0.45, 0.72, 1.0)

Corsair: (1.0, 0.38, 0.16)

Chorus: (0.80, 0.90, 0.28)

Ithar: (0.62, 1.0, 0.84)

Deathless: (0.15, 1.0, 0.35)

Layer	Godot 4.7 Node / Mesh [Proposal]	Shader & Material Behavior [Proposal]	Feel & Timing Ranges [Proposal]
1. Nozzle Glow	Disc or shallow interior cone MeshInstance3D seated inside the thruster bell.	Unshaded additive Spatial shader with radial UV gradient and view-angle Fresnel boost.	HDR emission 1.2 to 2.0 at idle; ramps to 3.2 to 5.5 over 0.15 to 0.35 s on thrust burn.
2. Core Plume	Tapered cylinder/cone mesh parented to nozzle (local_coords).	High-velocity coherent plasma jet; hosts the shock-diamond banding math (below).	Length scales 0.6 to 3.5 nozzle diameters with throttle; high-frequency UV scroll 10.0 to 24.0 units/s.
3. Outer Plume & Haze	Coaxial wider cone mesh plus short TubeTrailMesh.	Soft depth proximity fade (0.3 to 0.9 units), scrolling 3D noise erosion, lower HDR emission (0.6 to 1.6).	Width 1.4 to 2.2 times core plume; trail lifetime 0.20 to 0.55 s.
4. Wake	World-space GPUParticles3D with trail_enabled = true and RibbonTrailMesh (SHAPE_CROSS).	Alpha-blended or soft-additive dissipative wake; width curve tapers at tail while noise dissolves edges.	Lifetime 0.80 to 2.60 s, sections 6 to 12, section_length 0.15 to 0.45 s (3D Particle trails).

Shock-Diamond Banding [Proposal]:
In the Layer 2 (Core Plume) Spatial shader, generate Mach shock diamonds along the longitudinal coordinate UV.y (where 0.0 is the nozzle exit and 1.0 is the plume tip):

// Proposal: procedural Mach shock-diamond wave for Layer 2 Core Plume
float axial_fade = exp(-UV.y * (1.8)); // tune between 1.5 and 3.5
float radial_core = smoothstep(1.0, 0.15, abs(UV.x * 2.0 - 1.0));
float wave = max(0.0, sin(UV.y * diamond_freq - TIME * (4.0))); // diamond_freq: 14.0 to 28.0
float diamonds = pow(wave, 3.0) * axial_fade * radial_core; // exponent: 2.0 to 4.5
EMISSION = mix(engine_rgb, vec3(1.0), diamonds * 0.65) * (base_energy + diamonds * boost_energy);

Vary diamond_freq between 14.0 and 28.0 as a function of ship acceleration so stationary ships show soft exhaust while boosting ships snap into crisp diamond rings.

Corsair Sputter and Soot Variant [Proposal]:
For Corsair engines (1.0, 0.38, 0.16), sample a 1D Perlin/simplex noise curve over TIME * (4.0 to 9.0 Hz) on the CPU or in a global shader uniform:

Whenever the noise curve drops below a misfire threshold (0.20 to 0.35), drop Layer 2 Core Plume length by 30 to 65 percent for 0.06 to 0.16 seconds and trigger a burst on a child soot GPUParticles3D emitter: 6 to 16 dark matte soot puffs (albedo (0.04, 0.04, 0.04), alpha 0.45 to 0.80, lifetime 0.70 to 1.80 seconds) mixed with 4 to 10 cooling orange cinder sparks.

The High-Speed Spawn Tick-Rate Pitfall & Solutions [Lead / Proposal]:

The Pitfall: When strike craft (sq), torpedoes, or fast corvettes move at high speed relative to the frame tick rate, standard discrete billboard particles spawn at the current frame's node origin only, leaving visible "beaded" gaps between puffs.

Version Note (4.7 Stable vs 4.8 Beta): Godot 4.8 beta 1 introduces a native Trail3D node, which is not available in Godot 4.7 stable. In 4.7 stable, builders have two proven solutions:

Stretched Skinned Ribbon (GPUParticles3D Trails): Enable trail_enabled = true on GPUParticles3D using RibbonTrailMesh or TubeTrailMesh (documented in 3D Particle trails). Because GPU particle trails skin vertices continuously between historical particle positions, fast motion stretches the mesh segments smoothly rather than leaving gaps.

Swept-Segment Sub-Frame Spawning (Custom Particle Shader): For discrete smoke/soot puffs where a continuous ribbon looks wrong, convert ParticleProcessMaterial to a custom ShaderMaterial. Pass uniform vec3 prev_emitter_pos; updated each frame from GDScript. Inside start(), place each newly spawned particle at a random fraction t (in 0.0 to 1.0) along the swept line segment:

float t = rand_from_seed(alt_seed);
TRANSFORM[3].xyz = mix(prev_emitter_pos, EMISSION_TRANSFORM[3].xyz, t) + VELOCITY * (t * DELTA);

This eliminates tick-rate stepping at any ship velocity.

### 5. Damage Decals and the Staged Ladder

Godot 4.7 Decal & Texture Tooling [Lead / Proposal]:

Projected Decal Nodes: Supported in Forward+ and Mobile renderers (documented in Using decals). Each Decal projects texture_albedo, texture_normal, texture_orm, and texture_emission onto matching VisualInstance3D.layers (cull_mask). (Version note: built-in animated decals and Compatibility renderer decals are Godot 4.8 beta 1 features; in 4.7 stable, animate decal glow via modulate / emission_energy tweens or hull shader masks).

Godot 4.7 DrawableTexture2D Splatmap [Proposal]: New in Godot 4.7 stable (GH-105701), DrawableTexture2D lets code blit damage stamps directly onto a per-ship RGBA mask texture on the GPU without creating heavy SubViewport nodes for every ship in a fleet. Map channels as: R = Scorch, G = Dent depth, B = Exposed structure / Breach cutout, A = Bio corrosion.

Staged Damage Ladder Implementation (R16 Compliant) [Proposal]:

Ladder Stage	Visual & Shader Treatment in Godot 4.7 [Proposal]	Streaming Parts, Fire & Particle Tie-In (R16) [Proposal]
1. Intact	Base hull ORMMaterial3D or custom hull ShaderMaterial; DrawableTexture2D mask cleared to (0,0,0,0); zero active Decal nodes.	None. Normal thruster and running-light operation.
2. Scorched	Procedural scorch: Stamp Decal nodes (albedo_mix 0.65 to 0.90, ORM roughness 0.82 to 0.96) or blit into the R channel of DrawableTexture2D. Blend radial Perlin/Worley noise in the hull shader to soot-darken paint and strip metallic specular.	Transient impact smoke dissipates over 0.5 to 1.5 s; no permanent glowing orange cracks.
3. Dented	Dent normal-map: Spawn Decal nodes with albedo_mix set low (0.0 to 0.25) so they primarily override texture_normal and texture_orm (per Decal docs, texture_albedo alpha still masks the normal/ORM projection). Warps specular highlights across crumpled armor plates over 0.6 to 2.5 unit footprints.	Occasional micro-sparks (2 to 6 particles every 1.5 to 4.0 s) from strained armor seams.
4. Exposed Structure	Where DrawableTexture2D.b or a structural decal exceeds 0.40 to 0.60, the hull shader switches to a 2-layer interior parallax map (depth 0.04 to 0.10 UV units) showing darkened ribs, cross-trusses, and severed cables beneath the outer skin.	Attach 1 to 3 low-rate GPUParticles3D vents (4 to 12 particles/s) streaming white atmosphere condensation and tumbling hull insulation flakes.
5. Hull Breach	Breach geometry vs decal (below): Cut open real 3D cavities or alpha-scissored interior boxes rather than painting flat orange decals. Darken cavity interiors and rim them with torn metal normal maps.	Continuous R16 emitters inside the cavity: turbulent interior fire plumes (lifetime 0.40 to 1.10 s), electrical arcs, and a steady stream (6 to 18 parts/s) of spinning internal machinery and hull plates drifting into space.
6. Wreck	Freeze DrawableTexture2D updates; ramp hull emission_energy_multiplier down to 0.0 to 0.15 over 1.0 to 2.5 s; apply global soot darkening (30 to 55 percent albedo reduction) across broken hull sections.	Throttle active emitters down to 1 to 2 lingering smolder/debris streams (2 to 5 particles/s) plus persistent floating wreck-field chunks.

Breach Geometry versus Decal Trade-Off [Proposal]:

Decal + Alpha Cutout + Interior Box (Medium Hits / Corvettes): Project a Decal or DrawableTexture2D mask that drives ALPHA_SCISSOR_THRESHOLD (0.45 to 0.55) on the outer hull mesh, revealing a pre-authored low-poly "damage interior" mesh nested 0.2 to 0.8 units inside the ship. Fast, zero mesh-slicing CPU cost, and reads with true parallax depth at all camera angles.

Swappable Breach Socket Geometry (Heavy Hits / Capital Ships): Pre-author 3 to 8 modular armor sockets on large hulls. When a zone enters hull breach, hide the intact armor sub-mesh and unhide a jagged, inward-peeled cavity mesh with real 3D framing ribs and embedded GPUParticles3D spawners. Avoid runtime CSGShape3D booleans during combat, as Godot's CSG nodes are intended for level prototyping and cause CPU frame spikes when rebuilt dynamically.

Corrosion Skin Variant for bio [Proposal]:

When bio weapons hit a hull, increment the A channel of the ship's DrawableTexture2D mask (or project a bio-specific Decal).

In the hull Spatial shader, use that mask to blend in a cellular Voronoi corrosion pattern: displace vertices inward along -NORMAL by 0.02 to 0.08 units, shift surface roughness to either slick bio-resin (0.12 to 0.28) or pitted acid-etched metal (0.85 to 0.98), and pulse faint emissive veins (0.4 to 1.3 HDR energy) in Chorus (0.85, 0.90, 0.30) or Deathless (0.20, 1.0, 0.38) linear RGB.

Wreck-Field Persistence [Proposal]:

Enable Decal.distance_fade_enabled = true on all damage decals (distance_fade_begin 40.0 to 70.0 units, distance_fade_length 10.0 to 25.0 units) so distant wrecks automatically cull decal projection shader cost.

When ships shed structural parts or transition to wreck, hand off their detached static debris meshes to a battlefield-wide MultiMeshInstance3D ring buffer (capped at 300 to 800 instances across the hex grid). As particles or hull sections settle to near-zero velocity, bake their final Transform3D into the MultiMesh so the hex map accumulates a persistent, near-zero-draw-call graveyard for the rest of the battle.

### 6. Ship Death and Wreck Sequence

Timeline-Driven Cook-Off [Lead / Proposal]:
Use AnimationPlayer (taking advantage of Godot 4.7's collapsible animation track groups noted in the Coding Quests 4.7 guide to organize VFX, Audio, Shader, and Section tracks) to drive a 1.8 to 4.5 second ship death timeline:

0.0 to 1.2 s (Internal Cook-Off): Trigger 2 to 5 staggered method-call keys spaced 0.35 to 0.55 seconds apart (never faster, to obey the 3-flashes-per-second cap). Each cue fires an internal compartment blowout through existing hull breach sockets: a jet of fire and spinning interior parts (0.30 to 0.70 s) while interior emissive windows flicker and die.

1.0 to 2.2 s (Power & Engine Failure): Tween the hull material's emission_energy_multiplier and thruster nozzle glow from combat levels down to 0.0 with 1 to 2 brief sputter steps.

1.5 to 3.0 s (Structural Break-Up into Sections): Hide the intact parent MeshInstance3D and enable 2 to 5 pre-fractured hull section nodes (bow, midships, reactor spine, stern). Apply a local separating impulse (linear drift 0.4 to 2.2 units/s, angular tumble 0.05 to 0.30 rad/s with linear/angular damping 0.3 to 0.8) so the sections drift apart and settle into the wreck damage-ladder state. Spawn a dense curtain of torn girders, hull plates, and venting gas along the fracture plane.

Optional Final Blast for Heavy Ships [Proposal]:

On heavy ships [UNSURE - exact heavy ship class names not in context], append an optional final reactor detonation track at 2.2 to 3.8 seconds:

Pre-blast suck-in (0.15 to 0.30 s): Radial inward particle ring and a brief dimming of nearby fire.

Main blast (0.80 to 1.80 s): An expanding spherical core of boiling plasma + a planar hex-aligned shockwave ring mesh (ShaderMaterial with Fresnel alpha and hint_screen_texture refraction) + 30 to 80 flaming hull chunks ejected outward.

Flash-safe envelope: Ramp blast luminance up over 0.20 to 0.35 seconds and decay over 0.70 to 1.40 seconds (a single smooth envelope rather than rapid strobing).

Camera Shake and Slow-Motion (Optional and Off by Default) [Proposal]:

Define two explicit user settings in config: vfx_camera_shake_enabled = false and vfx_death_slowmo_enabled = false by default.

When vfx_camera_shake_enabled == true: Feed a trauma float (0.2 to 0.6 for heavy ship deaths) into the tactical Camera3D, driving h_offset and v_offset via 1D FastNoiseLite sampled at 12.0 to 22.0 Hz with a max displacement of 0.02 to 0.07 units and quadratic decay (trauma * trauma) over 0.40 to 0.90 seconds.

When vfx_death_slowmo_enabled == true: On a heavy ship final blast, create an unscaled tween (get_tree().create_tween().set_ignore_time_scale(true)) that dips Engine.time_scale to 0.70 to 0.85 for 0.25 to 0.50 seconds of real wall-clock time before smoothly restoring 1.0. When the setting is off (default), skip the tween completely.

### 7. Lighting and Post (Open A5 Items)

Workflow Order: Lighting First, Then Materials, Then Post [Lead / Proposal]:
Build a dedicated A5_LookDev_Calibration.tscn test bench in Godot 4.7. Note that Godot 4.7 optimizes multi-pass 3D rendering by giving every pass its own unique environment uniform buffer (GH-115177 in Godot 4.7 dev 1) and adds desktop HDR output (Ziva 4.7 overview). Enforce a strict 3-step pass:

Step 1 - Lighting Only: Disable glow_enabled in Environment. Place neutral 18-percent grey, matte white (0.80 albedo), and chrome reference spheres beside ship hulls. Tune key light, cool fill, and prefiltered sky radiance first.

Step 2 - Materials & Emissive Slot: Tune ship PBR ORMMaterial3D albedo/roughness/metallic values so lit hulls never exceed diffuse scene luminance of 0.40 to 0.48. Author all glowing ship ports, shields, and weapons exclusively on the dedicated emissive slot (emission_enabled = true, emission_texture).

Step 3 - Post-Processing & Tone Mapper Test: Enable glow before tone mapping, set bloom threshold, and run the luminance background scan.

Concrete Godot 4.7 Settings for Open A5 Items [Proposal]:

Open A5 Item	Godot 4.7 Implementation & Properties [Proposal]	Recommended Tuning Range [Proposal]
Single Key + Cool Fill + Fresnel Rim	Key: One DirectionalLight3D (shadow_enabled = true). Cool fill: Opposing shadowless DirectionalLight3D (or sky ambient tint) in cool blue-slate (0.55, 0.70, 0.95). Fresnel rim: Enable rim_enabled = true on StandardMaterial3D or add a view-normal Fresnel rim term in the hull shader.	Key light_energy 1.0 to 1.5; Cool fill energy 25 to 40 percent of key (0.25 to 0.60); Material rim 0.25 to 0.55, rim_tint 0.35 to 0.70.
Prefiltered Environment Map	Configure WorldEnvironment with a Sky resource (PanoramaSkyMaterial). Set Sky.process_mode = PROCESS_MODE_QUALITY so Godot prefilters GGX importance-sampled roughness mipmaps across the cubemap. (Note: PrefilteredTexture for textured AreaLight3D is deferred past 4.7 per Ziva 4.7 notes; sky cubemap prefiltering is stable in 4.7).	Sky.radiance_size set to 256 to 512; ambient_light_sky_contribution 0.60 to 0.90; reflected_light_source = REFLECTION_SOURCE_SKY.
Tone Mapper Test (AgX vs Neutral)	Set on Environment.tonemap_mode (documented in Environment and post-processing). AgX (TONE_MAPPER_AGX): Smoothly desaturates bright HDR emissives (energy 2.0 to 6.0) toward white, giving lances, thrusters, and explosions automatic white-hot cores while keeping faction colour in the outer bloom. Can slightly mute mid-tone greens/yellows (Chorus/Deathless). Neutral (TONE_MAPPER_NEUTRAL): Keeps faction linear RGB hues true with minimal chroma shift, but clips bright cores abruptly unless white cores are painted directly into particle colour ramps.	Test tonemap_exposure 0.90 to 1.15 across all 6 factions in an A/B switcher before locking.
Emissive on Its Own Slot	Keep base albedo_texture strictly reflective (zero baked glow). Put all self-illumination in emission_texture on BaseMaterial3D (emission_operator = EMISSION_OP_MULTIPLY or EMISSION_OP_ADD) or write directly to EMISSION in Spatial shaders.	Hull running lights 1.2 to 2.5 HDR energy; combat weapons/thrusters 2.0 to 5.5 HDR energy; wrecks 0.0 to 0.15.
Glow Before Tone Mapping & Bloom Threshold	In Godot 4's Forward+ pipeline, Environment evaluates the HDR glow downsample chain in linear scene space prior to tone mapping (glow_enabled = true, glow_blend_mode = GLOW_BLEND_MODE_SOFTLIGHT or ADDITIVE). Set glow_hdr_threshold to the target 0.5 to 1.0 range.	glow_hdr_threshold 0.50 to 1.00; glow_hdr_scale 1.5 to 2.5; glow_intensity 0.35 to 0.75; glow_bloom 0.0 to 0.10.
Luminance Background Scan	Because glow_hdr_threshold can sit as low as 0.50, run an automated validation pass that renders the skybox and lit intact hulls without VFX, downsamples the viewport (get_viewport().get_texture().get_image()), and checks pixel luminance dot(rgb, vec3(0.2126, 0.7152, 0.0722)).	Verify 99 percent of background and non-emissive hull pixels stay below 0.42 to 0.48 linear luminance so nebulas and hull armor never false-trigger bloom.
Screen-Size Effect LOD (with Check That It Is On)	Combine automatic mesh LOD (Mesh level of detail (LOD)) with GeometryInstance3D.visibility_range_begin / end (VISIBILITY_RANGE_FADE_SELF on Forward+) and dynamic GPUParticles3D.amount_ratio scaling based on projected screen height (aabb_size / camera_dist). Runtime check: Add an autoload assert() at scene boot verifying get_viewport().mesh_lod_threshold is between 1.0 and 2.5 pixels (not 0.0) and logging an error if any spawned VFX prefab has visibility_range_end == 0.0.	Micro-sparks cull at 40 to 80 units; impact plumes at 120 to 220 units; amount_ratio scales from 0.85 to 1.00 close-up down to 0.15 to 0.35 at wide tactical zoom.
VFX Importance Band	Tag every effect prefab with an enum (BAND_1_CRITICAL, BAND_2_TACTICAL, BAND_3_AMBIENT) managed by a central VFX budget autoload.	Band 1 (torp 750 to 850 ms white telegraph, interception call, lance beam, shield hit): amount_ratio 0.80 to 1.00, never culled. Band 2 (battery/flak/gauss/bio hits, engine cores): amount_ratio 0.35 to 0.80. Band 3 (wreck smoke, secondary sparks, shimmer): throttled to 0.10 to 0.30 or culled first when active emitters exceed 40 to 80 simultaneous systems.

### 8. Accessibility Implementation in Godot

Target Rule: At most 3 flashes per second anywhere on screen (targeting 1 to 3 flashes per second during heavy combat), plus a user-toggleable Reduce Flashing option.

1. Global Flash Counter & Merge Window for Concurrent Flashes [Proposal]:

Spatial-Temporal Flash Governor (VFXFlashGovernor Autoload):

Divide the camera screen space into an 8x4 to 16x9 tile grid (plus a global full-screen counter).

Every transient high-luminance event (muzzle flash, flak airburst, gauss impact, torpedo detonation, Corsair shield stutter, cook-off pop) calls VFXFlashGovernor.request_flash(world_pos, requested_energy) before emitting light or spiking HDR shader energy.

The 330 to 400 ms Merge Window: When a flash is approved in a screen tile (or globally) at time t_0, the governor opens an active flash envelope lasting 330 to 400 ms (which mathematically guarantees fewer than 3 distinct flash peaks per 1000 ms second):

Attack: 40 to 70 ms smooth ramp up.

Sustain / Merge Plateau: 130 to 180 ms. Any concurrent impacts arriving in the same region during this window merge into the existing plateau instead of triggering a new dark-to-bright spike. Their physical debris and smoke particles still spawn at 100 percent visibility, but their additive flash/light energy is clamped to the plateau ceiling (1.5 to 2.5 HDR energy) and extends the sustain by at most 30 to 60 ms before a mandatory decay.

Decay & Cooldown: 160 to 200 ms smooth ramp down, during which new flash spikes in that region are suppressed to non-flashing base emission (0.8 to 1.2 HDR energy).

2. Reduce-Flashing Replacements [Proposal]:
Register global shader uniforms in Godot's Project Settings (global uniform float a11y_flash_multiplier = 1.0; and global uniform float a11y_flicker_damp = 0.0;, documented in Spatial shaders):

When Reduce Flashing is turned ON (a11y_flash_multiplier set to 0.25 to 0.40, a11y_flicker_damp set to 1.0):

Weapon Muzzles & Impacts: Clamp peak HDR emission on all muzzle, flak, gauss, and torpedo impact shaders to 0.8 to 1.3 (below or barely at the bloom threshold) and stretch their alpha fade-in/fade-out envelopes to 250 to 500 ms so hits read via expanding smoke, shrapnel streaks, and hull debris rather than brightness spikes.

Corsair Shield & Engine Replacement: In the Corsair shield and engine shaders, mix(flicker_wave, 1.0, a11y_flicker_damp) disables the 8 to 16 Hz temporal stutter and replaces it with a slow, continuous spatial noise drift (0.4 to 1.0 Hz) while keeping the patchy holes and black soot puffs intact.

Torpedo Telegraph Replacement: Keep the two-stage 750 to 850 ms ramp to white, but enforce a strictly monotonic linear/cubic easing curve with zero terminal blinking, relying on the contracting targeting ring and colour shift from faction RGB to matte white (0.9, 0.9, 0.9).

3. How to Test a Worst-Case Mixed Salvo in Godot 4.7 [Proposal]:
Build an automated test scene (A5_WorstCase_Salvo_Test.tscn) wired to a RenderingServer.frame_post_draw verification script:

Salvo Scenario Setup: Spawn two opposing capital hulls and a strike-craft swarm inside a 1.5 to 3.0 second overlapping window firing simultaneously:

Heavy Gauss Broadside: 8 to 16 simultaneous hyper-velocity rail streaks and high-energy kinetic spall impacts.

Heavy Torp Volley: 12 to 24 incoming torpedoes completing their 750 to 850 ms white telegraph ramps simultaneously, with half triggering hull detonations and half triggering interception calls.

Mass Strike-Craft (sq) Deaths: 15 to 30 strike craft spiraling and popping via sub-emitters in the same hex cluster.

Flak Screen: 25 to 60 overlapping airbursts detonating across the camera foreground.

Automated Frame-Luminance Telemetry:

On every rendered frame (frame_post_draw), downsample the main ViewportTexture to a 32x18 grid of screen regions.

Convert each region's average RGB to relative luminance Y = 0.2126R + 0.7152G + 0.0722B.

Count a "flash transition" whenever a region's luminance rises and falls by more than 10 to 20 percent of peak display luminance within a rolling 1000 ms window.

Assert that across a 5.0 to 10.0 second capture at 60 to 144 FPS, zero regions reach more than 3 flashes per second in standard mode, and zero regions exceed 0 to 1 flash per second with Reduce Flashing enabled.

Sources

Godot Docs - GPUParticles3D Class Reference: https://docs.godotengine.org/en/stable/classes/class_gpuparticles3d.html

Godot Docs - Particle Systems (3D) Index: https://docs.godotengine.org/en/stable/tutorials/3d/particles/index.html

Godot Docs - Creating a 3D Particle System: https://docs.godotengine.org/en/stable/tutorials/3d/particles/creating_a_3d_particle_system.html

Godot Docs - Process Material Properties: https://docs.godotengine.org/en/stable/tutorials/3d/particles/process_material_properties.html

Godot Docs - Particle Sub-Emitters: https://docs.godotengine.org/en/stable/tutorials/3d/particles/subemitters.html

Godot Docs - 3D Particle Trails: https://docs.godotengine.org/en/stable/tutorials/3d/particles/trails.html

Godot Docs - Particle Turbulence: https://docs.godotengine.org/en/stable/tutorials/3d/particles/turbulence.html

Godot Docs - RibbonTrailMesh Class Reference: https://docs.godotengine.org/en/stable/classes/class_ribbontrailmesh.html

Godot Docs - TubeTrailMesh Class Reference: https://docs.godotengine.org/en/stable/classes/class_tubetrailmesh.html

Godot Docs - ShaderMaterial Class Reference: https://docs.godotengine.org/en/stable/classes/class_shadermaterial.html

Godot Docs - StandardMaterial3D Class Reference: https://docs.godotengine.org/en/stable/classes/class_standardmaterial3d.html

Godot Docs - Spatial Shaders Reference: https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html

Godot Docs - Screen-Reading Shaders: https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html

Godot Docs - Decal Class Reference: https://docs.godotengine.org/en/stable/classes/class_decal.html

Godot Docs - Using Decals: https://docs.godotengine.org/en/stable/tutorials/3d/using_decals.html

Godot Docs - AnimationPlayer Class Reference: https://docs.godotengine.org/en/stable/classes/class_animationplayer.html

Godot Docs - Environment Class Reference: https://docs.godotengine.org/en/stable/classes/class_environment.html

Godot Docs - Environment and Post-Processing: https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html

Godot Docs - Sky Class Reference: https://docs.godotengine.org/en/stable/classes/class_sky.html

Godot Docs - GeometryInstance3D Class Reference: https://docs.godotengine.org/en/stable/classes/class_geometryinstance3d.html

Godot Docs - Mesh Level of Detail (LOD): https://docs.godotengine.org/en/stable/tutorials/3d/mesh_lod.html

Godot Docs - Visibility Ranges (HLOD): https://docs.godotengine.org/en/stable/tutorials/3d/visibility_ranges.html

Godot Shaders - Fresnel Snippet: https://godotshaders.com/snippet/fresnel/

Godot Shaders - Glowing Shield/Beam/Buble/Magic/Frost Fresnel: https://godotshaders.com/shader/glowing-shield-beam-buble-dark-magic-fresnel/

Godot Shaders - Shield Shader with Intersection Highlight: https://godotshaders.com/shader/shield-shader-with-intersection-highlight/

Godot Shaders - Procedural Hex Barrier for Godot 4: https://godotshaders.com/shader/procedural-hex-barrier-shader-for-godot-4/

Godot Shaders - Hexagon Shield: https://godotshaders.com/shader/hexagon-shield/

Godot Engine Official Blog - Dev Snapshot: Godot 4.7 Dev 1: https://godotengine.org/article/dev-snapshot-godot-4-7-dev-1/

Godot Engine Official Blog - Dev Snapshot: Godot 4.7 Dev 5 (Inline Shader Previews): https://godotengine.org/article/dev-snapshot-godot-4-7-dev-5/

Godot Engine Official Blog - Release Candidate: Godot 4.7 RC 1: https://godotengine.org/article/release-candidate-godot-4-7-rc-1/

Ziva - Godot 4.7: Stable Release Date, HDR & Key Features: https://ziva.sh/blogs/godot-4-7

CG Channel - Discover 5 Key Features for CG Artists in Godot 4.7: https://www.cgchannel.com/2026/06/discover-5-key-features-for-cg-artists-in-godot-4-7/

Coding Quests - Godot 4.7: Everything New (Features Guide): https://codingquests.io/blog/godot-4-7-everything-new

Godot Engine Official Blog - Dev Snapshot: Godot 4.8 Beta 1: https://godotengine.org/article/dev-snapshot-godot-4-8-beta-1/

GodotAwesome - Godot 4.8 Beta: What's New and What Breaks: https://godotawesome.com/godot-4-8/

End of Gemini reply.
