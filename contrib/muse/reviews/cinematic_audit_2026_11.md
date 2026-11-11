# Cinematic audit, outside-eye leg (issue #486)

What looks and sounds staged in a battle, and where the limit that causes it lives. Chaired by Rey from five legs: a blind Rey leg written from the look bench captures alone (leg_rey.md), writer legs from DeepSeek (leg_deepseek.md) and Qwen (leg_qwen.md), and ideation legs from Grok (leg_grok.md) and Flash (leg_flash.md). Argon seat empty (blocked). The Opus code leg is issue #485 and the Codex capture leg is issue #487; the Board merges all three into the list Ryan picks from. The wreck break itself is not listed here; issue #484 owns it.

## How the legs were screened

Every decisive citation was checked against the sources in the pack before adoption. Spot checks that passed: cues.json really does carry "synth": [] (a single voice) on gun_flak, gun_tracer, gun_spine, gun_glob, hit_wet, hit_glass, patter_hull, patter_shield, engine, cough, puff, torp_rocket and torp_sac, and on all six death cues; bass_drop exists as a standalone cue and no death cue layers it (death_crack layers scrape, hullHitBig and crackSettle only); salvo_tail's salvoBoom layer sits at delay 0; gun_shell is max 6, gap 0.045, pitch jitter 0.03, salvo "gun". The movement function names the writer legs use (_best_facing, _path_dots, _move_segments, _play_move, _move_frames, _glide_steps, _maneuver_score, fx_ship.gd) come from issue #489's own text; two more names in Qwen's leg (_moveRules_raw, pathField) were not verified and nothing below rests on them.

Two chair rulings on the legs:

1. Flash proposed relaxing the 0.70 s flame cap itself. That cap is an owner ruling (fire is wrong for space; flash and snuff out), so the relaxation is NOT adopted. The adopted form, from DeepSeek, Qwen and Grok independently, keeps the cap for flame and separates it from matter: sparks, debris, gas, dust and cooling embers get their own longer lives. The cap question itself is put to Ryan as Question 1 below.
2. Qwen proposed breaking the 1.4 step at the top of the flash ladder (cruiser death 380 px, capital death 560 px). Those sizes were ruled by Ryan in the #352 staging table (302 and 423). The chair does not override a ruling; the proposal is put to Ryan as Question 2, with the chair's recommendation against.

Convergence note: all five legs, including the blind leg written before the rule books were opened, name the same top three: the shield that never reacts, one impact stamp for every weapon, and one soft material for every act of destruction. That is the audit's centre of gravity.

## Ranked findings

### 1. The shield never answers a hit and never shows its condition

1. Now: in m2 and m3 the shield is a flawless honeycomb ellipsoid, identical in every row and faction. A hit puts the same beige puff at the bubble's edge, disconnected from the surface. A shield at one fifth strength is pixel identical to a full shield; the collapse row is a flash and a loose ring with the ellipsoid still drawn; the bubble bleaches the ship inside it white.
2. A film would: answer at the point of impact and write condition on the surface. Star Trek and Stargate shield hits flare locally; Sins of a Solar Empire 2 uses local flares and opacity that drops with strength. A failing shield fails in patches before it goes.
3. Where the limit lives: effects.md section 1 defines only "invisible at rest, a faint edge glow on zoom, hover or a recent hit, a downed side reads as a dark gap". No rule exists for a local hit response, a strength state, or a break surface. The m3 bench caption itself admits the low-shield look does not exist yet.
4. Why it is there: the shield's look is deferred to Ryan's pick from the options sheet; the states that exist are binary and easy to check.
5. Loosening: three readable states (full, weakened, failing) plus a hit response. On a hit, a local flare at the impact cell (about 1.5 to 2 times the hit flash, 0.12 s), a ripple that travels outward through neighbouring cells, and cell brightness and density that fall with strength. On break, cells fail outward from the impact in patches, keeping the dark gap where the side went down. Replace the white bleach with a faint faction tint so the ship stays readable. This strengthens whichever shield direction Ryan picks from the options sheet; it does not pre-empt the pick.
6. Size: medium, two to three agent runs. Frame cost: a per-cell brightness term in the existing shield shader, low.
7. Point at: docs/shots/look_bench/m2_weapons_on_a_shield_a.jpg, m3_shield_states.jpg.

### 2. Every weapon lands the same two-part stamp

1. Now: in m1, ten weapons land on one hull and nine produce the same small round white glow plus one soft beige puff. At camera 170 a macro cannon, las, autocannon, scatter battery and plasma hit are interchangeable; only the lance and the torpedo read differently.
2. A film would: separate weapons by what the hit does. A kinetic round sparks and skips; an energy hit splashes and runs; a torpedo bloom is dirty and directional. The Expanse separates PDC, railgun and torpedo this way; Battlestar Galactica separates flak from cannon.
3. Where the limit lives: deaths_and_hits.md "The hits, upgraded" already writes distinct rows (las a tiny hot spark with no smoke, macro a short cone of sparks, lance a contact burn that crawls, torpedo fire through gas and debris), but effects.md builds every explosion one way (route B, flash plus hot core) and section 3 has every flash reach its size inside two frames. One template, resized, is what ships.
4. Why it is there: one bake route is cheap and checkable: measure the widest lit extent and count the frames.
5. Loosening: build the hit table's rows as distinct recipes, not one template resized. Kinetic: a spark cone with a skip, no smoke. Energy: a splash that runs along the plate, a short scorch, a brief arc. Torpedo: fire seen through gas plus directional debris. Each gets its own rise (kinetic 1 frame, energy 1 to 2, torpedo 3 to 4) and its own tail. Relax the two-frame rise for every body except the smallest flash.
6. Size: medium to large, three to four runs including a rebake. Frame cost: more particles per hit, capped by camera distance and event class.
7. Point at: docs/shots/look_bench/m1_weapons_on_a_hull_a.jpg.

### 3. One soft material for all destruction; the flame cap is applied to matter as well as flame

1. Now: every explosion, hit and death is the same soft round beige-grey puff, scaled. The torpedo's puff is the las puff enlarged. Nothing is thrown: no fragments with trajectories, no sparks that arc, no venting jet, no debris that keeps moving, no scorch or residue. The world resets after every act of violence.
2. A film would: use at least two materials at different speeds and directions: a bright fast one (sparks, molten spray) and a slow dirty one (gas, dust, debris). The Expanse and Battlestar Galactica both do this; Homeworld leaves debris behind.
3. Where the limit lives: effects.md section 1 caps flame and hot core (0.70 s, 0.25 s at full heat, owner ruling) and deaths_and_hits.md rule 4 says "Nothing floats beside the hull". In practice the cap is applied to all matter. The same playbook elsewhere promises what the cap forbids: torn faces "glowing white, then orange, then dull red, then dark" over about ten seconds, torpedo wounds that "glow and cool over about four seconds", capital coals cooling for about 14 s. The cooling arc is designed and then capped out of existence.
4. Why it is there: the owner ruling against rolling fire, plus performance and readability. One puff is cheap.
5. Loosening: keep the 0.70 s cap for open flame exactly as ruled. Separate the matter budget: ballistic sparks 0.3 to 0.8 s, debris chunks 1 to 4 s drifting and fading, gas and dust 2 to 6 s, venting jets 1 to 2 s from breach anchors, and a distinct ember class (no flicker, no bright white) that cools orange to deep red over 3 to 6 s for wreck faces, wound craters and death coals, capped at about six active embers per scene. One event carries three to five materials. Spawn anchored at the hull or breach, then let matter drift after release.
6. Size: medium (materials plus a debris spawner). Frame cost: more sprites, capped by camera distance and event class.
7. Point at: docs/shots/look_bench/m1, m4_deaths.jpg, deaths/cruiser_death_beats.jpg.

### 4. Hit response does not scale with the target's mass

1. Now: in m5 the same battleship macro battery hits an Eclipse frigate, destroyer, cruiser and tomb-ark, and the puff and glow are the same size on all four, while the incoming tracer is a glowing comet larger than the frigate itself. Tracers generally do not scale with the shooter either.
2. A film would: let target mass change the behaviour of the hit, not just its size. A hit on a capital is absorbed: a smaller, longer surface event, a deep ring, a hull shudder. A hit that guts a frigate goes through and vents out the far side.
3. Where the limit lives: the staging ladder scales by weapon only ("each step up the ladder is about 1.4 times the one below"); the hits table has one row per weapon and no target term, no angle term, no glancing or absorbed variant.
4. Why it is there: the table measured one weapon on one hull; a single number per weapon is easy to check.
5. Loosening: add a target term. Suggested starting multipliers on the flash: frigate 0.8, destroyer 0.9, cruiser 1.0, capital 1.2 (the #352 ruling's own target scaling), with behaviour on top: capitals flatten the puff against the hull (about 0.6 times height), lengthen it about 1.5 times, and add shudder and absorbed glow; frigates take the full flash plus an exit wound and more debris. Scale tracer size and speed by the firing class so a frigate's guns no longer fire comets bigger than itself.
6. Size: medium, two runs. Frame cost: low.
7. Point at: docs/shots/look_bench/m5_one_weapon_every_weight.jpg.

### 5. Beams are ruler-straight bars, and the gauss draws a hairline across the whole frame

1. Now: the lance and ion beams are perfect white bars: constant width, constant brightness, hard edges, no taper, flicker, head or tail. The gauss hit draws a thin line edge to edge across the frame, like a scratch on the photograph.
2. A film would: give the beam a straining source, a hot head, a tapering tail, edge flicker, and an impact that splashes and crawls. Homeworld's ion beams and Babylon 5's beams show a source under load.
3. Where the limit lives: the design already asks for more than the render does: deaths_and_hits.md gives the lance "a contact burn that stays lit and crawls along the hull while the beam dwells" and "a third of a second of tail when it lifts". effects.md section 3's two-frame rise, written for flashes, is applied to beams by analogy. The playbook's "straight white line" sentence is about the wreck's cut face, not the live beam.
4. Why it is there: a constant-width quad is the simplest render primitive, and a wobble would strain the width check (within 15 percent).
5. Loosening: a bright core with an emitter flare (1.5 times beam width, 0.1 s), a slight width oscillation (about plus or minus 8 percent), a 0.15 s ramp in, the crawling contact burn and the 0.33 s tail the design already specifies, and a faint halo on the ion beam. The gauss becomes a travelling tracer (3 to 4 px, muzzle to target in about 0.08 s) with a muzzle flash and a target spark, never a full-path line. Keep the wreck's cut straight; let the live beam live.
6. Size: medium, two runs. Frame cost: low.
7. Point at: m1, m2, m3_shield_states.jpg (the gauss row).

### 6. Chain blasts march on a metronome, and the core flash is a centred round ball

1. Now: in the death strips the capital's blasts 4 (1.58 s) and 5 (1.93 s) are the same white sparkle band at the same density; the cruiser's blasts 1 to 3 are the same small fire at three evenly marched positions. The core flash is a perfectly round scalloped orange ball centred on the ship, owing nothing to the ship's shape or where it was hit, although the playbook places it "at the lip of the torn face".
2. A film would: stagger internal explosions: uneven gaps, different sizes, some deep and muffled, one plainly bigger than the pattern, and the core flash at the torn face with a direction.
3. Where the limit lives: deaths_and_hits.md times the cruiser's chain blasts at about 0.5, 0.8 and 1.1 s, each at least 75 px (a floor with no variation, so all three land at the floor). The faction sheets repeat the habit: Sunward magazines "an even row, a drumbeat a quarter second apart", Hegemony secondaries "evenly timed".
4. Why it is there: a schedule is easy to author and easy to check; even spacing reads clearly at camera 170.
5. Loosening: replace fixed times with a staggered list with jitter (for example cruiser 0.42, 0.74, 1.15 s; sizes varying about plus or minus 40 percent, one blast 1.3 times the others), offsets of about plus or minus 12 px off the break line, one deep blast that lights the hull from within with no external flash (free drama inside FLASH_CAP), and the core flash moved to the tear's widest point, elliptical along the tear, briefly occluded by the hull. Keep a beat, not a metronome; faction sheets keep a rhythm but break the equal interval.
6. Size: small to medium, data change plus one bake. Frame cost: none.
7. Point at: deaths/capital_death_beats.jpg, deaths/cruiser_death_beats.jpg.

### 7. Small deaths are a puff and a ring, and the Eclipse burn-out is nearly invisible

1. Now: in m4 the frigate and destroyer die as the standard puff plus a translucent lavender ring, a perfect circle expanding on cue, with three small orange ticks. The Sunward cruiser's death puff is barely larger than a frigate's. The Eclipse burn-out row is three frames of a dark hulk with almost no visible event.
2. A film would: give even a small kill a signature: a hard spark, a tumbling fragment, a brief bright core before dark. Small and large deaths should be separated by more than puff diameter.
3. Where the limit lives: deaths_and_hits.md gives small craft "a single-frame spark and a puff, under 40 px, no wreck", and the Eclipse "one vent of gas" with "no fire at all". The ring is not in the playbook at all; it reads as a default particle. The Eclipse vent the design names is not visible at camera 170.
4. Why it is there: twenty small craft dying must never hide a cruiser (a real readability rule), and the dark death is the Eclipse's faction voice.
5. Loosening: keep the concurrency cap, raise per-event readability. Replace the ring with a directional scatter of three to five fragments plus one short gas jet. Small craft get a three-frame pop (spark, fragment, gone) inside the 40 px cap; one frame reads as a glitch. For the Eclipse, keep no fire, but make the vent visible (a narrow 30 px jet for 0.8 s) and let the running lights die bow to stern over 0.5 s, the tell the cruiser already has.
6. Size: small to medium. Frame cost: low.
7. Point at: docs/shots/look_bench/m4_deaths.jpg.

### 8. Nothing lights its neighbours, and space resets clean after every event

1. Now: no explosion throws light on a nearby hull, no scorch or residue persists, no debris field hangs where a ship died. Each event happens in its own clean bubble.
2. A film would: let violence write on the world for seconds: reflected light on neighbours, then a scarred, littered field.
3. Where the limit lives: the rule already exists and is unproven: deaths_and_hits.md says torpedo hits and every death light the hulls around them (about two hexes, three for a capital death), and the hits table specifies wounds that cool and then stay as dark craters. effects.md's bench checks measure the effect itself at its table size, never whether it lights anything else, so the written rule has no check to satisfy. Flash's ideation leg adds the field-scale version: low-density drift clouds and tumbling shards persisting on the hex for several turns.
4. Why it is there: dynamic light on neighbours costs more than a self-contained effect, and the bench isolates one ship.
5. Loosening: implement the written rule and give it a bench: a point light at the flash position following the flash curve, radius two hexes (three for a capital death). Enforce the "stays" half of the wound rows (cap about eight scorch decals per ship). Frigate and small-craft deaths leave a 2 to 3 px debris speck drifting 6 to 8 s; capital kills leave a sparse persistent particulate field for several turns.
6. Size: medium, two to three runs. Frame cost: one point light per active flash, two to three at most under FLASH_CAP; decals negligible.
7. Point at: m4, docs/shots/look_bench/f1_fleet_darkest_sky_world.jpg.

### 9. Sound: many cues have one voice, tiny pitch jitter, and shared layers blur the weapons together

1. Now: verified in cues.json: thirteen weapon, hit and misc cues carry "synth": [] and all six death cues do too, one sound played identically every time. Pitch jitter is 0.03 on most weapons. Layers are shared across weapons: boomLow sits in gun_shell, gun_rail, salvo_tail, hit_heavy and arrive_jump; laserLarge in gun_las, gun_plasma, lance and lance_dark; the vent layer in torp, phase, death_vent, hulk_vent, arrive_jump and board_grapple.
2. A film would: give each weapon a recognisable mid layer and enough takes that repetition is inaudible.
3. Where the limit lives: sound.md section 1 sets the rule the data breaks: "At least four takes of anything heard often, never the same one twice in a row."
4. Why it is there: asset budget; shared layers save files; a small jitter is safe.
5. Loosening: bake at least three variants for every single-voice cue (four for the frequent ones), raise weapon pitch jitter to about 0.07, add a no-repeat picker, and give every weapon one unique short mid layer so the shared bed cannot blur it. Note a housekeeping item for the Board: the sound playbook bans rising whooshes while cues.json names a whoosh layer in six cues; rename the layer to what it is (a vent or charge) or remove it, so the data stops contradicting the book.
6. Size: small to medium. Frame cost: audio only. Memory about 1.2 MB.
7. Point at: godot/audio/cues.json (gun_flak, lance, torp_heavy, engine, death cues).

### 10. Sound: no build-up, no tails, and death sounds are far shorter than the death pictures

1. Now: every weapon fires at full volume on frame one; the "defer" field is salvo sequencing, not a charge. The duck field is 0 on every weapon, impact and death; only the boom family ducks the mix. The death cues run 0.35 to 1.5 s against a cruiser picture of about ten seconds and capital coals of about 14 s.
2. A film would: let big events breathe: a charge before the shot, a long low tail after it, and a bed under a capital death for the length of the visual, with the mix ducking under it and a beat of near-silence as the wreck settles.
3. Where the limit lives: sound.md section 1, "Short and dry. Short tails, little echo", has been read as "no tails"; cues.json has no ramp or charge field on weapon cues and no death bed.
4. Why it is there: Ryan's "clean and tactical" target; dry is easy to mix and avoids mud.
5. Loosening: keep weapons dry. Put a reverb send (about 1.8 s decay) on the death bus only; give deaths, capital hits and shield breaks 1.5 to 6 s tails with sub-bass and a hull-groan layer; add a 0.15 to 0.25 s charge ramp to lance and torpedo; set duck about 0.4 on death_crack, death_powerdown and shield_break; run a death bed per size class for the visual length with the existing one-shots on top, ducking under the core flash, then swelling; end a capital death with about 1.5 s of near-silence.
6. Size: medium. Frame cost: audio only.
7. Point at: cues.json death cue durations against deaths/capital_death_beats.jpg.

### 11. Sound: the biggest event is not the heaviest sound; the sub-bass clip is never wired into a death

1. Now: verified in cues.json: bass_drop is a standalone cue (max 1, gap 0.5) and no death cue layers bassDrop. death_crack layers scrape, hullHitBig and crackSettle, all mid-frequency. A capital's 423 px core flash is paired with sounds that could be a cruiser's.
2. A film would: scale frequency with size. A frigate pops in the mids; a capital pressures at 30 to 50 Hz, felt before it is heard.
3. Where the limit lives: sound.md states the target ("Big events are deep, not loud"); the death chain was built to the beat structure before the palette landed, and the clip was never wired in.
4. Why it is there: sequencing, not a decision.
5. Loosening: layer bassDrop into death_crack (gain about 0.6, rate 0.9, delay 0.05 s); for capital deaths add a second bassDrop at rate 0.6, delay 0.3 s; boom_l gets a bassDrop layer at gain about 0.35. Frigate deaths stay mid-frequency; the contrast is the ladder.
6. Size: small, one run, no new files. Frame cost: audio only.
7. Point at: cues.json bass_drop, death_crack, boom_l.

### 12. Sound: no distance, no size, no faction in the mix

1. Now: cues.json gains are fixed; there is no distance parameter, no target-class term on impacts, and faction variants exist only for death_crack (ithar) and board_grapple (chorus). One gun_shell serves every faction.
2. A film would: muffle far guns, deepen capital guns, pitch a hit by the target's mass, strain a shield's ring as it weakens, and give each faction's weapons a shared family with a mechanical signature (a breech clunk, a capacitor whine, a rattle) before the shot.
3. Where the limit lives: sound.md section 1 promises faction voices (iron and fire, clean electrical hum, rattling junk, glass and tone, a low held note, wet and breathing) that the cue structure does not yet carry. The bank already holds a Glasswright bell-tone clip family (the file name is cited in leg_deepseek.md as evidence only).
4. Why it is there: faction audio is deferred; one cue per weapon is simple.
5. Loosening: add a distance term (level plus low-pass, about 6 dB per doubling from the focus ship); a class pitch term on firing and impact (frigate about +10 percent rate, capital about minus 8, tomb-ark about minus 15); shield hit pitch that rises as shield strength falls; hits on a wreck fall back to the quiet patter cue; and a short faction pre-sound on the three most-heard weapons.
6. Size: medium to large. Frame cost: audio only.
7. Point at: cues.json gun_shell, hit, shield; sound.md faction voices.

### 13. Salvos fire on one tick and get one shared tail

1. Now: nine gun cues carry salvo "gun"; salvo_tail's boom layer sits at delay 0, arriving with the first gun rather than after the last. In m1 every shot lands on the same hull at the same instant. (The picture side of this is a prediction from the stills; the capture leg's timings will confirm or clear it.)
2. A film would: ripple a broadside down the hull over half a second, each battery a beat apart, one gun a straggler, and the tail boom as the sum of the reports.
3. Where the limit lives: cues.json salvo grouping and gap fields; effects.md has no salvo rule at all.
4. Why it is there: one trigger per weapon group is tidy and cheap.
5. Loosening: stagger per mount by about 0.03 plus 0.05 per index (a four-gun battery fires over about 0.18 s), one gun in six 0.15 to 0.25 s late, salvo_tail's boom delayed to about 0.12 s, and matching stagger in the muzzle flashes and hit effects.
6. Size: small. Frame cost: low.
7. Point at: cues.json gun_shell, salvo_tail; m5.

### 14. The mix caps keep a fleet battle thin, and the engine is one loop with no thrust or class

1. Now: verified maxima: gun_shell 6, boom_l 2, boom_m 3, bass_drop 1, wreck 1. Twenty ships firing produce a polite queue, not a wall of sound. The engine cue is a single engineLoop layer, max 2, with no thrust parameter, and in f1 every hull carries one identical white engine smudge.
2. A film would: run a continuous low bed under a big fight that individual events punch through, and let the engine note rise with thrust and fall to a breath at coast, deeper for capitals.
3. Where the limit lives: cues.json max and gap fields; sound.md's "nothing competes with a torpedo" read together with conservative caps; effects.md has no engine-plume rule.
4. Why it is there: voice limits and clipping are real; the numbers are conservative first passes.
5. Loosening: raise boom_s to 5, boom_m to 4, boom_l to 3; add a battle bed (a 30 to 80 Hz rumble loop whose gain scales with active ships and recent explosions, about minus 12 dB at twenty ships, minus 24 dB at five); make the engine a parameterised loop (thrust drives pitch, filter and sub) with class presets, a start whoomp and a shutdown sigh, matched on the picture side by the movement plume work (Movement M2).
6. Size: medium. Frame cost: audio only, plus low picture cost.
7. Point at: cues.json boom family, engine; f1_fleet_darkest_sky_world.jpg.

### 15. FLASH_CAP flattens the biggest moments; the drama has to be found inside it

1. Now: FLASH_CAP is 3 large flashes per second (godot/fx/fx.gd), WCAG 2.3.1, applying to everyone. A capital death's core flash, five chain blasts and secondaries exceed it, so later flashes queue or soften and the loudest event in the game is metered into a metronome.
2. A film would: not strobe more, but sustain: bigger, slower, more colourful light that lingers.
3. Where the limit lives: FINDINGS R187 records the cap and its safety basis; effects.md section 4 covers the reduce-flashing variant.
4. Why it is there: photosensitivity safety. A real reason, not a habit. No leg proposes removing it, and this report does not either.
5. Loosening, inside the cap: schedule the three permitted flashes for the moments that matter (core flash, first chain blast, the break) and turn the rest into glows; make a suppressed flash linger as light and colour fading over 0.3 to 0.5 s instead of vanishing; use smaller bright areas inside a big soft bloom; ramp slower; let sound (Findings 10 and 11) and a small camera shake (Finding 17) carry the hits the cap cannot show. One further idea, counting only flashes above about 120 px and 70 percent luminance against the cap, changes what the safety rule counts and is put to Ryan as Question 3, not adopted here.
6. Size: small (scheduling plus a glow path). Frame cost: none.
7. Point at: deaths/capital_death_beats.jpg; FINDINGS R187.

### 16. The scene dim does not read in its own proof

1. Now: the capital beats strip prints the death twice, scene dim OFF and ON, and the two are hard to tell apart side by side in the bench built to show the difference (blind leg B10, from the captures alone).
2. A film would: take the light visibly: an exposure drop the audience feels, so the next light reads brighter.
3. Where the limit lives: deaths_and_hits.md specifies the scene "dims a little for a fifth of a second" after the core flash.
4. Why it is there: a cautious value, chosen not to hide the board.
5. Loosening: either make it count (dim 25 to 35 percent for 0.35 to 0.5 s with an ease-out, the flash itself exempt so contrast does the work) or drop the treatment. Test on the strip at camera 170; if it cannot be seen in the proof it will not be seen in battle.
6. Size: small. Frame cost: none.
7. Point at: deaths/capital_death_beats.jpg, dim rows.

### 17. The camera never moves, and between turns the fleet is dead still

1. Now: "the camera is never taken from the player for a death" has been read as "the camera never moves": no shake, no push, no linger, in any capture. Flash's ideation leg adds the twin tell the writers missed: between turns every ship stops dead on its hex centre, drives out, lights uniform, no station-keeping, no idle behaviour at all. The board game shows through the stillness.
2. A film would: let the camera witness (a shake scaled to the hit, a slight push on a capital death) and let ships idle alive (micro-drift, small attitude corrections, radiator shimmer on cooldown).
3. Where the limit lives: deaths_and_hits.md's camera sentence is the only camera rule in either playbook; no playbook specifies idle behaviour.
4. Why it is there: player control, readability and comfort; the stillness was never specified, it is just the absence of a system.
5. Loosening: a 2 to 4 px shake on torpedo hits and death core flashes (0.12 to 0.2 s, fast decay, scaled by class), a 5 percent push-in on a capital death that returns over a second, all of it off under reduce flashing, never a rotation or a cut. Separately, subtle idle life: a 1 to 2 px drift with correction puffs, per-faction in character (Movement M7). Whether any camera motion is acceptable is Ryan's call (Question 4); the idle life needs no ruling.
6. Size: small to medium. Frame cost: negligible.
7. Point at: f1; deaths/capital_death_beats.jpg.

### 18. The reduce-flashing variant only softens the envelope

1. Now: effects.md section 4 and deaths_and_hits.md rule 7 keep every size under reduce flashing and swap only the rise and fall. A 423 px white core flash at a softer rise is still a 423 px white event; area and luminance carry the photosensitivity load as much as rise time does.
2. What applies instead: this is an accessibility point, not a film device. WCAG 2.3.1 turns on flash rate, area and luminance together.
3. Where the limit lives: the "keeps every size" sentence in both books.
4. Why it is there: so the comfort option never changes gameplay readability. Sizes should indeed stay; that reason does not cover luminance or colour.
5. Loosening, inside the comfort option only: peak luminance capped at about 70 percent, flash colour shifted from pure white to warm amber, duration extended about 40 percent at the reduced peak. The default mode is untouched, FLASH_CAP stays, and the protected comfort option gets stronger, not weaker.
6. Size: small, one run. Frame cost: none.
7. Point at: deaths/capital_death_beats.jpg.

## Movement

Added to this leg by FINDINGS R188 (issue #489's five questions). Nobody on this leg has watched the game move; the picture-side claims are design view and predictions, and the capture leg (#487) holds the measurements.

### What the references do

The Expanse is the weight reference: ships burn along the nose, coast dark, turn by thruster puffs separate from travel, and flip and burn to stop; plumes are long, bright and class-scaled, and the audience always knows which way a ship is going and which way it is pointing. Battlestar Galactica sells mass by contrast: small craft drift and rotate, the battlestar turns slowly with visible puffs. Babylon 5's Starfury is the drift-while-turned reference: thrusters at all corners let it rotate to fire while its travel continues. Homeworld gives fleet scale: capitals slow with puffs, strikecraft drift, debris persists. Nexus: The Jupiter Incident is the closest game reference for committed, slow capital movement. Sins of a Solar Empire is the readability and mix reference, not a movement one; its capital motion leans naval.

Hex and fleet tactics games (BattleTech, Battlefleet Gothic: Armada, Stars in Shadow, Nebulous: Fleet Command) draw the same complaints when movement is done badly: a snap to final facing; a spin the long way round; a route that stair-steps or zigzags along hex centres where a straight run exists; a preview path that does not match the flown path; a ship ending facing away from every enemy; a final facing the player did not choose and could not see coming. The good handling is consistent: show the final facing before commit, animate the pivot as a manoeuvre, draw the route smooth, and fly exactly what was previewed.

### Proposals

**M1. Drift while turned: decouple the nose from the travel [LOOK].** Now: from the stills and issue #489's framing, the ship slides along its route with the nose pinned to the path and snaps to its heading at the end; a counter on rails. Change: keep translation on the hex route, drive the nose on a separate rotation curve toward the final facing from move start, finishing with a settle, so for part of the route the ship visibly travels sideways or backwards relative to its nose. Babylon 5 and The Expanse are the references. Size: medium, one to two runs. Capture: a cruiser making a two-hex lateral move ending 90 degrees off its travel.

**M2. The main engine burns only when accelerating or braking, and the plume scales with thrust and class [LOOK].** Now: f1 shows one identical white engine smudge on every hull; the engine reads as on or off, in the picture and in the sound (Finding 14). Change: three playback phases, burn-in (plume ramps up), coast (plume at about a quarter, narrower), retro and settle (a flare, then fade), with plume width by class (frigate about 6 px, cruiser 10, capital 16) and colour shifting with thrust. Size: medium. Capture: a frigate and a capital each making a one-hex and a three-hex move.

**M3. Manoeuvring thruster puffs on the hull at rotation and at start and stop [LOOK].** Now: no visible RCS; the ship rotates with no visible cause. Change: short puffs at authored hardpoints, bow-right and stern-left for a left yaw and the reverse for a right, forward puffs on braking, scaled by class. The Expanse, Babylon 5 and Nebulous are the references. Size: small to medium. Capture: a ship pivoting 180 degrees.

**M4. The end-of-move facing is a visible, weighty pivot, not a snap [LOOK].** Now: the heading arrives at the last hex as a smooth slide or a snap, with no cause and no settle. Change: animate the pivot over 0.3 to 0.8 s by class, with puffs (M3) and a slight overshoot and settle; if the rules send it the long way round, show that honestly. Size: medium. Capture: a cruiser ending 120 degrees off its travel.

**M5. Playback timing, arrival and settle scale with class [LOOK].** Now: issue #489 predicts the same playback speed for every ship and every move; the blind leg predicts no secondary motion at all. Change: per-hex duration by class (frigate about 0.7 times baseline, destroyer 0.85, cruiser 1.0, capital 1.5, tomb-ark 1.8), a deceleration over the last fifth of the move, an overshoot of 3 to 5 px past the hex centre, and a correction settle with a damped heading wobble. The ship's logical position is the destination hex throughout; only the picture overshoots. Size: small to medium. Capture: the same move flown by a frigate and a capital side by side.

**M6. The route is drawn smooth, and the preview is exactly what flies [LOOK].** Now: routes stair-step along hex centres; whether the preview and the flown path are the same path is unverified. Change: draw the route as a spline through the hex centres with rounded corners, fly exactly that spline, and show the same spline in preview. If the pathfinding itself produces zigzags where a straight run of equal cost exists, that half is a rule change and sits in M8. Size: small to medium. Capture: a multi-hex diagonal move, preview above playback.

**M7. Each faction moves in character [LOOK].** Now: every faction uses the same glow, plume, burn-in, turn and settle; the faction voices exist for sound and for deaths but not for movement (issue #489, question 2). Change: signatures inside the same structure: Crusade warm amber plume, steadier and heavier; Hegemony cool blue-white, precise, minimal overshoot; Hullbreakers orange-red with a sputter in the burn-in and a rough settle; Glasswrights pale and fastest, minimal overshoot, a dart; Eclipse dim green-white with a slow idle drift; Chorus a plume with an organic pulse and a slight wobble in the turn. Size: medium, two to three runs. Capture: six cruisers, one per faction, flying the same two-hex move in a grid.

**M8. Three rule questions on movement, for Ryan's ruling [RULE].** (a) Final facing: _best_facing chooses it and the player neither sees it before committing nor can override it; forward weapons make a wrong facing cost shots. Proposal: show the chosen facing as an arrow or arc in the route preview, and let the player cycle the six headings to override. Touches both rule twins. (b) AI routes: shortest-path output reads as a search algorithm, not a captain. Proposal: threat weighting (hexes in known player arcs cost more), cover preference when repositioning or retreating, and intent legibility (attack runs straight, retreats gain distance every hex). (c) Pathfinding preference: prefer straight runs and single-turn routes over multi-turn routes of equal hex cost, so the route a captain would draw is the route the rules produce. Each changes play; each needs Ryan's ruling before any build.

## Questions for Ryan

1. **The flame cap.** The cap is your ruling. The council's adopted proposal keeps it for flame and frees matter instead (Finding 3). Flash dissents and would relax the cap itself for capital deaths. Chair's recommendation: keep the cap, free the matter. Your call settles it.
2. **Death flash sizes.** Qwen would break the 1.4 step at deaths (cruiser 380 px, capital 560 px) against the #352 table you ruled (302, 423). Chair's recommendation: keep the ruled sizes; take the drama from body duration, materials and light (Findings 3, 6, 8), which the table does not forbid. Your call.
3. **What counts toward FLASH_CAP.** One leg proposes counting only flashes above about 120 px and 70 percent luminance, so 75 px chain blasts stop eating the safety budget (Finding 15). It is a safety rule, so the facts are laid out there and the change is yours alone.
4. **Camera emphasis.** A 2 to 4 px shake and a 5 percent push on a capital death, inside "the camera is never taken from the player", off under reduce flashing (Finding 17). Yours to allow or refuse.
5. **Movement rules.** The three RULE items in M8 (facing preview and override, AI route heuristics, pathfinding preference). The Board will bring them with the merged list.

## What this leg could not judge

Nobody on this leg heard the game or watched it move: sound findings are structural (sound.md, cues.json, the clip list) and movement findings are reference and design, as issue #489 asks. Timing inside a turn (salvo synchrony on the picture side, actual playback speeds and paths) waits on the capture leg, #487. Where this report and the code leg (#485) disagree on a fact, the code leg's file and line evidence should win.
