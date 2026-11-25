# Leg: DeepSeek (DeepThink on, Search off), issue 2061

Gate record: New chat, account already signed in. DeepThink ON and Search OFF verified before sending and again after generation (Search had started ON and was clicked off). The first paste became a file chip; the browser used "Paste original" to restore plain text and verified no attachment before sending. Chat: "Nebula volume and ambience plan", https://chat.deepseek.com/a/chat/s/6092139c-6662-4fae-80c3-4e3e074755e6
Chair note: en dashes in the model's numeric ranges are normalized to hyphens in this copy to meet the repo's no-dash rule. Wording is otherwise verbatim.

Response verbatim (dash-normalized):

Question 1

1. Recommended recipe

Treat each nebula as a world-space "cloud volume" object, not as a hex-contained patch. One patch should visually span 10-20 hex diameters, while its gameplay mask is only the hex footprint. Use five horizontal soft cards stacked below the board, all rendered before the board and ships:

- F0 far mass, y = -30: one very large soft-smoke plane, baked 2K FBM density atlas, alpha blend, alpha 0.20-0.30, drift 0.5 world units/min.
- F1 body A, y = -18: large soft card with low-frequency density, alpha blend, alpha 0.25-0.35, drift +1.5 units/min.
- F2 body B, y = -12: second body card with different noise seed and 3:1 stretched detail, alpha blend, alpha 0.20-0.30, drift -1.0 units/min.
- F3 dust lanes, y = -8: inverted FBM/dark-smoke card, multiply blend, alpha 0.15-0.25, drift +0.8 units/min opposite F2.
- F4 near haze, y = -3: edge-heavy soft card, alpha blend, alpha 0.10-0.18, drift -0.4 units/min.

All cards sit below the board plane at y=0; ships and markers sit above it. This avoids covering the grid and ships while still giving depth through layer separation and drift.

Textures: one baked 2K RGBA atlas per cloud family. R = density, G = dust-lane mask, B = rim mask, A = edge falloff. Use at most two texture fetches per card in the shader. No per-pixel FBM.

Blending: alpha blend for F0/F1/F2/F4; multiply for F3 dust lanes. Additive only for the B-channel rim, capped at 10-15% alpha. Use depth_draw_never and explicit render order.

Motion: slow world-space UV drift, not screen-space scrolling. Opposite drift between F1/F2/F3 is the main volume cue.

Colour rules: slate teal, smoke grey, ember tones only. Starting points: slate teal #3F5F66, smoke grey #6B7074, ember #B4552D. Desaturate 10-20% per farther layer. No purple, no mustard.

Rim: fake key light in the shader from density gradient dot key-light direction projected onto the plane. Slate-teal rim on body edges; ember rim only on sparse B-channel masks.

Edge: alpha falloff extends 2-4 hexes beyond the gameplay patch union. Separately, draw a faint SDF outline at the board plane y=0.02, 1-2 px at 4K, alpha 0.15-0.20, smoke grey/teal. The outline follows the gameplay patch union, not the visual cloud spill.

Dust lanes: F3 inverted FBM stretched 3:1 along the cloud major axis; F2's G channel subtracts density along the same axis. Keep dust-lane contrast under the board moderate; they should read as occlusion inside the cloud, not as black scars.

2. GPU cost argument

The cost is overdraw and alpha blending, not texture fetch complexity. At 4K, do not render five full-res cloud layers directly. Render the cloud stack into a SubViewport at 1920x1080 on the high preset, then composite once under the board. Average overdraw about 3.5 gives roughly 7.3M fragments; with two texture fetches and a gradient rim term this should be about 0.6-1.0 ms on an RTX 5080 including composite. Worst case with two overlapping patches: 1.2-1.8 ms. Cap the nebula system at 2 ms.

Medium preset: 1280x720 SubViewport, three layers, no multiply dust lane: 0.3-0.6 ms. Low preset: bake the cloud into the backdrop or use one 960x540 layer: 0.1-0.25 ms. Full-res 4K cloud cards would be roughly 4x the fragment cost and should be rejected. Additional savings: mip bias, texture atlas, no depth writes, no per-pixel noise, disable rim on low.

3. Readability argument

Cloud never renders above the board plane. Hex grid, ship models, ship markers and selection state render after the cloud and are never depth-occluded by it. The grid uses a dual-stroke line: 1 px light core plus 1 px darker edge, so it survives both light and dark cloud areas without a dark scrim. Ship markers are unlit emissive with a screen-space minimum size and a dark outer contour. Selection rings sit above the board and above the cloud outline.

The nebula patch outline is drawn at the board plane, 1-2 px, alpha 0.15-0.20, so it stays faint but legible. Within the gameplay patch, cloud texture authoring must cap local luminance contrast and avoid high-frequency detail under hex cells. The visual cloud can spill past the patch, but the readable outline and gameplay mask remain on the board plane.

4. Scale ruling

The visual cloud is 10-20 hex diameters across and its alpha spill extends 2-4 hexes past the gameplay patch union. UVs are world-space, anchored to the cloud centre, not to hex cells. Layer heights differ by 6-12 units, so camera pan and zoom produce parallax; if the camera is orthographic, fake the same effect by offsetting each layer's UVs with camera pan/zoom. Drift is 0.4-1.5 world units/min. Hexes sample the gameplay mask; they do not contain the visual cloud. The outline marks the gameplay union while the cloud visibly continues beyond it.

5. Least-sure decision and biggest risk

Least sure: whether true parallax at a fixed overhead camera will read strongly enough without looking like sliding wallpaper; I may need the orthographic fake-parallax path even on the perspective camera.

Biggest risk: alpha sorting/banding and readability on lower presets. The no-dark-scrim ruling removes the cheapest contrast reset, so the cloud can be visually correct and still make the board tactically muddy.

Question 2

Global bus and duck policy: all beds sit on the Ambience bus. Base and swell layers go to Ambience_Bed; sparse character sounds go to Ambience_Detail. Sidechain from the Effects/combat-loudness bus: Ambience_Bed drops -6 dB, Ambience_Detail drops -12 dB or mutes, attack 150 ms, release 2 s. When objective urgency rises, bed drops an additional -3 dB over 4 s and detail -6 dB so music carries tension. On a capital-ship death, the existing big-event duck sends Ambience down -8 dB for 1.5 s hold and 6 s release. All numbers are starting points.

Nebula
Sound: Low soft gas hum with slow warm swells and rare distant displacement; no weather, no hiss.
Layers: Base 40-80 Hz tonal hum plus muted low drone on Ambience_Bed. Swell 20-40 s band-limited swell, +/-3 dB, on Ambience_Bed. Character: soft low "gas displacement" whoom every 25-45 s on Ambience_Detail. Duck: global policy; detail mutes first.

Asteroid field
Sound: Low rocky rumble with occasional distant muffled mass shifts.
Layers: Base 35-60 Hz rumble plus low resonance on Ambience_Bed. Swell 15-30 s slow shifting resonance on Ambience_Bed. Character: soft low creak/groan every 20-40 s on Ambience_Detail; no ticks, no patter. Duck: global policy.

Dead star
Sound: Near-silent gravity hum with a very slow dark swell.
Layers: Base 25-50 Hz sub hum on Ambience_Bed. Swell 30-60 s slow dark swell on Ambience_Bed. Character: rare low tonal pulse every 40-90 s on Ambience_Detail. Duck: global policy; bed may duck only -4 dB if it is already very low, but start at -6 dB.

Planet orbit
Sound: Rounded low orbital hum with slow harmonic swells, no wind.
Layers: Base warm low drone on Ambience_Bed. Swell 25-50 s harmonic shift on Ambience_Bed. Character: soft low metallic resonance every 30-60 s on Ambience_Detail. Duck: global policy.

Station
Sound: Low mechanical hum with slow pressure-like swells, no electronic cues.
Layers: Base 50-90 Hz mechanical hum plus muted harmonic on Ambience_Bed. Swell 10-20 s slow shift on Ambience_Bed. Character: soft distant hull settle every 15-30 s on Ambience_Detail; avoid sharp clanks. Duck: global policy; detail drops first.

Deep space
Sound: Almost silence with a very low sub hum and sparse distant tonal drift.
Layers: Base 20-40 Hz sub hum on Ambience_Bed. Swell 45-90 s very slow drift on Ambience_Bed. Character: rare low resonance every 60-120 s on Ambience_Detail. Duck: global policy; bed may need -4 dB rather than -6 dB because it is already low, but start at -6 dB.

Build first: Nebula. It is the visual centrepiece and the hardest constraint because "no weather, no hiss" forbids the easy texture layers. It should set the reference for sub-bass level, swell rate, sparse character density and the combat duck curve; the other beds should be tuned as variations against it.

Least-sure decision: one global duck curve may not suit the sub-bass dead star and the mechanical station equally; per-biome thresholds may be needed.

Biggest risk: all six beds collapse into indistinguishable low hums, or disappear so far under combat that biome identity is lost. The no-hiss/no-weather ruling removes many character options, so the beds need disciplined spectral separation.

Closing objection

The strongest objection is that this direction treats the 12.5 ms frame budget as the binding constraint, when the real binding constraint is readability: big clouds, no dark scrim under the board, and only a faint patch outline leave no cheap contrast reset. Unless the council defines a measurable contrast floor for the hex grid and ship markers over nebula patches, the layered-volume recipe can pass performance and still be tactically unreadable.
