# Effects focused pass: visual effects for space fleet combat (Oct 24, 2026)

Filing note: this is the first leg of batch 7 (focused effects pass), done blind with web search plus two full page reads. No live browser use, no sign-in, no posting, voting, or commenting. No Reddit thread was used as a source in this pass. Each finding separates what the source says from the leg's inference, and ends with an ADOPT / ADAPT / SKIP decision. Weak sources are flagged inline. Several findings note that a full URL was not returned by search; those claims are re-verification-limited, and the screening note records that. Em dashes in the returned text have been normalized to hyphens; wording is otherwise unchanged. Chair screening is separate; reconciliation with the DeepSeek second leg comes when that leg lands.

Scope: a 3D turn-based fleet-tactics roguelite on PC, ~20-ship fleets, turn-based (not real-time). Effects only.

## (a) Shield effects

A1. Fresnel glow plus impact ripple, single impact point (read in full).
Source: "Energy shield with impact effect" - https://godotshaders.com/shader/energy-shield-with-impact-effect/
What it says: a spatial shader combining a Fresnel edge glow (alpha driven by the dot of normal and view direction, raised to an intensity power) with a ripple distortion. The ripple is computed from distance to a single _impact_origin uniform, with frequency, density, amplitude, blend, and radius parameters, and animated over time. The shield color is one uniform with a brightness multiplier (default 10.0). It is a hobbyist's first shader, MIT code on the page, and the author says it is rough and improvable.
Inference: this is the right skeleton for a behavior spec but not the finished spec, because it takes exactly one impact point and has no health states.
Decision: ADOPT as the starting shield shader shape (Fresnel shell plus ripple from the hit point).

A2. Force-field sets with hex pattern, contact glow, and low-health gaps (search snippet, store page).
Source: Reebo Labs Godot 4 Character Shaders, Force Field set - https://www.reebo.com/ (store listing surfaced via search; exact product page URL not returned, so no link is given)
What it says: a hex shield bubble with impact ripples, contact glow, and low-health gap states, in presets including Shield Hex Blue, Shield Energy Green, and Shield Broken Red.
Inference: the preset names map cleanly onto a health-state ladder (full, degraded, broken), which is the part worth copying, not the specific hex look.
Decision: ADAPT the state ladder (intact, damaged with gaps, broken) as the shield behavior spec.

A3. Hit-ripple behavior spec plus a material-sharing gotcha (search snippet, devlog).
Source: Sci-Fi Combat FX devlog (search snippet; project page surfaced via search, full URL not returned)
What it says: the shield ripple starts at the hit position, flickers as health drops, and is paired with a hit flash and an EMP shockwave. Gotcha: two enemies sharing one material flash together, so materials must be scene-local or duplicated per ship.
Inference: the gotcha generalizes to every per-ship effect parameter (damage amount, impact origin, flash state). Shared materials are the bug class, not just a shield bug.
Decision: ADOPT both the behavior spec (ripple at hit point, flicker at low health, flash on hit) and the per-ship material rule.

A4. Multi-impact buffers: NOT verified this round.
What was found: no primary source in this pass documents a multi-impact buffer (e.g. an array of impact origins with ages). The shield shader read in full takes a single impact origin only. The buffer idea (store N recent hits, decay each, sum the ripples) is standard shader practice, but no shipped implementation, slot count, or decay curve was verified this round.
Inference: a capped ring buffer of recent impacts with per-impact age decay is the obvious design, and the cap should be small (a handful, not dozens) because each slot costs a uniform and a ripple evaluation.
Decision: ADAPT as a spike item, not an adopted spec. Flag: unverified, needs a hands-on test before anyone relies on it.

A5. Shield color discipline.
What sources say: shield shaders take a single color uniform, and the hex-bubble presets are sold per color. No source in this pass states a color-discipline rule for a tactics game.
Inference: the discipline rule has to be invented here: shields get exactly one hue family, and that hue must not also mean damage, fire, selection, or danger. If shields are cyan, nothing else on the board is cyan.
Decision: ADOPT the one-hue rule as a project rule. Flag: inference, not a sourced claim.

A6. Shield break behavior.
What sources say: one store listing mentions "raise/collapse" for a force-field bubble. No source in this pass describes a full break sequence.
Inference: a break should read as collapse (shell shrinks or shatters inward over ~0.3-0.5s) plus a brief debris burst, then the hull underneath is fully exposed. A break with no collapse animation reads as a bug, not a state change.
Decision: ADAPT the collapse-plus-debris shape. Flag: inference, thin sourcing.

## (b) Progressive damage on hulls

B1. Noise-mask blend shader, damage amount 0-100 (read in full).
Source: "Blend damage revealed with noise texture mask" - https://godotshaders.com/shader/blend-damage-revealed-with-noise-texture-mask/
What it says: three textures (base, damage, noise mask). Damage Amount runs 0 to 100, where 100 shows the damage texture fully. A Threshold parameter (default 25%) sets the percentage below which no damage is yet visible, so damage appears first as blotches that grow and merge. Damage Amount is an instance uniform, so each ship can carry its own value without a unique material.
Inference: this is the cheapest shippable damage dial in the whole pass. One uniform per ship, no geometry work, no extra meshes.
Decision: ADOPT as the primary hull-damage mechanism.

B2. Pooled decals for scorch and impact marks (search snippets, official docs).
Source: "Using decals - Godot Engine (4.2) documentation" - https://docs.godotengine.org/en/4.2/tutorials/3d/using_decals.html
What it says: decals can inject their own PBR properties onto projected surfaces and can represent bullet impacts and explosion scorches. They can be faded over time with a script and then removed to improve performance.
Supporting source: "Visual Effects and Marks" (DeepWiki summary of an open-source shooter codebase) - https://deepwiki.com/noire-dev/opensandbox-SDK/6.4-visual-effects-and-marks
What it says: impact marks live in a fixed-size pool; when the pool is exhausted the oldest marks are cleaned up automatically; alpha and color fade over configurable periods.
Inference: the pool-plus-oldest-recycled design is the right shape, but fading marks away mid-battle is wrong for a tactics game (see B3).
Decision: ADOPT pooled decals for scorch and impact marks, with a per-ship and per-battle cap.

B3. Scorches should persist within a battle (search snippet, forum post; flag: forum).
Source: FreeSpace mod decal discussion - https://www.hard-light.net/forums/index.php?PHPSESSID=iqitstbqbpjbbunrvakpajhp9v&topic=23754.0
What it says: a player complained that strafing a ship and watching their own hits fade away to leave unblemished hull looks strange. The reply notes there is a per-ship decal limit and a mission-wide limit, imposed for performance.
Inference: in a turn-based game where damage state is information, a mark that fades is a lie about the board. Marks should persist for the battle and only recycle when the cap forces it, oldest first.
Decision: ADAPT the pool design from B2 with battle-persistent marks and oldest-first recycling at the cap.

B4. Staged damage ladder (scorch, dent, exposed structure, hole, fire): inference, not a sourced system.
What sources say: no source in this pass documents a single shipped ladder with those five stages tied to hit location. The noise-mask shader gives two states (base vs damage) with a threshold, and decals give localized marks. The ladder itself is not found as one system.
Inference: the shippable construction is a ladder built from the pieces above: threshold bands on the noise mask for scorch then structure, decals for localized impact marks at the hit point, and a looping fire/smoke emitter switched on only at the top band. Location tying comes from placing the decal and the emitter at the hit location, not from a separate mesh per location.
Decision: ADAPT the banded-mask plus decal plus emitter construction. Flag: the ladder as a whole is inference; only its parts are sourced.

B5. Mesh deformation: tech-demo risk.
What sources say: nothing in this pass documents a shipped turn-based game deforming hull meshes per hit. Deformation appears in tech demos and film tools, not in the tactics sources found.
Inference: deformation fights the kit (it breaks silhouette rules, needs topology that survives dents, and is invisible at battle zoom). The noise mask plus decals already sell damage at a fraction of the cost.
Decision: SKIP mesh deformation as a damage language. ADAPT sparingly at most (a brief scale wobble on a heavy hit, never a permanent dent).

## (c) Weapon effects

C1. Beams are instant; the line is confirmation, not the projectile (search snippet, wiki-style combat page; flag: secondary summary).
Source: DeepWiki combat systems page (search snippet; full URL not returned)
What it says: beams are visual-only lines with damage applied at the firing moment, before the line is created. Projectiles, by contrast, have time-of-flight (distance divided by speed), arc control points, and a miss check (target moved more than a threshold from the aimed position means a miss).
Inference: this split is exactly right for a turn-based game. A beam should never fly slowly across the board like a projectile, because the decision is already made. Its job is to confirm the hit instantly and readably.
Decision: ADOPT the split: beams instant with a brief visible line, projectiles with real flight time.

C2. Beam warmup telegraphs the big shot (search snippet, fan wiki; flag: fan wiki).
Source: "Energy projector" - https://www.halopedia.org/index.php?title=Energy_projector&diff=cur&oldid=904529
What it says: before firing, targeting vanes iris into position and a buildup of plasma glows around the muzzle, then the firing sequence starts. Supporting pattern: Warframe continuous weapons have a short warmup to full damage (search snippet, fan wiki; flag: fan wiki).
Inference: a 0.3-0.6s charge glow at the muzzle (matching the anticipation window in section (d)) makes a heavy beam feel earned and gives the defending player a readable beat before impact, without changing the instant-hit rule.
Decision: ADAPT warmup glow for heavy beams only, not for every gun.

C3. Torpedo feel versus missile feel (search snippet, forum post; flag: forum).
Source: forum thread distinguishing torpedo and missile feel (search snippet; full URL not returned)
What it says: torpedoes are slow, devastating, and carry a hold-your-breath pause while you wait to see if they hit; missiles are heat-seeking and near-impossible to escape. Torpedoes are more inclined to miss an evading target.
Inference: the torpedo's slowness is its identity, not a flaw to fix. Speeding torpedoes up to feel better would delete the dodge window that makes them fair.
Decision: ADOPT slow torpedoes with a real dodge window as the design identity.

C4. Torpedo telegraphing: torpedo plus path plus arrival (inference built on C3 and section (g)).
What sources say: no source in this pass documents a shipped torpedo telegraphing spec for a turn-based game. The pieces are sourced (slow flight from C3, preview-everything from G1), but the three-part spec below is my construction.
Inference: a torpedo miss feels fair only if the player could see all three things before the outcome: the torpedo itself (a visible mesh with engine glow, not a dot), its path (a faint projected line or a short trail), and its arrival (an ETA marker or arrival-zone highlight on the target). If any one is missing, the miss reads as random.
Decision: ADOPT the three-part telegraph as a spec to test. Flag: inference, not a sourced spec.

C5. Explosions are layered, one-shot, and self-cleaning (search snippets).
Source: "GPU Particle Systems" (DeepWiki summary of a Godot VFX project) - https://deepwiki.com/gtibo/VFX-sketchbook-Godot-4.x/5.1-gpu-particle-systems
What it says: one explosion pattern uses 76 primary particles plus 1024 sub-emitted smoke particles (1100 total active). One-shot particles automatically stop processing after emission completes, giving predictable memory use and automatic cleanup.
Source: "Game Particle Effects: Complete VFX Programming Guide 2025" - https://generalistprogrammer.com/tutorials/game-particle-effects-complete-vfx-programming-guide-2025
What it says: realistic fire is layered: an additive core flame with upward velocity and a yellow-to-red gradient, a slower alpha-blended smoke layer above it, and additive ember particles with gravity and flicker. Layer 3-5 systems for depth.
Inference: the layering is what makes an explosion read as big without a huge particle count, and the one-shot pattern is what keeps 20 ships' explosions from leaking emitters.
Decision: ADOPT layered one-shot explosions (core flash, fire, smoke, embers, shockwave ring).

C6. Muzzle flashes and engine glows: thin sourcing.
What sources say: muzzle flashes appear in effect-layer lists (additive foreground layer) but no source in this pass gives a muzzle-flash spec. Engine trails are covered only as generic particle trails.
Inference: a muzzle flash should be 1-3 frames plus a brief light pop, and engine glow should be a steady low-intensity trail, not a strobing effect. Both are cheap and safe, but neither is verified against a shipped spec here.
Decision: ADAPT the brief-flash shape. Flag: thin sourcing, inference-heavy.

C7. What makes a beam or explosion read as powerful without hiding the board (synthesis of C1, C5, and section (d)).
Sourced pieces: instant beam line (C1), layered explosion (C5), hitstop and flash caps (section (d)).
Inference: power reads from contrast and timing, not from size or duration: a dark frame before the flash, a white-hot core for 1-3 frames, a shockwave ring that expands past the hull, then fast decay. A big explosion that lingers as opaque smoke hides the board; a big explosion that peaks hard and clears fast reads as bigger and stays readable.
Decision: ADOPT peak-hard-decay-fast as the power rule. Flag: synthesis, not a single sourced claim.

## (d) Particles and juice

D1. Starting values, from two independent guides converging (search snippets).
Sources: game-feel guides surfaced via search (juice timing tables; full URLs not returned for the tables themselves)
What they say, converging across both: hitstop 3-6 frames (0.05-0.1s, and one guide gives 60-120ms with longer feeling laggy, not punchy); camera shake 0.2-0.5s decaying, or 6-12 frames in a frame-timeline table; screen/material flash ~0.1s; anticipation 0.3-0.6s windup before a big hit; hit flash 3-6 frames; particles 10-20 frames; knockback/stagger 8-30 frames after the freeze; damage numbers and bar drains 10-20 frames after the freeze; contact cues (hitstop, sound, flash) must land on frame 0.
Inference: these are starting values to tune from, not constants. The convergence across two guides makes them a reasonable default set, but they are not measurements on this game.
Decision: ADOPT the table above as the starting values.

D2. Trauma-squared shake scaling (search snippet, Godot example).
Source: game-feel guide with a Godot shake example (search snippet; full URL not returned)
What it says: keep a trauma value 0 to 1, decay it at 4.0 per second, square it before applying so small hits stay subtle, cap offset around 12px, and add 0.4 trauma on a hit.
Inference: squaring is the key insight. Linear shake makes every hit feel the same and makes small hits annoying. Squared trauma gives a real dynamic range between a glancing hit and a capital-ship kill.
Decision: ADOPT trauma-squared shake with decay, capped offset.

D3. Flashing hard cap from accessibility rules (search snippets, accessibility summaries of WCAG).
Source: "WCAG Three Flashes Explained" - https://www.getstark.co/wcag-explained/operable/seizures-and-physical-reactions/three-flashes/
What it says: WCAG 2.3.1/2.3.2 say content must not flash more than three times in any one-second period, where the strict threshold applies to flashes that are large and bright. Red flashing is called out as more sensitive than other colors. Tools named: PEAT and the Harding test.
Inference: the "max 3 flashes per second" number in the juice guides (D1) is not just a feel choice, it is the same number as the accessibility threshold. Treat it as a hard cap, not a target: stay under it always, and keep red flashing out of rapid effects entirely.
Decision: ADOPT as a hard rule: no effect flashes more than 3 times per second, full-screen flashes avoided, red flashing avoided.

D4. Audio carries a large share of the weight (partially sourced).
What sources say: juice guides tie sound effects to frame 0 alongside hitstop and flash, and one guide's framing treats sound as roughly half the perceived impact. The "half the weight" split itself is a rule of thumb from the task brief, not a measured figure verified in a source this round.
Inference: the actionable part is the timing rule (sound on frame 0, matched to the hit, scaled with damage), not the percentage. A big hit with a small sound feels small; a small hit with a big sound feels wrong.
Decision: ADOPT sound-on-frame-0 scaled to damage. Flag: the "half" figure is unverified as a measurement.

D5. Failure modes (synthesis of D1-D3 plus guide warnings).
Sourced: shake decay and flash caps (D1, D3); smoke overdraw cost (section (f)).
Inference, stated as failure modes to test against: too much shake hides the board and makes aiming miserable; flashing past the cap risks real harm and must be treated as a bug, not a style choice; juice that plays over information (a damage number hidden behind a flash, a shield state hidden behind smoke) breaks the tactics game even when it looks good. The test is simple: after every effect, can the player still read hull state, shield state, and turn order?
Decision: ADOPT the readability-after-every-effect test as the juice acceptance gate. Flag: synthesis, not a sourced test.

## (e) Lighting and post

E1. Three-point rig as the baseline (search snippets, lighting guides).
Sources: three-point lighting guides surfaced via search (full URLs not returned)
What they say: key light to one side and higher (about 45 degrees), fill at lower intensity from the opposite side, rim or backlight strong behind the subject, bluish-white at roughly 25-50% intensity in one guide, to keep edges from fading into blackness and define the silhouette.
Inference: in space, the "fill" is a cheat (there is no bounce light in a vacuum), but the rig still works because the goal is readability, not physical accuracy. A two-light rig (key plus rim) is the cut-down version, not the target.
Decision: ADOPT three-point as the baseline rig, two-light as the fallback.

E2. Rim light controls (search snippet, lighting guide).
Source: rim-light guide surfaced via search (full URL not returned)
What they say: rim shape is controlled by width, blur, power (0-10 range), and normal strength.
Inference: rim power is the single most valuable dial for dark-hull readability, because it separates hull from background without raising overall brightness.
Decision: ADAPT rim power as a per-faction tuning dial (pale hulls need less, dark hulls need more).

E3. Bloom threshold above 1.0, ACES tonemapping (search snippets, project profiles; flag: individual project configs, not a standard).
Sources: "Post-Processing Setup" - https://deepwiki.com/yangrc1234/AtmosphereScatter/8.1-post-processing-setup (bloom intensity 0.5, threshold 1.44, soft knee 0.485); "Post-Processing Effects" - https://deepwiki.com/calaveiraUwU/Slotmachine/4.1-post-processing-effects (bloom threshold 0.9); "Post-Processing Effects" - https://deepwiki.com/amrayach/house-of-letters/4.4-post-processing-effects (ACES Filmic, white point 4.0, middle grey 0.6).
What they say, taken together: shipped profiles put bloom thresholds anywhere from 0.9 to 1.44, with intensity around 0.5 for moderate glow, and ACES Filmic is the common filmic tonemapper with a white point well above 1.0.
Inference: the threshold matters more than the intensity. A threshold above 1.0 means only HDR brights (muzzle flashes, beam cores, explosions, engine glows) bloom, while lit hulls stay clean. A threshold below 1.0 makes everything glow and flattens the board.
Decision: ADOPT threshold above 1.0 with ACES Filmic as the starting post chain.

E4. "Hollywood darkness": feel dark, not actually dark (search snippet, lighting guide).
Source: lighting guide surfaced via search (full URL not returned)
What it says: dim the unimportant things so the important things get attention, and treat bloom, ambient occlusion, chromatic aberration, and emissive halos as separate hacks that must read as one system.
Inference: this is the grading principle for the whole game. Space should feel dark, but the board must never actually be dark. If a player cannot tell a damaged ship from an undamaged one, the grade is wrong no matter how cinematic it looks.
Decision: ADOPT as the grading principle.

E5. What carries the look most: lighting, post, or materials? (inference, no direct source).
What sources say: no source in this pass directly compares the three. The lighting guides emphasize rig and rim; the post profiles emphasize threshold and tonemap; the PBR guides emphasize correct metalness and roughness.
Judgment, flagged as inference: lighting first (a good rig with strong rim makes even simple materials read), materials second (correct PBR is what makes the rig pay off; wrong metalness everywhere flattens everything), post third (bloom and tonemap are polish that amplify a good image and cannot rescue a bad one). If only one can be perfect, it is lighting.
Decision: ADOPT the ranking lighting, materials, post as a prioritization rule. Flag: inference, not a sourced claim.

## (f) Effects performance budgets

F1. Overdraw breaks first, not particle count (search snippets, forum and guides; flag: forum for the first source).
Source: "Smoke and explosion fps spikes" - https://forums.tomshardware.com/threads/smoke-and-explosion-fps-spikes-do-they-cause-the-gpu-or-cpu.712248/
What it says: smoke and explosions drop frames, worse when looking directly at smoke, worse with more layers of smoke, and the load is on the GPU.
Source: "Game Particle Effects" guide - https://generalistprogrammer.com/tutorials/game-particle-effects-complete-vfx-programming-guide-2025
What it says: particle problems are usually overdraw from overlapping transparent particles, not raw count. Mitigations: smaller particles, shorter lifetimes, distance LOD, hard per-effect budgets, texture atlases plus material sharing to cut draw calls, additive blending faster than alpha blending for fire and sparks.
Inference: at 20 ships firing at once, the failure is a wall of overlapping transparent smoke and fire filling the screen, not the particle count number. Budget overdraw (screen coverage times layers), not just particles.
Decision: ADOPT overdraw as the primary effects budget, with additive blending for fire and sparks.

F2. Particle budget numbers as starting caps (search snippet, guide; flag: guide figures, not measurements on this game).
Source: "Game Particle Effects" guide - https://generalistprogrammer.com/tutorials/game-particle-effects-complete-vfx-programming-guide-2025
What it says: target a 1-2ms particle budget for 60fps games; particle systems often consume 15-30% of frame time in VFX-heavy games; use 20-30 particles where 100 would be overkill; limit mobile to 200-500 active particles; use LOD that reduces counts with distance and simpler shaders for distant effects; profile with Unity Profiler or Unreal Insights.
Inference: the 1-2ms budget and the 20-30 particle rule transfer to desktop as a starting cap, but the absolute numbers need measuring on this game at battle zoom with 20 ships. The explosion example in C5 (1100 active particles for one big explosion) already exceeds a naive per-effect cap, so the cap has to be global and pooled, not per effect.
Decision: ADAPT as starting caps: global particle budget, per-effect budgets, distance LOD. Flag: guide figures, not measurements.

F3. Pooling and one-shot cleanup (search snippets).
Source: "GPU Particle Systems" - https://deepwiki.com/gtibo/VFX-sketchbook-Godot-4.x/5.1-gpu-particle-systems (one-shot particles stop processing after emission, predictable memory, automatic cleanup).
Source: "Visual Effects System (Fx)" - https://deepwiki.com/deepnight/gamefeel/4.3-visual-effects-system-(fx) (a particle pool initialized with 2048 particles, four batch layers split by depth and blend mode: background additive, background normal, foreground additive, foreground normal).
Inference: the pool plus one-shot pattern is what prevents a 20-ship salvo from leaking emitters or spiking allocation. The four-layer split is also worth copying: additive glows and alpha smoke must not share a batch, or sorting and blending fight each other.
Decision: ADOPT pooled one-shot emitters with separate additive and alpha layers.

F4. What breaks first when 20 ships fire at once, and the mitigations (inference from F1-F3).
Sourced pieces: overdraw (F1), particle budgets (F2), pooling (F3).
Inference: the break order is (1) fill rate from overlapping transparent smoke and fire, (2) draw calls from per-effect materials that are not shared or atlased, (3) CPU spawn cost if emitters allocate per shot. Mitigations in priority order: cap simultaneous full-size effects (distant or minor hits get the small variant), pool decals and emitters, share materials and atlases across effects, scale particle counts and sizes with camera distance, shorten smoke lifetimes, and prefer additive blending for anything hot.
Decision: ADOPT the mitigation list in that priority order. Flag: the break order is inference, not a measured profile.

F5. Texture memory for effect maps: NOT verified this round.
What was found: no source in this pass gives a texture-memory figure for effect maps, and no compression-format claim (KTX2, Basis, BC7) was verified against a source this round. Do not reuse any compression percentage from memory or from another thread without a source.
Decision: SKIP any texture-memory claim until it is sourced and measured. Flag: unverified.

## (g) Effects readability rules

G1. Clarity beats cool ideas, every time (dev interview, strong source).
Source: "Into the Breach dev on UI design: 'Sacrifice cool ideas for the sake of clarity every time'" - https://www.gamedeveloper.com/design/-i-into-the-breach-i-dev-on-ui-design-sacrifice-cool-ideas-for-the-sake-of-clarity-every-time-
What it says: Subset Games' principle was to sacrifice cool ideas for clarity every time. They cut unique weapons and firing patterns because playtesters could not read them, even though the developers themselves understood them. The features that survived include animated tooltips that dynamically show how a weapon works.
Inference: this is the governing rule for the whole effects pass. Any effect that a new player cannot read (what hit, how hard, what state changed) gets cut or simplified, no matter how good it looks in isolation.
Decision: ADOPT as the governing rule for all effects work.

G2. Simultaneous playback with pause and replay (reviews and encyclopedia summary).
Source: "Battlestar Galactica: Deadlock" - https://en.wikipedia.org/wiki/Battlestar_Galactica_Deadlock
What it says: Deadlock uses a simultaneous turn structure (WEGO) where both sides' commands execute at the same time. Supporting coverage: Polygon - https://www.polygon.com/2017/6/28/15887180/battlestar-galactica-deadlock-ps4-pc-xbox-one-price-release-date (orders play out in scalable, pausable real-time, with full replays after each battle from any angle).
Supporting detail, flagged as forum: a Steam forum post gives each Deadlock turn as 12 seconds of simulated time - https://steamcommunity.com/app/544610/discussions/0/4700161192395595557/?l=italian (flag: forum post, not a developer source).
Inference: simultaneous playback is what makes a 20-ship turn watchable at all. Sequential playback of 20 ships' actions is what creates the 95-120 second waits. The pause and replay are what make simultaneous playback fair: the player can stop and inspect any moment.
Decision: ADAPT the WEGO shape: simultaneous playback of independent actions, pausable, with replay.

G3. Watch settings and accelerate options: inference, not a sourced feature.
What sources say: no source in this pass documents watch settings (never / always / commanders only) or a global accelerate toggle in a shipped tactics game. Deadlock's scalable playback speed (G2) is the closest sourced feature.
Inference: the settings shape that follows from G1 and G2 is: a watch setting (watch everything, watch only big events, watch nothing), a global accelerate toggle (1x / 2x / skip-to-results), and a rule that acceleration never skips the damage-state update (the board state after the turn must always be readable, even if the animation was skipped).
Decision: ADOPT the settings shape as a spec to build. Flag: inference, not a sourced feature.

G4. Contrast and preview rules from tactics guidance (search snippets, guides).
Sources: tactics readability guidance surfaced via search (full URLs not returned)
What they say: ranges, area-of-effect zones, and enemy intents should be visible; use tooltips, overlays, and subtle animations; show turn order clearly; the player should never be confused about what is happening or why; preview moves and offer undo where possible; keep animations short but strong; spectacle must not become repetitive; hit effects at 50-100ms per frame register without hiding the action; draw effects along the line of fire itself so no effect depends on the edge of a clip.
Inference: the "along the line of fire" point is the most actionable: a beam, projectile trail, or torpedo path that sits exactly on the attack line is readable at any zoom, while an effect offset from the line is ambiguous about what it hit.
Decision: ADOPT the preview-plus-contrast rules, including effects drawn on the line of fire.

G5. Effects scale with camera distance (inference from LOD guidance).
Sourced pieces: distance LOD for particles (F2), simpler shaders for distant effects (F2).
Inference: at battle zoom, full-size explosions on every ship are noise; at close zoom, tiny effects feel dead. The rule is: particle counts, sizes, and glow intensity scale down with distance, while the information (hit marker, damage number, state change) stays at full readability at every distance. Information never scales down; only spectacle does.
Decision: ADOPT distance scaling for spectacle with information held constant. Flag: the information-constant clause is inference.

G6. Simultaneous versus sequential animation (synthesis of G2 and the tactics sources).
Sourced: simultaneous WEGO playback (G2), short strong animations (G4).
Inference: the rule that reconciles them is causal, not temporal. Independent actions (two ships shooting two different targets) play simultaneously. Dependent actions (a kill that triggers an explosion that triggers a chain reaction) play sequentially, because the second cannot be understood without the first. Big kills get a beat (a brief pause on the kill) even inside simultaneous playback, because the kill is the information.
Decision: ADOPT the causal rule: simultaneous for independent actions, sequential for dependent chains, a beat for kills. Flag: synthesis, not a single sourced rule.

## Cross-cutting summary: what to build first

1. Shield: Fresnel shell plus ripple from the hit point, per-ship materials, low-health flicker and gaps, collapse on break (A1, A2, A3, A6).
2. Damage: noise-mask blend dial 0-100 with a 25% visibility threshold, plus pooled battle-persistent decals at hit points (B1, B2, B3).
3. Weapons: instant beams with warmup glow on heavy guns, slow torpedoes with torpedo-plus-path-plus-arrival telegraphing, layered one-shot explosions that peak hard and decay fast (C1, C2, C4, C5, C7).
4. Juice starting values: hitstop 3-6 frames, shake 0.2-0.5s trauma-squared decaying, flash ~0.1s, anticipation 0.3-0.6s, sound on frame 0, hard cap of 3 flashes per second (D1, D2, D3, D4).
5. Look: three-point rig with strong rim, bloom threshold above 1.0 with ACES Filmic, "feel dark, not actually dark" grading (E1, E3, E4).
6. Performance: budget overdraw first, pool everything one-shot, cap simultaneous full-size effects, scale spectacle with distance (F1, F3, F4).
7. Readability governing rule: clarity beats cool ideas; simultaneous playback for independent actions, sequential for dependent chains, watch and accelerate settings that never hide the resulting board state (G1, G2, G3, G6).

## Unverified or weak items carried forward

- Multi-impact shield buffers: no shipped implementation verified this round (A4). Needs a spike.
- Staged damage ladder as one system: only its parts are sourced (B4).
- Mesh deformation: no shipped turn-based source found; skipped (B5).
- Torpedo telegraphing three-part spec: inference (C4).
- Watch settings and accelerate options: inference, closest sourced feature is Deadlock's scalable playback (G3).
- Texture-memory and compression figures: not verified this round, no claim made (F5).
- "Lighting first, materials second, post third": prioritization judgment, not a sourced comparison (E5).
- "Audio is half the weight": rule of thumb, not a measured figure (D4).
- Fan-wiki and forum sources used and flagged: Halopedia energy projector (C2), Warframe continuous weapons (C2), Hard Light decal discussion (B3), Tom's Hardware smoke thread (F1), Steam forum Deadlock turn length (G2).
- Secondary summaries used and flagged: DeepWiki auto-generated code summaries (C1, C5, F3, E3), guide blogs with figures that are claims, not measurements on this game (D1, D2, F2).
