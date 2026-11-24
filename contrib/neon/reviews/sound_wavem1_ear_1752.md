# Wave M1 Music Ear Audit and Wave M2 Plan Check (Issues 1752 and 1989)

Direct listening and acoustic audit of all **3 Wave M1 ElevenLabs music takes** plus the **stem separation zip** (`opus1752wavem1/out_20261123_234509_1950/out_new/elevenlabs/`), compared against today's in-game Sunward and battle music (`godot/music/tracks/fac_voidsworn.ogg`, `calm_tactical.ogg`, `hot_pursuit.ogg`). Every source file, extracted stem (`drums`, `other`), crossfaded mix (`calm.wav`, `intense.wav` from `stem_loop_check.py`), loop wrap seam (`0.0 s`, `0.03 s`, `0.5 s`, `1.0 s`), and calm-to-intense / intense-to-calm switch at four loop positions was rendered and verified by ear alongside Python and ffmpeg spectral, envelope, and bar-grid checks.

## Bottom Line (Read First)

- **Wave M1 track calls:**
  - `mus_voidsworn_calm` (`t1`): **REJECT.** Good Sunward tone, but it climbs nearly 20 dB into a loud full-drum war march after 0:45, cannot loop back to its near-silent start, and drifts off-tempo against `hot`.
  - `mus_voidsworn_hot` (`t1`): **REJECT.** Good Sunward tone, but it builds into a fatiguing trailer climax, fades to dead silence over its last 5 seconds instead of looping, and drifts off-beat against `calm`.
  - `mus_battle_sunward_stemloop` (`t1` + stems): **KEEP.** Solid dark Sunward tactical groove with even energy across 16 bars, a calm mix that stands on its own musically, and dead-seamless calm-to-intense switches.
- **Stem loop seam and switch call:**
  - **Switches:** Seamless at all four test points (`4.9 s`, `14.8 s`, `24.7 s`, `34.6 s`) in both directions, with zero phasing, double-hits, or volume dips.
  - **Calm mix alone:** Stands on its own as tense dark orchestral battle underscore (`4.0 dB` under intense), though it feels more like "active battle without drums" than a quiet vigil and carries faint muted drum-thump ghosts in isolation.
  - **0.5 s crossfade seam:** **Audible rhythmic stumble.** The raw file is an exact 16-bar, `96.0 BPM`, `40.00 s` loop. Folding `0.5 s` of tail onto the head chops `0.50 s` (nearly a full `0.625 s` beat) out of the meter and ramps down bar 1's downbeat attack (`0.07 s`) by `-17 dB`. On the exact `40.00 s` grid with a `20` to `30 ms` click guard, the loop wraps right on the downbeat with zero stumble.
- **Wave M2 plan call: CHANGE before running all 44 steps.**
  1. Fix the loop crossfade method and bar-length rounding (8 of 11 battle loops round their 24-bar seconds off by `0.21` to `0.47 s`, and folding `0.5 s` onto an exact-bar loop breaks the beat grid).
  2. Run a cheap **2-track stem test on Glasswrights and Chorus first** (`mus_ithar_loop_a` and `mus_chorus_loop_a`) before spending ~46,000 credits on all 11 faction loops. ElevenLabs returned only `drums` + `other` on orchestral audio; light tuned percussion (Glasswrights) and soft heartbeat frame drums (Chorus) are high risk for a drums-only split.
  3. Shorten the 10 long looping tracks in M2 (`mus_map_*`, `mus_boss_*`, `mus_nemesis`, `mus_shop`, currently `96` to `120 s`) to `60` to `80 s`, because M1 proved `music_v2` holds flat loop energy at `40 s` but invents dramatic arcs and fade-outs at `101 s`. Also give boss and nemesis tracks their own stems (or play them solo), since today's `music_player.gd` layers boss `hot` over the enemy faction's `calm`, which will clash in key and tempo.
  4. Fix four specific faction prompt clashes in `waves.M2`: remove `"bowed metal and glass"` and `"tide"` from Chorus; remove `"Cinematic and heavy"` from Glasswrights; remove `"heavy anvil strikes"` from Eclipse so it stops colliding with Sunward; replace `"working-dock"` in `mus_shop`; and loosen the copy-pasted `"driving low ostinato + Cinematic and heavy"` template on Chorus, Glasswrights, and Eclipse so the six factions do not sound like skins of one action bed.

---

## Quick Scorecard (Wave M1)

| Track | Length | Call | One-Sentence Why |
|---|---:|---|---|
| `mus_voidsworn_calm_t1.mp3` | 101.04 s | **REJECT** | Fits the Sunward Crusade palette cleanly with no harshness or sea feel, but breaks its calm-loop prompt by climbing 19.8 dB into a loud full-drum war march after 0:45, cannot loop back to its quiet opening, and drifts off-tempo from `hot`. |
| `mus_voidsworn_hot_t1.mp3` | 101.06 s | **REJECT** | Hits the Sunward orchestral sound without harshness or sea feel, but ramps into a fatiguing movie-trailer climax around 1:15 to 1:35, fades to dead silence over its last 5 seconds instead of looping, and drifts out of sync with `calm`. |
| `mus_battle_sunward_stemloop_t1.mp3` (+ stems) | 40.03 s | **KEEP** | Delivers grounded, dark Sunward Crusade weight at steady energy across an exact 16-bar loop, splits into a musically solid no-drums calm layer with seamless intensity switches, and massively upgrades today's synthetic `fac_voidsworn.ogg` (just fix the 0.5 s seam fold in mastering). |

---

## 1. Track-by-Track Listening Notes (Wave M1)

### Baseline Check: Today's In-Game Music

- `godot/music/tracks/fac_voidsworn.ogg` (`180.5 s`, `-17.6 dB` RMS, `84.4%` in `40` to `120 Hz`, centroid `139 Hz`): sounds like dated retro synth-organ, buzzing sawtooth bass, and a clunky drum machine. All three M1 takes are a night-and-day leap in orchestral maturity and space-fleet weight.
- `godot/music/tracks/calm_tactical.ogg` (`64.0 s`, `-20.1 dB` RMS, centroid `335 Hz`) and `hot_pursuit.ogg` (`108.0 s`, `-19.4 dB` RMS, centroid `625 Hz`): `calm_tactical` is dry marimba/shaker percussion that feels lightweight for a dying-sun fleet war; `hot_pursuit` is fast generic action strings. M1's orchestral direction fits the game's tone far better.

### 1.1 `mus_voidsworn_calm_t1.mp3` -> REJECT

- **One-sentence call:** Reject: it fits the Sunward Crusade palette cleanly with no harshness or sea feel, but breaks its calm-loop prompt by climbing 19.8 dB into a loud full-drum war march after 0:45, cannot loop back to its near-silent opening, and drifts off-tempo against `hot`.
- **Sunward Crusade fit:** Yes. Dark weathered brass, solemn cellos and double basses, forge-iron anvil hits, and solemn minor-key gravity match Sunward Crusade well. Zero vocals or choir leaked.
- **20-minute battle fatigue:** The opening 30 seconds (`-34.6` to `-28.3 dB`) actually have great brooding vigil tension, but the track turns into a loud full-intensity war march (`-16.7` to `-14.8 dB`) by 0:45 and ends loud (`-16.9 dB` in the final second). Looping that back to `-45.4 dB` at `0:00` creates a jarring cliff every 101 seconds, and as a "calm" layer it completely destroys the contrast with `hot`.
- **Harsh or muddy bands:** None. Clean, warm orchestral balance (`0.3%` <40 Hz, `37.6%` 40 to 120 Hz, `30.3%` 120 to 500 Hz, `28.6%` 500 Hz to 2 kHz, `3.1%` 2 to 6 kHz, `0.2%` >6 kHz; centroid `466 Hz`, peak `-0.9 dBFS`, RMS `-18.0 dB`).
- **Sea or electronic-UI feel:** None. Pure space-orchestral weight.
- **Structural failure confirmed:** 5 s RMS climbs continuously from `-34.6 dB` to `-14.8 dB` (`19.8 dB` span), and onset tempo shifts from ~89.3 BPM in the first half to a ~61.1 BPM half-time/groove drift in the second half.

### 1.2 `mus_voidsworn_hot_t1.mp3` -> REJECT

- **One-sentence call:** Reject: it hits the Sunward orchestral sound without harshness or sea feel, but ramps into a fatiguing movie-trailer climax around 1:15 to 1:35, fades to dead silence over its last 5 seconds instead of looping, and drifts out of sync with `calm`.
- **Sunward Crusade fit:** Yes. Driving low strings, heavy war drums, anvil accents, and commanding dark brass match Sunward well. Zero vocals or choir.
- **20-minute battle fatigue:** Too theatrical in its back third. The first minute sits nicely at `-18.0` to `-14.3 dB`, but from 1:15 to 1:35 it swells into a booming movie-finale climax (`-12.3 dB`) with heroic brass, then resolves and fades out to `-58.5 dB` over the last 5 seconds (`45.7 dB` total span). Repeating a dramatic movie finale and fade-out every ~100 seconds would tire quickly in a 20-minute tactical fight and would compete with battle SFX during its peak.
- **Harsh or muddy bands:** None. Balanced orchestral spectrum (`0.4%` <40 Hz, `39.5%` 40 to 120 Hz, `29.2%` 120 to 500 Hz, `25.2%` 500 Hz to 2 kHz, `5.3%` 2 to 6 kHz, `0.5%` >6 kHz; centroid `549 Hz`, peak `-0.7 dBFS`, RMS `-14.8 dB`).
- **Sea or electronic-UI feel:** None.
- **Structural failure confirmed:** Steady ~90.7 BPM on its own, which drifts against `calm`'s tempo shift, and ends on a hard cadence + 5 s fade to silence.

### 1.3 `mus_battle_sunward_stemloop_t1.mp3` (and stems) -> KEEP

- **One-sentence call:** Keep: it delivers grounded, dark Sunward Crusade weight at steady energy across an exact 16-bar loop, splits into a musically solid no-drums calm layer with seamless intensity switches, and massively upgrades today's synthetic `fac_voidsworn.ogg`.
- **Sunward Crusade fit:** Strong match. Dark D-minor low brass motif, driving low cello/double-bass ostinato, measured war drums, metallic forge-iron strikes, and a dark sustained pad underneath. Note that M1's prompt omitted cathedral organ (which `mus_voidsworn_loop_b` adds), so this reads slightly leaner and more martial than `calm`/`hot`, which actually helps it sit cleanly under combat SFX. Zero vocals or choir (`vocals.mp3` in the stem zip is pure digital zero at `-240 dB`).
- **20-minute battle fatigue:** Much better suited for long tactical play than `hot_t1`. It stays brooding, restrained, and weighty from bar 1 to bar 16 (`4.5 dB` raw 5 s span, `2.2 dB` after xfade; `-17.2 dB` RMS) with no cheesy heroics or trailer swells. Its only fatigue risk is short length (`40.0 s` = 16 bars, ~30 repeats in a 20-minute fight), which the M2 plan of 24-bar loops (`~60 s`) and two loops per faction fixes cleanly.
- **Harsh or muddy bands:** No harshness (`3.4%` 2 to 6 kHz, `0.3%` >6 kHz; centroid `377 Hz`) and no mud in the mids. It is bass-forward (`44.6%` in `40` to `120 Hz` and `38.1%` in `120` to `500 Hz` on the full mix, because `66.8%` of the `drums` stem sits in `40` to `120 Hz`). That dark tilt keeps the midrange clear for gun cracks and UI clicks; during mastering, a gentle `35` to `40 Hz` high-pass (and a check against heavy cannons/explosions in game) is plenty.
- **Sea or electronic-UI feel:** None.

---

## 2. Stem Loop Deep Dive: Calm Layer, Switches, and Loop Seam

Running `stem_loop_check.py` reproduced Claude's exact numbers:
- Live stems in zip: `drums` (`-22.7 dB` RMS, `66.8%` in `40` to `120 Hz`, `24.3%` in `120` to `500 Hz`) and `other` (`-21.2 dB` RMS, `23.1%` in `40` to `120 Hz`, `51.7%` in `120` to `500 Hz`, `20.6%` in `500 Hz` to `2 kHz`, `4.5%` in `2` to `6 kHz`).
- Silent stems in zip: `bass` (`-102.0 dB`), `piano` (`-130.5 dB`), `guitar` (`-131.2 dB`), `vocals` (`-240.0 dB`).
- Stem alignment: stems lag the song by `1,203` samples (`25.1 ms`); after alignment they rebuild the song with a `-25.2 dB` residual.
- Calm (`other`) sits `4.0 dB` under intense (`song`), with `0.0%` below `40 Hz` and far less `40` to `120 Hz` load.

### 2.1 Does the Calm Layer Stand on Its Own as Music?

**Yes, with two mild caveats.**
- **What works:** Because the cellos/double basses drive a continuous rhythmic ostinato and the low brass + dark pad carry the motif and harmony in every bar, muting `drums` does not leave a hollow karaoke gap. Listening to `calm` alone for the full 40 seconds feels like a complete, tense orchestral battle underscore. Removing the war drums and anvil hits also opens up the `40` to `120 Hz` sub/punch zone (`22.8%` vs `44.5%`), giving early-battle weapon shots extra room to breathe.
- **Caveat 1 (energy contrast is "tense" vs "driving", not "quiet vigil" vs "war"):** Because `other` keeps the full driving string ostinato and full brass motif, `calm` already feels alert and combat-ready rather than hushed. That still reads clearly as a tactical step down from `intense` (`-4.0 dB` + no heavy drums/anvils), and fits a battle screen well, as long as nobody expects `mus_voidsworn_calm`'s whisper-quiet 0:00 vigil.
- **Caveat 2 (slight separator bleed in isolation):** Listening closely to `calm` alone on headphones, you can hear faint muted ghost thumps from the heaviest war-drum hits around 20 to 35 s, and `drums` took both the war drums and the sharp anvil hits with it. Under battle SFX this bleed is completely masked.

### 2.2 Calm-to-Intense and Intense-to-Calm Switches

Listened directly to 2-second linear crossfades at all four quarter-points (`4.9 s`, `14.8 s`, `24.7 s`, `34.6 s`), both `calm -> intense` and `intense -> calm`:
- **Verdict: Dead seamless in both directions at all four points.**
- On `calm -> intense`, the deep war drums and anvil strikes bloom cleanly up out of the existing string/brass groove with zero double-attack, zero phase hollowing, zero tempo wobble, and zero volume dip (measured deepest dip `0.00` to `0.14 dB`).
- On `intense -> calm`, the drums smoothly step back over 2 seconds and leave the string/brass ostinato rolling forward without feeling chopped off.
- **Small wiring note for Godot:** Today's `godot/music/music_player.gd` (line 381) keeps `calm` at `0.15` when `hot = 1.0` (`var calm := 1.0 - 0.85 * hot`). Since `intense` already contains `calm`, leaving `calm` at `0.15` adds `+1.2 dB` to the non-drum part at full intensity. When wiring stem loops (with `AudioStreamSynchronized` or paired players), either crossfade `calm = 1.0 - hot` cleanly, or keep `calm` at unity and fade only the `drums` stem from `0` to `1`.

### 2.3 Is the Loop Seam Audible with a 0.5 s Crossfade?

**Yes. Listening to the rendered wrap clips (`last 6 s -> seam -> first 6 s`) caught a real musical problem that the numeric script hid:**
- **With `--xfade 0.5` (`39.532 s`):** Both `intense` and `calm` have an **audible rhythmic stumble/skip right at the wrap**, and bar 1's opening downbeat sounds muted/swallowed. At `--xfade 1.0` (`39.032 s`), the meter jump is even worse.
- **Why this happens (verified by autocorrelation):** `mus_battle_sunward_stemloop_t1.mp3` actually generated an **exact 16-bar loop at `96.0 BPM`**:
  - Measured `1 beat = 0.63 s` (`0.625 s`), `1 bar = 2.50 s`, `2 bars = 5.00 s`, `4 bars = 10.00 s`, `8 bars = 19.99 s`, so 16 bars = **`40.00 s`** (raw file `40.032 s`).
  - Folding `0.5 s` of the tail onto the head (`y = x[:-k]; y[:k] = x[:k]*r + x[-k:]*(1-r)`) **deletes `0.50 s` (80% of one beat) out of the 16-bar musical cycle**, shortening it to `15.81 bars` (`39.532 s`), AND multiplies bar 1's downbeat hit at `0.07 s` by `0.14` (`-17 dB`), crushing the downbeat attack!
- **Why `--xfade 0.0` flagged `calm` as FAIL in `stem_loop_check.py`:** On the raw `40.032 s` file, bar 1 opens on a strong brass/string downbeat (`-14.0 dB` in `0.00` to `0.25 s`, `-15.2 dB` in the first `0.5 s`), while bar 16's last half-second settles to `-20.1 dB` right before the next downbeat. That `4.9 dB` step is a normal musical bar-1 accent (bar 1 itself drops `5.8 dB` from its first `0.5 s` to its second `0.5 s`), not a broken loop seam.
- **Verified fix by ear:** Rendering the same wrap at the raw `40.032 s` bar length with a **`30 ms` click guard** (just like today's `godot/music/music.json` `"20 ms click guard"`) lands right on the bar-1 downbeat with **zero rhythmic stumble and zero click**.

---

## 3. Verdict on the Wave M2 Plan: CHANGE

**Answer: CHANGE.** Do not stop (M1 proved ElevenLabs orchestral music + stem splitting is a huge upgrade over today's tracks), and do not run all 44 steps (~46,290 estimated credits, cap 52,000) unchanged. Make the four changes below first.

### Change 1: Fix the Loop Seam Rule and Bar-Duration Math Before Generating M2

1. **Stop folding `0.5 s` onto exact-bar loops.** When `music_v2` hits the requested bar count, use a `20` to `30 ms` click guard on the exact bar grid (trimming any ~30 ms MP3 padding to exact bar length). Only fold a `0.5 s` tail when you have generated extra overhang beyond the loop length (for example, prompting 25 bars and folding bar 25 onto bar 1 over an exact 24-bar loop). Update `stem_loop_check.py` to check bar-grid continuity and click-free sample joins rather than forcing a `0.5 s` fold that breaks the meter.
2. **Fix rounded `seconds` in `waves.M2`.** Eight of the 11 M2 battle loops (plus `mus_reward_2` and `mus_reward_3`) round their 24-bar duration to an integer second that misses the exact bar end by `0.21` to `0.47 s`:
   - `mus_hegemony_loop_b` (102 BPM, 24 bars = `56.47 s`, set to `56 s`, diff `-0.47 s`)
   - `mus_ithar_loop_a` (88 BPM, 24 bars = `65.45 s`, set to `65 s`, diff `-0.45 s`)
   - `mus_deathless_loop_a` (84 BPM, 24 bars = `68.57 s`, set to `69 s`, diff `+0.43 s`)
   - `mus_corsair_loop_a` (104 BPM, 24 bars = `55.38 s`, set to `55 s`, diff `-0.38 s`)
   - `mus_corsair_loop_b` (110 BPM, 24 bars = `52.36 s`, set to `52 s`, diff `-0.36 s`)
   - `mus_ithar_loop_b` (94 BPM, 24 bars = `61.28 s`, set to `61 s`, diff `-0.28 s`)
   - `mus_chorus_loop_b` (82 BPM, 24 bars = `70.24 s`, set to `70 s`, diff `-0.24 s`)
   - `mus_chorus_loop_a` (76 BPM, 24 bars = `75.79 s`, set to `76 s`, diff `+0.21 s`)
   - `mus_reward_2` (76 BPM, 16 bars = `50.53 s`, set to `51 s`, diff `+0.47 s`) and `mus_reward_3` (72 BPM, 16 bars = `53.33 s`, set to `53 s`, diff `-0.33 s`).
   - Either pass exact decimal seconds (since `elevenlabs_gen.js` converts `Math.round(it.seconds * 1000)`) or pick BPMs whose 24-bar length is an exact whole second (`72 BPM = 80 s`, `80 BPM = 72 s`, `90 BPM = 64 s`, `96 BPM = 60 s`, `120 BPM = 48 s`).

### Change 2: Test Stem-Splitting on Glasswrights and Chorus Before Running All 6 Factions

Because ElevenLabs' stem separator returns **only `drums` and `other`** on orchestral music (`bass`, `piano`, `guitar`, `vocals` are silent), "intense = full mix, calm = everything except drums" does **not** carry equal risk across all six factions:
- **Good fit (4 factions):**
  - **Sunward Crusade (`voidsworn`):** Proven in M1. War drums + anvil hits cleanly leave strings, brass, and organ pad intact.
  - **Meridian Directorate (`hegemony`):** Crisp marching snare, field drums, and timpani should separate cleanly from military brass and cold strings.
  - **Ashfall Hullbreakers (`corsair`):** Pounding war drums and scrap percussion should separate cleanly from rough low strings and low brass (just watch that `"blaring detuned low brass"` does not get tiring over 20 minutes).
  - **Eclipse (`deathless`):** Deep taiko percussion will separate cleanly from the held pedal note and low brass/strings once its prompt stops duplicating Sunward (see Change 4).
- **High risk (2 factions, test first):**
  - **The Glasswrights (`ithar`):** Prompts `"precise tuned crystalline percussion and light timpani"` alongside `"glass harmonica, celesta, harp"`. A pop/rock drum separator will likely either leave `drums` way too quiet (failing the `1.0 dB` minimum calm-to-intense gap) or rip sharp celesta/harp/glass plucks into `drums`, leaving the calm layer thin and artifacted.
  - **The Chorus (`chorus`):** Prompts `"deep frame drums beating like a vast heartbeat"` and `"col legno strings"`. Soft sub-bass frame drums often stay trapped in `other` instead of cleanly landing in `drums`, while woody string taps can bleed across both stems.
- **Recommended gate:** Run a small M1b test on **`mus_ithar_loop_a` and `mus_chorus_loop_a` with stems** (~4,200 credits total) before launching the full 44-step M2 run. If either fails clean drum separation, either strengthen its percussive layer slightly for the intense state or use a Godot-side calm mix (gentle low-pass + level drop + faction ambient bed) instead of paying for broken stem zips.

### Change 3: Fix the 120-Second Arc Trap and Boss/Nemesis Layering

1. **Shorten long loops from `96` to `120 s` down to `60` to `80 s`.** M1 proved `music_v2` obeys `"continuous loop, even energy"` at `40 s`, while **both** `101 s` tracks (`mus_voidsworn_calm` and `mus_voidsworn_hot`) ignored that exact wording and invented big ramps (`+19.8 dB`) and 5-second fade-outs to silence. All 6 map tracks (`mus_map_s1_1` through `mus_map_s3_2`), both boss tracks (`mus_boss_1`, `mus_boss_2`), `mus_nemesis` (`120 s` each), and `mus_shop` (`96 s`) carry that exact same failure risk. Plan section 9's note ("Their fades are trimmed to loop points in mastering") will not fix a track that whispers for the first 35 seconds and ends on a loud climax or finale cadence. Bringing those loops down to `60` to `80 s` (24 to 32 bars) also saves ~5,500 credits while dramatically improving loop compliance. Keep `mus_title` at `150 s` since it is meant to have a full arc.
2. **Stem-split (or isolate) `mus_boss_1`, `mus_boss_2`, and `mus_nemesis`.** Today's `godot/music/music_player.gd` (line 254) swaps only `hot_id` to the boss track while keeping the enemy faction's `calm` layer playing underneath. Mixing a `100` or `108 BPM` boss track in D/C minor over a `76`/`84`/`88 BPM` faction calm stem in B/C#/F# minor will clash badly during crossfades and at low intensity. Give boss and nemesis tracks their own stems (or play them solo without a mismatched faction calm bed).

### Change 4: Fix Specific Faction Clashes and Word Traps in `waves.M2`

- **Chorus (`mus_chorus_loop_a`, `mus_chorus_loop_b`):**
  - Remove `"eerie bowed metal and glass textures"`. Metal and glass are Sunward and Glasswright identities, not Chorus (`docs/playbooks/factions.md` explicitly bans metal on Chorus; plan section 4 specifies `"Unsettling low contrabassoon/reeds, organic slow pulsing sub-bass, eerie scraping bone-like string harmonics"`).
  - Remove `"a vast living tide rising"` in `mus_chorus_loop_a`: `"tide"` is a sea/ocean word and `"rising"` encourages a dynamic swell that breaks even loop energy.
  - Drop `"Cinematic and heavy"` and `"a driving low ostinato"` so Chorus stays unsettling, breathing, and organic rather than turning into another standard action ostinato.
- **Glasswrights (`mus_ithar_loop_a`, `mus_ithar_loop_b`):**
  - Replace `"Cinematic and heavy"` and `"a driving low ostinato"` with luminous, poised, glass-and-light phrasing. `"Heavy"` actively fights the Glasswrights' crystalline identity and risks muddying the glass harmonica, celesta, and harp under generic low brass.
- **Eclipse (`mus_deathless_loop_a`, `mus_deathless_loop_b`):**
  - Remove `"heavy anvil strikes like a machine"` and soften `"relentless low string ostinato"`. Right now Eclipse shares anvils, war drums/taiko, dark low brass, and a driving low string ostinato with Sunward Crusade, which will make the two factions sound too close. Keep anvils for Sunward's forge-iron identity, and steer Eclipse back toward plan section 4 (`"Glacial hollow sub-brass, sparse resonant obsidian chimes, tense wide pockets of dark silence"`) with the low held pedal note and measured deep taiko.
- **Shipyard / Shop (`mus_shop`):**
  - Replace `"working-dock"` with `"orbital refit bay"` or `"starship repair bay"` so `"dock"` + `"shipyard"` does not pull in maritime/harbor flavor.
- **Avoid one copy-pasted arrangement across all 6 factions:**
  - All 11 M2 battle loop prompts currently copy the identical sentence: `"four parts that all play in every bar... a driving low ostinato; a lead line carrying ... varied every four bars; and a sustained harmonic pad ... Cinematic and heavy."` Keep that structure for Sunward, Directorate, and Hullbreakers, where a driving ostinato fits; vary the arrangement wording for Chorus (slow breathing pulse), Glasswrights (poised shimmering arpeggios and clean light pulse), and Eclipse (sparse glacial pedal and heavy spaced hits) so the six factions actually sound distinct in combat.
