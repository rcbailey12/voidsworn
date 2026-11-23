# Wave A3 Sound Ear Audit (Issues 1752 and 1853)

Listening and mono fold-down audit of all 18 Wave A3 ElevenLabs takes (`out_20261122_222753_165/out_new/elevenlabs/`) against today's game clips (`out_new/listen/audio/*_today*.ogg`). Every take was listened to in stereo, folded to mono `(L + R) / 2`, listened to again in mono, and measured with one Python/ffmpeg FFT script (44.1 kHz, power-weighted bands and stereo-to-mono band loss in dB).

## Bottom Line (Read Before Listening)

- **Scorecard: 7 keeps, 11 rejects** across 18 takes (9 ids).
  - **Strong ready-to-master keeps (5):** `shd_break_energy_t1.mp3`, `wep_directorate_laser_b_t1.mp3`, `wep_directorate_laser_b_t2.mp3`, `wep_ithar_shard_t1.mp3`, `wep_sunward_lance_beam_t2.mp3`.
  - **Dark-leaning keeps needing gain match and small-speaker check (2):** `wep_chorus_spines_t2.mp3`, `wep_eclipse_gauss_fire_t2.mp3`.
  - **Rejects (11):** `shd_break_energy_t2.mp3`, `wep_chorus_spines_t1.mp3`, `wep_directorate_laser_t1.mp3`, `wep_directorate_laser_t2.mp3`, `wep_eclipse_gauss_fire_t1.mp3`, `wep_eclipse_gauss_fire_ctl_t1.mp3`, `wep_eclipse_gauss_fire_ctl_t2.mp3`, `wep_ithar_shard_t2.mp3`, `wep_sunward_lance_beam_t1.mp3`, `wep_sunward_lance_beam_inf45_t1.mp3`, `wep_sunward_lance_beam_inf45_t2.mp3`.
- **Directorate laser pick: Recipe B (`wep_directorate_laser_b`) wins clearly.** Both Recipe B takes sound like disciplined capital-ship plasma cannons with zero retro raygun chirp and rock-solid mono coherence. Recipe A (`wep_directorate_laser`) produced tiny, quiet electrical switch snaps. Use Recipe B wording for Wave B Directorate weapons.
- **Lance beam pick: `wep_sunward_lance_beam` at influence 0.60 wins over `inf45` (0.45), with one big timing caveat.** Influence 0.60 gave a focused, mono-safe solar-thermal core (`t2`), while 0.45 drifted into wide-stereo hiss that collapses in mono. However, all four 1.8 s takes finish 95% to 99% of their energy by 0.30 to 0.60 s (rushing straight into the power-down), so Wave B beams should keep influence 0.60 and the tonal non-roar wording, and either match short lance visuals or split ignition + looped body + release in Godot.
- **Eclipse gauss control (`_ctl`): the new prompt helped mono survival and cleared a little top end on `t2`, but did NOT reliably fix the bass trap.** Both `_ctl` takes sound huge in stereo, yet both are 92% to 94% below 500 Hz and lose 3 to 4 dB of mid/high snap in mono. The new prompt fixed mono coherence on `t2`, but `t1` fell right back to 97.2% below 500 Hz and both new takes came out 7 to 10 dB quieter.

---

## Per-Take Verdict, Bass Check, and Mono Check

### 1. `shd_break_energy` (vs `today0` shieldBig, `today1` shieldHit, `today2` shieldShatter, `today3` shieldShimmer)

- **`shd_break_energy_t1.mp3` -> KEEP (trim 29 ms dead head).**
  1. **Verdict:** Keep `shd_break_energy_t1.mp3`: it reads as a real capital-ship energy barrier failing, with a crisp electrical crackle dropping into a heavy generator power-down that replaces today's synthy hum layers (`today1`, `today3`) in one coherent cue.
  2. **Bass (<500 Hz):** No, not trapped. Measured 59.4% below 500 Hz in mono (49.7% stereo), 15.6% in 500 Hz to 2 kHz, 25.0% above 2 kHz, centroid 1530 Hz, 0.0% below 20 Hz; the crackle and midrange wind-down read clearly over solid low weight.
  3. **Mono:** Wide stereo (corr 0.33), so mono drops 1.8 dB overall and 2.6 to 2.7 dB in mids, highs, and first-100 ms attack, making it slightly narrower and warmer; by ear in mono it still keeps its crackle and unmistakable power-down contour, so it survives.

- **`shd_break_energy_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject `shd_break_energy_t2.mp3`: it starts slowly (48 ms dead head, peak at 182 ms) and reads more like a noisy blown-transformer static spray with a weak power-down contour than a clean shield collapse, losing to `t1` and today's layered break (`today0` to `today3`).
  2. **Bass (<500 Hz):** No. Measured 33.5% below 500 Hz in mono, 24.0% in 500 Hz to 2 kHz, 42.5% above 2 kHz, centroid 2374 Hz; fizz-heavy rather than bass-trapped.
  3. **Mono:** Very wide stereo (corr 0.23), losing 2.1 dB overall and 2.3 dB above 2 kHz (attack -0.9 dB); folding to mono narrows the static into a flat, harsh hiss.

### 2. `wep_chorus_spines` (vs `today0` gunSpine)

- **`wep_chorus_spines_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject `wep_chorus_spines_t1.mp3`: it is a dull, muffled low-end thump that completely loses the brittle calcified-bone crack, even though it has more weight than today's tiny `gunSpine` tick (`today0`).
  2. **Bass (<500 Hz):** Yes, confirmed bass trap. Measured 90.0% below 500 Hz, 9.0% in 500 Hz to 2 kHz, and only 1.0% above 2 kHz (centroid 323 Hz); hears like a muffled cannon puff.
  3. **Mono:** Already dual-mono (corr 1.00, 0.00 dB loss across all bands); mono does not hurt it, the muffled dark tone kills it.

- **`wep_chorus_spines_t2.mp3` -> KEEP (needs loudness match; check presence in mix).**
  1. **Verdict:** Keep `wep_chorus_spines_t2.mp3`: it is a big physical upgrade over today's flimsy mosquito-like `gunSpine` tick (`today0`), opening with a crisp dry bone-bolt crack right at 0 ms (peak 23 ms) into a tight pressurized launch puff.
  2. **Bass (<500 Hz):** Borderline no (dark-leaning, not pure mud). Measured 78.8% below 500 Hz, 16.1% in 500 Hz to 2 kHz, 5.2% above 2 kHz (centroid 576 Hz, 1.7% below 20 Hz); by ear the dry front crack cuts through clearly, though raw RMS is quiet (-22.8 dB) and a gentle high-pass plus presence lift will help in battle.
  3. **Mono:** Already dual-mono (corr 1.00, -0.01 dB overall, -0.05 dB above 2 kHz); zero loss of punch or dry crack in mono.

### 3. `wep_directorate_laser` - Recipe A (vs `today0` laserLarge, `today1` laserLR)

- **`wep_directorate_laser_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject `wep_directorate_laser_t1.mp3`: it sounds like a small, quiet electrical breaker spark or taser click (-29.0 dB RMS, 71% over in 100 ms) rather than a capital-ship cannon; less cheesy than today's retro `laserLarge` pew (`today0`) but too tiny next to today's `laserLR` (`today1`) and Recipe B.
  2. **Bass (<500 Hz):** Borderline yes. Measured 80.5% below 500 Hz in mono, 7.6% in 500 Hz to 2 kHz, 11.9% above 2 kHz (centroid 715 Hz); thin click over a short low thump.
  3. **Mono:** Holds up fine (corr 0.87, -0.28 dB overall, -0.47 dB above 2 kHz, -0.12 dB attack); mono is not the issue, small scale is.

- **`wep_directorate_laser_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject `wep_directorate_laser_t2.mp3`: another short, quiet electrical switch snap (-27.9 dB RMS, 73% over in 100 ms) that feels too small for a starship weapon and weaker than today's `laserLR` (`today1`) and Recipe B.
  2. **Bass (<500 Hz):** Yes. Measured 83.9% below 500 Hz in mono, 8.1% in 500 Hz to 2 kHz, 8.0% above 2 kHz (centroid 614 Hz).
  3. **Mono:** Loses top end and bite (corr 0.54, -1.13 dB overall, -1.61 dB in 500 Hz to 2 kHz, -1.65 dB above 2 kHz, -1.06 dB attack); folding to mono dulls its already-thin electrical edge.

### 4. `wep_directorate_laser_b` - Recipe B (vs `today0` laserLarge, `today1` laserLR)

- **`wep_directorate_laser_b_t1.mp3` -> KEEP (standout Directorate take).**
  1. **Verdict:** Keep `wep_directorate_laser_b_t1.mp3`: it hits like a real cold, military capital-ship plasma cannon with a crisp superheated arc crack, solid directed-energy body, and zero retro raygun chirp, clearly beating both today's `laserLarge` (`today0`) and `laserLR` (`today1`).
  2. **Bass (<500 Hz):** No, weighty rather than trapped. Measured 78.9% below 500 Hz in mono, 7.7% in 500 Hz to 2 kHz, 13.3% above 2 kHz (centroid 966 Hz, 0.0% below 20 Hz, healthy -22.7 dB RMS); full low recoil with a bright, cutting attack on top.
  3. **Mono:** Virtually mono-identical (corr 0.96, -0.10 dB overall, -0.13 dB in 500 Hz to 2 kHz, -0.48 dB above 2 kHz, -0.14 dB attack); keeps full punch and crispness in mono.

- **`wep_directorate_laser_b_t2.mp3` -> KEEP (loudness-match as round-robin twin for `b_t1`).**
  1. **Verdict:** Keep `wep_directorate_laser_b_t2.mp3`: crisp, disciplined plasma-arc snap with clean midrange bite and zero toy pew; quieter raw (-28.4 dB RMS) and slightly lighter than `b_t1`, making a strong second variant over today's `laserLarge` (`today0`) once gain-matched.
  2. **Bass (<500 Hz):** No. Measured 66.8% below 500 Hz in mono, 14.3% in 500 Hz to 2 kHz, 18.8% above 2 kHz (centroid 1296 Hz, 0.0% below 20 Hz); the brightest, cleanest midrange bite of all four Directorate takes.
  3. **Mono:** Virtually pure mono (corr 0.99, -0.02 dB overall, -0.08 dB above 2 kHz, -0.04 dB attack); loses nothing in mono.

### 5. `wep_eclipse_gauss_fire` - New Prompt (vs `today0` boomLow, `today1` railStrike)

- **`wep_eclipse_gauss_fire_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject `wep_eclipse_gauss_fire_t1.mp3`: it is a tiny, quiet, muffled sub-bass thump (-29.8 dB RMS, 84% over in 100 ms) with almost no void snap or hollow obsidian ring, worse than today's `boomLow` and `railStrike` (`today0`, `today1`).
  2. **Bass (<500 Hz):** Yes, severe bass trap. Measured 97.2% below 500 Hz in mono, 1.5% in 500 Hz to 2 kHz, 1.3% above 2 kHz (centroid 183 Hz, plus 3.3% infrasonic below 20 Hz).
  3. **Mono:** Fails mono on its thin top end (corr 0.71, -0.71 dB overall, -2.70 dB in 500 Hz to 2 kHz, -2.98 dB above 2 kHz); collapses into a dull knock.

- **`wep_eclipse_gauss_fire_t2.mp3` -> KEEP (needs loudness match, high-pass, and small-speaker check).**
  1. **Verdict:** Keep `wep_eclipse_gauss_fire_t2.mp3`: it delivers a real dark electrostatic snap at 0 ms dropping into a cold, hollow alien gravity-weapon thump that sounds far more cohesive and otherworldly than today's split `boomLow` rumble (`today0`) and short `railStrike` click (`today1`).
  2. **Bass (<500 Hz):** Yes, still bass-heavy, though not pure mud. Measured 86.4% below 500 Hz in mono, 5.9% in 500 Hz to 2 kHz, 7.7% above 2 kHz (centroid 418 Hz, 3.2% below 20 Hz, quiet raw at -26.0 dB RMS); the front crack and eerie hollow ring are audible, so high-passing at 35 to 40 Hz and matching loudness makes it usable, with a small-speaker check recommended.
  3. **Mono:** Passes mono cleanly (corr 0.91, -0.21 dB overall, -0.76 dB in 500 Hz to 2 kHz, -0.81 dB above 2 kHz, -0.27 dB attack); keeps its electrostatic snap far better than either `_ctl` take.

### 6. `wep_eclipse_gauss_fire_ctl` - Old A2 Prompt Control (vs `today0` boomLow, `today1` railStrike)

- **`wep_eclipse_gauss_fire_ctl_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject `wep_eclipse_gauss_fire_ctl_t1.mp3`: it sounds huge and dramatic in stereo (-19.8 dB RMS), easily topping today's `boomLow` and `railStrike` (`today0`, `today1`), but it only works in stereo and turns muddy in mono.
  2. **Bass (<500 Hz):** Yes. Measured 92.1% below 500 Hz in mono (up from 83.4% in stereo), leaving just 2.9% in 500 Hz to 2 kHz and 5.0% above 2 kHz (centroid 426 Hz).
  3. **Mono:** Fails mono. Wide uncorrelated top end (corr 0.49) drops -3.36 dB in 500 Hz to 2 kHz, -3.22 dB above 2 kHz, and -2.04 dB on the first-100 ms attack; by ear the crisp void snap gets pulled back into bass boom.

- **`wep_eclipse_gauss_fire_ctl_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject `wep_eclipse_gauss_fire_ctl_t2.mp3`: loud cinematic bass drop in stereo (-18.6 dB RMS) that leans too much toward generic seismic boom over rail snap, and loses its snap and hollow ring when folded to mono.
  2. **Bass (<500 Hz):** Yes. Measured 93.9% below 500 Hz in mono, 2.2% in 500 Hz to 2 kHz, 3.9% above 2 kHz (centroid 346 Hz).
  3. **Mono:** Fails mono. Wide stereo (corr 0.45) drops -3.93 dB in 500 Hz to 2 kHz and -2.90 dB above 2 kHz (-1.12 dB attack), hollowing out the top end completely.

### 7. `wep_ithar_shard` (vs `today0` laserSmall, `today1` needleTick)

- **`wep_ithar_shard_t1.mp3` -> KEEP (standout Glasswright take; trim 13 ms dead head + high-pass).**
  1. **Verdict:** Keep `wep_ithar_shard_t1.mp3`: massive upgrade over today's arcade `laserSmall` pew (`today0`) and tiny `needleTick` ping (`today1`), sounding like a monumental ice-and-crystal prism fracturing with a luminous harmonic ring over a tight low-mid punch.
  2. **Bass (<500 Hz):** No. Measured 75.0% below 500 Hz in mono, 14.2% in 500 Hz to 2 kHz, 10.8% above 2 kHz (centroid 709 Hz, -19.6 dB RMS; 2.4% below 20 Hz to high-pass out); reads fast, bright, and crystalline with real weight underneath.
  3. **Mono:** Passes mono cleanly (corr 0.82, -0.41 dB overall, -0.10 dB in 500 Hz to 2 kHz, -1.04 dB above 2 kHz, -0.56 dB attack); keeps both punch and shimmering crystal tail.

- **`wep_ithar_shard_t2.mp3` -> REJECT (hard mono fail).**
  1. **Verdict:** Reject `wep_ithar_shard_t2.mp3`: it sounds nicely crystalline in stereo compared with today's `laserSmall` and `needleTick` (`today0`, `today1`), but it is out of phase between left and right and falls apart completely in mono.
  2. **Bass (<500 Hz):** Borderline yes in mono as the highs cancel out. Measured 80.7% below 500 Hz in mono, 11.5% in 500 Hz to 2 kHz, 7.8% above 2 kHz (centroid 599 Hz).
  3. **Mono:** Hard fail. Negative stereo correlation (-0.29); folding to mono drops -4.47 dB overall, -4.33 dB in 500 Hz to 2 kHz, -5.42 dB above 2 kHz, and -5.10 dB on the first-100 ms attack, leaving a thin, phase-cancelled shadow.

### 8. `wep_sunward_lance_beam` - Influence 0.60 (vs `today0` laserLarge, `today1` lanceLR)

- **`wep_sunward_lance_beam_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject `wep_sunward_lance_beam_t1.mp3`: hot, bright solar-furnace burst that avoids A2's noise brick and beats today's retro `laserLarge` (`today0`) and synthetic `lanceLR` (`today1`) in realism, but its ignition peaks late (266 ms, 20.5 ms dead head), its energy drops off by ~0.55 s, and it loses punch in mono.
  2. **Bass (<500 Hz):** No. Measured 31.7% below 500 Hz, 27.8% in 500 Hz to 2 kHz, 40.5% above 2 kHz (centroid 2457 Hz, 0.0% below 20 Hz); bright and slightly hissy on top, zero bass trap.
  3. **Mono:** Fails mono. Very wide stereo (corr 0.18) drops -2.30 dB overall, -2.28 dB in 500 Hz to 2 kHz, -2.44 dB above 2 kHz, and -2.51 dB on the first-100 ms attack, noticeably softening its bite and body.

- **`wep_sunward_lance_beam_t2.mp3` -> KEEP (best lance take; trim 26 ms dead head; short ~0.4 s active envelope).**
  1. **Verdict:** Keep `wep_sunward_lance_beam_t2.mp3`: focused, hot molten-metal and reactor-core discharge that clearly beats today's retro `laserLarge` (`today0`) and synthetic `lanceLR` screech (`today1`), matching today's ~0.4 s active punch as real physical hardware (95% of energy finishes by 300 ms, 99% by 470 ms).
  2. **Bass (<500 Hz):** No. Balanced full-band body: 43.9% below 500 Hz, 33.9% in 500 Hz to 2 kHz, 22.1% above 2 kHz (centroid 1611 Hz, 0.3% below 20 Hz).
  3. **Mono:** Passes mono (best of all four lance takes by far: corr 0.69, -0.73 dB overall, -0.43 dB in 500 Hz to 2 kHz, -1.35 dB above 2 kHz, -1.18 dB attack); keeps its focused tonal core and punch cleanly in mono.

### 9. `wep_sunward_lance_beam_inf45` - Influence 0.45 (vs `today0` laserLarge, `today1` lanceLR)

- **`wep_sunward_lance_beam_inf45_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject `wep_sunward_lance_beam_inf45_t1.mp3`: looser, washier furnace-jet whoosh with a slight synthetic whistle that fades out by ~0.45 s and loses ignition punch in mono, weaker than `wep_sunward_lance_beam_t2` despite sounding more physical than today's `laserLarge` (`today0`).
  2. **Bass (<500 Hz):** No. Measured 30.1% below 500 Hz, 32.9% in 500 Hz to 2 kHz, 37.0% above 2 kHz (centroid 2205 Hz).
  3. **Mono:** Fails mono. Wide stereo (corr 0.26) drops -2.01 dB overall, -2.16 dB in 500 Hz to 2 kHz, -2.29 dB above 2 kHz, and -2.66 dB on the first-100 ms attack.

- **`wep_sunward_lance_beam_inf45_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject `wep_sunward_lance_beam_inf45_t2.mp3`: thin, hissy arc-welder sizzle lacking capital-ship reactor weight, fading by ~0.45 s and collapsing badly in mono; lacks even the punch of today's `lanceLR` (`today1`).
  2. **Bass (<500 Hz):** No, opposite problem (too thin). Only 16.7% below 500 Hz, 30.1% in 500 Hz to 2 kHz, and 53.2% above 2 kHz (centroid 3229 Hz).
  3. **Mono:** Hard fail. Nearly uncorrelated stereo (corr 0.07) drops -2.70 dB overall, -2.81 dB above 2 kHz, and -2.76 dB on the first-100 ms attack.

---

## The Two Style Picks and Gauss Control Call

### Pick 1: Directorate Weapons -> Use Recipe B (`wep_directorate_laser_b`)

- **Pick:** Rewrite the remaining Wave B Directorate weapons (`wep_directorate_turbo`, `wep_directorate_hturbo`, `wep_directorate_picket`, and the ignition/body tone of `wep_directorate_ion_beam`) around **Recipe B** ("military starship plasma cannon", "superheated plasma-arc crack", "focused directed-energy discharge punch", "strong bright midrange snap", "tight firm low recoil", "steady pitch, abrupt controlled cutoff").
- **Why:**
  - Recipe A ("high-voltage energy cannon", "capacitor-bank discharge", "buzzing electrical body") still behaves like Fable's breaker-switch trap: both takes (`wep_directorate_laser_t1.mp3`, `wep_directorate_laser_t2.mp3`) came out quiet (-27.9 to -29.0 dB RMS), over in ~100 ms, 81% to 84% below 500 Hz, and small like a relay spark.
  - Recipe B kept strictly flat pitch with **zero 80s toy raygun chirp**, gave real weapon sustain and authority (`b_t1` at -22.7 dB RMS, 46% energy in first 100 ms instead of 72%), opened up the top end (centroid 966 Hz and 1296 Hz, 21% to 33% above 500 Hz), and stayed almost pure mono (corr 0.96 and 0.99, <= 0.10 dB loss).

### Pick 2: Beams -> Keep Influence 0.60 (`wep_sunward_lance_beam`) and Fix the Sustain Envelope

- **Pick:** Keep **prompt influence 0.60** (reject 0.45) and keep the **tonal non-roar beam wording** ("bright ringing molten-metal core over a deep reactor furnace hum, holding one strong clear note") rather than A2's "roar / held solid and flat" wording.
- **Why influence 0.60 wins:** Lowering influence to 0.45 (`inf45_t1`, `inf45_t2`) drifted toward loose furnace hiss and thin welder sizzle (53% above 2 kHz on `inf45_t2`) with severe stereo decorrelation (corr 0.07 to 0.26, losing -2.0 to -2.8 dB in mono). At 0.60, `wep_sunward_lance_beam_t2.mp3` stayed tight, balanced (44% <500 Hz, 34% 500 Hz to 2 kHz, 22% >2 kHz), and mono-safe (corr 0.69, -0.73 dB).
- **Important recipe caveat for Wave B beams:** Asking one 1.8 s prompt to perform ignition + sustain + "then a fast falling power-down into silence" caused ElevenLabs v3 to rush straight into the power-down on all four takes (99% of energy finished by 0.47 to 0.60 s; the last 1.2 s is near-silence below -40 to -85 dB).
  - For a short lance pulse (~0.4 to 0.5 s, which matches today's `lanceLR` envelope), `wep_sunward_lance_beam_t2.mp3` already works.
  - For any Wave B beam that must visually sustain past 0.6 s (`wep_directorate_ion_beam`, `wep_ithar_pulsar`, `wep_eclipse_doom`, or a longer Sunward lance), drop the "fast falling power-down" clause from the body prompt and use section 8's modular Godot build (short ignition + looped steady tonal body + engine fade/pitch-down release) so the beam matches its real visual duration without paying for dead silence.

### Eclipse Gauss Control (`wep_eclipse_gauss_fire` vs `wep_eclipse_gauss_fire_ctl`)

- **Did the new prompt help?** **Partially, but it did not solve the bass trap.**
  - **Where it helped:** Dropping `"40 Hz"`, `"sub-bass"`, `"monumental sub-bass weight"`, and `"smooth top end"` stopped the extreme stereo phase-widening on `t2` (corr 0.91 vs 0.45 and 0.49 on `_ctl`) and gave `wep_eclipse_gauss_fire_t2.mp3` more usable energy above 500 Hz in mono (13.6% vs 7.9% and 6.1% on `_ctl`).
  - **Where it failed:** The new prompt still kept `"crushing seismic-charge cinematic bass impact wave"` and `"ancient alien monolith"`, so `t1` fell right back to 97.2% below 500 Hz (centroid 183 Hz), both new takes carried 3.2% to 3.3% infrasonic energy below 20 Hz, and both came out 7 to 10 dB quieter than `_ctl` (-29.8 and -26.0 dB RMS vs -19.8 and -18.6 dB).
  - **Takeaway for Wave B Eclipse prompts:** Keep `"40 Hz"` and `"sub-bass"` out (as proven by `_ctl`'s 92% to 94% bass-heavy mono collapse), and also tone down `"crushing seismic-charge cinematic bass"` to midrange-anchored snap wording (`"hard cold electrostatic snap"`, `"hollow bowed-obsidian mid-low knock"`) so Eclipse hits read clearly on laptop speakers and in mono without relying on lucky rolls.

---

## Mastering Checklist for the 7 Keeps (Before Game Wiring)

No edits were made here; apply these when moving approved takes into Godot (per `cohesive_audio_v2.md` section 8):

| File | Verdict | Dead head to trim | Mono fold loss (all / >2 kHz) | Notes for mastering |
|---|---|---|---|---|
| `shd_break_energy_t1.mp3` | Keep | ~29 ms | -1.76 / -2.72 dB | Fold to mono, high-pass 35 Hz, loudness match |
| `wep_chorus_spines_t2.mp3` | Keep | 0 ms | -0.01 / -0.05 dB | Fold to mono, high-pass 40 Hz, lift gain (-22.8 dB raw), optional +2 to 3 dB presence |
| `wep_directorate_laser_b_t1.mp3` | Keep | 0 ms | -0.10 / -0.48 dB | Fold to mono, high-pass 35 Hz, loudness match (lead take) |
| `wep_directorate_laser_b_t2.mp3` | Keep | 0 ms | -0.02 / -0.08 dB | Fold to mono, high-pass 35 Hz, lift gain (-28.4 dB raw) to match `b_t1` |
| `wep_eclipse_gauss_fire_t2.mp3` | Keep | 0 ms | -0.21 / -0.81 dB | Fold to mono, high-pass 40 Hz (3.2% <20 Hz), lift gain (-26.0 dB raw), check on small speakers |
| `wep_ithar_shard_t1.mp3` | Keep | ~13 ms | -0.41 / -1.04 dB | Fold to mono, high-pass 40 Hz (2.4% <20 Hz), loudness match |
| `wep_sunward_lance_beam_t2.mp3` | Keep | ~26 ms | -0.73 / -1.35 dB | Fold to mono, high-pass 35 Hz, trim silent tail past ~0.7 s if wired as a short lance |
