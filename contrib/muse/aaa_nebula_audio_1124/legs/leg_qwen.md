# Leg: Qwen (Qwen4-Max TRIAL leg), issue 2061

Gate record (trial protocol, Ryan ruled Nov 24, 2026): New Chat on chat.qwen.ai, already signed in on the Free account. The model selector listed Qwen4-Max; selecting it required no paid plan or upgrade. The selector showed Qwen4-Max BEFORE the brief was pasted or sent, and the chat header still showed Qwen4-Max after generation. Brief pasted as plain text, no file attached. Single response (not comparison mode). Chat: "Nebula Clouds and Biome Ambience", https://chat.qwen.ai/c/361d91b3-ad49-445a-bbbc-161d13011cfa
Chair note: em and en dashes in the model's response are normalized to commas or hyphens in this copy to meet the repo's no-dash rule. Wording is otherwise verbatim. This leg is the one-leg Qwen4-Max trial; the standing gate for other jobs remains Qwen3.8-Max unless Ryan rules otherwise.

Response verbatim (dash-normalized):

All numbers below are opening values for tuning, not specs.
QUESTION 1: LAYERED NEBULA CLOUDS
What the precedents actually do. Homeworld and Homeworld 2 get their nebula read from fog plus large soft cards at varied depths, with ships tinting into the medium. FreeSpace 2's nebula "poofs" are soft sprites scattered through a volume, almost pure motion parallax, very cheap, but it reads as fog rather than cloud. Battlefleet Gothic: Armada 2 and BSG Deadlock use cloud decks sitting below the fleet with rim light and dark absorption lanes; that is the closest match to our camera. EVE and Sins are largely painted sky plus a few drifting soft cards, the volume is painted in, not computed. Stellaris is flat animated sprites, which is exactly our current failure state. Elite Dangerous and Star Citizen raymarch real volumes and give us the look target (self-shadowing, dark cores, silver linings) but not the technique.
The pattern: the ones that read as volume from above all have baked directional shading with self-shadow, dark absorption lanes, and at least two depths that slip against each other. Shading makes the claim; motion confirms it.
Core decision: bake the volume, run the parallax. The camera never rotates, so every view-dependent term can be computed offline. That is a budget gift and we should spend it.
Recipe
Offline: author a 256-cubed density volume (fBm billow plus flow-warped anisotropic filaments). Render it straight down with a short raymarch and one directional key at a fixed azimuth (315 degrees board-space, elevation 28 degrees). Output 2048-square RG8: R = integrated extinction, G = scattered luminance including self-shadow and key-side rim. Dust lanes are authored inside the volume as density x3 / albedo x0.15 regions, so they emerge dark with a lit edge for free, no separate multiply deck, no sort hazards.
Runtime: four horizontal decks per cloud field.
D0 deep floor: y = -0.85 x camera height, footprint 1.85x board plane, 1024sq, drift 0.06 u/s, weight 0.50
D1 body far: y = -0.40 x camera height, 1.40x, 2048sq, drift 0.12 u/s, weight 0.85
D2 body near: y = -0.16 x camera height, 1.16x, 2048sq, drift 0.22 u/s, weight 1.00
D3 wisp: y = +0.5 absolute (above board, below markers), 1024sq, drift 0.40 u/s, alpha cap 0.06, Ultra only
Depths as fractions of camera height keep the parallax ratio constant across zoom instead of flattening when the player pulls out. All drift directions stay within 25 degrees of one flow axis per field, so it reads as one body, not four sliding sheets.
Blend: premultiplied-alpha over (Godot render_mode blend_premul_alpha), rgb = G x paletteLUT(R) x keyColour, a = 1 - exp(-R x 2.2). That is emission plus extinction, the correct gas composite. Additive stacking blows out to white where decks overlap and is the usual reason layered clouds look like glowing decals.
Detail: a second sample of the same texture at 0.37x UV scrolling at 0.3x speed, multiplied into R. Boil period 90-180 s. Weight the detail term up toward the falloff so the boundary shreds into wisps.
Edge: warped-ellipse falloff, exponent 2.5, last 15% of density fading over 4-8 hex widths of world space. No quad boundary and no hex-shaped stamp anywhere.
Colour: density drives a 256x1 LUT. Stops: extinct #0B1418, slate teal #2E4A50, smoke grey #6E7A7E, bone #E8DCC8; ember #C9743A appears only on the top 8% of the baked light channel, i.e. rims. Hue windows 170-200 and 15-35 plus neutrals. The ember ramp goes rust to bone and skips 40-55 entirely, that band is where mustard lives. Enforce it in the LUT tool, not by eye. One global key azimuth for all biomes; biomes vary by LUT, scale, drift rate and key colour temperature, which also lets three shared texture atlases serve all six biomes.
Ship contact shadows: one soft multiply quad per ship on D2's plane, alpha 0.20, radius 0.6 hex. Twenty ships is about 0.02 ms and it is the best depth cue per millisecond in the whole plan.
Storms reuse the identical stack with an ember-heavy LUT, drift x2.5, and k raised to 3.0.
GPU cost
The cost is blended fill, not math. Four full-screen decks is 33.2M fragments at 4K, roughly 4x screen overdraw, with no early-Z between transparent decks. Opaque ships drawn first do reject cloud pixels behind them, about a 10% saving. Per fragment: two RG8 fetches, one LUT fetch, ~25 ALU. That is ~100M fetches/frame, ~8 Gtexel/s at 80 fps, low single-digit percent of a 5080's texture rate, and bandwidth is a non-issue with 1:1 UV mapping on a quad. Textures are BC4 pairs, ~4 MB per 2048sq deck; three shared atlases with mips is ~18 MB total, not 200 MB.
Estimate: 0.5-0.9 ms at 4K Ultra. Nominal 0.6 ms, worst case 1.0 ms zoomed out with a storm overlapping a nebula (seven decks in some pixels). Four to six draw calls; CPU negligible.
Rejected alternatives, with numbers: Godot's volumetric fog is roughly 1.5-3 ms and gives less art control than a bake from a fixed camera. A 48-step raymarch with 6 shadow steps is roughly 3-8 ms, i.e. 25-65% of the entire frame budget; half-res plus temporal reprojection gets it to ~1.5 ms but ghosts on pan, which is precisely when the parallax has to be clean.
Preset ladder: Ultra 4 decks full-res two samples ~0.6 ms; High 3 decks full-res ~0.45; Medium 3 decks 1024sq one sample in a half-res SubViewport ~0.12; Low 2 decks half-res drift only ~0.06; Minimal one pre-composited RGBA beauty card with UV drift ~0.03. Half-res is safe because the cloud is low-frequency and entirely below the board, so a plain bilinear upsample suffices, no depth-aware upsample needed. D3 must never enter the half-res buffer or it bleeds over hull edges; drop it below Ultra.
Degradation principle: lose motion depth first, never lose the baked shading. The Minimal card still has self-shadow and dust lanes, so it still reads as a cloud in a still.
Readability
Draw order is the guarantee, not dimming (which is banned). Sky, D0/D1/D2, board-plane decals (grid, patch outline, contact shadows), ships, D3 wisp, then markers/selection/UI overlay.
Hex grid: board plane, above every cloud deck. Constant screen-space width 1.2 px, bone core at alpha 0.14 over a 3 px slate casing at 0.10. The casing is local, not a scrim, and it holds contrast on both ember rims and dark lanes. Alternative: sample cloud density in the grid shader and adapt alpha 0.18 to 0.06, cheaper-looking, more failure modes.
Ship models: opaque, always in front of every cloud deck. Cap peak cloud luminance at 0.55 linear while hull key highlights run to 1.0+. Target at least 3:1 silhouette-to-local-cloud luminance. Contact shadow anchors them.
Markers and selection: overlay pass, depth test off, bone fill plus 1.5 px near-black keyline. Immune to backdrop by construction, not by tuning.
Patch outline: crisp hex-edge decal on the board plane, constant 1.5 px, alpha 0.25 normal, 0.55 when a move or target preview touches the patch. Deliberately mismatched to the cloud's soft edge, crisp geometry inside a soft body is the R247 read.
Hard rule: visual drift never moves the gameplay footprint or the outline. If the cloud slides three hexes over a battle and the outline follows, players read a moving hazard.
Scale
Field extent 3-5x the board footprint; a cloud spans 25-60 hex widths against a 0.6-1.5 ship, so 20-60x ship length. Depth spread is ~0.85 x camera height, roughly 30x ship height. Rule: at default zoom the cloud silhouette must exit the viewport on at least two sides, the player never sees the whole thing. Parallax ratios relative to board-plane motion: D3 1.01, D2 0.86, D1 0.71, D0 0.55. A 10-hex pan (~600 px of board motion) slips D0 about 270 px against the board. Unaffected hexes still show cloud beneath them, which is literally "the hex samples it".
Least sure and biggest risk
Least sure: D3, the wisp above the board. It is the only thing putting gas in front of a hull, the strongest "we are inside it" cue and the only real readability threat. At alpha 0.06 I believe it is free; I would not ship it without a test where five players call out ship class through it.
Biggest risk: this is turn-based, so the camera is still most of the time. Parallax and drift are motion cues and they do not fire while the player is thinking. If the bake is weak we will have built an expensive painted floor again. Test: freeze all drift, take a 4K still, ask five people "cloud or backdrop?" Four of five say cloud, or the bake goes back, not the layer count.
QUESTION 2: BIOME AMBIENCE
Bus layout, fitting 2034: Master -> Music, Combat (-> Effects, Tactical), Ambience (-> Bed_Low, Bed_Mid, Character), UI. Split each bed at a 150 Hz crossover into Bed_Low and Bed_Mid. Bed_Mid carries a compressor keyed from a post-fader send off Combat: threshold -24 dBFS, ratio 4:1, attack 40 ms, release 900 ms. Bed_Low gets almost none. Clearing 300 Hz-4 kHz for weapons and cues while leaving the weight underneath is the whole trick, "weight without harshness" is a spectral problem, not a level problem. Character is its own sub-bus so one-shots can be suppressed outright rather than ducked.
Nominal level: bed around -30 LUFS-S against combat around -14 LUFS-S momentary; Ambience fader about -18 dB relative to Effects at 0. Voice cap 3: one bed, one swell, one character. Beds use two reserved players for crossfades, never pooled, never preempted. Character one-shots are pooled and preemptible; a capital-death event fades any playing character over 200 ms and takes its voice.
Anti-rain contract, applied to every layer of every bed: whole-bed spectral centroid at or below 400 Hz; no sustained energy above 3 kHz; no layer with grain density above 3 events/s; every character sound has attack of at least 300 ms. Those four numbers are what "sounds like rain" actually means, and they are checkable in an analyser instead of argued about.
Global floor: a shared 70 Hz "your own ship is alive" hum at about -34 dB present in all six biomes. Biome identity is what changes on top of it.
NEBULA
Line: a cathedral-sized breath of warm gas, a low pressure hum that leans in and out, with a faint bowed-metal warmth off to one side.
Base: 44 + 66 Hz, plus band-limited noise lowpassed at 220 Hz sweeping 120-300 Hz at 0.05 Hz. Loops of 89 s and 97 s so the combined pattern repeats after hours.
Swell: 60-140 Hz, LFO 0.02-0.04 Hz, +/-5 dB, side gain breathing 0.3 to 0.6. Rounded, never a peak.
Character: a gas fold every 50-100 s, 7 s long, 35-80 Hz with a 380 Hz bowed partial at -22 dB relative.
Duck: Mid -7, Low -1. Urgency: extra -3 Mid and swell LFO rate halved. Capital death: full bed -10 dB, hold 1.5 s, release 4 s, character muted 6 s.
ASTEROID FIELD
Line: enormous rocks turning slowly in the dark, deep stone groans and a hollow low knock that arrives from far away and takes its time leaving.
Base: 38 + 57 Hz, plus bandpassed noise at 90-160 Hz, Q 3, modulated at 0.03 Hz. Reads as mass and cavity, not wind.
Swell: bowed stone grind, 12-20 s, lowpassed 900 Hz, in over 6 s out over 8 s, every 40-75 s.
Character: one sub-thud every 35-70 s, 55 Hz, 300 ms onset, 1.5 s decay, faint 240 Hz partial, dark reverb 4-6 s damped above 1 kHz. Never two within 20 s, gravel is patter.
Duck: Mid -6, Low 0. Urgency: character suppressed, extra -3 Mid. Capital death: -9 dB, hold 1.2 s, release 4 s.
DEAD STAR
Line: the silence after something enormous died, one vast low tone that barely moves, with a cold metallic ring far above it that never resolves.
Base: 28-32 Hz plus a 90 Hz partial at -18 dB, LFO 0.008 Hz, +/-1.5 dB. The emptiest bed.
Swell: a collapse breath every 70-120 s, 15 s, 45 to 60 Hz gliding two semitones down and back, +/-4 dB. Slow pitch drift is the entire movement vocabulary.
Character: a bowed inharmonic metal bar (partials 1 : 2.76 : 5.4), bandpassed 500-900 Hz, attack 800 ms, decay 9 s, every 90-150 s. Bowed, not struck, a struck bell reads as a UI cue.
Duck: Mid -4, Low 0. Urgency: no extra duck; raise the 90 Hz partial +2 dB so the bed tightens spectrally instead of getting louder. Capital death: -12 dB, hold 2 s, release 5 s.
PLANET ORBIT
Line: a world turning underneath you, a broad warm low drone with the sense of a huge curved surface, and one slow harmonic shift as you cross the terminator.
Base: 50 + 75 + 100 Hz, gently chorused, lowpassed 500 Hz, about 2 dB L/R asymmetry to imply a body off to one side.
Swell: terminator crossing, a 30-45 s crossfade between root-plus-fifth and root-plus-low-minor-third, every 60-90 s. The only bed with harmonic change.
Character: a limb tone every 60-110 s, 180 Hz bowed air-column, 5 s, no transient, wide static pan. Explicitly no filtered-noise sweeps: this is the highest weather-risk bed and ionosphere wind is banned.
Duck: Mid -8 (most masking of any bed), Low -1. Urgency: freeze the crossfade, extra -3. Capital death: -10 dB, hold 1.5 s, release 4 s.
STATION
Line: being inside something built, a low structural hum from machinery you cannot see, and the occasional far-off weight of the thing settling on its frame.
Base: 45 + 90 Hz structural drone from bowed metal and vent resonance, lowpassed 400 Hz, load-cycle AM at 0.06 Hz, +/-2 dB. Avoid 50/60 Hz plus odd harmonics, transformer whine at 2-8 kHz, and relay clicks, this is the highest "sounds electronic" risk bed.
Swell: load cycle, 20-35 s, a 110 Hz resonance rising 3 dB and settling, every 45-80 s; stereo image drifting +/-10 degrees over 60 s.
Character: one structural settle every 40-80 s, metal groan lowpassed 600 Hz, 4 s, 500 ms onset, one-semitone downward bend. No clang, no servo, no beep.
Duck: Mid -8, Low -1. Urgency: character off, swell frozen, extra -3. Capital death: -10 dB, hold 1.2 s, release 3.5 s, then optionally one settle one-shot on Character 2 s after the death resolves.
DEEP SPACE
Line: almost nothing, a wide cold very low floor tone with so little movement that you notice it only when it stops.
Base: 30 + 45 Hz at -6 dB relative to the nebula base, lowpassed 200 Hz.
Swell: +/-1.5 dB at 0.01 Hz. Effectively none; the absence of movement is the identity, mirroring the fewer-stars ruling.
Character: every 120-200 s, one 10 s 120 Hz bowed partial with a 6 s decay, hard far pan. Or nothing.
Duck: Mid -3, Low 0. Urgency: no duck; highpass corner rises 25 to 45 Hz over 8 s, thinning the floor to make room for the music's low end. Capital death: -8 dB, hold 2 s, release 6 s, the floor returning is the beat.
Build nebula first. It is the bed already rejected once, so it is the approval gate for the whole plan; it is the visual flagship, so picture and sound get tuned against one reference; it is median on all four anti-rain axes, so the other five are derivable by subtraction (deep space, dead star), added character (asteroid, station) or added harmony (orbit); and building it forces the anti-rain contract to be written as numbers rather than adjectives. The alternative I considered and rejected is deep space as the "floor" reference, you cannot calibrate a ducking curve against near-silence.
Least sure: leaving Bed_Low unducked. Combat weight also lives at 40-90 Hz, and I am betting the bed's sub and a capital impact share that band without smearing. A/B a capital hit with Bed_Low at 0 versus -4 dB before committing.
Biggest risk: six beds that are all "low hum with slow swells" collapse into one indistinguishable hum at -30 LUFS under combat, and all this biome work becomes invisible. Test blind identification at final mix level, 10-second clips, ducked, not soloed, targeting 4 of 6. If it fails, add character events or movement-rate contrast, never level.
CLOSING OBJECTION
Five of these six beds have fundamentals below 70 Hz, and the rulings systematically strip out everything above 3 kHz that would survive small speakers. Most players are on laptop speakers, TV speakers or cheap headsets that roll off hard below 120 Hz. On that hardware this entire ambience plan is silence, and the owner will read the silence as "the beds are too quiet" and ask for level, which is the one thing the mix cannot give. We will have built six biomes and shipped one. This needs a ruling before production, not a tuning pass after: either every bed carries a deliberate 150-450 Hz harmonic body layer voiced for the missing fundamental (2f/3f/4f so the ear infers the sub), explicitly permitted as neither hiss nor electronic, or we accept that ambience is a headphones-and-subwoofer feature and stop spending on biome variety. Audition every bed on a mono laptop speaker at 60 dB SPL before approving it.
