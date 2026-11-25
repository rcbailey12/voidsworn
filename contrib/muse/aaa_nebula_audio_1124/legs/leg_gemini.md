# Leg: Gemini on Hydrogen (the Flash seat), issue 2061

Gate record: signed in with the saved Google login, no phone tap needed. Model picker verified on "Everyday help - 4 Hydrogen" before pasting and still on Hydrogen after generation. Brief pasted as plain text, no file attached. Chat: "Nebula Visuals and Biome Ambience Plan", https://gemini.google.com/app/6ada3b6e82484978
Chair note: the model's raw response used em dashes; they are normalized to commas or colons in this copy to meet the repo's no-dash rule. Wording is otherwise verbatim.

Response verbatim (dash-normalized):

Question 1: Layered Nebula Clouds

To turn flat tinted patches into massive, volumetric structures under a fixed overhead camera, drawing from techniques used in Homeworld: Deserts of Kharak (ground dust/smoke), Stellaris, and Sins of a Solar Empire II, we avoid expensive raymarching and instead use parallax-offset multi-planar alpha-blended cards with procedural domain-warped density and directional rim lighting.

1. The Concrete Recipe

Layer Architecture (4 Vertical Planes):
All nebula patches in a single sector are batched into 4 world-space horizontal planes (MultiMeshInstance3D or single merged patch meshes per layer) positioned relative to the tactical board plane (Y = 0.0):

Layer 0 (Deep Under-Bed, Y = -12.0 m): The vast, low-frequency anchor. Uses a 1024x1024 seamless packed texture (R: base cloud macro-shape, G: low-frequency turbulence, B: temperature mask). Standard alpha blending (mix), opacity capped at 0.45. Drifts at 0.15 m/s along the sector wind vector.

Layer 1 (Lower Core & Dust Lanes, Y = -4.5 m): Carries the primary body and dark occlusion. Uses a 1024x1024 detail texture (R: medium fBm noise, G: ridge/filament noise for dust lanes, B: normal/gradient X, A: normal/gradient Y). Uses premultiplied alpha blending so dark dust lanes can absorb light (darken the layer below) without washing out to grey. Drifts at 0.35 m/s at a +12 degree offset from Layer 0.

Layer 2 (Upper Rim-Lit Wisps, Y = -1.2 m): Just below the ship hulls (assuming ship keels sit at Y = 0.0 to +0.5 m). High-frequency wispy edges (R: fine curl-warped noise, G: edge breakup). Additive-alpha hybrid blending (blend_mix with emissive rim boost). Drifts at 0.55 m/s at a -8 degree offset.

Layer 3 (Subtle Ship-Grazing Veil, Y = +1.8 m): Sits above smaller hulls and clips/interacts with capital ship upper superstructures. Very low opacity (0.08 to 0.14 max), large scale, zero high-frequency detail. Gives ships the feeling of sitting inside the upper atmosphere of the cloud rather than floating on top of a rug. Uses depth-fade (proximity_fade in Godot 4) so it softly wraps around ship geometry without hard intersection seams.

Edge & Dust Lane Formation:

Organic Spillover Edge: Instead of masking the cloud to the hex polygon, each hex tagged as "nebula" spawns overlapping circular/elliptical soft falloff metaballs whose radii are 1.6x to 2.2x the hex radius. In the shader, world-space UV coordinates sample a domain-warped noise texture to distort the metaball distance field before applying a smoothstep(0.15, 0.75, density) ramp. This ensures the cloud spills raggedly across hex borders.

Dark Dust Lanes: In Layer 1, ridge noise (1.0 - abs(noise * 2.0 - 1.0)) raised to a power of 3.5 carves dark, cool charcoal-slate veins (#14191D) through the cloud body. Because Layer 1 uses premultiplied alpha with low RGB and high alpha in these veins, it physically blocks the brighter Layer 0 underneath, creating instant 3D shelf depth.

Rim Lighting: A single global directional key light vector (matching the sector's star direction) is passed to the nebula shader. Using the pre-baked XY density gradients (B and A channels of Layer 1/2), the shader computes dot(gradient_xy, key_light_xy) and boosts the edge brightness where density is between 0.2 and 0.5, creating sunlit silver-teal or warm ember rims along the cloud shelves facing the star.

Colour Rules (Strictly Enforced):

Palette is locked to three ramp stops driven by the B (temperature) channel: Deep Smoke Grey (#1E2429) in dense/occluded zones, Muted Slate Teal (#2D4F56 to #48737A) in mid-density illuminated zones, and Subtle Ember (#8A4226 to #B85A32) strictly confined to thin, high-energy rim-lit edges (< 15% of total cloud area).

Shader includes a hard HSV/RGB clamp preventing saturation above 0.42 and ensuring zero magenta/purple or yellow-green/mustard hue drift when additive rims overlap teal bases.

2. GPU Cost Argument (4K / RTX 5080 & Scalability)

Where Frame Time Goes: At 3840x2160 (8.29M pixels), vertex cost is negligible (< 0.05 ms), and texture fetches are cheap (3 bilinear samples per layer). Overdraw (pixel fill-rate and ROP blending) is 90% of the cost. If a nebula covers 50% of the screen across 4 overlapping layers, that is ~16.5M shaded and blended pixels per frame.

Estimated Frame Time: On an RTX 5080 (which has massive memory bandwidth and ROP throughput), 4 full-coverage layers with 3 texture lookups, domain warping, and 1 depth-buffer read (DEPTH_TEXTURE on Layer 3 only) will cost 0.65 ms to 1.10 ms at native 4K, well inside a 12.5 ms (80 FPS) budget.

Scaling Down for Lower Presets:

Medium Preset: Drop Layer 3 (the depth-faded upper veil) entirely, eliminating the DEPTH_TEXTURE fetch and MSAA resolve overhead. Merge Layer 0 and Layer 1 into a single parallax-offset (Parallax Occlusion / 2-tap UV offset) plane. Drops cost by ~55%.

Low / Steam Deck Preset: Render the nebula pass into a half-resolution (0.5x width, 0.5x height) offscreen viewport using 2 layers, then bilinear-upsample behind the ship pass. Cuts pixel fill cost by 75%+ (< 0.25 ms) while the soft, blurry nature of gas clouds hides the lower render resolution completely.

3. Readability Guarantee

Hex Grid: Rendered at Y = +0.02 m (above Layers 0-2, below Layer 3). Because Layer 3 is capped at 0.14 opacity and has zero high-frequency contrast, the grid lines remain crisp. Grid shader uses a subtle 15% luminance boost over whatever pixel lies beneath it so lines never vanish over bright ember rims.

Ship Models: Ships sit at Y = 0.0 m to +2.5 m. Layers 0, 1, and 2 sit physically below Y = -1.2 m, meaning ship silhouettes are 100% unoccluded from below. Layer 3's proximity_fade pulls opacity to 0.0 within 0.8 m of ship hulls, ensuring hull panel lines and faction markings stay sharp.

Ship Markers & Selection State: Rendered in a dedicated post-nebula pass (or with no_depth_test + UI overlay layer at Y = +3.0 m) so selection rings, health pips, and facing arcs never get tinted or obscured by Layer 3.

Nebula Patch Outline (Owner Ruling): Rendered as a crisp, thin (1.5 px screen-space constant width) SDF contour line at Y = +0.05 m following the true logical hex-boundary of the nebula effect. Because the volumetric gas visibly spills outside this clean tactical boundary line, the player sees both the exact mechanical rules boundary and a massive continuous cloud.

4. Honouring the Scale Ruling (R247)

Parallax Separation: With 13.8 m of vertical separation between Layer 0 (Y = -12.0 m) and Layer 3 (Y = +1.8 m), panning the camera across the board produces unmistakable physical parallax: the deep gas bed lags behind the hex grid while the upper wisps glide with the ships.

World-Space Texture Mapping: Noise UVs are bound to sector world coordinates, not individual hex UVs. A single noise wavelength spans 18 to 25 hexes across. Consequently, adjacent nebula hexes merge into one continuous continent of gas, and isolated 1-hex nebula patches look like tiny windows into a much larger subterranean cloud layer rather than self-contained cotton balls.

5. Least-Sure Decision & Biggest Risk

Least-Sure Decision: Setting Layer 3 (Y = +1.8 m) above the ships. While it sells volumetric immersion, even 12% opacity over small fighter/corvette hulls could reduce contrast during zoomed-out play. It may need to be disabled automatically when the camera zooms out past 60% altitude.

Biggest Risk: Visual muddiness when ember rims overlap slate-teal clouds. Because purple and mustard are banned, any additive or screen-blending math between warm orange-red (#B85A32) and cool blue-green (#48737A) naturally passes through desaturated grey-brown or muddy olive in linear color space. The shader must enforce hue-preserving lerp ramps rather than raw additive RGB blending.

Question 2: Biome Ambience Plan

To fit Issue 2034's mix architecture (separate channels for Effects, Tactical, Music, and a dedicated Ambience sub-bus under Environment), all beds avoid high-frequency white/pink noise above 3.5 kHz (eliminating any rain/hiss perception) and avoid rhythmic transients or synth arpeggios.

1. Nebula

One-Line Description: A massive, slow-breathing sub-bass pressure wave with hollow, resonant metallic-hull groans in the far distance.

Layer Plan:

Base Layer: Warm, heavily low-pass filtered (180 Hz cutoff) stereo drone built from slowed-down bowed contrabass and resonant pipe air, pure warm pressure, zero hiss.

Swell/Movement Layer: Two overlapping 22-second and 31-second sinusoidal filter-swept bandpass swells (220 Hz to 520 Hz) panning slowly (0.04 Hz LFO) across the stereo field to match the visual drift of the gas.

Sparse Character Sounds: Every 25-45 seconds, a single muffled, distant hull-creak or low electromagnetic inductance thrum (140 Hz-300 Hz, -24 LUFS, 4-second reverb tail), simulating static discharge on ship plating.

Combat Ducking & Mix Behavior:

Bus: Environment / Ambience_Bed (base + swells) and Environment / Ambience_Spot (character sounds).

Loud Combat Duck: Sidechained to the Effects bus; drops -6 dB (150 ms attack, 1.8 s release) during active weapon fire/explosions.

Tense Moments: When objective urgency rises (music intensity > 0.7), the swell layer's bandpass narrows and shifts up +80 Hz to add subtle harmonic tension without increasing volume. On a capital ship death, Ambience_Spot is muted for 3 seconds and Ambience_Bed ducks -10 dB to leave a vacuum before the shockwave hits.

2. Asteroid Field

One-Line Description: Deep, dry lithic silence punctuated by ultra-low sub-harmonic rumbles when massive rocks grind past each other in the distance.

Layer Plan:

Base Layer: Near-silent room-tone vacuum bed (-38 LUFS), ultra-low 45 Hz-90 Hz seismic floor (tactile weight felt more than heard).

Swell/Movement Layer: Slow, non-periodic amplitude modulation (14-19 s cycles) of a muted, granular sub-octave rumble (80 Hz-160 Hz), pitched down 3 octaves from glacial ice/rock friction recordings, no gravel patter, only massive geological weight.

Sparse Character Sounds: Every 30-50 seconds, a dull, single low-end thud (60 Hz-120 Hz, zero high-end click) like two giant boulders colliding miles away through hull-coupled vibrations.

Combat Ducking & Mix Behavior:

Bus: Environment / Ambience_Bed and Environment / Ambience_Spot.

Loud Combat Duck: Drops -8 dB during combat (the dry transient space is needed so kinetic autocannons and railguns pop cleanly).

Tense Moments: When objective urgency rises, the granular swell rate increases slightly (1.2x speed) but volume stays flat. On capital ship death, full -12 dB duck for 2.5 seconds.

3. Dead Star (White Dwarf / Cooling Remnant)

One-Line Description: A taut, oppressive magnetic hum with slow, rhythmic pulsar-like bass pulses that feel like radiation pressure against the hull.

Layer Plan:

Base Layer: Clean, steady 60 Hz + 120 Hz transformer/magnetosphere harmonic hum, completely smooth, zero crackle or static.

Swell/Movement Layer: A slow, hypnotic 7.5-second periodic pulse (0.13 Hz) where a warm 180 Hz resonant harmonic swells +3 dB and recedes, evoking a dead star's slow rotation period.

Sparse Character Sounds: Every 35-60 seconds, a deep, hollow glass-bowl or bowed-metal harmonic swell (340 Hz pure sine-like overtone, 5-second fade-in/out) representing gravitational/magnetic shear.

Combat Ducking & Mix Behavior:

Bus: Environment / Ambience_Bed.

Loud Combat Duck: Drops -7 dB during weapon bursts so the 60/120 Hz hum never muddies explosion low-end.

Tense Moments: As objective urgency climbs, the 7.5-second magnetic pulse subtly tightens to 5.5 seconds (crossfaded via RTPC), subconsciously raising player pulse without adding extra audio layers. Capital ship death triggers a 2-second hard notch cut at 120 Hz and -9 dB overall duck.

4. Planet Orbit

One-Line Description: A vast, serene low-frequency planetary resonance with slow, majestic tonal shifts as the fleet drifts across the terminator line.

Layer Plan:

Base Layer: Broad, warm stereo pad built from slowed-down choral/brass fundamentals stripped of all breath and attack (90 Hz-240 Hz), giving a sense of immense planetary mass below.

Swell/Movement Layer: Ultra-slow (40-second cycle) crossfade between a slightly brighter "daylight side" harmonic (260 Hz overtone) and a darker "night side" sub-fundamental (75 Hz).

Sparse Character Sounds: Every 40-60 seconds, a single muted telemetry/atmospheric bounce, a soft, pitch-bent low bell tone (280 Hz bending down to 255 Hz, heavily diffused, acoustic/analog character, never a digital beep).

Combat Ducking & Mix Behavior:

Bus: Environment / Ambience_Bed.

Loud Combat Duck: Drops -5 dB (since this bed is smooth and non-competing, it requires less aggressive ducking).

Tense Moments: During high objective urgency, the daylight harmonic overtone ducks -4 dB leaving only the darker night-side fundamental. Capital ship death ducks -9 dB over 2 seconds.

5. Station (Orbital Drydock / Relay Complex)

One-Line Description: The heavy, grounded mechanical thrum of distant reactor turbines and structural bulkhead vibrations transmitted through vacuum.

Layer Plan:

Base Layer: Tight, rhythmic-free industrial foundation: a steady 55 Hz turbine fundamental paired with a warm 110 Hz fifth, heavily damped (LPF at 220 Hz).

Swell/Movement Layer: Slow 18-second cycle of a distant hydraulic/coolant circulation hum (160 Hz-280 Hz) that rises gently and settles, suggesting massive off-screen machinery.

Sparse Character Sounds: Every 20-35 seconds, a heavy, low-frequency mechanical lock or docking clamp reverberation (90 Hz thump + 210 Hz metallic ring, 3-second decay), tactile, heavy, zero high-frequency hiss or steam venting.

Combat Ducking & Mix Behavior:

Bus: Environment / Ambience_Bed and Environment / Ambience_Spot.

Loud Combat Duck: Drops -7 dB during combat; Ambience_Spot (docking thumps) is completely suppressed whenever Effects bus activity exceeds -18 LUFS so mechanical thuds are never mistaken for incoming ordnance.

Tense Moments: When objective urgency rises (e.g., a relay changing hands), the turbine base shifts up +1.5 semitones over 10 seconds (mimicking reactor spin-up). Capital ship death ducks -11 dB.

6. Deep Space

One-Line Description: Cold, near-total acoustic emptiness, just the faintest sub-audible hull floor and rare, lonely inertial creaks.

Layer Plan:

Base Layer: Minimalist floor (-42 LUFS) at 40 Hz-75 Hz, purely to prevent the audio engine from sounding "dead" or muted on headphones.

Swell/Movement Layer: None (absence of movement defines the biome; stillness creates contrast with every other sector).

Sparse Character Sounds: Every 45-75 seconds, a single dry, intimate micro-stress groan from the player's own flagship hull (150 Hz-260 Hz, dry mono-to-narrow-stereo image), emphasizing isolation.

Combat Ducking & Mix Behavior:

Bus: Environment / Ambience_Bed.

Loud Combat Duck: Drops -4 dB (already ultra-quiet; serves to make weapon fire and tactical cues sound starkly loud and exposed).

Tense Moments: No tonal change, Deep Space stays indifferent, allowing the dynamic battle music alone to carry the urgency. Capital ship death ducks -8 dB for 3 seconds to accentuate the sudden silence after the explosion.

Reference Bed to Build First: Nebula

Build Nebula first as the tuning benchmark. It sits right in the middle of the spectral and dynamic range: it requires both a continuous sub-bass bed and slow mid-low swells (220-520 Hz), plus sparse character events. Because the owner has already rejected a nebula bed for sounding like rain, getting the low-pass ceiling (3.5 kHz hard roll-off, primary energy below 500 Hz) and swell curves approved on Nebula establishes the exact "approved spectral ceiling" and "approved loudness floor" (-32 LUFS idle, -38 LUFS ducked) that every other biome can then be calibrated against.

Least-Sure Decision & Biggest Risk (Ambience Plan)

Least-Sure Decision: Using musical pitch shifts (+1.5 semitones on Station, harmonic shifts on Planet Orbit) driven by objective urgency. If the battle music in Issue 2034 is already modulating keys or building harmonic tension, a pitched ambience bed risks clashing dissonantly (minor second rub) against the score unless the music and ambience share a strict tonal root (e.g., D or C).

Biggest Risk: Low-end mud accumulation (50 Hz-200 Hz) across simultaneous systems. Every single biome relies on warm sub-bass and low-mid hums because high frequencies are banned to avoid hiss/rain. When battle music basslines, capital weapon impacts, and a 120 Hz ambient drone play simultaneously on consumer speakers or headphones, headroom will evaporate fast, requiring strict sidechain multiband ducking (80-250 Hz notch) on the Environment bus whenever Effects or Music hit peak transients.

Closing Objection

The brief demands rich visual volume and rich sonic atmosphere while simultaneously stripping away the primary perceptual cues humans use to read both, forcing everything into the exact same narrow mid-low band. Visually, banning purple and yellow/mustard, reducing star density behind the cloud (which normally provides high-contrast occlusion cues), removing the dark board scrim, and forbidding high-frequency texture contrast leaves only muted teal, grey, and dim orange to separate background, nebula, grid, and ships. Sonically, banning all high-frequency air/hiss, all weather-like textures, and all electronic cues forces all six biomes into the 40 Hz-500 Hz sub/low-mid band, the exact frequency range already occupied by capital ship engines, explosions, and battle music percussion. Without widening either the tonal contrast window or allowing subtle high-frequency air/specular shimmer in both art and audio, the game risks feeling visually flat and sonically congested during peak 15-round engagements.
