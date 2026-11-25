# Wave F2 and M2 Two-Track Test Sound Ear Audit (Issues 1752 and 2056)

Direct listening, mono fold-down, and stem-separation audit of all **32 Wave F2 ElevenLabs SFX takes** (16 sound ids) plus both **Wave M2_test music tracks and stem zips** (`mus_ithar_loop_a` and `mus_chorus_loop_a`) from relay `pc-out-opus1752wavef2` (`opus1752wavef2/out_20261124_184021_28349/out_new/elevenlabs/`), totaling **34 takes across 18 sound ids**. Every take was listened to directly alongside its current game baseline (`listen/audio/*_today*.ogg`, mastered Gate 2 keepers in `godot/audio/clips/`, and today's `godot/music/tracks/fac_ithar.ogg` and `fac_chorus.ogg`), compared against the rejected Wave F takes on Ryan's 7 rejects, and measured with a Python and ffmpeg FFT pass (44.1 kHz SFX / 48 kHz music, power-weighted bands, magnitude and power-weighted spectral centroids, median pitch centre, stereo-to-mono fold loss in dB, L/R channel splits, onset timing, peak, T95, envelope windows, 40 Hz HP checks on v2 guns, loop seam wraps, and `stem_loop_check.py`). All single-channel rescues, 40 Hz HP v2 renders, loop wraps, and M2_test calm/drums/wrap/switch renders were verified by ear.

Ryan's picks override ours; this audit is advice for his listen and the Board's listening page.

## Bottom Line (Read Before Listening)

- **Per-take scorecard: 17 keeps, 17 rejects** across 34 takes (17 keeps / 15 rejects across 32 Wave F2 takes; 0 keeps / 2 rejects across 2 M2_test music tracks).
- **Final answer breakdown across the 16 Wave F2 SFX ids:** **13 of 16 ship without re-rolling** (5 single take, 6 both takes, 2 single stereo channel L/R), **1 keep today's sound** (`wep_ithar_pulsar_b_f2`), and **2 re-rolls** (`death_metal_crack_f2`, `ship_thruster_puff_f2`).
- **Ryan's 7 rejects landed 6 of 7:**
  - `death_metal_powerdown_f2` (**t1**): completely fixed. Zero static (`0.1% >6 kHz`, power centroid dropped from `2634 Hz` to `107 Hz`); deep sinking reactor hum with a grounded metal groan.
  - `evt_ram_impact_f2` (**channel R of t1**): completely fixed once extracted to channel R and head-trimmed (`75 ms`). Power centroid dropped from Wave F's `702 Hz` to `237 Hz` (median `64 Hz` vs `281 Hz`): pure low, heavy hull-on-hull crunch with zero high metallic ring.
  - `evt_nebula_bed_f2` (**t1**): completely fixed. `100.0% <500 Hz`, `0.0% >2 kHz`, `74 Hz` dark gaseous hum with smooth slow swells, zero rain or patter, and a seamless loop wrap at usable `-17.1 dB` raw level.
  - `ui_rank_up_f2` (**t1 and t2**): completely fixed. Clean, crisp rising three-note brass trumpet promotion calls with natural ring and zero odd or raspy tone.
  - `imp_obsidian_eclipse_more_f2` (**t2**): completely fixed once its `113 ms` dead head is trimmed. Power centroid is `492 Hz` and median `58 Hz` (less than half of keeper `1060 Hz` / `163 Hz` and Wave F `1076 Hz`), dense and heavy in pure mono (`corr +0.97`, `cos 0.908`).
  - `wep_hullbreaker_junk_gun_more_f2` (**t2**): fixed once 40 Hz high-passed. Immediate crude scrap-cannon bang at `0.0 ms` followed by a tight rattling scrap-metal tail, not loose clattering metal.
  - `death_metal_crack_f2` (**re-roll**; keep today meanwhile): **STILL FAILED Ryan's "super high pitched" note.** Both takes are `99% >2 kHz` shrill `3050 Hz` metal sword/gong clangs (`cent(pwr) 4575` to `4655 Hz`), even higher than Wave F (`1255 Hz`) and today's deep `126 Hz` baseline.
- **Neon's 9 Wave F re-rolls landed 7 of 9:**
  - Shipped: `death_metal_run_f2` (**t1 and t2**), `evt_torp_intercept_f2` (**t1**), `imp_energy_sear_more_f2` (**t1 and t2**), `wep_sunward_autocannon_more_f2` (**t1 and t2**), `wep_sunward_turret_more_f2` (**channel L of t2**), `wep_eclipse_gsentry_more_f2` (**t1 and t2**), and `wep_craft_guns_more_f2` (**t1 and t2**).
  - Missed: `wep_ithar_pulsar_b_f2` (**keep today's sound**: both takes collapsed to `99.7%` to `100.0% <500 Hz` `261 Hz` pure low drones with zero high crystal shimmer and `7.2` to `9.1 dB` swells) and `ship_thruster_puff_f2` (**re-roll**: both takes still ramp up to peak on the final sample `679.8 ms` with `last20 +4.2/+4.1 dB` abrupt cutoffs and uncorrelated wide stereo; a zero-credit fallback is `channel R of t1` trimmed to `0.45 s` with a `200 ms` fade-out).
- **Wave M2_test and M2 plan verdict: CHANGE before running the remaining 30 M2 tracks.** Both M2_test tracks (`mus_ithar_loop_a` and `mus_chorus_loop_a`) hit their exact BPM bar grids (`88.0 BPM` and `76.0 BPM`), prove how huge an upgrade orchestral faction music is over `fac_ithar.ogg` and `fac_chorus.ogg`, and exposed **three exact fixes** needed before spending credits on M2:
  1. Widen `stem_loop_check.py`'s MP3 length window (`-1 ms to +50 ms` auto-failed both tracks at `-30.5 ms` and `+50.5 ms` despite exact BPM bar grids).
  2. Fix the Glasswrights (`ithar`) 21 dB intro ramp and weak drums (`0.99 dB` contrast in the first third, silent drums for 10 s): restore `"every part plays in every bar from bar 1 beat 1, no intro build, no fade-in"` on all 24-bar faction loops, and either strengthen Glasswright percussion from bar 1 or use an in-game calm treatment instead of paying for Glasswright stems.
  3. Fix Chorus prompts so pitched instruments actually play alongside the frame drums (`mus_chorus_loop_a` generated `99.2% <500 Hz` frame drums only, leaving `calm` as a bare `100% <500 Hz` / `99.4% <100 Hz` sub-heartbeat ghost that cannot stand alone as music), or switch Chorus to an in-game calm treatment.
- **The 4 re-roll ids (one sentence each on what to change):**
  - `death_metal_crack_f2`: re-roll: drop "crack" and "steel spine" words that trigger 3 kHz sword-clang priors in v3, switch to v2 or ask for a dull low-frequency ship bulkhead girder snapping and groaning below 500 Hz with no metallic ring or clang.
  - `ship_thruster_puff_f2`: re-roll: switch to v2 or lengthen to 1.0 s asking for an instant short pressurized valve burst in the first 250 ms followed by 700 ms of total silence (or skip re-rolling and trim `channel R of t1` to 0.45 s with a 200 ms fade-out).
  - `mus_ithar_loop_a`: re-roll: add "every instrument including timpani plays from bar 1 beat 1 at full texture with no intro build and no fade-in" (and either strengthen the rhythmic timpani pulse for >=2.5 dB stem contrast or drop stems and use an in-game calm filter).
  - `mus_chorus_loop_a`: re-roll: foreground sustained bowed cellos, contrabassoon melody, and eerie high string harmonics in every bar above restrained frame drums so `other` stands on its own as music (or drop stems and use an in-game calm treatment).
- **Mastering traps caught across F2:** Mandatory head trims on `evt_ram_impact_f2` (`75 ms` on `t1`), `imp_obsidian_eclipse_more_f2` (`113 ms` on `t2`, `175 ms` on `t1`), `wep_eclipse_gsentry_more_f2` (`68 ms` on `t1`, `49 ms` on `t2`), and `wep_craft_guns_more_f2` (`25 ms` on `t1`); mandatory 40 Hz high-pass and peak headroom trims on all three `v2` gun rows (`wep_sunward_autocannon_more_f2`, `wep_craft_guns_more_f2`, `wep_hullbreaker_junk_gun_more_f2`, which carry `17%` to `74%` sub-40 Hz DC/rumble raw).

---

## Quick Pick Summary (All 18 IDs: 16 Wave F2 + 2 M2_test)

| # | Group | Sound ID | Final Answer | Mastering / Handling Notes |
|---|---|---|---|---|
| 1 | Ryan reject | `death_metal_powerdown_f2` | **t1** | Fold to mono (`corr +0.73`), high-pass 40 Hz (strips `10.4% <40 Hz`); zero static (`0.1% >6 kHz`), deep sinking reactor hum and metal groan |
| 2 | Ryan reject | `death_metal_crack_f2` | **re-roll** | Keep today's sound meanwhile; both takes are shrill `3050 Hz` metal sword clangs (`99% >2 kHz`); drop "crack"/"steel spine" and ask for dull sub-500 Hz girder buckle with no ring |
| 3 | Ryan reject | `evt_ram_impact_f2` | **channel R of t1** | Extract channel R only (`-18.7 dB` RMS, `92.4/3.0/4.6%`, `237 Hz` pwr centroid vs Wave F `702 Hz`), trim `75 ms` dead head, high-pass 40 Hz (`channel L of t1` is slightly darker) |
| 4 | Ryan reject | `evt_nebula_bed_f2` | **t1** | Keep stereo as unpositioned terrain bed (or extract `channel R of t1` if mono 3D), high-pass 35 Hz; `100% <500 Hz` `74 Hz` dark gas hum, zero rain/patter, seamless loop verified |
| 5 | Ryan reject | `ui_rank_up_f2` | **t1 and t2** | Keep stereo UI or fold cleanly (`corr +0.82/+0.73`), trim `5 ms` (`t1`) / `10 ms` (`t2`) lead-in, high-pass 40 Hz; clean rising brass promotion fanfare (`t1` brighter lead, `t2` warmer) |
| 6 | Ryan reject | `imp_obsidian_eclipse_more_f2` | **t2** | Fold to mono (pure `corr +0.97`, `cos 0.908`), trim `113 ms` dead head, high-pass 40 Hz; `492 Hz` pwr centroid / `58 Hz` median clearly lower and heavier than keeper (`1060 Hz`) |
| 7 | Ryan reject | `wep_hullbreaker_junk_gun_more_f2` | **t2** | Fold to mono (`corr +0.85`), high-pass 40 Hz (clears `66.1% <20 Hz` v2 DC/sub), lift ~+4 dB to keeper `-22.3 dB`; immediate crude cannon bang at `0.0 ms` with rattling scrap tail |
| 8 | F2 re-roll | `ship_thruster_puff_f2` | **re-roll** | Both takes ramp into an abrupt peak cut at `679.8 ms` (`last20 +4.2/+4.1 dB`) in uncorrelated stereo; zero-credit fallback is `channel R of t1` trimmed to `0.45 s` with a `200 ms` fade-out |
| 9 | F2 re-roll | `death_metal_run_f2` | **t1 and t2** | Fold to mono (pure `corr +0.99/+1.00`), high-pass 40 Hz, lift `t1` ~+6 dB; sharp rolling midrange metallic blast cracks (`49-55% <500 Hz`, `4-14% <100 Hz`), `t1` rolls longest |
| 10 | F2 re-roll | `wep_ithar_pulsar_b_f2` | **keep today's sound** | Keep today's `wep_ithar_pulsar_0.ogg` (`44/14/42%`); both F2 takes collapsed to `99.7-100% <500 Hz` `261 Hz` low drones (`cos 0.26-0.30`) with zero shimmer and `7-9 dB` swells |
| 11 | F2 re-roll | `evt_torp_intercept_f2` | **t1** | Fold to mono (rock-solid `corr +0.96`), high-pass 40 Hz, `0.0 ms` onset; crisp PD rattle into sharp clean warhead detonation decaying to `-57.6 dB` with zero end-cut |
| 12 | F2 re-roll | `imp_energy_sear_more_f2` | **t1 and t2** | Fold to mono (`corr +0.91/+0.87`), high-pass 40 Hz, trim `8 ms` head and attenuate `t2` ~-8 dB to match keeper; `t2` is closest match (`cos 0.867`), `t1` adds bright crackling arc |
| 13 | F2 re-roll | `wep_sunward_autocannon_more_f2` | **t1 and t2** | Fold to mono (pure `corr +0.99/+0.98`), mandatory 40 Hz HP (clears `63-74% <40 Hz` v2 DC/sub) and peak/level trim to `-23 dB` keeper; both match tight punch (`cos 0.857/0.850` post-HP) |
| 14 | F2 re-roll | `wep_sunward_turret_more_f2` | **channel L of t2** | Extract channel L only (`-28.5 dB` RMS, `20.1/47.8/32.1%`, `cos 0.906`, `0.0 ms` onset), high-pass 40 Hz, lift ~+4 dB; `channel R of t1` (`cos 0.872`) also works as a second single-channel take |
| 15 | F2 re-roll | `wep_eclipse_gsentry_more_f2` | **t1 and t2** | Fold to mono (`corr +0.91/+0.86`), trim `68 ms` (`t1`) and `49 ms` (`t2`) dead heads, high-pass 40 Hz, match level to keeper `-23.3 dB`; loud crisp high-voltage snaps (`cos 0.850/0.860`) |
| 16 | F2 re-roll | `wep_craft_guns_more_f2` | **t1 and t2** | Fold to mono (pure `corr +0.99`), mandatory 40 Hz HP (clears `17-69% <40 Hz` v2 DC/sub), trim `25 ms` head on `t1`, peak/level trim; tight 3-round bursts (`t2` fuller lead `cos 0.822` post-HP) |
| 17 | M2 test | `mus_ithar_loop_a` | **re-roll** | On-theme Glasswrights timbre and intact tonal calm mix, but `-30.5 ms` short of grid, `21.2 dB` wrap cliff from quiet solo-harp start, and silent first-10 s drums (`0.99 dB` first-third / `1.27 dB` total contrast) |
| 18 | M2 test | `mus_chorus_loop_a` | **re-roll** | Exact `76 BPM` wrap (`0.7 dB` 5 s span, `+50.5 ms` MP3 pad), but generated `99.2% <500 Hz` drums only; `calm` is a bare `100% <500 Hz` / `99.4% <100 Hz` sub-heartbeat ghost with no tonal parts |

---

## Group 1: Ryan's 7 Rejects (7 Wave F2 IDs, 14 Takes)

### 1. `death_metal_powerdown_f2` (F2 re-roll: death_powerdown base (a steel ship's reactor dying), 1.8 s)

- **Ryan's note:** "just sounds like static"; ask for a deep reactor wind-down with groaning metal and fading hum.
- **Today baseline:** `death_metal_powerdown_f2_today0.ogg` (`-19.6 dB`, `18.2/15.3/66.5%`, `47.1% >6 kHz`, `cent(mag) 8397 Hz`, `cent(pwr) 6642 Hz`, `T95 1157 ms`), `death_metal_powerdown_f2_today1.ogg` (`-21.6 dB`, `51.4/14.2/34.4%`, `cent(pwr) 2058 Hz`, `T95 793 ms`).
- **Wave F rejected baseline:** `death_metal_powerdown_t1.mp3` (`-20.0 dB`, `36.8/10.6/52.6%`, `9.8% >6 kHz`, `cent(mag) 5701 Hz`, `cent(pwr) 2634 Hz`, `med 2298 Hz`).
- **`death_metal_powerdown_f2_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Smooth, deep sinking reactor hum with a low groaning steel support and zero static (`0.1% >6 kHz`, power centroid dropped from Wave F's `2634 Hz` to `107 Hz`), nailing Ryan's note cleanly.
  2. **Bass (<500 Hz):** Yes (`98.4%` below 500 Hz stereo, `98.5%` mono). Measured stereo `98.4%` <500 Hz (`0.2%` <20 Hz, `10.4%` <40 Hz, `75.0%` <100 Hz), `1.3%` in 500 Hz to 2 kHz, `0.3%` >2 kHz (`0.1%` >6 kHz); mono centroid `1682 Hz` (power centroid `107 Hz`, median `52 Hz`, dominant `44.9 Hz`), `-14.4 dB` stereo RMS (`-15.1 dB` mono, peak `-1.7 dBFS`).
  3. **Mono:** Holds up cleanly with minor softening. `corr +0.73`, fold loss `-0.69 dB` overall (`-0.68 dB` <500 Hz, `-0.93 dB` 500 Hz to 2 kHz, `-2.19 dB` >2 kHz, `-1.06 dB` attack 0 to 60 ms). L/R imbalance `-2.4 dB` (`L -15.8 dB`, `R -13.4 dB`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `16.0 ms` at -20 dB). Peak at `621.4 ms`, `T95 = 1096 ms`, dur `1.76 s`, end `-41.8 dB`.
- **`death_metal_powerdown_f2_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Opens with a brief breathy hiss/clank before a deep metal groan and collapses `-2.4 dB` overall (`-3.4 dB` mids, `-3.3 dB` attack) in wide mono fold-down.
  2. **Bass (<500 Hz):** Yes (`93.8%` below 500 Hz stereo, `95.1%` mono). Measured stereo `93.8%` <500 Hz (`3.8%` <20 Hz, `18.1%` <40 Hz, `48.3%` <100 Hz), `5.6%` in 500 Hz to 2 kHz, `0.5%` >2 kHz (`0.1%` >6 kHz); mono centroid `1495 Hz` (power centroid `170 Hz`, median `89 Hz`, dominant `28.4 Hz`), `-16.9 dB` stereo RMS (`-19.4 dB` mono, peak `-0.9 dBFS`).
  3. **Mono:** Yes, loses midrange and punch. `corr +0.15`, fold loss `-2.41 dB` overall (`-2.35 dB` <500 Hz, `-3.41 dB` 500 Hz to 2 kHz, `-2.88 dB` >2 kHz, `-3.31 dB` attack 0 to 60 ms). Single channels: L `-18.3 dB` (pk `-3.3 dBFS`, `93.1/6.3/0.6%`), R `-15.9 dB` (pk `-0.9 dBFS`, `94.3/5.3/0.5%`).
  4. **Onset (<=30 ms):** Yes, immediate (`6.6 ms` at -40 dB, `11.2 ms` at -30 dB, `16.4 ms` at -20 dB). Peak at `180.3 ms`, `T95 = 987 ms`, dur `1.76 s`, end `-62.8 dB`.
- **Final answer (`death_metal_powerdown_f2`):** **t1**

### 2. `death_metal_crack_f2` (F2 re-roll: death_crack base (the hull's spine cracking), 1.5 s)

- **Ryan's note:** "super high pitched", nothing like the prompt; ask for a low, heavy spine crack with deep metal stress.
- **Today baseline:** `death_metal_crack_f2_today0.ogg` (`-19.0 dB`, `100.0/0.0/0.0%`, `cent(mag) 187 Hz`, `cent(pwr) 126 Hz`, `med 138 Hz`, `T95 1752 ms`), `death_metal_crack_f2_today1.ogg` (`-20.2 dB`, `99.5/0.5/0.0%`, `cent(pwr) 42 Hz`, `T95 976 ms`), `death_metal_crack_f2_today2.ogg` (`-31.1 dB`, `7.2/15.2/77.7%`, `T95 260 ms`).
- **Wave F rejected baseline:** `death_metal_crack_t2.mp3` (`-21.3 dB`, `37.8/42.4/19.9%`, `cent(mag) 3314 Hz`, `cent(pwr) 1255 Hz`, `med 790 Hz`).
- **`death_metal_crack_f2_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Even higher pitched than Wave F (`99.3% >2 kHz`, `3048 Hz` dominant, `4575 Hz` power centroid vs today's `126 Hz`), sounding like a piercing sword or gong clang with `138 ms` dead head and wide-stereo loss.
  2. **Bass (<500 Hz):** No (`0.4%` below 500 Hz stereo, `0.4%` mono). Measured stereo `0.4%` <500 Hz (`0.0%` <20 Hz), `0.3%` in 500 Hz to 2 kHz, `99.3%` >2 kHz (`39.1%` >6 kHz); mono centroid `6037 Hz` (power centroid `4575 Hz`, median `3175 Hz`, dominant `3048.0 Hz`), `-22.9 dB` stereo RMS (`-24.7 dB` mono, peak `-3.5 dBFS`).
  3. **Mono:** Yes, loses body and attack. `corr +0.31`, fold loss `-1.84 dB` overall (`-2.37 dB` <500 Hz, `-2.85 dB` 500 Hz to 2 kHz, `-1.84 dB` >2 kHz, `-3.09 dB` attack 0 to 60 ms). Single channels: L `-22.7 dB` (pk `-3.5 dBFS`, `0.3/0.2/99.5%`), R `-23.1 dB` (pk `-5.6 dBFS`, `0.5/0.3/99.2%`).
  4. **Onset (<=30 ms):** No, very late start (`138.3 ms` at -40 dB, `155.6 ms` at -30 dB, `310.7 ms` at -20 dB). Peak at `712.9 ms`, `T95 = 868 ms`, dur `1.48 s`, end `-42.2 dB`.
- **`death_metal_crack_f2_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Another shrill metallic screech and high ring (`98.7% >2 kHz`, `3077 Hz` dominant, `4655 Hz` power centroid vs today's `126 Hz`), completely missing Ryan's call for a low heavy spine crack.
  2. **Bass (<500 Hz):** No (`0.5%` below 500 Hz stereo, `0.5%` mono). Measured stereo `0.5%` <500 Hz (`0.0%` <20 Hz), `0.8%` in 500 Hz to 2 kHz, `98.7%` >2 kHz (`44.1%` >6 kHz); mono centroid `5959 Hz` (power centroid `4655 Hz`, median `3568 Hz`, dominant `3077.0 Hz`), `-24.2 dB` stereo RMS (`-25.7 dB` mono, peak `-6.1 dBFS`).
  3. **Mono:** Yes, loses midrange in mono fold. `corr +0.42`, fold loss `-1.49 dB` overall (`-1.67 dB` <500 Hz, `-3.50 dB` 500 Hz to 2 kHz, `-1.48 dB` >2 kHz, `-1.43 dB` attack 0 to 60 ms). Single channels: L `-24.0 dB` (pk `-6.1 dBFS`, `0.5/0.7/98.8%`), R `-24.4 dB` (pk `-6.6 dBFS`, `0.6/0.8/98.6%`).
  4. **Onset (<=30 ms):** No, late start (`30.8 ms` at -40 dB, `76.5 ms` at -30 dB, `106.5 ms` at -20 dB). Peak at `631.8 ms`, `T95 = 917 ms`, dur `1.48 s`, end `-35.1 dB`.
- **Final answer (`death_metal_crack_f2`):** **re-roll: drop "crack" and "steel spine" words that trigger 3 kHz sword-clang priors in v3, switch to v2 or ask for a dull low-frequency ship bulkhead girder snapping and groaning below 500 Hz with no metallic ring or clang (keep today's sound meanwhile).**

### 3. `evt_ram_impact_f2` (F2 re-roll: new: Hullbreaker ram (RAM_FAC) hull-on-hull collision, 1.6 s)

- **Ryan's note:** too high pitched; ask for a low heavy hull-on-hull crunch.
- **Today baseline:** `evt_ram_impact_f2_today0.ogg` (`-23.0 dB`, `75.6/15.1/9.3%`, `cent(mag) 3330 Hz`, `cent(pwr) 657 Hz`, `med 137 Hz`, `T95 307 ms`).
- **Wave F rejected baseline:** `evt_ram_impact_t1.mp3` (`-16.4 dB`, `81.1/8.8/10.1%`, `cent(mag) 4088 Hz`, `cent(pwr) 702 Hz`, `med 281 Hz`, ringing metal clash).
- **`evt_ram_impact_f2_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Massive low, heavy hull-on-hull crunch and plate crush (`237 Hz` power centroid / `64 Hz` median vs Wave F's `702 Hz` / `281 Hz`) with zero high metallic ring, but wide stereo drops `-2.2` to `-2.5 dB` of mids and highs in mono; channel R alone is clean after trimming its `75 ms` dead head.
  2. **Bass (<500 Hz):** Yes (`93.6%` below 500 Hz stereo, `94.5%` mono). Measured stereo `93.6%` <500 Hz (`1.1%` <20 Hz, `29.8%` <40 Hz, `83.3%` <100 Hz), `2.9%` in 500 Hz to 2 kHz, `3.6%` >2 kHz (`1.0%` >6 kHz); mono centroid `3791 Hz` (power centroid `237 Hz`, median `64 Hz`, dominant `33.1 Hz`), `-18.6 dB` stereo RMS (`-20.3 dB` mono, peak `-4.7 dBFS`).
  3. **Mono:** Yes, loses midrange and crunch edge. `corr +0.37`, fold loss `-1.65 dB` overall (`-1.61 dB` <500 Hz, `-2.18 dB` 500 Hz to 2 kHz, `-2.53 dB` >2 kHz, `-0.99 dB` attack 0 to 60 ms). Single channels: L `-18.6 dB` (pk `-6.8 dBFS`, `94.7/2.7/2.5%`), R `-18.7 dB` (pk `-4.7 dBFS`, `92.4/3.0/4.6%`).
  4. **Onset (<=30 ms):** No, late start (`76.3 ms` at -40 dB, `93.9 ms` at -30 dB, `96.1 ms` at -20 dB; trim `75 ms` dead head in mastering). Peak at `158.6 ms`, `T95 = 1094 ms`, dur `1.60 s`, end `-49.4 dB`.
- **`evt_ram_impact_f2_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Brighter, scrap-heavy shatter (`4600 Hz` mag centroid, `1139 Hz` power centroid, `19.5% >2 kHz`), wide stereo (`-3.5 dB` mid fold loss), and late peak at `406 ms` that stays brighter than `t1`.
  2. **Bass (<500 Hz):** Yes (`67.6%` below 500 Hz stereo, `73.6%` mono). Measured stereo `67.6%` <500 Hz (`2.7%` <20 Hz, `11.7%` <40 Hz, `51.0%` <100 Hz), `13.0%` in 500 Hz to 2 kHz, `19.5%` >2 kHz (`6.3%` >6 kHz); mono centroid `4600 Hz` (power centroid `1139 Hz`, median `76 Hz`, dominant `51.9 Hz`), `-21.8 dB` stereo RMS (`-23.9 dB` mono, peak `-1.3 dBFS`).
  3. **Mono:** Yes, loses midrange and top crunch. `corr +0.23`, fold loss `-2.11 dB` overall (`-1.74 dB` <500 Hz, `-3.51 dB` 500 Hz to 2 kHz, `-2.71 dB` >2 kHz, `-1.41 dB` attack 0 to 60 ms). Single channels: L `-22.1 dB` (pk `-1.4 dBFS`, `81.4/8.0/10.7%`), R `-21.6 dB` (pk `-1.3 dBFS`, `55.4/17.4/27.2%`).
  4. **Onset (<=30 ms):** No, slightly late start (`30.5 ms` at -40 dB, `38.8 ms` at -30 dB, `41.4 ms` at -20 dB). Peak at `405.9 ms`, `T95 = 869 ms`, dur `1.60 s`, end `-57.2 dB`.
- **Final answer (`evt_ram_impact_f2`):** **channel R of t1**

### 4. `evt_nebula_bed_f2` (F2 re-roll: new: nebula or ion cloud terrain bed, loops, 8.0 s)

- **Ryan's note:** "sounds like rain"; ask for a low soft gas hum with slow swells, no hiss or patter.
- **Today baseline:** No clip today (`new_moment`).
- **Wave F rejected baseline:** `evt_nebula_bed_t1.mp3` (`-51.7 dB`, `39.0/47.3/13.7%`, `cent(mag) 2504 Hz`, `cent(pwr) 1069 Hz`, `med 691 Hz`).
- **`evt_nebula_bed_f2_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Smooth, dark low gaseous nebula hum (`100% <500 Hz`, `74 Hz` dominant, `0.0% >2 kHz`) with slow shallow swells, zero rain or patter, healthy `-17.1 dB` level, and a seamless loop verified by ear; keep stereo as an unpositioned bed (or extract channel R if mono).
  2. **Bass (<500 Hz):** Yes (`100.0%` below 500 Hz stereo, `100.0%` mono). Measured stereo `100.0%` <500 Hz (`0.0%` <20 Hz, `0.3%` <40 Hz, `56.6%` <100 Hz), `0.0%` in 500 Hz to 2 kHz, `0.0%` >2 kHz (`0.0%` >6 kHz); mono centroid `212 Hz` (power centroid `94 Hz`, median `80 Hz`, dominant `74.0 Hz`), `-17.1 dB` stereo RMS (`-19.5 dB` mono, peak `-4.7 dBFS`). Loop seam: `-1.30 dB` end-to-start, spectral cosine `0.982`, 0.5 s spread `3.14 dB`, boundary jump `0.0207`.
  3. **Mono:** Wide stereo ambient bed (`corr +0.16`, fold loss `-2.36 dB` overall). Keep stereo for unpositioned terrain bed, or extract channel R (`-16.6 dB`, pk `-4.7 dBFS`, `100.0/0.0/0.0%`, verified clean by ear) if mono 3D.
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `1473.7 ms`, `T95 = 7504 ms`, dur `8.00 s`.
- **`evt_nebula_bed_f2_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Also smooth and seamless (`+0.06 dB` end-to-start, `cos 0.986`) with zero rain or patter, but `17.5 dB` quieter (`-34.6 dB`) and higher-pitched (`178 Hz` hollow drone) than `t1`'s deeper gas hum.
  2. **Bass (<500 Hz):** Yes (`99.3%` below 500 Hz stereo, `99.3%` mono). Measured stereo `99.3%` <500 Hz (`0.0%` <20 Hz, `0.0%` <100 Hz), `0.7%` in 500 Hz to 2 kHz, `0.0%` >2 kHz (`0.0%` >6 kHz); mono centroid `339 Hz` (power centroid `191 Hz`, median `177 Hz`, dominant `177.6 Hz`), `-34.6 dB` stereo RMS (`-36.7 dB` mono, peak `-21.8 dBFS`). Loop seam: `+0.06 dB` end-to-start, spectral cosine `0.986`, 0.5 s spread `3.49 dB`, boundary jump `0.0022`.
  3. **Mono:** Wide stereo ambient bed (`corr +0.23`, fold loss `-2.10 dB` overall). Single channels: L `-34.2 dB` (pk `-21.8 dBFS`, `99.2/0.8/0.0%`), R `-35.1 dB` (pk `-22.9 dBFS`, `99.3/0.7/0.0%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `3917.5 ms`, `T95 = 7536 ms`, dur `8.00 s`.
- **Final answer (`evt_nebula_bed_f2`):** **t1**

### 5. `ui_rank_up_f2` (F2 re-roll: new: a captain or ship ranks up, 1.8 s)

- **Ryan's note:** odd, "almost like a fart"; ask for a short bright brass or bell promotion cue.
- **Today baseline:** `ui_rank_up_f2_today0.ogg` (`-21.4 dB`, `90.8/8.7/0.5%`, `cent(mag) 992 Hz`, `cent(pwr) 225 Hz`, `T95 1015 ms`).
- **Wave F rejected baseline:** `ui_rank_up_t2.mp3` (`-24.6 dB`, `71.3/26.2/2.4%`, `dom 76 Hz`, `med 288 Hz`).
- **`ui_rank_up_f2_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Crisp, noble rising three-note bright brass trumpet promotion call with clean attack (`5.5 ms`), solid mono lock, and natural ring that completely fixes Ryan's note.
  2. **Bass (<500 Hz):** No (`0.2%` below 500 Hz stereo, `0.2%` mono). Measured stereo `0.2%` <500 Hz (`0.0%` <20 Hz), `67.3%` in 500 Hz to 2 kHz, `32.5%` >2 kHz (`0.1%` >6 kHz); mono centroid `2596 Hz` (power centroid `1595 Hz`, median `1569 Hz`, dominant `1569.3 Hz`), `-17.0 dB` stereo RMS (`-17.5 dB` mono, peak `-2.2 dBFS`).
  3. **Mono:** Holds up cleanly with minor softening. `corr +0.82`, fold loss `-0.45 dB` overall (`-0.54 dB` <500 Hz, `-0.38 dB` 500 Hz to 2 kHz, `-0.59 dB` >2 kHz, `-0.12 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`5.5 ms` at -40 dB, `8.2 ms` at -30 dB, `12.0 ms` at -20 dB; trim `5 ms` lead-in). Peak at `342.7 ms`, `T95 = 1106 ms`, dur `1.76 s`, end `-57.2 dB`.
- **`ui_rank_up_f2_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Slightly warmer, fuller brass promotion fanfare (`392 Hz` lower brass harmonic base beneath bright upper trumpet) with clean mono fold and crisp ring, pairing well with `t1`.
  2. **Bass (<500 Hz):** No (`22.4%` below 500 Hz stereo, `25.0%` mono). Measured stereo `22.4%` <500 Hz (`0.0%` <20 Hz), `61.4%` in 500 Hz to 2 kHz, `16.2%` >2 kHz (`0.0%` >6 kHz); mono centroid `2016 Hz` (power centroid `1360 Hz`, median `1566 Hz`, dominant `392.0 Hz`), `-18.0 dB` stereo RMS (`-18.6 dB` mono, peak `-1.3 dBFS`).
  3. **Mono:** Holds up cleanly with minor top softening. `corr +0.73`, fold loss `-0.62 dB` overall (`-0.14 dB` <500 Hz, `-0.53 dB` 500 Hz to 2 kHz, `-1.81 dB` >2 kHz, `-0.02 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`10.5 ms` at -40 dB, `25.1 ms` at -30 dB, `31.3 ms` at -20 dB; trim `10 ms` lead-in). Peak at `350.5 ms`, `T95 = 1058 ms`, dur `1.76 s`, end `-57.5 dB`.
- **Final answer (`ui_rank_up_f2`):** **t1 and t2**

### 6. `imp_obsidian_eclipse_more_f2` (F2 re-roll: variety: 2 more takes of keeper imp_obsidian_eclipse (C t1) for the round robin, 1.0 s)

- **Ryan's note:** too high pitched; ask for lower, heavier obsidian impacts that match today's keeper.
- **Today baseline:** `imp_obsidian_eclipse_more_f2_today0.ogg` (`-25.8 dB`, `74.1/2.9/22.9%`, `cent(pwr) 2036 Hz`, `T95 232 ms`).
- **In-game keeper (`godot/audio/clips/imp_obsidian_eclipse_0.ogg`):** `-26.2 dB` RMS, `63.3/17.9/18.9%` (<500 / 500-2k / >2k), `cent(mag) 3712 Hz`, `cent(pwr) 1060 Hz`, `med 163 Hz`, `dom 40 Hz`, `T95 237 ms`, dur `0.997 s`.
- **Wave F rejected baseline:** `imp_obsidian_eclipse_more_t1.mp3` (`-20.7 dB`, `60.6/21.2/18.2%`, `cent(mag) 3945 Hz`, `cent(pwr) 1076 Hz`, `med 159 Hz`), `t2` (`-18.9 dB`, `71.0/13.4/15.6%`, `cent(pwr) 886 Hz`, `med 90 Hz`).
- **`imp_obsidian_eclipse_more_f2_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Good obsidian knock (`cos 0.907`, `930 Hz` power centroid, `-130 Hz` below keeper) in solid mono, but carries a `175.9 ms` dead head and brighter `4464 Hz` magnitude centroid (`6.4% >6 kHz`) than `t2`, which answers Ryan's lower/heavier note much more clearly (usable as an optional second sibling only after `175 ms` trim).
  2. **Bass (<500 Hz):** Yes (`65.4%` below 500 Hz stereo, `69.1%` mono). Measured stereo `65.4%` <500 Hz (`0.0%` <20 Hz, `42.9%` <100 Hz), `19.0%` in 500 Hz to 2 kHz, `15.6%` >2 kHz (`6.4%` >6 kHz); mono centroid `4464 Hz` (power centroid `930 Hz`, median `143 Hz`, dominant `73.0 Hz`), `-24.9 dB` stereo RMS (`-25.2 dB` mono, peak `-1.2 dBFS`). vs `imp_obsidian_eclipse_0.ogg`: spectral cosine `0.907`, `T95` ratio `1.03x`, above-30 Hz deltas `+6/+1/-7%`, power centroid `-130 Hz`, median `-20 Hz`.
  3. **Mono:** No loss; rock-solid mono. `corr +0.88`, fold loss `-0.28 dB` overall (`-0.04 dB` <500 Hz, `-0.23 dB` 500 Hz to 2 kHz, `-1.51 dB` >2 kHz, `-0.22 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** No, very late dead head (`175.9 ms` at -40 dB, `178.8 ms` at -30 dB, `195.1 ms` at -20 dB; must trim `175 ms` head if used). Peak at `201.5 ms`, `T95 = 244 ms`, dur `1.00 s`, end `-47.3 dB`.
- **`imp_obsidian_eclipse_more_f2_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Dense, lower, heavier obsidian impact (`492 Hz` power centroid / `58 Hz` median vs keeper `1060 Hz` / `163 Hz` and Wave F `1076 Hz`) matching the keeper (`cos 0.908`, `T95 231 ms`) in pure mono once its `113 ms` dead head is trimmed.
  2. **Bass (<500 Hz):** Yes (`79.5%` below 500 Hz stereo, `80.6%` mono). Measured stereo `79.5%` <500 Hz (`0.1%` <20 Hz, `7.2%` <40 Hz, `66.9%` <100 Hz), `14.6%` in 500 Hz to 2 kHz, `5.8%` >2 kHz (`1.8%` >6 kHz); mono centroid `3897 Hz` (power centroid `492 Hz`, median `58 Hz`, dominant `45.0 Hz`), `-22.0 dB` stereo RMS (`-22.1 dB` mono, peak `-1.3 dBFS`). vs `imp_obsidian_eclipse_0.ogg`: spectral cosine `0.908`, `T95` ratio `0.97x`, above-30 Hz deltas `+17/-4/-13%`, power centroid `-568 Hz`, median `-105 Hz`.
  3. **Mono:** No loss; rock-solid mono. `corr +0.97`, fold loss `-0.07 dB` overall (`-0.01 dB` <500 Hz, `-0.30 dB` 500 Hz to 2 kHz, `-0.32 dB` >2 kHz, `-0.01 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** No, late dead head (`113.9 ms` at -40 dB, `117.6 ms` at -30 dB, `136.3 ms` at -20 dB; must trim `113 ms` dead head in mastering). Peak at `165.6 ms`, `T95 = 231 ms`, dur `1.00 s`, end `-52.6 dB`.
- **Final answer (`imp_obsidian_eclipse_more_f2`):** **t2**

### 7. `wep_hullbreaker_junk_gun_more_f2` (F2 re-roll: variety: 2 more takes of keeper wep_hullbreaker_junk_gun (D t2) for the round robin, 0.6 s)

- **Ryan's note:** "just sounds like metal clattering, not a junk gun"; ask for a crude scrap cannon firing (a bang with rattling scrap), matching today's junk gun keeper.
- **Today baseline:** `wep_hullbreaker_junk_gun_more_f2_today0.ogg` (`-21.6 dB`, `100.0/0.0/0.0%`, `T95 594 ms`), `wep_hullbreaker_junk_gun_more_f2_today1.ogg` (`-21.8 dB`, `58.9/31.6/9.5%`, `T95 292 ms`).
- **In-game keeper (`godot/audio/clips/wep_hullbreaker_junk_gun_0.ogg`):** `-22.3 dB` RMS, `6.1/43.0/50.9%` (<500 / 500-2k / >2k), `cent(mag) 5062 Hz`, `cent(pwr) 2564 Hz`, `med 2062 Hz`, `T95 199 ms`, dur `0.597 s`.
- **`wep_hullbreaker_junk_gun_more_f2_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Whisper-quiet (`-40.2 dB` raw, `-43.6 dB` after 40 Hz HP, 21 dB below the keeper) tiny muffled DC thump (`cos 0.403`) with no cannon bang or scrap rattle.
  2. **Bass (<500 Hz):** Yes (`97.8%` below 500 Hz raw, `93.0%` after 40 Hz HP). Measured stereo `97.8%` <500 Hz (`67.3%` <20 Hz), `1.6%` in 500 Hz to 2 kHz, `0.6%` >2 kHz; mono centroid `2528 Hz` (`2790 Hz` post-HP), `-40.2 dB` stereo RMS (`-43.6 dB` post-HP, peak `-23.6 dBFS`). vs `wep_hullbreaker_junk_gun_0.ogg`: post-HP spectral cosine `0.403`, `T95` `122 ms`.
  3. **Mono:** No loss; pure mono. `corr +1.00`, fold loss `-0.00 dB` overall.
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `0.0 ms`, `T95 = 514 ms` (`122 ms` post-HP), dur `0.60 s`.
- **`wep_hullbreaker_junk_gun_more_f2_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Immediate punchy crude scrap-cannon bang at `0.0 ms` followed by a tight rattling scrap-metal tail in solid mono (`corr +0.85`), fixing Ryan's "just metal clattering" note once 40 Hz high-passed and lifted ~+4 dB.
  2. **Bass (<500 Hz):** Yes (`92.2%` below 500 Hz raw due to `66.1% <20 Hz` v2 DC thump; after mandatory 40 Hz HP: `67.3%` <500 Hz, `22.2%` in 500 Hz to 2 kHz, `10.5%` >2 kHz, `cent(mag) 3768 Hz`, `cent(pwr) 865 Hz`, `-26.4 dB` RMS, peak `-3.8 dBFS`, `T95 75 ms`). vs `wep_hullbreaker_junk_gun_0.ogg`: post-HP spectral cosine `0.666` (heavier/punchier low-mid bang than keeper, zero tinnitus whine).
  3. **Mono:** No loss; rock-solid mono. `corr +0.85`, fold loss `-0.34 dB` overall (`-0.31 dB` <500 Hz, `-0.32 dB` 500 Hz to 2 kHz, `-0.42 dB` >2 kHz, `-0.55 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `6.3 ms`, `T95 = 160 ms` (`75 ms` post-HP), dur `0.60 s`, end `-45.7 dB`.
- **Final answer (`wep_hullbreaker_junk_gun_more_f2`):** **t2**

---

## Group 2: Neon's 9 Wave F Re-Rolls (9 Wave F2 IDs, 18 Takes)

### 8. `ship_thruster_puff_f2` (F2 re-roll: puff (a maneuvering thruster firing), 0.7 s)

- **Today baseline:** `ship_thruster_puff_f2_today0.ogg` (`-23.1 dB`, `5.9/1.4/92.7%`, `T95 1206 ms`, dur `2.638 s`).
- **`ship_thruster_puff_f2_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Still repeats Wave F's exact failure by ramping upward to its peak on the final sample (`679.1 ms`, `last20 +4.2 dB`) and cutting off dead in uncorrelated wide stereo (`corr +0.05`); `channel R of t1` trimmed to `0.45 s` with a `200 ms` fade-out is a usable zero-credit fallback if no F3 runs.
  2. **Bass (<500 Hz):** No (`22.2%` below 500 Hz stereo, `25.8%` mono). Measured stereo `22.2%` <500 Hz (`0.0%` <20 Hz), `56.2%` in 500 Hz to 2 kHz, `21.6%` >2 kHz (`4.7%` >6 kHz); mono centroid `3323 Hz`, dominant `629.2 Hz`, `-16.0 dB` stereo RMS (`-18.8 dB` mono, peak `0.1 dBFS`).
  3. **Mono:** Yes, loses midrange, highs, and attack. `corr +0.05`, fold loss `-2.79 dB` overall (`-2.15 dB` <500 Hz, `-2.85 dB` 500 Hz to 2 kHz, `-3.37 dB` >2 kHz, `-3.05 dB` attack 0 to 60 ms). Single channels: L `-17.3 dB` (pk `-2.5 dBFS`, `19.7/54.8/25.5%`), R `-15.0 dB` (pk `0.1 dBFS`, `23.7/57.0/19.3%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `679.1 ms`, `T95 = 672 ms`, dur `0.68 s`. Warning: abrupt end cut (`last 20 ms` is `+4.2 dB` rel RMS, peaking at `-11.8 dB` on the final window).
- **`ship_thruster_puff_f2_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Same abrupt peak cut on the final sample (`679.8 ms`, `last20 +4.1 dB`) plus phase-inverted stereo (`corr -0.09`, `-3.43 dB` fold loss, `-4.30 dB` attack loss).
  2. **Bass (<500 Hz):** No (`32.4%` below 500 Hz stereo, `41.4%` mono). Measured stereo `32.4%` <500 Hz (`0.0%` <20 Hz), `56.3%` in 500 Hz to 2 kHz, `11.3%` >2 kHz (`3.8%` >6 kHz); mono centroid `3166 Hz`, dominant `67.6 Hz`, `-17.0 dB` stereo RMS (`-20.5 dB` mono, peak `0.2 dBFS`).
  3. **Mono:** Yes, severe cancellation across all bands. `corr -0.09`, fold loss `-3.43 dB` overall (`-2.37 dB` <500 Hz, `-4.05 dB` 500 Hz to 2 kHz, `-4.11 dB` >2 kHz, `-4.30 dB` attack 0 to 60 ms). Single channels: L `-17.7 dB` (pk `0.2 dBFS`, `32.4/55.0/12.6%`), R `-16.5 dB` (pk `-0.0 dBFS`, `32.4/57.3/10.3%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.2 ms` at -20 dB). Peak at `679.8 ms`, `T95 = 676 ms`, dur `0.68 s`. Warning: abrupt end cut (`last 20 ms` is `+4.1 dB` rel RMS).
- **Final answer (`ship_thruster_puff_f2`):** **re-roll: switch to v2 or lengthen to 1.0 s asking for an instant short pressurized valve burst in the first 250 ms followed by 700 ms of total silence (or skip re-rolling and trim `channel R of t1` to 0.45 s with a 200 ms fade-out).**

### 9. `death_metal_run_f2` (F2 re-roll: death_run base (blasts running along the hull), 1.8 s)

- **Today baseline:** `death_metal_run_f2_today0.ogg` (`-14.9 dB`, `99.0/0.9/0.1%`, `cent(pwr) 135 Hz`, `T95 3557 ms`, dur `5.00 s`).
- **`death_metal_run_f2_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Sharp rolling cascade of distinct metallic blast cracks and steel shrapnel (`50` to `700 ms` peaks, only `14.4% <100 Hz` vs Wave F's `61%` to `72%`) in pure mono (`corr +0.99`), vastly cleaner than today's muffled low drone once lifted ~+6 dB.
  2. **Bass (<500 Hz):** Balanced (`48.5%` below 500 Hz stereo, `48.7%` mono). Measured stereo `48.5%` <500 Hz (`0.0%` <20 Hz, `0.2%` <40 Hz, `14.4%` <100 Hz), `32.9%` in 500 Hz to 2 kHz, `18.5%` >2 kHz (`0.9%` >6 kHz); mono centroid `2956 Hz` (power centroid `1089 Hz`, median `546 Hz`, dominant `141.5 Hz`), `-29.1 dB` stereo RMS (`-29.1 dB` mono, peak `-5.0 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +0.99`, fold loss `-0.03 dB` overall (`-0.01 dB` <500 Hz, `-0.02 dB` 500 Hz to 2 kHz, `-0.07 dB` >2 kHz, `-0.02 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `0.1 ms`, `T95 = 462 ms`, dur `1.76 s`, end `-51.4 dB`.
- **`death_metal_run_f2_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Louder, punchier rapid multi-crack metallic hull burst (`10` to `510 ms` peaks, `3.6% <100 Hz`) in pure `corr +1.00` mono, pairing cleanly with `t1`'s longer roll.
  2. **Bass (<500 Hz):** Balanced (`54.8%` below 500 Hz stereo, `54.9%` mono). Measured stereo `54.8%` <500 Hz (`0.0%` <20 Hz, `0.0%` <40 Hz, `3.6%` <100 Hz), `25.5%` in 500 Hz to 2 kHz, `19.7%` >2 kHz (`0.9%` >6 kHz); mono centroid `2856 Hz` (power centroid `1045 Hz`, median `356 Hz`, dominant `120.5 Hz`), `-23.3 dB` stereo RMS (`-23.4 dB` mono, peak `-0.8 dBFS`).
  3. **Mono:** No loss; pure mono. `corr +1.00`, fold loss `-0.01 dB` overall (`-0.00 dB` <500 Hz, `-0.01 dB` 500 Hz to 2 kHz, `-0.02 dB` >2 kHz, `-0.00 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.3 ms` at -20 dB). Peak at `52.8 ms`, `T95 = 259 ms`, dur `1.76 s`, end `-59.8 dB`.
- **Final answer (`death_metal_run_f2`):** **t1 and t2**

### 10. `wep_ithar_pulsar_b_f2` (F2 re-roll: lance_choir (Glasswright pulsar, re-roll: one even beam), 1.6 s)

- **Today baseline:** `wep_ithar_pulsar_b_f2_today0.ogg` (`-16.5 dB`, `60.3/33.5/6.2%`, `T95 158 ms`), `wep_ithar_pulsar_b_f2_today1.ogg` (`-23.8 dB`, `85.6/14.4/0.1%`, `T95 127 ms`).
- **In-game keeper (`godot/audio/clips/wep_ithar_pulsar_0.ogg`):** `-22.4 dB` RMS, `44.3/13.6/42.1%` (<500 / 500-2k / >2k), `cent(mag) 4853 Hz`, `cent(pwr) 2500 Hz`, `T95 613 ms`, dur `1.564 s`.
- **`wep_ithar_pulsar_b_f2_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Collapsed into a `100.0% <500 Hz` `261 Hz` low drone (`cos 0.261` vs `wep_ithar_pulsar_0.ogg`, `0.0%` high shimmer) with a `9.1 dB` volume swell and an audible `+8.14 dB` loop cliff.
  2. **Bass (<500 Hz):** Yes (`100.0%` below 500 Hz stereo, `100.0%` mono). Measured stereo `100.0%` <500 Hz (`0.0%` <20 Hz), `0.0%` in 500 Hz to 2 kHz, `0.0%` >2 kHz; mono centroid `983 Hz`, dominant `261.9 Hz`, `-21.4 dB` stereo RMS (`-21.4 dB` mono, peak `-12.1 dBFS`). Loop seam: `+8.14 dB` end-to-start, spectral cosine `0.982`, spread `9.13 dB`, jump `0.0069`.
  3. **Mono:** No loss; pure mono. `corr +1.00`, fold loss `-0.01 dB` overall.
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `612.4 ms`, `T95 = 1542 ms`, dur `1.60 s`.
- **`wep_ithar_pulsar_b_f2_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Same `99.7% <500 Hz` `259 Hz` low drone (`cos 0.297`, `0.0%` >2 kHz crystal shimmer) with a `7.23 dB` mid-loop pulse instead of a flat, luminous Glasswright beam.
  2. **Bass (<500 Hz):** Yes (`99.7%` below 500 Hz stereo, `99.7%` mono). Measured stereo `99.7%` <500 Hz (`0.0%` <20 Hz), `0.2%` in 500 Hz to 2 kHz, `0.0%` >2 kHz; mono centroid `1976 Hz`, dominant `258.8 Hz`, `-18.3 dB` stereo RMS (`-18.4 dB` mono, peak `-7.4 dBFS`). Loop seam: `+0.56 dB` end-to-start, spectral cosine `0.997`, spread `7.23 dB`, jump `0.0089`.
  3. **Mono:** No loss; pure mono. `corr +1.00`, fold loss `-0.00 dB` overall.
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `732.5 ms`, `T95 = 1515 ms`, dur `1.60 s`.
- **Final answer (`wep_ithar_pulsar_b_f2`):** **keep today's sound**

### 11. `evt_torp_intercept_f2` (F2 re-roll: new: point defense shooting down a torpedo, 1.1 s)

- **Today baseline:** `evt_torp_intercept_f2_today0.ogg` (`-22.3 dB`, `68.2/20.0/11.9%`, `T95 155 ms`).
- **`evt_torp_intercept_f2_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Quick dry point-defense rattle into a sharp, clean warhead detonation that decays naturally to `-57.6 dB` (fixing Wave F's clipped 800 ms peak) in rock-solid mono (`corr +0.96`, `0.0 ms` onset).
  2. **Bass (<500 Hz):** Yes (`83.3%` below 500 Hz stereo, `84.0%` mono). Measured stereo `83.3%` <500 Hz (`0.0%` <20 Hz, `0.1%` <100 Hz), `12.6%` in 500 Hz to 2 kHz, `4.1%` >2 kHz (`1.1%` >6 kHz); mono centroid `3087 Hz` (power centroid `588 Hz`, dominant `402.8 Hz`), `-24.3 dB` stereo RMS (`-24.4 dB` mono, peak `-6.2 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +0.96`, fold loss `-0.08 dB` overall (`-0.04 dB` <500 Hz, `-0.10 dB` 500 Hz to 2 kHz, `-0.84 dB` >2 kHz, `-0.13 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `55.9 ms`, `T95 = 175 ms`, dur `1.08 s`, end `-57.6 dB`.
- **`evt_torp_intercept_f2_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Dark muffled bass pop (`97.2% <500 Hz`, `0.2% >2 kHz`, `cent(mag) 1373 Hz`) lacking crisp point-defense rattle and carrying a lingering low rumble tail (`last20 -20.3 dB`).
  2. **Bass (<500 Hz):** Yes (`97.2%` below 500 Hz stereo, `97.2%` mono). Measured stereo `97.2%` <500 Hz (`0.1%` <20 Hz), `2.6%` in 500 Hz to 2 kHz, `0.2%` >2 kHz; mono centroid `1373 Hz`, dominant `340.7 Hz`, `-22.8 dB` stereo RMS (`-22.8 dB` mono, peak `-1.2 dBFS`).
  3. **Mono:** No loss; pure mono. `corr +1.00`, fold loss `-0.00 dB` overall.
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `12.2 ms`, `T95 = 206 ms`, dur `1.08 s`, end `-20.3 dB`.
- **Final answer (`evt_torp_intercept_f2`):** **t1**

### 12. `imp_energy_sear_more_f2` (F2 re-roll: variety: 2 more takes of keeper imp_energy_sear (D t1, its exact prompt) for the round robin, 0.7 s)

- **Today baseline / In-game keeper (`godot/audio/clips/imp_energy_sear_0.ogg`):** `-25.1 dB` RMS, `69.2/2.9/27.9%` (<500 / 500-2k / >2k), `cent(mag) 6677 Hz`, `cent(pwr) 2279 Hz`, `T95 217 ms`, dur `0.677 s`.
- **`imp_energy_sear_more_f2_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Crisp forged-steel armor clang into a bright crackling plasma arc (`50.7% >2 kHz`, `cos 0.715`, `-24.2 dB` matching keeper level) at `0.0 ms` in rock-solid mono, adding hot sear variety to the round robin.
  2. **Bass (<500 Hz):** No (`16.5%` below 500 Hz stereo, `15.5%` mono). Measured stereo `16.5%` <500 Hz (`0.2%` <20 Hz), `32.8%` in 500 Hz to 2 kHz, `50.7%` >2 kHz (`12.3%` >6 kHz); mono centroid `5224 Hz`, dominant `80.9 Hz`, `-24.2 dB` stereo RMS (`-24.3 dB` mono, peak `-1.2 dBFS`). vs `imp_energy_sear_0.ogg`: spectral cosine `0.715`, `T95` ratio `0.56x`, above-30 Hz deltas `-54/+31/+23%`.
  3. **Mono:** No loss; rock-solid mono. `corr +0.91`, fold loss `-0.19 dB` overall (`-0.45 dB` <500 Hz, `-0.08 dB` 500 Hz to 2 kHz, `-0.18 dB` >2 kHz, `-0.15 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.2 ms` at -30 dB, `11.6 ms` at -20 dB). Peak at `35.2 ms`, `T95 = 121 ms`, dur `0.68 s`, end `-58.8 dB`.
- **`imp_energy_sear_more_f2_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Dead-ringer heavy steel-and-plasma sibling (`cos 0.867`, `T95 298 ms`) in solid mono (`corr +0.87`) that blends seamlessly into `imp_energy_sear_0.ogg`'s round robin after `8 ms` head trim and `-8 dB` level match.
  2. **Bass (<500 Hz):** Yes (`84.4%` below 500 Hz stereo, `87.5%` mono). Measured stereo `84.4%` <500 Hz (`0.1%` <20 Hz, `61.7%` <100 Hz), `1.9%` in 500 Hz to 2 kHz, `13.7%` >2 kHz (`3.8%` >6 kHz); mono centroid `5324 Hz`, dominant `47.0 Hz`, `-16.2 dB` stereo RMS (`-16.5 dB` mono, peak `-1.1 dBFS`). vs `imp_energy_sear_0.ogg`: spectral cosine `0.867`, `T95` ratio `1.37x`, above-30 Hz deltas `+18/-1/-17%`.
  3. **Mono:** No loss; rock-solid mono. `corr +0.87`, fold loss `-0.30 dB` overall (`-0.14 dB` <500 Hz, `-1.31 dB` 500 Hz to 2 kHz, `-1.23 dB` >2 kHz, `-0.93 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`8.9 ms` at -40 dB, `26.9 ms` at -30 dB, `29.7 ms` at -20 dB; trim `8 ms` lead-in). Peak at `72.8 ms`, `T95 = 298 ms`, dur `0.68 s`, end `-31.3 dB`.
- **Final answer (`imp_energy_sear_more_f2`):** **t1 and t2**

### 13. `wep_sunward_autocannon_more_f2` (F2 re-roll: variety: 2 more takes of keeper wep_sunward_autocannon (B t1, its exact prompt) for the round robin, 0.5 s)

- **Today baseline:** `wep_sunward_autocannon_more_f2_today0.ogg` (`-28.1 dB`, `1.9/10.9/87.1%`, `T95 161 ms`).
- **In-game keeper (`godot/audio/clips/wep_sunward_autocannon_0.ogg`):** `-23.3 dB` RMS, `74.8/8.3/16.9%` (<500 / 500-2k / >2k), `cent(mag) 4927 Hz`, `cent(pwr) 1067 Hz`, `T95 92 ms`, dur `0.477 s`.
- **`wep_sunward_autocannon_more_f2_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Tight mechanical cannon punch with a crisp steel action cycle (`cos 0.857` post-40 Hz HP, `0.0 ms` onset, pure mono `corr +0.99`) that matches `wep_sunward_autocannon_0.ogg` cleanly once v2 sub-40 Hz rumble and peak headroom are trimmed.
  2. **Bass (<500 Hz):** Yes (`95.9%` raw due to `62.7% <40 Hz` v2 DC/sub; after mandatory 40 Hz HP: `87.7%` <500 Hz, `5.5%` in 500 Hz to 2 kHz, `6.8%` >2 kHz, `cent(mag) 4617 Hz`, `-11.8 dB` RMS, `T95 147 ms`). Raw stereo `-6.7 dB` RMS, peak `+1.4 dBFS`. vs `wep_sunward_autocannon_0.ogg`: post-HP spectral cosine `0.857` (raw `0.799`).
  3. **Mono:** No loss; pure mono. `corr +0.99`, fold loss `-0.02 dB` overall (`-0.01 dB` <500 Hz, `-0.19 dB` 500 Hz to 2 kHz, `-0.42 dB` >2 kHz, `-0.06 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `9.1 ms`, `T95 = 206 ms` (`147 ms` post-HP), dur `0.48 s`, end `-41.6 dB`.
- **`wep_sunward_autocannon_more_f2_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Compact, punchy autocannon report and mechanical bolt click (`cos 0.850` post-40 Hz HP, `0.0 ms` onset, pure mono `corr +0.98`) pairing tightly with `t1` and the keeper after 40 Hz HP and level trim.
  2. **Bass (<500 Hz):** Yes (`96.1%` raw due to `73.7% <40 Hz` v2 DC/sub; after mandatory 40 Hz HP: `89.2%` <500 Hz, `5.3%` in 500 Hz to 2 kHz, `5.4%` >2 kHz, `cent(mag) 4056 Hz`, `-13.5 dB` RMS, `T95 158 ms`). Raw stereo `-7.7 dB` RMS, peak `+0.9 dBFS`. vs `wep_sunward_autocannon_0.ogg`: post-HP spectral cosine `0.850` (raw `0.623`).
  3. **Mono:** No loss; pure mono. `corr +0.98`, fold loss `-0.05 dB` overall (`-0.00 dB` <500 Hz, `-1.36 dB` 500 Hz to 2 kHz, `-1.47 dB` >2 kHz, `-0.09 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `21.7 ms`, `T95 = 148 ms` (`158 ms` post-HP), dur `0.48 s`, end `-37.6 dB`.
- **Final answer (`wep_sunward_autocannon_more_f2`):** **t1 and t2**

### 14. `wep_sunward_turret_more_f2` (F2 re-roll: variety: 2 more takes of keeper wep_sunward_turret (C t2, its exact prompt) for the round robin, 0.6 s)

- **Today baseline:** `wep_sunward_turret_more_f2_today0.ogg` (`-21.6 dB`, `100.0/0.0/0.0%`, `T95 594 ms`), `wep_sunward_turret_more_f2_today1.ogg` (`-21.8 dB`, `58.9/31.6/9.5%`, `T95 292 ms`).
- **In-game keeper (`godot/audio/clips/wep_sunward_turret_0.ogg`):** `-24.5 dB` RMS, `31.5/51.7/16.8%` (<500 / 500-2k / >2k), `cent(mag) 3186 Hz`, `cent(pwr) 1237 Hz`, `T95 100 ms`, dur `0.597 s`.
- **`wep_sunward_turret_more_f2_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Crisp forged-steel breech crack and midrange bark (`cos 0.872` on channel R, `0.0 ms` onset), but wide stereo drops `-2.2 dB` mids and `-4.0 dB` highs in mono; channel R alone is clean and works as a second single-channel sibling.
  2. **Bass (<500 Hz):** No (`22.7%` below 500 Hz stereo, `34.8%` mono). Measured stereo `22.7%` <500 Hz (`0.0%` <20 Hz), `39.7%` in 500 Hz to 2 kHz, `37.6%` >2 kHz (`1.3%` >6 kHz); mono centroid `3347 Hz`, dominant `791.7 Hz`, `-27.1 dB` stereo RMS (`-29.3 dB` mono, peak `-7.1 dBFS`). vs `wep_sunward_turret_0.ogg`: spectral cosine `0.861` (L `0.853`, R `0.872`), `T95` ratio `1.96x`.
  3. **Mono:** Yes, loses top end, midrange, and attack. `corr +0.19`, fold loss `-2.24 dB` overall (`-0.38 dB` <500 Hz, `-2.17 dB` 500 Hz to 2 kHz, `-4.04 dB` >2 kHz, `-2.63 dB` attack 0 to 60 ms). Single channels: L `-26.8 dB` (pk `-7.5 dBFS`, `19.6/36.9/43.6%`), R `-27.4 dB` (pk `-7.1 dBFS`, `26.3/43.0/30.7%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `0.6 ms`, `T95 = 197 ms`, dur `0.60 s`, end `-43.2 dB`.
- **`wep_sunward_turret_more_f2_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Dead-ringer bright forged-steel deck-gun crack (`cos 0.906` on channel L, `47.8%` midrange bark vs keeper `51.7%`, `0.0 ms` onset), but wide stereo drops `-3.1 dB` of mids in mono; channel L alone is spotless.
  2. **Bass (<500 Hz):** No (`23.6%` below 500 Hz stereo, `29.3%` mono). Measured stereo `23.6%` <500 Hz (`0.0%` <20 Hz), `42.7%` in 500 Hz to 2 kHz, `33.7%` >2 kHz (`0.6%` >6 kHz); mono centroid `2849 Hz`, dominant `146.7 Hz`, `-28.6 dB` stereo RMS (`-31.4 dB` mono, peak `-7.7 dBFS`). vs `wep_sunward_turret_0.ogg`: spectral cosine `0.909` (L `0.906`, R `0.899`), `T95` ratio `2.02x`.
  3. **Mono:** Yes, loses midrange, highs, and attack. `corr +0.07`, fold loss `-2.71 dB` overall (`-1.77 dB` <500 Hz, `-3.11 dB` 500 Hz to 2 kHz, `-2.98 dB` >2 kHz, `-2.66 dB` attack 0 to 60 ms). Single channels: L `-28.5 dB` (pk `-7.7 dBFS`, `20.1/47.8/32.1%`), R `-28.8 dB` (pk `-11.4 dBFS`, `27.4/37.1/35.5%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `7.1 ms`, `T95 = 203 ms`, dur `0.60 s`, end `-37.7 dB`.
- **Final answer (`wep_sunward_turret_more_f2`):** **channel L of t2**

### 15. `wep_eclipse_gsentry_more_f2` (F2 re-roll: variety: 2 more takes of keeper wep_eclipse_gsentry (D t2, its exact prompt) for the round robin, 0.6 s)

- **Today baseline:** `wep_eclipse_gsentry_more_f2_today0.ogg` (`-21.6 dB`, `100.0/0.0/0.0%`, `T95 594 ms`), `wep_eclipse_gsentry_more_f2_today1.ogg` (`-20.5 dB`, `87.0/9.3/3.7%`, `T95 17 ms`).
- **In-game keeper (`godot/audio/clips/wep_eclipse_gsentry_0.ogg`):** `-23.3 dB` RMS, `37.4/18.1/44.5%` (<500 / 500-2k / >2k), `cent(mag) 7103 Hz`, `cent(pwr) 4001 Hz`, `T95 162 ms`, dur `0.597 s`.
- **`wep_eclipse_gsentry_more_f2_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Loud, crisp high-voltage electric snap and compact cold metallic gauss crack (`cos 0.850`, `65.3% >2 kHz`, peak `-1.3 dBFS`) in rock-solid mono once its `68 ms` dead head is trimmed and loudness matched to keeper.
  2. **Bass (<500 Hz):** No (`23.4%` below 500 Hz stereo, `24.4%` mono). Measured stereo `23.4%` <500 Hz (`0.2%` <20 Hz), `11.3%` in 500 Hz to 2 kHz, `65.3%` >2 kHz (`12.8%` >6 kHz); mono centroid `5404 Hz`, dominant `126.7 Hz`, `-32.5 dB` stereo RMS (`-32.7 dB` mono, peak `-1.3 dBFS`). vs `wep_eclipse_gsentry_0.ogg`: spectral cosine `0.850`, `T95` ratio `0.56x`, above-30 Hz deltas `-13/-7/+20%`.
  3. **Mono:** No loss; rock-solid mono. `corr +0.91`, fold loss `-0.21 dB` overall (`-0.03 dB` <500 Hz, `-0.12 dB` 500 Hz to 2 kHz, `-0.29 dB` >2 kHz, `-0.88 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** No, dead head (`68.8 ms` at -40 dB, `71.8 ms` at -30 dB, `84.3 ms` at -20 dB; must trim `68 ms` head in mastering). Peak at `88.2 ms`, `T95 = 91 ms`, dur `0.60 s`, end `-51.7 dB`.
- **`wep_eclipse_gsentry_more_f2_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Matching crisp high-voltage gauss sentry snap (`cos 0.860`, `61.0% >2 kHz`, peak `-1.2 dBFS`) in solid mono (`corr +0.86`) once its `49 ms` dead head is trimmed and level matched.
  2. **Bass (<500 Hz):** No (`27.7%` below 500 Hz stereo, `29.8%` mono). Measured stereo `27.7%` <500 Hz (`0.0%` <20 Hz), `11.3%` in 500 Hz to 2 kHz, `61.0%` >2 kHz (`18.8%` >6 kHz); mono centroid `5551 Hz`, dominant `171.7 Hz`, `-31.9 dB` stereo RMS (`-32.3 dB` mono, peak `-1.2 dBFS`). vs `wep_eclipse_gsentry_0.ogg`: spectral cosine `0.860`, `T95` ratio `0.51x`, above-30 Hz deltas `-8/-7/+14%`.
  3. **Mono:** No loss; rock-solid mono. `corr +0.86`, fold loss `-0.34 dB` overall (`-0.03 dB` <500 Hz, `-0.36 dB` 500 Hz to 2 kHz, `-0.48 dB` >2 kHz, `-0.29 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** No, dead head (`49.6 ms` at -40 dB, `52.3 ms` at -30 dB, `72.0 ms` at -20 dB; must trim `49 ms` head in mastering). Peak at `76.1 ms`, `T95 = 82 ms`, dur `0.60 s`, end `-48.2 dB`.
- **Final answer (`wep_eclipse_gsentry_more_f2`):** **t1 and t2**

### 16. `wep_craft_guns_more_f2` (F2 re-roll: variety: 2 more takes of keeper wep_craft_guns (B t2, its exact prompt) for the round robin, 0.6 s)

- **Today baseline:** `wep_craft_guns_more_f2_today0.ogg` (`-16.5 dB`, `60.3/33.5/6.2%`, `T95 158 ms`).
- **In-game keeper (`godot/audio/clips/wep_craft_guns_0.ogg`):** `-22.5 dB` RMS, `75.9/14.7/9.3%` (<500 / 500-2k / >2k), `cent(mag) 4259 Hz`, `cent(pwr) 779 Hz`, `T95 150 ms`, dur `0.597 s`.
- **`wep_craft_guns_more_f2_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Tight, crisp three-round rapid fighter cannon burst (`T95 186 ms` post-HP vs keeper `150 ms`, `cos 0.742` post-HP) in pure mono (`corr +0.99`), fixing Wave F's single-pop collapse once `25 ms` head is trimmed and 40 Hz HP applied.
  2. **Bass (<500 Hz):** Balanced (`36.3%` raw with `17.0% <40 Hz`; after mandatory 40 Hz HP: `20.4%` <500 Hz, `26.4%` in 500 Hz to 2 kHz, `53.2%` >2 kHz, `cent(mag) 6247 Hz`, `-15.5 dB` RMS, `T95 186 ms`). Raw stereo `-14.6 dB` RMS, peak `+1.0 dBFS`. vs `wep_craft_guns_0.ogg`: post-HP spectral cosine `0.742`.
  3. **Mono:** No loss; pure mono. `corr +0.99`, fold loss `-0.02 dB` overall (`-0.02 dB` <500 Hz, `-0.01 dB` 500 Hz to 2 kHz, `-0.03 dB` >2 kHz, `-0.01 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, within 30 ms (`25.5 ms` at -40 dB, `28.3 ms` at -30 dB, `32.7 ms` at -20 dB; trim `25 ms` head for tight sync). Peak at `71.1 ms`, `T95 = 184 ms` (`186 ms` post-HP), dur `0.60 s`, end `-58.0 dB`.
- **`wep_craft_guns_more_f2_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Fuller, heavier three-round rapid fighter cannon burst (`0.0 ms` onset, `cos 0.822` post-40 Hz HP, pure mono `corr +0.99`) that leads the round robin cleanly once v2's `68.8% <40 Hz` DC/sub and peak headroom are trimmed.
  2. **Bass (<500 Hz):** Yes (`82.8%` raw due to `48.3% <20 Hz` / `68.8% <40 Hz` v2 DC/sub; after mandatory 40 Hz HP: `44.5%` <500 Hz, `22.4%` in 500 Hz to 2 kHz, `33.1%` >2 kHz, `cent(mag) 5763 Hz`, `-12.9 dB` RMS, `T95 249 ms`). Raw stereo `-8.4 dB` RMS, peak `+1.2 dBFS`. vs `wep_craft_guns_0.ogg`: post-HP spectral cosine `0.822`.
  3. **Mono:** No loss; pure mono. `corr +0.99`, fold loss `-0.01 dB` overall (`-0.01 dB` <500 Hz, `-0.01 dB` 500 Hz to 2 kHz, `-0.05 dB` >2 kHz, `-0.01 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `154.9 ms`, `T95 = 260 ms` (`249 ms` post-HP), dur `0.60 s`, end `-55.1 dB`.
- **Final answer (`wep_craft_guns_more_f2`):** **t1 and t2**

---

## Group 3: Wave M2 Two-Track Music Test (2 IDs, 2 Songs + 2 Stem Zips)

### Baseline Check: Today's In-Game Glasswrights and Chorus Tracks

- `godot/music/tracks/fac_ithar.ogg` (`59.8 s`, `-20.3 dB` RMS, `86.7/13.3/0.0%`, centroid `828 Hz`): flat ambient sci-fi synth pad with zero rhythmic drive or acoustic sparkle. `mus_ithar_loop_a` is a night-and-day leap in acoustic craft and Glasswright identity.
- `godot/music/tracks/fac_chorus.ogg` (`200.6 s`, `-17.9 dB` RMS, `29.7% <40 Hz`, `77.4% <100 Hz`, `99.4/0.6/0.0%`, centroid `490 Hz`): slow droning synth bass with a repetitive electronic thud. `mus_chorus_loop_a`'s real frame drums are far more organic, though its missing tonal layers keep it from shipping as a stem pair yet.

### 17. `mus_ithar_loop_a` (M2_test: battle music loop a for ithar fights, 88 BPM, 24 bars = 65.455 s, with stems)

- **Today baseline:** `godot/music/tracks/fac_ithar.ogg` (`59.8 s`, `-20.3 dB`, centroid `828 Hz`).
- **`mus_ithar_loop_a_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Gorgeous Glasswrights acoustic palette (harp, celesta, glass harmonica, zero vocals) with an intact tonal calm mix, but fails the M2 gate on three counts: `30.5 ms` short of the bar grid (`STEM LOOP CHECK FAIL`), a jarring `21.2 dB` wrap cliff from bar 24 (`-17.1 dB`) back to a quiet solo-harp opening (`-38.3 dB`), and silent drums for the first 10 s leaving only `0.99 dB` first-third (`1.27 dB` overall) calm-to-intense contrast.
  2. **Faction fit & tonal balance:** Strong Glasswrights fit. Luminous F# minor harp/celesta arpeggios and glass harmonica chords with zero mud and zero harshness (`0.2% <40 Hz`, `19.2%` 40 to 120 Hz, `68.1% <500 Hz`, `31.0%` 500 Hz to 2 kHz, `0.9% >2 kHz`, centroid `1599 Hz`, RMS `-18.6 dB`, peak `-1.1 dBFS`).
  3. **Calm/intense split & >=1 dB contrast:** Live stems: `other` (`-20.2 dB`), `drums` (`-27.3 dB`), `piano` (`-38.9 dB`); silent: `bass` (`-94.7 dB`), `vocals` (`-131.7 dB`), `guitar` (`-137.8 dB`). Offset `1,203` samples (`25.1 ms`), aligned rebuild residual `-24.0 dB`. Calm (`other + piano`, `-19.9 dB`) keeps every tonal part cleanly with seamless `0.00 dB`-dip switches at all four quarter points, **but** `drums` is dead silent (`-240 dB`) for the first `10 s` and drops to `-55.9` / `-65.0 dB` in mid-track pockets, giving only `1.27 dB` overall contrast and failing the `1.0 dB` floor in the opening third (thirds: `0.99 / 1.03 / 1.49 dB`).
  4. **Bar-grid loop join (no click):** Raw file is `3,140,352` samples (`65.4240 s`) vs exact 24-bar `n_grid = 3,141,818` (`65.4545 s`, diff `-30.5 ms`), failing `stem_loop_check.py`'s `-1 ms to +50 ms` check. Autocorrelation confirms dead-accurate `88.0 BPM` (`1 beat = 0.68 s`, `1 bar = 2.73 s`, `8 bars = 21.82 s`), **but** 5 s RMS climbs `14.9 dB` (`-31.1 dB` to `-16.2 dB`: `[-31.1, -26.3, -22.0, -22.6, -18.1, -20.1, -18.4, -17.9, -16.2, -16.8, -17.0, -16.6, -16.9]`). Listening to `wrap_intense.wav` and `wrap_calm.wav` confirms no sample click with the 25 ms guard, but a jarring `21.2 dB` musical cliff where the full bar-24 ensemble drops abruptly to quiet solo harp at bar 1. (Bars 9 to 24, `21.82` to `65.45 s`, hold flat at `-18.4` to `-16.2 dB`, confirming the arrangement only broke on its intro ramp.)
- **Final answer (`mus_ithar_loop_a`):** **re-roll**

### 18. `mus_chorus_loop_a` (M2_test: battle music loop a for chorus fights, 76 BPM, 24 bars = 75.789 s, with stems)

- **Today baseline:** `godot/music/tracks/fac_chorus.ogg` (`200.6 s`, `-17.9 dB`, centroid `490 Hz`).
- **`mus_chorus_loop_a_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Nails the eerie organic frame-drum heartbeat, `76.0 BPM` bar grid, and rock-solid `0.7 dB` energy stability with a smooth click-free wrap, but `music_v2` omitted the prompted contrabassoon reeds and bone-like string harmonics so `drums` took almost the entire track, leaving `calm` as a bare `100% <500 Hz` / `99.4% <100 Hz` sub-heartbeat ghost that cannot stand alone as music (plus `+50.5 ms` MP3 length tripped `stem_loop_check.py`).
  2. **Faction fit & tonal balance:** Halfway on theme. Zero metal, zero glass, zero sea feel, and zero vocals, and the deep heartbeat frame drums sound genuinely alien and unnerving. However, the full mix is `99.2% <500 Hz` (`87.3%` in 40 to 120 Hz, `0.7%` 500 Hz to 2 kHz, `0.1% >2 kHz`, centroid `837 Hz`, RMS `-21.9 dB`, peak `-6.3 dBFS`): the contrabassoon call, bowed basses, and bone-like harmonics never materialized above the drums.
  3. **Calm/intense split & >=1 dB contrast:** Live stems: `drums` (`-25.1 dB`) and `other` (`-27.1 dB`); silent: `bass` (`-106.2 dB`), `piano` (`-141.7 dB`), `guitar` (`-240.0 dB`), `vocals` (`-240.0 dB`). Offset `1,203` samples (`25.1 ms`), aligned rebuild residual `-27.0 dB`. Contrast is `5.20 dB` overall (thirds `5.40 / 5.06 / 5.14 dB`) with `0.00` to `0.02 dB` switch dips, **but** listening to `calm.wav` fails the review gate: `other` is `99.4% <100 Hz` / `100.0% <500 Hz` / `0.0%` mids / `0.0%` highs (`cent 209 Hz`), sounding like a hollow sub-bass thump with faint frame-drum bleed in the final bars and zero standalone musical content.
  4. **Bar-grid loop join (no click):** Raw file is `3,640,320` samples (`75.8400 s`) vs exact 24-bar `n_grid = 3,637,895` (`75.7895 s`, diff `+50.5 ms`), failing `stem_loop_check.py`'s `-1 ms to +50 ms` ceiling by `0.5 ms`. By ear and autocorrelation, the bar grid is rock-solid (`76.0 BPM`: `1 beat = 0.79 s`, `1 bar = 3.16 s`, `8 bars = 25.26 s`), 5 s RMS span across all 75.8 s is an exemplary `0.7 dB` (`-22.1` to `-21.4 dB`), and `wrap_intense.wav` joins cleanly across the downbeat with zero stumble and zero click.
- **Final answer (`mus_chorus_loop_a`):** **re-roll**

---

## Wave M2 Go / Change Verdict: CHANGE (Do Not Run All 30 M2 Tracks Yet)

**Answer: CHANGE.** The two-track M2_test paid for itself immediately: both tracks proved that ElevenLabs `music_v2` hits exact requested BPMs (`88.0 BPM` and `76.0 BPM`) and respects `65` to `76 s` durations without 5-second fade-outs, and both showed that `codex/issue-2039`'s M2 timing/length/word-trap fixes are in place. However, running the remaining 30 M2 tracks unchanged would hit three avoidable failures caught by this test:

1. **Widen `stem_loop_check.py`'s MP3 length tolerance before running M2.** Both `mus_ithar_loop_a` (`-30.5 ms`) and `mus_chorus_loop_a` (`+50.5 ms`) hit their exact BPM bar grids down to `0.01 s` by autocorrelation, yet **both auto-failed** `stem_loop_check.py`'s `-1 ms to +50 ms` check because ElevenLabs `music_v2` quantizes MP3 output in 24 ms frames. Widen the allowed source-vs-grid window to `-50 ms to +120 ms` (still padding/trimming to exact `n_grid` samples and applying the 25 ms click guard), and add a 5 s RMS-span / end-to-start level-cliff check (`<=6 dB`) so a 21 dB intro ramp like `mus_ithar_loop_a` is caught automatically.
2. **Restore "every part plays in every bar from bar 1 beat 1, no intro build, no fade-in" on all 24-bar faction loops.** Notice that `mus_boss_1` and `mus_map_*` in `elevenlabs_gate3.json` kept the M1-proven phrasing (`"every part plays in every bar from the first to the last at even energy and density"`), whereas `mus_ithar_loop_a/b`, `mus_chorus_loop_a/b`, and `mus_deathless_loop_a/b` shortened it to `"Start at full texture"`, and `mus_ithar_loop_a` immediately reverted to a 15 dB intro build with 10 s of silent drums. Put the explicit no-intro-build wording back on every looping track.
3. **Decide stem split vs in-game calm treatment for Glasswrights and Chorus before spending on their 4 loops (8 steps):**
   - **Sunward, Directorate, Hullbreakers, Eclipse, Boss, Nemesis (strong percussion + rich melodic beds):** Ready to run with stem splits once Changes 1 and 2 are in.
   - **Glasswrights (`ithar`) and Chorus (`chorus`):** This test confirmed our M1 warning. On Glasswrights, light timpani only produced `1.27 dB` total contrast (`0.99 dB` in the opening third); on Chorus, frame-drum emphasis crowded out the contrabassoon and strings, leaving `calm` empty (`100% <500 Hz`). Pick one path before launching M2:
     - **Option A (Recommended, lowest risk, saves ~4,000 credits):** Run `mus_ithar_loop_a/b` and `mus_chorus_loop_a/b` **without stem zips** (`stems: false`), with Chorus prompts rewritten to foreground bowed cellos, contrabassoon melody, and eerie string harmonics above softer frame drums, and drive their calm state in Godot (`music_player.gd` gentle low-pass + level drop) so Glasswrights stays luminous/delicate and Chorus never loses its tonal bed.
     - **Option B (Keep stem splits on all 6 factions):** Rewrite both prompts (stronger continuous timpani/mallet pulse from bar 1 beat 1 on Glasswrights; prominent bowed cellos + contrabassoon + high string harmonics in every bar above restrained frame drums on Chorus) and re-run the 2-track `M2_test` first before unlocking full M2.
