# Wave B Sound Ear Audit (Issues 1752 and 1862)

Listening and mono fold-down audit of all 108 Wave B ElevenLabs takes (`out_20261123_114446_25233/out_new/elevenlabs/`) across all 55 sound ids against today's game clips (`out_new/listen/audio/*_today*.ogg`). Every take was listened to directly in stereo, measured with one Python/ffmpeg FFT script (44.1 kHz, power-weighted bands, stereo-to-mono band loss in dB, DC offset, and onset/tail timing), and every wide or borderline take (32 takes with notable stereo spread or band cancellation) was folded to mono `(L + R) / 2` and listened to again in mono.

## Bottom Line (Read Before Listening)

- **Scorecard: 48 keeps, 60 rejects** across 108 takes (55 ids).
  - **IDs with a pick: 35 of 55** (34 shippable game cues plus `wep_sunward_hbattery_salvo_t1.mp3` as REFERENCE ONLY).
  - **IDs needing a re-roll: 20 of 55** (see the short list at the bottom).
- **Five big Wave B findings:**
  1. **Critical vocal leak in `amb_bridge_bed_t1.mp3` (REJECT):** Between seconds 7 and 11, a muffled human radio voice speaks (`"...three one..."`), spiking RMS by +15 dB and jumping 300 Hz to 3 kHz energy from 16% to 63.4%. The `"no vocals"` phrase leaked a voice (pink-elephant trap), and `"command bridge"` pulled radio chatter. It cannot loop.
  2. **Mono collapse killed 11 otherwise good sounds:** Wide stereo panning/noise phrases (`"wide"`, `"racing outward"`, `"scatter"`, `"rippling outward"`) produced near-zero or negative L/R correlation on `dmg_breach_vent`, `dmg_shield_burnout`, `shd_break_prismatic`, `wep_chorus_spore_cloud`, `wep_eclipse_gsentry`, `wep_torp_eject_t2`, `wep_hullbreaker_rockets_t1`, `wep_ithar_pulsar_t2`, `wep_craft_bombs_t2`, `dmg_engine_fail_t2`, and `evt_fleet_warp_in_t2`. Because positioned battle sounds ship in mono, these fall apart on one speaker.
  3. **Bass trap still hit 12 ids:** Prompts that kept `"sub-bass"`, `"sub-harmonic"`, `"massive low end"`, `"muffled"`, `"colossal"`, or `"monumental"` came back 90% to 100% below 500 Hz (`death_eclipse_shear` at 100.0%, `wep_directorate_picket` at 99.8% to 99.9%, `evt_fleet_warp_in_t1` at 99.9%, `death_ithar_shatter` at 98.2% to 99.4%, `imp_energy_sear` at 98.8% to 99.0%, `wep_sunward_turret` at 94.8% to 99.0%, `death_sunward_magazine` at 97.4% to 98.0%, `wep_sunward_hbattery` at 96.4% to 99.5%, `imp_obsidian_eclipse` at 95.0% to 99.4%, `evt_pass_by_slug` at 95.9% to 99.4%).
  4. **Hidden DC offset on ElevenLabs v2 shell guns:** Several v2 takes carry a real DC offset that inflates `<20 Hz` power (`wep_flak_airburst_t2` 75.8% `<20 Hz`, `wep_hullbreaker_junk_gun_t2` 61.7%, `wep_sunward_hbattery_t1` 60.6%, `wep_craft_guns_t1/t2` 14.5% / 13.8%). High-passing at 35 to 40 Hz in mastering strips it cleanly (and reveals `wep_flak_airburst_t2` is actually bright above 30 Hz, not bass-trapped).
  5. **Sustained beams still fade before the end:** Even without the power-down clause, `wep_directorate_ion_beam_t1` (`T95 = 762 ms`), `wep_ithar_pulsar_t1` (`T95 = 405 ms`), and `wep_eclipse_doom_t1` (`T95 = 747 ms`) decay sharply past 0.5 to 0.8 s. Their core tones are keepers, so loop the steady middle slice in Godot for beams longer than ~0.7 s, as planned in `cohesive_audio_v2.md` section 8.2.
- **Standout keepers (strongest hardware upgrades over today):** `wep_hullbreaker_scatter_t1.mp3`, `wep_directorate_turbo_t1.mp3` & `t2.mp3`, `wep_directorate_ion_beam_t1.mp3`, `wep_sunward_torp_launch_t1.mp3`, `wep_sunward_autocannon_t1.mp3`, `wep_ithar_pulsar_t1.mp3`, `wep_ithar_startorp_t2.mp3`, `wep_eclipse_doom_t1.mp3`, `wep_craft_guns_t2.mp3`, `imp_acid_on_metal_t2.mp3`, `dmg_breach_shear_metal_t2.mp3`, `dmg_engine_fail_t1.mp3`, `death_directorate_blackout_t1.mp3`, `death_metal_break_t1.mp3`, `ui_confirm_latch_t1.mp3`.

---

## Per-Take Verdict, Bass Check, Mono Check, and Pick (55 IDs, 108 Takes)

### 1. `wep_sunward_hbattery_salvo` - REFERENCE ONLY (vs `today0` boomLow, `today1` shellBang)

- **`wep_sunward_hbattery_salvo_t1.mp3` -> KEEP (reference only, not for wiring).**
  1. **Verdict:** Keep `wep_sunward_hbattery_salvo_t1.mp3` as the salvo target reference: it rolls cleanly through five heavy iron-ringing capital cannon blasts over a hull shudder, far richer and more physical than today's flat `boomLow` and `shellBang` (`today0`, `today1`).
  2. **Bass (<500 Hz):** No. Measured 74.3% below 500 Hz in mono, 22.9% in 500 Hz to 2 kHz, 2.8% above 2 kHz (centroid 423 Hz, 1.6% below 20 Hz); heavy low punch with clear midrange iron bark.
  3. **Mono:** Passes mono cleanly (corr 0.76, -0.55 dB overall, -0.06 dB in 500 Hz to 2 kHz, -0.33 dB above 2 kHz, -0.29 dB attack); keeps both rolling cadence and metal ring.
- **ID Pick (`wep_sunward_hbattery_salvo`):** Keep `wep_sunward_hbattery_salvo_t1.mp3` as the reference salvo (not wired).

### 2. `wep_sunward_autocannon` (vs `today0` gunTracer)

- **`wep_sunward_autocannon_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep `wep_sunward_autocannon_t1.mp3`: tight, crisp mechanical autocannon report with a clean metallic bolt cycle and solid punch, a massive hardware upgrade over today's thin, tinny `gunTracer` (`today0`, 87% above 2 kHz).
  2. **Bass (<500 Hz):** No. Measured 78.3% below 500 Hz, 7.2% in 500 Hz to 2 kHz, 14.5% above 2 kHz (centroid 927 Hz, -15.9 dB RMS, 0.1% below 20 Hz); reads fast and sharp.
  3. **Mono:** Passes mono cleanly (corr 0.87, -0.30 dB overall, -0.29 dB mid, -1.52 dB above 2 kHz, -0.30 dB attack); holds its crisp snap and punch on one speaker.
- **`wep_sunward_autocannon_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject `wep_sunward_autocannon_t2.mp3`: darker and drier than `t1` with less metallic action character, and its top-end crack softens badly in mono even though it beats today's `gunTracer` (`today0`) in raw weight.
  2. **Bass (<500 Hz):** Yes, bass-leaning. Measured 88.8% below 500 Hz, 6.2% in 500 Hz to 2 kHz, 5.0% above 2 kHz (centroid 406 Hz, 1.4% below 20 Hz).
  3. **Mono:** Fails on top end (corr 0.84, -0.36 dB overall, -1.69 dB mid, -2.97 dB above 2 kHz); folding to mono dulls the crisp autocannon bite.
- **ID Pick (`wep_sunward_autocannon`):** Keep `wep_sunward_autocannon_t1.mp3`.

### 3. `wep_sunward_torp_launch` (vs `today0` whoosh, `today1` heavyPlate)

- **`wep_sunward_torp_launch_t1.mp3` -> KEEP (trim 9 ms dead head).**
  1. **Verdict:** Keep `wep_sunward_torp_launch_t1.mp3`: hefty thruster ignition surging into a smooth, powerful heavy burn accelerating away, far more credible as capital ordnance than today's generic `whoosh` and `heavyPlate` (`today0`, `today1`).
  2. **Bass (<500 Hz):** No. Balanced full-band burn: 61.4% below 500 Hz, 18.9% in 500 Hz to 2 kHz, 19.7% above 2 kHz (centroid 1114 Hz, -17.5 dB RMS, 0.2% below 20 Hz).
  3. **Mono:** Rock-solid mono (corr 0.98, -0.05 dB overall, -0.03 dB mid, -0.20 dB above 2 kHz, -0.16 dB attack); identical punch and burn on one speaker.
- **`wep_sunward_torp_launch_t2.mp3` -> KEEP (alternate, trim 7 ms dead head).**
  1. **Verdict:** Keep `wep_sunward_torp_launch_t2.mp3` as a backup: sharper ignition pop into a slightly shorter, airier burn (`T95 = 704 ms` vs `909 ms` on `t1`), still clearly beating today's `whoosh` and `heavyPlate` (`today0`, `today1`).
  2. **Bass (<500 Hz):** No. Measured 70.6% below 500 Hz, 12.1% in 500 Hz to 2 kHz, 17.3% above 2 kHz (centroid 899 Hz, -18.9 dB RMS, 0.3% below 20 Hz).
  3. **Mono:** Rock-solid mono (corr 0.98, -0.03 dB overall, -0.02 dB mid, -0.12 dB above 2 kHz, -0.08 dB attack).
- **ID Pick (`wep_sunward_torp_launch`):** Keep `wep_sunward_torp_launch_t1.mp3` (fuller, longer thruster surge; `t2` works as an alternate).

### 4. `wep_sunward_turret` (vs `today0` boomLow, `today1` shellBang)

- **`wep_sunward_turret_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject `wep_sunward_turret_t1.mp3`: sounds punchy on headphones, but its energy is trapped below 500 Hz with almost zero forged-steel barrel crack compared with today's `shellBang` (`today1`, 32% mid, 10% high).
  2. **Bass (<500 Hz):** Yes, confirmed bass trap. Measured 99.0% below 500 Hz (96.3% even above 30 Hz), 0.5% in 500 Hz to 2 kHz, 0.5% above 2 kHz (centroid 78 Hz, 4.7% below 20 Hz); reads as a dull low thump on small speakers.
  3. **Mono:** Passes mono (corr 0.93, -0.32 dB overall, -0.50 dB mid, -1.56 dB above 2 kHz), so mono is not the issue, lack of midrange metal crack is.
- **`wep_sunward_turret_t2.mp3` -> REJECT (hard mono fail).**
  1. **Verdict:** Reject `wep_sunward_turret_t2.mp3`: slightly noisier double-tap mechanical snap in stereo that collapses into a thin, phase-cancelled thud in mono, losing to today's `shellBang` (`today1`).
  2. **Bass (<500 Hz):** Yes. Measured 94.8% below 500 Hz (86.3% above 30 Hz), 1.8% in 500 Hz to 2 kHz, 3.4% above 2 kHz (centroid 211 Hz, 6.4% below 20 Hz).
  3. **Mono:** Hard fail. Negative correlation (corr -0.15) drops -3.72 dB overall and -3.72 dB on the attack (-1.85 dB mid, -2.31 dB high); audibly hollows out when summed.
- **ID Pick (`wep_sunward_turret`):** Neither, re-roll. Drop `"compact punchy low thump"` and prompt a bright forged-steel breech crack and sharp midrange propellant report so it sits cleanly between `autocannon` and `battery`.

### 5. `wep_sunward_hbattery` (vs `today0` boomLow, `today1` shellBang)

- **`wep_sunward_hbattery_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject `wep_sunward_hbattery_t1.mp3`: huge raw boom, but carries a severe DC offset and zero forged-iron upper crack, so five staggered shots will turn into pure sub-bass mud unlike today's `shellBang` (`today1`) or `wep_sunward_hbattery_salvo_t1`.
  2. **Bass (<500 Hz):** Yes, extreme bass trap plus DC offset. Measured 99.5% below 500 Hz with 60.6% below 20 Hz (DC +0.090); even above 30 Hz it is 98.3% below 500 Hz, 1.7% mid, 0.0% above 2 kHz (centroid 36 Hz).
  3. **Mono:** Dual-mono (corr 1.00, 0.00 dB loss), so mono is clean, but there is no top-end iron crack left to survive a 5-gun volley.
- **`wep_sunward_hbattery_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject `wep_sunward_hbattery_t2.mp3`: cleaner than `t1` with no DC offset and massive low punch, but still 96.4% below 500 Hz with virtually no crisp barrel crack above 2 kHz to cut through when five shots stack, unlike `wep_sunward_hbattery_salvo_t1` or today's `shellBang` (`today1`).
  2. **Bass (<500 Hz):** Yes, bass trap. Measured 96.4% below 500 Hz, 3.5% in 500 Hz to 2 kHz, 0.1% above 2 kHz (centroid 135 Hz, -8.1 dB RMS, 3.1% below 20 Hz).
  3. **Mono:** Dual-mono (corr 1.00, 0.00 dB loss across all bands); mono-safe, just far too dark for a 5-shot staggered flank battery.
- **ID Pick (`wep_sunward_hbattery`):** Neither, re-roll. Remove `"heavy hull-frame low-end shudder"` and `"slower and deeper"`; ask for a hard bright propellant crack and ringing forged-iron barrel bark over a controlled low punch (matching `wep_sunward_hbattery_salvo_t1`'s 23% midrange clarity).

### 6. `wep_flak_airburst` (vs `today0` gunFlak)

- **`wep_flak_airburst_t1.mp3` -> KEEP (high-pass 40 Hz in mastering).**
  1. **Verdict:** Keep `wep_flak_airburst_t1.mp3`: fast, sharp point-defense flak crack with a quick gritty burst of fragments, far meatier and more physical than today's thin `gunFlak` (`today0`).
  2. **Bass (<500 Hz):** No. Measured 75.8% below 500 Hz raw (69.9% in 30 to 500 Hz after stripping 11.0% below 20 Hz DC/sub), 15.1% in 500 Hz to 2 kHz, 9.1% above 2 kHz (centroid 653 Hz, -10.3 dB RMS); crisp and punchy.
  3. **Mono:** Passes mono cleanly (corr 0.92, -0.17 dB overall, -0.67 dB mid, -0.43 dB above 2 kHz, -0.25 dB attack).
- **`wep_flak_airburst_t2.mp3` -> KEEP (alternate, requires 40 Hz high-pass and gain lift).**
  1. **Verdict:** Keep `wep_flak_airburst_t2.mp3` as a drier alternate: tighter, snappier defensive pop than today's `gunFlak` (`today0`), slightly less shrapnel grit and quieter than `t1` (`-21.2 dB` vs `-10.3 dB`).
  2. **Bass (<500 Hz):** No (once DC is high-passed). Raw 86.0% below 500 Hz is caused by a large DC offset (-0.041, 75.8% below 20 Hz); above 30 Hz it is bright and balanced at 39.3% in 30 to 500 Hz, 41.2% mid, 19.5% above 2 kHz.
  3. **Mono:** Passes mono cleanly (corr 0.96, -0.07 dB overall, -0.08 dB mid, -1.03 dB above 2 kHz, -0.09 dB attack).
- **ID Pick (`wep_flak_airburst`):** Keep `wep_flak_airburst_t1.mp3` (high-pass at 40 Hz; `t2` works as a second take after DC removal and gain match).

### 7. `wep_torp_eject` (vs `today0` whoosh, `today1` ionCharge)

- **`wep_torp_eject_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject `wep_torp_eject_t1.mp3`: reads as a dull muffled air puff with weak steel-rail character, missing the crisp mechanical launch-cell identity needed to replace today's generic `whoosh` and synthy `ionCharge` (`today0`, `today1`).
  2. **Bass (<500 Hz):** Yes, bass trap. Measured 96.3% below 500 Hz (96.0% above 30 Hz), 2.4% in 500 Hz to 2 kHz, 1.2% above 2 kHz (centroid 239 Hz, 7.7% below 20 Hz).
  3. **Mono:** Softens on top (corr 0.75, -0.62 dB overall, -1.61 dB mid, -2.01 dB above 2 kHz), dulling the already faint rail slide.
- **`wep_torp_eject_t2.mp3` -> REJECT (mono fail).**
  1. **Verdict:** Reject `wep_torp_eject_t2.mp3`: sounds great in stereo with a punchy gas push and crisp steel rail stop, far better than today's `whoosh` and `ionCharge` (`today0`, `today1`), but collapses badly when folded to mono.
  2. **Bass (<500 Hz):** Yes in mono as mids/highs cancel. Measured 88.4% below 500 Hz, 8.9% in 500 Hz to 2 kHz, 2.7% above 2 kHz (centroid 338 Hz).
  3. **Mono:** Fails mono. Very wide stereo (corr 0.24) drops -2.07 dB overall, -3.05 dB in 500 Hz to 2 kHz, -3.58 dB above 2 kHz, and -1.84 dB attack; by ear in mono the steel rail slide turns hollow and dull.
- **ID Pick (`wep_torp_eject`):** Neither, re-roll. Drop `"deep compressed-gas thump"` and lead with `"close centered heavy steel rail slide, crisp pneumatic burst, and solid mechanical latch clunk"` so the hardware detail cuts through in mono.

### 8. `evt_pass_by_slug` (no clip today)

- **`evt_pass_by_slug_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject `evt_pass_by_slug_t1.mp3`: starts late (30.6 ms dead head) and reads as a muffled sub-bass thud rather than a supersonic heavy slug whipping close past the camera (no baseline clip today).
  2. **Bass (<500 Hz):** Yes, extreme bass trap. Measured 99.4% below 500 Hz, 0.2% in 500 Hz to 2 kHz, 0.4% above 2 kHz (centroid 86 Hz); almost invisible on small speakers.
  3. **Mono:** Passes overall (corr 0.85, -0.35 dB), but drops -2.25 dB in 500 Hz to 2 kHz and -1.65 dB above 2 kHz, erasing the little pass-by air it had.
- **`evt_pass_by_slug_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject `evt_pass_by_slug_t2.mp3`: tighter and cleaner in mono than `t1`, but still trapped below 500 Hz so it sounds like a muffled low boom instead of a fast close-pass projectile (no baseline clip today).
  2. **Bass (<500 Hz):** Yes, bass trap. Measured 95.9% below 500 Hz, 2.8% in 500 Hz to 2 kHz, 1.2% above 2 kHz (centroid 157 Hz, 2.6% below 20 Hz).
  3. **Mono:** Passes mono cleanly (corr 0.89, -0.28 dB overall, -0.82 dB mid, -0.84 dB high), but lacks upper-mid Doppler zip.
- **ID Pick (`evt_pass_by_slug`):** Neither, re-roll. Drop `"deep heavy"`, `"low and solid"`, and `"dark tail"`; ask for a fast high-velocity Doppler pressure whip and crisp midrange air zip over a tight brief thump.

### 9. `wep_directorate_turbo` (vs `today0` laserLarge, `today1` plasmaShot)

- **`wep_directorate_turbo_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep `wep_directorate_turbo_t1.mp3`: disciplined, cold, authoritative medium-heavy plasma cannon discharge with zero raygun chirp, completely replacing today's retro arcade `laserLarge` and `plasmaShot` (`today0`, `today1`).
  2. **Bass (<500 Hz):** No, well balanced for a heavy plasma shot. Measured 79.5% below 500 Hz, 9.1% in 500 Hz to 2 kHz, 11.4% above 2 kHz (centroid 719 Hz, -17.9 dB RMS, 0.0% below 20 Hz); crisp arc crack reads clearly over weighted low recoil.
  3. **Mono:** Rock-solid mono (corr 0.96, -0.08 dB overall, -0.09 dB mid, -0.29 dB above 2 kHz, -0.12 dB attack); keeps full snap and punch on one speaker.
- **`wep_directorate_turbo_t2.mp3` -> KEEP (strong round-robin variant).**
  1. **Verdict:** Keep `wep_directorate_turbo_t2.mp3`: slightly brighter, tighter plasma crack matching `t1`'s loudness (`-17.8 dB` vs `-17.9 dB`) and cold Directorate discipline, far ahead of today's `laserLarge` and `plasmaShot` (`today0`, `today1`).
  2. **Bass (<500 Hz):** No. Measured 76.9% below 500 Hz, 9.5% in 500 Hz to 2 kHz, 13.6% above 2 kHz (centroid 846 Hz, 0.0% below 20 Hz).
  3. **Mono:** Passes mono cleanly (corr 0.89, -0.24 dB overall, -0.42 dB mid, -0.97 dB above 2 kHz, -0.48 dB attack).
- **ID Pick (`wep_directorate_turbo`):** Keep `wep_directorate_turbo_t1.mp3` (and keep `wep_directorate_turbo_t2.mp3` as a ready round-robin partner).

### 10. `wep_directorate_hturbo` (vs `today0` laserLarge, `today1` plasmaShot)

- **`wep_directorate_hturbo_t1.mp3` -> KEEP (dark-leaning, light +3 dB presence lift in mastering).**
  1. **Verdict:** Keep `wep_directorate_hturbo_t1.mp3`: commanding flagship plasma blast with a fierce superheated arc crack, flat steady pitch, and heavy recoil decay, miles beyond today's arcade `laserLarge` and `plasmaShot` (`today0`, `today1`).
  2. **Bass (<500 Hz):** Borderline yes on raw ratio, but bright enough on top to master cleanly. Measured 88.6% below 500 Hz, 3.0% in 500 Hz to 2 kHz, 8.4% above 2 kHz (centroid 529 Hz, -17.5 dB RMS, 0.4% below 20 Hz); the 8.4% top crack reads clearly by ear.
  3. **Mono:** Pure dual-mono (corr 1.00, -0.01 dB overall, -0.03 dB mid, -0.04 dB above 2 kHz, -0.02 dB attack); zero mono loss.
- **`wep_directorate_hturbo_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject `wep_directorate_hturbo_t2.mp3`: much quieter (`-25.8 dB` RMS), slower peaking (194 ms vs 85 ms on `t1`), and duller than `t1`, losing the flagship plasma snap despite beating today's `laserLarge` (`today0`) in realism.
  2. **Bass (<500 Hz):** Yes, bass-trapped. Measured 92.2% below 500 Hz, 2.4% in 500 Hz to 2 kHz, 5.4% above 2 kHz (centroid 392 Hz).
  3. **Mono:** Passes mono (corr 0.97, -0.08 dB overall, -0.72 dB above 2 kHz), but weaker and slower than `t1`.
- **ID Pick (`wep_directorate_hturbo`):** Keep `wep_directorate_hturbo_t1.mp3` (add a light upper-mid lift in mastering).

### 11. `wep_directorate_ion_beam` (vs `today0` arc, `today1` ionField)

- **`wep_directorate_ion_beam_t1.mp3` -> KEEP (loop 0.25 to 0.70 s core in Godot for long beams).**
  1. **Verdict:** Keep `wep_directorate_ion_beam_t1.mp3`: crisp plasma ignition straight into a thick, cold, industrial Tesla-coil buzzing ion arc holding one steady pitch, a night-and-day upgrade over today's harsh synth `arc` and flat `ionField` (`today0`, `today1`).
  2. **Bass (<500 Hz):** No. Measured 64.4% below 500 Hz, 8.4% in 500 Hz to 2 kHz, 27.2% above 2 kHz (centroid 2231 Hz, -19.2 dB RMS, 0.0% below 20 Hz); sharp high-voltage buzz over strong transformer hum. Note: decays past ~0.8 s (`T95 = 762 ms`, `-16.3 dB` in 0.3 to 0.8 s vs `-29.0 dB` in 0.8 to 1.3 s), so loop the steady middle in Godot for longer beams.
  3. **Mono:** Wide stereo (corr 0.40, -1.57 dB overall, -1.24 dB mid, -1.87 dB above 2 kHz, -1.03 dB attack), slightly narrower on one speaker, but by ear in mono it keeps its fierce ignition snap and unbroken industrial buzz cleanly.
- **`wep_directorate_ion_beam_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject `wep_directorate_ion_beam_t2.mp3`: very quiet (`-34.0 dB` RMS), huge 92.2 ms dead head, and a thinner welder buzz that feels small compared with `t1` and even today's loud `ionField` (`today1`).
  2. **Bass (<500 Hz):** No. Measured 68.8% below 500 Hz (63.0% above 30 Hz), 6.9% mid, 24.2% above 2 kHz (centroid 2009 Hz, 7.2% below 20 Hz).
  3. **Mono:** Rock-solid mono (corr 0.98, -0.04 dB overall), but far too quiet and thin to beat `t1`.
- **ID Pick (`wep_directorate_ion_beam`):** Keep `wep_directorate_ion_beam_t1.mp3` (trim 5 ms dead head; loop steady core for beams past 0.7 s).

### 12. `wep_directorate_picket` (vs `today0` gunFlak)

- **`wep_directorate_picket_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject `wep_directorate_picket_t1.mp3`: sounds like a tiny, quiet muffled low tap (`-26.7 dB` RMS) with zero crisp point-defense plasma edge, losing clarity badly against today's `gunFlak` (`today0`, 51% mid, 21% high).
  2. **Bass (<500 Hz):** Yes, severe bass trap. Measured 99.8% below 500 Hz, 0.1% in 500 Hz to 2 kHz, 0.2% above 2 kHz (centroid 129 Hz).
  3. **Mono:** Dual-mono (corr 0.99, -0.02 dB overall), completely dull on every speaker.
- **`wep_directorate_picket_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject `wep_directorate_picket_t2.mp3`: another muffled low bass pop with zero bright plasma pulse bite, unreadable as defensive laser fire compared with today's `gunFlak` (`today0`).
  2. **Bass (<500 Hz):** Yes, severe bass trap. Measured 99.9% below 500 Hz, 0.1% in 500 Hz to 2 kHz, 0.0% above 2 kHz (centroid 103 Hz, -23.6 dB RMS).
  3. **Mono:** Dual-mono (corr 0.99, -0.01 dB overall), zero top end.
- **ID Pick (`wep_directorate_picket`):** Neither, re-roll. Drop `"compact firm low-mid punch"` and prompt `"one short bright crisp high-voltage plasma-arc tick and disciplined light energy snap"` so it cuts cleanly above 1 kHz.

### 13. `wep_hullbreaker_scatter` (vs `today0` boomLow, `today1` shellBang)

- **`wep_hullbreaker_scatter_t1.mp3` -> KEEP (standout Hullbreaker take).**
  1. **Verdict:** Keep `wep_hullbreaker_scatter_t1.mp3`: filthy, ragged, overdriven scrap-cannon blast with tumbling steel fragments and a rattling iron housing, dripping with Hullbreaker character and crushing today's generic `boomLow` and `shellBang` (`today0`, `today1`).
  2. **Bass (<500 Hz):** No. Ideal full-band balance: 53.5% below 500 Hz, 23.9% in 500 Hz to 2 kHz, 22.6% above 2 kHz (centroid 1654 Hz, -12.4 dB RMS, 0.0% below 20 Hz).
  3. **Mono:** Rock-solid mono (corr 0.99, -0.02 dB overall, -0.01 dB mid, -0.06 dB above 2 kHz, -0.02 dB attack); zero loss on one speaker.
- **`wep_hullbreaker_scatter_t2.mp3` -> KEEP (alternate).**
  1. **Verdict:** Keep `wep_hullbreaker_scatter_t2.mp3` as a second take: equally gritty, rough metallic scrap blast beating today's `boomLow` and `shellBang` (`today0`, `today1`), with a slightly slower peak (79 ms vs 20 ms on `t1`).
  2. **Bass (<500 Hz):** No. Measured 51.9% below 500 Hz, 30.4% in 500 Hz to 2 kHz, 17.7% above 2 kHz (centroid 1129 Hz, -11.6 dB RMS).
  3. **Mono:** Moderate stereo (corr 0.51, -1.21 dB overall, -0.64 dB mid, -1.18 dB above 2 kHz, -1.17 dB attack); slightly narrower rattle in mono, still gritty and punchy by ear.
- **ID Pick (`wep_hullbreaker_scatter`):** Keep `wep_hullbreaker_scatter_t1.mp3` (tighter onset and near-zero mono loss; `t2` works as a round-robin alternate).

### 14. `wep_hullbreaker_rockets` (vs `today0` torpRocket)

- **`wep_hullbreaker_rockets_t1.mp3` -> REJECT (mono fail).**
  1. **Verdict:** Reject `wep_hullbreaker_rockets_t1.mp3`: gritty, roaring solid-fuel rocket in stereo that beats today's flat `torpRocket` (`today0`), but loses its crackling exhaust bite and goes hollow when folded to mono.
  2. **Bass (<500 Hz):** No. Measured 73.7% below 500 Hz, 14.7% in 500 Hz to 2 kHz, 11.6% above 2 kHz (centroid 758 Hz).
  3. **Mono:** Fails mono. Very wide stereo (corr 0.10) drops -2.60 dB overall, -3.76 dB in 500 Hz to 2 kHz, -3.51 dB above 2 kHz, and -2.94 dB attack; audibly thins out on one speaker.
- **`wep_hullbreaker_rockets_t2.mp3` -> KEEP (trim 7 ms dead head).**
  1. **Verdict:** Keep `wep_hullbreaker_rockets_t2.mp3`: punchy, unrefined crude rocket ignition surging into a rough crackling solid-fuel streak, clearly more physical and dirty than today's dull `torpRocket` (`today0`).
  2. **Bass (<500 Hz):** No. Balanced full-band texture: 58.4% below 500 Hz, 24.7% in 500 Hz to 2 kHz, 16.9% above 2 kHz (centroid 1015 Hz, -20.9 dB RMS, 0.0% below 20 Hz).
  3. **Mono:** Passes mono cleanly (corr 0.90, -0.23 dB overall, -0.18 dB mid, -0.69 dB above 2 kHz, -0.36 dB attack); keeps full gritty roar on one speaker.
- **ID Pick (`wep_hullbreaker_rockets`):** Keep `wep_hullbreaker_rockets_t2.mp3`.

### 15. `wep_hullbreaker_junk_gun` (vs `today0` boomLow, `today1` shellBang)

- **`wep_hullbreaker_junk_gun_t1.mp3` -> REJECT (bass trap + mono fail).**
  1. **Verdict:** Reject `wep_hullbreaker_junk_gun_t1.mp3`: sounds clanky in stereo, but collapses into a muffled, weak low thud in mono, losing the loose iron-rattle identity against today's `shellBang` (`today1`).
  2. **Bass (<500 Hz):** Yes, bass trap. Measured 97.0% below 500 Hz, 2.2% in 500 Hz to 2 kHz, 0.7% above 2 kHz (centroid 106 Hz, 2.8% below 20 Hz).
  3. **Mono:** Fails mono. Very wide stereo (corr 0.12) drops -2.53 dB overall and -2.64 dB on the attack, noticeably gutting its punch.
- **`wep_hullbreaker_junk_gun_t2.mp3` -> REJECT (bass trap + huge DC offset).**
  1. **Verdict:** Reject `wep_hullbreaker_junk_gun_t2.mp3`: mono-locked, but carries a 61.7% DC/infrasonic offset and remains too muffled even above 30 Hz to deliver the loose clattering scrap-turret character against today's `shellBang` (`today1`).
  2. **Bass (<500 Hz):** Yes, bass trap. Measured 97.6% below 500 Hz raw (61.7% below 20 Hz, DC +0.025); even above 30 Hz it is still 90.8% below 500 Hz, 4.5% mid, 4.8% above 2 kHz (centroid 96 Hz).
  3. **Mono:** Rock-solid mono (corr 0.99, -0.02 dB overall, -0.61 dB above 2 kHz), just far too dark.
- **ID Pick (`wep_hullbreaker_junk_gun`):** Neither, re-roll. Drop `"blunt low thump"` and ask for a bright clattering iron-housing rattle and rough metallic scrap-turret crack (full-band like `wep_hullbreaker_scatter_t1`, just tighter and lighter).

### 16. `wep_chorus_bioplasma` (vs `today0` gunGlob)

- **`wep_chorus_bioplasma_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject `wep_chorus_bioplasma_t1.mp3`: envelope is backward for a `t=0` weapon fire cue (peak at 879 ms of an 880 ms clip!) and reads like an industrial sewer-pipe drone rather than an organic Chorus launch, worse in timing than today's tiny `gunGlob` (`today0`).
  2. **Bass (<500 Hz):** No, midrange-heavy industrial hum. Measured 35.9% below 500 Hz, 62.6% in 500 Hz to 2 kHz, 1.4% above 2 kHz (centroid 651 Hz).
  3. **Mono:** Passes mono (corr 0.92, -0.19 dB overall, -1.10 dB above 2 kHz), but the backward envelope and industrial tone make it unusable.
- **`wep_chorus_bioplasma_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject `wep_chorus_bioplasma_t2.mp3`: better timing than `t1`, but sounds like a hollow industrial culvert foghorn resonance (585 Hz peak) with no wet organic Chorus texture, missing the organic character of today's `gunGlob` (`today0`) even at larger scale.
  2. **Bass (<500 Hz):** No, midrange-heavy pipe tone. Measured 39.0% below 500 Hz, 59.5% in 500 Hz to 2 kHz, 1.5% above 2 kHz (centroid 577 Hz).
  3. **Mono:** Rock-solid mono (corr 0.99, -0.02 dB overall), but wrong faction identity (still used the un-rewritten `"industrial culvert"` prompt).
- **ID Pick (`wep_chorus_bioplasma`):** Neither, re-roll (after confirming Chorus projectile look). Replace `"pressurized industrial culvert"` and `"molten mineral slag"` with pressurized wet calcified-sac / viscous organic ejection with an immediate `t=0` burst.

### 17. `wep_chorus_tendril` (vs `today0` grappleWet, `today1` hullHitBig, `today2` scrape, `today3` whoosh)

- **`wep_chorus_tendril_t1.mp3` -> KEEP (high-pass 40 Hz; check 374 ms sweep-peak timing).**
  1. **Verdict:** Keep `wep_chorus_tendril_t1.mp3`: monumental bone-and-timber crack with a heavy rushing lash sweep, far bigger and more physical than today's squishy `grappleWet` and synth `scrape` (`today0`, `today2`), though note it reads dry bone-wood rather than wet bio.
  2. **Bass (<500 Hz):** No. Balanced full-band body: 63.8% below 500 Hz (59.7% above 30 Hz after removing 9.4% below 20 Hz), 15.2% in 500 Hz to 2 kHz, 21.0% above 2 kHz (centroid 1317 Hz, -19.6 dB RMS).
  3. **Mono:** Rock-solid mono (corr 0.97, -0.06 dB overall, -0.02 dB mid, -0.23 dB above 2 kHz, -0.02 dB attack); keeps its full bone crack and rush on one speaker.
- **`wep_chorus_tendril_t2.mp3` -> KEEP (alternate with faster 91 ms attack).**
  1. **Verdict:** Keep `wep_chorus_tendril_t2.mp3` as an alternate: hits much sooner (`peak 91 ms` vs `374 ms` on `t1`) with a sharp bone snap and rushing sweep that beats today's `grappleWet` (`today0`), though wider in stereo than `t1`.
  2. **Bass (<500 Hz):** No. Measured 53.5% below 500 Hz, 24.8% in 500 Hz to 2 kHz, 21.6% above 2 kHz (centroid 1385 Hz, 2.1% below 20 Hz).
  3. **Mono:** Moderate-wide stereo (corr 0.42, -1.50 dB overall, -1.23 dB mid, -1.74 dB above 2 kHz, -1.39 dB attack); air sweep softens slightly in mono, but by ear the hard bone lash still survives cleanly.
- **ID Pick (`wep_chorus_tendril`):** Keep `wep_chorus_tendril_t1.mp3` for mono lock (pick `t2` if the visual lash needs an immediate `t=0` snap; note both are dry bone-timber, so layer subtle wet texture in Gate 3 if Ryan wants Chorus wetter).

### 18. `wep_chorus_spore_cloud` (vs `today0` gunFlak)

- **`wep_chorus_spore_cloud_t1.mp3` -> REJECT (no body + hard mono fail).**
  1. **Verdict:** Reject `wep_chorus_spore_cloud_t1.mp3`: thin, hissy air-hose spray with zero low-mid weight that collapses into hollow static in mono, weaker than today's punchier `gunFlak` (`today0`).
  2. **Bass (<500 Hz):** No (opposite problem: zero low body). Measured 0.8% below 500 Hz, 6.9% in 500 Hz to 2 kHz, 92.3% above 2 kHz (centroid 6544 Hz).
  3. **Mono:** Hard fail. Negative correlation (corr -0.12) drops -3.56 dB overall, -3.91 dB mid, -3.53 dB above 2 kHz, and -3.83 dB attack; sounds phasey and hollow in mono.
- **`wep_chorus_spore_cloud_t2.mp3` -> REJECT (pure white-noise hiss + mono fail).**
  1. **Verdict:** Reject `wep_chorus_spore_cloud_t2.mp3`: virtually pure high-frequency noise hiss with no organic body that thins out further in mono, losing to today's `gunFlak` (`today0`).
  2. **Bass (<500 Hz):** No (zero body). Measured 0.5% below 500 Hz, 1.2% in 500 Hz to 2 kHz, 98.2% above 2 kHz (centroid 9449 Hz).
  3. **Mono:** Fails mono. Very wide stereo (corr 0.17) drops -2.32 dB overall, -3.54 dB mid, -2.30 dB high, and -2.24 dB attack.
- **ID Pick (`wep_chorus_spore_cloud`):** Neither, re-roll. Drop `"fine mineral dust"` and `"gas blowout"` (which generated pure air-hose hiss); prompt a centered pressurized organic spore-pod burst with a firm woody-sac low-mid thump and coarse wet-organic scatter.

### 19. `wep_chorus_sporeb` (vs `today0` laserSmall)

- **`wep_chorus_sporeb_t1.mp3` -> REJECT (mono fail).**
  1. **Verdict:** Reject `wep_chorus_sporeb_t1.mp3`: crisp little pneumatic pop in stereo, but very quiet (`-29.1 dB` RMS) and collapses into a faint papery click in mono, failing to hold up beside today's loud `laserSmall` (`today0`).
  2. **Bass (<500 Hz):** No. Measured 45.0% below 500 Hz, 11.6% in 500 Hz to 2 kHz, 43.3% above 2 kHz (centroid 3189 Hz).
  3. **Mono:** Fails mono. Very wide stereo (corr 0.07) drops -2.74 dB overall, -2.94 dB mid, -3.38 dB above 2 kHz, and -2.74 dB attack.
- **`wep_chorus_sporeb_t2.mp3` -> KEEP (lift gain ~5 dB).**
  1. **Verdict:** Keep `wep_chorus_sporeb_t2.mp3`: tight, punchy compact pneumatic mortar launch with a clean dry crack, great strike-craft scale and a huge upgrade over today's arcade `laserSmall` pew (`today0`).
  2. **Bass (<500 Hz):** No. Bright and punchy: 31.1% below 500 Hz, 13.5% in 500 Hz to 2 kHz, 55.4% above 2 kHz (centroid 4397 Hz, -23.2 dB RMS, 0.0% below 20 Hz).
  3. **Mono:** Passes mono cleanly (corr 0.80, -0.48 dB overall, -0.71 dB mid, -0.63 dB above 2 kHz, -0.45 dB attack).
- **ID Pick (`wep_chorus_sporeb`):** Keep `wep_chorus_sporeb_t2.mp3`.

### 20. `wep_ithar_needle` (vs `today0` laserSmall, `today1` needleTick)

- **`wep_ithar_needle_t1.mp3` -> KEEP (dark-leaning; high-pass 50 Hz + upper-mid lift).**
  1. **Verdict:** Keep `wep_ithar_needle_t1.mp3`: crisp luminous prism snap into a clean glass-harmonic ring with a sharp cutoff, far more authentic Glasswright hardware than today's arcade `laserSmall` and tiny UI-like `needleTick` (`today0`, `today1`).
  2. **Bass (<500 Hz):** Borderline yes on raw ratio, but audible crystal ring survives. Measured 87.8% below 500 Hz (86.3% above 30 Hz after removing 9.3% below 20 Hz), 5.0% in 500 Hz to 2 kHz, 7.2% above 2 kHz (centroid 421 Hz, -24.4 dB RMS); lifting above 1.5 kHz brings the prism tone right forward.
  3. **Mono:** Pure dual-mono (corr 1.00, 0.00 dB overall, -0.01 dB mid, -0.02 dB above 2 kHz, 0.00 dB attack); zero mono loss.
- **`wep_ithar_needle_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject `wep_ithar_needle_t2.mp3`: carries 25.2% infrasonic waste below 20 Hz and thinner midrange harmonic body than `t1`, sounding more hollow despite beating today's `laserSmall` (`today0`).
  2. **Bass (<500 Hz):** Yes. Measured 92.4% below 500 Hz raw (25.2% below 20 Hz; 86.3% above 30 Hz), only 1.7% in 500 Hz to 2 kHz, 5.9% above 2 kHz (centroid 293 Hz).
  3. **Mono:** Dual-mono (corr 1.00, 0.00 dB loss), beaten clearly by `t1`'s richer midrange crystal body.
- **ID Pick (`wep_ithar_needle`):** Keep `wep_ithar_needle_t1.mp3` (high-pass 50 Hz, lift gain and upper mids).

### 21. `wep_ithar_pulsar` (vs `today0` laserSmall, `today1` choirBell)

- **`wep_ithar_pulsar_t1.mp3` -> KEEP (trim 7 ms dead head; loop steady core for long beams).**
  1. **Verdict:** Keep `wep_ithar_pulsar_t1.mp3`: luminous prism ignition into a majestic, pure, non-vocal bowed-crystal harmonic chord over a warm low drone, completely outclassing today's arcade `laserSmall` and plain synth `choirBell` (`today0`, `today1`).
  2. **Bass (<500 Hz):** No. Gorgeous full-band crystal spread: 35.0% below 500 Hz, 29.6% in 500 Hz to 2 kHz, 35.3% above 2 kHz (centroid 1736 Hz, -20.8 dB RMS, 0.2% below 20 Hz). Note: decays past ~0.5 s (`T95 = 405 ms`, `-52.8 dB` in 0.8 to 1.3 s), so loop the 0.1 to 0.45 s chord core in Godot for sustained beams.
  3. **Mono:** Passes mono cleanly (corr 0.55, -1.11 dB overall, -0.97 dB mid, -0.97 dB above 2 kHz, -0.49 dB attack); by ear in mono the crystal chord stays radiant and clear.
- **`wep_ithar_pulsar_t2.mp3` -> REJECT (mono fail + late onset).**
  1. **Verdict:** Reject `wep_ithar_pulsar_t2.mp3`: starts late (38.7 ms dead head, peak 332 ms) and hollows out its crystalline chord body badly when summed to mono, losing cleanly to `t1`.
  2. **Bass (<500 Hz):** No. Measured 47.8% below 500 Hz, 9.6% in 500 Hz to 2 kHz, 42.6% above 2 kHz (centroid 2553 Hz).
  3. **Mono:** Fails mono. Very wide stereo (corr 0.11) drops -2.56 dB overall, -3.32 dB in 500 Hz to 2 kHz, -1.97 dB above 2 kHz, and -1.59 dB attack; noticeably thins out on one speaker.
- **ID Pick (`wep_ithar_pulsar`):** Keep `wep_ithar_pulsar_t1.mp3`.

### 22. `wep_ithar_startorp` (vs `today0` whoosh, `today1` starShimmer)

- **`wep_ithar_startorp_t1.mp3` -> KEEP (alternate, lift gain).**
  1. **Verdict:** Keep `wep_ithar_startorp_t1.mp3` as a lighter variant: bright shimmering crystalline impulse receding into a luminous hum, far more physical and majestic than today's generic `whoosh` and retro synth arpeggio `starShimmer` (`today0`, `today1`).
  2. **Bass (<500 Hz):** No. Bright crystalline spectrum: 10.1% below 500 Hz, 32.4% in 500 Hz to 2 kHz, 57.5% above 2 kHz (centroid 4200 Hz, -24.1 dB RMS, 0.0% below 20 Hz).
  3. **Mono:** Passes mono (corr 0.60, -0.97 dB overall, -0.46 dB mid, -1.37 dB above 2 kHz, -0.84 dB attack); keeps its shimmer cleanly.
- **`wep_ithar_startorp_t2.mp3` -> KEEP (lead pick; trim 10 ms dead head + high-pass 35 Hz).**
  1. **Verdict:** Keep `wep_ithar_startorp_t2.mp3`: fuller, louder (`-18.2 dB` vs `-24.1 dB`), longer receding radiant crystal launch (`T95 = 666 ms` vs `401 ms`) with both warm low push and shimmering upper harmonics, crushing today's `whoosh` and `starShimmer` (`today0`, `today1`).
  2. **Bass (<500 Hz):** No. Measured 37.0% below 500 Hz raw (19.0% in 30 to 500 Hz after stripping 8.7% below 20 Hz), 3.4% mid, 59.6% above 2 kHz (centroid 3003 Hz).
  3. **Mono:** Passes mono cleanly (corr 0.84, -0.35 dB overall, -0.17 dB mid, -0.53 dB above 2 kHz, -0.21 dB attack); tight and radiant on one speaker.
- **ID Pick (`wep_ithar_startorp`):** Keep `wep_ithar_startorp_t2.mp3` (`t1` works as a lighter variant).

### 23. `wep_eclipse_gsentry` (vs `today0` boomLow, `today1` railStrike)

- **`wep_eclipse_gsentry_t1.mp3` -> REJECT (hard mono fail).**
  1. **Verdict:** Reject `wep_eclipse_gsentry_t1.mp3`: eerily snappy in stereo, but severely out of phase between channels and collapses to a tiny `-37.3 dB` whisper in mono, losing completely to today's `railStrike` (`today1`).
  2. **Bass (<500 Hz):** No in mono ratio (72.0% below 500 Hz, 15.8% mid, 12.2% high, centroid 620 Hz), because the low-end void drop cancels itself out.
  3. **Mono:** Hard fail. Strong negative correlation (corr -0.40) drops -5.21 dB overall and -4.82 dB on the attack; almost vanishes in mono.
- **`wep_eclipse_gsentry_t2.mp3` -> REJECT (mono fail + bass trap).**
  1. **Verdict:** Reject `wep_eclipse_gsentry_t2.mp3`: punches nicely in stereo, but folds down to a dull, muted low thud in mono, losing the crisp electrostatic snap compared with today's `railStrike` (`today1`).
  2. **Bass (<500 Hz):** Yes, bass trap. Measured 92.0% below 500 Hz, 3.7% in 500 Hz to 2 kHz, 4.3% above 2 kHz (centroid 337 Hz).
  3. **Mono:** Fails mono. Zero correlation (corr 0.01) drops -2.95 dB overall, -1.68 dB mid, -2.11 dB above 2 kHz, and -3.23 dB on the attack.
- **ID Pick (`wep_eclipse_gsentry`):** Neither, re-roll. Drop `"deep hollow sub-bass drop"` and prompt `"one centered tight cold electrostatic void snap paired with a compact hollow mid-low magnetic knock cutting sharply into silence"`.

### 24. `wep_eclipse_gauss_charge` (vs `today0` ionCharge, `today1` arc)

- **`wep_eclipse_gauss_charge_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject `wep_eclipse_gauss_charge_t1.mp3`: opens with 128.6 ms of dead silence (wasting a huge chunk of the charge lead) and loses its crisp coil edge in mono, losing clearly to `t2` despite beating today's synthy `ionCharge` (`today0`).
  2. **Bass (<500 Hz):** No. Measured 73.2% below 500 Hz, 23.8% in 500 Hz to 2 kHz, 3.0% above 2 kHz (centroid 477 Hz).
  3. **Mono:** Drops top end (corr 0.78, -0.50 dB overall, -0.88 dB mid, -2.82 dB above 2 kHz).
- **`wep_eclipse_gauss_charge_t2.mp3` -> KEEP (trim 27 ms dead head).**
  1. **Verdict:** Keep `wep_eclipse_gauss_charge_t2.mp3`: dread-filled ancient gravitational hum and cold electrical coil tension swelling tightly and cutting into dead silence, far more menacing and physical than today's synthy `ionCharge` and harsh `arc` (`today0`, `today1`).
  2. **Bass (<500 Hz):** No. Measured 74.8% below 500 Hz, 21.2% in 500 Hz to 2 kHz, 4.0% above 2 kHz (centroid 506 Hz, strong -14.7 dB RMS, 0.0% below 20 Hz); menacing midrange coil whine reads clearly on small speakers.
  3. **Mono:** Passes mono (corr 0.62, -0.90 dB overall, -1.68 dB mid, -0.90 dB above 2 kHz, -1.00 dB attack); keeps its ominous swell cleanly on one speaker.
- **ID Pick (`wep_eclipse_gauss_charge`):** Keep `wep_eclipse_gauss_charge_t2.mp3` (trim 27 ms dead head).

### 25. `wep_eclipse_nlance` (vs `today0` laserLarge, `today1` darkLance)

- **`wep_eclipse_nlance_t1.mp3` -> KEEP (dark-leaning, matches Ryan's Eclipse taste; add presence lift).**
  1. **Verdict:** Keep `wep_eclipse_nlance_t1.mp3`: eerie cold snap into a dark hollow bowed-obsidian note (398 Hz resonant tone) cutting cleanly to silence, far more ominous and distinct than today's arcade `laserLarge` and thin whooshy `darkLance` (`today0`, `today1`).
  2. **Bass (<500 Hz):** Borderline yes on raw band share, but holds a clear audible 400 Hz tone. Measured 91.0% below 500 Hz, 9.0% in 500 Hz to 2 kHz, 0.0% above 2 kHz (centroid 337 Hz, -19.9 dB RMS, 0.0% below 20 Hz); add a subtle presence boost in mastering.
  3. **Mono:** Pure dual-mono (corr 1.00, 0.00 dB overall, -0.01 dB mid, 0.00 dB attack); zero mono loss.
- **`wep_eclipse_nlance_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject `wep_eclipse_nlance_t2.mp3`: loses the cold electrostatic snap and hollow upper-low resonance, collapsing into a plain dull rumble compared with `t1`.
  2. **Bass (<500 Hz):** Yes, severe bass trap. Measured 98.9% below 500 Hz, 1.0% in 500 Hz to 2 kHz, 0.0% above 2 kHz (centroid 163 Hz, -22.3 dB RMS).
  3. **Mono:** Dual-mono (corr 1.00, -0.01 dB overall), but far too muffled to ship.
- **ID Pick (`wep_eclipse_nlance`):** Keep `wep_eclipse_nlance_t1.mp3` (add upper-mid presence lift in mastering).

### 26. `wep_eclipse_doom` (vs `today0` laserLarge, `today1` darkLance)

- **`wep_eclipse_doom_t1.mp3` -> KEEP (standout Eclipse superweapon; lift gain ~8 dB, loop steady middle for long beams).**
  1. **Verdict:** Keep `wep_eclipse_doom_t1.mp3`: terrifying seismic-charge slam expanding into a vast, cold hollow bowed-obsidian void drone (334 Hz pitch), delivering real world-ending dread that completely eclipses today's `laserLarge` and whispery `darkLance` (`today0`, `today1`).
  2. **Bass (<500 Hz):** No, remarkably well balanced for Eclipse! Measured 51.8% below 500 Hz, 47.6% in 500 Hz to 2 kHz, 0.6% above 2 kHz (centroid 617 Hz, -28.2 dB raw RMS, 1.8% below 20 Hz); reads huge even on small speakers. Note: decays past ~0.85 s (`T95 = 747 ms`, `-37.4 dB` in 0.8 to 1.3 s), so loop the steady middle in Godot for long arcs.
  3. **Mono:** Pure dual-mono (corr 1.00, -0.01 dB overall, -0.01 dB mid, -0.02 dB attack); zero mono loss.
- **`wep_eclipse_doom_t2.mp3` -> KEEP (alternate; lift gain ~9 dB, trim 24 ms dead head).**
  1. **Verdict:** Keep `wep_eclipse_doom_t2.mp3` as an alternate: similarly huge hollow void drone (348 Hz resonant pitch) crushing today's `darkLance` (`today1`), just slightly slower to peak (599 ms vs 372 ms on `t1`) and 1 dB quieter.
  2. **Bass (<500 Hz):** No. Measured 59.7% below 500 Hz, 39.8% in 500 Hz to 2 kHz, 0.4% above 2 kHz (centroid 556 Hz, -29.3 dB raw RMS, 0.0% below 20 Hz).
  3. **Mono:** Pure dual-mono (corr 0.99, -0.01 dB overall, -0.01 dB mid, -0.01 dB attack).
- **ID Pick (`wep_eclipse_doom`):** Keep `wep_eclipse_doom_t1.mp3` (stronger, quicker slam; lift gain and loop middle section if beam exceeds ~0.8 s).

### 27. `wep_eclipse_doom_charge` (vs `today0` ionCharge, `today1` arc)

- **`wep_eclipse_doom_charge_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject `wep_eclipse_doom_charge_t1.mp3`: half the clip is dead silence (340.5 ms dead head on a 680 ms file) and the swell is tiny (`-31.3 dB` RMS), failing to telegraph a superweapon compared with today's audible `ionCharge` (`today0`).
  2. **Bass (<500 Hz):** Yes. Measured 87.1% below 500 Hz (86.1% above 30 Hz), 9.3% in 500 Hz to 2 kHz, 3.6% above 2 kHz (centroid 334 Hz, 4.6% below 20 Hz).
  3. **Mono:** Passes mono (corr 0.89, -0.30 dB overall, -1.19 dB high), but timing and level fail.
- **`wep_eclipse_doom_charge_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject `wep_eclipse_doom_charge_t2.mp3`: clean immediate reverse-suction swell into cutoff, but almost all sub-500 Hz rumble so players on normal speakers barely hear the pull-in warning before the Corona arc strikes (today's `ionCharge` has 66% above 2 kHz).
  2. **Bass (<500 Hz):** Yes, confirmed bass trap. Measured 95.5% below 500 Hz, 4.2% in 500 Hz to 2 kHz, 0.4% above 2 kHz (centroid 150 Hz, -23.5 dB RMS, 3.3% below 20 Hz).
  3. **Mono:** Rock-solid mono (corr 0.96, -0.10 dB overall), just missing audible midrange vacuum-suction tension.
- **ID Pick (`wep_eclipse_doom_charge`):** Neither, re-roll. Drop `"deep reverse-suction sub-bass"` and prompt `"a tight centered inward vacuum air-pull rush with rising cold electrostatic coil tension snapping abruptly into dead silence"` so the pull-in reads on every speaker.

### 28. `wep_craft_guns` (vs `today0` laserSmall)

- **`wep_craft_guns_t1.mp3` -> KEEP (alternate; high-pass 40 Hz for DC offset).**
  1. **Verdict:** Keep `wep_craft_guns_t1.mp3` as a second burst variant: crisp, fast space-fighter autocannon burst that sounds like real small-caliber space hardware instead of today's arcade `laserSmall` pew (`today0`).
  2. **Bass (<500 Hz):** No. Measured 74.3% below 500 Hz raw (69.6% in 30 to 500 Hz after stripping 14.5% below 20 Hz DC offset), 12.4% mid, 13.3% above 2 kHz (centroid 930 Hz, -16.0 dB RMS).
  3. **Mono:** Moderate stereo (corr 0.51, -1.41 dB overall, -0.87 dB mid, -1.60 dB above 2 kHz, -0.92 dB attack); slightly narrower in mono, still punchy and clean.
- **`wep_craft_guns_t2.mp3` -> KEEP (lead pick; high-pass 40 Hz for DC offset).**
  1. **Verdict:** Keep `wep_craft_guns_t2.mp3`: punchier, louder (`-11.5 dB` RMS), tighter rapid fighter burst (`T95 = 147 ms`) with zero synth feel, obliterating today's arcade `laserSmall` (`today0`).
  2. **Bass (<500 Hz):** No. Measured 79.6% below 500 Hz raw (76.1% in 30 to 500 Hz after stripping 13.8% below 20 Hz DC offset), 12.4% mid, 8.0% above 2 kHz (centroid 655 Hz).
  3. **Mono:** Passes mono cleanly (corr 0.91, -0.20 dB overall, -0.21 dB mid, -1.16 dB above 2 kHz, -0.19 dB attack); much tighter in mono than `t1`.
- **ID Pick (`wep_craft_guns`):** Keep `wep_craft_guns_t2.mp3` (`t1` works as a round-robin alternate; high-pass both at 40 Hz).

### 29. `wep_craft_bombs` (vs `today0` laserSmall)

- **`wep_craft_bombs_t1.mp3` -> KEEP (lift gain ~6 dB).**
  1. **Verdict:** Keep `wep_craft_bombs_t1.mp3`: crisp electromagnetic rack release thunk, short mechanical drop, and brief thruster kick that clearly reads as ordnance release instead of today's placeholder `laserSmall` pew (`today0`).
  2. **Bass (<500 Hz):** No. Crisp mechanical detail: 37.0% below 500 Hz, 12.5% in 500 Hz to 2 kHz, 50.5% above 2 kHz (centroid 3522 Hz, -25.7 dB raw RMS, 0.4% below 20 Hz).
  3. **Mono:** Passes mono cleanly (corr 0.53, -1.17 dB overall, -1.17 dB mid, -1.55 dB above 2 kHz, -1.16 dB attack); by ear in mono the rack clunk and thruster kick stay sharp and clear.
- **`wep_craft_bombs_t2.mp3` -> REJECT (mono fail).**
  1. **Verdict:** Reject `wep_craft_bombs_t2.mp3`: clean rack release in stereo, but loses its sharp mechanical clunk and top bite when summed to mono, losing clearly to `t1`.
  2. **Bass (<500 Hz):** No. Measured 34.2% below 500 Hz, 10.9% mid, 54.9% above 2 kHz (centroid 4001 Hz).
  3. **Mono:** Fails mono. Very wide stereo (corr 0.15) drops -2.39 dB overall, -2.58 dB mid, -3.10 dB above 2 kHz, and -2.55 dB attack; audibly thins out on one speaker.
- **ID Pick (`wep_craft_bombs`):** Keep `wep_craft_bombs_t1.mp3`.

### 30. `wep_mech_recoil_tail` (vs `today0` boomLow, `today1` salvoBoom)

- **`wep_mech_recoil_tail_t1.mp3` -> KEEP (lead pick; trim 8 ms dead head, lift gain).**
  1. **Verdict:** Keep `wep_mech_recoil_tail_t1.mp3`: tactile damped hydraulic piston return, heavy steel block seating solidly, and brief coolant gas vent, purpose-built for a pri-0 volley tail instead of today's boomy `boomLow` and `salvoBoom` (`today0`, `today1`).
  2. **Bass (<500 Hz):** No. Balanced mechanical body: 68.4% below 500 Hz, 20.3% in 500 Hz to 2 kHz, 11.3% above 2 kHz (centroid 886 Hz, -27.1 dB raw RMS, 0.0% below 20 Hz).
  3. **Mono:** Rock-solid mono (corr 0.99, -0.02 dB overall, -0.02 dB mid, -0.07 dB above 2 kHz, -0.06 dB attack).
- **`wep_mech_recoil_tail_t2.mp3` -> KEEP (alternate; trim 9 ms dead head, lift gain).**
  1. **Verdict:** Keep `wep_mech_recoil_tail_t2.mp3` as an alternate: slightly airier coolant hiss and later seating clunk (`peak 308 ms` vs `135 ms` on `t1`), still completely physical machinery.
  2. **Bass (<500 Hz):** No. Measured 55.6% below 500 Hz, 18.9% mid, 25.5% above 2 kHz (centroid 1092 Hz, -27.5 dB raw RMS, 0.0% below 20 Hz).
  3. **Mono:** Passes mono cleanly (corr 0.92, -0.17 dB overall, -0.28 dB mid, -0.33 dB above 2 kHz, -0.37 dB attack).
- **ID Pick (`wep_mech_recoil_tail`):** Keep `wep_mech_recoil_tail_t1.mp3` (`t2` works as an alternate).

### 31. `wep_layer_body_heavy` (Layer B low-body test, no clip today)

- **`wep_layer_body_heavy_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep `wep_layer_body_heavy_t1.mp3`: pure, immediate, clean sub-bass structural thump with a dense hull shudder and zero stray clicks or hiss, hitting the Layer B low-body test spec cleanly (no baseline clip today).
  2. **Bass (<500 Hz):** Yes, by design (pure low-body layer). Measured 99.9% below 500 Hz (dominant 48.3 Hz, centroid 61 Hz, -18.2 dB RMS, only 0.9% below 20 Hz); intentionally pure low body to sit under attack clips.
  3. **Mono:** Pure dual-mono (corr 1.00, -0.01 dB overall, 0.00 dB attack); zero phase risk when layered.
- **`wep_layer_body_heavy_t2.mp3` -> KEEP (alternate, slightly higher 57 Hz punch).**
  1. **Verdict:** Keep `wep_layer_body_heavy_t2.mp3` as an alternate: instant `1 ms` peak and slightly tighter 57 Hz low punch with the same clean, artifact-free hull body (no baseline clip today).
  2. **Bass (<500 Hz):** Yes, by design (pure low-body layer). Measured 99.8% below 500 Hz (dominant 56.7 Hz, centroid 62 Hz, -19.3 dB RMS, 1.0% below 20 Hz).
  3. **Mono:** Rock-solid mono (corr 0.98, -0.04 dB overall, -0.03 dB attack).
- **ID Pick (`wep_layer_body_heavy`):** Keep `wep_layer_body_heavy_t1.mp3` (`t2` is a great tighter 57 Hz option for medium guns).

### 32. `imp_glass_armor` (vs `today0` hitGlass)

- **`imp_glass_armor_t1.mp3` -> KEEP (dark-leaning; lift gain ~10 dB + +4 dB high-mid lift).**
  1. **Verdict:** Keep `imp_glass_armor_t1.mp3`: sounds like a heavy shell slamming into ten-meter glacier-scale crystal armor with racing slab fractures and zero kitchen wine-glass tinkle, far bigger than today's short `hitGlass` (`today0`, 0.24 s).
  2. **Bass (<500 Hz):** Borderline yes on raw numbers, with real midrange fracture detail to lift. Measured 86.7% below 500 Hz, 11.6% in 500 Hz to 2 kHz, 1.6% above 2 kHz (centroid 276 Hz, quiet -29.5 dB raw RMS, 0.5% below 20 Hz).
  3. **Mono:** Pure dual-mono (corr 1.00, -0.01 dB overall, -0.01 dB mid, -0.04 dB above 2 kHz, 0.00 dB attack); zero mono loss.
- **`imp_glass_armor_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject `imp_glass_armor_t2.mp3`: louder than `t1`, but loses half its midrange crystal-fracture texture and reads more like a blunt rock impact, losing its Glasswright identity beside `t1` and today's `hitGlass` (`today0`, 23% mid).
  2. **Bass (<500 Hz):** Yes, bass trap. Measured 93.0% below 500 Hz, only 5.9% in 500 Hz to 2 kHz, 1.1% above 2 kHz (centroid 244 Hz, 2.3% below 20 Hz).
  3. **Mono:** Rock-solid mono (corr 0.99, -0.03 dB overall), just too dark and rock-like.
- **ID Pick (`imp_glass_armor`):** Keep `imp_glass_armor_t1.mp3` (boost gain and upper mids in mastering).

### 33. `imp_obsidian_eclipse` (vs `today0` hullHitBig, `today1` railHit)

- **`imp_obsidian_eclipse_t1.mp3` -> REJECT (bass trap + mid/high mono collapse).**
  1. **Verdict:** Reject `imp_obsidian_eclipse_t1.mp3`: brittle basalt crack and faint electrostatic edge read nicely in stereo, but both drop out in mono leaving a generic heavy boom indistinguishable from today's `hullHitBig` (`today0`).
  2. **Bass (<500 Hz):** Yes, bass trap. Measured 95.0% below 500 Hz, 2.6% in 500 Hz to 2 kHz, 2.4% above 2 kHz (centroid 221 Hz, 1.4% below 20 Hz).
  3. **Mono:** Fails mono on substance detail. Moderate overall correlation (corr 0.63, -0.90 dB overall), but drops -3.13 dB in 500 Hz to 2 kHz and -3.20 dB above 2 kHz (-1.42 dB attack), erasing the obsidian crack by ear.
- **`imp_obsidian_eclipse_t2.mp3` -> REJECT (extreme bass trap).**
  1. **Verdict:** Reject `imp_obsidian_eclipse_t2.mp3`: pure low stone-boom mud with zero brittle obsidian fracture or cold electrostatic edge, no clearer than today's dull `hullHitBig` (`today0`, 100% below 500 Hz).
  2. **Bass (<500 Hz):** Yes, extreme bass trap. Measured 99.4% below 500 Hz (99.3% above 30 Hz), 0.4% mid, 0.2% above 2 kHz (centroid 73 Hz, 4.8% below 20 Hz).
  3. **Mono:** Passes mono (corr 0.79, -0.50 dB overall), because there are almost no highs left to cancel.
- **ID Pick (`imp_obsidian_eclipse`):** Neither, re-roll. Drop `"sub-bass"` and `"monolithic"` (still in the prompt); lead with `"hard cold brittle obsidian slab crack and sharp dark stone splintering with a brief crisp electrostatic snap over a tight mid-low knock"`.

### 34. `imp_metal_light` (vs `today0` hullHit, `today1` hullTick)

- **`imp_metal_light_t1.mp3` -> KEEP (trim 4 ms dead head).**
  1. **Verdict:** Keep `imp_metal_light_t1.mp3`: solid, contained dense cannon-shell thud on armored steel plating with a short dull plate ring, a huge realism upgrade over today's shrill `hullHit` (`today0`, 94% above 2 kHz) and tiny `hullTick` (`today1`).
  2. **Bass (<500 Hz):** No. Balanced metal hit: 65.0% below 500 Hz, 24.5% in 500 Hz to 2 kHz, 10.5% above 2 kHz (centroid 791 Hz, -20.2 dB RMS, 2.2% below 20 Hz).
  3. **Mono:** Moderate stereo (corr 0.52, -1.22 dB overall, -1.48 dB mid, -2.32 dB above 2 kHz, -1.18 dB attack); fragment sparkle softens slightly in mono, but by ear the solid metallic plate hit survives cleanly.
- **`imp_metal_light_t2.mp3` -> REJECT (mono fail).**
  1. **Verdict:** Reject `imp_metal_light_t2.mp3`: slower peaking (108 ms vs 58 ms on `t1`) and hollows out its metallic plate midrange badly in mono, losing clearly to `t1`.
  2. **Bass (<500 Hz):** No. Measured 66.0% below 500 Hz, 21.1% mid, 12.9% above 2 kHz (centroid 836 Hz).
  3. **Mono:** Fails mono. Wide stereo (corr 0.32) drops -1.81 dB overall, -3.14 dB in 500 Hz to 2 kHz, and -2.39 dB above 2 kHz; audibly hollow on one speaker.
- **ID Pick (`imp_metal_light`):** Keep `imp_metal_light_t1.mp3`.

### 35. `imp_energy_sear` (vs `today0` hullHitBig, `today1` plasmaHit)

- **`imp_energy_sear_t1.mp3` -> REJECT (extreme bass trap).**
  1. **Verdict:** Reject `imp_energy_sear_t1.mp3`: reads as a quiet, muffled low bass thud (`-25.6 dB` RMS) with almost none of the hot thermal-arc flash or weld-arc crackle needed for a plasma bolt hitting steel, far duller than today's `plasmaHit` (`today1`, 38% mid, 48% high).
  2. **Bass (<500 Hz):** Yes, extreme bass trap. Measured 98.8% below 500 Hz (98.5% above 30 Hz), 0.7% in 500 Hz to 2 kHz, 0.5% above 2 kHz (centroid 118 Hz, 9.9% below 20 Hz).
  3. **Mono:** Passes overall (corr 0.92, -0.17 dB), but drops -2.33 dB above 2 kHz, wiping out the tiny bit of sear crackle.
- **`imp_energy_sear_t2.mp3` -> REJECT (extreme bass trap + high cancellation).**
  1. **Verdict:** Reject `imp_energy_sear_t2.mp3`: another muffled sub-bass bump whose faint high-frequency crackle cancels out in mono, missing plasma-sear identity completely compared with today's `plasmaHit` (`today1`).
  2. **Bass (<500 Hz):** Yes, extreme bass trap. Measured 99.0% below 500 Hz, 0.6% mid, 0.5% above 2 kHz (centroid 110 Hz, -26.6 dB RMS).
  3. **Mono:** Passes low body (corr 0.95, -0.11 dB overall), but drops -4.52 dB above 2 kHz, killing the top sear completely.
- **ID Pick (`imp_energy_sear`):** Neither, re-roll. Drop `"forceful pressurized heat-impact punch"` and prompt `"bright fierce electric weld-arc flash and hot scorching metallic crackle on armor steel over a tight mid-weight impact"` (combining `imp_las_t1`'s crisp sear with metal weight).

### 36. `imp_las` (vs `today0` hullHit, `today1` lasSear)

- **`imp_las_t1.mp3` -> KEEP (lift gain ~8 dB).**
  1. **Verdict:** Keep `imp_las_t1.mp3`: crisp, hot, focused weld-arc flash and compact scorching steel contact, a clean physical replacement for today's arcade `lasSear` zap and shrill `hullHit` (`today0`, `today1`).
  2. **Bass (<500 Hz):** No, bright and hot. Measured 9.1% below 500 Hz, 4.4% in 500 Hz to 2 kHz, 86.6% above 2 kHz (centroid 7860 Hz, -27.8 dB raw RMS, 0.0% below 20 Hz); optionally tame a touch above 8 kHz if bright in rapid fire.
  3. **Mono:** Passes mono cleanly (corr 0.84, -0.35 dB overall, -0.24 dB mid, -0.38 dB above 2 kHz, -0.27 dB attack).
- **`imp_las_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject `imp_las_t2.mp3`: peaks way too late for a beam contact cue (`255 ms` on a `520 ms` clip) and loses more in mono than `t1`.
  2. **Bass (<500 Hz):** No. Measured 11.0% below 500 Hz, 4.9% mid, 84.1% above 2 kHz (centroid 7413 Hz).
  3. **Mono:** Passes mono (corr 0.63, -0.89 dB overall, -0.94 dB high), but late onset makes `t1` the clear winner.
- **ID Pick (`imp_las`):** Keep `imp_las_t1.mp3`.

### 37. `imp_acid_on_metal` (vs `today0` hitWet)

- **`imp_acid_on_metal_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject `imp_acid_on_metal_t1.mp3`: strong chemical-foundry roar in stereo that beats today's tiny `hitWet` (`today0`), but loses crisp dissolution fizz in mono compared with `t2`.
  2. **Bass (<500 Hz):** No. Measured 33.5% below 500 Hz, 51.6% in 500 Hz to 2 kHz, 14.9% above 2 kHz (centroid 1111 Hz).
  3. **Mono:** Softens top end (corr 0.46, -1.37 dB overall, -1.54 dB mid, -2.67 dB above 2 kHz, -1.58 dB attack); clearly outclassed by `t2`'s mono stability.
- **`imp_acid_on_metal_t2.mp3` -> KEEP (trim 5 ms dead head).**
  1. **Verdict:** Keep `imp_acid_on_metal_t2.mp3`: blunt payload thud straight into a heavy, bubbling industrial chemical-etching roar dissolving steel without ever sounding like frying bacon, a huge upgrade over today's tiny `hitWet` (`today0`, `-29.0 dB`).
  2. **Bass (<500 Hz):** No. Textbook three-band balance: 32.3% below 500 Hz, 35.2% in 500 Hz to 2 kHz, 32.6% above 2 kHz (centroid 1711 Hz, -21.7 dB RMS, 0.4% below 20 Hz).
  3. **Mono:** Rock-solid mono (corr 0.93, -0.17 dB overall, -0.14 dB mid, -0.27 dB above 2 kHz, -0.19 dB attack); keeps full corrosive weight on one speaker.
- **ID Pick (`imp_acid_on_metal`):** Keep `imp_acid_on_metal_t2.mp3`.

### 38. `shd_break_prismatic` (vs `today0` shieldBig, `today1` shieldHit, `today2` shieldShatter, `today3` shieldShimmer)

- **`shd_break_prismatic_t1.mp3` -> REJECT (mono fail).**
  1. **Verdict:** Reject `shd_break_prismatic_t1.mp3`: sounds stunning in stereo (massive ice-sheet crack cascading into ringing crystal slabs and a descending glass harmonic, far better than today's synthy `shieldBig` to `shieldShimmer`), but fails mono fold-down and thins into a brittle narrow splash.
  2. **Bass (<500 Hz):** No. Measured 21.7% below 500 Hz, 16.3% in 500 Hz to 2 kHz, 62.0% above 2 kHz (centroid 3073 Hz, 0.0% below 20 Hz).
  3. **Mono:** Fails mono. Very wide stereo (corr 0.15) drops -2.40 dB overall, -2.12 dB mid, -2.71 dB above 2 kHz, and -1.72 dB attack; audibly loses its lush crystal shimmer and body on one speaker.
- **`shd_break_prismatic_t2.mp3` -> REJECT (mono fail).**
  1. **Verdict:** Reject `shd_break_prismatic_t2.mp3`: slower, noisier glass crash (`peak 169 ms`) with weaker descending harmonic than `t1`, and collapses even harder in mono.
  2. **Bass (<500 Hz):** No. Measured 58.5% below 500 Hz, 25.5% mid, 16.0% above 2 kHz (centroid 1185 Hz).
  3. **Mono:** Fails mono. Near-zero correlation (corr 0.08) drops -2.69 dB overall, -2.64 dB mid, -3.12 dB above 2 kHz, and -3.31 dB on the attack.
- **ID Pick (`shd_break_prismatic`):** Neither, re-roll. Keep the winning crystal-slab and glass-harmonic imagery, but remove `"racing outward"` and `"scatter"` (which triggered wide stereo panning) and ask for a centered close-mic crystal-barrier fracture into a clear descending glass-harmonic tone.

### 39. `shd_hit_absorb` (vs `today0` shieldHit, `today1` shieldShimmer)

- **`shd_hit_absorb_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject `shd_hit_absorb_t1.mp3`: softer than today's harsh synth `shieldHit` (`today0`), but trapped below 500 Hz so it reads as a dull low bass thump rather than a clean tonal energy deflection.
  2. **Bass (<500 Hz):** Yes, bass trap. Measured 94.2% below 500 Hz (93.1% above 30 Hz), 5.7% in 500 Hz to 2 kHz, 0.1% above 2 kHz (centroid 97 Hz, 9.0% below 20 Hz).
  3. **Mono:** Rock-solid mono (corr 0.96, -0.31 dB overall), just too dark.
- **`shd_hit_absorb_t2.mp3` -> KEEP (borderline mono; verify in mono battle mix).**
  1. **Verdict:** Keep `shd_hit_absorb_t2.mp3`: clean, quiet, controlled rounded energy deflection with a gentle resonant harmonic ripple, far more refined and less annoying than today's buzzing synth `shieldHit` and `shieldShimmer` (`today0`, `today1`).
  2. **Bass (<500 Hz):** No. Well-balanced deflection tone: 50.0% below 500 Hz, 44.5% in 500 Hz to 2 kHz, 5.5% above 2 kHz (centroid 614 Hz, -22.2 dB RMS, 0.0% below 20 Hz).
  3. **Mono:** Borderline pass. Moderate stereo (corr 0.49, -1.29 dB overall, -2.14 dB mid, -3.18 dB above 2 kHz, -0.72 dB attack) softens its upper sparkle in mono, yet by ear the soft thud and clean 44.5% midrange deflection pulse still read cleanly for a quiet block cue (R412 rule 4).
- **ID Pick (`shd_hit_absorb`):** Keep `shd_hit_absorb_t2.mp3` (if Ryan wants brighter deflection sparkle in mono, re-roll dropping `"rippling outward"`).

### 40. `dmg_turret_knockout` (no clip today)

- **`dmg_turret_knockout_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject `dmg_turret_knockout_t1.mp3`: believable heavy gear jam with arc snaps in stereo, but loses top-end electrical bite in mono compared with `t2` (no baseline clip today).
  2. **Bass (<500 Hz):** Yes, bass-leaning. Measured 89.5% below 500 Hz, 5.2% mid, 5.3% above 2 kHz (centroid 448 Hz).
  3. **Mono:** Softens arcs (corr 0.79, -0.48 dB overall, -1.71 dB mid, -2.24 dB above 2 kHz); beaten cleanly by `t2`.
- **`dmg_turret_knockout_t2.mp3` -> KEEP (dark-leaning; add +3 dB presence lift in mastering).**
  1. **Verdict:** Keep `dmg_turret_knockout_t2.mp3`: authoritative heavy industrial turret drive-gear grind locking into a solid mechanical jam with crisp high-voltage arc snaps, reading unmistakably as a knocked-out weapon mount (no baseline clip today).
  2. **Bass (<500 Hz):** Borderline yes on raw ratio, with audible mechanical crunch and snaps. Measured 89.7% below 500 Hz, 5.7% in 500 Hz to 2 kHz, 4.6% above 2 kHz (centroid 438 Hz, strong -15.8 dB RMS, 0.1% below 20 Hz); a light +3 dB high-mid lift makes the jam and arcs pop cleanly.
  3. **Mono:** Passes mono cleanly (corr 0.92, -0.18 dB overall, -0.83 dB mid, -1.40 dB above 2 kHz, -0.18 dB attack).
- **ID Pick (`dmg_turret_knockout`):** Keep `dmg_turret_knockout_t2.mp3`.

### 41. `dmg_shield_burnout` (no clip today)

- **`dmg_shield_burnout_t1.mp3` -> REJECT (mono fail + thin fizz).**
  1. **Verdict:** Reject `dmg_shield_burnout_t1.mp3`: sounds like a crisp stray electrical spark in stereo, but has almost no low-mid transformer hum and collapses into thin, hollow static hiss in mono (no baseline clip today).
  2. **Bass (<500 Hz):** No (opposite problem: thin high-frequency fizz). Measured 1.1% below 500 Hz, 3.9% in 500 Hz to 2 kHz, 95.1% above 2 kHz (centroid 9921 Hz).
  3. **Mono:** Fails mono. Very wide stereo (corr 0.07) drops -2.74 dB overall, -3.41 dB mid, -2.70 dB above 2 kHz, and -3.18 dB attack.
- **`dmg_shield_burnout_t2.mp3` -> REJECT (hard mono fail).**
  1. **Verdict:** Reject `dmg_shield_burnout_t2.mp3`: late-peaking (479 ms), out-of-phase spark hiss that cancels itself out in mono (no baseline clip today).
  2. **Bass (<500 Hz):** No (high fizz). Measured 4.6% below 500 Hz, 5.6% mid, 89.8% above 2 kHz (centroid 9224 Hz).
  3. **Mono:** Hard fail. Negative correlation (corr -0.23) drops -4.13 dB overall, -4.98 dB mid, -4.14 dB high, and -4.27 dB attack.
- **ID Pick (`dmg_shield_burnout`):** Neither, re-roll. Prompt `"one close centered dry high-voltage electrical arc snap across steel plating with a short audible midrange transformer buzz beneath"` (no wide spark spray) so it survives mono with real body.

### 42. `dmg_breach_shear_metal` (no clip today)

- **`dmg_breach_shear_metal_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject `dmg_breach_shear_metal_t1.mp3`: heavy structural steel buckling in stereo, but loses its sharp shearing metal edge in mono and is clearly outclassed by `t2` (no baseline clip today).
  2. **Bass (<500 Hz):** No. Measured 56.6% below 500 Hz, 26.7% mid, 16.7% above 2 kHz (centroid 1142 Hz).
  3. **Mono:** Loses top bite (corr 0.66, -0.81 dB overall, -0.54 dB mid, -2.79 dB above 2 kHz).
- **`dmg_breach_shear_metal_t2.mp3` -> KEEP (standout R416 damage take).**
  1. **Verdict:** Keep `dmg_breach_shear_metal_t2.mp3`: visceral, massive steel-girder rupture and thick bolted armor plates buckling open with crisp tearing metal detail right at `t=0` (`peak 8 ms`), unmistakably a real hull breach (no baseline clip today).
  2. **Bass (<500 Hz):** No. Ideal three-band balance: 36.1% below 500 Hz, 28.2% in 500 Hz to 2 kHz, 35.7% above 2 kHz (centroid 2086 Hz, -19.9 dB RMS, 3.6% below 20 Hz).
  3. **Mono:** Rock-solid mono (corr 0.90, -0.22 dB overall, -0.08 dB mid, -0.17 dB above 2 kHz, -0.17 dB attack); zero loss on one speaker.
- **ID Pick (`dmg_breach_shear_metal`):** Keep `dmg_breach_shear_metal_t2.mp3`.

### 43. `dmg_breach_vent` (no clip today)

- **`dmg_breach_vent_t1.mp3` -> REJECT (hard mono fail).**
  1. **Verdict:** Reject `dmg_breach_vent_t1.mp3`: forceful escaping air jet in stereo, but late-peaking (727 ms) and out of phase between channels, collapsing into hollow, comb-filtered hiss in mono (no baseline clip today).
  2. **Bass (<500 Hz):** No. Measured 4.2% below 500 Hz, 41.7% mid, 54.1% above 2 kHz (centroid 2521 Hz).
  3. **Mono:** Hard fail. Negative correlation (corr -0.18) drops -3.90 dB overall, -3.96 dB mid and high, and -5.10 dB on the attack.
- **`dmg_breach_vent_t2.mp3` -> REJECT (hard mono fail).**
  1. **Verdict:** Reject `dmg_breach_vent_t2.mp3`: smooth roaring decompression blast in stereo, but completely uncorrelated across channels so mono fold-down turns it hollow and flat (no baseline clip today).
  2. **Bass (<500 Hz):** No. Measured 25.7% below 500 Hz, 67.0% mid, 7.3% above 2 kHz (centroid 944 Hz).
  3. **Mono:** Hard fail. Uncorrelated stereo (corr -0.01) drops -3.08 dB overall, -3.39 dB mid, -3.21 dB high, and -3.29 dB attack.
- **ID Pick (`dmg_breach_vent`):** Neither, re-roll. Remove `"Wide"` and `"rushing outward"` (which forced uncorrelated stereo air noise) and prompt `"a tight centered close-mic high-pressure air relief valve blast starting immediately and thinning fast to silence"`.

### 44. `dmg_engine_fail` (vs `today0` cough)

- **`dmg_engine_fail_t1.mp3` -> KEEP (standout R416 take; trim 5 ms dead head).**
  1. **Verdict:** Keep `dmg_engine_fail_t1.mp3`: heavy metallic fusion-turbine misfire with two distinct sputtering power surges and a clear winding-down turbine whine, zero human cough, and a night-and-day upgrade over today's strange screechy `cough` (`today0`).
  2. **Bass (<500 Hz):** No. Crisp mechanical midrange: 23.4% below 500 Hz, 54.9% in 500 Hz to 2 kHz, 21.7% above 2 kHz (centroid 1470 Hz, -16.1 dB RMS, 0.0% below 20 Hz).
  3. **Mono:** Passes mono cleanly (corr 0.68, -0.77 dB overall, -0.67 dB mid, -1.45 dB above 2 kHz, -0.90 dB attack); keeps its sputtering turbine character intact on one speaker.
- **`dmg_engine_fail_t2.mp3` -> REJECT (mono fail).**
  1. **Verdict:** Reject `dmg_engine_fail_t2.mp3`: smoother, less distinctive turbine stall in stereo that loses its midrange whine and top grit badly when folded to mono, losing clearly to `t1`.
  2. **Bass (<500 Hz):** No. Measured 60.1% below 500 Hz, 29.0% mid, 10.9% above 2 kHz (centroid 822 Hz).
  3. **Mono:** Fails mono. Very wide stereo (corr 0.13) drops -2.48 dB overall, -3.61 dB mid, -3.92 dB above 2 kHz, and -2.51 dB attack.
- **ID Pick (`dmg_engine_fail`):** Keep `dmg_engine_fail_t1.mp3`.

### 45. `death_directorate_blackout` (vs `today0` ionCharge, `today1` whoosh)

- **`death_directorate_blackout_t1.mp3` -> KEEP (lead pick).**
  1. **Verdict:** Keep `death_directorate_blackout_t1.mp3`: authoritative massive substation main power-breaker slam straight into a clean, cold descending power-grid shutdown, unmistakably Directorate and miles beyond today's synthy `ionCharge` and `whoosh` (`today0`, `today1`).
  2. **Bass (<500 Hz):** No. Measured 74.4% below 500 Hz, 15.3% in 500 Hz to 2 kHz, 10.4% above 2 kHz (centroid 703 Hz, -21.2 dB RMS, 0.3% below 20 Hz); crisp slam and clear winding-down hum.
  3. **Mono:** Pure dual-mono (corr 1.00, -0.01 dB overall, -0.01 dB mid, -0.03 dB above 2 kHz, -0.01 dB attack).
- **`death_directorate_blackout_t2.mp3` -> KEEP (alternate for longer 1.1 s wind-down).**
  1. **Verdict:** Keep `death_directorate_blackout_t2.mp3` as an alternate: brighter, louder (`-15.7 dB`), and longer-winding turbine blackout (`T95 = 1028 ms` vs `482 ms` on `t1`), softer initial breaker slam than `t1`, still crushing today's `ionCharge` (`today0`).
  2. **Bass (<500 Hz):** No. Full-band: 50.7% below 500 Hz (43.8% above 30 Hz), 26.0% mid, 23.3% above 2 kHz (centroid 1334 Hz, 4.0% below 20 Hz).
  3. **Mono:** Passes mono cleanly (corr 0.81, -0.44 dB overall, -0.40 dB mid, -1.00 dB above 2 kHz, -0.90 dB attack).
- **ID Pick (`death_directorate_blackout`):** Keep `death_directorate_blackout_t1.mp3` (crisp `t=0` breaker slam; `t2` is a great alternate if a longer wind-down fits the death timing better).

### 46. `death_hullbreaker_snap` (vs `today0` scrape, `today1` hullHitBig, `today2` crackSettle)

- **`death_hullbreaker_snap_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject `death_hullbreaker_snap_t1.mp3`: very quiet (`-31.4 dB` RMS) and bass-heavy with a softer cable snap than `t2`, lacking the sharp welded-seam parting bite needed to upgrade today's `scrape` and `crackSettle` (`today0`, `today2`).
  2. **Bass (<500 Hz):** Yes, bass trap. Measured 90.5% below 500 Hz, 5.8% mid, 3.7% above 2 kHz (centroid 384 Hz).
  3. **Mono:** Dual-mono (corr 1.00, -0.01 dB overall), but clearly weaker and duller than `t2`.
- **`death_hullbreaker_snap_t2.mp3` -> KEEP (dark-leaning; lift gain ~10 dB).**
  1. **Verdict:** Keep `death_hullbreaker_snap_t2.mp3`: brief steel-girder stress breaking into a sharp metallic suspension-cable snap and deep iron shudder, genuinely reading like a welded scrap ship snapping its spine and beating today's dull `scrape` and `hullHitBig` (`today0`, `today1`).
  2. **Bass (<500 Hz):** Borderline yes on raw share, with clear upper metal twang. Measured 84.2% below 500 Hz, 6.9% in 500 Hz to 2 kHz, 8.9% above 2 kHz (centroid 567 Hz, quiet -28.5 dB raw RMS, 0.2% below 20 Hz).
  3. **Mono:** Passes mono cleanly (corr 0.75, -0.57 dB overall, -0.10 dB mid, -0.22 dB above 2 kHz, -0.50 dB attack); keeps its parting-cable snap intact.
- **ID Pick (`death_hullbreaker_snap`):** Keep `death_hullbreaker_snap_t2.mp3` (lift gain in mastering).

### 47. `death_ithar_shatter` (vs `today0` crackGlass, `today1` hitGlass, `today2` choirBell)

- **`death_ithar_shatter_t1.mp3` -> REJECT (extreme bass trap + mono fail).**
  1. **Verdict:** Reject `death_ithar_shatter_t1.mp3`: massive glacier rumble in stereo, but almost all energy sits below 500 Hz and its sparse midrange crystal cracks collapse in mono, sounding like a dull rock collapse instead of a Glasswright crystal hull shattering (unlike today's bright `crackGlass`, `today0`, even though today's is too small).
  2. **Bass (<500 Hz):** Yes, extreme bass trap. Measured 98.2% below 500 Hz (97.9% above 30 Hz), 1.7% in 500 Hz to 2 kHz, 0.1% above 2 kHz (centroid 120 Hz, 9.7% below 20 Hz).
  3. **Mono:** Fails mono. Wide stereo (corr 0.27) drops -1.99 dB overall, -2.55 dB mid, and -2.28 dB attack, leaving only muffled sub-rumble.
- **`death_ithar_shatter_t2.mp3` -> REJECT (extreme bass trap + high collapse).**
  1. **Verdict:** Reject `death_ithar_shatter_t2.mp3`: even darker sub-boom whose trailing crystal cascade drops nearly 4 dB in mono, losing all crystalline identity.
  2. **Bass (<500 Hz):** Yes, extreme bass trap. Measured 99.4% below 500 Hz, 0.6% mid, 0.0% above 2 kHz (centroid 91 Hz).
  3. **Mono:** Fails on crystal highs (corr 0.57, -1.08 dB overall, -2.30 dB mid, -3.80 dB above 2 kHz).
- **ID Pick (`death_ithar_shatter`):** Neither, re-roll. Drop `"deep resonant glacier fracture boom"`, `"Colossal"`, and `"dark resonant silence"`; prompt `"a centered close-mic collapse of thick crystalline armor slabs cracking and ringing apart in bright cascading glass-slab fractures over a firm mid-low structural break"`.

### 48. `death_eclipse_shear` (vs `today0` scrape, `today1` hullHitBig, `today2` crackSettle)

- **`death_eclipse_shear_t1.mp3` -> REJECT (100% bass trap).**
  1. **Verdict:** Reject `death_eclipse_shear_t1.mp3`: loud 57 Hz sub-bass boom (`-9.2 dB` RMS) with literally zero midrange basalt grinding or electrostatic static, no better than today's dull `hullHitBig` (`today1`) and invisible on small speakers.
  2. **Bass (<500 Hz):** Yes, total bass trap. Measured 100.0% below 500 Hz, 0.0% in 500 Hz to 2 kHz, 0.0% above 2 kHz (centroid 53 Hz, dominant 57.4 Hz).
  3. **Mono:** Passes mono (corr 0.84, -0.37 dB overall), because there is nothing above 500 Hz to cancel.
- **`death_eclipse_shear_t2.mp3` -> REJECT (100% bass trap).**
  1. **Verdict:** Reject `death_eclipse_shear_t2.mp3`: identical 100% sub-500 Hz rumble (`62 Hz` dominant) with zero audible stone shear or cold crackle, failing to distinguish Eclipse from a generic sub-boom.
  2. **Bass (<500 Hz):** Yes, total bass trap. Measured 100.0% below 500 Hz, 0.0% mid, 0.0% above 2 kHz (centroid 61 Hz).
  3. **Mono:** Passes mono (corr 0.83, -0.38 dB overall), but completely devoid of mids and highs.
- **ID Pick (`death_eclipse_shear`):** Neither, re-roll. Drop `"Colossal"`, `"deep sub-harmonic"`, and `"Monumental"`; lead with `"hard brittle basalt-stone slabs grinding and shearing apart with crisp dry rock-fracture grit and sharp cold electrostatic crackle over a dark hollow low knock"`.

### 49. `death_metal_break` (vs `today0` boomBig, `today1` debris)

- **`death_metal_break_t1.mp3` -> KEEP (lead pick; light +2 to 3 dB presence boost on metal cracks).**
  1. **Verdict:** Keep `death_metal_break_t1.mp3`: enormous capital-ship structural break with audible wrenching steel plating and tumbling metallic wreckage decaying into a long dark rumble, a massive clarity upgrade over today's muddy 4.3 s `boomBig` (`today0`, 99% below 500 Hz) and `debris` (`today1`, 98% below 500 Hz).
  2. **Bass (<500 Hz):** Borderline yes on raw ratio, appropriate for a flagship death base with real midrange steel detail. Measured 84.7% below 500 Hz, 11.6% in 500 Hz to 2 kHz, 3.7% above 2 kHz (centroid 357 Hz, -17.6 dB RMS, 1.3% below 20 Hz).
  3. **Mono:** Passes mono (corr 0.65, -0.84 dB overall, -1.50 dB mid, -2.02 dB above 2 kHz, -1.39 dB attack); minor softening on the highest debris edge, while the huge break and wrenching steel cracks hold up cleanly by ear.
- **`death_metal_break_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject `death_metal_break_t2.mp3`: slower peaking (290 ms vs 98 ms on `t1`), darker, and loses slightly more midrange steel detail in mono, cleanly beaten by `t1`.
  2. **Bass (<500 Hz):** Yes. Measured 88.0% below 500 Hz, 7.8% mid, 4.2% above 2 kHz (centroid 304 Hz).
  3. **Mono:** Softens mids/highs (corr 0.58, -1.01 dB overall, -2.12 dB mid, -2.05 dB high, -1.80 dB attack).
- **ID Pick (`death_metal_break`):** Keep `death_metal_break_t1.mp3`.

### 50. `death_sunward_magazine` (vs `today0` boomSmall, `today1` boomLow, `today2` debris)

- **`death_sunward_magazine_t1.mp3` -> REJECT (extreme bass trap).**
  1. **Verdict:** Reject `death_sunward_magazine_t1.mp3`: loud (`-10.5 dB` RMS), late-peaking (208 ms) muffled sub-bass boom that will blur right into `death_metal_break` instead of reading as distinct steel-framed magazine flashes, duller than today's `boomSmall` (`today0`, 8% mid, 9% high).
  2. **Bass (<500 Hz):** Yes, extreme bass trap. Measured 98.0% below 500 Hz, 1.7% mid, 0.3% above 2 kHz (centroid 126 Hz, 2.5% below 20 Hz).
  3. **Mono:** Dual-mono (corr 1.00, -0.01 dB overall), but far too muffled to layer over a ship breakup.
- **`death_sunward_magazine_t2.mp3` -> REJECT (extreme bass trap).**
  1. **Verdict:** Reject `death_sunward_magazine_t2.mp3`: much tighter instant onset (`peak 6 ms`) than `t1`, but still 97.4% below 500 Hz so individual magazine detonations will get buried under `death_metal_break` compared with today's punchier `boomSmall` (`today0`).
  2. **Bass (<500 Hz):** Yes, extreme bass trap. Measured 97.4% below 500 Hz, 2.3% mid, 0.3% above 2 kHz (centroid 165 Hz).
  3. **Mono:** Dual-mono (corr 1.00, 0.00 dB loss), just too muffled.
- **ID Pick (`death_sunward_magazine`):** Neither, re-roll. Drop `"muffled"`, `"deep heavy"`, and `"massive low end"`; prompt `"one sharp tight internal ammunition detonation bursting inside armored steel plating with a crisp metallic hull-plate crack and brief hot blast"` so each flash punches cleanly over `death_metal_break`.

### 51. `ui_boss_arrival` (vs `today0` impactChord)

- **`ui_boss_arrival_t1.mp3` -> KEEP (unpositioned UI sting; pitch +2 semitones C2 to D2, add light 300 to 1200 Hz brass lift).**
  1. **Verdict:** Keep `ui_boss_arrival_t1.mp3`: grave, menacing real acoustic orchestral bass drum strike with dark low brass and double basses, completely replacing today's thin electronic `impactChord` (`today0`).
  2. **Bass (<500 Hz):** Yes, very dark (98.6% below 500 Hz, 1.3% mid, 0.0% high, centroid 94 Hz, dominant 65.5 Hz = C2); intentional orchestral sub-dread, though it needs a gentle upper-bass/low-mid brass lift for laptop speakers and a +200 cent pitch shift to hit D2 (73.4 Hz) matching the D-minor score.
  3. **Mono:** Passes mono cleanly (corr 0.63, -0.89 dB overall, -0.98 dB mid, -0.32 dB high, -0.24 dB attack); note also that as an unpositioned UI sting it may ship stereo per Ryan's ruling.
- **`ui_boss_arrival_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject `ui_boss_arrival_t2.mp3`: even darker (`58.6 Hz` = A#1), shorter body (`T95 = 239 ms` vs `406 ms` on `t1`), less low-brass sustain, and drops high overtones in mono.
  2. **Bass (<500 Hz):** Yes. Measured 99.0% below 500 Hz, 1.0% mid, 0.0% high (centroid 82 Hz).
  3. **Mono:** Passes low drum (corr 0.84, -0.35 dB overall), but drops -2.88 dB above 2 kHz; clearly weaker than `t1`.
- **ID Pick (`ui_boss_arrival`):** Keep `ui_boss_arrival_t1.mp3` (trim 7 ms dead head, pitch +2 semitones to D2, and check brass harmonics on laptop speakers).

### 52. `evt_fleet_warp_in` (vs `today0` whoosh, `today1` boomLow)

- **`evt_fleet_warp_in_t1.mp3` -> REJECT (extreme bass trap + late head).**
  1. **Verdict:** Reject `evt_fleet_warp_in_t1.mp3`: starts 69.3 ms late and is pure sub-bass rumble with almost no audible arrival snap, losing presence on normal speakers compared with today's `whoosh` (`today0`).
  2. **Bass (<500 Hz):** Yes, extreme bass trap. Measured 99.9% below 500 Hz, 0.1% mid, 0.0% high (centroid 72 Hz, dominant 55.5 Hz).
  3. **Mono:** Drops midrange snap (corr 0.69, -0.72 dB overall, -2.44 dB mid, -2.29 dB high), erasing what little onset edge existed.
- **`evt_fleet_warp_in_t2.mp3` -> REJECT (mono fail).**
  1. **Verdict:** Reject `evt_fleet_warp_in_t2.mp3`: much better inward pressure snap in stereo, but collapses in mono and drops to `-26.7 dB` RMS, losing its authoritative reinforcement weight.
  2. **Bass (<500 Hz):** Yes, bass-leaning (87.5% below 500 Hz, 4.2% mid, 8.3% above 2 kHz, centroid 374 Hz).
  3. **Mono:** Fails mono. Near-zero correlation (corr 0.04) drops -2.84 dB overall (-1.14 dB attack); noticeably loses its arrival boom on one speaker.
- **ID Pick (`evt_fleet_warp_in`):** Neither, re-roll. Drop `"monumental deep sub-bass"` and `"low heavy"`; prompt `"a crisp centered inward gravitational pressure snap immediately cracking into a punchy mid-low spatial displacement boom and brief resonant thruster settle"`.

### 53. `ui_confirm_latch` (vs `today0` uiConfirm)

- **`ui_confirm_latch_t1.mp3` -> KEEP (lead pick; trim 29 ms dead head + lift gain ~8 dB).**
  1. **Verdict:** Keep `ui_confirm_latch_t1.mp3`: crisp, weighty real-world two-stage machined control lever seating firmly into place, completely acoustic hardware that obliterates today's electronic video-game `uiConfirm` beep (`today0`).
  2. **Bass (<500 Hz):** No. Clean tactile mechanical detail: 1.5% below 500 Hz, 12.0% in 500 Hz to 2 kHz, 86.5% above 2 kHz (centroid 3696 Hz, -30.1 dB raw RMS, 0.0% below 20 Hz).
  3. **Mono:** Rock-solid mono (corr 0.96, -0.10 dB overall, -0.10 dB mid, -0.10 dB above 2 kHz, -0.47 dB attack).
- **`ui_confirm_latch_t2.mp3` -> KEEP (alternate; trim 44 ms dead head + lift gain ~6 dB).**
  1. **Verdict:** Keep `ui_confirm_latch_t2.mp3` as an alternate: slightly heavier, chunkier mechanical lever clunk, equally physical and miles ahead of today's electronic `uiConfirm` (`today0`).
  2. **Bass (<500 Hz):** No. Measured 3.3% below 500 Hz, 13.7% mid, 83.0% above 2 kHz (centroid 3837 Hz, -28.1 dB raw RMS).
  3. **Mono:** Rock-solid mono (corr 0.91, -0.19 dB overall, -0.21 dB mid, -0.18 dB above 2 kHz, -0.17 dB attack).
- **ID Pick (`ui_confirm_latch`):** Keep `ui_confirm_latch_t1.mp3` (`t2` works as an alternate).

### 54. `ui_turn_start` (vs `today0` yourTurn)

- **`ui_turn_start_t1.mp3` -> KEEP (alternate; lift gain ~9 dB, check D-tuning).**
  1. **Verdict:** Keep `ui_turn_start_t1.mp3` as an alternate: calm, solemn struck acoustic bronze plate bloom, replacing today's retro synthy `yourTurn` game chime (`today0`) with real dignified hardware, just 3 dB quieter than `t2`.
  2. **Bass (<500 Hz):** Yes (pure low-fundamental acoustic bronze tone at 185 Hz = F#3, not sub-bass mud). Measured 99.8% below 500 Hz, 0.1% mid, 0.0% high (centroid 189 Hz, -31.2 dB raw RMS, 0.0% below 20 Hz); reads cleanly on laptops around 185 Hz, though very mellow.
  3. **Mono:** Pure dual-mono (corr 1.00, -0.01 dB overall, -0.01 dB attack).
- **`ui_turn_start_t2.mp3` -> KEEP (lead pick; lift gain ~7 dB, optional pitch-shift F#3 to D3).**
  1. **Verdict:** Keep `ui_turn_start_t2.mp3`: warmer, fuller, 3 dB louder acoustic struck bronze plate bloom with a gentle natural fade, calm and dignified against today's electronic `yourTurn` chime (`today0`).
  2. **Bass (<500 Hz):** Yes (pure 183 Hz F#3 bronze plate fundamental, zero sub-20 Hz mud). Measured 100.0% below 500 Hz, 0.0% mid, 0.0% high (centroid 180 Hz, -28.4 dB raw RMS); pitch-shifting -4 semitones to D3 (146.8 Hz) or checking against the D-minor score is easy in mastering.
  3. **Mono:** Pure dual-mono (corr 1.00, 0.00 dB loss across overall and attack).
- **ID Pick (`ui_turn_start`):** Keep `ui_turn_start_t2.mp3` (if Ryan wants brighter shimmering bronze overtones above 500 Hz, re-roll adding `"gentle warm midrange bronze overtones, pitch D"`).

### 55. `amb_bridge_bed` (20 s loop, no clip today)

- **`amb_bridge_bed_t1.mp3` -> REJECT (vocal leak + 17 dB level spike).**
  1. **Verdict:** Reject `amb_bridge_bed_t1.mp3`: opens and ends as a calm quiet reactor hum (`-43` to `-45 dB`), but between seconds 7 and 11 a muffled human radio voice speaks (`"...three one..."`), spiking RMS by +15 dB to `-28.1 dB` and jumping 300 Hz to 3 kHz energy from ~16% to 63.4%, which ruins any 20 s loop (no baseline clip today).
  2. **Bass (<500 Hz):** No, overall 74.6% below 500 Hz, 25.3% in 500 Hz to 2 kHz (mostly from the leaked speech), 0.1% above 2 kHz (centroid 305 Hz, 1.3% below 20 Hz).
  3. **Mono:** Wide stereo (corr 0.32, -1.81 dB overall, -1.18 dB mid, -1.43 dB high, -3.84 dB first-100ms); ambience may ship stereo as an unpositioned bed, but the leaked voice and 17.0 dB loudness spread make this take unusable.
- **ID Pick (`amb_bridge_bed`):** Neither, re-roll. Drop `"no vocals"` (pink-elephant vocal trigger) and `"command bridge"` (radio-chatter trigger); prompt `"Empty uncrewed mechanical engine-room tone: a steady low reactor hum, faint smooth air duct flow, and soft constant electrical transformer drone, completely flat unchanging volume from start to finish"` with `loop: true` and `prompt_influence: 0.50`.

---

## Quick Pick Summary (All 55 IDs)

| # | Sound ID | Pick | Mastering / Handling Notes |
|---|---|---|---|
| 1 | `wep_sunward_hbattery_salvo` | `wep_sunward_hbattery_salvo_t1.mp3` | REFERENCE ONLY (not wired) |
| 2 | `wep_sunward_autocannon` | `wep_sunward_autocannon_t1.mp3` | Fold mono, high-pass 35 Hz |
| 3 | `wep_sunward_torp_launch` | `wep_sunward_torp_launch_t1.mp3` | Trim 9 ms, fold mono (`t2` alt) |
| 4 | `wep_sunward_turret` | **Re-roll** | Both bass-trapped; `t2` mono fail |
| 5 | `wep_sunward_hbattery` | **Re-roll** | Both >96% <500 Hz; `t1` DC offset |
| 6 | `wep_flak_airburst` | `wep_flak_airburst_t1.mp3` | High-pass 40 Hz (`t2` alt after DC cut) |
| 7 | `wep_torp_eject` | **Re-roll** | `t1` dark; `t2` fails mono (-3.6 dB hi) |
| 8 | `evt_pass_by_slug` | **Re-roll** | Both >95% <500 Hz, no zip |
| 9 | `wep_directorate_turbo` | `wep_directorate_turbo_t1.mp3` | Ready (`t2` strong round-robin partner) |
| 10 | `wep_directorate_hturbo` | `wep_directorate_hturbo_t1.mp3` | Dual-mono; +3 dB presence lift |
| 11 | `wep_directorate_ion_beam` | `wep_directorate_ion_beam_t1.mp3` | Trim 5 ms; loop 0.25 to 0.70 s for long beams |
| 12 | `wep_directorate_picket` | **Re-roll** | Both 99.8% to 99.9% <500 Hz |
| 13 | `wep_hullbreaker_scatter` | `wep_hullbreaker_scatter_t1.mp3` | Standout, ready (`t2` alt) |
| 14 | `wep_hullbreaker_rockets` | `wep_hullbreaker_rockets_t2.mp3` | Trim 7 ms, fold mono |
| 15 | `wep_hullbreaker_junk_gun` | **Re-roll** | `t1` mono fail + dark; `t2` DC + dark |
| 16 | `wep_chorus_bioplasma` | **Re-roll** | Old industrial prompt; `t1` backward envelope |
| 17 | `wep_chorus_tendril` | `wep_chorus_tendril_t1.mp3` | High-pass 40 Hz (`t2` alt for faster 91 ms peak) |
| 18 | `wep_chorus_spore_cloud` | **Re-roll** | Both 92% to 98% >2 kHz hiss + mono fail |
| 19 | `wep_chorus_sporeb` | `wep_chorus_sporeb_t2.mp3` | Lift gain ~5 dB, fold mono |
| 20 | `wep_ithar_needle` | `wep_ithar_needle_t1.mp3` | High-pass 50 Hz, lift gain + upper mids |
| 21 | `wep_ithar_pulsar` | `wep_ithar_pulsar_t1.mp3` | Trim 7 ms; loop 0.10 to 0.45 s for long beams |
| 22 | `wep_ithar_startorp` | `wep_ithar_startorp_t2.mp3` | Trim 10 ms, high-pass 35 Hz (`t1` alt) |
| 23 | `wep_eclipse_gsentry` | **Re-roll** | Both fail mono (`t1` corr -0.40, `t2` corr 0.01) |
| 24 | `wep_eclipse_gauss_charge` | `wep_eclipse_gauss_charge_t2.mp3` | Trim 27 ms, fold mono |
| 25 | `wep_eclipse_nlance` | `wep_eclipse_nlance_t1.mp3` | Dual-mono; subtle upper-mid snap lift |
| 26 | `wep_eclipse_doom` | `wep_eclipse_doom_t1.mp3` | Lift gain ~8 dB; loop middle for long arcs (`t2` alt) |
| 27 | `wep_eclipse_doom_charge` | **Re-roll** | `t1` 340 ms dead head; `t2` 95.5% <500 Hz |
| 28 | `wep_craft_guns` | `wep_craft_guns_t2.mp3` | High-pass 40 Hz for DC (`t1` alt) |
| 29 | `wep_craft_bombs` | `wep_craft_bombs_t1.mp3` | Lift gain ~6 dB, fold mono |
| 30 | `wep_mech_recoil_tail` | `wep_mech_recoil_tail_t1.mp3` | Trim 8 ms, lift gain (`t2` alt) |
| 31 | `wep_layer_body_heavy` | `wep_layer_body_heavy_t1.mp3` | Pure Layer B low body (`t2` 57 Hz alt) |
| 32 | `imp_glass_armor` | `imp_glass_armor_t1.mp3` | Lift gain ~10 dB + +4 dB high-mid lift |
| 33 | `imp_obsidian_eclipse` | **Re-roll** | `t1` mid/hi mono drop + dark; `t2` 99.4% <500 Hz |
| 34 | `imp_metal_light` | `imp_metal_light_t1.mp3` | Trim 4 ms, fold mono |
| 35 | `imp_energy_sear` | **Re-roll** | Both ~99% <500 Hz; `t2` -4.5 dB hi cancel |
| 36 | `imp_las` | `imp_las_t1.mp3` | Lift gain ~8 dB, fold mono |
| 37 | `imp_acid_on_metal` | `imp_acid_on_metal_t2.mp3` | Trim 5 ms, fold mono |
| 38 | `shd_break_prismatic` | **Re-roll** | Both fail mono (`t1` corr 0.15, `t2` corr 0.08) |
| 39 | `shd_hit_absorb` | `shd_hit_absorb_t2.mp3` | Borderline mono; verify quiet deflection in mix |
| 40 | `dmg_turret_knockout` | `dmg_turret_knockout_t2.mp3` | Fold mono, +3 dB presence lift |
| 41 | `dmg_shield_burnout` | **Re-roll** | Both 90% to 95% >2 kHz fizz + mono fail |
| 42 | `dmg_breach_shear_metal` | `dmg_breach_shear_metal_t2.mp3` | Standout, ready |
| 43 | `dmg_breach_vent` | **Re-roll** | Both out-of-phase mono fail (corr -0.18 / -0.01) |
| 44 | `dmg_engine_fail` | `dmg_engine_fail_t1.mp3` | Standout, trim 5 ms, fold mono |
| 45 | `death_directorate_blackout` | `death_directorate_blackout_t1.mp3` | Dual-mono, ready (`t2` longer-wind-down alt) |
| 46 | `death_hullbreaker_snap` | `death_hullbreaker_snap_t2.mp3` | Lift gain ~10 dB, fold mono |
| 47 | `death_ithar_shatter` | **Re-roll** | Both >98% <500 Hz + mono mid/hi drop |
| 48 | `death_eclipse_shear` | **Re-roll** | Both 100.0% <500 Hz pure sub-boom |
| 49 | `death_metal_break` | `death_metal_break_t1.mp3` | Fold mono, +2 to 3 dB metal-crack presence |
| 50 | `death_sunward_magazine` | **Re-roll** | Both >97% <500 Hz muffled booms |
| 51 | `ui_boss_arrival` | `ui_boss_arrival_t1.mp3` | Unpositioned UI; trim 7 ms, pitch +2 st to D2 |
| 52 | `evt_fleet_warp_in` | **Re-roll** | `t1` 99.9% <500 Hz + late; `t2` mono fail |
| 53 | `ui_confirm_latch` | `ui_confirm_latch_t1.mp3` | Trim 29 ms, lift gain ~8 dB (`t2` alt) |
| 54 | `ui_turn_start` | `ui_turn_start_t2.mp3` | Lift gain ~7 dB, optional tune F#3 to D3 (`t1` alt) |
| 55 | `amb_bridge_bed` | **Re-roll** | Leaked voice at 7 to 11 s (+15 dB spike) |

---

## Short List of IDs That Need a Re-Roll (20 of 55)

1. **`wep_sunward_turret`:** Drop `"compact punchy low thump"`; push bright forged-steel breech crack and sharp midrange propellant report.
2. **`wep_sunward_hbattery`:** Drop `"heavy hull-frame low-end shudder"` and `"slower and deeper"`; ask for a hard bright propellant crack and ringing forged-iron barrel bark over controlled low punch.
3. **`wep_torp_eject`:** Drop `"deep compressed-gas thump"`; lead with close centered heavy steel rail slide, crisp pneumatic burst, and solid mechanical latch clunk.
4. **`evt_pass_by_slug`:** Drop `"deep heavy"`, `"low and solid"`, and `"dark tail"`; prompt a fast high-velocity Doppler pressure whip and crisp midrange air zip over a tight brief thump.
5. **`wep_directorate_picket`:** Drop `"compact firm low-mid punch"`; prompt one short bright crisp high-voltage plasma-arc tick and disciplined light energy snap.
6. **`wep_hullbreaker_junk_gun`:** Drop `"blunt low thump"`; prompt a bright clattering iron-housing rattle and rough metallic scrap-turret crack.
7. **`wep_chorus_bioplasma`:** Wait for Chorus projectile look confirmation, then replace `"industrial culvert"` and `"molten mineral slag"` with immediate `t=0` pressurized wet calcified-sac / organic ejection.
8. **`wep_chorus_spore_cloud`:** Drop `"fine mineral dust"` and `"gas blowout"`; prompt a centered pressurized organic spore-pod burst with a firm woody-sac low-mid thump and coarse wet-organic scatter.
9. **`wep_eclipse_gsentry`:** Drop `"deep hollow sub-bass drop"`; prompt one centered tight cold electrostatic void snap paired with a compact hollow mid-low magnetic knock cutting dead.
10. **`wep_eclipse_doom_charge`:** Drop `"deep reverse-suction sub-bass"`; prompt a tight centered inward vacuum air-pull rush with rising cold electrostatic coil tension snapping abruptly into silence.
11. **`imp_obsidian_eclipse`:** Drop `"sub-bass"` and `"monolithic"`; lead with hard cold brittle obsidian slab crack and sharp dark stone splintering with a brief crisp electrostatic snap over a tight mid-low knock.
12. **`imp_energy_sear`:** Drop `"forceful pressurized heat-impact punch"`; prompt a bright fierce electric weld-arc flash and hot scorching metallic crackle on armor steel over a tight mid-weight impact.
13. **`shd_break_prismatic`:** Drop `"racing outward"` and `"scatter"` (wide stereo triggers); prompt a centered close-mic crystal-barrier fracture into a clear descending glass-harmonic tone.
14. **`dmg_shield_burnout`:** Prompt one close centered dry high-voltage electrical arc snap across steel plating with a short audible midrange transformer buzz beneath (no wide spark spray).
15. **`dmg_breach_vent`:** Drop `"Wide"` and `"rushing outward"` (wide noise triggers); prompt a tight centered close-mic high-pressure air relief valve blast starting immediately and thinning fast to silence.
16. **`death_ithar_shatter`:** Drop `"deep resonant glacier fracture boom"`, `"Colossal"`, and `"dark resonant silence"`; prompt a centered collapse of thick crystalline armor slabs cracking and ringing apart in bright cascading fractures over a firm mid-low structural break.
17. **`death_eclipse_shear`:** Drop `"Colossal"`, `"deep sub-harmonic"`, and `"Monumental"`; lead with hard brittle basalt-stone slabs grinding and shearing apart with crisp dry rock-fracture grit and sharp cold electrostatic crackle over a dark hollow low knock.
18. **`death_sunward_magazine`:** Drop `"muffled"`, `"deep heavy"`, and `"massive low end"`; prompt one sharp tight internal ammunition detonation bursting inside armored steel plating with a crisp metallic hull-plate crack and brief hot blast.
19. **`evt_fleet_warp_in`:** Drop `"monumental deep sub-bass"` and `"low heavy"`; prompt a crisp centered inward gravitational pressure snap immediately cracking into a punchy mid-low spatial displacement boom and brief resonant thruster settle.
20. **`amb_bridge_bed`:** Drop `"no vocals"` (pink-elephant voice leak) and `"command bridge"` (radio-chatter trigger); prompt an empty uncrewed mechanical engine-room tone with steady low reactor hum, faint smooth air duct flow, and soft constant transformer drone at flat unchanging volume (`loop: true`, `prompt_influence: 0.50`).
