# Wave C Sound Ear Audit (Issues 1752 and 1891)

Listening and mono fold-down audit of all 49 Wave C ElevenLabs takes (`out_20261123_134355_15807/out_new/elevenlabs/`) across all 25 re-rolled sound ids, judged directly against Ryan's Wave B notes, the rejected Wave B takes (`out_20261123_114446_25233/out_new/elevenlabs/`), and today's game clips (`out_new/listen/audio/*_today*.ogg`). Every take was listened to directly in stereo, measured with a Python and ffmpeg FFT pass (44.1 kHz, power-weighted bands, stereo-to-mono band loss in dB, DC offset, onset and T95 timing, plus 1-second window checks on `amb_bridge_bed_t1.mp3`), and all 27 wide or borderline takes (`corr < 0.72` or mid/high mono drop > 1.2 dB) were folded to mono `(L + R) / 2` and listened to again in mono.

## Bottom Line (Read Before Listening)

- **Scorecard: 25 keeps, 24 rejects** across 49 takes (25 ids).
  - **IDs with a pick: 19 of 25** (14 clean mono picks, plus 5 borderline-mono or dark-leaning picks flagged below for Ryan's headphones check: `wep_eclipse_doom_charge_t1.mp3`, `dmg_breach_vent_t1.mp3`, `death_ithar_shatter_t2.mp3`, `death_eclipse_shear_t2.mp3`, and `evt_fleet_warp_in_t2.mp3`).
  - **IDs still needing a re-roll: 6 of 25** (`wep_directorate_picket`, `wep_eclipse_gsentry`, `imp_metal_light`, `imp_energy_sear`, `imp_las`, `dmg_shield_burnout`).
- **Six big Wave C findings:**
  1. **`amb_bridge_bed_t1.mp3` is clean (KEEP):** Zero voice anywhere in the 20 s clip. Removing `"no vocals"` and `"command bridge"` completely cured Wave B's 7 to 11 s radio-voice leak. RMS stays flat between -38.3 dB and -35.5 dB across all twenty 1-second slices (2.8 dB spread vs 17.0 dB in Wave B), 300 Hz to 3 kHz energy stays flat at 3.7% to 9.0% (vs 63.4% in Wave B), and the loop seam matches within 0.23 dB (`-37.5 dB` vs `-37.7 dB`).
  2. **Major Ryan fixes landed cleanly:** Sunward shell guns (`wep_sunward_turret_t2.mp3`, `wep_sunward_hbattery_t2.mp3` and `t1.mp3`) now have the bright breech crack and iron barrel ring in dual-mono; `wep_eclipse_doom_t2.mp3` (and `t1.mp3`) delivers a fierce crackling dark lightning arc for the Corona arc look; `wep_chorus_spore_cloud_t2.mp3` and `wep_chorus_sporeb_t1.mp3` read as centered dry organic pods with zero electrical static; `wep_craft_bombs_t2.mp3` (and `t1.mp3`) reads clearly as clamp release plus thruster ignition; `dmg_breach_shear_metal_t1.mp3` genuinely buckles and rips over 1.4 s; `imp_obsidian_eclipse_t1.mp3`, `imp_acid_on_metal_t1.mp3`, `wep_hullbreaker_junk_gun_t2.mp3`, `wep_torp_eject_t1.mp3`, and `death_sunward_magazine_t2.mp3` all lock cleanly in mono.
  3. **Three of four metal hits still need a re-roll (`imp_metal_light`, `imp_energy_sear`, `imp_las`):** Only `imp_acid_on_metal_t1.mp3` nailed both the clear armored-steel clang first and clean mono. The other three omitted `"heard close and centered"` from their prompts, and `imp_energy_sear` and `imp_las` used `"hiss"` (plus banned word `"ping"` on `imp_las`). Result: `imp_energy_sear` and `imp_las` swung into thin uncorrelated >2 kHz hiss (`corr -0.02` to `0.24`), and `imp_metal_light_t1.mp3` gets the steel clang right in stereo but drops -2.41 dB of its clang midrange in mono (`corr 0.30`).
  4. **Two light point-defense weapons stayed trapped in the basement (`wep_directorate_picket`, `wep_eclipse_gsentry`):** Both `wep_directorate_picket` takes are still 97.3% to 99.0% below 500 Hz, and both `wep_eclipse_gsentry` takes came back whisper-quiet (-40.7 dB and -47.0 dB RMS) and 96.2% to 97.2% below 500 Hz. `"Much lighter than a main cannon"` plus `"hollow mid-low"` keeps pulling v3 into tiny muffled taps.
  5. **`dmg_shield_burnout` swung from thin fizz to wide low hum:** Both Wave C takes failed mono (`corr -0.04` and `0.31`) while `"transformer buzz"` pulled 86.7% to 93.6% of energy below 500 Hz (and `t2` peaks at 600 ms on a 600 ms clip).
  6. **Mastering notes for the keepers:** High-pass at 40 Hz on `wep_sunward_turret_t2.mp3`, `wep_sunward_hbattery_t2.mp3`, `wep_hullbreaker_junk_gun_t2.mp3`, and `dmg_breach_shear_metal_t1.mp3` (v2 DC offset / sub-20 Hz rumble). Trim dead heads before wiring: `wep_craft_bombs_t2.mp3` (138 ms), `death_eclipse_shear_t2.mp3` (52 ms), `wep_eclipse_doom_charge_t1.mp3` (47 ms), `dmg_breach_shear_metal_t1.mp3` (32 ms), `wep_eclipse_doom_t2.mp3` (29 ms), `dmg_breach_vent_t1.mp3` (20 ms), `imp_obsidian_eclipse_t1.mp3` (9 ms), and `imp_acid_on_metal_t1.mp3` (9 ms). Loop `wep_eclipse_doom_t2.mp3`'s steady crackling core (0.15 to 0.85 s) in Godot for arcs longer than ~0.9 s (`T95 = 816 ms`).

---

## Per-Take Verdict, Bass Check, Mono Check, and Pick (25 IDs, 49 Takes)

### 1. `wep_sunward_turret` (Ryan ask: bright breech crack and barrel ring; vs `today0` boomLow, `today1` shellBang)

- **`wep_sunward_turret_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject `wep_sunward_turret_t1.mp3`: very quiet (-31.5 dB RMS, 17 dB softer than `t2`) and still muffled like Wave B `t1` (99.0% below 500 Hz), missing the bright breech crack Ryan asked for and losing midrange bark to today's `shellBang` (`today1`, 31.6% mid).
  2. **Bass (<500 Hz):** Yes, bass trap. Measured 94.1% below 500 Hz raw (91.2% in 30 to 500 Hz), 2.8% in 500 Hz to 2 kHz, 3.1% above 2 kHz (centroid 225 Hz, 1.5% below 20 Hz, dominant 30 Hz).
  3. **Mono:** Pure dual-mono (corr 1.00, 0.00 dB overall, -0.02 dB mid, -0.03 dB above 2 kHz, 0.00 dB attack); mono is clean, lack of bright breech snap is the fail.
- **`wep_sunward_turret_t2.mp3` -> KEEP (high-pass 40 Hz for DC offset).**
  1. **Verdict:** Keep `wep_sunward_turret_t2.mp3`: delivers the immediate bright forged-steel breech crack and crisp ringing iron barrel tone Ryan asked for, a night-and-day fix over Wave B `t1`/`t2` (99.0% / 94.8% below 500 Hz) and far more physical than today's flat `boomLow` and `shellBang` (`today0`, `today1`).
  2. **Bass (<500 Hz):** No. Measured 42.8% below 500 Hz raw (32.9% in 30 to 500 Hz after stripping 8.7% below 20 Hz / +0.0106 DC offset), 42.8% in 500 Hz to 2 kHz (50.2% above 30 Hz), 14.3% above 2 kHz (centroid 1042 Hz, -14.8 dB RMS, fast `T95 = 97 ms`).
  3. **Mono:** Pure dual-mono (corr 1.00, 0.00 dB overall, 0.00 dB mid, -0.01 dB above 2 kHz, 0.00 dB attack); keeps full breech crack and metallic ring on one speaker.
- **ID Pick (`wep_sunward_turret`):** Keep `wep_sunward_turret_t2.mp3` (high-pass at 40 Hz in mastering).

### 2. `wep_sunward_hbattery` (Ryan ask: bright breech crack and barrel ring; vs `today0` boomLow, `today1` shellBang)

- **`wep_sunward_hbattery_t1.mp3` -> KEEP (alternate; clean DC).**
  1. **Verdict:** Keep `wep_sunward_hbattery_t1.mp3` as a strong round-robin partner: huge main-battery blast with an unmistakable bright propellant crack and metallic steel recoil clank/ring, completely curing Wave B `t1`/`t2`'s sub-bass mud (99.5% / 96.4% below 500 Hz) and outclassing today's `boomLow` and `shellBang` (`today0`, `today1`).
  2. **Bass (<500 Hz):** No. Measured 72.4% below 500 Hz (70.5% above 30 Hz), 10.4% in 500 Hz to 2 kHz, 17.2% above 2 kHz (centroid 1036 Hz, -11.0 dB RMS, 1.6% below 20 Hz, peak 34 ms, `T95 = 263 ms`).
  3. **Mono:** Pure dual-mono (corr 0.99, -0.02 dB overall, -0.02 dB mid, -0.08 dB above 2 kHz, -0.02 dB attack); zero mono loss.
- **`wep_sunward_hbattery_t2.mp3` -> KEEP (lead pick; high-pass 40 Hz for DC offset).**
  1. **Verdict:** Keep `wep_sunward_hbattery_t2.mp3`: hits harder and earlier (`peak 7 ms` vs `34 ms` on `t1`, -8.9 dB RMS) with a fuller forged-iron midrange barrel ring and huge bright propellant crack, fixing Wave B's mud so five staggered shots will punch cleanly without blurring together, far ahead of today's `boomLow` and `shellBang` (`today0`, `today1`).
  2. **Bass (<500 Hz):** No. Measured 69.0% below 500 Hz raw (65.9% in 30 to 500 Hz after stripping 4.7% below 20 Hz / +0.0221 DC offset), 19.2% in 500 Hz to 2 kHz (21.2% above 30 Hz), 11.8% above 2 kHz (centroid 724 Hz, `T95 = 296 ms`).
  3. **Mono:** Pure dual-mono (corr 1.00, -0.01 dB overall, -0.01 dB mid, -0.02 dB above 2 kHz, 0.00 dB attack); rock-solid on one speaker.
- **ID Pick (`wep_sunward_hbattery`):** Keep `wep_sunward_hbattery_t2.mp3` (high-pass at 40 Hz; `wep_sunward_hbattery_t1.mp3` is ready as a second take).

### 3. `wep_torp_eject` (Wave B reject; vs `today0` whoosh, `today1` ionCharge)

- **`wep_torp_eject_t1.mp3` -> KEEP (optional gentle top tame above 6 kHz).**
  1. **Verdict:** Keep `wep_torp_eject_t1.mp3`: crisp heavy steel rail slide, tight pneumatic air release burst, and solid mechanical latch clunk before ignition, curing both Wave B `t1`'s muffled puff (96.3% below 500 Hz) and Wave B `t2`'s mono collapse, and easily beating today's generic `whoosh` and synthy `ionCharge` (`today0`, `today1`).
  2. **Bass (<500 Hz):** No (very bright mechanical detail). Measured 1.8% below 500 Hz, 2.8% in 500 Hz to 2 kHz, 95.4% above 2 kHz (centroid 7790 Hz, -18.8 dB RMS, 0.0% below 20 Hz, `T95 = 249 ms` fits inside the 0.30 s `CHARGE_LEAD`).
  3. **Mono:** Passes mono cleanly (corr 0.64, -0.87 dB overall, -0.62 dB mid, -0.88 dB above 2 kHz, -0.51 dB attack); verified by ear in mono, rail slide and pneumatic eject stay sharp and purposeful.
- **`wep_torp_eject_t2.mp3` -> REJECT (mono fail + late peak).**
  1. **Verdict:** Reject `wep_torp_eject_t2.mp3`: weightier clunk in stereo than `t1`, but just like Wave B `t2` (corr 0.24) it hollows out when folded to mono and peaks at 479 ms of a 500 ms clip (too late for the 0.30 s `CHARGE_LEAD`).
  2. **Bass (<500 Hz):** No. Measured 19.4% below 500 Hz, 5.5% in 500 Hz to 2 kHz, 75.1% above 2 kHz (centroid 2634 Hz, -16.0 dB RMS, 0.2% below 20 Hz).
  3. **Mono:** Fails mono. Very wide stereo (corr 0.24) drops -2.09 dB overall, -2.76 dB in 500 Hz to 2 kHz, -2.08 dB above 2 kHz, and -2.66 dB on the attack; audibly thins and loses rail snap in mono.
- **ID Pick (`wep_torp_eject`):** Keep `wep_torp_eject_t1.mp3`.

### 4. `evt_pass_by_slug` (Wave B reject; no clip today)

- **`evt_pass_by_slug_t1.mp3` -> REJECT (top-end mono drop + quiet).**
  1. **Verdict:** Reject `evt_pass_by_slug_t1.mp3`: sharper close-pass Doppler zip than Wave B `t1`/`t2` (99.4% / 95.9% below 500 Hz), but 8.4 dB quieter than `t2` (-25.0 dB RMS) and loses over 2 dB of its top air zip in mono (no baseline clip today).
  2. **Bass (<500 Hz):** No. Measured 82.6% below 500 Hz, 8.1% in 500 Hz to 2 kHz, 9.2% above 2 kHz (centroid 732 Hz, 0.1% below 20 Hz).
  3. **Mono:** Softens top end (corr 0.66, -0.84 dB overall, -1.27 dB mid, -2.29 dB above 2 kHz, -0.85 dB attack); beaten clearly by `t2`'s mono lock and presence.
- **`evt_pass_by_slug_t2.mp3` -> KEEP (dark-leaning; add +3 dB presence lift above 1 kHz in mastering).**
  1. **Verdict:** Keep `evt_pass_by_slug_t2.mp3`: fast, loud (-16.6 dB RMS), immediate close-pass heavy shell whoosh with a tight pressure thump at closest approach and crisp air rush, a clear step up from Wave B `t1`/`t2`'s muffled low thuds (centroids 86 Hz / 157 Hz; no baseline clip today).
  2. **Bass (<500 Hz):** Borderline yes on raw ratio, with audible midrange and top air rush. Measured 86.8% below 500 Hz, 8.0% in 500 Hz to 2 kHz, 5.2% above 2 kHz (centroid 518 Hz, 0.9% below 20 Hz, `T95 = 301 ms`).
  3. **Mono:** Passes mono cleanly (corr 0.92, -0.18 dB overall, -1.09 dB mid, -0.89 dB above 2 kHz, -0.16 dB attack); keeps its fast close-pass punch intact on one speaker.
- **ID Pick (`evt_pass_by_slug`):** Keep `evt_pass_by_slug_t2.mp3` (add a light +3 dB presence lift in mastering).

### 5. `wep_directorate_picket` (Wave B reject; vs `today0` gunFlak)

- **`wep_directorate_picket_t1.mp3` -> REJECT (bass trap).**
  1. **Verdict:** Reject `wep_directorate_picket_t1.mp3`: still a quiet (-26.7 dB RMS), muffled low tap with almost no bright point-defense plasma-arc snap, barely moving past Wave B `t1` (99.8% below 500 Hz) and losing clarity badly against today's `gunFlak` (`today0`, 50.8% mid, 21.2% >2 kHz).
  2. **Bass (<500 Hz):** Yes, severe bass trap. Measured 97.3% below 500 Hz, 2.0% in 500 Hz to 2 kHz, 0.7% above 2 kHz (centroid 178 Hz, 0.2% below 20 Hz, dominant 85.4 Hz).
  3. **Mono:** Pure dual-mono (corr 1.00, -0.01 dB overall, -0.04 dB mid, -0.10 dB above 2 kHz, 0.00 dB attack); completely dull on every speaker.
- **`wep_directorate_picket_t2.mp3` -> REJECT (severe bass trap).**
  1. **Verdict:** Reject `wep_directorate_picket_t2.mp3`: even darker and quieter (-27.1 dB RMS) muffled low pop than `t1`, repeating Wave B `t2`'s 99.9% bass trap and unreadable as point-defense laser/plasma fire next to today's `gunFlak` (`today0`).
  2. **Bass (<500 Hz):** Yes, severe bass trap. Measured 99.0% below 500 Hz, 0.6% in 500 Hz to 2 kHz, 0.4% above 2 kHz (centroid 137 Hz, 0.2% below 20 Hz, dominant 75.0 Hz).
  3. **Mono:** Dual-mono (corr 0.98, -0.04 dB overall, -0.55 dB mid and high), with virtually no energy above 500 Hz.
- **ID Pick (`wep_directorate_picket`):** Neither, re-roll. Drop `"plasma tick"` and `"much lighter than a main cannon"` (which keep yielding muffled low taps on v3); prompt a crisp high-voltage electrical arc snap and tight dry spark discharge with bright upper-midrange bite and no low thump.

### 6. `wep_hullbreaker_junk_gun` (Wave B reject; vs `today0` boomLow, `today1` shellBang)

- **`wep_hullbreaker_junk_gun_t1.mp3` -> REJECT (hard mono fail).**
  1. **Verdict:** Reject `wep_hullbreaker_junk_gun_t1.mp3`: crunchy, rattling scrap-built turret crack in stereo that fixes Wave B `t1`'s 97.0% bass trap, but collapses and hollows out badly when folded to mono, losing cleanly to `t2` and today's punchier `shellBang` (`today1`).
  2. **Bass (<500 Hz):** No. Measured 28.1% below 500 Hz raw (11.9% in 30 to 500 Hz after stripping 14.4% below 20 Hz), 40.8% in 500 Hz to 2 kHz, 31.0% above 2 kHz (centroid 1958 Hz, -22.7 dB RMS).
  3. **Mono:** Hard fail. Near-zero correlation (corr 0.07) drops -2.73 dB overall, -1.90 dB mid, -2.38 dB above 2 kHz, and -3.04 dB on the attack; audibly guts the turret punch in mono.
- **`wep_hullbreaker_junk_gun_t2.mp3` -> KEEP (standout Wave C fix; high-pass 40 Hz).**
  1. **Verdict:** Keep `wep_hullbreaker_junk_gun_t2.mp3`: rough, bright metallic scrap crack with loose rattling iron plates and a clanking bolt over a firm punch (-15.4 dB RMS, `T95 = 178 ms`), completely curing Wave B `t1`/`t2`'s 97% bass trap and DC offset and crushing today's generic `boomLow` and `shellBang` (`today0`, `today1`).
  2. **Bass (<500 Hz):** No. Ideal gritty scrap balance: 29.2% below 500 Hz raw (12.0% in 30 to 500 Hz after stripping 9.1% below 20 Hz), 36.6% in 500 Hz to 2 kHz (45.5% above 30 Hz), 34.2% above 2 kHz (42.4% above 30 Hz, centroid 2071 Hz).
  3. **Mono:** Passes mono cleanly (corr 0.90, -0.21 dB overall, -0.19 dB mid, -0.20 dB above 2 kHz, -0.08 dB attack); keeps every bit of its clanking scrap-gun character on one speaker.
- **ID Pick (`wep_hullbreaker_junk_gun`):** Keep `wep_hullbreaker_junk_gun_t2.mp3` (high-pass at 40 Hz in mastering).

### 7. `wep_chorus_spore_cloud` (Ryan ask: rejected in Wave B, now close and centered; vs `today0` gunFlak)

- **`wep_chorus_spore_cloud_t1.mp3` -> KEEP (alternate; lift gain ~7 dB).**
  1. **Verdict:** Keep `wep_chorus_spore_cloud_t1.mp3` as a lighter brittle-husk alternate: reads as a dry centered woody pod pop followed by a coarse rattle of hard seed husks, completely fixing Wave B's white-noise air-hose hiss (92.3% to 98.2% >2 kHz, corr -0.12 / 0.17) and far more distinctly Chorus than today's `gunFlak` (`today0`), just quieter (-27.3 dB RMS) than `t2`.
  2. **Bass (<500 Hz):** No. Measured 21.3% below 500 Hz, 15.6% in 500 Hz to 2 kHz, 63.1% above 2 kHz (centroid 4597 Hz, 0.2% below 20 Hz, `T95 = 323 ms`).
  3. **Mono:** Passes mono cleanly (corr 0.69, -0.79 dB overall, -0.17 dB mid, -1.08 dB above 2 kHz, -0.30 dB attack); verified by ear in mono, woody pop and dry seed rattle stay centered and intact.
- **`wep_chorus_spore_cloud_t2.mp3` -> KEEP (lead pick).**
  1. **Verdict:** Keep `wep_chorus_spore_cloud_t2.mp3`: 9 dB louder (-18.4 dB RMS), punchier, and more centered than `t1`, opening with a firm dry woody pod thump and crisp brittle seed-husk scatter (`T95 = 173 ms`), completely curing Wave B's hiss and mono collapse and clearly beating today's generic `gunFlak` (`today0`).
  2. **Bass (<500 Hz):** No. Measured 81.3% below 500 Hz, 7.5% in 500 Hz to 2 kHz, 11.2% above 2 kHz (centroid 711 Hz, 0.0% below 20 Hz); solid organic pod body with clear dry husk scatter.
  3. **Mono:** Rock-solid mono (corr 0.89, -0.24 dB overall, -0.06 dB mid, -0.64 dB above 2 kHz, -0.11 dB attack); zero loss on one speaker.
- **ID Pick (`wep_chorus_spore_cloud`):** Keep `wep_chorus_spore_cloud_t2.mp3` (`t1` works as a lighter brittle alternate).

### 8. `wep_chorus_sporeb` (Ryan ask: Wave B sounded like electrical static; vs `today0` laserSmall)

- **`wep_chorus_sporeb_t1.mp3` -> KEEP (lead pick; light +2 to 3 dB upper-mid lift optional).**
  1. **Verdict:** Keep `wep_chorus_sporeb_t1.mp3`: completely cures Wave B `t2`'s electrical static, delivering a small dry hollow bone-pod pop with a brief pressurized puff and brittle woody rattle (-19.6 dB RMS, `T95 = 78 ms`) right at strike-craft scale and miles ahead of today's arcade `laserSmall` pew (`today0`).
  2. **Bass (<500 Hz):** Borderline yes on raw ratio, with clear woody pop and rattle by ear. Measured 88.1% below 500 Hz, 6.4% in 500 Hz to 2 kHz, 5.5% above 2 kHz (centroid 506 Hz, 0.3% below 20 Hz).
  3. **Mono:** Rock-solid mono (corr 0.95, -0.12 dB overall, -0.22 dB mid, -1.34 dB above 2 kHz, -0.26 dB attack); keeps its crisp hollow pod pop intact on one speaker.
- **`wep_chorus_sporeb_t2.mp3` -> REJECT (bass trap).**
  1. **Verdict:** Reject `wep_chorus_sporeb_t2.mp3`: also free of Wave B's electrical static, but much duller and quieter (-24.0 dB RMS) than `t1`, reading almost purely as a soft muffled low bloop without `t1`'s brittle bone-pod rattle.
  2. **Bass (<500 Hz):** Yes, bass trap. Measured 99.0% below 500 Hz, 0.7% in 500 Hz to 2 kHz, 0.3% above 2 kHz (centroid 226 Hz, 0.0% below 20 Hz, dominant 231.7 Hz).
  3. **Mono:** Pure dual-mono (corr 1.00, 0.00 dB overall, -0.01 dB mid, -0.02 dB above 2 kHz), just far too dull compared with `t1`.
- **ID Pick (`wep_chorus_sporeb`):** Keep `wep_chorus_sporeb_t1.mp3`.

### 9. `wep_eclipse_gsentry` (Wave B reject; vs `today0` boomLow, `today1` railStrike)

- **`wep_eclipse_gsentry_t1.mp3` -> REJECT (whisper-quiet + bass trap).**
  1. **Verdict:** Reject `wep_eclipse_gsentry_t1.mp3`: fixes Wave B `t1`'s severe out-of-phase collapse (corr -0.40 -> 0.99), but came back whisper-quiet (-40.7 dB RMS, 20 dB below today's `railStrike`) and muffled below 500 Hz, reading as a tiny dull tap instead of a crisp Eclipse point-defense emitter.
  2. **Bass (<500 Hz):** Yes, bass trap. Measured 97.2% below 500 Hz, 1.4% in 500 Hz to 2 kHz, 1.4% above 2 kHz (centroid 158 Hz, 0.2% below 20 Hz, dominant 48.3 Hz).
  3. **Mono:** Pure dual-mono (corr 0.99, -0.02 dB overall, -0.09 dB mid, -0.01 dB above 2 kHz), but unusable at -40.7 dB and 97% bass.
- **`wep_eclipse_gsentry_t2.mp3` -> REJECT (virtually silent + extreme sub-20 Hz / bass trap).**
  1. **Verdict:** Reject `wep_eclipse_gsentry_t2.mp3`: virtually silent (-47.0 dB RMS) with 72.4% of its energy below 20 Hz, losing completely to today's audible `railStrike` (`today1`, -20.5 dB) even though mono correlation is fixed vs Wave B `t2` (corr 0.01).
  2. **Bass (<500 Hz):** Yes, extreme sub/bass trap. Measured 96.2% below 500 Hz raw (72.4% below 20 Hz; even above 30 Hz it is 80.6% in 30 to 500 Hz, 12.7% mid, 6.7% above 2 kHz, centroid 127 Hz, at an unusable noise-floor level).
  3. **Mono:** Pure dual-mono (corr 1.00, -0.01 dB overall), unusable due to level and sub-20 Hz content.
- **ID Pick (`wep_eclipse_gsentry`):** Neither, re-roll. Drop `"hollow mid-low"` and `"much lighter than a main null cannon"`; prompt a crisp, loud cold high-voltage obsidian-bolt crack and tight dry electrostatic spark snap cutting off dead, with real midrange presence.

### 10. `wep_eclipse_doom` (Ryan ask: crackling dark lightning arc for the Corona arc look; vs `today0` laserLarge, `today1` darkLance)

- **`wep_eclipse_doom_t1.mp3` -> KEEP (alternate; trim 31 ms dead head, loop 0.15 to 0.75 s for long arcs).**
  1. **Verdict:** Keep `wep_eclipse_doom_t1.mp3` as a brighter alternate: immediate violent electrostatic discharge crack erupting into jagged crackling dark lightning over a cold hollow drone (303.5 Hz), fitting the Corona arc look far better than Wave B's pure foghorn drone and crushing today's `laserLarge` and whispery `darkLance` (`today0`, `today1`).
  2. **Bass (<500 Hz):** No. Measured 17.7% below 500 Hz, 10.5% in 500 Hz to 2 kHz, 71.8% above 2 kHz (centroid 3704 Hz, -20.1 dB RMS, 0.0% below 20 Hz). Note: holds strongly to 0.8 s (`0.0 to 0.4 s: -15.7 dB`, `0.4 to 0.8 s: -16.7 dB`, drops to `-31.7 dB` in `0.8 to 1.2 s`, `T95 = 660 ms`), so loop the steady core in Godot for longer arcs.
  3. **Mono:** Passes mono cleanly (corr 0.66, -0.82 dB overall, -0.83 dB mid, -0.78 dB above 2 kHz, -1.01 dB attack); verified by ear in mono, fierce dark lightning crackle stays sharp and heavy.
- **`wep_eclipse_doom_t2.mp3` -> KEEP (lead pick; trim 29 ms dead head, loop 0.15 to 0.85 s for long arcs).**
  1. **Verdict:** Keep `wep_eclipse_doom_t2.mp3`: louder (-18.3 dB RMS), deeper ominous drone under the violent branching dark lightning crackle (130 Hz dark fundamental vs 303 Hz on `t1`), sustains longer (`T95 = 816 ms`, `-14.2 dB` in `0.0 to 0.4 s`, `-15.0 dB` in `0.4 to 0.8 s`, `-23.9 dB` in `0.8 to 1.2 s`), and locks tightly in mono, nailing Ryan's Corona arc brief over Wave B and today's `darkLance` (`today1`).
  2. **Bass (<500 Hz):** No. Fierce crackling lightning over dark weight: 27.3% below 500 Hz, 10.9% in 500 Hz to 2 kHz, 61.8% above 2 kHz (centroid 2960 Hz, 0.0% below 20 Hz).
  3. **Mono:** Rock-solid mono (corr 0.93, -0.15 dB overall, -0.24 dB mid, -0.15 dB above 2 kHz, -0.07 dB attack); virtually identical punch and branching crackle on one speaker.
- **ID Pick (`wep_eclipse_doom`):** Keep `wep_eclipse_doom_t2.mp3` (trim 29 ms dead head; loop 0.15 to 0.85 s core for arcs past 0.9 s; `t1` is a brighter alternate).

### 11. `wep_eclipse_doom_charge` (Wave B reject; vs `today0` ionCharge, `today1` arc)

- **`wep_eclipse_doom_charge_t1.mp3` -> KEEP (borderline mono; trim 47 ms dead head, add +2 dB >2 kHz shelf).**
  1. **Verdict:** Keep `wep_eclipse_doom_charge_t1.mp3`: huge improvement over Wave B (`t1` had 340 ms dead silence, `t2` was 95.5% sub-bass mud), delivering a strong (-15.5 dB RMS) rising inward air rush and cold building electrostatic coil sweep into a tight cutoff that telegraphs the Corona arc cleanly without today's synthy arcade `ionCharge` (`today0`).
  2. **Bass (<500 Hz):** No. Balanced, audible swell on every speaker: 54.7% below 500 Hz, 24.4% in 500 Hz to 2 kHz, 20.9% above 2 kHz (centroid 1377 Hz, 0.0% below 20 Hz, `T95 = 557 ms`).
  3. **Mono:** Borderline pass (corr 0.48, -1.31 dB overall, -1.84 dB mid, -2.97 dB above 2 kHz, -1.66 dB attack); verified by ear in mono, the top fizz softens noticeably while the rising inward rush and cold midrange coil sweep still read loud, tense, and unmistakably Eclipse.
- **`wep_eclipse_doom_charge_t2.mp3` -> REJECT (mono fail + late 92 ms dead head).**
  1. **Verdict:** Reject `wep_eclipse_doom_charge_t2.mp3`: starts 92.2 ms late, 5.5 dB quieter (-21.0 dB RMS), and loses nearly 4 dB of top-end coil tension in mono, clearly outclassed by `t1`.
  2. **Bass (<500 Hz):** No. Measured 51.1% below 500 Hz, 34.0% in 500 Hz to 2 kHz, 14.9% above 2 kHz (centroid 1188 Hz).
  3. **Mono:** Fails on top end (corr 0.38, -1.62 dB overall, -1.96 dB mid, -3.89 dB above 2 kHz, -0.90 dB attack); audibly dulls in mono.
- **ID Pick (`wep_eclipse_doom_charge`):** Keep `wep_eclipse_doom_charge_t1.mp3` (trim 47 ms dead head; check mono top-end softness on headphones and add a light >2 kHz shelf in mastering).

### 12. `wep_craft_bombs` (Ryan ask: clamp release and thruster ignition; vs `today0` laserSmall)

- **`wep_craft_bombs_t1.mp3` -> KEEP (alternate; trim 92 ms dead head, lift gain ~5 dB).**
  1. **Verdict:** Keep `wep_craft_bombs_t1.mp3` as an alternate: reads clearly as a metallic belly-rack clamp release clank, quick pneumatic push, and brief thruster ignition burst, directly fulfilling Ryan's note over Wave B `t1`/`t2` and completely replacing today's placeholder `laserSmall` (`today0`).
  2. **Bass (<500 Hz):** No. Crisp compact ordnance detail: 10.3% below 500 Hz, 2.3% in 500 Hz to 2 kHz, 87.4% above 2 kHz (centroid 7161 Hz, -23.7 dB RMS, 0.0% below 20 Hz, `T95 = 180 ms` after 92.4 ms dead head).
  3. **Mono:** Passes mono cleanly (corr 0.84, -0.37 dB overall, -0.08 dB mid, -0.41 dB above 2 kHz, -0.44 dB attack).
- **`wep_craft_bombs_t2.mp3` -> KEEP (lead pick; trim 138 ms dead head, lift gain ~5 dB).**
  1. **Verdict:** Keep `wep_craft_bombs_t2.mp3`: sharper clamp release clank into a slightly fuller, longer thruster ignition burst (`T95 = 249 ms` vs `180 ms` on `t1`) with tighter mono lock, nailing Ryan's clamp-plus-thruster brief over Wave B and today's `laserSmall` (`today0`). Note: requires trimming 138.2 ms of dead head so the clamp clank lands at `t=0`.
  2. **Bass (<500 Hz):** No. Measured 5.2% below 500 Hz, 1.8% in 500 Hz to 2 kHz, 93.1% above 2 kHz (centroid 7092 Hz, -24.6 dB RMS, 0.1% below 20 Hz).
  3. **Mono:** Rock-solid mono (corr 0.95, -0.11 dB overall, -0.10 dB mid, -0.11 dB above 2 kHz, -0.07 dB attack); zero loss on one speaker.
- **ID Pick (`wep_craft_bombs`):** Keep `wep_craft_bombs_t2.mp3` (trim 138 ms dead head and lift gain ~5 dB; `t1` is an equally clean alternate after trimming 92 ms).

### 13. `imp_obsidian_eclipse` (Re-rolled on Neon's Wave B note; vs `today0` hullHitBig, `today1` railHit)

- **`imp_obsidian_eclipse_t1.mp3` -> KEEP (standout Wave C fix; trim 9 ms dead head).**
  1. **Verdict:** Keep `imp_obsidian_eclipse_t1.mp3`: immediate hard cold brittle obsidian stone crack with sharp dark rock splintering, crisp electrostatic snap, and tight hollow mid-low knock, completely fixing Wave B's bass trap and mono collapse (95.0% to 99.4% below 500 Hz) and crushing today's muddy `hullHitBig` and plain `railHit` (`today0`, `today1`).
  2. **Bass (<500 Hz):** No. Textbook armored-stone balance: 68.7% below 500 Hz, 15.0% in 500 Hz to 2 kHz, 16.3% above 2 kHz (centroid 918 Hz, -18.7 dB RMS, 0.1% below 20 Hz, `T95 = 243 ms`).
  3. **Mono:** Rock-solid mono (corr 0.97, -0.06 dB overall, -0.05 dB mid, -0.26 dB above 2 kHz, -0.05 dB attack); zero loss on one speaker.
- **`imp_obsidian_eclipse_t2.mp3` -> KEEP (alternate; trim 50 ms dead head).**
  1. **Verdict:** Keep `imp_obsidian_eclipse_t2.mp3` as a darker alternate: equally authentic brittle obsidian stone shatter beating Wave B and today's `hullHitBig` (`today0`), just slower to open (49.5 ms dead head, peak 256 ms vs 109 ms on `t1`) and slightly darker than `t1`.
  2. **Bass (<500 Hz):** No. Measured 80.9% below 500 Hz, 11.2% in 500 Hz to 2 kHz, 7.9% above 2 kHz (centroid 525 Hz, -18.1 dB RMS, 0.1% below 20 Hz).
  3. **Mono:** Passes mono cleanly (corr 0.90, -0.23 dB overall, -0.51 dB mid, -1.40 dB above 2 kHz, -0.15 dB attack).
- **ID Pick (`imp_obsidian_eclipse`):** Keep `imp_obsidian_eclipse_t1.mp3` (trim 9 ms dead head; `t2` works as a darker alternate after trimming 50 ms).

### 14. `imp_metal_light` (Ryan ask: armored steel impact with clear steel clang first; vs `today0` hullHit, `today1` hullTick)

- **`imp_metal_light_t1.mp3` -> REJECT (mono fail; borderline, right steel clang in stereo).**
  1. **Verdict:** Reject `imp_metal_light_t1.mp3` on mono: in stereo it nails Ryan's ask with a clear hard steel clang first and solid plate punch (far better than Wave B `t1`'s dull thud and today's shrill `hullHit`, `today0`), but because the prompt omitted `"heard close and centered"` it drops -2.41 dB of its steel clang midrange when folded to mono, which is too risky for the single most-heard impact in the game (if Ryan still likes it on his mono check, it only needs a 24 ms head trim and 40 Hz high-pass).
  2. **Bass (<500 Hz):** No. Measured 75.4% below 500 Hz raw (73.2% in 30 to 500 Hz after stripping 6.0% below 20 Hz), 14.7% in 500 Hz to 2 kHz, 9.9% above 2 kHz (centroid 697 Hz, -19.9 dB RMS, `T95 = 216 ms`).
  3. **Mono:** Fails mono bar. Wide stereo (corr 0.30) drops -1.87 dB overall, -2.41 dB in 500 Hz to 2 kHz, -1.94 dB above 2 kHz, and -1.13 dB on the attack; by ear in mono the clang survives faintly but noticeably hollows out compared with stereo.
- **`imp_metal_light_t2.mp3` -> REJECT (hard mono fail + thin ping).**
  1. **Verdict:** Reject `imp_metal_light_t2.mp3`: quiet (-30.3 dB RMS) thin high metallic clink with no armored weight that collapses hard in mono, worse than Wave B `t1` and today's `hullTick` (`today1`).
  2. **Bass (<500 Hz):** No (thin high ping). Measured 4.2% below 500 Hz, 9.8% in 500 Hz to 2 kHz, 86.0% above 2 kHz (centroid 3226 Hz).
  3. **Mono:** Hard fail. Negative correlation (corr -0.08) drops -3.33 dB overall, -3.05 dB mid, -3.42 dB above 2 kHz, and -3.38 dB on the attack; turns into a tiny phasey tink in mono.
- **ID Pick (`imp_metal_light`):** Neither, re-roll (note: `t1` gets the armored steel clang right in stereo if Ryan decides it passes his own mono ear check). Add `"heard close and centered"` and drop `"rattle of fragments"` (wide stereo trigger) to lock the steel clang and mid punch in mono.

### 15. `imp_energy_sear` (Ryan ask: armored steel impact with clear steel clang first; vs `today0` hullHitBig, `today1` plasmaHit)

- **`imp_energy_sear_t1.mp3` -> REJECT (thin hiss, missing steel weight + mono fail).**
  1. **Verdict:** Reject `imp_energy_sear_t1.mp3`: swung from Wave B `t1`'s 98.8% sub-bass thud to the opposite extreme of wide bright air/arc hiss with only a faint metallic tic instead of an armored steel clang first, collapsing in mono and sounding thinner than today's `plasmaHit` (`today1`, 37.6% mid).
  2. **Bass (<500 Hz):** No (opposite problem: 96.5% above 2 kHz hiss). Measured 2.2% below 500 Hz, 1.3% in 500 Hz to 2 kHz, 96.5% above 2 kHz (centroid 8838 Hz, -23.6 dB RMS, 0.0% below 20 Hz).
  3. **Mono:** Fails mono. Very wide stereo (corr 0.24) drops -2.06 dB overall, -2.12 dB mid, -2.03 dB above 2 kHz, and -2.04 dB on the attack; sounds hollow and wispy on one speaker.
- **`imp_energy_sear_t2.mp3` -> REJECT (thin hiss, missing steel clang + mono fail).**
  1. **Verdict:** Reject `imp_energy_sear_t2.mp3`: even thinner, fizzier wide stereo hiss (-25.9 dB RMS) with virtually no armored steel clang, failing Ryan's brief and losing cleanly to today's `plasmaHit` (`today1`).
  2. **Bass (<500 Hz):** No (high hiss). Measured 1.3% below 500 Hz, 2.9% in 500 Hz to 2 kHz, 95.8% above 2 kHz (centroid 8020 Hz).
  3. **Mono:** Fails mono. Very wide stereo (corr 0.13) drops -2.50 dB overall, -3.09 dB in 500 Hz to 2 kHz, -2.49 dB above 2 kHz, and -2.29 dB on the attack.
- **ID Pick (`imp_energy_sear`):** Neither, re-roll. Add `"heard close and centered"`, drop `"hiss"` and `"crackle"` (which caused uncorrelated >2 kHz fizz), and lead with a heavy forged-steel armor clang struck by a hot plasma bolt with a short seared electric arc bark.

### 16. `imp_las` (Ryan ask: armored steel impact with clear steel clang first; vs `today0` hullHit, `today1` lasSear)

- **`imp_las_t1.mp3` -> REJECT (hard mono fail + quiet thin hiss, weak steel clang).**
  1. **Verdict:** Reject `imp_las_t1.mp3`: very quiet (-33.1 dB RMS) high-frequency arc hiss with barely any armored steel clang first, failing Ryan's ask just like Wave B `t1` while adding a hard mono collapse that loses even to today's loud `lasSear` (`today1`, -22.4 dB).
  2. **Bass (<500 Hz):** No (96% high hiss). Measured 1.8% below 500 Hz, 2.3% in 500 Hz to 2 kHz, 96.0% above 2 kHz (centroid 7748 Hz, 0.0% below 20 Hz).
  3. **Mono:** Hard fail. Negative correlation (corr -0.02) drops -3.08 dB overall, -2.72 dB mid, -3.11 dB above 2 kHz, and -3.14 dB on the attack; almost vanishes into phasey hiss in mono.
- **`imp_las_t2.mp3` -> REJECT (hard mono fail + whisper-quiet).**
  1. **Verdict:** Reject `imp_las_t2.mp3`: whisper-quiet (-39.1 dB RMS) thin metallic fizz that collapses in mono and never reads as a beam hitting armored starship steel compared with Wave B `t1` or today's `lasSear` (`today1`).
  2. **Bass (<500 Hz):** No. Measured 14.6% below 500 Hz, 11.5% in 500 Hz to 2 kHz, 73.9% above 2 kHz (centroid 5514 Hz).
  3. **Mono:** Hard fail. Near-zero correlation (corr 0.04) drops -2.86 dB overall, -2.44 dB mid, -3.24 dB above 2 kHz, and -2.78 dB on the attack.
- **ID Pick (`imp_las`):** Neither, re-roll. Add `"heard close and centered"`, remove `"hiss"` and banned word `"ping"`, and lead with a solid armored-steel plate clang first followed by a tight brief hot laser sear.

### 17. `imp_acid_on_metal` (Ryan ask: armored steel impact with clear steel clang first; vs `today0` hitWet)

- **`imp_acid_on_metal_t1.mp3` -> KEEP (lead pick; trim 9 ms dead head).**
  1. **Verdict:** Keep `imp_acid_on_metal_t1.mp3`: nails Ryan's ask with an unmistakable solid armored steel clang first straight into an aggressive caustic bubbling and hissing chemical burn eating into steel, fixing Wave B `t2`'s duller blunt thud and obliterating today's tiny `hitWet` (`today0`, -29.0 dB).
  2. **Bass (<500 Hz):** No. Crisp metal hit plus wet corrosive burn: 8.7% below 500 Hz, 8.0% in 500 Hz to 2 kHz, 83.3% above 2 kHz (centroid 3658 Hz, -23.5 dB RMS, 0.0% below 20 Hz, `T95 = 198 ms`).
  3. **Mono:** Passes mono cleanly (corr 0.75, -0.57 dB overall, -0.60 dB mid, -0.53 dB above 2 kHz, -0.32 dB attack); both steel clang and chemical fizz stay crisp on one speaker.
- **`imp_acid_on_metal_t2.mp3` -> KEEP (alternate; trim 29 ms dead head).**
  1. **Verdict:** Keep `imp_acid_on_metal_t2.mp3` as a wetter alternate: also lands a clear steel clang first into bubbling caustic etch beating Wave B `t1` and today's `hitWet` (`today0`), just slightly slower to open (28.7 ms dead head vs 8.8 ms on `t1`) and wider in stereo.
  2. **Bass (<500 Hz):** No. Measured 4.7% below 500 Hz, 5.6% in 500 Hz to 2 kHz, 89.7% above 2 kHz (centroid 4561 Hz, -22.9 dB RMS, 0.1% below 20 Hz, `T95 = 262 ms`).
  3. **Mono:** Borderline pass (corr 0.48, -1.32 dB overall, -0.27 dB mid, -1.42 dB above 2 kHz, -1.33 dB attack); verified by ear in mono, steel clang and burn survive cleanly, though `t1` is tighter and punchier.
- **ID Pick (`imp_acid_on_metal`):** Keep `imp_acid_on_metal_t1.mp3` (trim 9 ms dead head; `t2` works as an alternate after trimming 29 ms).

### 18. `dmg_shield_burnout` (Wave B reject; no clip today)

- **`dmg_shield_burnout_t1.mp3` -> REJECT (hard mono fail + bass trap).**
  1. **Verdict:** Reject `dmg_shield_burnout_t1.mp3`: swung from Wave B's 95% >2 kHz spark fizz into a muffled low hum that is out of phase between channels, collapsing into a dull hollow buzz in mono (no baseline clip today).
  2. **Bass (<500 Hz):** Yes, bass trap. Measured 93.6% below 500 Hz, 2.9% in 500 Hz to 2 kHz, 3.5% above 2 kHz (centroid 404 Hz, -19.5 dB RMS, 0.0% below 20 Hz).
  3. **Mono:** Hard fail. Negative correlation (corr -0.04) drops -3.19 dB overall, -2.99 dB mid, -3.72 dB above 2 kHz, and -1.91 dB on the attack; audibly guts the arc snap in mono.
- **`dmg_shield_burnout_t2.mp3` -> REJECT (mono fail + late peak + bass-leaning).**
  1. **Verdict:** Reject `dmg_shield_burnout_t2.mp3`: better electrical buzz and snap in stereo than `t1` or Wave B's thin fizz, but peaks at the very end (600 ms on a 600 ms clip) and loses nearly 3 dB of its electrical mid and top bite when folded to mono (no baseline clip today).
  2. **Bass (<500 Hz):** Yes, bass-leaning. Measured 86.7% below 500 Hz, 2.4% in 500 Hz to 2 kHz, 10.9% above 2 kHz (centroid 676 Hz, -19.3 dB RMS, 0.1% below 20 Hz).
  3. **Mono:** Fails mono. Wide stereo (corr 0.31) drops -1.89 dB overall, -2.73 dB in 500 Hz to 2 kHz, -2.68 dB above 2 kHz, and -1.52 dB on the attack; audibly hollows out on one speaker.
- **ID Pick (`dmg_shield_burnout`):** Neither, re-roll. Drop `"transformer buzz"` (which pulled 87% to 94% below 500 Hz); prompt one immediate centered dry electrical short-circuit snap and crisp metallic breaker spark popping right at the start over a tight midrange buzz decaying fast.

### 19. `dmg_breach_shear_metal` (Ryan ask: should buckle and rip, now 1.4 s; no clip today)

- **`dmg_breach_shear_metal_t1.mp3` -> KEEP (lead pick; trim 32 ms dead head, high-pass 40 Hz).**
  1. **Verdict:** Keep `dmg_breach_shear_metal_t1.mp3`: nails Ryan's ask with deep straining steel bending, a loud violent metallic rip along a plate seam, popping rivets, and a heavy final metal lurch across 1.4 s (`T95 = 767 ms`), clearly outperforming Wave B `t2`'s short crunch (no baseline clip today).
  2. **Bass (<500 Hz):** No. Strong physical steel balance: 74.0% below 500 Hz raw (69.2% in 30 to 500 Hz after stripping 13.8% below 20 Hz), 13.1% in 500 Hz to 2 kHz (15.6% above 30 Hz), 12.8% above 2 kHz (15.2% above 30 Hz, centroid 793 Hz, -18.2 dB RMS).
  3. **Mono:** Passes mono cleanly (corr 0.58, -1.04 dB overall, -1.20 dB mid, -0.82 dB above 2 kHz, -1.09 dB attack); verified by ear in mono, buckling strain, ripping seam, and metal lurch keep full physical bite on one speaker.
- **`dmg_breach_shear_metal_t2.mp3` -> REJECT (mono mid/high drop + darker + heavy sub-20 Hz).**
  1. **Verdict:** Reject `dmg_breach_shear_metal_t2.mp3`: also buckles and rips nicely in stereo (`T95 = 906 ms`), but carries 21.0% below 20 Hz and loses over 2.3 dB of its tearing metal mids and highs in mono, sounding noticeably duller than `t1` on one speaker.
  2. **Bass (<500 Hz):** Yes, bass-leaning raw (85.1% below 500 Hz with 21.0% below 20 Hz; 80.5% in 30 to 500 Hz, 11.3% mid, 8.3% above 2 kHz, centroid 396 Hz).
  3. **Mono:** Fails on tearing detail (corr 0.43, -1.47 dB overall, -2.38 dB in 500 Hz to 2 kHz, -2.40 dB above 2 kHz, -1.49 dB attack); cleanly beaten by `t1`.
- **ID Pick (`dmg_breach_shear_metal`):** Keep `dmg_breach_shear_metal_t1.mp3` (trim 32 ms dead head, high-pass 40 Hz).

### 20. `dmg_breach_vent` (Re-rolled on Neon's Wave B note; no clip today)

- **`dmg_breach_vent_t1.mp3` -> KEEP (borderline mono; trim 20 ms dead head).**
  1. **Verdict:** Keep `dmg_breach_vent_t1.mp3`: immediate sudden high-pressure air blast rushing through a torn opening with loose metal pieces rattling and thinning quickly to silence (`T95 = 274 ms`), a major mono fix over Wave B `t1`/`t2`'s out-of-phase comb-filtered hiss (corr -0.18 / -0.01; no baseline clip today).
  2. **Bass (<500 Hz):** No. Measured 14.1% below 500 Hz, 5.0% in 500 Hz to 2 kHz, 80.9% above 2 kHz (centroid 4784 Hz, -23.2 dB RMS, 0.0% below 20 Hz).
  3. **Mono:** Borderline pass (corr 0.39, -1.63 dB overall, -1.54 dB mid, -1.73 dB above 2 kHz, -1.69 dB attack); verified by ear in mono, it narrows slightly compared with stereo yet stays crisp, pressurized, and unmistakably a hull decompression vent.
- **`dmg_breach_vent_t2.mp3` -> REJECT (mono fail).**
  1. **Verdict:** Reject `dmg_breach_vent_t2.mp3`: quieter (-25.9 dB RMS), thinner hiss (89.8% above 2 kHz) that hollows out badly in mono, clearly beaten by `t1`.
  2. **Bass (<500 Hz):** No. Measured 8.1% below 500 Hz, 2.0% in 500 Hz to 2 kHz, 89.8% above 2 kHz (centroid 5639 Hz).
  3. **Mono:** Fails mono. Very wide stereo (corr 0.23) drops -2.10 dB overall, -2.49 dB mid, -2.11 dB above 2 kHz, and -1.96 dB on the attack.
- **ID Pick (`dmg_breach_vent`):** Keep `dmg_breach_vent_t1.mp3` (trim 20 ms dead head; verify mono decompression rush on headphones).

### 21. `death_ithar_shatter` (Wave B reject, stacked death cue; vs `today0` crackGlass, `today1` hitGlass, `today2` choirBell)

- **`death_ithar_shatter_t1.mp3` -> REJECT (mono fail).**
  1. **Verdict:** Reject `death_ithar_shatter_t1.mp3`: bright cascading crystalline fractures in stereo that cure Wave B's 98.2% to 99.4% sub-bass rock mud, but collapses hard on top when folded to mono, losing cleanly to `t2`.
  2. **Bass (<500 Hz):** No. Measured 27.4% below 500 Hz, 11.5% in 500 Hz to 2 kHz, 61.1% above 2 kHz (centroid 4706 Hz, -24.2 dB RMS, 2.1% below 20 Hz).
  3. **Mono:** Fails mono. Very wide stereo (corr 0.24) drops -2.11 dB overall, -1.31 dB mid, -2.81 dB above 2 kHz, and -1.41 dB attack; audibly thins and loses crystal ring on one speaker.
- **`death_ithar_shatter_t2.mp3` -> KEEP (borderline mono; stacked death crack, +2 dB presence lift).**
  1. **Verdict:** Keep `death_ithar_shatter_t2.mp3`: thick crystal armor slabs cracking apart with unmistakable ringing glass-harmonic tones over a firm structural break (`0.7 ms` onset, `T95 = 270 ms`, ideal as the stacked `death_crack` layer over `boom_l` and `death_bed`), completely fixing Wave B's 99% sub-mud and far heavier than today's small `crackGlass` and `hitGlass` (`today0`, `today1`).
  2. **Bass (<500 Hz):** No. Strong crystalline balance: 59.1% below 500 Hz (54.9% above 30 Hz), 7.5% in 500 Hz to 2 kHz, 33.4% above 2 kHz (centroid 1794 Hz, -23.4 dB RMS, 0.7% below 20 Hz).
  3. **Mono:** Borderline pass (corr 0.38, -1.61 dB overall, -2.08 dB mid, -2.19 dB above 2 kHz, -1.59 dB attack); verified by ear in mono, top shimmer softens slightly while the heavy crystalline break and clear glass-harmonic tones still read distinctly Glasswright.
- **ID Pick (`death_ithar_shatter`):** Keep `death_ithar_shatter_t2.mp3` (add +2 dB high-mid lift in mastering and check inside the stacked death preview).

### 22. `death_eclipse_shear` (Wave B reject, stacked death cue; vs `today0` scrape, `today1` hullHitBig, `today2` crackSettle)

- **`death_eclipse_shear_t1.mp3` -> REJECT (mono fail).**
  1. **Verdict:** Reject `death_eclipse_shear_t1.mp3`: huge brightness fix over Wave B's 100.0% sub-bass mud with dry brittle stone grinding and fracture grit (`47.8%` mid), but fails mono and thins out on one speaker, losing to `t2`.
  2. **Bass (<500 Hz):** No. Measured 44.3% below 500 Hz, 47.8% in 500 Hz to 2 kHz, 8.0% above 2 kHz (centroid 919 Hz, -23.5 dB RMS, 0.2% below 20 Hz).
  3. **Mono:** Fails mono. Very wide stereo (corr 0.19) drops -2.28 dB overall, -1.29 dB mid, -2.08 dB above 2 kHz, and -1.55 dB on the attack; audibly loses stone weight in mono.
- **`death_eclipse_shear_t2.mp3` -> KEEP (borderline mono; trim 52 ms dead head, +2 to 3 dB presence lift).**
  1. **Verdict:** Keep `death_eclipse_shear_t2.mp3`: completely breaks Wave B's 100.0% sub-bass boom, delivering heavy ancient obsidian slabs grinding and shearing apart with crisp dry rock-fracture grit (`T95 = 905 ms`, -20.1 dB RMS) that will stand out sharply over `boom_l` and `death_bed`, far more physical than today's dull `scrape` and `hullHitBig` (`today0`, `today1`).
  2. **Bass (<500 Hz):** No. Solid stone-grinding body: 76.9% below 500 Hz, 20.1% in 500 Hz to 2 kHz, 3.0% above 2 kHz (centroid 397 Hz, 0.0% below 20 Hz).
  3. **Mono:** Borderline pass (corr 0.43, -1.50 dB overall, -2.14 dB mid, -2.64 dB above 2 kHz, rock-solid -0.12 dB attack); verified by ear in mono, the faint upper crackle softens while the heavy initial obsidian break and grinding stone shear remain big, eerie, and clear.
- **ID Pick (`death_eclipse_shear`):** Keep `death_eclipse_shear_t2.mp3` (trim 52 ms dead head, add +2 to 3 dB presence lift, and check in the stacked death preview).

### 23. `death_sunward_magazine` (Wave B reject, stacked death cue; vs `today0` boomSmall, `today1` boomLow, `today2` debris)

- **`death_sunward_magazine_t1.mp3` -> REJECT (mono fail).**
  1. **Verdict:** Reject `death_sunward_magazine_t1.mp3`: sharp internal steel-plated explosion in stereo that cures Wave B's 98.0% sub-bass mud, but loses over 3.3 dB of its metallic hull-plate crack in mono, cleanly beaten by `t2`.
  2. **Bass (<500 Hz):** No. Measured 81.5% below 500 Hz, 12.2% in 500 Hz to 2 kHz, 6.4% above 2 kHz (centroid 507 Hz, -20.0 dB RMS, 0.4% below 20 Hz).
  3. **Mono:** Fails mono. Wide stereo (corr 0.29) drops -1.91 dB overall, -3.35 dB in 500 Hz to 2 kHz, -3.40 dB above 2 kHz, and -2.16 dB on the attack; goes dull and hollow on one speaker.
- **`death_sunward_magazine_t2.mp3` -> KEEP (standout Wave C fix).**
  1. **Verdict:** Keep `death_sunward_magazine_t2.mp3`: immediate (`0.0 ms` onset, `peak 19 ms`) violent internal magazine detonation bursting through armored steel with a crisp metallic hull-plate crack and rattling fragments (`T95 = 240 ms`), completely curing Wave B's 97.4% to 98.0% muffled booms so each flash punches cleanly over `death_metal_break`, sharper and more metallic than today's `boomSmall` and `boomLow` (`today0`, `today1`).
  2. **Bass (<500 Hz):** No. Measured 80.9% below 500 Hz, 10.7% in 500 Hz to 2 kHz, 8.4% above 2 kHz (centroid 587 Hz, -21.3 dB RMS, 0.1% below 20 Hz).
  3. **Mono:** Passes mono cleanly (corr 0.77, -0.53 dB overall, -1.17 dB mid, -1.84 dB above 2 kHz, -0.47 dB attack); verified by ear in mono, sharp steel-plated blast stays punchy and distinct.
- **ID Pick (`death_sunward_magazine`):** Keep `death_sunward_magazine_t2.mp3`.

### 24. `evt_fleet_warp_in` (Wave B reject; vs `today0` whoosh, `today1` boomLow)

- **`evt_fleet_warp_in_t1.mp3` -> REJECT (bass trap + quieter than `t2`).**
  1. **Verdict:** Reject `evt_fleet_warp_in_t1.mp3`: tighter timing (`0.2 ms` onset vs `69.3 ms` late in Wave B `t1`) and clean mono, but 3.8 dB quieter (-18.6 dB RMS), carries 6.7% sub-20 Hz rumble, and has less midrange snap than `t2`.
  2. **Bass (<500 Hz):** Yes, bass trap. Measured 95.8% below 500 Hz (95.4% above 30 Hz), 4.1% in 500 Hz to 2 kHz, 0.0% above 2 kHz (centroid 181 Hz, dominant 111.7 Hz).
  3. **Mono:** Pure dual-mono (corr 0.98, -0.04 dB overall, -0.19 dB mid, -0.10 dB attack); beaten cleanly by `t2`.
- **`evt_fleet_warp_in_t2.mp3` -> KEEP (dark-leaning; add +4 dB presence lift in 800 Hz to 3 kHz, check on small speakers).**
  1. **Verdict:** Keep `evt_fleet_warp_in_t2.mp3`: loud (-14.8 dB RMS), immediate (`0.2 ms` onset) inward gravitational pressure snap cracking into a punchy authoritative displacement boom and resonant thruster settle (`T95 = 733 ms`), curing Wave B `t1`'s late 55 Hz mud and Wave B `t2`'s mono collapse (corr 0.04) and far weightier than today's plain `whoosh` and `boomLow` (`today0`, `today1`).
  2. **Bass (<500 Hz):** Yes, dark-leaning (94.0% below 500 Hz, 6.0% in 500 Hz to 2 kHz, 0.0% above 2 kHz, centroid 223 Hz, only 0.1% below 20 Hz); its dominant 156.2 Hz core and 6.0% midrange read clearly by ear rather than turning into infrasonic mud, though it has no top air crackle above 2 kHz.
  3. **Mono:** Pure dual-mono (corr 0.99, -0.02 dB overall, -0.03 dB mid, -0.26 dB above 2 kHz, -0.03 dB attack); zero mono loss.
- **ID Pick (`evt_fleet_warp_in`):** Keep `evt_fleet_warp_in_t2.mp3` (add a light upper-mid presence lift in mastering; if Ryan wants crisp top-end crackle above 2 kHz on small speakers, re-roll adding bright electrical/air snap wording).

### 25. `amb_bridge_bed` (Ryan ask: check that Wave B's 7 to 11 s voice is gone; 20 s loop, no clip today)

- **`amb_bridge_bed_t1.mp3` -> KEEP (standout Wave C fix; zero voice, seamless loop).**
  1. **Verdict:** Keep `amb_bridge_bed_t1.mp3`: completely voice-free across all 20 seconds, curing Wave B `t1`'s 7 to 11 s muffled radio voice (`+15 dB` spike, 63.4% voice-band jump). Reads as a calm, steady, uncrewed starship engine room with a smooth low reactor hum (197.3 Hz), faint even air-duct flow, and soft constant transformer drone; 1-second RMS stays between -38.3 dB and -35.5 dB (2.8 dB total spread vs 17.0 dB in Wave B), 300 Hz to 3 kHz stays flat at 3.7% to 9.0%, and the loop seam matches within 0.23 dB (`-37.5 dB` first 0.5 s vs `-37.7 dB` last 0.5 s; no baseline clip today).
  2. **Bass (<500 Hz):** Yes, by design for a quiet background bed (98.7% below 500 Hz, 1.2% in 500 Hz to 2 kHz, 0.1% above 2 kHz, centroid 213 Hz, 0.0% below 20 Hz, -36.7 dB RMS); sits cleanly around 200 Hz out of the way of combat SFX and music.
  3. **Mono:** Rock-solid mono (corr 0.96, -0.09 dB overall, -0.31 dB mid, -0.56 dB above 2 kHz, -0.08 dB attack); works cleanly in either stereo (unpositioned ambient bed) or mono.
- **ID Pick (`amb_bridge_bed`):** Keep `amb_bridge_bed_t1.mp3`.

---

## Quick Pick Summary (All 25 IDs)

| # | Sound ID | Pick | Mastering / Handling Notes |
|---|---|---|---|
| 1 | `wep_sunward_turret` | `wep_sunward_turret_t2.mp3` | Dual-mono; high-pass 40 Hz for DC offset |
| 2 | `wep_sunward_hbattery` | `wep_sunward_hbattery_t2.mp3` | Dual-mono; high-pass 40 Hz (`t1` ready alt) |
| 3 | `wep_torp_eject` | `wep_torp_eject_t1.mp3` | Fold mono; optional gentle tame >6 kHz |
| 4 | `evt_pass_by_slug` | `evt_pass_by_slug_t2.mp3` | Fold mono; +3 dB presence lift >1 kHz |
| 5 | `wep_directorate_picket` | **Re-roll** | Both 97.3% to 99.0% <500 Hz muffled taps |
| 6 | `wep_hullbreaker_junk_gun` | `wep_hullbreaker_junk_gun_t2.mp3` | Standout; fold mono, high-pass 40 Hz |
| 7 | `wep_chorus_spore_cloud` | `wep_chorus_spore_cloud_t2.mp3` | Clean mono, centered organic pod (`t1` alt) |
| 8 | `wep_chorus_sporeb` | `wep_chorus_sporeb_t1.mp3` | Zero static, solid mono; optional light mid lift |
| 9 | `wep_eclipse_gsentry` | **Re-roll** | Both -40.7 / -47.0 dB whisper-quiet + >96% <500 Hz |
| 10 | `wep_eclipse_doom` | `wep_eclipse_doom_t2.mp3` | Trim 29 ms; loop 0.15 to 0.85 s for long arcs (`t1` alt) |
| 11 | `wep_eclipse_doom_charge` | `wep_eclipse_doom_charge_t1.mp3` | Borderline mono (-2.97 dB hi); trim 47 ms, +2 dB >2 kHz |
| 12 | `wep_craft_bombs` | `wep_craft_bombs_t2.mp3` | Trim 138 ms, lift gain ~5 dB (`t1` alt, trim 92 ms) |
| 13 | `imp_obsidian_eclipse` | `imp_obsidian_eclipse_t1.mp3` | Standout; trim 9 ms (`t2` alt, trim 50 ms) |
| 14 | `imp_metal_light` | **Re-roll** | `t1` right steel clang in stereo, fails mono (-2.41 dB mid); `t2` corr -0.08 |
| 15 | `imp_energy_sear` | **Re-roll** | Both ~96% >2 kHz thin hiss, weak steel clang + mono fail |
| 16 | `imp_las` | **Re-roll** | Both -33 to -39 dB hiss, weak clang, hard mono fail (corr -0.02 / 0.04) |
| 17 | `imp_acid_on_metal` | `imp_acid_on_metal_t1.mp3` | Standout; clear steel clang first, trim 9 ms (`t2` alt) |
| 18 | `dmg_shield_burnout` | **Re-roll** | Both 87% to 94% <500 Hz + mono fail; `t2` peaks at 600 ms |
| 19 | `dmg_breach_shear_metal` | `dmg_breach_shear_metal_t1.mp3` | Standout 1.4 s buckle and rip; trim 32 ms, high-pass 40 Hz |
| 20 | `dmg_breach_vent` | `dmg_breach_vent_t1.mp3` | Borderline mono (-1.63 dB); trim 20 ms, verify on headphones |
| 21 | `death_ithar_shatter` | `death_ithar_shatter_t2.mp3` | Borderline mono (-1.61 dB); +2 dB high-mid lift, stacked death check |
| 22 | `death_eclipse_shear` | `death_eclipse_shear_t2.mp3` | Borderline mono (-0.12 dB atk); trim 52 ms, +2 to 3 dB lift |
| 23 | `death_sunward_magazine` | `death_sunward_magazine_t2.mp3` | Standout; immediate metallic internal detonation, clean mono |
| 24 | `evt_fleet_warp_in` | `evt_fleet_warp_in_t2.mp3` | Dual-mono, dark-leaning (156 Hz core, 0% >2 kHz); +4 dB mid lift |
| 25 | `amb_bridge_bed` | `amb_bridge_bed_t1.mp3` | Standout; zero voice, 2.8 dB flat across 20 s, 0.23 dB loop seam |

---

## Short List of IDs That Still Need a Re-Roll (6 of 25)

1. **`wep_directorate_picket`:** Drop `"plasma tick"` and `"much lighter than a main cannon"`; prompt a crisp centered high-voltage electrical arc snap and tight dry spark discharge with bright upper-midrange bite and no low thump.
2. **`wep_eclipse_gsentry`:** Drop `"hollow mid-low"` and `"much lighter than a main null cannon"`; prompt a loud crisp centered cold electrostatic obsidian-bolt crack cutting off dead, with real midrange presence.
3. **`imp_metal_light`:** Add `"heard close and centered"` and drop `"rattle of fragments"` (wide stereo trigger) to lock `t1`'s winning armored-steel clang and firm mid punch cleanly in mono.
4. **`imp_energy_sear`:** Add `"heard close and centered"`, drop `"hiss"` and `"crackle"` (uncorrelated >2 kHz fizz triggers), and lead with a heavy forged-steel armor clang struck by a hot plasma bolt plus a short seared electric arc bark.
5. **`imp_las`:** Add `"heard close and centered"`, remove `"hiss"` and banned word `"ping"`, and lead with a solid armored-steel plate clang first followed by a tight brief hot laser sear.
6. **`dmg_shield_burnout`:** Drop `"transformer buzz"` (which pulled 87% to 94% below 500 Hz); prompt one immediate centered dry electrical short-circuit snap and crisp metallic breaker spark popping right at the start over a tight midrange buzz decaying fast.
