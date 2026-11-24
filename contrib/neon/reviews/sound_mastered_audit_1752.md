# Mastered Sound Keepers Audit (Issues 1752 and 1924)

Direct listening and acoustic audit of all 65 mastered Gate 2 game files (`m_<id>.ogg`) against their raw ElevenLabs picks (`r_<wave>_<id>_<take>.mp3`), today's game clips (`<id>_today0.ogg`), `master_report.json`, and both 32-weapon comparison reels (`reel_raw.mp3` and `reel_mastered.mp3`) from `rcbailey12/voidsworn-relay` branch `claude/project-thread-3riw5a` (`sound1752_mastered/`). Every raw/mastered pair and both reels were listened to directly, cross-checked against single-channel L/R and no-EQ test renders where needed, and measured for onset, trim head content, peak/50 ms/RMS loudness, stereo-to-mono drop, spectral balance, and loop-end fades.

## Bottom Line

- **Overall verdict: 60 of 65 files are ready for the game as they are; 5 files need a quick mastering tweak before shipping.**
- **Per-file scorecard (65 files):** 45 **Better**, 16 **Same**, 4 **Worse** (plus 1 **Better** file, `amb_bridge_bed`, held back for a loop-seam fade bug).
- **Weapon reels (`reel_raw.mp3` vs `reel_mastered.mp3`):** **Clear win.** The mastered reel is dramatically more even from gun to gun without sounding flat, crushed, or dull. Only two weapons in the mastered reel still stand out for the wrong reasons: `wep_directorate_laser` (too quiet because its presence EQ tripped the peak cap) and `wep_sunward_lance_beam` (hollowed out by folding a wide `0.18`-correlation take).
- **Do not ship as-is (5 files):**
  1. `death_ithar_shatter` (Worse): drop `"eq": "presence"` and switch to single channel `"src": "L"` (or `"R"`).
  2. `wep_directorate_laser` (Worse): drop `"eq": "presence"`.
  3. `wep_sunward_lance_beam` (Worse): change `"src": "fold"` to `"src": "R"` (or `"L"`).
  4. `shd_break_energy` (Worse): change from auto fold to `"src": "L"`.
  5. `amb_bridge_bed` (Better in level, broken loop seam): skip the 1 ms head fade-in and 15 ms tail fade-out on looping ambience.

---

## Weapon Reels Verdict (`reel_raw.mp3` vs `reel_mastered.mp3`)

- **`reel_raw.mp3`:** Wildly uneven. Loud kinetic blasts (`wep_sunward_hbattery`, `wep_flak_airburst`, `wep_craft_guns`, `wep_sunward_turret`, `wep_hullbreaker_scatter`) jump 6 to 9 dB over the middle of the pack, while quieter picks (`wep_ithar_needle`, `wep_eclipse_nlance`, `wep_mech_recoil_tail`, `wep_craft_bombs`) recede, and `wep_craft_bombs` leaves an obvious dead-air pause before releasing.
- **`reel_mastered.mp3`:** Much more even without turning flat, squashed, or dull. Because `master_keepers.py` uses linear gain with a `-1 dBFS` ceiling rather than heavy compression, transient snap, dynamics, and faction tone stay crisp and distinct while the wild +8/-8 dB volume swings disappear and `wep_craft_bombs` fires right on time.
- **Only two weak spots heard in the mastered reel:** `wep_sunward_lance_beam` sounds slightly hollow compared to its raw shimmer (caused by forcing `fold` on a `corr 0.18` stereo beam), and `wep_directorate_laser` dips slightly soft next to its neighbors (caused by its `+3 dB` presence shelf spiking into the `-1 dBFS` peak cap and locking it at `-14.8 dB`). Fixing those two makes the full weapon reel rock-solid.

---

## Final List: Files Not Ready As They Are (5 Files)

1. **`death_ithar_shatter`** (call: **Worse**)
   - **What is wrong:** `"eq": "presence"` (`+3 dB` above 2 kHz) boosted its sharp glass transient peak so much that the `-1 dBFS` peak cap forced `-1.7 dB` of attenuation, leaving it thin, poky, and quiet (`-14.1 dB` 50 ms loudness, `-24.9 dB` full-clip RMS, which is 3.1 dB below the `-11 dB` death target and 6 to 9 dB quieter in average RMS than the other six deaths). Folding at `corr 0.38` also thinned its shimmer.
   - **What to change:** Remove `"eq": "presence"` and set `"src": "L"` (or `"R"`). Verified by A/B listen: channel L with no EQ lifts it cleanly to `-12.1 dB` 50 ms loudness and `-22.6 dB` RMS (channel R reaches `-11.8 dB` / `-22.8 dB`) and restores full crystalline shatter weight right next to the other deaths.

2. **`wep_directorate_laser`** (call: **Worse**)
   - **What is wrong:** `"eq": "presence"` spiked its sharp attack transient by 2.6 dB, tripping the `-1 dBFS` peak cap early and starving the rest of the bolt to `-14.8 dB` 50 ms loudness (`-21.0 dB` RMS), making it the quietest weapon in the entire 33-file category and noticeably softer than its reel neighbors and today's clip (`-18.4 dB` RMS).
   - **What to change:** Remove `"eq": "presence"`. Verified by A/B listen: without EQ, gain rises from `+1.5 dB` to `+4.1 dB`, lifting 50 ms loudness to `-12.8 dB` and RMS to `-18.8 dB` (virtually matching today's `-18.4 dB` RMS) with a much punchier laser body and plenty of natural top snap.

3. **`wep_sunward_lance_beam`** (call: **Worse**)
   - **What is wrong:** `keepers_gate2.json` forces `"src": "fold"` on a wide stereo take (`corr 0.18`). Folding causes a `-2.3 dB` phase drop that audibly hollows out the beam shimmer and takes the edge off its sweeping punch compared to the raw pick.
   - **What to change:** Change `"src": "fold"` to `"src": "R"` (or `"L"`). Verified by A/B listen: single channel R (`42.2%` above 2 kHz, centroid `2624 Hz`, `-1.6 dBFS` peak, no limiting) and L (`41.6%` above 2 kHz, `2552 Hz`, `-1.9 dBFS`) both sound dramatically fuller and brighter than the fold and hit `-12.0 dB` cleanly.

4. **`shd_break_energy`** (call: **Worse**)
   - **What is wrong:** At `corr 0.33` (just above the `0.30` auto-switch cutoff), `master_keepers.py` folded it to mono, losing `-1.8 dB`, dulling its high-end electrical crackle (`31.2%` above 2 kHz down to `27.6%`, centroid `1897` down to `1701 Hz`), and hitting the peak cap at `-15.1 dB` (1.1 dB under the `-14 dB` shield target).
   - **What to change:** Set `"src": "L"`. Verified by A/B listen: single channel L preserves the full `31.6%` high-end shimmer (`1898 Hz` centroid) and lifts loudness `+0.9 dB` to `-14.3 dB` (`-19.9 dB` RMS), matching `shd_break_prismatic` (`-14.2 dB`) and `shd_hit_absorb` (`-14.0 dB`).

5. **`amb_bridge_bed`** (call: **Better** in loudness, **hold for loop seam**)
   - **What is wrong:** The `+10.6 dB` lift to `-26.0 dB` RMS is clean and noise-free, and stereo width is intact, but `master_keepers.py` unconditionally applies a 1 ms head fade-in from zero and a 15 ms tail fade-out to zero even on `notrim: true` ambience. Raw runs steadily edge to edge (`-37.8 dB` start, `-38.1 dB` middle, `-37.5 dB` end), while the mastered tail drops to `-47.3 dB` in the last 5 ms and hits silence, creating an audible 16 ms dip every time Godot loops the 20-second bed.
   - **What to change:** Skip the head and tail fades for `cat == "amb"` (or apply a short seamless loop crossfade instead of fading to zero).

---

## Special-Focus Mono Check (One-Channel Picks, Folded Lance, Eclipse Shear)

- **One-channel picks (all 5 worked well):**
  - `wep_eclipse_gsentry` (`src: L`, `corr 0.04`): **Win.** Completely avoids `-2.8 dB` mono cancellation and R-channel clipping, keeping the cold electrostatic obsidian crack sharp (`44.5%` above 2 kHz, centroid `4001 Hz`, `-12.1 dB`).
  - `imp_metal_light` (`src: L`, `corr 0.29`): **Win.** Keeps the immediate armored-steel clang and midrange body intact (`47.1%` above 2 kHz, centroid `2763 Hz`, `-14.0 dB`) with zero phase hollowing.
  - `wep_ithar_pulsar` (`src: L`, `corr 0.11`): **Win.** Avoids `-2.6 dB` fold loss and keeps the bright crystalline pulsar tone cleaner than R (`42.1%` above 2 kHz vs R's `33.8%`), sitting cleanly at `-12.0 dB`. Its 35.9 ms head trim removed only dead silence (`-45.3 dB` cut peak); the slow 87 ms climb afterward is the natural pulsar pre-swell rising smoothly from `-41.8 dB` at `t=0`.
  - `shd_break_prismatic` (`src: R`, `corr 0.15`): **Win.** Avoids `-2.4 dB` phase loss and keeps the shimmering prismatic glass shatter bright and even at `-14.0 dB`.
  - `dmg_engine_fail` (`src: R`, `corr 0.13`): **Win.** Right channel is clearly brighter and more readable than both L and the fold (`19.3%` above 2 kHz, centroid `1239 Hz`, vs L `11.4%` / `918 Hz` and fold `10.9%` / `822 Hz`), preserving the screeching turbine failure cleanly.
- **Forced-fold wide takes (1 failed, 1 passed):**
  - `wep_sunward_lance_beam` (`src: fold`, `corr 0.18`): **Failed.** Hollows out the beam shimmer compared to single channel R or L (see Final List above).
  - `death_eclipse_shear` (`src: fold`, `corr 0.02`): **Passed.** Uncorrelated stereo drops `-2.9 dB` evenly across every band without comb-filtering (`0.3%` above 2 kHz raw and mastered, centroid `268` vs `266 Hz`), and the `+3.2 dB` lift puts it right on the `-11.0 dB` death target with `-3.3 dBFS` peak headroom. Single channel L is also clean, so keeping the fold per plan 8.6 is completely fine.

---

## Minor Level Notes (Checked and Shippable As-Is)

These files stood out on the report numbers, were checked by ear against peers and `today0`, and do **not** need remastering:
- `wep_directorate_picket` (`limited`, `-14.0 dB` 50 ms, `-21.5 dB` RMS): 2.0 dB below `-12` on 50 ms peak because of its sharp bolt transient, but already `+1.6 dB` louder in RMS than today's `gunFlak` (`-23.1 dB`) and fits naturally as a light point-defense gun.
- `wep_directorate_ion_beam` (`limited`, `-13.6 dB` 50 ms, `-19.9 dB` RMS): sits right on the weapon median RMS (`-19.5 dB`) because it is a sustained 1.76 s beam.
- `wep_eclipse_doom_charge` (`-12.9 dB` 50 ms, `-15.7 dB` RMS) and `wep_eclipse_nlance` (`-12.0 dB` 50 ms, `-15.9 dB` RMS): sustained energy sounds with the highest average RMS among weapons; clean and menacing, and easy to trim 1 to 2 dB in Godot mix if they feel forward.
- `wep_mech_recoil_tail` (`-12.0 dB`) and `wep_layer_body_heavy` (`-12.0 dB`): both are clean additive weapon layers; make sure Godot mixes them underneath the primary weapon shot rather than at 0 dB on top of a `-12 dB` cannon.
- `ui_confirm_latch` (`limited`, `-20.7 dB` 50 ms, `-0.9 dBFS` peak): only looks low in a 50 ms RMS window because a sharp metallic click is far shorter than 50 ms; by ear it hits crisp and clear next to `ui_turn_start` and `ui_reward_vault`.
- `ui_boss_arrival` (`-10.3 dB` cut, `-16.0 dB` 50 ms, `-30.1 dB` RMS): huge cut from an overly loud raw file, landing right on today's `ui_boss_arrival_today0.ogg` (`-16.8 dB` 50 ms, `-29.1 dB` RMS).
- `death_directorate_blackout` (`-11.7 dB` 50 ms, `-15.5 dB` RMS) and `dmg_engine_fail` (`-14.0 dB` 50 ms, `-16.3 dB` RMS): sustained sounds with fuller average RMS than short transient peers, closely matching their `today0` RMS (`-16.6 dB` and `-15.5 dB`).

---

## Per-File Audit (All 65 Mastered Files)

Every file below was listened to raw vs mastered and checked on all four audit points: (1) call and why, (2) trim/attack, (3) mono/width, (4) category level.

### Weapons (33 files, target `-12 dB`)

1. **`wep_sunward_lance_beam`** (`A3 t1`, `fold`, `corr 0.18`, `+0.9 dB`, trim `5.9 ms`, `loud -12.0 dB`) -> **Worse.** Folding a wide `0.18`-correlation stereo beam hollows out the bright energy shimmer and softens its sweeping punch compared to the raw pick.
   - **Trim/Attack:** Clean (`5.9 ms` cut removed `-46.7 dB` dead head; attack untouched).
   - **Mono/Width:** Lost shimmer and punch that mattered; single channel R or L sounds noticeably fuller and sharper.
   - **Level:** Sits on `-12.0 dB` (`-20.3 dB` RMS), right in the weapon pack. (**Fix: use `"src": "R"` or `"L"`.**)

2. **`wep_directorate_laser`** (`A3 t1`, `fold`, `corr 0.96`, `eq: presence`, `+1.5 dB`, `limited`, trim `0.0 ms`, `loud -14.8 dB`) -> **Worse.** The `+3 dB` presence shelf spiked its sharp attack peak into the `-1 dBFS` ceiling early, starving the laser body by 2 to 3 dB compared to both raw balance and other weapons.
   - **Trim/Attack:** Clean (`0.0 ms` trim; immediate bolt snap).
   - **Mono/Width:** Pure mono fold (`corr 0.96`); zero loss.
   - **Level:** Gets lost slightly in the weapon reel (`-14.8 dB` 50 ms, `-21.0 dB` RMS, quietest weapon in the pool). (**Fix: drop `"eq": "presence"` to recover `+2.0 dB` body.**)

3. **`wep_ithar_shard`** (`A3 t1`, `fold`, `corr 0.82`, `+0.3 dB`, trim `7.0 ms`, `loud -12.0 dB`) -> **Same.** Preserves the crisp crystalline shard snap and bright tail almost identically to the raw pick at target loudness.
   - **Trim/Attack:** Clean (`7.0 ms` removed `-46.8 dB` dead head; no cut or gap).
   - **Mono/Width:** Holds up tightly (`corr 0.82`); sharp top ping stays intact.
   - **Level:** Sits right on `-12.0 dB` (`-19.6 dB` RMS).

4. **`wep_chorus_spines`** (`A3 t2`, `fold`, `corr 1.00`, `+2.2 dB`, trim `0.0 ms`, `loud -12.1 dB`) -> **Better.** The `+2.2 dB` lift gives the wet organic spine volley fuller bite and puts it right on par with the other primary weapons.
   - **Trim/Attack:** Clean (`0.0 ms` trim; starts immediately).
   - **Mono/Width:** Dual-mono (`corr 1.00`); zero loss.
   - **Level:** Sits squarely at `-12.1 dB` (`-20.8 dB` RMS).

5. **`wep_eclipse_gauss_fire`** (`A3 t2`, `fold`, `corr 0.45`, `eq: presence`, `-0.5 dB`, trim `0.0 ms`, `loud -12.0 dB`) -> **Better.** The `+3 dB` presence shelf sharpens the dark electromagnetic gauss crack over the slightly darker raw pick without losing punch.
   - **Trim/Attack:** Clean (`0.0 ms` trim; crisp instant onset).
   - **Mono/Width:** Folds cleanly (`corr 0.45`); crack and punch stay solid.
   - **Level:** Sits squarely at `-12.0 dB` (`-18.9 dB` RMS).

6. **`wep_sunward_autocannon`** (`B t1`, `fold`, `corr 0.87`, `-3.6 dB`, trim `0.0 ms`, `loud -12.1 dB`) -> **Better.** Taming `-3.6 dB` brings the hot raw ballistic crack cleanly into line with the weapon roster while keeping every bit of punch.
   - **Trim/Attack:** Clean (`0.0 ms` trim; immediate muzzle snap).
   - **Mono/Width:** Tight fold (`corr 0.87`); zero audible loss.
   - **Level:** Sits squarely at `-12.1 dB` (`-20.3 dB` RMS).

7. **`wep_sunward_torp_launch`** (`B t1`, `fold`, `corr 0.98`, `-1.1 dB`, trim `6.9 ms`, `loud -12.0 dB`) -> **Same.** Clean `-1.1 dB` trim keeps the torpedo tube thump and propellant whoosh faithful to the raw pick.
   - **Trim/Attack:** Clean (`6.9 ms` removed `-45.0 dB` dead head; smooth launch onset).
   - **Mono/Width:** Virtually mono (`corr 0.98`); zero loss.
   - **Level:** Sits squarely at `-12.0 dB` (`-18.9 dB` RMS).

8. **`wep_directorate_turbo`** (`B t2`, `fold`, `corr 0.89`, `+0.4 dB`, trim `0.0 ms`, `loud -12.0 dB`) -> **Same.** Preserves the punchy, tight Directorate turbolaser crack virtually unchanged from raw.
   - **Trim/Attack:** Clean (`0.0 ms` trim; immediate transient).
   - **Mono/Width:** Solid fold (`corr 0.89`); keeps crisp top end and snap.
   - **Level:** Sits squarely at `-12.0 dB` (`-17.7 dB` RMS).

9. **`wep_directorate_turbo_v2`** (`B t1`, `fold`, `corr 0.96`, `+0.1 dB`, trim `0.0 ms`, `loud -12.0 dB`) -> **Same.** Matches raw in punch and tone and pairs seamlessly with `wep_directorate_turbo`.
   - **Trim/Attack:** Clean (`0.0 ms` trim; instant onset).
   - **Mono/Width:** Tight fold (`corr 0.96`); zero loss.
   - **Level:** Sits squarely at `-12.0 dB` (`-18.1 dB` RMS).

10. **`wep_directorate_hturbo`** (`B t1`, `fold`, `corr 1.00`, `eq: presence`, `-1.4 dB`, trim `0.0 ms`, `loud -12.0 dB`) -> **Better.** The `+3 dB` presence shelf adds clean upper bite (`8.4%` to `13.2%` above 2 kHz) while `-1.4 dB` keeps the heavy turbolaser balanced.
    - **Trim/Attack:** Clean (`0.0 ms` trim; solid attack).
    - **Mono/Width:** Dual-mono (`corr 1.00`); zero loss.
    - **Level:** Sits squarely at `-12.0 dB` (`-18.9 dB` RMS).

11. **`wep_directorate_ion_beam`** (`B t1`, `fold`, `corr 0.40`, `-0.4 dB`, `limited`, trim `2.7 ms`, `loud -13.6 dB`) -> **Same.** Keeps the continuous crackling ion beam tone and steady energy intact with minimal change from raw.
    - **Trim/Attack:** Clean (`2.7 ms` removed `-38.5 dB` lead-in; smooth beam start).
    - **Mono/Width:** Acceptable fold (`corr 0.40`); loses a touch of stereo spread (`29.1%` to `28.0%` high), but beam bite holds up well.
    - **Level:** Peak-capped at `-13.6 dB` 50 ms, but its `-19.9 dB` sustained RMS sits right on the weapon median.

12. **`wep_ithar_needle`** (`B t1`, `fold`, `corr 1.00`, `hp 50`, `eq: presence`, `+5.2 dB`, trim `0.0 ms`, `loud -12.0 dB`) -> **Better.** Lifting `+5.2 dB` with the presence shelf rescues a quiet raw take into a crisp, sparkling glassy needle zap.
    - **Trim/Attack:** Clean (`0.0 ms` trim; sharp instant onset).
    - **Mono/Width:** Dual-mono (`corr 1.00`); zero loss.
    - **Level:** Sits squarely at `-12.0 dB` (`-20.0 dB` RMS).

13. **`wep_ithar_pulsar`** (`B t2`, `L`, `corr 0.11`, `+1.0 dB`, trim `35.9 ms`, `loud -12.0 dB`) -> **Better.** Extracting channel L avoids `-2.6 dB` mono cancellation and preserves the bright, shimmering crystalline pulsar sweep cleanly.
    - **Trim/Attack:** Clean (`35.9 ms` cut only `-45.3 dB` dead silence; the remaining `86.9 ms` climb to `-20 dB` is the natural smooth pre-swell rising from `-41.8 dB` at `t=0`).
    - **Mono/Width:** One-channel L pick worked well; brighter and cleaner than both R (`33.8%` hi) and fold (`-2.6 dB` drop).
    - **Level:** Sits squarely at `-12.0 dB` (`-19.4 dB` RMS).

14. **`wep_ithar_startorp`** (`B t2`, `fold`, `corr 0.85`, `+0.5 dB`, trim `7.7 ms`, `loud -12.0 dB`) -> **Better.** Stripping `25.0%` raw sub-40 Hz rumble tightens the crystalline torpedo sweep and lets its glassy shimmer read clearer than raw.
    - **Trim/Attack:** Clean (`7.7 ms` cut `-50.8 dB` dead silence; smooth sweep onset).
    - **Mono/Width:** Tight fold (`corr 0.85`); zero top-end loss.
    - **Level:** Sits squarely at `-12.0 dB` (`-18.9 dB` RMS).

15. **`wep_eclipse_gauss_charge`** (`B t2`, `fold`, `corr 0.62`, `-1.6 dB`, trim `25.0 ms`, `loud -12.0 dB`) -> **Same.** Removes 25 ms of dead lead-in and nudges level `-1.6 dB` while keeping the dark rising gauss whine intact.
    - **Trim/Attack:** Clean (`25.0 ms` cut `-50.9 dB` silence; charge ramps in promptly without clipping).
    - **Mono/Width:** Clean fold (`corr 0.62`); no audible tone loss.
    - **Level:** Sits squarely at `-12.0 dB` (`-16.5 dB` sustained RMS, fitting a rising charge).

16. **`wep_eclipse_nlance`** (`B t1`, `fold`, `corr 1.00`, `eq: presence`, `+4.0 dB`, trim `0.0 ms`, `loud -12.0 dB`) -> **Better.** The `+4.0 dB` lift brings this quiet, ominous dark beam up into the weapon mix without losing its deep low weight.
    - **Trim/Attack:** Clean (`0.0 ms` trim; immediate low-mid swell).
    - **Mono/Width:** Dual-mono (`corr 1.00`); zero loss.
    - **Level:** Hits `-12.0 dB` 50 ms with a full `-15.9 dB` sustained RMS (bold as a sustained lance, clean without clipping).

17. **`wep_hullbreaker_scatter`** (`B t2`, `fold`, `corr 0.51`, `-5.3 dB`, trim `0.0 ms`, `loud -12.0 dB`) -> **Better.** Pulling back `-5.3 dB` tames an overly loud raw blast cleanly into the weapon band while keeping all its gritty shrapnel snap.
    - **Trim/Attack:** Clean (`0.0 ms` trim; immediate blast).
    - **Mono/Width:** Clean fold (`corr 0.51`); high-end grit stays intact (`17.6%` to `17.7%`).
    - **Level:** Sits squarely at `-12.0 dB` (`-17.3 dB` RMS).

18. **`wep_hullbreaker_rockets`** (`B t2`, `fold`, `corr 0.90`, `+1.6 dB`, trim `4.9 ms`, `loud -12.0 dB`) -> **Better.** The `+1.6 dB` lift gives the rocket salvo launch fuller body and a cleaner immediate start.
    - **Trim/Attack:** Clean (`4.9 ms` removed `-41.1 dB` lead-in; full ignition whoosh preserved).
    - **Mono/Width:** Tight fold (`corr 0.90`); zero loss.
    - **Level:** Sits squarely at `-12.0 dB` (`-19.5 dB` RMS).

19. **`wep_flak_airburst`** (`B t1`, `fold`, `corr 0.92`, `-8.1 dB`, trim `0.0 ms`, `loud -12.0 dB`) -> **Better.** Cutting `-8.1 dB` pulls a huge loudness outlier straight into line with the weapon pack while preserving its crisp metallic burst crack.
    - **Trim/Attack:** Clean (`0.0 ms` trim; instant sharp burst).
    - **Mono/Width:** Tight fold (`corr 0.92`); zero loss.
    - **Level:** Sits squarely at `-12.0 dB` (`-19.6 dB` RMS).

20. **`wep_craft_guns`** (`B t2`, `fold`, `corr 0.91`, `-7.1 dB`, trim `0.0 ms`, `loud -12.0 dB`) -> **Better.** Cutting `-7.1 dB` stops this rapid fighter burst from blasting over heavy capital guns while keeping its crisp chatter.
    - **Trim/Attack:** Clean (`0.0 ms` trim; immediate first shot).
    - **Mono/Width:** Tight fold (`corr 0.91`); zero loss.
    - **Level:** Sits squarely at `-12.0 dB` (`-19.5 dB` RMS).

21. **`wep_mech_recoil_tail`** (`B t1`, `fold`, `corr 0.99`, `+4.8 dB`, trim `6.4 ms`, `loud -12.0 dB`) -> **Better.** The `+4.8 dB` lift brings the quiet mechanical bolt/recoil clack out clearly so it can actually be heard in a busy fight.
    - **Trim/Attack:** Clean (`6.4 ms` removed `-45.4 dB` dead head; click stays crisp).
    - **Mono/Width:** Nearly mono (`corr 0.99`); zero loss.
    - **Level:** Hits `-12.0 dB` (`-22.3 dB` RMS); clean on its own, though Godot should mix it below the main cannon shot as a layer.

22. **`wep_layer_body_heavy`** (`B t1`, `fold`, `corr 1.00`, `+1.0 dB`, trim `0.0 ms`, `loud -12.0 dB`) -> **Same.** Clean `+1.0 dB` nudge keeps the deep kinetic cannon thump tight, full, and well-controlled.
    - **Trim/Attack:** Clean (`0.0 ms` trim; immediate thump).
    - **Mono/Width:** Dual-mono (`corr 1.00`); zero loss.
    - **Level:** Hits `-12.0 dB` (`-18.2 dB` RMS, `-8.4 dBFS` peak); clean low-end body layer.

23. **`wep_sunward_turret`** (`C t2`, `fold`, `corr 1.00`, `-5.8 dB`, trim `0.0 ms`, `loud -12.0 dB`) -> **Better.** Pulling back `-5.8 dB` tames an overly loud raw shot cleanly into the weapon band while keeping its crisp metallic snap.
    - **Trim/Attack:** Clean (`0.0 ms` trim; instant crack).
    - **Mono/Width:** Dual-mono (`corr 1.00`); zero loss.
    - **Level:** Sits squarely at `-12.0 dB` (`-21.5 dB` RMS).

24. **`wep_sunward_hbattery`** (`C t2`, `fold`, `corr 1.00`, `-8.6 dB`, trim `0.0 ms`, `loud -12.0 dB`) -> **Better.** Pulling back `-8.6 dB` reins in the loudest raw blast in the entire pool so it hits hard at `-12 dB` without dwarfing every other gun.
    - **Trim/Attack:** Clean (`0.0 ms` trim; full heavy punch intact).
    - **Mono/Width:** Dual-mono (`corr 1.00`); zero loss.
    - **Level:** Sits squarely at `-12.0 dB` (`-19.1 dB` RMS).

25. **`wep_torp_eject`** (`C t1`, `fold`, `corr 0.64`, `+1.6 dB`, `limited`, trim `0.0 ms`, `loud -12.4 dB`) -> **Better.** The `+1.6 dB` lift brings the pressurized pneumatic tube hiss-thump right up to the weapon line without clipping.
    - **Trim/Attack:** Clean (`0.0 ms` trim; crisp instant release).
    - **Mono/Width:** Clean fold (`corr 0.64`); bright air hiss stays intact (`95.7%` to `95.3%` above 2 kHz).
    - **Level:** Sits right on target at `-12.4 dB` (`-17.4 dB` RMS).

26. **`wep_chorus_spore_cloud`** (`C t2`, `fold`, `corr 0.89`, `-2.8 dB`, trim `0.0 ms`, `loud -12.0 dB`) -> **Better.** Taming `-2.8 dB` balances the wet organic burst-hiss neatly alongside other weapons with zero clipping.
    - **Trim/Attack:** Clean (`0.0 ms` trim; organic burst hits immediately).
    - **Mono/Width:** Tight fold (`corr 0.89`); keeps its textured wet spray intact.
    - **Level:** Sits squarely at `-12.0 dB` (`-21.4 dB` RMS).

27. **`wep_chorus_sporeb`** (`C t1`, `fold`, `corr 0.95`, `-1.5 dB`, trim `0.0 ms`, `loud -12.0 dB`) -> **Same.** Clean `-1.5 dB` trim preserves the snappy organic spore pop cleanly at target loudness.
    - **Trim/Attack:** Clean (`0.0 ms` trim; instant pop).
    - **Mono/Width:** Tight fold (`corr 0.95`); zero loss.
    - **Level:** Sits squarely at `-12.0 dB` (`-21.1 dB` RMS).

28. **`wep_eclipse_doom`** (`C t2`, `fold`, `corr 0.93`, `0.0 dB`, `limited`, trim `6.3 ms`, `loud -12.9 dB`) -> **Same.** Almost identical to the raw superweapon roar (`0.0 dB` gain), keeping its massive tearing beam discharge fully intact.
    - **Trim/Attack:** Clean (`6.3 ms` removed `-43.0 dB` dead head; full blast onset preserved).
    - **Mono/Width:** Tight fold (`corr 0.93`); keeps bright crackling sheen (`61.7%` to `60.6%` above 2 kHz).
    - **Level:** Peak-capped at `-12.9 dB` 50 ms (`-18.5 dB` RMS); sounds huge and well-proportioned.

29. **`wep_eclipse_doom_charge`** (`C t1`, `fold`, `corr 0.48`, `eq: air`, `-0.7 dB`, `limited`, trim `32.9 ms`, `loud -12.9 dB`) -> **Same.** Removes 32.9 ms of quiet lead-in and keeps the menacing swirling superweapon charge full and immediate.
    - **Trim/Attack:** Clean (`32.9 ms` removed `-41.4 dB` dead head; charge swells cleanly without clipping).
    - **Mono/Width:** Slight high-end drop in fold (`30.6%` to `26.0%` above 2 kHz despite `+2 dB` air shelf), but still reads gritty and intense by ear.
    - **Level:** Peak-capped at `-12.9 dB` 50 ms with `-15.7 dB` sustained RMS; plenty loud in the category.

30. **`wep_craft_bombs`** (`C t2`, `fold`, `corr 0.95`, `+3.5 dB`, `limited`, trim `131.9 ms`, `loud -12.3 dB`) -> **Better.** Cutting 131.9 ms of dead digital silence (`-137` to `-75 dBFS`) fixes an obvious raw lag and `+3.5 dB` brings the crisp bomb-release hiss right into the weapon band.
    - **Trim/Attack:** Big win (`131.9 ms` cut pure silence with `-47.5 dB` peak; attack lands cleanly at `t=0`).
    - **Mono/Width:** Tight fold (`corr 0.95`); top-end hiss stays pristine (`93.1%` to `93.4%` above 2 kHz).
    - **Level:** Sits right on target at `-12.3 dB` (`-20.2 dB` RMS).

31. **`wep_hullbreaker_junk_gun`** (`D t2`, `fold`, `corr 0.66`, `-1.3 dB`, trim `0.0 ms`, `loud -12.0 dB`) -> **Better.** Removing `23.7%` raw sub-40 Hz rumble tightens the gritty scrap-metal cannon blast so the metallic clatter reads crisper than raw.
    - **Trim/Attack:** Clean (`0.0 ms` trim; immediate metallic slam).
    - **Mono/Width:** Clean fold (`corr 0.66`); top metallic grit jumps cleanly (`38.9%` to `50.9%` after sub-40 cleanup).
    - **Level:** Sits squarely at `-12.0 dB` (`-19.3 dB` RMS).

32. **`wep_directorate_picket`** (`E t1`, `fold`, `corr 0.84`, `+1.5 dB`, `limited`, trim `24.0 ms`, `loud -14.0 dB`) -> **Better.** The fixed 24 ms trim removes the quiet lead-in right up to the bolt crack so the point-defense laser fires snappily on `t=0`.
    - **Trim/Attack:** Clean (`24.0 ms` removed quiet lead-in; `m_on20 = 1.5 ms`, bolt snap untouched).
    - **Mono/Width:** Clean fold (`corr 0.84`); bright electric crack stays crisp.
    - **Level:** Peak-capped at `-14.0 dB` 50 ms (`-21.5 dB` RMS), 2 dB lighter than heavy cannons yet `+1.6 dB` louder in RMS than today's `gunFlak` (`-23.1 dB`), which fits a light picket gun.

33. **`wep_eclipse_gsentry`** (`D t2`, `L`, `corr 0.04`, `+0.5 dB`, `limited`, trim `0.0 ms`, `loud -12.1 dB`) -> **Better.** Extracting channel L avoids severe `corr 0.04` phase cancellation and R-channel clipping, keeping the cold obsidian crack razor-sharp and loud.
    - **Trim/Attack:** Clean (`0.0 ms` trim; instant cold crack).
    - **Mono/Width:** One-channel L pick worked great (`44.5%` above 2 kHz, centroid `4001 Hz`, zero hollowing).
    - **Level:** Sits right on target at `-12.1 dB` (`-20.3 dB` RMS).

---

### Impacts (10 files, target `-14 dB`)

34. **`imp_metal_heavy`** (`A2 t1`, `fold`, `corr 0.57`, `-1.4 dB`, trim `5.4 ms`, `loud -14.0 dB`) -> **Same.** Clean `-1.4 dB` adjustment keeps the heavy armored hull crunch and metallic ring faithful to raw.
    - **Trim/Attack:** Clean (`5.4 ms` removed `-47.3 dB` dead head; crunch starts cleanly).
    - **Mono/Width:** Solid fold (`corr 0.57`); steel bite and punch stay intact.
    - **Level:** Sits squarely at `-14.0 dB` (`-22.1 dB` RMS).

35. **`imp_metal_heavy_v2`** (`A2 t2`, `fold`, `corr 0.51`, `-1.9 dB`, trim `0.6 ms`, `loud -14.0 dB`) -> **Same.** Clean `-1.9 dB` trim matches `imp_metal_heavy` smoothly with the same solid steel crunch.
    - **Trim/Attack:** Clean (`0.6 ms` trim; immediate hit).
    - **Mono/Width:** Clean fold (`corr 0.51`); slight high softening (`13.9%` to `10.8%`), still punchy and solid by ear.
    - **Level:** Sits squarely at `-14.0 dB` (`-22.7 dB` RMS).

36. **`imp_bio_flesh`** (`A2 t1`, `fold`, `corr 0.98`, `hp 65`, `eq: bio`, `+5.4 dB`, `limited`, trim `0.0 ms`, `loud -14.1 dB`) -> **Better.** The `bio` EQ plus `+5.4 dB` turns a muddy raw thump into a crisp, wet organic smack that actually cuts through battle audio (`2.1%` to `13.4%` above 2 kHz).
    - **Trim/Attack:** Clean (`0.0 ms` trim; instant wet impact).
    - **Mono/Width:** Virtually mono (`corr 0.98`); zero loss.
    - **Level:** Sits right on target at `-14.1 dB` (`-23.9 dB` RMS).

37. **`imp_bio_flesh_v2`** (`A2 t2`, `fold`, `corr 0.85`, `hp 65`, `eq: bio`, `+5.0 dB`, trim `0.0 ms`, `loud -14.1 dB`) -> **Better.** Same `bio` EQ and `+5.0 dB` lift rescues the raw thump into a clear, punchy wet organic hit right beside `imp_bio_flesh`.
    - **Trim/Attack:** Clean (`0.0 ms` trim; instant wet impact).
    - **Mono/Width:** Clean fold (`corr 0.85`); zero loss.
    - **Level:** Sits right on target at `-14.1 dB` (`-24.6 dB` RMS).

38. **`imp_glass_armor`** (`B t1`, `fold`, `corr 1.00`, `eq: presence`, `+7.4 dB`, trim `0.0 ms`, `loud -14.0 dB`) -> **Better.** Lifting `+7.4 dB` with the presence shelf brings a very quiet, distant raw clip up into a vivid, crisp crystalline armor hit.
    - **Trim/Attack:** Clean (`0.0 ms` trim; immediate crystalline hit).
    - **Mono/Width:** Dual-mono (`corr 1.00`); zero loss.
    - **Level:** Sits squarely at `-14.0 dB` (`-22.6 dB` RMS).

39. **`imp_obsidian_eclipse`** (`C t1`, `fold`, `corr 0.97`, `-3.6 dB`, trim `0.0 ms`, `loud -14.0 dB`) -> **Better.** Pulling back `-3.6 dB` tames an overly loud raw strike cleanly into the impact band while preserving its sharp obsidian crack.
    - **Trim/Attack:** Clean (`0.0 ms` trim; sharp instant hit).
    - **Mono/Width:** Virtually mono (`corr 0.97`); zero loss.
    - **Level:** Sits squarely at `-14.0 dB` (`-23.2 dB` RMS).

40. **`imp_acid_on_metal`** (`C t1`, `fold`, `corr 0.75`, `-1.8 dB`, trim `2.0 ms`, `loud -14.0 dB`) -> **Same.** Clean `-1.8 dB` trim preserves the sharp sizzling acid-on-hull hiss cleanly at target loudness.
    - **Trim/Attack:** Clean (`2.0 ms` removed `-48.1 dB` dead head; sizzle starts right on time).
    - **Mono/Width:** Clean fold (`corr 0.75`); bright sizzle stays intact (`82.4%` to `83.2%` above 2 kHz).
    - **Level:** Sits squarely at `-14.0 dB` (`-25.5 dB` RMS, normal for a decaying hiss).

41. **`imp_energy_sear`** (`D t1`, `fold`, `corr 0.71`, `eq: presence`, `-0.8 dB`, trim `0.0 ms`, `loud -14.0 dB`) -> **Better.** The `+3 dB` presence shelf sharpens the sizzling energy-burn bite while `-0.8 dB` keeps it balanced.
    - **Trim/Attack:** Clean (`0.0 ms` trim; immediate sear).
    - **Mono/Width:** Clean fold (`corr 0.71`); zero audible loss.
    - **Level:** Sits squarely at `-14.0 dB` (`-22.1 dB` RMS).

42. **`imp_las`** (`D t1`, `fold`, `corr 0.96`, `+9.5 dB`, trim `0.0 ms`, `loud -14.0 dB`) -> **Better.** Huge rescue: `+9.5 dB` lifts a whisper-quiet raw take cleanly into a crisp, snappy laser-impact zap with zero clipping or noise trouble.
    - **Trim/Attack:** Clean (`0.0 ms` trim; instant zap).
    - **Mono/Width:** Tight fold (`corr 0.96`); zero loss.
    - **Level:** Sits squarely at `-14.0 dB` (`-21.6 dB` RMS, `-2.4 dBFS` peak).

43. **`imp_metal_light`** (`D t1`, `L`, `corr 0.29`, `-2.2 dB`, trim `0.0 ms`, `loud -14.0 dB`) -> **Better.** Extracting channel L avoids mono midrange loss while `-2.2 dB` puts the crisp armored-steel clang squarely in line with the other impacts.
    - **Trim/Attack:** Clean (`0.0 ms` trim; immediate metallic clang).
    - **Mono/Width:** One-channel L pick worked great (`47.1%` above 2 kHz, centroid `2763 Hz`, full steel midrange intact).
    - **Level:** Sits squarely at `-14.0 dB` (`-21.9 dB` RMS).

---

### Shields (3 files, target `-14 dB`)

44. **`shd_break_energy`** (`A3 t1`, `fold`, `corr 0.33`, `+2.9 dB`, `limited`, trim `9.1 ms`, `loud -15.1 dB`) -> **Worse.** Folding just above the `0.30` auto cutoff dulls the bright electrical shield collapse and leaves it 1.1 dB under target against the other shield cues.
    - **Trim/Attack:** Clean (`9.1 ms` removed `-43.6 dB` dead head; no attack cut).
    - **Mono/Width:** Lost top-end shimmer (`31.2%` down to `27.6%`, centroid `1897` to `1701 Hz`, `-1.8 dB` fold loss); channel L sounds clearly crisper.
    - **Level:** Peak-capped at `-15.1 dB` (`-20.9 dB` RMS), slightly softer than `shd_break_prismatic` and `shd_hit_absorb`. (**Fix: set `"src": "L"`.**)

45. **`shd_break_prismatic`** (`B t1`, `R`, `corr 0.15`, `-1.7 dB`, trim `4.1 ms`, `loud -14.0 dB`) -> **Better.** Extracting channel R avoids `-2.4 dB` phase loss and keeps the bright crystalline prismatic shield shatter sparkling cleanly at `-14 dB`.
    - **Trim/Attack:** Clean (`4.1 ms` removed `-41.6 dB` dead head; immediate shatter).
    - **Mono/Width:** One-channel R pick worked great (`63.6%` above 2 kHz, centroid `3158 Hz`, crisp and unhollowed).
    - **Level:** Sits squarely at `-14.0 dB` (`-21.9 dB` RMS).

46. **`shd_hit_absorb`** (`B t1`, `fold`, `corr 0.96`, `+1.8 dB`, trim `0.0 ms`, `loud -14.0 dB`) -> **Better.** The `+1.8 dB` lift gives the deep resonant shield-absorb hum clearer weight so it reads cleanly in combat.
    - **Trim/Attack:** Clean (`0.0 ms` trim; smooth immediate hum).
    - **Mono/Width:** Tight fold (`corr 0.96`); zero loss.
    - **Level:** Sits squarely at `-14.0 dB` (`-20.0 dB` RMS).

---

### Damage (5 files, target `-14 dB`)

47. **`dmg_turret_knockout`** (`B t2`, `fold`, `corr 0.92`, `-5.2 dB`, trim `0.0 ms`, `loud -14.0 dB`) -> **Better.** Cutting `-5.2 dB` brings an overly loud raw pop-and-spark cleanly into the damage tier without losing crispness.
    - **Trim/Attack:** Clean (`0.0 ms` trim; instant mechanical pop).
    - **Mono/Width:** Tight fold (`corr 0.92`); zero loss.
    - **Level:** Sits squarely at `-14.0 dB` (`-21.2 dB` RMS).

48. **`dmg_engine_fail`** (`B t2`, `R`, `corr 0.13`, `-1.1 dB`, trim `2.7 ms`, `loud -14.0 dB`) -> **Better.** Picking channel R preserves the bright turbine failure screech that gets dulled badly in both channel L and a mono fold.
    - **Trim/Attack:** Clean (`2.7 ms` removed `-46.2 dB` dead head; immediate wind-down).
    - **Mono/Width:** One-channel R pick worked great (`19.3%` above 2 kHz, centroid `1239 Hz` vs fold's `10.9%` / `822 Hz`).
    - **Level:** Sits at `-14.0 dB` 50 ms (`-16.3 dB` sustained RMS, fuller than transient damage cues yet matching today's `-15.5 dB` RMS).

49. **`dmg_breach_shear_metal`** (`C t1`, `fold`, `corr 0.58`, `+0.1 dB`, trim `8.5 ms`, `loud -14.0 dB`) -> **Better.** Stripping `32.5%` raw sub-40 Hz mud cleans up the harsh metal-tearing hull breach so its midrange screech reads clearer than raw.
    - **Trim/Attack:** Clean (`8.5 ms` removed `-47.0 dB` dead head; tear enters cleanly).
    - **Mono/Width:** Clean fold (`corr 0.58`); metallic bite stays sharp (`12.2%` to `17.4%` above 2 kHz after sub-40 cleanup).
    - **Level:** Sits squarely at `-14.0 dB` (`-19.6 dB` RMS).

50. **`dmg_breach_vent`** (`C t1`, `fold`, `corr 0.39`, `+1.6 dB`, trim `4.2 ms`, `loud -14.0 dB`) -> **Better.** The `+1.6 dB` lift puts the sharp depressurization hiss right at `-14 dB` while preserving its airy top end.
    - **Trim/Attack:** Clean (`4.2 ms` removed `-52.7 dB` dead head; instant hiss).
    - **Mono/Width:** Holds up well (`corr 0.39`; `82.9%` to `81.4%` above 2 kHz, no audible hollowing).
    - **Level:** Sits squarely at `-14.0 dB` (`-21.9 dB` RMS).

51. **`dmg_shield_burnout`** (`D t1`, `fold`, `corr 0.61`, `eq: air`, `-0.6 dB`, trim `0.0 ms`, `loud -14.0 dB`) -> **Same.** Clean `-0.6 dB` and light air shelf preserve the sizzling electrical shield collapse virtually unchanged from raw.
    - **Trim/Attack:** Clean (`0.0 ms` trim; immediate fizzle).
    - **Mono/Width:** Clean fold (`corr 0.61`); top end holds steady (`21.2%` to `21.4%` above 2 kHz).
    - **Level:** Sits squarely at `-14.0 dB` (`-20.6 dB` RMS).

---

### Deaths (7 files, target `-11 dB`)

52. **`death_chorus_rupture`** (`A2 t2`, `fold`, `corr 0.93`, `+5.3 dB`, `limited`, trim `0.0 ms`, `loud -11.8 dB`) -> **Better.** Lifting `+5.3 dB` gives the wet organic hull rupture real ship-death weight without clipping or distorting.
    - **Trim/Attack:** Clean (`0.0 ms` trim; full tearing onset intact).
    - **Mono/Width:** Tight fold (`corr 0.93`); zero loss.
    - **Level:** Peak-capped just under target at `-11.8 dB` (`-19.9 dB` RMS); sits cleanly with the death group.

53. **`death_metal_break`** (`B t1`, `fold`, `corr 0.65`, `0.0 dB`, trim `0.0 ms`, `loud -11.0 dB`) -> **Same.** Virtually identical to raw (`0.0 dB` gain), keeping the massive metallic snap and wreckage crunch strong at `-11 dB`.
    - **Trim/Attack:** Clean (`0.0 ms` trim; full heavy break intact).
    - **Mono/Width:** Solid fold (`corr 0.65`); punch and metallic grit hold up well.
    - **Level:** Sits squarely at `-11.0 dB` (`-18.6 dB` RMS).

54. **`death_hullbreaker_snap`** (`B t2`, `fold`, `corr 0.75`, `+8.0 dB`, trim `0.0 ms`, `loud -11.0 dB`) -> **Better.** The `+8.0 dB` lift rescues a quiet raw take into a brutal, authoritative metallic snap right on the `-11 dB` death target.
    - **Trim/Attack:** Clean (`0.0 ms` trim; immediate snap).
    - **Mono/Width:** Clean fold (`corr 0.75`); punch and top end stay intact.
    - **Level:** Sits squarely at `-11.0 dB` (`-20.8 dB` RMS, `-1.4 dBFS` peak).

55. **`death_directorate_blackout`** (`B t1+t2`, `fold`, `corr 0.85`, `+5.9 dB`, `limited`, trim `0.0 ms`, `loud -11.7 dB`) -> **Better.** Layering `t1` and `t2` with a `+5.9 dB` lift creates a huge, cohesive reactor blackout and power collapse that beats either raw take alone.
    - **Trim/Attack:** Clean (`0.0 ms` trim; both layers align cleanly at `t=0`).
    - **Mono/Width:** Tight fold (`corr 0.85`); zero audible loss.
    - **Level:** Hits `-11.7 dB` 50 ms (`-15.5 dB` sustained RMS, the fullest death in the set yet close to today's `-16.6 dB` RMS).

56. **`death_ithar_shatter`** (`C t2`, `fold`, `corr 0.38`, `eq: presence`, `-1.7 dB`, `limited`, trim `0.0 ms`, `loud -14.1 dB`) -> **Worse.** The presence shelf spiked its sharp glass peak into the `-1 dBFS` ceiling, forcing `-1.7 dB` attenuation that makes it thinner and far quieter than raw and every other death sound.
    - **Trim/Attack:** Clean (`0.0 ms` trim; no cut or gap).
    - **Mono/Width:** Folding at `corr 0.38` plus the presence shelf thins the shatter body (`38.1%` to `54.7%` above 2 kHz, `-24.9 dB` RMS).
    - **Level:** Gets lost in the death category (`-14.1 dB` 50 ms, `-24.9 dB` RMS, 3.1 dB under target and 6 to 9 dB below the other deaths in RMS). (**Fix: drop `"eq": "presence"` and set `"src": "L"` or `"R"`.**)

57. **`death_sunward_magazine`** (`C t2`, `fold`, `corr 0.77`, `+1.3 dB`, `limited`, trim `0.0 ms`, `loud -11.4 dB`) -> **Better.** The `+1.3 dB` nudge gives the heavy magazine cook-off explosion fuller authority right near `-11 dB`.
    - **Trim/Attack:** Clean (`0.0 ms` trim; immediate detonation).
    - **Mono/Width:** Solid fold (`corr 0.77`); punch and debris crackle hold up well.
    - **Level:** Sits right near target at `-11.4 dB` (`-21.0 dB` RMS).

58. **`death_eclipse_shear`** (`E t2`, `fold`, `corr 0.02`, `+3.2 dB`, trim `9.0 ms`, `loud -11.0 dB`) -> **Better.** Folding with a `+3.2 dB` lift cleanly offsets its uniform `-2.9 dB` uncorrelated stereo drop and removes 9 ms of dead head without altering the dark metallic grind.
    - **Trim/Attack:** Clean (`9.0 ms` removed `-44.0 dB` dead head; metallic grind enters cleanly).
    - **Mono/Width:** Holds up surprisingly well for `corr 0.02`; zero comb-filtering or tone shift (`268` vs `266 Hz` centroid), verified against channel L.
    - **Level:** Sits squarely at `-11.0 dB` (`-18.1 dB` RMS, `-3.3 dBFS` peak).

---

### Events (2 files, target `-14 dB`)

59. **`evt_pass_by_slug`** (`C t2`, `fold`, `corr 0.92`, `eq: presence`, `-3.5 dB`, trim `0.0 ms`, `loud -14.0 dB`) -> **Better.** Pulling back `-3.5 dB` tames a hot raw flyby while the `+3 dB` presence shelf sharpens its zippy doppler air-tear.
    - **Trim/Attack:** Clean (`0.0 ms` trim; immediate whoosh).
    - **Mono/Width:** Tight fold (`corr 0.92`); zero loss.
    - **Level:** Sits squarely at `-14.0 dB` (`-20.2 dB` RMS).

60. **`evt_fleet_warp_in`** (`C t2`, `fold`, `corr 0.99`, `eq: mid`, `-4.7 dB`, trim `0.0 ms`, `loud -14.0 dB`) -> **Better.** Cutting `-4.7 dB` tames an overly loud raw boom while the `+4 dB` midrange boost at 1.2 kHz helps the warp-in swoop read clearly on normal speakers.
    - **Trim/Attack:** Clean (`0.0 ms` trim; full warp swell preserved).
    - **Mono/Width:** Nearly mono (`corr 0.99`); zero loss.
    - **Level:** Sits squarely at `-14.0 dB` (`-19.3 dB` RMS).

---

### UI (4 files, stereo kept, target `-16 dB`)

61. **`ui_reward_vault`** (`A2 t1`, `stereo`, `corr 0.29`, `-50 cents`, `+7.0 dB`, trim `4.6 ms`, `loud -16.0 dB`) -> **Better.** Lifting `+7.0 dB` rescues a quiet raw chime and the `-50 cents` pitch drop makes the reward vault swell feel warmer and richer while keeping full stereo width.
    - **Trim/Attack:** Clean (`4.6 ms` removed `-48.5 dB` dead head; chime blooms cleanly).
    - **Mono/Width:** Kept stereo (`src: stereo`); rich spatial shimmer preserved.
    - **Level:** Sits squarely at `-16.0 dB` (`-19.5 dB` RMS).

62. **`ui_boss_arrival`** (`B t1`, `stereo`, `corr 0.63`, `-10.3 dB`, trim `5.0 ms`, `loud -16.0 dB`) -> **Better.** Pulling back `-10.3 dB` tames a massively over-loud raw bass boom so it sits right where today's boss stinger sits (`-16.0 dB` vs today's `-16.8 dB`, `-30.1 dB` vs `-29.1 dB` RMS) without overwhelming the UI.
    - **Trim/Attack:** Clean (`5.0 ms` removed `-48.2 dB` dead head; heavy boom hits cleanly).
    - **Mono/Width:** Kept stereo (`src: stereo`); full stereo presence preserved.
    - **Level:** Sits cleanly at `-16.0 dB` 50 ms alongside the other UI cues.

63. **`ui_confirm_latch`** (`B t1`, `stereo`, `corr 0.96`, `-0.1 dB`, `limited`, trim `15.4 ms`, `loud -20.7 dB`) -> **Same.** Trims 15.4 ms of dead lead-in and preserves the crisp metallic double-click latch cleanly in stereo.
    - **Trim/Attack:** Clean (`15.4 ms` removed `-40.3 dB` silence; initial click stays sharp).
    - **Mono/Width:** Kept stereo (`src: stereo`); clean and tight.
    - **Level:** Reports `-20.7 dB` 50 ms only because the click is much shorter than 50 ms (`-0.9 dBFS` peak); by ear it reads crisp and properly proportioned for a UI latch.

64. **`ui_turn_start`** (`B t2`, `stereo`, `corr 1.00`, `+4.8 dB`, trim `0.0 ms`, `loud -16.0 dB`) -> **Better.** Lifting `+4.8 dB` brings the quiet raw chime up to a clear, warm UI cue right beside `ui_reward_vault`.
    - **Trim/Attack:** Clean (`0.0 ms` trim; clean warm onset).
    - **Mono/Width:** Kept stereo (`src: stereo`); clean and steady.
    - **Level:** Sits squarely at `-16.0 dB` (`-23.6 dB` RMS).

---

### Ambience (1 file, stereo kept, target `-26 dB` full-clip RMS)

65. **`amb_bridge_bed`** (`C t1`, `stereo`, `corr 0.96`, `notrim`, `+10.6 dB`, trim `0.0 ms`, `RMS -26.0 dB`, `loud -21.8 dB`) -> **Better** in loudness, **do not ship as-is** until the loop-end fades are removed. The `+10.6 dB` lift rescues a faint `-36.6 dB` hum up to a clean, steady `-26.0 dB` stereo bridge bed without harsh hiss, but the script's 1 ms fade-in and 15 ms fade-out to zero put an audible dip into the loop seam.
    - **Trim/Attack:** `notrim` respected (`0.0 ms` trim), **but** unconditional 1 ms head / 15 ms tail fades drop the last 5 ms to `-47.3 dB` (vs `-27.4 dB` body) and zero at both edges.
    - **Mono/Width:** Kept stereo (`src: stereo`); steady, clean hum with zero noise-floor artifacts (`-14.4 dBFS` peak).
    - **Level:** Sits cleanly at `-26.0 dB` RMS (well under `-16` UI and `-12`/`-14` combat beds). (**Fix: skip head/tail fades on `amb` or apply a seamless loop crossfade.**)
