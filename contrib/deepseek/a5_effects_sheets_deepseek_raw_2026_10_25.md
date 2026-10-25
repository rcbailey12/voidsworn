# Raw return: A5 effects sheets, DeepSeek, Oct 25, 2026

Source: fresh DeepSeek chat (chat.deepseek.com/a/chat/s/d3cc41b2-c605-461f-b93c-f2d137a9ed2f), DeepThink ON, Search ON, both verified active before submitting. Ran Oct 25, 2026, 2:50-2:58 PM CDT (runtime-measured). Evidence pack job_a_evidence.md uploaded as sole repo-facts source. Complete sheet returned in 4 parts, confirmed complete with no gaps. Filed verbatim below; the working copy is reviews/a5_effects_sheets_deepseek_2026_10_25.md.

# A5 effects sheets, engine-neutral, seven weapon kinds (DeepSeek leg, Oct 25, 2026)

Filed verbatim from a fresh DeepSeek chat at chat.deepseek.com (chat URL https://chat.deepseek.com/a/chat/s/d3cc41b2-c605-461f-b93c-f2d137a9ed2f). Ran Oct 25, 2026, 2:50-2:58 PM CDT (runtime-measured). DeepThink ON and Search ON both verified active before submitting (each pill toggle-tested off to gray and back on to blue). Evidence pack job_a_evidence.md (6.79 KB) was uploaded and was the sole source for repo facts. No other chats opened, referenced, or reused; session already signed in; no sign-in performed. Research only: no code written, nothing bought, nothing posted. The complete sheet was returned in 4 parts, confirmed complete with no gaps, no truncation, no dropped sections.

Chair note (not part of DeepSeek's sheet): two source URLs named in the sheet are reachable only through the chat transcript's citation links and are not printed in the sheet text (Star Citizen Comm-Link rehost, Real Time VFX flipbook thread). One BattleTech forum URL as printed contains a transient session parameter. See the screening note for the full list of flags.

## Scope and rules used throughout

Every feel value below is a range. Every range is a screen-tuned guess unless the evidence file pins a centre value, in which case the pin is named. No value is a final constant. All sheets are written to be built in either engine, because the engine call is still pending between Godot 4.7 and Babylon 9.30 (job_a_evidence.md, Engine status). The sheets describe what the player sees and hears, plus timing envelopes. They do not prescribe engine APIs. Decals, flipbooks, particle systems, shader parameters, mesh swaps and audio middleware are all acceptable implementation choices.

Batch 7 disagreement markers are used exactly where the evidence file lists disagreement (job_a_evidence.md, FINDINGS X1). The disagreement table is repeated at the top so each sheet can refer to it.

Accessibility is global: at most 3 flashes per second anywhere, plus a reduce-flashing option. A flash means a near-full-screen or large-area luminance jump above the bloom threshold. Small muzzle flashes and small impact sparks share the same scene-wide budget. If a burst would exceed the budget, the effect is rendered as a faction-coloured emissive ramp with no white frame, and the fade is lengthened. This is the safe default, not an optional extra.

The evidence file's R16 bar is the visual target: damage must read as holes with streaming parts, fire and other damage, not orange lines. Weapons and engine trails must read as more realistic and cinematic, with BattleTech, Sins of a Solar Empire II and Rogue Trader as the comparison bar (job_a_evidence.md, FINDINGS R16). The SPEC effects grammar and the 4-second effect loop are the backbone of the timing below (job_a_evidence.md, SPEC.md, Effects grammar and SPEC effect loop).

## Global reference tables

### Batch 7 feel-value disagreements (job_a_evidence.md, FINDINGS X1)

| Feel value | Leg 1 | Leg 2 | Sheet treatment |
|---|---|---|---|
| Hitstop | 3 to 6 frames | 2 to 5 frames normal, 8 to 12 frames for kills and criticals | DISAGREE. Sheets use 2 to 6 frames normal, 7 to 12 frames for kills, criticals and capital explosions. Treat the scalar as tunable, not fixed. |
| Screen shake | 0.2 to 0.5 s | at most 0.25 s, positional only, trauma model | DISAGREE. Sheets use 0.15 to 0.30 s default, positional only, trauma model. Allow 0.35 to 0.45 s only for capital-scale destruction. |
| Anticipation (wind-up) | 0.3 to 0.6 s | 6 to 12 frames on heavy weapons only | DISAGREE. Sheets use 0.15 to 0.45 s, and only on heavy weapons. Light and rapid weapons get 0.05 to 0.20 s. |
| Rim light | 25 to 50 percent of key | 50 to 80 percent of key | DISAGREE. Sheets use 30 to 60 percent as a middle testing range. Do not bake a final value. |
| Starting tonemapper | ACES | Neutral, with a three-way test (Neutral vs AgX vs ACES) | DISAGREE. Effects are authored scene-linear. Babylon tests ACES vs Khronos PBR Neutral; Godot adds AgX. No sheet assumes a tonemapper. |

### Faction colours (job_a_evidence.md, SPEC.md, from ships3d.js FAC3D)

| Faction | Weapon (bolt, beam, flash tint) | Shield | Engine |
|---|---|---|---|
| Voidsworn | (1.0, 0.45, 0.15) | (1.0, 0.46, 0.16) | (1.0, 0.50, 0.16) |
| Hegemony | (0.55, 0.82, 1.0) | (0.38, 0.68, 1.0) | (0.45, 0.72, 1.0) |
| Corsair | (0.95, 0.22, 0.10) | (0.85, 0.16, 0.10) | (1.0, 0.38, 0.16) |
| Chorus | (0.85, 0.90, 0.30) | none, hull hit | (0.80, 0.90, 0.28) |
| Ithar | (0.75, 1.0, 0.88) | (0.72, 1.0, 0.86) | (0.62, 1.0, 0.84) |
| Deathless | (0.20, 1.0, 0.38) | none, hull hit | (0.15, 1.0, 0.35) |

Shields keep their faction colours. The cyan-only shield rule is retired for 3D shields; interface shield bars stay cyan (job_a_evidence.md, FINDINGS R3). Corsair shields flicker and are patchy; Chorus and Deathless take hull hits instead of shield hits (job_a_evidence.md, SPEC effect loop, item 4).

### External source ledger

External sources are used only for comparable-game claims and for effects techniques that are not stated in the evidence file. Where a source is a community description rather than an official specification, it is marked UNSURE for exact values.

- Star Citizen official Comm-Link on the damage system (rehosted with the original link; URL in the chat transcript citations): squibs and particles cause holes and burn damage, reveal the ship's internals, and add smoke, explosions and sparks when parts detach.
- Eurogamer report on Star Citizen's damage model: temperature, burn, thickness and deformation drive hull glow, paint burn, bubbling, peeling, denting and holes that expose internals. https://www.eurogamer.net/blowing-up-star-citizens-space-ships#1
- Homeworld 3 official Steam announcement by Senior FX Artist Tim O'Connell: four damage types, unique impact decals, "Splat Damage" that alters surface geometry, and a progression from surface scars to hull breaches with secondary hot spots and burn marks. https://store.steampowered.com/news/posts/?feed=steam_community_announcements&enddate=1676473212#1
- Sins of a Solar Empire II official modder journal: traveling beams use length-based fade, front and back fade distances, and speed multipliers for readability in large fights. https://wiki.sinsofasolarempire2.com/space/SSEFW/2857598995/Pt.+1+-+A+Very+Merry+Modder+Holiday
- Rogue Trader official wiki: macro-cannons fire multiple shots, and lance weapons are long-range energy weapons. https://roguetrader.wh40k.wiki/Imperial_Navy
- BattleTech community discussion of gauss rifles: heavy white-blue muzzle flash, a bright projectile streak, and a sonic boom; this is fan discussion, not an official specification, so exact values are UNSURE. https://bg.battletech.com/forums/index.php?PHPSESSID=ccuq85iu9lb9s1qp9pos0naovm&topic=63575.90
- Real Time VFX community discussion of flipbook muzzle flashes (URL in the chat transcript citations): using random segments of a flipbook reduces visible repetition between consecutive flashes; this is a community technique, not a formal standard, so exact use is UNSURE.

## Sheet 1: Battery

Battery is the broadside macro-cannon kind, the Rogue Trader-style heavy broadside. The evidence file's SPEC effect loop already pins a four-gun port-side ripple at 80 ms intervals, a shell tracer at 160 units per second, and an impact point 70 units off the port side (job_a_evidence.md, SPEC effect loop, item 2). The ranges below are centred on those pins. Rogue Trader's macro-cannons are described as firing multiple shots per broadside, which supports the ripple treatment (see source ledger).

### 1. Fire

- Wind-up: 0.20 to 0.50 s for the full broadside. Per gun, 0.05 to 0.15 s. Anticipation is a batch 7 DISAGREE value (leg 1: 0.3 to 0.6 s; leg 2: 6 to 12 frames on heavy weapons only). Use 0.20 to 0.50 s as the testing compromise. The wind-up is mechanical: breech locks, barrel elevates a few degrees, a small hydraulic twitch. No glowing charge-up on a chemical battery.
- Muzzle flash behaviour: primary flash 1 to 3 frames (roughly 16 to 50 ms at 60 fps), white-yellow core with faction weapon tint at the edge. A flame tongue extends 3 to 8 units beyond the muzzle for 2 to 5 frames. A smoke ring leaves the muzzle and drifts 2 to 5 units over 1.5 to 2.5 s. The smoke ring lingers, it does not snap away. Each gun's flash is slightly different in size and timing so the broadside does not read as one blob.
- Projectile count and ripple timing: 3 to 5 guns per broadside, with the SPEC pin at four. Ripple interval 70 to 90 ms between guns, with the SPEC pin at 80 ms. The ripple is desynced per ship. Two ships firing "at the same time" should not produce identical flash patterns. This is the grammar rule that volleys ripple and never fire as one blob (job_a_evidence.md, SPEC.md, Effects grammar).

### 2. Travel

- Projectile type: a visible shell tracer, not a beam and not a missile. The tracer has a bright core and a short hot streak behind it, 20 to 40 units long. It is not a long engine trail.
- Speed: 140 to 180 units per second, with the SPEC pin at 160. Travel distance to the impact point is 60 to 80 units, with the SPEC pin at 70. Flight time is therefore roughly 0.35 to 0.55 s. This is slow enough to read as a shell, not a laser.
- Trail: the tracer streak fades over 0.2 to 0.4 s. A faint smoke wisp may follow 5 to 15 units behind the shell, life 0.3 to 0.6 s. No coloured line is drawn across the screen. The shell itself is the read.

### 3. Impact

On shields (Voidsworn, Hegemony, Corsair, Ithar): a partial shield bubble ripples out from the hit point in the faction shield colour. Bright impact core 1 to 3 frames. Ripple radius 8 to 16 units. Fade 0.5 to 0.7 s, with the SPEC pin at 0.6 s. Corsair's shield flickers 2 to 4 times and is patchy, so parts of the ripple are missing or dimmer. The shield does not turn cyan; it uses the faction shield colour (job_a_evidence.md, FINDINGS R3).

On hull by target weight class: these weight classes are a design proposal, because the evidence file does not define them. Treat the class boundaries as UNSURE and tune them.

| Target class | Flash | Sparks | Debris | Decal result |
|---|---|---|---|---|
| Light (strike craft, small escort) | 1 to 2 frames | 5 to 12 | 2 to 4 small pieces | Scorch 0.1 to 0.2 ship units, stage 1 |
| Medium (frigate, destroyer) | 2 to 4 frames | 10 to 25 | 4 to 10 pieces | Scorch 0.2 to 0.4 ship units, dent, stage 1 to 2 |
| Heavy (cruiser) | 3 to 5 frames | 20 to 40 | 8 to 15 pieces | Scorch 0.4 to 0.7 ship units, stage 2 to 3, small breach possible on repeated hits |
| Capital | 4 to 6 frames | 30 to 60 | 10 to 20 pieces | Scorch 0.6 to 1.0 ship units, stage 3, breach likely after several hits |

The decal stage ladder is defined in section 7. A single battery shell should not jump straight to a hull breach on a heavy or capital ship. It stages the damage.

### 4. Sound cue

A layered mechanical report. A low body thump, a metallic breech clank, and a distant boom tail. The four-gun ripple should be heard as four separate beats 70 to 90 ms apart, not one merged bang. The sound has 2 to 4 layers: body, mechanism, tail, and a faint shell whoosh. No high-pitched laser whine.

### 5. Faction differences

Faction tint applies to the muzzle flash edge, the tracer core and the impact flash. The smoke ring stays neutral dark grey, with a faint faction tint in the first 0.3 to 0.5 s.

| Faction | Battery read |
|---|---|
| Voidsworn | Ember-orange flash and tracer, warm smoke, heavy thump. Shield ripple in orange. |
| Hegemony | Pale blue-white flash, cleaner smoke, tighter ripple. Shield in pale blue. |
| Corsair | Red-orange flash, dirtier smoke, more uneven ripple. Shield in red, patchy and flickering. |
| Chorus | Yellow-green flash, thin smoke, hull hits only, no shield. |
| Ithar | Mint-white flash, smooth smoke, precise ripple. Shield in mint. |
| Deathless | Green flash, cold-looking sparks, hull hits only, no shield. |

## Sheet 2: Flak

Flak is the rapid-fire anti-air and area-denial kind. The evidence file lists flak as one of the seven weapon kinds but does not give a SPEC loop for it, so the values below are screen-tuned proposals and should be tagged UNSURE until tested. The design target is a dense, chattering curtain of small bursts, not a single big gun.

### 1. Fire

- Wind-up: 0.10 to 0.30 s for tracking and barrel spin-up. This is a light, fast weapon, so it does not take the heavy-weapon anticipation. Anticipation is a batch 7 DISAGREE value, but leg 2 restricts wind-up to heavy weapons, so flak uses the short end.
- Muzzle flash behaviour: small flashes, 1 to 2 frames each. 3 to 6 barrels ripple 40 to 80 ms apart. No large flame tongue and no lingering smoke ring. A thin muzzle smoke puff 0.3 to 0.6 s.
- Projectile count and ripple timing: 6 to 12 shells per burst, 2 to 4 bursts per engagement. The bursts are deliberately uneven. This is the "volleys ripple, never fire as one blob" rule applied to a rapid-fire weapon.

### 2. Travel

- Projectile type: small tracer shells. Bright core, thin trail 10 to 20 units. The shell is visible enough to read the direction of fire.
- Speed: 180 to 260 units per second. Faster than battery shells, slower than gauss.
- Fuse and burst: proximity airburst at 20 to 40 units from the target, or on contact if the target is closer. The burst produces a smoke puff 1.5 to 3 units across, life 0.8 to 1.5 s. Shrapnel fragments 10 to 30 per burst, speed 60 to 120 units per second, life 0.3 to 0.6 s.

### 3. Impact

On shields: many small ripples across the shield surface, each 0.2 to 0.4 s, in the faction shield colour. The whole burst counts as one flash event for the 3-per-second budget, not 12 separate flashes. Corsair's shield flickers and dims in patches.

On hull by target weight class: flak is a pitting weapon. It does not make clean holes by itself.

| Target class | Flash | Sparks | Debris | Decal result |
|---|---|---|---|---|
| Light | 1 frame per hit | 3 to 8 | 1 to 3 | Pitting, scorch dots 0.05 to 0.15 ship units, stage 1 |
| Medium | 1 to 2 frames per hit | 5 to 12 | 2 to 5 | Scorch clusters 0.1 to 0.25, stage 1 |
| Heavy | 1 to 2 frames per hit | 8 to 15 | 3 to 6 | Surface pitting, stage 1, massed fire can reach stage 2 |
| Capital | 1 to 2 frames per hit | 10 to 20 | 4 to 8 | Cosmetic pitting, stage 1, only sustained fire reaches stage 2 |

Flak is intentionally bad at breaching heavy armour. It strips shields, kills strike craft and suppresses, but it does not replace a lance or torpedo for a breach.

### 4. Sound cue

Sharp cracks and popping, with a mechanical chatter underneath. The burst should sound like a rapid sequence of small explosions, not one large boom. A distant thump tail for the airburst. The sound has 3 layers: crack, chatter, tail.

### 5. Faction differences

| Faction | Flak read |
|---|---|
| Voidsworn | Orange tracer tips, warm bursts, heavy crack. Shield orange. |
| Hegemony | Blue-white tracer tips, clean bursts, precise rhythm. Shield blue. |
| Corsair | Red tracer tips, ragged rhythm, dirtier smoke. Shield red, patchy. |
| Chorus | Yellow-green tracer tips, hull pitting, no shield. The smoke has a faint spore tint, proposed and UNSURE. |
| Ithar | Mint tracer tips, very tight grouping, cool smoke. Shield mint. |
| Deathless | Green tracer tips, cold sparks, hull pitting, no shield. |

## Sheet 3: Lance

Lance is the heavy energy beam kind, the Sins-style beam. The evidence file's SPEC loop pins a thick beam from the bow to a point 80 units ahead, 0.7 s duration, a charge-up flare at 0.25 s before fire, a white-hot core, faction glow, heat shimmer, and an impact flare with a spark fountain (job_a_evidence.md, SPEC effect loop, item 3). Rogue Trader's lance weapons are described as long-range energy weapons, which supports the "thin, precise, high-energy" read rather than a shotgun (see source ledger). Sins of a Solar Empire II's traveling beams use length-based fade and speed controls, which is a useful reference for making a long beam readable in a crowded fight (see source ledger).

### 1. Fire

- Wind-up (charge-up): 0.20 to 0.30 s, with the SPEC pin at 0.25 s. The emitter flares in the faction weapon colour, with a white-hot centre. The charge-up is a clear tell. Anticipation is a batch 7 DISAGREE value, and lance is a heavy weapon, so both legs apply. Use 0.20 to 0.40 s as the compromise, with the lower half preferred for readability.
- Muzzle flash behaviour: there is no chemical muzzle flash. There is an emitter flare at the bow, 2 to 5 frames, plus a brief lens-like bloom on the emitter housing. The flare is not a smoke event.
- Beam count and ripple timing: one beam, not a volley. The lance is the exception to the ripple rule because it is a single sustained energy weapon. If a ship has multiple lance mounts, stagger them 150 to 300 ms apart so they do not merge into one thick bar.

### 2. Travel

- Beam type: a sustained energy column, not a projectile. White-hot core with a faction-coloured glow. The beam extends from the bow to 80 units ahead, with the SPEC pin at 80 units. It can be rendered as a full-length beam with a front fade, or as a fast traveling beam at 300 to 600 units per second reaching full length in 0.13 to 0.27 s. The Sins approach of fading the beginning and end is a valid reference for readability (see source ledger).
- Duration: 0.6 to 0.8 s, with the SPEC pin at 0.7 s. The beam does not flicker on and off. It may have a heat shimmer 0.1 to 0.3 s in duration travelling along its length, and a slight width pulse at 3 to 6 Hz.
- Afterglow: 0.3 to 0.6 s, cooling from white to faction colour to transparent. No lingering line after the afterglow. The R16 bar rejects orange lines across the hull, so the beam itself is the only line, and it ends cleanly.

### 3. Impact

On shields: the shield bubble is stressed over a wider area than a battery hit. Bright core 2 to 4 frames in the faction shield colour, ripple 0.5 to 0.8 s. The ripple is smoother and more continuous than the battery ripple. Corsair's shield flickers 3 to 5 times and may show a patchy hole for 0.1 to 0.2 s, but it does not collapse unless the shield is already low.

On hull by target weight class: the lance burns a line and then tears. It is a heavy weapon, so it can reach deeper stages faster than battery.

| Target class | Flash | Sparks | Debris | Decal result |
|---|---|---|---|---|
| Light | 2 to 3 frames | 10 to 20 | 3 to 6 | Burn line 0.2 to 0.4 ship units, stage 2 |
| Medium | 3 to 4 frames | 15 to 30 | 5 to 10 | Burn line 0.3 to 0.6, torn edges, stage 2 to 3 |
| Heavy | 4 to 5 frames | 20 to 40 | 8 to 15 | Burn line 0.5 to 0.9, glowing torn edges, stage 3 |
| Capital | 5 to 6 frames | 30 to 60 | 10 to 20 | Burn line 0.7 to 1.2, stage 3 to 4, breach likely |

The impact spark fountain is a SPEC requirement: 15 to 35 sparks travelling outward in a cone, life 0.3 to 0.8 s, plus a bright impact flare at the far end. The sparks are hot white-yellow at birth and cool to faction colour.

### 4. Sound cue

A rising electrical hum during the charge-up, 0.20 to 0.40 s, then a sharp crack at fire, then a sustained sizzle for the beam duration. The hum should pitch upward, not stay flat. The sizzle has a slight crackle layer. No explosion boom at the impact unless the target is destroyed; the lance impact is a hot hiss plus a metallic ping.

### 5. Faction differences

| Faction | Lance read |
|---|---|
| Voidsworn | Orange glow around a white core, ember-like sparks, warm hum. Shield orange. |
| Hegemony | Pale blue glow, clean beam edges, steady hum. Shield pale blue. |
| Corsair | Red glow, ragged beam edge, flickering hum, patchy shield. |
| Chorus | Yellow-green glow, organic-looking beam edge, hull hit, no shield. The beam may leave a faint spore smear, proposed and UNSURE. |
| Ithar | Mint-white glow, very smooth beam, cool hum. Shield mint. |
| Deathless | Green glow, cold-looking beam, hull hit, no shield. |

## Sheet 4: Torp

Torp is the torpedo kind. The evidence file lists torp as a weapon kind and the K2 items include a torpedo telegraph: a two-stage warning, about 800 ms ramp to white, and an interception call (job_a_evidence.md, K2 A5 items). That telegraph is not yet scheduled by name, so the values below are proposals and should be treated as UNSURE until the K2 item is scheduled. The design target is a slow, readable, high-consequence weapon that gives the defender a chance to react.

### 1. Fire

- Wind-up: 0.40 to 0.80 s. The torpedo tube opens, a pressure bloom escapes, and the torpedo ignites. This is longer than battery or lance because the telegraph is part of the weapon's readability.
- Muzzle flash behaviour: tube flash 1 to 2 frames, mostly white with faction tint. A smoke puff 1 to 2 s. No large flame tongue. The torpedo's motor ignition is the visual event, not the tube flash.
- Projectile count and ripple timing: one or two torpedoes per launch. If two, stagger them 200 to 400 ms apart so they do not overlap into one blob.
- Telegraph: two-stage warning, 700 to 900 ms total ramp to white, with the K2 pin at about 800 ms. The first stage is a dim faction-coloured pulse at the launching ship or the torpedo; the second stage ramps to white and holds for 100 to 200 ms before launch. An interception call is available if the target has point defence. K2 item, UNSURE on exact timing.

### 2. Travel

- Projectile type: a self-propelled torpedo with a visible body and a motor plume. It is not an instant-hit beam and not a small shell.
- Speed: 40 to 80 units per second. Slow enough that the defender can see it coming and respond. This is intentionally much slower than battery or gauss.
- Trail: smoky exhaust 30 to 60 units long, life 1.5 to 3 s, with a slight wobble 1 to 3 units in amplitude. The trail thins and cools from faction-coloured hot gas to grey smoke. It is not a clean line.

### 3. Impact

On shields: a large shield ripple, 0.6 to 1.0 s, with a bright core 2 to 4 frames. The shield surface may wash with faction colour for 0.2 to 0.4 s. Corsair's shield flickers violently and may show a temporary patchy hole. The torpedo is a shield-breaker as much as a hull-breaker.

On hull by target weight class: torpedoes are the most likely weapon to produce a breach.

| Target class | Flash | Sparks | Debris | Decal result |
|---|---|---|---|---|
| Light | 3 to 5 frames | 15 to 30 | 6 to 12 | Crater 0.3 to 0.6 ship units, stage 3, often destroyed |
| Medium | 3 to 5 frames | 20 to 40 | 8 to 18 | Crater 0.4 to 0.8, stage 3, breach likely |
| Heavy | 4 to 6 frames | 25 to 50 | 10 to 20 | Crater 0.6 to 1.0, stage 3 to 4, breach very likely |
| Capital | 5 to 7 frames | 30 to 60 | 12 to 25 | Crater 0.8 to 1.2, stage 4, breach and secondary explosions |

A torpedo impact also produces a shockwave ring 0.5 to 1.0 s, a fireball 0.8 to 1.5 s, and dark smoke 2 to 4 s. If the torpedo is intercepted, the result is a small flash, a debris puff and a smoke cloud, not a full explosion. The interception call is a separate K2 item and should be treated as UNSURE until scheduled.

### 4. Sound cue

A launch whoosh, a motor ignition rumble, and a rising whistle during travel. The impact is a deep boom with a long tail. The whistle is important: it is the audio half of the telegraph. The sound has 4 layers: whoosh, motor, whistle, boom. The whistle should be audible for at least 1.0 to 2.0 s before impact so the player has a cue.

### 5. Faction differences

| Faction | Torp read |
|---|---|
| Voidsworn | Orange motor plume, warm smoke, heavy boom. Shield orange. |
| Hegemony | Blue-white motor plume, clean smoke, sharp whistle. Shield pale blue. |
| Corsair | Red motor plume, dirty smoke, ragged whistle. Shield red, very patchy. |
| Chorus | Yellow-green motor plume, spore-like smoke, hull hit, no shield. The torpedo may be a bio-warhead variant, proposed and UNSURE. |
| Ithar | Mint motor plume, smooth smoke, clean whistle. Shield mint. |
| Deathless | Green motor plume, cold smoke, hull hit, no shield. |

## Sheet 5: Bio

Bio is the organic or biological weapon kind. The evidence file lists bio as one of the seven kinds but gives no SPEC loop, so the values below are proposals and should be tagged UNSURE. The design target is a weapon that feels alive: slow, wet, clinging, and persistent. It should not read as a recoloured battery shell. The R16 bar wants damage that streams and clings, not orange lines, and bio is the natural place to push that.

### 1. Fire

- Wind-up: 0.30 to 0.70 s. The launcher contracts and pulses, then releases. The motion is organic, not mechanical. Anticipation is a batch 7 DISAGREE value; bio is not a standard heavy weapon, so use the lower half of the range, 0.30 to 0.45 s, as the default.
- Muzzle flash behaviour: there is no bright muzzle flash. Instead, a wet bioluminescent puff in the faction weapon colour, 2 to 4 frames, plus a spray of droplets 0.2 to 0.5 s. The puff is dimmer than a battery flash and should not count as a full flash for the 3-per-second budget unless it exceeds the bloom threshold.
- Projectile count and ripple timing: 1 to 3 globs per launch, staggered 100 to 200 ms apart. Each glob is a separate organism, not a fragment of one shell.

### 2. Travel

- Projectile type: a wobbling glob of bio matter with a faint internal glow. It is not streamlined and it does not travel in a perfectly straight line.
- Speed: 60 to 120 units per second. Slow, readable, and slightly unpredictable.
- Trail: dripping bio matter and a faint spore trail, 15 to 30 units long. Droplets fall away from the glob and fade over 0.5 to 1.5 s. The trail is not a clean line; it is a sequence of blobs and droplets.
- Lifetime: 1 to 3 s before impact or dissipation.

### 3. Impact

On shields: the glob splashes against the shield and clings for 0.2 to 0.5 s before sliding off. The shield ripple is in the faction shield colour, but it is contaminated by the bio colour, producing a mottled patch. Bright core is weak, 1 to 2 frames. The shield does not flare as brightly as it does for battery or lance. Corsair's shield may flicker where the bio matter clings.

On hull by target weight class: bio damage is a lingering corrosion, not a single impact.

| Target class | Flash | Sparks | Debris | Decal result |
|---|---|---|---|---|
| Light | 1 frame | 2 to 6 | 2 to 5 organic pieces | Corrosion patch 0.15 to 0.35 ship units, stage 1 to 2 over 1 to 3 s |
| Medium | 1 to 2 frames | 3 to 10 | 3 to 8 | Corrosion patch 0.25 to 0.5, stage 2 over 2 to 4 s |
| Heavy | 1 to 2 frames | 5 to 12 | 4 to 10 | Corrosion patch 0.4 to 0.7, stage 2 to 3 over 2 to 5 s |
| Capital | 1 to 2 frames | 5 to 15 | 5 to 12 | Corrosion patch 0.5 to 0.9, stage 3 over 3 to 6 s |

The immediate impact is a sizzle, a smoke puff and a wet slap. The corrosion continues to spread for 2 to 6 s, darkening the hull and producing small bubbles and fumes. If the target is destroyed while corroded, the wreck continues to smoke with a bio tint for 2 to 5 s. Persistent corrosion is the bio signature.

### 4. Sound cue

A wet slap at launch, a gurgle during travel, and a hiss plus bubbling at impact. The sound has 3 layers: wet launch, gurgle, corrosion hiss. No sharp crack and no high-energy whine.

### 5. Faction differences

| Faction | Bio read |
|---|---|
| Voidsworn | Orange-glowing bio matter, ember-like droplets, warm gurgle. Shield orange, contaminated. |
| Hegemony | Pale blue-glowing bio matter, clean droplets, cold gurgle. Shield pale blue. |
| Corsair | Red-glowing bio matter, dirty droplets, ragged gurgle. Shield red, patchy. |
| Chorus | Yellow-green bio matter, spore clouds, hull hit, no shield. This is the most natural faction fit for bio, proposed and UNSURE. |
| Ithar | Mint-glowing bio matter, smooth droplets, cool gurgle. Shield mint. |
| Deathless | Green bio matter, cold fumes, hull hit, no shield. |

## Sheet 6: Gauss

Gauss is the hypervelocity kinetic kind. The evidence file lists gauss as a weapon kind but gives no SPEC loop, so the values below are proposals and should be tagged UNSURE. The design target is speed and penetration: a blue-white flash, a nearly instant impact, a small entry hole and a violent exit. BattleTech community descriptions of gauss rifles mention a heavy white-blue muzzle flash and a bright projectile streak, but this is fan discussion, not an official specification, so exact BattleTech values are UNSURE (see source ledger). The visual principle is consistent with the R16 bar: a hard, realistic kinetic punch, not an orange line.

### 1. Fire

- Wind-up: 0.10 to 0.30 s. Coil glow sequence 2 to 4 stages over 0.10 to 0.20 s. The glow is blue-white with a faction tint at the edges. This is a fast heavy weapon, so anticipation is a batch 7 DISAGREE value: leg 1 says 0.3 to 0.6 s, leg 2 says 6 to 12 frames. Use 0.10 to 0.30 s because the coil glow is the tell and the weapon is not a slow siege gun.
- Muzzle flash behaviour: a blue-white flash, 1 to 3 frames, with a very short ionized puff. No smoke ring and no flame tongue. The flash is brighter and whiter than battery or flak. The muzzle may emit a brief electromagnetic distortion ring 0.1 to 0.2 s.
- Projectile count and ripple timing: one slug. No ripple. Gauss is a single, precise shot.

### 2. Travel

- Projectile type: a hypervelocity slug with a bright blue-white streak. It is not a glowing ball and not a beam.
- Speed: 400 to 800 units per second, or near hitscan with a visible streak. The slug should cross the engagement range in under 0.2 s. If the engine can support it, a hitscan trace with a short visible streak is acceptable; otherwise a fast projectile is fine.
- Trail: 10 to 30 units of bright streak, fading over 0.1 to 0.2 s. A faint shockwave distortion 0.1 to 0.2 s behind the slug. No smoke trail and no lingering line.

### 3. Impact

On shields: a sharp, tight ripple, 0.3 to 0.5 s, with a high-frequency flicker. The shield colour is the faction shield colour. Bright core 1 to 2 frames. The impact is smaller in area than a battery hit but sharper in intensity. Corsair's shield may flicker briefly.

On hull by target weight class: gauss penetrates. It makes a small entry and a large exit.

| Target class | Flash | Sparks | Debris | Decal result |
|---|---|---|---|---|
| Light | 1 to 2 frames | 5 to 12 | 3 to 6 | Entry hole 0.05 to 0.10 ship units, stage 2 |
| Medium | 2 to 3 frames | 10 to 25 | 5 to 12 | Entry hole 0.08 to 0.15, spall, stage 2 to 3 |
| Heavy | 3 to 4 frames | 15 to 35 | 8 to 15 | Entry hole 0.10 to 0.20, stage 3, breach possible |
| Capital | 3 to 5 frames | 20 to 45 | 10 to 18 | Entry hole 0.15 to 0.25, stage 3, breach possible after multiple hits |

The signature is the entry hole: small, dark, with a ring of scorched metal. The exit damage is a spray of spall and debris on the far side, 5 to 15 pieces. The decal is a dent that becomes a hole, not a scorch line. The impact sound arrives after the visual if the slug is supersonic: a crack at impact, then a deeper sonic boom 0.2 to 0.5 s later.

### 4. Sound cue

A sharp crack at fire, a brief electromagnetic hum from the coils, a supersonic crack at impact, and a metallic ring. The sound has 3 layers: coil hum, crack, ring. No low boom unless the target is destroyed.

### 5. Faction differences

| Faction | Gauss read |
|---|---|
| Voidsworn | White-blue flash with orange edge, warm sparks. Shield orange. |
| Hegemony | Clean blue-white flash, precise streak, cold sparks. Shield pale blue. |
| Corsair | White-blue flash with red edge, dirtier spall. Shield red, patchy. |
| Chorus | Yellow-green edge on the flash, hull hit, no shield. The slug may be a bio-metal composite, proposed and UNSURE. |
| Ithar | Mint-white flash, very clean streak, cool sparks. Shield mint. |
| Deathless | Green-white flash, cold sparks, hull hit, no shield. |

## Sheet 7: SQ (strike craft)

SQ is the strike craft kind. The evidence file lists sq as one of the seven kinds but gives no SPEC loop, so the values below are proposals and should be tagged UNSURE. The design target is many small, fast attackers that read as a swarm, not as a single ship. The 4-second loop and the 0.5 s stagger can be applied per craft or per squadron, but the squadron should not fire as one synchronized block. Sins of a Solar Empire II's carrier launch points are a relevant reference for how strike craft leave a hull, but that is a launch reference, not a weapon-effects reference (see source ledger).

### 1. Fire

- Wind-up: 0.05 to 0.15 s per craft. The craft noses down, guns spin up, then fire. This is a light, fast weapon, so anticipation is a batch 7 DISAGREE value, but strike craft are not heavy weapons; use the short end.
- Muzzle flash behaviour: small flashes, 1 frame each, in the faction weapon colour. 2 to 6 craft in a run, each firing 1 to 3 bolts. The flashes are deliberately out of phase so the run reads as a ragged volley, not a single burst.
- Projectile count and ripple timing: 2 to 6 craft per run, 1 to 3 bolts per craft, ripple 20 to 60 ms between bolts. A full squadron run can produce 6 to 18 bolts, but they are spread over 0.3 to 0.8 s.

### 2. Travel

- Projectile type: small bolts or pulses, not full-size shells.
- Bolt speed: 200 to 350 units per second. Fast enough to feel like a fighter attack, slow enough to see the individual bolts.
- Bolt trail: 10 to 25 units, fading over 0.1 to 0.3 s.
- Craft speed: 100 to 200 units per second during a strafing run. The craft themselves have engine trails, which are covered in section 6.

### 3. Impact

On shields: many small ripples, each 0.2 to 0.3 s, in the faction shield colour. A massed run can overlap into a larger shimmer, but the individual hits should still be visible. Treat the run as one flash event for the 3-per-second budget if the bolts land within 0.2 s of each other.

On hull by target weight class: strike craft are a pitting and harassment weapon.

| Target class | Flash | Sparks | Debris | Decal result |
|---|---|---|---|---|
| Light | 1 frame per hit | 3 to 8 | 1 to 4 | Pitting, stage 1 |
| Medium | 1 frame per hit | 4 to 10 | 2 to 5 | Scorch clusters, stage 1 |
| Heavy | 1 to 2 frames per hit | 5 to 12 | 3 to 6 | Surface pitting, stage 1, massed run can reach stage 2 |
| Capital | 1 to 2 frames per hit | 5 to 15 | 3 to 8 | Cosmetic pitting, stage 1, only sustained runs reach stage 2 |

Strike craft do not breach heavy hulls by themselves. Their job is to strip shields, chase other strike craft, and add pressure.

### 4. Sound cue

A buzzing engine note, rapid zip sounds for the bolts, and small impacts. The sound has 3 layers: engine buzz, zip, patter. The engine buzz should be audible before the bolts, so the player hears the run coming.

### 5. Faction differences

| Faction | SQ read |
|---|---|
| Voidsworn | Orange bolt tips, warm engine buzz. Shield orange. |
| Hegemony | Blue-white bolt tips, clean engine buzz. Shield pale blue. |
| Corsair | Red bolt tips, ragged engine buzz, sooty exhaust. Shield red, patchy. |
| Chorus | Yellow-green bolt tips, spore-like engine puffs, hull hit, no shield. |
| Ithar | Mint bolt tips, smooth engine buzz. Shield mint. |
| Deathless | Green bolt tips, cold engine buzz, hull hit, no shield. |

## 6. Engine trails per faction

Engine trails are part of the same cinematic bar as weapons. The evidence file's SPEC loop gives the general shape: a hot core at each nozzle with a white-yellow centre and a faction-tinted edge, a turbulent plume about 1.5 ship-widths long that flickers, and a long fading exhaust trail behind the ship about 60 units, thinning and cooling in colour as it fades, slightly wavering (job_a_evidence.md, SPEC effect loop, item 1). The values below give ranges around those pins. Corsair is explicitly different: it sputters, coughs soot, and is uneven.

General engine trail:

- Nozzle core: white-yellow centre, 1 to 3 units across, with a faction-tinted edge 1 to 2 units thick. Flicker 8 to 15 Hz.
- Plume length: 1.2 to 1.8 ship widths, with the SPEC pin at about 1.5. The plume is turbulent, not a perfect cone.
- Exhaust trail: 50 to 70 units long, with the SPEC pin at about 60. Fade time 1.5 to 3.0 s. The trail thins and cools from faction colour to dark grey or transparent. Slight waver 2 to 5 units in amplitude.
- Lighting: the engine adds light to the hull and nearby geometry. It does not change exposure. One key light and fixed exposure are global rules (job_a_evidence.md, SPEC.md, Effects grammar).

| Faction | Engine colour | Read |
|---|---|---|
| Voidsworn | (1.0, 0.50, 0.16) | Ember orange, steady with occasional bright flares, warm smoke. |
| Hegemony | (0.45, 0.72, 1.0) | Clean pale blue, tight plume, minimal smoke, very steady. |
| Corsair | (1.0, 0.38, 0.16) | Sooty orange, sputters and coughs dark smoke, uneven 4 to 10 Hz, visible pulses. This is the explicit SPEC exception. |
| Chorus | (0.80, 0.90, 0.28) | Yellow-green, soft plume with spore-like puffs, proposed and UNSURE. |
| Ithar | (0.62, 1.0, 0.84) | Mint green, smooth and cool, very little smoke. |
| Deathless | (0.15, 1.0, 0.35) | Green, guttering and cold, with occasional ember pops, proposed and UNSURE. |

The engine trail is not a weapon trail. It is longer, softer and more continuous. Weapon trails are short and hot; engine trails are long and cooling.

## 7. The staged damage ladder

The evidence file requires damage to be staged on the hull: scorch, then torn holes, with venting, sparks, fire at the breach, and parts that come off leaving torn edges with squibs, never a clean swap (job_a_evidence.md, SPEC.md, Effects grammar). The R16 bar specifically rejects orange lines and asks for holes with streaming parts, fire and other damage. The ladder below turns that into five stages. It draws on Homeworld 3's public description of surface scars progressing to hull breaches with secondary hot spots and burn marks (see source ledger), and on Star Citizen's public description of hull glow, paint burn, bubbling, peeling, denting and holes that expose internals (see source ledger). The stage boundaries and sizes are screen-tuned guesses.

| Stage | Visual | Decals and geometry | Effects | Timing and persistence |
|---|---|---|---|---|
| 0: Intact | Clean hull, paint and panels readable. | None. | Engine trail only. | Until first damage. |
| 1: Scorched | Matte black scorch, slight roughness change, no glow. Paint may darken but not peel. | Scorch decal 0.1 to 0.4 ship units across, irregular edge. | Thin smoke wisp 1 to 3 s, occasional ember 0.1 to 0.3 s. | Persistent until repaired. Smoke fades; scorch stays. |
| 2: Dented | Surface deformation, paint bubbling and peeling at the edges, bare metal beginning to show. | Dent depth 0.05 to 0.15 ship units, scorch 0.2 to 0.5, small paint peel patches. | Small debris 1 to 3 pieces, sparks 1 to 4 per event, smoke 0.5 to 2 s. | Persistent. Dent and peel stay. |
| 3: Exposed structure | Paint gone over a larger patch, ribs, wiring and internal structure visible, no through-hole yet. | Exposed patch 0.3 to 0.7 ship units across, torn metal edges, dark recess 0.05 to 0.1 deep. | Intermittent sparks 2 to 5 per second, smoke puffs 0.5 to 1.5 s, small debris 1 to 3. | Persistent. Sparks and smoke pulse intermittently. |
| 4: Hull breach | A torn hole with jagged glowing-hot edges, dark interior, gas venting, fire licking out, secondary explosions. | Hole about 1/10 of ship length across, with the SPEC pin. Jagged edges, not a clean circle. Dark recess. | Venting gas jet 0.5 to 1.5 ship units, fire 0.2 to 0.5 ship units, sparks 3 to 8 per burst, secondary explosion every 3 to 8 s, debris 2 to 5 per event. | Persistent. Fire and venting continue until death or repair. |
| 5: Wreck | The ship is destroyed and becomes a drifting wreck with fires, debris and torn chunks. | Chunks keep torn edges with squibs. No clean swaps. | Fires, smoke, embers, occasional secondary explosions. | See section 8. |

The ladder is cumulative. A breach still shows the earlier scorch and dent around it. The decals should blend, not replace each other. Star Citizen's public damage description supports the idea of layered surface change before a hole opens (see source ledger). Homeworld 3's public description supports the progression from surface scars to breaches (see source ledger). The exact stage thresholds are UNSURE and should be tuned against hull hit points and weapon damage.

## 8. Ship death and wreck behaviour

The evidence file's destruction event is scene-wide, once per 12 s, using a seventh ship that is a copy of the Hegemony hull at 0.6 scale, placed above the formation. It explodes with a blinding flash, an expanding shockwave ring, a rolling fireball with dark smoke, 3 to 5 large hull chunks, a spray of small debris and embers, and a burning wreck chunk that drifts on. It reappears whole 2 s before the next event (job_a_evidence.md, SPEC effect loop, item 6). The ranges below are centred on those pins. The squib behaviour is supported by Star Citizen's public description: squibs detonate along the separation edge, cause holes and burn damage, reveal the ship's guts, and particles add smoke, explosions and sparks (see source ledger).

Death sequence:

- Trigger: hull reaches zero, or the scene-wide destruction event fires. The death sequence is not a clean swap and not a vanish.
- Flash: 1 to 3 frames. The flash lights nearby hulls for 0.1 to 0.3 s. It adds light but does not change exposure.
- Shockwave ring: expands from 10 to 20 units to 40 to 80 units over 0.5 to 1.5 s, fading as it expands.
- Fireball: 0.8 to 1.5 s, rolling, with a white-yellow core and faction-tinted edges. Dark smoke follows for 2 to 5 s.
- Large chunks: 3 to 5 chunks, with the SPEC pin at 3 to 5. Chunks are pieces of the ship's own mesh or prepared chunk meshes. Tumbling speed 5 to 20 units per second. Burning edges. Squibs along the break line, 2 to 6 squibs per chunk, each producing a small flash, sparks and a puff of smoke. Torn edges, not clean cuts.
- Small debris and embers: 20 to 50 small debris pieces, 30 to 80 embers. Life 1 to 4 s. Debris is affected by the shockwave.
- Wreck chunk: one burning wreck chunk drifts on at 5 to 15 units per second. Fires persist 5 to 15 s. The wreck fades over 12 to 20 s. It does not disappear abruptly.
- Scene-wide cadence: every 10 to 14 s, with the SPEC pin at 12 s. The seventh ship is at 0.6 scale above the formation. It reappears whole 1.5 to 2.5 s before the next event, with a fade-in of 0.5 to 1.0 s.
- Sound: a sharp flash crack, a deep boom, a debris patter, and a fire roar. The boom tail is 1 to 3 s. The debris patter is 0.5 to 2 s after the boom.
- Hitstop and shake during death: Hitstop is a batch 7 DISAGREE value (leg 1: 3 to 6 frames; leg 2: 2 to 5 normal, 8 to 12 kills and criticals). For a capital-scale death, use 7 to 12 frames. Screen shake is a batch 7 DISAGREE value (leg 1: 0.2 to 0.5 s; leg 2: at most 0.25 s, positional only, trauma model). For death, use 0.15 to 0.30 s positional shake with a trauma model, and allow 0.35 to 0.45 s only for the largest explosions. Both are tunable and should be exposed to the reduce-motion and reduce-shake accessibility settings.

## Accessibility and global constraints

- Flash budget: at most 3 flashes per second anywhere. A flash is a near-full-screen or large-area luminance jump above the bloom threshold. Muzzle flashes, impact flashes, shield breaks, torpedo detonations and destruction flashes all share the budget. When the budget would be exceeded, the effect is converted to a faction-coloured emissive ramp with no white frame, and the fade is lengthened by 1.5x to 2x. The event still reads through smoke, debris and sound. The 3-per-second limit is a hard cap, not a target.
- Reduce-flashing option: a settings toggle that caps flashes at 1 per second, removes white flash frames entirely, lowers flash intensity by 40 to 70 percent, lengthens fades by 1.5x to 2x, and keeps smoke, debris, tracers and engine trails. It should also reduce or disable screen shake and hitstop for players who need it. This is separate from the global 3-per-second cap, which applies even when the option is off.
- No forced camera by default: the batch 7 readability rules are background only, and this sheet does not present forced camera as a requirement. If the effects pass later needs a camera treatment, it must be optional and off by default.
- Engine-neutral authoring: all values are described as visible outcomes and timing envelopes. Any engine can build them with decals, flipbooks, particle systems, shader parameters, mesh swaps and audio middleware. No Babylon-only or Godot-only implementation code is given. The tonemapper is not baked into any effect: Babylon tests ACES vs PBR Neutral, Godot adds AgX, and this is a batch 7 DISAGREE value. Effects are authored scene-linear, glow is applied before tone mapping, and the single key light with 25 to 40 percent cool fill and Fresnel rim is a global lighting rule (job_a_evidence.md, K2 A5 items; FINDINGS X1).
- Screen-tuned status: every numeric range in this document is a screen-tuned guess unless it is explicitly named as a SPEC pin. The SPEC pins themselves are also subject to later tuning. The batch 7 disagreement markers are not resolved by this sheet; they are flagged so the effects pass can test both legs.

END OF SHEET.
