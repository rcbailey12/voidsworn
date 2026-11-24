# Wave F and Wave A Extras Sound Ear Audit (Issues 1752 and 1947)

Direct listening and mono fold-down audit of all **161 Wave F ElevenLabs takes** (`opus1752wavef/out_20261123_234059_1725/out_new/elevenlabs/`, 80 sound ids) plus the **4 Wave A extras** (`wep_sunward_battery_t1/t2` and `ui_click_switch_t1/t2` from relay `pc-out-opus1752wavea`, 2 sound ids) for **165 takes across 82 sound ids**. Every take was listened to directly alongside its current game baseline (`listen/audio/*_today*.ogg` and the mastered Gate 2 keepers in `godot/audio/clips/`), measured with a Python and ffmpeg FFT pass (44.1 kHz, power-weighted bands, stereo-to-mono fold loss in dB, L/R channel splits, onset timing, peak, T95, envelope windows, high-frequency tail whine scan, and loop seam checks), and borderline wide stereo takes plus all 4 loop wrap seams were rendered and verified by ear.

Note on id count: `contrib/opus/sound/elevenlabs_gate3.json` (`waves.F`) holds 33 placeholder ids from `wep_ithar_flak` through `ui_enemy_turn` (not 34), plus 4 polish re-rolls, 16 new moments, and 27 variety ids = 80 Wave F ids (161 takes), plus the 2 Wave A extra ids (4 takes) = 82 ids and 165 takes total.

## Bottom Line (Read Before Listening)

- **Per-take scorecard: 82 keeps, 83 rejects** across 165 takes (161 Wave F + 4 Wave A extras).
- **Final answer breakdown across all 82 ids:** **72 of 82 ids ship without re-rolling** (42 single take, 17 both takes, 13 single stereo channel L/R), **1 keep today's sound** (`death_wreck_settle`), and **9 re-rolls**.
- **The 9 re-roll ids (one sentence each on what to change):**
  - `ship_thruster_puff`: re-roll: lengthen to 0.7 s and ask for a single brief nozzle puff that ends in clean silence so the burst does not slam into the 0.48 s file end.
  - `death_metal_run`: re-roll: ask for five distinct sharp midrange metallic blast cracks spaced across 1.8 s with steel shrapnel, dropping low-explosion body words so it stays above 250 Hz and actually rolls bow to stern.
  - `wep_ithar_pulsar_b`: re-roll: generate with loop enabled and flat-volume wording so it holds one steady level with no swells, and ask for bright high crystal shimmer plus a low cathedral hum alongside the midrange chord.
  - `evt_torp_intercept`: re-roll: lengthen to 1.1 s with the same prompt so the warhead detonation decays cleanly instead of cutting off at its peak at 800 ms.
  - `imp_energy_sear_more`: re-roll: keep the same prompt at higher influence (0.75) and add 'bright crackling arc' so takes keep `imp_energy_sear_0.ogg`'s 28% >2 kHz plasma sear instead of turning into quiet or dark thuds.
  - `wep_sunward_autocannon_more`: re-roll: raise influence to 0.75 or shift to v3 with explicit tight mechanical cannon punch so takes match `wep_sunward_autocannon_0.ogg` instead of flipping between a tinny click and a muffled thud.
  - `wep_sunward_turret_more`: re-roll: drop low-punch weight or move to v3 emphasizing a bright forged-steel breech crack so takes match `wep_sunward_turret_0.ogg`'s 52% midrange bark.
  - `wep_eclipse_gsentry_more`: re-roll: lead with a loud crisp high-voltage snap and drop heavy obsidian weight words so takes match `wep_eclipse_gsentry_0.ogg`'s level and 45% >2 kHz bite.
  - `wep_craft_guns_more`: re-roll: ask explicitly for a tight three-round rapid fighter cannon burst lasting about 200 ms so takes match `wep_craft_guns_0.ogg`'s burst cadence instead of collapsing to one short pop.
- **Key ear findings across Wave F and Wave A extras:**
  1. **Placeholders are a huge win (30 of 33 ship, 1 keeps today, 2 re-rolls):** Glasswright flak (`wep_ithar_flak`), Directorate ion hit (`imp_ion_disrupt`), Eclipse gauss hit (`imp_gauss_slug`), ship launches/coughs/charges, boarding/brace orders, and every acoustic UI cue (`ui_cancel_switch`, `ui_select_detent`, `ui_hover_tick`, `ui_panel_slide`, `ui_alert_bell`, `ui_round_bell`, `ui_enemy_turn`) replace old synths and flat clips cleanly. Only `ship_thruster_puff` (both takes chop off at peak on the final sample `479 ms`) and `death_metal_run` (both takes pile `61%` to `72%` below 100 Hz and die by `0.5 s` instead of rolling 5 to 6 blasts) need re-rolls; `death_wreck_settle` keeps today's crisp `wreckSettle` because Wave F `t2` is a harsh `2.38 kHz` brake screech.
  2. **Polish re-rolls landed 3 of 4:** `wep_hullbreaker_rockets_b` (`t2`) nails one single crude launch cleanly; `dmg_engine_fail_long` (`channel R of t2`) delivers the full 1.5 s sputtering wind-down with crisp turbine whine and zero mono loss; `ui_boss_arrival_long` (`t2`) is far fuller and audible past 2.5 s (though its quiet tail fades before 3.5 s). Only `wep_ithar_pulsar_b` missed: both takes pulse/swell unevenly and collapsed to bare `99.8%` midrange singing-bowls with zero high shimmer or low body.
  3. **New moments are a standout success (15 of 16 ship):** Players immediately recognize `evt_ram_impact` (`t1`), `evt_asteroid_scrape` (`t1 and t2`), `evt_hull_alarm` (`t1`, avoiding `t2`'s naval foghorn), `ui_purchase` (`t1 and t2`), `ui_module_install` (`t1`), `ui_relic_socket` (`t1 and t2`), `ui_rank_up` (`t2`), `ui_event_comm` (`t1 and t2`), `ui_ship_lost` (`t2`, a grave `230 Hz` memorial bell), and both seamless 8 s terrain beds (`evt_gravity_well` `t1` and `evt_nebula_bed` `t1`, both verified seamless on wrap renders). Only `evt_torp_intercept` needs a re-roll (`t2` chops off right on its warhead blast peak at `800.0 ms`).
  4. **Variety round-robin added usable takes to 22 of 27 keepers:** 17 ids passed straight mono fold (5 with both takes, 12 with one take), 5 ids matched the keeper cleanly via a single stereo channel L or R (`imp_metal_light_more`, `imp_las_more`, `wep_directorate_turbo_more`, `wep_chorus_spore_cloud_more`, `wep_eclipse_gauss_fire_ctl_more`, with bonus clean single channels noted on `imp_metal_heavy_more`, `shd_hit_absorb_more`, and `wep_ithar_shard_more`), and 5 ids missed the keeper's character or cadence (`imp_energy_sear_more`, `wep_sunward_autocannon_more`, `wep_sunward_turret_more`, `wep_eclipse_gsentry_more`, `wep_craft_guns_more`).
  5. **Wave A extras both ship:** `wep_sunward_battery` `t2` (massive forged-iron blast, solid mono after 40 Hz HP and peak trim; `channel L of t1` is also clean) and `ui_click_switch` `t1` (weighty acoustic toggle click, trim `24 ms` dead head).
  6. **Recurring mastering traps to handle systematically:** Several UI cues (`ui_select_detent`, `ui_hover_tick`, `ui_panel_slide`, `ui_relic_socket`, `ui_rank_up`) and `map_fleet_arrive` carry `40` to `156 ms` of dead head and need head trims; all ElevenLabs `v2` shell-gun takes (`wep_sunward_hbattery_more`, `wep_flak_airburst_more`, `wep_hullbreaker_scatter_more`, `wep_hullbreaker_junk_gun_more`, `wep_sunward_battery`) need peak headroom trims (`+0.8` to `+1.4 dBFS`) and 40 Hz high-pass filtering; and `evt_nebula_bed_t1` sits at `-49.4 dB` raw so it needs a ~+23 dB gain lift.

---

## Quick Pick Summary (All 82 IDs)

| # | Group | Sound ID | Final Answer | Mastering / Handling Notes |
|---|---|---|---|---|
| 1 | Placeholder | `wep_ithar_flak` | **t1 and t2** | Fold to mono (`t2` is tighter lead); onset already `0.0 ms`, gentle de-ess above 8 kHz if bright in mix |
| 2 | Placeholder | `imp_gauss_slug` | **t1** | Fold to mono, trim `28 ms` quiet lead-in so hit lands at `t=0`, high-pass 40 Hz |
| 3 | Placeholder | `imp_ion_disrupt` | **t1 and t2** | Fold to mono (`t2` has tighter `corr +0.92`), high-pass 40 Hz |
| 4 | Placeholder | `imp_patter_hull` | **t2** | Fold to mono, apply a `30 ms` tail fade in mastering to remove the last-sample tick at `799.8 ms` |
| 5 | Placeholder | `imp_patter_shield` | **channel L of t1** | Extract channel L only (avoids 4 dB L/R tilt and `-3.1 dB` mid fold loss), lift gain ~+6 dB |
| 6 | Placeholder | `boom_pop_metal` | **t1** | Fold to mono, high-pass 40 Hz |
| 7 | Placeholder | `boom_small_metal` | **t1** | Fold to mono, high-pass 40 Hz |
| 8 | Placeholder | `boom_medium_metal` | **channel L of t2** | Extract channel L only (preserves `15.4%` midrange crunch and `7.9%` high debris at `-17.5 dB` RMS, `-1.9 dBFS` peak), high-pass 40 Hz |
| 9 | Placeholder | `ship_engine_loop` | **channel R of t2** | Extract channel R only (avoids `-2.9 dB` wide fold loss), high-pass 40 Hz; seamless 6 s loop |
| 10 | Placeholder | `ship_craft_launch` | **t1** | Fold to mono, high-pass 40 Hz |
| 11 | Placeholder | `ship_phase_jump` | **channel L of t2** | Extract channel L only (`-16.3 dB` RMS, `26.8%` mid, `11.1%` high, `-0.2 dBFS` peak), high-pass 40 Hz |
| 12 | Placeholder | `ship_engine_cough` | **t1 and t2** | Fold to mono (`t2` is punchier), high-pass 40 Hz |
| 13 | Placeholder | `ship_thruster_puff` | **re-roll** | lengthen to 0.7 s and ask for a single brief nozzle puff that ends in clean silence so the burst does not slam into the 0.48 s file end. |
| 14 | Placeholder | `ship_power_charge` | **t1** | Fold to mono, high-pass 40 Hz |
| 15 | Placeholder | `death_metal_powerdown` | **t1** | Fold to mono, high-pass 40 Hz (strips `15.0%` sub-40 rumble cleanly, leaving `85%` above 100 Hz) |
| 16 | Placeholder | `death_metal_vent` | **t1 and t2** | Fold to mono, high-pass 40 Hz; both are pure mono with <5% below 100 Hz |
| 17 | Placeholder | `death_metal_crack` | **t2** | Fold to mono, high-pass 40 Hz (zero energy below 100 Hz) |
| 18 | Placeholder | `death_metal_run` | **re-roll** | ask for five distinct sharp midrange metallic blast cracks spaced across 1.8 s with steel shrapnel, dropping low-explosion body words so it stays above 250 Hz and actually rolls bow to stern. |
| 19 | Placeholder | `death_debris_cool` | **channel R of t1** | Extract channel R only (`-27.5 dB` RMS, `17.4%` mid, `15.8%` high), high-pass 60 Hz, lift gain to quiet debris target |
| 20 | Placeholder | `death_hulk_vent` | **t1** | Fold to mono, high-pass 40 Hz, lift gain ~+10 dB (clean `-17.2 dBFS` peak headroom) |
| 21 | Placeholder | `death_metal_tail` | **t1 and t2** | Fold to mono, high-pass 40 Hz; both are pure mono with <3% below 100 Hz |
| 22 | Placeholder | `death_wreck_settle` | **keep today's sound** | Keep today's `wreckSettle` (`25/35/40%`, crisp midrange, zero harsh screech) |
| 23 | Placeholder | `death_bass_drop` | **t1** | Fold to mono (or extract channel L for +2.9 dB extra sub weight), high-pass 25 Hz |
| 24 | Placeholder | `ord_brace_lock` | **t2** | Fold to mono, high-pass 40 Hz |
| 25 | Placeholder | `ord_adapt_shift` | **channel L of t1** | Extract channel L only (`-19.6 dB` RMS, `47.5% <500 / 8.8% mid / 43.7% hi`, `-1.9 dBFS` peak), high-pass 40 Hz |
| 26 | Placeholder | `ord_board_grapple` | **t2** | Fold to mono, high-pass 40 Hz |
| 27 | Placeholder | `ui_cancel_switch` | **t3** | Fold to mono (pure `corr +0.95`, `0.0 ms` onset), lift gain to UI target; `t1` also works after trimming `34 ms` |
| 28 | Placeholder | `ui_select_detent` | **t1 and t2** | Fold to mono, trim dead heads (`58 ms` on `t1`, `132 ms` on `t2`), lift gain to UI target |
| 29 | Placeholder | `ui_hover_tick` | **t1** | Fold to mono, trim `90 ms` dead head, lift gain gently to soft hover level |
| 30 | Placeholder | `ui_panel_slide` | **t1 and t2** | Fold to mono, trim quiet lead-ins (`95 ms` on `t1`, `115 ms` on `t2`), lift gain |
| 31 | Placeholder | `ui_alert_bell` | **t2** | Fold to mono (`0.0 ms` onset), lift gain ~+5 dB to UI target |
| 32 | Placeholder | `ui_round_bell` | **t1** | Fold to mono (pure `corr +1.00`), trim `40 ms` dead head, lift gain ~+8 dB |
| 33 | Placeholder | `ui_enemy_turn` | **t2** | Keep stereo as unpositioned UI sting (or fold to mono with +1 dB lift), high-pass 35 Hz |
| 34 | Polish | `wep_ithar_pulsar_b` | **re-roll** | generate with loop enabled and flat-volume wording so it holds one steady level with no swells, and ask for bright high crystal shimmer plus a low cathedral hum alongside the midrange chord. |
| 35 | Polish | `wep_hullbreaker_rockets_b` | **t2** | Fold to mono (pure `corr +1.00`, `0.0 ms` onset), high-pass 40 Hz |
| 36 | Polish | `ui_boss_arrival_long` | **t2** | Keep stereo as unpositioned UI sting (or fold cleanly, `corr +0.89`), high-pass 30 Hz; gentle compression optional to lift the 1.5 to 3.0 s brass sustain |
| 37 | Polish | `dmg_engine_fail_long` | **channel R of t2** | Extract channel R only (`-15.6 dB` RMS, `45.2% <500 / 26.8% mid / 27.9% hi`, `-1.7 dBFS` peak, `6.1 ms` onset), high-pass 40 Hz |
| 38 | New moment | `evt_ram_impact` | **t1** | Fold to mono (pure `corr +0.99`, `0.0 ms` onset), high-pass 40 Hz |
| 39 | New moment | `evt_torp_intercept` | **re-roll** | lengthen to 1.1 s with the same prompt so the warhead detonation decays cleanly instead of cutting off at its peak at 800 ms. |
| 40 | New moment | `shd_raise` | **channel L of t2** | Extract channel L only (`-16.7 dB` RMS, `93.6/3.2/3.2%`, `-3.2 dBFS` peak), trim `30 ms` quiet lead-in, add +3 dB presence lift above 800 Hz |
| 41 | New moment | `evt_gravity_well` | **t1** | Fold to mono (`corr +0.93`) or keep stereo as terrain bed, high-pass 35 Hz, lift ~+8 dB; seamless loop verified |
| 42 | New moment | `evt_nebula_bed` | **t1** | Keep stereo as unpositioned terrain bed (or channel R if mono 3D), lift ~+23 dB and verify noise floor; seamless loop verified |
| 43 | New moment | `evt_asteroid_scrape` | **t1 and t2** | Fold to mono (`t1` is heavier pure mono `corr +0.97`), high-pass 40 Hz |
| 44 | New moment | `evt_hull_alarm` | **t1** | Fold to mono (pure `corr +1.00`), match loudness to alert bus (raw `-12.7 dB` is hot) |
| 45 | New moment | `ui_command_issue` | **t1 and t2** | Fold to mono (`t2` has faster `6.4 ms` onset and `corr +0.94`), high-pass 40 Hz |
| 46 | New moment | `map_fleet_jump` | **t1** | Keep stereo as unpositioned map cue (or channel R if mono), trim `40 ms` quiet lead-in, high-pass 35 Hz |
| 47 | New moment | `map_fleet_arrive` | **t1** | Fold to mono (rock-solid `corr +0.95`), trim `65 ms` dead head, high-pass 40 Hz |
| 48 | New moment | `ui_purchase` | **t1 and t2** | Fold to mono (both pure `corr +1.00`), high-pass 40 Hz |
| 49 | New moment | `ui_module_install` | **t1** | Keep stereo as unpositioned UI cue (or fold cleanly, `-1.5 dB`), high-pass 40 Hz |
| 50 | New moment | `ui_relic_socket` | **t1 and t2** | Fold to mono (both pure `corr +0.99/1.00`), trim dead heads (`150 ms` on `t1`, `90 ms` on `t2`) |
| 51 | New moment | `ui_rank_up` | **t2** | Keep stereo as unpositioned UI cue (or channel R if mono), trim `50 ms` dead head, high-pass 40 Hz |
| 52 | New moment | `ui_event_comm` | **t1 and t2** | Fold to mono (`t2` is crisper pure mono `corr +0.99`), high-pass 40 Hz |
| 53 | New moment | `ui_ship_lost` | **t2** | Fold to mono (pure `corr +1.00`), trim `30 ms` lead-in |
| 54 | Variety | `imp_metal_light_more` | **channel R of t2** | Extract channel R only (`-19.2 dB` RMS, `-0.5 dBFS` peak, `35/29/35%`), high-pass 40 Hz; `channel L of t1` is also usable |
| 55 | Variety | `imp_metal_heavy_more` | **t2** | Fold to mono, high-pass 40 Hz; `channel L of t1` also works for a 4th take |
| 56 | Variety | `imp_las_more` | **channel L of t2** | Extract channel L only (`-17.8 dB` RMS, `66.1% <500 / 15.5% mid / 18.4% hi`, `-1.1 dBFS` peak), high-pass 40 Hz |
| 57 | Variety | `imp_energy_sear_more` | **re-roll** | keep the same prompt at higher influence (0.75) and add 'bright crackling arc' so takes keep `imp_energy_sear_0.ogg`'s 28% >2 kHz plasma sear instead of turning into quiet or dark thuds. |
| 58 | Variety | `imp_bio_flesh_more` | **t1 and t2** | Fold to mono (pure `corr +1.00/0.99`), apply keeper's `hp: 65, eq: bio` |
| 59 | Variety | `imp_glass_armor_more` | **t1 and t2** | Fold to mono (pure `corr +1.00/0.99`), high-pass 40 Hz, apply keeper's `eq: presence` |
| 60 | Variety | `imp_obsidian_eclipse_more` | **t1 and t2** | Fold to mono (both `corr +0.95`), trim `27 ms` lead-in on `t1`, high-pass 40 Hz |
| 61 | Variety | `shd_hit_absorb_more` | **t1** | Fold to mono (`corr +0.94`), trim `20 ms` lead-in, high-pass 40 Hz; `channel L of t2` also matches cleanly |
| 62 | Variety | `wep_sunward_autocannon_more` | **re-roll** | raise influence to 0.75 or shift to v3 with explicit tight mechanical cannon punch so takes match `wep_sunward_autocannon_0.ogg` instead of flipping between a tinny click and a muffled thud. |
| 63 | Variety | `wep_sunward_turret_more` | **re-roll** | drop low-punch weight or move to v3 emphasizing a bright forged-steel breech crack so takes match `wep_sunward_turret_0.ogg`'s 52% midrange bark. |
| 64 | Variety | `wep_sunward_hbattery_more` | **t2** | Fold to mono (`corr +0.95`), high-pass 40 Hz, trim `+0.8 dBFS` peak headroom |
| 65 | Variety | `wep_flak_airburst_more` | **t1** | Fold to mono (`corr +0.98`), high-pass 40 Hz (clears `15.6% <20 Hz`), trim `+0.8 dBFS` peak |
| 66 | Variety | `wep_directorate_laser_b_more` | **t2** | Fold to mono (`corr +0.95`), lift gain ~+5 dB to match `wep_directorate_laser_0.ogg` |
| 67 | Variety | `wep_directorate_turbo_more` | **channel L of t2** | Extract channel L only (`-22.7 dB` RMS, `79.5/8.8/11.8%` matching keeper `77.3/9.3/13.4%`, `-2.3 dBFS` peak), high-pass 40 Hz |
| 68 | Variety | `wep_directorate_hturbo_more` | **t1 and t2** | Fold to mono (both `corr +0.96/0.99`), apply keeper's `eq: presence`, high-pass 40 Hz |
| 69 | Variety | `wep_directorate_picket_more` | **t1** | Fold to mono (`corr +0.94`), high-pass 40 Hz |
| 70 | Variety | `wep_hullbreaker_scatter_more` | **t1** | Fold to mono (`corr +0.64`), high-pass 40 Hz, trim `+1.4 dBFS` peak headroom |
| 71 | Variety | `wep_hullbreaker_junk_gun_more` | **t1** | Fold to mono (`corr +0.78`), high-pass 40 Hz (clears `11.5% <20 Hz`), trim `+1.2 dBFS` peak; zero tinnitus whine |
| 72 | Variety | `wep_chorus_spines_more` | **t2** | Fold to mono (`corr +0.94`), high-pass 40 Hz |
| 73 | Variety | `wep_chorus_spore_cloud_more` | **channel R of t1** | Extract channel R only (`-19.7 dB` RMS, `82.8/8.5/8.7%` matching keeper `81.8/7.6/10.7%`, `-1.4 dBFS` peak), high-pass 40 Hz |
| 74 | Variety | `wep_chorus_sporeb_more` | **t2** | Fold to mono (pure `corr +0.99`), high-pass 40 Hz |
| 75 | Variety | `wep_ithar_shard_more` | **t2** | Fold to mono (`corr +0.53`, `-0.1 dB` mid), high-pass 40 Hz; `channel L of t1` also works cleanly |
| 76 | Variety | `wep_ithar_needle_more` | **t1 and t2** | Fold to mono (pure `corr +1.00/0.99`), apply keeper's `hp: 50, eq: presence` |
| 77 | Variety | `wep_eclipse_gsentry_more` | **re-roll** | lead with a loud crisp high-voltage snap and drop heavy obsidian weight words so takes match `wep_eclipse_gsentry_0.ogg`'s level and 45% >2 kHz bite. |
| 78 | Variety | `wep_eclipse_gauss_fire_ctl_more` | **channel R of t2** | Extract channel R only (`-16.1 dB` RMS, `93.9/3.1/3.0%` matching keeper `91.4/2.5/6.2%`, `-1.4 dBFS` peak), apply keeper's `eq: presence`, high-pass 40 Hz |
| 79 | Variety | `wep_craft_guns_more` | **re-roll** | ask explicitly for a tight three-round rapid fighter cannon burst lasting about 200 ms so takes match `wep_craft_guns_0.ogg`'s burst cadence instead of collapsing to one short pop. |
| 80 | Variety | `ui_confirm_latch_more` | **t2** | Keep stereo or fold cleanly (`corr +0.89`), trim `11 ms` lead-in; `t1` can also join if kept stereo like the keeper |
| 81 | Wave A extra | `wep_sunward_battery` | **t2** | Fold to mono (`corr +0.73`), high-pass 40 Hz, trim `+1.0 dBFS` peak headroom; `channel L of t1` can join as a second take |
| 82 | Wave A extra | `ui_click_switch` | **t1** | Keep stereo as unpositioned UI cue (or channel R if mono), trim `24 ms` dead head, lift gain |

---

## Group 1: Placeholders (33 Wave F IDs, 69 Takes)

### 1. `wep_ithar_flak` (gun_flak variant ithar.flak (Glasswright flak: ONE burst), 0.6 s)

- **Today baseline:** `wep_ithar_flak_today0.ogg` (`-26.1 dB`, `28.0/50.8/21.2%`, `T95 57 ms`).
- **`wep_ithar_flak_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Bright glittering crystalline prism spray that fits the Glasswrights cleanly and easily replaces today's generic kinetic `gunFlak`.
  2. **Bass (<500 Hz):** No (`0.3%` below 500 Hz stereo, `0.3%` mono). Measured stereo `0.3%` <500 Hz (`0.0%` <20 Hz), `0.1%` in 500 Hz to 2 kHz, `99.6%` >2 kHz; mono centroid `10730 Hz`, dominant `13600.0 Hz`, `-21.1 dB` stereo RMS (`-21.6 dB` mono, peak `-4.5 dBFS`).
  3. **Mono:** Holds up cleanly with minor softening. `corr +0.75`, fold loss `-0.58 dB` overall (`-0.82 dB` <500 Hz, `-0.99 dB` 500 Hz to 2 kHz, `-0.57 dB` >2 kHz, `-0.09 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `112.4 ms`, `T95 = 244 ms`, dur `0.6 s`.
- **`wep_ithar_flak_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Louder, tighter crystal burst with pure mono lock and instant snap, making a strong lead paired with `t1`.
  2. **Bass (<500 Hz):** No (`0.3%` below 500 Hz stereo, `0.3%` mono). Measured stereo `0.3%` <500 Hz (`0.0%` <20 Hz), `0.1%` in 500 Hz to 2 kHz, `99.6%` >2 kHz; mono centroid `9969 Hz`, dominant `7691.7 Hz`, `-19.4 dB` stereo RMS (`-19.4 dB` mono, peak `-3.0 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +0.96`, fold loss `-0.08 dB` overall (`-0.31 dB` <500 Hz, `-0.39 dB` 500 Hz to 2 kHz, `-0.08 dB` >2 kHz, `-0.07 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `151.4 ms`, `T95 = 299 ms`, dur `0.6 s`.
- **Final answer (`wep_ithar_flak`):** **t1 and t2**

### 2. `imp_gauss_slug` (hit_rail (gauss and rail hits on a metal hull), 0.9 s)

- **Today baseline:** `imp_gauss_slug_today0.ogg` (`-20.2 dB`, `99.5/0.5/0.0%`, `T95 976 ms`), `imp_gauss_slug_today1.ogg` (`-22.6 dB`, `88.5/5.9/5.6%`, `T95 83 ms`).
- **`imp_gauss_slug_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Hard cold magnetic crack with a hollow metallic ring and steel armor punch that fits Eclipse and beats today's dark `hullHitBig`.
  2. **Bass (<500 Hz):** Yes (`69.8%` below 500 Hz stereo, `73.2%` mono). Measured stereo `69.8%` <500 Hz (`0.0%` <20 Hz), `2.9%` in 500 Hz to 2 kHz, `27.3%` >2 kHz; mono centroid `6805 Hz`, dominant `194.3 Hz`, `-18.3 dB` stereo RMS (`-18.7 dB` mono, peak `-1.0 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +0.86`, fold loss `-0.32 dB` overall (`-0.12 dB` <500 Hz, `-0.21 dB` 500 Hz to 2 kHz, `-0.90 dB` >2 kHz, `-1.26 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, within 30 ms (`28.9 ms` at -40 dB, `35.7 ms` at -30 dB, `38.4 ms` at -20 dB; trim ~`28 ms` head for tight sync). Peak at `161.4 ms`, `T95 = 261 ms`, dur `0.88 s`.
- **`imp_gauss_slug_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Crisp fast armor punch in stereo with immediate onset, but phase-uncorrelated stereo collapses across every band when folded to mono.
  2. **Bass (<500 Hz):** Yes (`62.0%` below 500 Hz stereo, `61.8%` mono). Measured stereo `62.0%` <500 Hz (`0.1%` <20 Hz), `5.7%` in 500 Hz to 2 kHz, `32.3%` >2 kHz; mono centroid `6460 Hz`, dominant `62.5 Hz`, `-18.9 dB` stereo RMS (`-22.1 dB` mono, peak `-0.9 dBFS`).
  3. **Mono:** Yes, loses top end/midrange and punch. `corr -0.04`, fold loss `-3.20 dB` overall (`-3.21 dB` <500 Hz, `-3.40 dB` 500 Hz to 2 kHz, `-3.14 dB` >2 kHz, `-2.94 dB` attack 0 to 60 ms). Single channels: L `-18.8 dB` (pk `-0.9 dBFS`, `58.9/6.3/34.8%`), R `-19.1 dB` (pk `-1.7 dBFS`, `65.3/5.1/29.7%`).
  4. **Onset (<=30 ms):** Yes, immediate (`5.3 ms` at -40 dB, `9.9 ms` at -30 dB, `16.4 ms` at -20 dB). Peak at `72.6 ms`, `T95 = 232 ms`, dur `0.88 s`.
- **Final answer (`imp_gauss_slug`):** **t1**

### 3. `imp_ion_disrupt` (hit_ion (Directorate ion beam contact on a hull), 0.9 s)

- **Today baseline:** `imp_ion_disrupt_today0.ogg` (`-23.6 dB`, `20.1/25.7/54.3%`, `T95 685 ms`), `imp_ion_disrupt_today1.ogg` (`-25.0 dB`, `0.3/0.1/99.6%`, `T95 133 ms`).
- **`imp_ion_disrupt_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Heavy substation breaker slam into a flat-pitch electric surge on steel plating that fits the Directorate and replaces today's synthy `arc` and `ionZap`.
  2. **Bass (<500 Hz):** Yes (`72.8%` below 500 Hz stereo, `73.6%` mono). Measured stereo `72.8%` <500 Hz (`0.3%` <20 Hz), `10.6%` in 500 Hz to 2 kHz, `16.7%` >2 kHz; mono centroid `3391 Hz`, dominant `83.0 Hz`, `-18.4 dB` stereo RMS (`-19.3 dB` mono, peak `-0.7 dBFS`).
  3. **Mono:** Holds up cleanly with minor softening. `corr +0.63`, fold loss `-0.88 dB` overall (`-0.83 dB` <500 Hz, `-1.07 dB` 500 Hz to 2 kHz, `-0.98 dB` >2 kHz, `-0.59 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`3.9 ms` at -40 dB, `7.8 ms` at -30 dB, `11.4 ms` at -20 dB). Peak at `73.4 ms`, `T95 = 279 ms`, dur `0.88 s`.
- **`imp_ion_disrupt_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Tighter punchy electric slam and crackling short-out with rock-solid mono lock, pairing naturally with `t1`.
  2. **Bass (<500 Hz):** Yes (`68.9%` below 500 Hz stereo, `70.5%` mono). Measured stereo `68.9%` <500 Hz (`0.5%` <20 Hz), `8.4%` in 500 Hz to 2 kHz, `22.7%` >2 kHz; mono centroid `4127 Hz`, dominant `40.9 Hz`, `-18.7 dB` stereo RMS (`-18.9 dB` mono, peak `-1.0 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +0.92`, fold loss `-0.18 dB` overall (`-0.08 dB` <500 Hz, `-0.34 dB` 500 Hz to 2 kHz, `-0.45 dB` >2 kHz, `-0.35 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`6.7 ms` at -40 dB, `8.2 ms` at -30 dB, `25.8 ms` at -20 dB). Peak at `41.8 ms`, `T95 = 284 ms`, dur `0.88 s`.
- **Final answer (`imp_ion_disrupt`):** **t1 and t2**

### 4. `imp_patter_hull` (patter_hull (small fragments raining on a hull after a hit), 0.8 s)

- **Today baseline:** `imp_patter_hull_today0.ogg` (`-21.2 dB`, `2.5/22.5/75.0%`, `T95 61 ms`).
- **`imp_patter_hull_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Ramps upward to a late peak at `647 ms` instead of thinning out fast and sits too dark and rumbly for fine steel shrapnel.
  2. **Bass (<500 Hz):** Yes (`73.7%` below 500 Hz stereo, `74.0%` mono). Measured stereo `73.7%` <500 Hz (`0.1%` <20 Hz), `23.4%` in 500 Hz to 2 kHz, `2.9%` >2 kHz; mono centroid `2227 Hz`, dominant `78.8 Hz`, `-17.1 dB` stereo RMS (`-17.1 dB` mono, peak `-4.3 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +0.98`, fold loss `-0.04 dB` overall (`-0.03 dB` <500 Hz, `-0.05 dB` 500 Hz to 2 kHz, `-0.48 dB` >2 kHz, `-0.01 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.3 ms` at -40 dB, `2.8 ms` at -30 dB, `9.4 ms` at -20 dB). Peak at `646.9 ms`, `T95 = 729 ms`, dur `0.8 s`.
- **`imp_patter_hull_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Crisp metallic shrapnel ticks across armored steel that start at `0.0 ms`, hold pure mono, and beat today's tiny `patterHull` once the last-sample tick is faded.
  2. **Bass (<500 Hz):** No (`39.5%` below 500 Hz stereo, `39.8%` mono). Measured stereo `39.5%` <500 Hz (`0.0%` <20 Hz), `15.7%` in 500 Hz to 2 kHz, `44.8%` >2 kHz; mono centroid `4955 Hz`, dominant `156.2 Hz`, `-19.0 dB` stereo RMS (`-19.1 dB` mono, peak `-3.8 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +0.97`, fold loss `-0.06 dB` overall (`-0.03 dB` <500 Hz, `-0.04 dB` 500 Hz to 2 kHz, `-0.10 dB` >2 kHz, `-0.04 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `799.8 ms`, `T95 = 754 ms`, dur `0.8 s`. Warning: abrupt end cut (`last 20 ms` is `+0.2 dB` rel RMS).
- **Final answer (`imp_patter_hull`):** **t2**

### 5. `imp_patter_shield` (patter_shield (fragments ticking off an energy shield), 0.8 s)

- **Today baseline:** `imp_patter_shield_today0.ogg` (`-22.0 dB`, `2.5/93.6/3.8%`, `T95 35 ms`).
- **`imp_patter_shield_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Fine bright crackling electric ticks read clearly as shield shrapnel over today's dull `patterShield`, but a 4 dB left-right tilt costs `-3.1 dB` of midrange on mono fold; channel L alone is clean.
  2. **Bass (<500 Hz):** No (`6.1%` below 500 Hz stereo, `6.0%` mono). Measured stereo `6.1%` <500 Hz (`0.0%` <20 Hz), `0.9%` in 500 Hz to 2 kHz, `92.9%` >2 kHz; mono centroid `5920 Hz`, dominant `7723.8 Hz`, `-28.7 dB` stereo RMS (`-29.9 dB` mono, peak `-5.5 dBFS`).
  3. **Mono:** Yes, loses top end/midrange. `corr +0.54`, fold loss `-1.28 dB` overall (`-1.36 dB` <500 Hz, `-3.10 dB` 500 Hz to 2 kHz, `-1.26 dB` >2 kHz, `-0.77 dB` attack 0 to 60 ms). L/R imbalance `+4.0 dB` (`L -27.1 dB`, `R -31.1 dB`). Single channels: L `-27.1 dB` (pk `-5.5 dBFS`, `5.9/1.0/93.1%`), R `-31.1 dB` (pk `-9.4 dBFS`, `6.6/0.9/92.4%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.3 ms` at -30 dB, `9.8 ms` at -20 dB). Peak at `65.4 ms`, `T95 = 282 ms`, dur `0.8 s`.
- **`imp_patter_shield_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Softer fizzy crackle that loses punch and midrange in wide stereo fold-down.
  2. **Bass (<500 Hz):** No (`43.0%` below 500 Hz stereo, `42.7%` mono). Measured stereo `43.0%` <500 Hz (`1.0%` <20 Hz), `16.6%` in 500 Hz to 2 kHz, `40.4%` >2 kHz; mono centroid `4885 Hz`, dominant `591.2 Hz`, `-20.1 dB` stereo RMS (`-22.4 dB` mono, peak `-3.3 dBFS`).
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.19`, fold loss `-2.27 dB` overall (`-2.29 dB` <500 Hz, `-2.70 dB` 500 Hz to 2 kHz, `-2.08 dB` >2 kHz, `-0.68 dB` attack 0 to 60 ms). Single channels: L `-20.4 dB` (pk `-3.9 dBFS`, `39.2/15.3/45.5%`), R `-19.8 dB` (pk `-3.3 dBFS`, `46.3/17.7/36.0%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `208.8 ms`, `T95 = 375 ms`, dur `0.8 s`.
- **Final answer (`imp_patter_shield`):** **channel L of t1**

### 6. `boom_pop_metal` (pop (strike craft or missile destroyed), 0.7 s)

- **Today baseline:** `boom_pop_metal_today0.ogg` (`-22.0 dB`, `83.2/8.0/8.8%`, `T95 430 ms`).
- **`boom_pop_metal_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Compact sharp strike-craft blast with a quick metallic crunch and fast decay that beats today's longer, muddier `boomSmall`.
  2. **Bass (<500 Hz):** Yes (`63.7%` below 500 Hz stereo, `69.9%` mono). Measured stereo `63.7%` <500 Hz (`0.0%` <20 Hz), `21.8%` in 500 Hz to 2 kHz, `14.4%` >2 kHz; mono centroid `3896 Hz`, dominant `42.6 Hz`, `-18.9 dB` stereo RMS (`-19.6 dB` mono, peak `-0.4 dBFS`).
  3. **Mono:** Holds up cleanly with minor softening. `corr +0.73`, fold loss `-0.63 dB` overall (`-0.23 dB` <500 Hz, `-1.30 dB` 500 Hz to 2 kHz, `-1.65 dB` >2 kHz, `-0.47 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `6.6 ms` at -30 dB, `15.1 ms` at -20 dB). Peak at `128.2 ms`, `T95 = 171 ms`, dur `0.68 s`.
- **`boom_pop_metal_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Over 6 dB quieter than `t1` and loses midrange and top crunch when folded to mono.
  2. **Bass (<500 Hz):** Yes (`69.8%` below 500 Hz stereo, `78.9%` mono). Measured stereo `69.8%` <500 Hz (`0.0%` <20 Hz), `19.8%` in 500 Hz to 2 kHz, `10.4%` >2 kHz; mono centroid `3876 Hz`, dominant `126.4 Hz`, `-25.1 dB` stereo RMS (`-26.2 dB` mono, peak `-2.4 dBFS`).
  3. **Mono:** Yes, loses top end/midrange. `corr +0.55`, fold loss `-1.10 dB` overall (`-0.56 dB` <500 Hz, `-2.78 dB` 500 Hz to 2 kHz, `-2.44 dB` >2 kHz, `-0.92 dB` attack 0 to 60 ms). Single channels: L `-25.2 dB` (pk `-4.1 dBFS`, `70.8/19.0/10.2%`), R `-25.0 dB` (pk `-2.4 dBFS`, `68.8/20.5/10.7%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.1 ms` at -20 dB). Peak at `18.3 ms`, `T95 = 87 ms`, dur `0.68 s`.
- **Final answer (`boom_pop_metal`):** **t1**

### 7. `boom_small_metal` (boom_s (small explosion bursting through a steel hull), 1.1 s)

- **Today baseline:** `boom_small_metal_today0.ogg` (`-22.0 dB`, `83.2/8.0/8.8%`, `T95 430 ms`), `boom_small_metal_today1.ogg` (`-16.9 dB`, `91.7/6.6/1.7%`, `T95 482 ms`).
- **`boom_small_metal_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Punchy internal steel hull explosion with clear buckling armor crunch and fast decay, cleaner in the midrange than today's `boomSmall` and `boomCrunch`.
  2. **Bass (<500 Hz):** Yes (`73.3%` below 500 Hz stereo, `78.4%` mono). Measured stereo `73.3%` <500 Hz (`0.0%` <20 Hz), `15.6%` in 500 Hz to 2 kHz, `11.1%` >2 kHz; mono centroid `3278 Hz`, dominant `35.2 Hz`, `-20.2 dB` stereo RMS (`-21.0 dB` mono, peak `-1.2 dBFS`).
  3. **Mono:** Holds up cleanly with minor softening. `corr +0.67`, fold loss `-0.79 dB` overall (`-0.49 dB` <500 Hz, `-1.49 dB` 500 Hz to 2 kHz, `-2.03 dB` >2 kHz, `-0.70 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`4.6 ms` at -40 dB, `7.4 ms` at -30 dB, `12.7 ms` at -20 dB). Peak at `24.6 ms`, `T95 = 351 ms`, dur `1.08 s`.
- **`boom_small_metal_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Brighter crunch in stereo, but wide stereo strips `-3.5 dB` of midrange and `-2.7 dB` of attack when folded to mono.
  2. **Bass (<500 Hz):** Yes (`52.9%` below 500 Hz stereo, `61.1%` mono). Measured stereo `52.9%` <500 Hz (`0.3%` <20 Hz), `24.1%` in 500 Hz to 2 kHz, `23.0%` >2 kHz; mono centroid `4236 Hz`, dominant `90.7 Hz`, `-18.4 dB` stereo RMS (`-20.2 dB` mono, peak `-0.8 dBFS`).
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.32`, fold loss `-1.80 dB` overall (`-1.17 dB` <500 Hz, `-3.47 dB` 500 Hz to 2 kHz, `-1.90 dB` >2 kHz, `-2.72 dB` attack 0 to 60 ms). Single channels: L `-18.5 dB` (pk `-1.3 dBFS`, `58.2/19.0/22.9%`), R `-18.4 dB` (pk `-0.8 dBFS`, `47.7/29.2/23.1%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.3 ms` at -30 dB, `6.6 ms` at -20 dB). Peak at `14.8 ms`, `T95 = 542 ms`, dur `1.08 s`.
- **Final answer (`boom_small_metal`):** **t1**

### 8. `boom_medium_metal` (boom_m (a hull section blowing out), 1.7 s)

- **Today baseline:** `boom_medium_metal_today0.ogg` (`-22.0 dB`, `83.2/8.0/8.8%`, `T95 430 ms`), `boom_medium_metal_today1.ogg` (`-21.6 dB`, `100.0/0.0/0.0%`, `T95 594 ms`), `boom_medium_metal_today2.ogg` (`-20.1 dB`, `98.4/1.2/0.4%`, `T95 668 ms`).
- **`boom_medium_metal_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Darker blast whose midrange and debris rattle drop more than `-3.2 dB` in wide mono fold-down.
  2. **Bass (<500 Hz):** Yes (`84.8%` below 500 Hz stereo, `88.7%` mono). Measured stereo `84.8%` <500 Hz (`0.2%` <20 Hz), `11.6%` in 500 Hz to 2 kHz, `3.6%` >2 kHz; mono centroid `3155 Hz`, dominant `65.5 Hz`, `-18.2 dB` stereo RMS (`-20.2 dB` mono, peak `-1.2 dBFS`).
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.26`, fold loss `-2.00 dB` overall (`-1.80 dB` <500 Hz, `-3.24 dB` 500 Hz to 2 kHz, `-3.58 dB` >2 kHz, `-1.92 dB` attack 0 to 60 ms). Single channels: L `-18.5 dB` (pk `-1.5 dBFS`, `86.5/9.8/3.6%`), R `-18.0 dB` (pk `-1.2 dBFS`, `83.2/13.2/3.7%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `23.0 ms`, `T95 = 737 ms`, dur `1.68 s`.
- **`boom_medium_metal_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Powerful hull-section blowout with gritty grinding steel and tumbling debris that crushes today's muffled `boomLow` and `debris`, but wide stereo drops `-1.9 dB` across every band in mono; channel L alone is spotless.
  2. **Bass (<500 Hz):** Yes (`77.6%` below 500 Hz stereo, `77.9%` mono). Measured stereo `77.6%` <500 Hz (`0.7%` <20 Hz), `15.1%` in 500 Hz to 2 kHz, `7.3%` >2 kHz; mono centroid `2974 Hz`, dominant `66.7 Hz`, `-17.5 dB` stereo RMS (`-19.3 dB` mono, peak `-1.5 dBFS`).
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.30`, fold loss `-1.86 dB` overall (`-1.84 dB` <500 Hz, `-1.86 dB` 500 Hz to 2 kHz, `-2.06 dB` >2 kHz, `-1.29 dB` attack 0 to 60 ms). Single channels: L `-17.5 dB` (pk `-1.9 dBFS`, `76.7/15.4/7.9%`), R `-17.5 dB` (pk `-1.5 dBFS`, `78.5/14.8/6.7%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `216.3 ms`, `T95 = 705 ms`, dur `1.68 s`.
- **Final answer (`boom_medium_metal`):** **channel L of t2**

### 9. `ship_engine_loop` (engine (a ship's drive under way, looped), 6.0 s)

- **Today baseline:** `ship_engine_loop_today0.ogg` (`-15.8 dB`, `74.5/6.4/19.1%`, `T95 2007 ms`).
- **`ship_engine_loop_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Loops smoothly with no audible seam, but carries `14.2%` sub-20 Hz rumble, a 3.1 dB left-right imbalance, and phase-inverted stereo.
  2. **Bass (<500 Hz):** Yes (`99.8%` below 500 Hz stereo, `99.8%` mono). Measured stereo `99.8%` <500 Hz (`14.2%` <20 Hz), `0.2%` in 500 Hz to 2 kHz, `0.0%` >2 kHz; mono centroid `188 Hz`, dominant `28.5 Hz`, `-17.2 dB` stereo RMS (`-20.4 dB` mono, peak `-3.9 dBFS`). Loop seam: `+0.58 dB` end-to-start, spectral cosine `0.997`, 0.5 s spread `4.14 dB`, boundary jump `0.0044`.
  3. **Mono:** Yes, loses top end/midrange and punch. `corr -0.05`, fold loss `-3.21 dB` overall (`-3.18 dB` <500 Hz, `-3.22 dB` 500 Hz to 2 kHz, `-3.82 dB` >2 kHz, `-3.21 dB` attack 0 to 60 ms). L/R imbalance `-3.2 dB` (`L -19.0 dB`, `R -15.9 dB`). Single channels: L `-19.0 dB` (pk `-6.4 dBFS`, `99.8/0.2/0.0%`), R `-15.9 dB` (pk `-3.9 dBFS`, `99.8/0.2/0.0%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `2781.8 ms`, `T95 = 5669 ms`, dur `6.0 s`.
- **`ship_engine_loop_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Smooth calm starship fusion drive hum with a seamless wrap that is miles cleaner than today's jackhammer-like `engineLoop`, but near-zero stereo correlation drops `-2.9 dB` in mono; channel R alone loops cleanly.
  2. **Bass (<500 Hz):** Yes (`100.0%` below 500 Hz stereo, `100.0%` mono). Measured stereo `100.0%` <500 Hz (`2.5%` <20 Hz), `0.0%` in 500 Hz to 2 kHz, `0.0%` >2 kHz; mono centroid `145 Hz`, dominant `35.0 Hz`, `-14.9 dB` stereo RMS (`-17.8 dB` mono, peak `-2.9 dBFS`). Loop seam: `-1.17 dB` end-to-start, spectral cosine `0.994`, 0.5 s spread `3.43 dB`, boundary jump `0.0009`.
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.03`, fold loss `-2.86 dB` overall (`-2.86 dB` <500 Hz, `-2.82 dB` 500 Hz to 2 kHz, `-2.58 dB` >2 kHz, `-3.31 dB` attack 0 to 60 ms). Single channels: L `-15.2 dB` (pk `-4.0 dBFS`, `100.0/0.0/0.0%`), R `-14.7 dB` (pk `-2.9 dBFS`, `100.0/0.0/0.0%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.4 ms` at -20 dB). Peak at `5239.6 ms`, `T95 = 5673 ms`, dur `6.0 s`.
- **Final answer (`ship_engine_loop`):** **channel R of t2**

### 10. `ship_craft_launch` (launch (strike craft leaving the bay), 1.3 s)

- **Today baseline:** `ship_craft_launch_today0.ogg` (`-16.9 dB`, `86.8/4.1/9.2%`, `T95 485 ms`).
- **`ship_craft_launch_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Clear heavy catapult release clunk followed by a fast fighter thruster streaking away, far more vivid than today's generic `launch`.
  2. **Bass (<500 Hz):** Yes (`62.4%` below 500 Hz stereo, `65.6%` mono). Measured stereo `62.4%` <500 Hz (`2.3%` <20 Hz), `26.5%` in 500 Hz to 2 kHz, `11.1%` >2 kHz; mono centroid `2635 Hz`, dominant `46.9 Hz`, `-21.8 dB` stereo RMS (`-22.1 dB` mono, peak `-1.1 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +0.90`, fold loss `-0.23 dB` overall (`-0.02 dB` <500 Hz, `-0.38 dB` 500 Hz to 2 kHz, `-1.23 dB` >2 kHz, `-1.93 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.5 ms` at -40 dB, `11.8 ms` at -30 dB, `16.5 ms` at -20 dB). Peak at `64.6 ms`, `T95 = 430 ms`, dur `1.28 s`.
- **`ship_craft_launch_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Starts late past 30 ms and loses `-2.8 dB` of top end and `-3.9 dB` of attack when folded to mono.
  2. **Bass (<500 Hz):** Yes (`56.7%` below 500 Hz stereo, `65.5%` mono). Measured stereo `56.7%` <500 Hz (`2.0%` <20 Hz), `27.6%` in 500 Hz to 2 kHz, `15.7%` >2 kHz; mono centroid `3092 Hz`, dominant `45.3 Hz`, `-20.1 dB` stereo RMS (`-21.0 dB` mono, peak `-1.4 dBFS`).
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.62`, fold loss `-0.95 dB` overall (`-0.33 dB` <500 Hz, `-1.51 dB` 500 Hz to 2 kHz, `-2.79 dB` >2 kHz, `-3.86 dB` attack 0 to 60 ms). Single channels: L `-20.9 dB` (pk `-3.1 dBFS`, `58.9/26.6/14.5%`), R `-19.4 dB` (pk `-1.4 dBFS`, `55.2/28.3/16.5%`).
  4. **Onset (<=30 ms):** No, late start (`30.4 ms` at -40 dB, `32.5 ms` at -30 dB, `51.0 ms` at -20 dB; trim ~`28 ms` dead head in mastering). Peak at `266.9 ms`, `T95 = 541 ms`, dur `1.28 s`.
- **Final answer (`ship_craft_launch`):** **t1**

### 11. `ship_phase_jump` (phase (short-range phase jump), 1.3 s)

- **Today baseline:** `ship_phase_jump_today0.ogg` (`-21.6 dB`, `51.4/14.2/34.4%`, `T95 793 ms`), `ship_phase_jump_today1.ogg` (`-23.6 dB`, `20.1/25.7/54.3%`, `T95 685 ms`).
- **`ship_phase_jump_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Good sci-fi phase-jump arc in stereo, but wide uncorrelated stereo collapses `-2.5` to `-3.0 dB` across all bands in mono.
  2. **Bass (<500 Hz):** Yes (`70.6%` below 500 Hz stereo, `73.4%` mono). Measured stereo `70.6%` <500 Hz (`0.0%` <20 Hz), `21.8%` in 500 Hz to 2 kHz, `7.6%` >2 kHz; mono centroid `2738 Hz`, dominant `149.2 Hz`, `-20.6 dB` stereo RMS (`-23.1 dB` mono, peak `-1.2 dBFS`).
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.14`, fold loss `-2.48 dB` overall (`-2.30 dB` <500 Hz, `-2.88 dB` 500 Hz to 2 kHz, `-3.04 dB` >2 kHz, `-2.25 dB` attack 0 to 60 ms). L/R imbalance `-2.6 dB` (`L -22.1 dB`, `R -19.5 dB`). Single channels: L `-22.1 dB` (pk `-3.5 dBFS`, `75.2/19.2/5.6%`), R `-19.5 dB` (pk `-1.2 dBFS`, `68.0/23.2/8.8%`).
  4. **Onset (<=30 ms):** Yes, within 30 ms (`27.0 ms` at -40 dB, `28.6 ms` at -30 dB, `32.5 ms` at -20 dB; trim ~`27 ms` head for tight sync). Peak at `219.1 ms`, `T95 = 424 ms`, dur `1.28 s`.
- **`ship_phase_jump_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Clean swelling pull, solid displacement thump, and quick collapse that beats today's `whoosh` and `arc`, but a 4.9 dB left-right tilt costs `-2.6` to `-3.0 dB` of mids and highs in mono; channel L alone is crisp and loud.
  2. **Bass (<500 Hz):** Yes (`62.2%` below 500 Hz stereo, `69.9%` mono). Measured stereo `62.2%` <500 Hz (`0.1%` <20 Hz), `26.5%` in 500 Hz to 2 kHz, `11.2%` >2 kHz; mono centroid `3607 Hz`, dominant `116.4 Hz`, `-18.1 dB` stereo RMS (`-19.8 dB` mono, peak `-0.2 dBFS`).
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.39`, fold loss `-1.75 dB` overall (`-1.24 dB` <500 Hz, `-2.64 dB` 500 Hz to 2 kHz, `-2.98 dB` >2 kHz, `-1.28 dB` attack 0 to 60 ms). L/R imbalance `+4.9 dB` (`L -16.3 dB`, `R -21.2 dB`). Single channels: L `-16.3 dB` (pk `-0.2 dBFS`, `62.1/26.8/11.1%`), R `-21.2 dB` (pk `-4.7 dBFS`, `62.5/25.8/11.7%`).
  4. **Onset (<=30 ms):** Yes, immediate (`8.0 ms` at -40 dB, `24.6 ms` at -30 dB, `26.2 ms` at -20 dB). Peak at `279.8 ms`, `T95 = 453 ms`, dur `1.28 s`.
- **Final answer (`ship_phase_jump`):** **channel L of t2**

### 12. `ship_engine_cough` (cough (a damaged drive misfiring), 0.9 s)

- **Today baseline:** `ship_engine_cough_today0.ogg` (`-18.5 dB`, `56.9/17.5/25.7%`, `T95 519 ms`).
- **`ship_engine_cough_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Two rough choking misfire bursts with a gritty mechanical stutter and dull clank, more mechanical than today's `cough`.
  2. **Bass (<500 Hz):** Yes (`77.0%` below 500 Hz stereo, `76.6%` mono). Measured stereo `77.0%` <500 Hz (`0.1%` <20 Hz), `16.8%` in 500 Hz to 2 kHz, `6.1%` >2 kHz; mono centroid `2329 Hz`, dominant `63.6 Hz`, `-17.0 dB` stereo RMS (`-17.4 dB` mono, peak `-1.4 dBFS`).
  3. **Mono:** Holds up cleanly with minor softening. `corr +0.84`, fold loss `-0.36 dB` overall (`-0.39 dB` <500 Hz, `-0.21 dB` 500 Hz to 2 kHz, `-0.49 dB` >2 kHz, `-0.19 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, within 30 ms (`13.1 ms` at -40 dB, `27.9 ms` at -30 dB, `34.3 ms` at -20 dB; trim ~`13 ms` head for tight sync). Peak at `227.1 ms`, `T95 = 553 ms`, dur `0.88 s`.
- **`ship_engine_cough_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Punchier, louder misfire stutter with rock-solid mono lock and tight onset, pairing cleanly with `t1`.
  2. **Bass (<500 Hz):** Yes (`82.5%` below 500 Hz stereo, `82.8%` mono). Measured stereo `82.5%` <500 Hz (`2.1%` <20 Hz), `14.1%` in 500 Hz to 2 kHz, `3.4%` >2 kHz; mono centroid `2368 Hz`, dominant `64.8 Hz`, `-14.5 dB` stereo RMS (`-14.6 dB` mono, peak `-1.3 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +0.95`, fold loss `-0.11 dB` overall (`-0.10 dB` <500 Hz, `-0.19 dB` 500 Hz to 2 kHz, `-0.18 dB` >2 kHz, `-0.16 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`10.0 ms` at -40 dB, `20.4 ms` at -30 dB, `26.7 ms` at -20 dB). Peak at `96.0 ms`, `T95 = 554 ms`, dur `0.88 s`.
- **Final answer (`ship_engine_cough`):** **t1 and t2**

### 13. `ship_thruster_puff` (puff (a maneuvering thruster firing), 0.5 s)

- **Today baseline:** `ship_thruster_puff_today0.ogg` (`-23.1 dB`, `5.9/1.4/92.7%`, `T95 1206 ms`).
- **`ship_thruster_puff_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Nice tight valve click and gas rush, but wide stereo drops `-2.9 dB` of midrange in mono and the clip cuts off abruptly right on its peak at `479.5 ms`.
  2. **Bass (<500 Hz):** No (`33.8%` below 500 Hz stereo, `43.3%` mono). Measured stereo `33.8%` <500 Hz (`0.3%` <20 Hz), `57.7%` in 500 Hz to 2 kHz, `8.5%` >2 kHz; mono centroid `3703 Hz`, dominant `208.3 Hz`, `-18.4 dB` stereo RMS (`-20.5 dB` mono, peak `-1.4 dBFS`).
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.24`, fold loss `-2.07 dB` overall (`-1.00 dB` <500 Hz, `-2.94 dB` 500 Hz to 2 kHz, `-1.58 dB` >2 kHz, `-2.52 dB` attack 0 to 60 ms). Single channels: L `-18.4 dB` (pk `-1.6 dBFS`, `34.2/56.1/9.8%`), R `-18.5 dB` (pk `-1.4 dBFS`, `33.5/59.4/7.2%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `479.5 ms`, `T95 = 478 ms`, dur `0.48 s`. Warning: abrupt end cut (`last 20 ms` is `+3.8 dB` rel RMS).
- **`ship_thruster_puff_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Loses `-2.9 dB` of top end in mono and cuts off abruptly right on its peak at `479.2 ms`.
  2. **Bass (<500 Hz):** No (`40.6%` below 500 Hz stereo, `44.0%` mono). Measured stereo `40.6%` <500 Hz (`0.6%` <20 Hz), `39.4%` in 500 Hz to 2 kHz, `20.0%` >2 kHz; mono centroid `3655 Hz`, dominant `89.6 Hz`, `-23.9 dB` stereo RMS (`-24.9 dB` mono, peak `-1.4 dBFS`).
  3. **Mono:** Yes, loses top end/midrange. `corr +0.61`, fold loss `-0.99 dB` overall (`-0.64 dB` <500 Hz, `-0.60 dB` 500 Hz to 2 kHz, `-2.89 dB` >2 kHz, `-1.04 dB` attack 0 to 60 ms). L/R imbalance `+2.1 dB` (`L -23.0 dB`, `R -25.1 dB`). Single channels: L `-23.0 dB` (pk `-1.4 dBFS`, `43.0/38.7/18.3%`), R `-25.1 dB` (pk `-8.9 dBFS`, `36.5/40.5/22.9%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.2 ms` at -20 dB). Peak at `479.2 ms`, `T95 = 479 ms`, dur `0.48 s`. Warning: abrupt end cut (`last 20 ms` is `+5.2 dB` rel RMS).
- **Final answer (`ship_thruster_puff`):** **re-roll: lengthen to 0.7 s and ask for a single brief nozzle puff that ends in clean silence so the burst does not slam into the 0.48 s file end.**

### 14. `ship_power_charge` (charge (an ability charging up), 1.1 s)

- **Today baseline:** `ship_power_charge_today0.ogg` (`-19.6 dB`, `18.2/15.3/66.5%`, `T95 1157 ms`).
- **`ship_power_charge_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Smooth rising capacitor hum climbing into a firm mechanical lock that feels far more physical than today's synthy `ionCharge`.
  2. **Bass (<500 Hz):** Yes (`61.8%` below 500 Hz stereo, `66.7%` mono). Measured stereo `61.8%` <500 Hz (`0.0%` <20 Hz), `9.2%` in 500 Hz to 2 kHz, `29.0%` >2 kHz; mono centroid `4723 Hz`, dominant `230.6 Hz`, `-15.9 dB` stereo RMS (`-16.3 dB` mono, peak `-1.4 dBFS`).
  3. **Mono:** Holds up cleanly with minor softening. `corr +0.83`, fold loss `-0.38 dB` overall (`-0.05 dB` <500 Hz, `-0.23 dB` 500 Hz to 2 kHz, `-1.26 dB` >2 kHz, `-0.82 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `7.6 ms` at -20 dB). Peak at `237.4 ms`, `T95 = 809 ms`, dur `1.08 s`.
- **`ship_power_charge_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Clean shorter charge-up with instant onset, though slightly softer top end in mono and quieter than `t1`.
  2. **Bass (<500 Hz):** Yes (`63.8%` below 500 Hz stereo, `72.1%` mono). Measured stereo `63.8%` <500 Hz (`0.0%` <20 Hz), `7.8%` in 500 Hz to 2 kHz, `28.4%` >2 kHz; mono centroid `4198 Hz`, dominant `137.0 Hz`, `-19.5 dB` stereo RMS (`-20.3 dB` mono, peak `-3.1 dBFS`).
  3. **Mono:** Holds up cleanly with minor softening. `corr +0.69`, fold loss `-0.78 dB` overall (`-0.25 dB` <500 Hz, `-1.67 dB` 500 Hz to 2 kHz, `-1.98 dB` >2 kHz, `-0.88 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `258.2 ms`, `T95 = 552 ms`, dur `1.08 s`.
- **Final answer (`ship_power_charge`):** **t1**

### 15. `death_metal_powerdown` (death_powerdown base (a steel ship's reactor dying), 1.8 s)

- **Today baseline:** `death_metal_powerdown_today0.ogg` (`-19.6 dB`, `18.2/15.3/66.5%`, `T95 1157 ms`), `death_metal_powerdown_today1.ogg` (`-21.6 dB`, `51.4/14.2/34.4%`, `T95 793 ms`).
- **`death_metal_powerdown_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Centered sinking reactor hum with crisp midrange relay clunks, zero 40 to 100 Hz sub-bass pile-up, and a clean decay that beats today's `ionCharge` and `whoosh`.
  2. **Bass (<500 Hz):** No (`35.6%` below 500 Hz stereo, `36.8%` mono). Measured stereo `35.6%` <500 Hz (`14.1%` <20 Hz), `10.7%` in 500 Hz to 2 kHz, `53.7%` >2 kHz; mono centroid `5701 Hz`, dominant `0.6 Hz`, `-19.7 dB` stereo RMS (`-20.0 dB` mono, peak `-0.6 dBFS`). Death low breakdown (mono): `15.0%` <40 Hz, `0.3%` in 40 to 100 Hz (`15.3%` <100 Hz), `15.2%` in 100 to 250 Hz, `6.4%` in 250 to 500 Hz.
  3. **Mono:** No loss; rock-solid mono. `corr +0.87`, fold loss `-0.31 dB` overall (`-0.15 dB` <500 Hz, `-0.34 dB` 500 Hz to 2 kHz, `-0.39 dB` >2 kHz, `-0.30 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.6 ms` at -30 dB, `13.6 ms` at -20 dB). Peak at `743.8 ms`, `T95 = 844 ms`, dur `1.76 s`.
- **`death_metal_powerdown_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Louder with even stronger midrange and high relay clunks and no sub-bass pile-up after 40 Hz high-pass, though it cuts off abruptly near the end (`-1.8 dB`) and needs a tail fade.
  2. **Bass (<500 Hz):** No (`25.1%` below 500 Hz stereo, `25.1%` mono). Measured stereo `25.1%` <500 Hz (`9.7%` <20 Hz), `14.3%` in 500 Hz to 2 kHz, `60.6%` >2 kHz; mono centroid `5478 Hz`, dominant `355.1 Hz`, `-16.7 dB` stereo RMS (`-17.2 dB` mono, peak `-0.9 dBFS`). Death low breakdown (mono): `12.1%` <40 Hz, `1.0%` in 40 to 100 Hz (`13.1%` <100 Hz), `5.2%` in 100 to 250 Hz, `6.9%` in 250 to 500 Hz.
  3. **Mono:** Holds up cleanly with minor softening. `corr +0.82`, fold loss `-0.47 dB` overall (`-0.45 dB` <500 Hz, `-0.25 dB` 500 Hz to 2 kHz, `-0.50 dB` >2 kHz, `-0.37 dB` attack 0 to 60 ms). L/R imbalance `-2.5 dB` (`L -18.1 dB`, `R -15.7 dB`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `8.5 ms` at -20 dB). Peak at `1045.9 ms`, `T95 = 1672 ms`, dur `1.76 s`. Warning: abrupt end cut (`last 20 ms` is `-1.8 dB` rel RMS).
- **Final answer (`death_metal_powerdown`):** **t1**

### 16. `death_metal_vent` (death_vent base (atmosphere venting from a dying hull), 1.5 s)

- **Today baseline:** `death_metal_vent_today0.ogg` (`-21.6 dB`, `51.4/14.2/34.4%`, `T95 793 ms`).
- **`death_metal_vent_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Gritty forceful pressurized gas roar centered in the 100 Hz to 2 kHz band with under 5% below 100 Hz, easily beating today's generic `whoosh`.
  2. **Bass (<500 Hz):** Yes (`73.0%` below 500 Hz stereo, `73.4%` mono). Measured stereo `73.0%` <500 Hz (`0.1%` <20 Hz), `16.8%` in 500 Hz to 2 kHz, `10.1%` >2 kHz; mono centroid `3419 Hz`, dominant `137.2 Hz`, `-12.5 dB` stereo RMS (`-12.5 dB` mono, peak `-1.2 dBFS`). Death low breakdown (mono): `0.3%` <40 Hz, `4.3%` in 40 to 100 Hz (`4.6%` <100 Hz), `33.1%` in 100 to 250 Hz, `35.6%` in 250 to 500 Hz.
  3. **Mono:** No loss; rock-solid mono. `corr +0.99`, fold loss `-0.03 dB` overall (`-0.01 dB` <500 Hz, `-0.03 dB` 500 Hz to 2 kHz, `-0.18 dB` >2 kHz, `-0.04 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `882.6 ms`, `T95 = 1214 ms`, dur `1.48 s`.
- **`death_metal_vent_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Equally centered pure-mono hull vent with no sub-bass pile-up, slightly warmer than `t1` and great as a second take.
  2. **Bass (<500 Hz):** Yes (`78.9%` below 500 Hz stereo, `79.1%` mono). Measured stereo `78.9%` <500 Hz (`0.1%` <20 Hz), `14.6%` in 500 Hz to 2 kHz, `6.5%` >2 kHz; mono centroid `2807 Hz`, dominant `283.1 Hz`, `-11.7 dB` stereo RMS (`-11.7 dB` mono, peak `-1.3 dBFS`). Death low breakdown (mono): `0.3%` <40 Hz, `4.7%` in 40 to 100 Hz (`5.0%` <100 Hz), `37.9%` in 100 to 250 Hz, `36.1%` in 250 to 500 Hz.
  3. **Mono:** No loss; rock-solid mono. `corr +0.99`, fold loss `-0.02 dB` overall (`-0.01 dB` <500 Hz, `-0.03 dB` 500 Hz to 2 kHz, `-0.10 dB` >2 kHz, `-0.01 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `394.9 ms`, `T95 = 1250 ms`, dur `1.48 s`.
- **Final answer (`death_metal_vent`):** **t1 and t2**

### 17. `death_metal_crack` (death_crack base (the hull's spine cracking), 1.5 s)

- **Today baseline:** `death_metal_crack_today0.ogg` (`-19.0 dB`, `100.0/0.0/0.0%`, `T95 1752 ms`), `death_metal_crack_today1.ogg` (`-20.2 dB`, `99.5/0.5/0.0%`, `T95 976 ms`), `death_metal_crack_today2.ogg` (`-31.1 dB`, `7.2/15.2/77.7%`, `T95 260 ms`).
- **`death_metal_crack_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Midrange snapping metal with zero sub-bass pile-up, but quiet, 8.3 dB lopsided left-to-right, and weak in mono.
  2. **Bass (<500 Hz):** No (`17.3%` below 500 Hz stereo, `16.3%` mono). Measured stereo `17.3%` <500 Hz (`0.0%` <20 Hz), `52.3%` in 500 Hz to 2 kHz, `30.3%` >2 kHz; mono centroid `3200 Hz`, dominant `408.8 Hz`, `-26.8 dB` stereo RMS (`-28.7 dB` mono, peak `-1.3 dBFS`). Death low breakdown (mono): `0.0%` <40 Hz, `0.0%` in 40 to 100 Hz (`0.0%` <100 Hz), `1.4%` in 100 to 250 Hz, `14.9%` in 250 to 500 Hz.
  3. **Mono:** Yes, loses punch. `corr +0.44`, fold loss `-1.89 dB` overall (`-2.16 dB` <500 Hz, `-1.77 dB` 500 Hz to 2 kHz, `-1.92 dB` >2 kHz, `-1.77 dB` attack 0 to 60 ms). L/R imbalance `-8.3 dB` (`L -32.7 dB`, `R -24.4 dB`). Single channels: L `-32.7 dB` (pk `-11.0 dBFS`, `18.1/52.1/29.8%`), R `-24.4 dB` (pk `-1.3 dBFS`, `17.2/52.4/30.4%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.4 ms` at -40 dB, `11.8 ms` at -30 dB, `17.6 ms` at -20 dB). Peak at `492.1 ms`, `T95 = 671 ms`, dur `1.48 s`.
- **`death_metal_crack_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Crisp snapping girders, rivets, and splitting steel right in the midrange with `0.0%` below 100 Hz, beating today's muddy `scrape` and `hullHitBig`.
  2. **Bass (<500 Hz):** No (`33.5%` below 500 Hz stereo, `37.8%` mono). Measured stereo `33.5%` <500 Hz (`0.0%` <20 Hz), `42.1%` in 500 Hz to 2 kHz, `24.4%` >2 kHz; mono centroid `3314 Hz`, dominant `299.3 Hz`, `-20.5 dB` stereo RMS (`-21.3 dB` mono, peak `-1.2 dBFS`). Death low breakdown (mono): `0.0%` <40 Hz, `0.0%` in 40 to 100 Hz (`0.0%` <100 Hz), `5.9%` in 100 to 250 Hz, `31.8%` in 250 to 500 Hz.
  3. **Mono:** Holds up cleanly with minor softening. `corr +0.69`, fold loss `-0.80 dB` overall (`-0.28 dB` <500 Hz, `-0.77 dB` 500 Hz to 2 kHz, `-1.69 dB` >2 kHz, `-6.14 dB` attack 0 to 60 ms). L/R imbalance `-2.4 dB` (`L -21.9 dB`, `R -19.5 dB`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `313.9 ms`, `T95 = 624 ms`, dur `1.48 s`.
- **Final answer (`death_metal_crack`):** **t2**

### 18. `death_metal_run` (death_run base (blasts running along the hull), 2.0 s)

- **Today baseline:** `death_metal_run_today0.ogg` (`-14.9 dB`, `99.0/0.9/0.1%`, `T95 3557 ms`).
- **`death_metal_run_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Severe sub-bass pile-up (`61.0%` below 100 Hz, only `1.3%` midrange) and dies out by `456 ms` instead of rolling through five or six hull blasts.
  2. **Bass (<500 Hz):** Yes (`97.8%` below 500 Hz stereo, `97.8%` mono). Measured stereo `97.8%` <500 Hz (`17.3%` <20 Hz), `1.3%` in 500 Hz to 2 kHz, `0.9%` >2 kHz; mono centroid `2107 Hz`, dominant `20.5 Hz`, `-20.4 dB` stereo RMS (`-20.4 dB` mono, peak `-1.6 dBFS`). Death low breakdown (mono): `47.1%` <40 Hz, `13.9%` in 40 to 100 Hz (`61.0%` <100 Hz), `32.5%` in 100 to 250 Hz, `4.4%` in 250 to 500 Hz.
  3. **Mono:** No loss; rock-solid mono. `corr +0.99`, fold loss `-0.01 dB` overall (`-0.01 dB` <500 Hz, `-0.05 dB` 500 Hz to 2 kHz, `-0.22 dB` >2 kHz, `-0.00 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `37.2 ms`, `T95 = 456 ms`, dur `2.0 s`.
- **`death_metal_run_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Same sub-bass pile-up (`72.1%` below 100 Hz, `1.7%` midrange) and stops by `558 ms`, adding mud under `boom_l` without a rolling chain.
  2. **Bass (<500 Hz):** Yes (`97.8%` below 500 Hz stereo, `97.8%` mono). Measured stereo `97.8%` <500 Hz (`8.8%` <20 Hz), `1.7%` in 500 Hz to 2 kHz, `0.5%` >2 kHz; mono centroid `1633 Hz`, dominant `56.0 Hz`, `-18.0 dB` stereo RMS (`-18.0 dB` mono, peak `-1.2 dBFS`). Death low breakdown (mono): `21.3%` <40 Hz, `50.8%` in 40 to 100 Hz (`72.1%` <100 Hz), `21.7%` in 100 to 250 Hz, `3.9%` in 250 to 500 Hz.
  3. **Mono:** No loss; rock-solid mono. `corr +1.00`, fold loss `-0.00 dB` overall (`-0.00 dB` <500 Hz, `-0.03 dB` 500 Hz to 2 kHz, `-0.10 dB` >2 kHz, `-0.00 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `2.4 ms`, `T95 = 558 ms`, dur `2.0 s`.
- **Final answer (`death_metal_run`):** **re-roll: ask for five distinct sharp midrange metallic blast cracks spaced across 1.8 s with steel shrapnel, dropping low-explosion body words so it stays above 250 Hz and actually rolls bow to stern.**

### 19. `death_debris_cool` (chunk_cool base (hot wreck pieces cooling), 2.2 s)

- **Today baseline:** `death_debris_cool_today0.ogg` (`-20.1 dB`, `98.4/1.2/0.4%`, `T95 668 ms`), `death_debris_cool_today1.ogg` (`-19.0 dB`, `100.0/0.0/0.0%`, `T95 1752 ms`).
- **`death_debris_cool_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Authentic sparse contracting steel ticks and creaks that beat today's dark `debris` and `scrape` with low sub-bass, but wide stereo drops `-3.6 dB` of mids and highs in mono; channel R alone is clean.
  2. **Bass (<500 Hz):** Yes (`67.0%` below 500 Hz stereo, `75.2%` mono). Measured stereo `67.0%` <500 Hz (`0.9%` <20 Hz), `18.0%` in 500 Hz to 2 kHz, `15.0%` >2 kHz; mono centroid `3948 Hz`, dominant `40.0 Hz`, `-28.1 dB` stereo RMS (`-30.4 dB` mono, peak `-8.8 dBFS`). Death low breakdown (mono): `6.5%` <40 Hz, `16.0%` in 40 to 100 Hz (`22.5%` <100 Hz), `34.4%` in 100 to 250 Hz, `18.3%` in 250 to 500 Hz.
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.16`, fold loss `-2.37 dB` overall (`-1.87 dB` <500 Hz, `-3.64 dB` 500 Hz to 2 kHz, `-3.58 dB` >2 kHz, `-2.16 dB` attack 0 to 60 ms). Single channels: L `-28.8 dB` (pk `-10.7 dBFS`, `67.2/18.9/13.9%`), R `-27.5 dB` (pk `-8.8 dBFS`, `66.8/17.4/15.8%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.1 ms` at -30 dB, `9.3 ms` at -20 dB). Peak at `535.3 ms`, `T95 = 753 ms`, dur `2.2 s`.
- **`death_debris_cool_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Phase-inverted stereo collapses `-4.0 dB` in mono and sounds darker than `t1`.
  2. **Bass (<500 Hz):** Yes (`79.5%` below 500 Hz stereo, `79.6%` mono). Measured stereo `79.5%` <500 Hz (`1.1%` <20 Hz), `15.9%` in 500 Hz to 2 kHz, `4.5%` >2 kHz; mono centroid `3093 Hz`, dominant `109.1 Hz`, `-26.2 dB` stereo RMS (`-30.2 dB` mono, peak `-8.0 dBFS`). Death low breakdown (mono): `5.8%` <40 Hz, `15.2%` in 40 to 100 Hz (`21.0%` <100 Hz), `31.9%` in 100 to 250 Hz, `26.7%` in 250 to 500 Hz.
  3. **Mono:** Yes, loses top end/midrange and punch. `corr -0.20`, fold loss `-3.95 dB` overall (`-3.95 dB` <500 Hz, `-4.11 dB` 500 Hz to 2 kHz, `-3.53 dB` >2 kHz, `-2.76 dB` attack 0 to 60 ms). Single channels: L `-26.2 dB` (pk `-8.5 dBFS`, `77.5/18.1/4.4%`), R `-26.3 dB` (pk `-8.0 dBFS`, `81.6/13.7/4.7%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `276.9 ms`, `T95 = 601 ms`, dur `2.2 s`.
- **Final answer (`death_debris_cool`):** **channel R of t1**

### 20. `death_hulk_vent` (hulk_vent base (a dead hulk slowly leaking), 2.2 s)

- **Today baseline:** `death_hulk_vent_today0.ogg` (`-21.6 dB`, `51.4/14.2/34.4%`, `T95 793 ms`), `death_hulk_vent_today1.ogg` (`-19.0 dB`, `100.0/0.0/0.0%`, `T95 1752 ms`).
- **`death_hulk_vent_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Quiet steady leaking hull gas with subtle settling metal groans, centered mono, clear midrange presence, and no sub-bass pile-up after 40 Hz high-pass.
  2. **Bass (<500 Hz):** Yes (`71.0%` below 500 Hz stereo, `72.6%` mono). Measured stereo `71.0%` <500 Hz (`9.6%` <20 Hz), `20.0%` in 500 Hz to 2 kHz, `8.9%` >2 kHz; mono centroid `2615 Hz`, dominant `153.2 Hz`, `-33.8 dB` stereo RMS (`-34.0 dB` mono, peak `-17.2 dBFS`). Death low breakdown (mono): `9.8%` <40 Hz, `11.0%` in 40 to 100 Hz (`20.8%` <100 Hz), `29.3%` in 100 to 250 Hz, `22.5%` in 250 to 500 Hz.
  3. **Mono:** No loss; rock-solid mono. `corr +0.90`, fold loss `-0.22 dB` overall (`-0.12 dB` <500 Hz, `-0.35 dB` 500 Hz to 2 kHz, `-0.69 dB` >2 kHz, `-0.10 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `9.7 ms`, `T95 = 1710 ms`, dur `2.2 s`.
- **`death_hulk_vent_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Loud harsh screaming vent roar that cuts off abruptly at `-2.9 dB` instead of a quiet dying hulk leak.
  2. **Bass (<500 Hz):** No (`33.9%` below 500 Hz stereo, `34.1%` mono). Measured stereo `33.9%` <500 Hz (`4.4%` <20 Hz), `34.2%` in 500 Hz to 2 kHz, `31.9%` >2 kHz; mono centroid `3224 Hz`, dominant `65.9 Hz`, `-19.5 dB` stereo RMS (`-19.5 dB` mono, peak `-2.4 dBFS`). Death low breakdown (mono): `4.7%` <40 Hz, `5.7%` in 40 to 100 Hz (`10.4%` <100 Hz), `5.1%` in 100 to 250 Hz, `18.8%` in 250 to 500 Hz.
  3. **Mono:** No loss; rock-solid mono. `corr +0.98`, fold loss `-0.04 dB` overall (`-0.01 dB` <500 Hz, `-0.01 dB` 500 Hz to 2 kHz, `-0.10 dB` >2 kHz, `-0.09 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.2 ms` at -20 dB). Peak at `215.8 ms`, `T95 = 1832 ms`, dur `2.2 s`. Warning: abrupt end cut (`last 20 ms` is `-2.9 dB` rel RMS).
- **Final answer (`death_hulk_vent`):** **t1**

### 21. `death_metal_tail` (death_tail base (debris settling after a kill), 2.2 s)

- **Today baseline:** `death_metal_tail_today0.ogg` (`-19.0 dB`, `100.0/0.0/0.0%`, `T95 1752 ms`), `death_metal_tail_today1.ogg` (`-20.1 dB`, `98.4/1.2/0.4%`, `T95 668 ms`), `death_metal_tail_today2.ogg` (`-21.6 dB`, `100.0/0.0/0.0%`, `T95 594 ms`).
- **`death_metal_tail_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Unmistakable tumbling steel fragments scraping and settling in pure mono with clear midrange and high detail and almost zero sub-bass.
  2. **Bass (<500 Hz):** No (`30.2%` below 500 Hz stereo, `30.6%` mono). Measured stereo `30.2%` <500 Hz (`0.0%` <20 Hz), `23.6%` in 500 Hz to 2 kHz, `46.2%` >2 kHz; mono centroid `3834 Hz`, dominant `292.3 Hz`, `-19.1 dB` stereo RMS (`-19.2 dB` mono, peak `-1.0 dBFS`). Death low breakdown (mono): `0.1%` <40 Hz, `2.7%` in 40 to 100 Hz (`2.8%` <100 Hz), `12.8%` in 100 to 250 Hz, `15.1%` in 250 to 500 Hz.
  3. **Mono:** No loss; rock-solid mono. `corr +0.96`, fold loss `-0.08 dB` overall (`-0.01 dB` <500 Hz, `-0.03 dB` 500 Hz to 2 kHz, `-0.14 dB` >2 kHz, `-0.05 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `15.1 ms`, `T95 = 1020 ms`, dur `2.2 s`.
- **`death_metal_tail_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Equally crisp pure-mono tumbling metal debris that settles cleanly to silence with `0.2%` below 100 Hz, easily beating today's muffled `scrape` and `boomLow`.
  2. **Bass (<500 Hz):** No (`24.6%` below 500 Hz stereo, `24.7%` mono). Measured stereo `24.6%` <500 Hz (`0.0%` <20 Hz), `26.9%` in 500 Hz to 2 kHz, `48.5%` >2 kHz; mono centroid `3667 Hz`, dominant `3498.6 Hz`, `-20.4 dB` stereo RMS (`-20.5 dB` mono, peak `-1.5 dBFS`). Death low breakdown (mono): `0.0%` <40 Hz, `0.2%` in 40 to 100 Hz (`0.2%` <100 Hz), `7.8%` in 100 to 250 Hz, `16.7%` in 250 to 500 Hz.
  3. **Mono:** No loss; rock-solid mono. `corr +0.99`, fold loss `-0.03 dB` overall (`-0.01 dB` <500 Hz, `-0.02 dB` 500 Hz to 2 kHz, `-0.05 dB` >2 kHz, `-0.01 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `70.8 ms`, `T95 = 727 ms`, dur `2.2 s`.
- **Final answer (`death_metal_tail`):** **t1 and t2**

### 22. `death_wreck_settle` (wreck base (a wreck groaning to rest), 2.2 s)

- **Today baseline:** `death_wreck_settle_today0.ogg` (`-19.0 dB`, `100.0/0.0/0.0%`, `T95 1752 ms`), `death_wreck_settle_today1.ogg` (`-27.5 dB`, `25.4/34.9/39.6%`, `T95 590 ms`).
- **`death_wreck_settle_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Very quiet, trapped below 500 Hz, and phase-inverted so it collapses `-3.5 dB` in mono.
  2. **Bass (<500 Hz):** Yes (`95.5%` below 500 Hz stereo, `94.9%` mono). Measured stereo `95.5%` <500 Hz (`0.0%` <20 Hz), `4.0%` in 500 Hz to 2 kHz, `0.6%` >2 kHz; mono centroid `1358 Hz`, dominant `198.2 Hz`, `-30.4 dB` stereo RMS (`-33.9 dB` mono, peak `-16.3 dBFS`). Death low breakdown (mono): `0.0%` <40 Hz, `0.0%` in 40 to 100 Hz (`0.0%` <100 Hz), `57.8%` in 100 to 250 Hz, `37.1%` in 250 to 500 Hz.
  3. **Mono:** Yes, loses top end/midrange and punch. `corr -0.13`, fold loss `-3.55 dB` overall (`-3.58 dB` <500 Hz, `-2.94 dB` 500 Hz to 2 kHz, `-4.16 dB` >2 kHz, `-1.96 dB` attack 0 to 60 ms). L/R imbalance `-3.3 dB` (`L -32.3 dB`, `R -29.0 dB`). Single channels: L `-32.3 dB` (pk `-19.0 dBFS`, `91.9/7.3/0.9%`), R `-29.0 dB` (pk `-16.3 dBFS`, `97.1/2.4/0.4%`).
  4. **Onset (<=30 ms):** Yes, immediate (`1.0 ms` at -40 dB, `17.4 ms` at -30 dB, `111.8 ms` at -20 dB). Peak at `1284.6 ms`, `T95 = 1507 ms`, dur `2.2 s`.
- **`death_wreck_settle_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Harsh piercing `2.38 kHz` metal-brake screech (`85.0%` above 2 kHz) that breaks Ryan's no-harshness rule and loses cleanly to today's `wreckSettle`.
  2. **Bass (<500 Hz):** No (`5.3%` below 500 Hz stereo, `5.3%` mono). Measured stereo `5.3%` <500 Hz (`0.0%` <20 Hz), `9.7%` in 500 Hz to 2 kHz, `85.0%` >2 kHz; mono centroid `2793 Hz`, dominant `2381.8 Hz`, `-18.9 dB` stereo RMS (`-20.0 dB` mono, peak `-0.3 dBFS`). Death low breakdown (mono): `0.0%` <40 Hz, `0.0%` in 40 to 100 Hz (`0.0%` <100 Hz), `1.2%` in 100 to 250 Hz, `4.1%` in 250 to 500 Hz.
  3. **Mono:** Mild softening; holds up cleanly by ear. `corr +0.54`, fold loss `-1.15 dB` overall (`-1.18 dB` <500 Hz, `-1.85 dB` 500 Hz to 2 kHz, `-1.07 dB` >2 kHz, `-0.64 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`5.0 ms` at -40 dB, `12.6 ms` at -30 dB, `29.5 ms` at -20 dB). Peak at `1024.3 ms`, `T95 = 1384 ms`, dur `2.2 s`.
- **Final answer (`death_wreck_settle`):** **keep today's sound**

### 23. `death_bass_drop` (bass_drop (low hit under a capital kill), 1.6 s)

- **Today baseline:** `death_bass_drop_today0.ogg` (`-10.4 dB`, `99.9/0.1/0.0%`, `T95 1405 ms`).
- **`death_bass_drop_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Massive clean physical low impact boom centered in 40 to 100 Hz with instant onset, beating today's cheesy pitch-dropping synth `bassDrop`.
  2. **Bass (<500 Hz):** Yes (`100.0%` below 500 Hz stereo, `100.0%` mono). Measured stereo `100.0%` <500 Hz (`0.3%` <20 Hz), `0.0%` in 500 Hz to 2 kHz, `0.0%` >2 kHz; mono centroid `748 Hz`, dominant `62.5 Hz`, `-15.8 dB` stereo RMS (`-17.0 dB` mono, peak `-1.3 dBFS`). Death low breakdown (mono): `5.3%` <40 Hz, `89.9%` in 40 to 100 Hz (`95.2%` <100 Hz), `4.1%` in 100 to 250 Hz, `0.6%` in 250 to 500 Hz.
  3. **Mono:** Mild softening; holds up cleanly by ear. `corr +0.57`, fold loss `-1.25 dB` overall (`-1.25 dB` <500 Hz, `-1.85 dB` 500 Hz to 2 kHz, `-1.50 dB` >2 kHz, `-0.46 dB` attack 0 to 60 ms). L/R imbalance `+4.4 dB` (`L -14.1 dB`, `R -18.6 dB`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `11.6 ms`, `T95 = 630 ms`, dur `1.6 s`.
- **`death_bass_drop_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Wide stereo loses `-2.4 dB` overall and `-3.4 dB` on attack in mono, with a softer late peak at `121 ms`.
  2. **Bass (<500 Hz):** Yes (`99.9%` below 500 Hz stereo, `99.8%` mono). Measured stereo `99.9%` <500 Hz (`0.5%` <20 Hz), `0.1%` in 500 Hz to 2 kHz, `0.0%` >2 kHz; mono centroid `1892 Hz`, dominant `58.8 Hz`, `-15.9 dB` stereo RMS (`-18.4 dB` mono, peak `-1.3 dBFS`). Death low breakdown (mono): `5.2%` <40 Hz, `91.8%` in 40 to 100 Hz (`97.0%` <100 Hz), `2.6%` in 100 to 250 Hz, `0.3%` in 250 to 500 Hz.
  3. **Mono:** Yes, loses punch. `corr +0.15`, fold loss `-2.42 dB` overall (`-2.42 dB` <500 Hz, `-0.03 dB` 500 Hz to 2 kHz, `-0.01 dB` >2 kHz, `-3.37 dB` attack 0 to 60 ms). Single channels: L `-16.4 dB` (pk `-1.9 dBFS`, `99.9/0.1/0.0%`), R `-15.5 dB` (pk `-1.3 dBFS`, `99.9/0.1/0.0%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `120.9 ms`, `T95 = 613 ms`, dur `1.6 s`.
- **Final answer (`death_bass_drop`):** **t1**

### 24. `ord_brace_lock` (brace_lock (a ship bracing: bulkheads lock), 1.1 s)

- **Today baseline:** `ord_brace_lock_today0.ogg` (`-24.7 dB`, `0.0/6.2/93.7%`, `T95 177 ms`), `ord_brace_lock_today1.ogg` (`-20.2 dB`, `99.5/0.5/0.0%`, `T95 976 ms`).
- **`ord_brace_lock_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Lopsided stereo loses `-3.7 dB` of midrange and `-5.0 dB` of top end when folded to mono.
  2. **Bass (<500 Hz):** Yes (`79.7%` below 500 Hz stereo, `88.3%` mono). Measured stereo `79.7%` <500 Hz (`0.1%` <20 Hz), `15.3%` in 500 Hz to 2 kHz, `5.0%` >2 kHz; mono centroid `2629 Hz`, dominant `94.4 Hz`, `-18.9 dB` stereo RMS (`-20.6 dB` mono, peak `-1.3 dBFS`).
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.40`, fold loss `-1.66 dB` overall (`-1.22 dB` <500 Hz, `-3.74 dB` 500 Hz to 2 kHz, `-5.02 dB` >2 kHz, `-2.46 dB` attack 0 to 60 ms). L/R imbalance `+3.8 dB` (`L -17.4 dB`, `R -21.3 dB`). Single channels: L `-17.4 dB` (pk `-1.3 dBFS`, `85.0/11.3/3.7%`), R `-21.3 dB` (pk `-1.4 dBFS`, `67.0/24.7/8.3%`).
  4. **Onset (<=30 ms):** Yes, immediate (`5.6 ms` at -40 dB, `7.6 ms` at -30 dB, `18.3 ms` at -20 dB). Peak at `90.8 ms`, `T95 = 307 ms`, dur `1.08 s`.
- **`ord_brace_lock_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Heavy decisive armored bulkhead slams and magnetic anchor clunks with tight onset that stay punchy in mono and crush today's reused `hullHit` and `hullHitBig`.
  2. **Bass (<500 Hz):** Yes (`87.7%` below 500 Hz stereo, `89.2%` mono). Measured stereo `87.7%` <500 Hz (`0.4%` <20 Hz), `9.5%` in 500 Hz to 2 kHz, `2.8%` >2 kHz; mono centroid `2584 Hz`, dominant `74.1 Hz`, `-16.6 dB` stereo RMS (`-17.8 dB` mono, peak `-1.3 dBFS`).
  3. **Mono:** Mild softening; holds up cleanly by ear. `corr +0.52`, fold loss `-1.26 dB` overall (`-1.19 dB` <500 Hz, `-1.97 dB` 500 Hz to 2 kHz, `-1.32 dB` >2 kHz, `-1.21 dB` attack 0 to 60 ms). L/R imbalance `+2.9 dB` (`L -15.4 dB`, `R -18.3 dB`).
  4. **Onset (<=30 ms):** Yes, immediate (`3.4 ms` at -40 dB, `6.8 ms` at -30 dB, `12.7 ms` at -20 dB). Peak at `94.9 ms`, `T95 = 335 ms`, dur `1.08 s`.
- **Final answer (`ord_brace_lock`):** **t2**

### 25. `ord_adapt_shift` (adapt_shift (systems reconfiguring), 1.1 s)

- **Today baseline:** `ord_adapt_shift_today0.ogg` (`-19.6 dB`, `85.3/14.4/0.3%`, `T95 313 ms`), `ord_adapt_shift_today1.ogg` (`-19.6 dB`, `85.3/14.4/0.3%`, `T95 313 ms`).
- **`ord_adapt_shift_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Crisp mechanical relays, turning gears, and pneumatic settle beat today's double `uiSelect`, but wide stereo loses `-3.6 dB` of midrange and `-3.2 dB` of top end in mono; channel L alone is crisp and clean.
  2. **Bass (<500 Hz):** Yes (`54.3%` below 500 Hz stereo, `67.2%` mono). Measured stereo `54.3%` <500 Hz (`0.0%` <20 Hz), `7.4%` in 500 Hz to 2 kHz, `38.3%` >2 kHz; mono centroid `3963 Hz`, dominant `144.4 Hz`, `-19.0 dB` stereo RMS (`-20.8 dB` mono, peak `-1.9 dBFS`).
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.33`, fold loss `-1.79 dB` overall (`-0.86 dB` <500 Hz, `-3.56 dB` 500 Hz to 2 kHz, `-3.16 dB` >2 kHz, `-2.79 dB` attack 0 to 60 ms). Single channels: L `-19.6 dB` (pk `-1.9 dBFS`, `47.5/8.8/43.7%`), R `-18.5 dB` (pk `-1.9 dBFS`, `59.6/6.4/34.1%`).
  4. **Onset (<=30 ms):** Yes, immediate (`4.4 ms` at -40 dB, `8.7 ms` at -30 dB, `13.3 ms` at -20 dB). Peak at `113.3 ms`, `T95 = 426 ms`, dur `1.08 s`.
- **`ord_adapt_shift_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Solid gears and hydraulic piston clunk at `0.0 ms`, but loses `-3.2 dB` of midrange in mono.
  2. **Bass (<500 Hz):** Yes (`78.8%` below 500 Hz stereo, `78.7%` mono). Measured stereo `78.8%` <500 Hz (`0.0%` <20 Hz), `6.0%` in 500 Hz to 2 kHz, `15.2%` >2 kHz; mono centroid `3670 Hz`, dominant `61.1 Hz`, `-17.7 dB` stereo RMS (`-19.1 dB` mono, peak `-1.6 dBFS`).
  3. **Mono:** Yes, loses top end/midrange. `corr +0.45`, fold loss `-1.42 dB` overall (`-1.42 dB` <500 Hz, `-3.25 dB` 500 Hz to 2 kHz, `-0.84 dB` >2 kHz, `-0.75 dB` attack 0 to 60 ms). Single channels: L `-18.2 dB` (pk `-1.7 dBFS`, `75.5/6.7/17.8%`), R `-17.2 dB` (pk `-1.6 dBFS`, `81.5/5.4/13.1%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `2.7 ms` at -20 dB). Peak at `187.1 ms`, `T95 = 472 ms`, dur `1.08 s`.
- **Final answer (`ord_adapt_shift`):** **channel L of t1**

### 26. `ord_board_grapple` (board_grapple base (boarding pod biting a hull), 1.5 s)

- **Today baseline:** `ord_board_grapple_today0.ogg` (`-20.2 dB`, `99.5/0.5/0.0%`, `T95 976 ms`), `ord_board_grapple_today1.ogg` (`-19.0 dB`, `100.0/0.0/0.0%`, `T95 1752 ms`), `ord_board_grapple_today2.ogg` (`-21.6 dB`, `51.4/14.2/34.4%`, `T95 793 ms`).
- **`ord_board_grapple_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Too dark below 500 Hz, burying the cable snap and drill bite under a dull thud.
  2. **Bass (<500 Hz):** Yes (`91.1%` below 500 Hz stereo, `91.2%` mono). Measured stereo `91.1%` <500 Hz (`1.1%` <20 Hz), `4.8%` in 500 Hz to 2 kHz, `4.0%` >2 kHz; mono centroid `2067 Hz`, dominant `64.2 Hz`, `-22.2 dB` stereo RMS (`-22.3 dB` mono, peak `-1.4 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +0.98`, fold loss `-0.05 dB` overall (`-0.05 dB` <500 Hz, `-0.12 dB` 500 Hz to 2 kHz, `-0.04 dB` >2 kHz, `-0.01 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`4.1 ms` at -40 dB, `6.5 ms` at -30 dB, `18.8 ms` at -20 dB). Peak at `23.4 ms`, `T95 = 286 ms`, dur `1.48 s`.
- **`ord_board_grapple_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Unmistakable heavy harpoon thud, taut cable snap, and grinding drill lock in clean mono that replaces today's mismatched `hullHitBig`, `scrape`, and `whoosh`.
  2. **Bass (<500 Hz):** Yes (`77.8%` below 500 Hz stereo, `78.2%` mono). Measured stereo `77.8%` <500 Hz (`4.9%` <20 Hz), `13.3%` in 500 Hz to 2 kHz, `9.0%` >2 kHz; mono centroid `3342 Hz`, dominant `56.8 Hz`, `-20.3 dB` stereo RMS (`-20.7 dB` mono, peak `-1.5 dBFS`).
  3. **Mono:** Holds up cleanly with minor softening. `corr +0.84`, fold loss `-0.37 dB` overall (`-0.35 dB` <500 Hz, `-0.26 dB` 500 Hz to 2 kHz, `-0.75 dB` >2 kHz, `-0.05 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, within 30 ms (`10.3 ms` at -40 dB, `29.7 ms` at -30 dB, `34.5 ms` at -20 dB; trim ~`10 ms` head for tight sync). Peak at `100.0 ms`, `T95 = 374 ms`, dur `1.48 s`.
- **Final answer (`ord_board_grapple`):** **t2**

### 27. `ui_cancel_switch` (ui_cancel, 0.5 s)

- **Today baseline:** `ui_cancel_switch_today0.ogg` (`-23.8 dB`, `76.5/20.1/3.4%`, `T95 310 ms`).
- **`ui_cancel_switch_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Weighty acoustic toggle-off click with a soft damped stop and usable mono lock, needing a `34 ms` head trim.
  2. **Bass (<500 Hz):** No (`0.9%` below 500 Hz stereo, `1.1%` mono). Measured stereo `0.9%` <500 Hz (`0.0%` <20 Hz), `10.9%` in 500 Hz to 2 kHz, `88.2%` >2 kHz; mono centroid `7360 Hz`, dominant `2062.5 Hz`, `-34.2 dB` stereo RMS (`-35.3 dB` mono, peak `-7.0 dBFS`).
  3. **Mono:** Mild softening; holds up cleanly by ear. `corr +0.57`, fold loss `-1.06 dB` overall (`-0.49 dB` <500 Hz, `-0.15 dB` 500 Hz to 2 kHz, `-1.19 dB` >2 kHz, `-0.66 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** No, late start (`34.6 ms` at -40 dB, `52.4 ms` at -30 dB, `69.5 ms` at -20 dB; trim ~`32 ms` dead head in mastering). Peak at `72.9 ms`, `T95 = 234 ms`, dur `0.48 s`.
- **`ui_cancel_switch_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Wide stereo loses `-3.1 dB` of midrange in mono.
  2. **Bass (<500 Hz):** No (`4.4%` below 500 Hz stereo, `6.1%` mono). Measured stereo `4.4%` <500 Hz (`0.0%` <20 Hz), `14.4%` in 500 Hz to 2 kHz, `81.2%` >2 kHz; mono centroid `6886 Hz`, dominant `695.8 Hz`, `-32.2 dB` stereo RMS (`-34.2 dB` mono, peak `-5.6 dBFS`).
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.27`, fold loss `-1.96 dB` overall (`-0.52 dB` <500 Hz, `-3.14 dB` 500 Hz to 2 kHz, `-1.87 dB` >2 kHz, `-1.79 dB` attack 0 to 60 ms). Single channels: L `-32.4 dB` (pk `-7.1 dBFS`, `5.1/18.0/76.9%`), R `-32.0 dB` (pk `-5.6 dBFS`, `3.7/11.2/85.1%`).
  4. **Onset (<=30 ms):** Yes, immediate (`7.8 ms` at -40 dB, `11.6 ms` at -30 dB, `30.4 ms` at -20 dB). Peak at `34.4 ms`, `T95 = 222 ms`, dur `0.48 s`.
- **`ui_cancel_switch_t3.mp3` -> KEEP.**
  1. **Verdict:** Keep: Instant, dry, fully acoustic low console switch click with rock-solid mono lock and zero electronic tone, beating today's `uiDeny` cleanly.
  2. **Bass (<500 Hz):** No (`2.6%` below 500 Hz stereo, `2.5%` mono). Measured stereo `2.6%` <500 Hz (`0.0%` <20 Hz), `11.1%` in 500 Hz to 2 kHz, `86.3%` >2 kHz; mono centroid `7538 Hz`, dominant `629.2 Hz`, `-35.3 dB` stereo RMS (`-35.4 dB` mono, peak `-10.0 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +0.95`, fold loss `-0.11 dB` overall (`-0.30 dB` <500 Hz, `-0.05 dB` 500 Hz to 2 kHz, `-0.12 dB` >2 kHz, `-0.13 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `8.7 ms`, `T95 = 158 ms`, dur `0.48 s`.
- **Final answer (`ui_cancel_switch`):** **t3**

### 28. `ui_select_detent` (ui_select, 0.5 s)

- **Today baseline:** `ui_select_detent_today0.ogg` (`-19.6 dB`, `85.3/14.4/0.3%`, `T95 313 ms`).
- **`ui_select_detent_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Clean single heavy rotary detent snap that sounds fully mechanical and acoustic once the `58 ms` dead head is trimmed.
  2. **Bass (<500 Hz):** No (`2.4%` below 500 Hz stereo, `1.9%` mono). Measured stereo `2.4%` <500 Hz (`0.0%` <20 Hz), `9.3%` in 500 Hz to 2 kHz, `88.3%` >2 kHz; mono centroid `8652 Hz`, dominant `8781.2 Hz`, `-42.5 dB` stereo RMS (`-43.0 dB` mono, peak `-15.0 dBFS`).
  3. **Mono:** Holds up cleanly with minor softening. `corr +0.78`, fold loss `-0.52 dB` overall (`-1.54 dB` <500 Hz, `-0.66 dB` 500 Hz to 2 kHz, `-0.48 dB` >2 kHz, `-0.52 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** No, late start (`59.2 ms` at -40 dB, `66.8 ms` at -30 dB, `77.3 ms` at -20 dB; trim ~`57 ms` dead head in mastering). Peak at `82.9 ms`, `T95 = 252 ms`, dur `0.48 s`.
- **`ui_select_detent_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Even cleaner pure-mono metal detent click once the `132 ms` dead head is trimmed, beating today's dull `uiSelect`.
  2. **Bass (<500 Hz):** No (`3.2%` below 500 Hz stereo, `3.1%` mono). Measured stereo `3.2%` <500 Hz (`0.1%` <20 Hz), `8.7%` in 500 Hz to 2 kHz, `88.2%` >2 kHz; mono centroid `7586 Hz`, dominant `3464.6 Hz`, `-40.0 dB` stereo RMS (`-40.0 dB` mono, peak `-9.8 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +0.98`, fold loss `-0.04 dB` overall (`-0.10 dB` <500 Hz, `-0.02 dB` 500 Hz to 2 kHz, `-0.04 dB` >2 kHz, `+0.00 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** No, late start (`132.4 ms` at -40 dB, `136.9 ms` at -30 dB, `143.4 ms` at -20 dB; trim ~`130 ms` dead head in mastering). Peak at `146.1 ms`, `T95 = 332 ms`, dur `0.48 s`.
- **`ui_select_detent_t3.mp3` -> REJECT.**
  1. **Verdict:** Reject: Has a subtle double-click bounce peaking at `201 ms` instead of one clean detent snap.
  2. **Bass (<500 Hz):** No (`3.3%` below 500 Hz stereo, `3.2%` mono). Measured stereo `3.3%` <500 Hz (`0.1%` <20 Hz), `21.4%` in 500 Hz to 2 kHz, `75.2%` >2 kHz; mono centroid `7096 Hz`, dominant `668.8 Hz`, `-40.5 dB` stereo RMS (`-40.7 dB` mono, peak `-12.4 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +0.94`, fold loss `-0.14 dB` overall (`-0.29 dB` <500 Hz, `-0.14 dB` 500 Hz to 2 kHz, `-0.14 dB` >2 kHz, `-0.18 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`7.0 ms` at -40 dB, `9.5 ms` at -30 dB, `27.3 ms` at -20 dB). Peak at `200.6 ms`, `T95 = 211 ms`, dur `0.48 s`.
- **Final answer (`ui_select_detent`):** **t1 and t2**

### 29. `ui_hover_tick` (new hover cue (orders_kit HOVER_CUE, today ui_click at a low gain), 0.5 s)

- **Today baseline:** `ui_hover_tick_today0.ogg` (`-22.9 dB`, `0.0/97.7/2.3%`, `T95 43 ms`).
- **`ui_hover_tick_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Tiny soft muted acoustic mechanical key tick in clean mono that makes a far gentler hover cue than today's bright `uiClick` once the `90 ms` dead head is trimmed.
  2. **Bass (<500 Hz):** No (`9.5%` below 500 Hz stereo, `10.2%` mono). Measured stereo `9.5%` <500 Hz (`0.0%` <20 Hz), `43.3%` in 500 Hz to 2 kHz, `47.2%` >2 kHz; mono centroid `4897 Hz`, dominant `139.6 Hz`, `-38.3 dB` stereo RMS (`-38.7 dB` mono, peak `-11.6 dBFS`).
  3. **Mono:** Holds up cleanly with minor softening. `corr +0.83`, fold loss `-0.42 dB` overall (`-0.13 dB` <500 Hz, `-0.35 dB` 500 Hz to 2 kHz, `-0.55 dB` >2 kHz, `+0.00 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** No, late start (`91.1 ms` at -40 dB, `96.1 ms` at -30 dB, `109.5 ms` at -20 dB; trim ~`89 ms` dead head in mastering). Peak at `134.2 ms`, `T95 = 227 ms`, dur `0.48 s`.
- **`ui_hover_tick_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Phase-inverted stereo drops `-3.6 dB` overall and `-4.9 dB` of top end in mono.
  2. **Bass (<500 Hz):** No (`10.2%` below 500 Hz stereo, `18.4%` mono). Measured stereo `10.2%` <500 Hz (`0.0%` <20 Hz), `28.8%` in 500 Hz to 2 kHz, `61.0%` >2 kHz; mono centroid `4708 Hz`, dominant `2327.1 Hz`, `-38.4 dB` stereo RMS (`-42.0 dB` mono, peak `-9.4 dBFS`).
  3. **Mono:** Yes, loses top end/midrange and punch. `corr -0.15`, fold loss `-3.58 dB` overall (`-1.02 dB` <500 Hz, `-2.58 dB` 500 Hz to 2 kHz, `-4.87 dB` >2 kHz, `+0.00 dB` attack 0 to 60 ms). L/R imbalance `-5.9 dB` (`L -42.3 dB`, `R -36.4 dB`). Single channels: L `-42.3 dB` (pk `-19.6 dBFS`, `16.4/46.2/37.4%`), R `-36.4 dB` (pk `-9.4 dBFS`, `8.6/24.3/67.1%`).
  4. **Onset (<=30 ms):** No, late start (`111.1 ms` at -40 dB, `114.6 ms` at -30 dB, `123.4 ms` at -20 dB; trim ~`109 ms` dead head in mastering). Peak at `128.4 ms`, `T95 = 240 ms`, dur `0.48 s`.
- **`ui_hover_tick_t3.mp3` -> REJECT.**
  1. **Verdict:** Reject: Phase-inverted stereo drops `-4.9 dB` of midrange in mono and reads like a soft double tick.
  2. **Bass (<500 Hz):** No (`9.1%` below 500 Hz stereo, `18.9%` mono). Measured stereo `9.1%` <500 Hz (`0.0%` <20 Hz), `49.8%` in 500 Hz to 2 kHz, `41.1%` >2 kHz; mono centroid `6653 Hz`, dominant `100.0 Hz`, `-40.6 dB` stereo RMS (`-44.2 dB` mono, peak `-17.7 dBFS`).
  3. **Mono:** Yes, loses top end/midrange and punch. `corr -0.12`, fold loss `-3.59 dB` overall (`-0.40 dB` <500 Hz, `-4.89 dB` 500 Hz to 2 kHz, `-3.28 dB` >2 kHz, `+0.00 dB` attack 0 to 60 ms). Single channels: L `-40.9 dB` (pk `-17.7 dBFS`, `5.8/49.4/44.8%`), R `-40.3 dB` (pk `-18.1 dBFS`, `12.0/50.1/37.9%`).
  4. **Onset (<=30 ms):** No, late start (`77.7 ms` at -40 dB, `95.1 ms` at -30 dB, `98.9 ms` at -20 dB; trim ~`75 ms` dead head in mastering). Peak at `228.9 ms`, `T95 = 239 ms`, dur `0.48 s`.
- **Final answer (`ui_hover_tick`):** **t1**

### 30. `ui_panel_slide` (ui_panel, 0.8 s)

- **Today baseline:** `ui_panel_slide_today0.ogg` (`-26.3 dB`, `14.4/78.1/7.6%`, `T95 106 ms`).
- **`ui_panel_slide_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Smooth acoustic metal rail slide ending in a crisp solid latch with pure mono lock, replacing today's synthy `uiPanel` cleanly after a `95 ms` head trim.
  2. **Bass (<500 Hz):** No (`7.4%` below 500 Hz stereo, `7.4%` mono). Measured stereo `7.4%` <500 Hz (`0.0%` <20 Hz), `21.1%` in 500 Hz to 2 kHz, `71.4%` >2 kHz; mono centroid `4955 Hz`, dominant `2362.5 Hz`, `-29.8 dB` stereo RMS (`-29.8 dB` mono, peak `-4.2 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +0.99`, fold loss `-0.02 dB` overall (`-0.02 dB` <500 Hz, `-0.01 dB` 500 Hz to 2 kHz, `-0.02 dB` >2 kHz, `-0.05 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** No, late start (`95.8 ms` at -40 dB, `245.6 ms` at -30 dB, `265.8 ms` at -20 dB; trim ~`93 ms` dead head in mastering). Peak at `279.5 ms`, `T95 = 315 ms`, dur `0.8 s`.
- **`ui_panel_slide_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Equally clean mechanical panel slide and latch in solid mono after a `115 ms` head trim.
  2. **Bass (<500 Hz):** No (`10.5%` below 500 Hz stereo, `10.2%` mono). Measured stereo `10.5%` <500 Hz (`0.0%` <20 Hz), `13.9%` in 500 Hz to 2 kHz, `75.6%` >2 kHz; mono centroid `5826 Hz`, dominant `137.5 Hz`, `-30.5 dB` stereo RMS (`-30.7 dB` mono, peak `-4.2 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +0.93`, fold loss `-0.15 dB` overall (`-0.30 dB` <500 Hz, `-0.22 dB` 500 Hz to 2 kHz, `-0.11 dB` >2 kHz, `-0.47 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** No, late start (`116.2 ms` at -40 dB, `326.4 ms` at -30 dB, `350.3 ms` at -20 dB; trim ~`114 ms` dead head in mastering). Peak at `358.1 ms`, `T95 = 396 ms`, dur `0.8 s`.
- **Final answer (`ui_panel_slide`):** **t1 and t2**

### 31. `ui_alert_bell` (ui_alert, 1.2 s)

- **Today baseline:** `ui_alert_bell_today0.ogg` (`-21.0 dB`, `87.3/12.3/0.4%`, `T95 2374 ms`).
- **`ui_alert_bell_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Loud and bright with a sharp `4.02 kHz` ringing peak that borders on shrill.
  2. **Bass (<500 Hz):** No (`0.3%` below 500 Hz stereo, `0.3%` mono). Measured stereo `0.3%` <500 Hz (`0.0%` <20 Hz), `8.6%` in 500 Hz to 2 kHz, `91.0%` >2 kHz; mono centroid `5174 Hz`, dominant `4010.0 Hz`, `-15.9 dB` stereo RMS (`-17.0 dB` mono, peak `-0.4 dBFS`).
  3. **Mono:** Mild softening; holds up cleanly by ear. `corr +0.56`, fold loss `-1.08 dB` overall (`-1.43 dB` <500 Hz, `-0.57 dB` 500 Hz to 2 kHz, `-1.13 dB` >2 kHz, `-0.69 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`4.5 ms` at -40 dB, `7.0 ms` at -30 dB, `8.8 ms` at -20 dB). Peak at `290.5 ms`, `T95 = 521 ms`, dur `1.2 s`. Tail tone scan: `4020 Hz` at `-35.9 dBFS` (`+29.5 dB` prominence at `600 ms`).
- **`ui_alert_bell_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Urgent acoustic double-strike mechanical steel bell at `2.17 kHz` that is never shrill, starts at `0.0 ms`, and beats today's reused synth `enemyTurn`.
  2. **Bass (<500 Hz):** No (`2.1%` below 500 Hz stereo, `2.1%` mono). Measured stereo `2.1%` <500 Hz (`0.0%` <20 Hz), `8.0%` in 500 Hz to 2 kHz, `90.0%` >2 kHz; mono centroid `5244 Hz`, dominant `2174.2 Hz`, `-25.2 dB` stereo RMS (`-26.0 dB` mono, peak `-6.9 dBFS`).
  3. **Mono:** Holds up cleanly with minor softening. `corr +0.69`, fold loss `-0.75 dB` overall (`-0.63 dB` <500 Hz, `-0.42 dB` 500 Hz to 2 kHz, `-0.79 dB` >2 kHz, `-0.63 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `326.3 ms`, `T95 = 414 ms`, dur `1.2 s`. Tail tone scan: `3250 Hz` at `-50.6 dBFS` (`+32.4 dB` prominence at `500 ms`).
- **Final answer (`ui_alert_bell`):** **t2**

### 32. `ui_round_bell` (ui_round (a new round starts), 1.4 s)

- **Today baseline:** `ui_round_bell_today0.ogg` (`-26.3 dB`, `76.5/23.4/0.1%`, `T95 484 ms`).
- **`ui_round_bell_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Solemn warm large bronze watch bell sitting cleanly in the midrange (`581 Hz`) with zero harshness and pure mono lock, crushing today's tiny ping `uiRound`.
  2. **Bass (<500 Hz):** No (`2.8%` below 500 Hz stereo, `2.8%` mono). Measured stereo `2.8%` <500 Hz (`0.0%` <20 Hz), `97.1%` in 500 Hz to 2 kHz, `0.0%` >2 kHz; mono centroid `754 Hz`, dominant `580.9 Hz`, `-27.8 dB` stereo RMS (`-27.8 dB` mono, peak `-17.7 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +1.00`, fold loss `-0.01 dB` overall (`-0.02 dB` <500 Hz, `-0.01 dB` 500 Hz to 2 kHz, `-0.29 dB` >2 kHz, `-0.02 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** No, late start (`40.0 ms` at -40 dB, `45.4 ms` at -30 dB, `50.1 ms` at -20 dB; trim ~`38 ms` dead head in mastering). Peak at `136.1 ms`, `T95 = 782 ms`, dur `1.36 s`.
- **`ui_round_bell_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Smaller higher-pitched bell (`1979 Hz`, short decay) that sounds like a desk bell rather than a solemn watch bell.
  2. **Bass (<500 Hz):** No (`0.1%` below 500 Hz stereo, `0.1%` mono). Measured stereo `0.1%` <500 Hz (`0.0%` <20 Hz), `64.0%` in 500 Hz to 2 kHz, `35.9%` >2 kHz; mono centroid `4311 Hz`, dominant `1979.4 Hz`, `-29.7 dB` stereo RMS (`-30.0 dB` mono, peak `-11.4 dBFS`).
  3. **Mono:** Holds up cleanly with minor softening. `corr +0.88`, fold loss `-0.26 dB` overall (`-1.52 dB` <500 Hz, `-0.09 dB` 500 Hz to 2 kHz, `-0.56 dB` >2 kHz, `-0.12 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, within 30 ms (`10.2 ms` at -40 dB, `27.8 ms` at -30 dB, `31.4 ms` at -20 dB; trim ~`10 ms` head for tight sync). Peak at `58.5 ms`, `T95 = 396 ms`, dur `1.36 s`. Tail tone scan: `3510 Hz` at `-41.0 dBFS` (`+28.3 dB` prominence at `150 ms`).
- **Final answer (`ui_round_bell`):** **t1**

### 33. `ui_enemy_turn` (ui_enemy (the enemy's turn), 1.4 s)

- **Today baseline:** `ui_enemy_turn_today0.ogg` (`-21.0 dB`, `87.3/12.3/0.4%`, `T95 2374 ms`).
- **`ui_enemy_turn_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Starts abruptly on a sample-0 transient peak with a 3.8 dB left-right imbalance and feels smaller than `t2`.
  2. **Bass (<500 Hz):** Yes (`98.5%` below 500 Hz stereo, `98.7%` mono). Measured stereo `98.5%` <500 Hz (`0.5%` <20 Hz), `1.5%` in 500 Hz to 2 kHz, `0.1%` >2 kHz; mono centroid `1891 Hz`, dominant `31.6 Hz`, `-21.8 dB` stereo RMS (`-22.5 dB` mono, peak `-6.1 dBFS`).
  3. **Mono:** Holds up cleanly with minor softening. `corr +0.78`, fold loss `-0.69 dB` overall (`-0.68 dB` <500 Hz, `-1.35 dB` 500 Hz to 2 kHz, `-0.66 dB` >2 kHz, `-0.49 dB` attack 0 to 60 ms). L/R imbalance `+3.8 dB` (`L -20.3 dB`, `R -24.1 dB`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `0.0 ms`, `T95 = 400 ms`, dur `1.36 s`.
- **`ui_enemy_turn_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Restrained ominous acoustic war drum and dark low brass stab that fits the enemy turn far better than today's synth pad `enemyTurn`.
  2. **Bass (<500 Hz):** Yes (`98.0%` below 500 Hz stereo, `98.5%` mono). Measured stereo `98.0%` <500 Hz (`0.1%` <20 Hz), `1.9%` in 500 Hz to 2 kHz, `0.1%` >2 kHz; mono centroid `679 Hz`, dominant `44.9 Hz`, `-16.8 dB` stereo RMS (`-18.0 dB` mono, peak `-1.4 dBFS`).
  3. **Mono:** Yes, loses top end/midrange. `corr +0.53`, fold loss `-1.17 dB` overall (`-1.14 dB` <500 Hz, `-2.49 dB` 500 Hz to 2 kHz, `-2.51 dB` >2 kHz, `-0.97 dB` attack 0 to 60 ms). Single channels: L `-16.8 dB` (pk `-1.5 dBFS`, `98.0/1.9/0.1%`), R `-16.9 dB` (pk `-1.4 dBFS`, `98.0/1.9/0.1%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `72.2 ms`, `T95 = 483 ms`, dur `1.36 s`.
- **Final answer (`ui_enemy_turn`):** **t2**

## Group 2: Polish Re-Rolls (4 Wave F IDs, 8 Takes)

### 34. `wep_ithar_pulsar_b` (lance_choir (Glasswright pulsar, re-roll: one even beam), 1.6 s)

- **Today baseline:** `wep_ithar_pulsar_b_today0.ogg` (`-16.5 dB`, `60.3/33.5/6.2%`, `T95 158 ms`), `wep_ithar_pulsar_b_today1.ogg` (`-23.8 dB`, `85.6/14.4/0.1%`, `T95 127 ms`).
- **In-game keeper (`godot/audio/clips/wep_ithar_pulsar_0.ogg`):** `-22.4 dB` RMS, `44.3/13.6/42.1%` (<500 / 500-2k / >2k), centroid `4853 Hz`, `T95 613 ms`, dur `1.564 s`.
- **`wep_ithar_pulsar_b_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Not an even beam: dips `-16.5 dB` at `500 ms` then swells to peak at `1004 ms`, and collapsed to a bare midrange glass bowl with almost zero bright shimmer or low cathedral hum.
  2. **Bass (<500 Hz):** No (`0.1%` below 500 Hz stereo, `0.0%` mono). Measured stereo `0.1%` <500 Hz (`0.0%` <20 Hz), `99.8%` in 500 Hz to 2 kHz, `0.1%` >2 kHz; mono centroid `2869 Hz`, dominant `824.4 Hz`, `-21.6 dB` stereo RMS (`-21.6 dB` mono, peak `-9.6 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +1.00`, fold loss `-0.00 dB` overall (`-0.82 dB` <500 Hz, `-0.00 dB` 500 Hz to 2 kHz, `-0.15 dB` >2 kHz, `-0.00 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `1003.7 ms`, `T95 = 1188 ms`, dur `1.6 s`. Tail tone scan: `3310 Hz` at `-53.4 dBFS` (`+32.1 dB` prominence at `400 ms`).
- **`wep_ithar_pulsar_b_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Pulses three times across 1.6 s (dipping `-11.0 dB` at `300 ms` and `-12.9 dB` at `1000 ms` before peaking at `1272 ms`) and also lost all high shimmer and low body.
  2. **Bass (<500 Hz):** No (`0.1%` below 500 Hz stereo, `0.1%` mono). Measured stereo `0.1%` <500 Hz (`0.0%` <20 Hz), `99.8%` in 500 Hz to 2 kHz, `0.1%` >2 kHz; mono centroid `3065 Hz`, dominant `658.8 Hz`, `-13.4 dB` stereo RMS (`-13.4 dB` mono, peak `-3.4 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +1.00`, fold loss `-0.01 dB` overall (`-0.39 dB` <500 Hz, `-0.01 dB` 500 Hz to 2 kHz, `-0.46 dB` >2 kHz, `-0.01 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, within 30 ms (`17.4 ms` at -40 dB, `23.5 ms` at -30 dB, `37.9 ms` at -20 dB; trim ~`17 ms` head for tight sync). Peak at `1271.6 ms`, `T95 = 1329 ms`, dur `1.6 s`. Tail tone scan: `3950 Hz` at `-53.2 dBFS` (`+24.7 dB` prominence at `700 ms`).
- **Final answer (`wep_ithar_pulsar_b`):** **re-roll: generate with loop enabled and flat-volume wording so it holds one steady level with no swells, and ask for bright high crystal shimmer plus a low cathedral hum alongside the midrange chord.**

### 35. `wep_hullbreaker_rockets_b` (torp_rocket (Hullbreaker rocket, re-roll: ONE launch), 1.4 s)

- **Today baseline:** `wep_hullbreaker_rockets_b_today0.ogg` (`-20.7 dB`, `61.7/33.1/5.1%`, `T95 231 ms`).
- **In-game keeper (`godot/audio/clips/wep_hullbreaker_rockets_0.ogg`):** `-22.5 dB` RMS, `58.2/25.3/16.5%` (<500 / 500-2k / >2k), centroid `3269 Hz`, `T95 367 ms`, dur `1.355 s`.
- **`wep_hullbreaker_rockets_b_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Exactly one scrap rocket launch with a long sputtering motor trail and pure mono lock, though 8 dB quieter than `t2`.
  2. **Bass (<500 Hz):** No (`49.1%` below 500 Hz stereo, `49.2%` mono). Measured stereo `49.1%` <500 Hz (`0.0%` <20 Hz), `28.3%` in 500 Hz to 2 kHz, `22.7%` >2 kHz; mono centroid `3076 Hz`, dominant `105.1 Hz`, `-31.0 dB` stereo RMS (`-31.0 dB` mono, peak `-10.1 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +0.99`, fold loss `-0.02 dB` overall (`-0.01 dB` <500 Hz, `-0.03 dB` 500 Hz to 2 kHz, `-0.04 dB` >2 kHz, `-0.04 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.1 ms` at -20 dB). Peak at `102.1 ms`, `T95 = 1032 ms`, dur `1.36 s`.
- **`wep_hullbreaker_rockets_b_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Exactly one crude heavy rocket launch with a hard ignition bang, rattling rail, and gritty sputtering motor streaking cleanly away in pure mono, decisively fixing the short Gate 2 keeper.
  2. **Bass (<500 Hz):** No (`15.1%` below 500 Hz stereo, `15.1%` mono). Measured stereo `15.1%` <500 Hz (`0.0%` <20 Hz), `38.0%` in 500 Hz to 2 kHz, `46.9%` >2 kHz; mono centroid `3410 Hz`, dominant `124.3 Hz`, `-23.2 dB` stereo RMS (`-23.2 dB` mono, peak `-0.9 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +1.00`, fold loss `-0.01 dB` overall (`-0.01 dB` <500 Hz, `-0.00 dB` 500 Hz to 2 kHz, `-0.01 dB` >2 kHz, `-0.01 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `28.7 ms`, `T95 = 783 ms`, dur `1.36 s`.
- **Final answer (`wep_hullbreaker_rockets_b`):** **t2**

### 36. `ui_boss_arrival_long` (ui_boss (re-roll at 3.5 s: the old take was too short), 3.5 s)

- **Today baseline:** `ui_boss_arrival_long_today0.ogg` (`-30.9 dB`, `98.5/1.5/0.1%`, `T95 398 ms`).
- **In-game keeper (`godot/audio/clips/ui_boss_arrival_0.ogg`):** `-30.9 dB` RMS, `98.5/1.5/0.1%` (<500 / 500-2k / >2k), centroid `614 Hz`, `T95 398 ms`, dur `2.195 s`.
- **`ui_boss_arrival_long_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Barely longer than the old 2.2 s keeper (`T95 458 ms` vs `398 ms`), dropping below `-30 dB` by 1.2 s so the last two seconds are nearly silent.
  2. **Bass (<500 Hz):** Yes (`98.1%` below 500 Hz stereo, `98.0%` mono). Measured stereo `98.1%` <500 Hz (`0.8%` <20 Hz), `1.8%` in 500 Hz to 2 kHz, `0.2%` >2 kHz; mono centroid `861 Hz`, dominant `67.0 Hz`, `-22.7 dB` stereo RMS (`-23.2 dB` mono, peak `-1.3 dBFS`).
  3. **Mono:** Holds up cleanly with minor softening. `corr +0.78`, fold loss `-0.51 dB` overall (`-0.51 dB` <500 Hz, `-0.43 dB` 500 Hz to 2 kHz, `-0.30 dB` >2 kHz, `-0.01 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`8.7 ms` at -40 dB, `9.5 ms` at -30 dB, `25.7 ms` at -20 dB). Peak at `27.1 ms`, `T95 = 458 ms`, dur `3.48 s`.
- **`ui_boss_arrival_long_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Noticeably fuller and 9.5 dB hotter than the old keeper with a menacing bass drum hit and dark held brass shudder audible past 2.5 s in solid mono, though the quiet tail still fades well before 3.5 s.
  2. **Bass (<500 Hz):** Yes (`97.8%` below 500 Hz stereo, `98.0%` mono). Measured stereo `97.8%` <500 Hz (`0.1%` <20 Hz), `2.2%` in 500 Hz to 2 kHz, `0.0%` >2 kHz; mono centroid `649 Hz`, dominant `63.2 Hz`, `-21.4 dB` stereo RMS (`-21.6 dB` mono, peak `-1.3 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +0.89`, fold loss `-0.30 dB` overall (`-0.29 dB` <500 Hz, `-0.77 dB` 500 Hz to 2 kHz, `-0.96 dB` >2 kHz, `-0.04 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`8.0 ms` at -40 dB, `26.8 ms` at -30 dB, `27.4 ms` at -20 dB). Peak at `68.0 ms`, `T95 = 554 ms`, dur `3.48 s`.
- **Final answer (`ui_boss_arrival_long`):** **t2**

### 37. `dmg_engine_fail_long` (dmg_engine_fail (re-roll at 1.5 s: the old take was too short), 1.5 s)

- **Today baseline:** `dmg_engine_fail_long_today0.ogg` (`-19.3 dB`, `42.3/38.4/19.3%`, `T95 707 ms`).
- **In-game keeper (`godot/audio/clips/dmg_engine_fail_0.ogg`):** `-19.3 dB` RMS, `42.3/38.4/19.3%` (<500 / 500-2k / >2k), centroid `3232 Hz`, `T95 707 ms`, dur `0.874 s`.
- **`dmg_engine_fail_long_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Long enough at 1.5 s (`T95 994 ms`) with clear misfires and turbine whine, but wide stereo drops `-2.8` to `-3.0 dB` of mids and highs in mono; channel R alone is clean.
  2. **Bass (<500 Hz):** No (`44.9%` below 500 Hz stereo, `52.4%` mono). Measured stereo `44.9%` <500 Hz (`0.2%` <20 Hz), `25.0%` in 500 Hz to 2 kHz, `30.1%` >2 kHz; mono centroid `4266 Hz`, dominant `66.9 Hz`, `-15.6 dB` stereo RMS (`-17.9 dB` mono, peak `-1.2 dBFS`).
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.18`, fold loss `-2.30 dB` overall (`-1.63 dB` <500 Hz, `-2.82 dB` 500 Hz to 2 kHz, `-3.03 dB` >2 kHz, `-1.99 dB` attack 0 to 60 ms). Single channels: L `-15.9 dB` (pk `-1.3 dBFS`, `52.5/22.0/25.5%`), R `-15.2 dB` (pk `-1.2 dBFS`, `38.4/27.5/34.0%`).
  4. **Onset (<=30 ms):** Yes, within 30 ms (`11.4 ms` at -40 dB, `28.3 ms` at -30 dB, `30.2 ms` at -20 dB; trim ~`11 ms` head for tight sync). Peak at `612.0 ms`, `T95 = 994 ms`, dur `1.48 s`.
- **`dmg_engine_fail_long_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Full 1.5 s sputtering propulsion failure (`T95 1115 ms`, closest timbre to the old 0.87 s keeper), but out-of-phase stereo loses `-4.8 dB` of midrange turbine whine in mono; channel R alone preserves the full wind-down.
  2. **Bass (<500 Hz):** Yes (`56.1%` below 500 Hz stereo, `68.0%` mono). Measured stereo `56.1%` <500 Hz (`0.1%` <20 Hz), `23.5%` in 500 Hz to 2 kHz, `20.4%` >2 kHz; mono centroid `3286 Hz`, dominant `34.5 Hz`, `-16.0 dB` stereo RMS (`-19.1 dB` mono, peak `-0.9 dBFS`).
  3. **Mono:** Yes, loses top end/midrange and punch. `corr -0.03`, fold loss `-3.16 dB` overall (`-2.33 dB` <500 Hz, `-4.82 dB` 500 Hz to 2 kHz, `-4.24 dB` >2 kHz, `-4.03 dB` attack 0 to 60 ms). Single channels: L `-16.4 dB` (pk `-0.9 dBFS`, `69.4/19.3/11.3%`), R `-15.6 dB` (pk `-1.7 dBFS`, `45.2/26.8/27.9%`).
  4. **Onset (<=30 ms):** Yes, immediate (`6.1 ms` at -40 dB, `9.4 ms` at -30 dB, `20.8 ms` at -20 dB). Peak at `135.2 ms`, `T95 = 1115 ms`, dur `1.48 s`.
- **Final answer (`dmg_engine_fail_long`):** **channel R of t2**

## Group 3: New Moments (16 Wave F IDs, 30 Takes)

### 38. `evt_ram_impact` (new: Hullbreaker ram (RAM_FAC) hull-on-hull collision, 1.6 s)

- **Today baseline:** `evt_ram_impact_today0.ogg` (`-22.0 dB`, `83.2/8.0/8.8%`, `T95 430 ms`), `evt_ram_impact_today1.ogg` (`-16.9 dB`, `91.7/6.6/1.7%`, `T95 482 ms`).
- **`evt_ram_impact_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Players know at once two armored ships collided: crushing steel prow impact, shrieking buckling plates, and heavy frame crunch in pure mono.
  2. **Bass (<500 Hz):** Yes (`80.9%` below 500 Hz stereo, `81.1%` mono). Measured stereo `80.9%` <500 Hz (`1.5%` <20 Hz), `8.8%` in 500 Hz to 2 kHz, `10.3%` >2 kHz; mono centroid `4088 Hz`, dominant `49.4 Hz`, `-16.4 dB` stereo RMS (`-16.4 dB` mono, peak `-1.8 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +0.99`, fold loss `-0.01 dB` overall (`-0.00 dB` <500 Hz, `-0.01 dB` 500 Hz to 2 kHz, `-0.09 dB` >2 kHz, `-0.01 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `606.1 ms`, `T95 = 1118 ms`, dur `1.6 s`.
- **`evt_ram_impact_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Very dark (`94.4%` below 500 Hz, `0.5%` above 2 kHz) so it reads more like a dull heavy blast than hull-on-hull ramming.
  2. **Bass (<500 Hz):** Yes (`94.4%` below 500 Hz stereo, `94.4%` mono). Measured stereo `94.4%` <500 Hz (`3.2%` <20 Hz), `5.1%` in 500 Hz to 2 kHz, `0.5%` >2 kHz; mono centroid `1370 Hz`, dominant `337.5 Hz`, `-14.6 dB` stereo RMS (`-14.6 dB` mono, peak `-1.6 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +1.00`, fold loss `-0.00 dB` overall (`-0.00 dB` <500 Hz, `-0.01 dB` 500 Hz to 2 kHz, `-0.02 dB` >2 kHz, `-0.00 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.1 ms` at -30 dB, `0.2 ms` at -20 dB). Peak at `421.1 ms`, `T95 = 838 ms`, dur `1.6 s`.
- **Final answer (`evt_ram_impact`):** **t1**

### 39. `evt_torp_intercept` (new: point defense shooting down a torpedo, 0.8 s)

- **Today baseline:** `evt_torp_intercept_today0.ogg` (`-22.0 dB`, `83.2/8.0/8.8%`, `T95 430 ms`).
- **`evt_torp_intercept_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Quiet, muffled below 500 Hz, and wide stereo; players would not read it as point-defense shooting down a torpedo.
  2. **Bass (<500 Hz):** Yes (`94.1%` below 500 Hz stereo, `95.5%` mono). Measured stereo `94.1%` <500 Hz (`0.0%` <20 Hz), `4.8%` in 500 Hz to 2 kHz, `1.1%` >2 kHz; mono centroid `2173 Hz`, dominant `422.5 Hz`, `-31.6 dB` stereo RMS (`-34.1 dB` mono, peak `-9.5 dBFS`).
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.14`, fold loss `-2.49 dB` overall (`-2.43 dB` <500 Hz, `-3.82 dB` 500 Hz to 2 kHz, `-2.92 dB` >2 kHz, `-2.72 dB` attack 0 to 60 ms). L/R imbalance `-3.4 dB` (`L -33.7 dB`, `R -30.2 dB`). Single channels: L `-33.7 dB` (pk `-10.6 dBFS`, `93.7/4.8/1.5%`), R `-30.2 dB` (pk `-9.5 dBFS`, `94.3/4.8/0.9%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `31.3 ms`, `T95 = 276 ms`, dur `0.8 s`.
- **`evt_torp_intercept_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Crisp point-defense rattle into a sharp warhead blast in pure mono, but the file chops off abruptly right at its peak on the final sample (`800.0 ms`, `end -0.4 dB`).
  2. **Bass (<500 Hz):** Yes (`63.4%` below 500 Hz stereo, `64.0%` mono). Measured stereo `63.4%` <500 Hz (`1.3%` <20 Hz), `22.1%` in 500 Hz to 2 kHz, `14.4%` >2 kHz; mono centroid `3728 Hz`, dominant `465.0 Hz`, `-13.6 dB` stereo RMS (`-13.7 dB` mono, peak `-0.8 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +0.98`, fold loss `-0.05 dB` overall (`-0.01 dB` <500 Hz, `-0.02 dB` 500 Hz to 2 kHz, `-0.28 dB` >2 kHz, `-0.02 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `800.0 ms`, `T95 = 739 ms`, dur `0.8 s`. Warning: abrupt end cut (`last 20 ms` is `-0.4 dB` rel RMS).
- **Final answer (`evt_torp_intercept`):** **re-roll: lengthen to 1.1 s with the same prompt so the warhead detonation decays cleanly instead of cutting off at its peak at 800 ms.**

### 40. `shd_raise` (new: a ship's shield coming back online, 1.2 s)

- **Today baseline:** `shd_raise_today0.ogg` (`-23.0 dB`, `90.1/9.8/0.1%`, `T95 350 ms`).
- **`shd_raise_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Reads as a shield powering up, but sits `97.5%` below 500 Hz with a 3.7 dB left-right tilt and wide stereo that drops `-3.3` to `-4.0 dB` of upper glow in mono.
  2. **Bass (<500 Hz):** Yes (`97.5%` below 500 Hz stereo, `98.3%` mono). Measured stereo `97.5%` <500 Hz (`0.0%` <20 Hz), `0.8%` in 500 Hz to 2 kHz, `1.7%` >2 kHz; mono centroid `3533 Hz`, dominant `50.8 Hz`, `-13.6 dB` stereo RMS (`-15.7 dB` mono, peak `-0.8 dBFS`).
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.26`, fold loss `-2.09 dB` overall (`-2.06 dB` <500 Hz, `-3.29 dB` 500 Hz to 2 kHz, `-4.04 dB` >2 kHz, `-1.58 dB` attack 0 to 60 ms). L/R imbalance `-3.7 dB` (`L -15.8 dB`, `R -12.1 dB`). Single channels: L `-15.8 dB` (pk `-1.9 dBFS`, `96.0/1.4/2.6%`), R `-12.1 dB` (pk `-0.8 dBFS`, `98.2/0.5/1.3%`).
  4. **Onset (<=30 ms):** No, late start (`41.7 ms` at -40 dB, `48.4 ms` at -30 dB, `69.3 ms` at -20 dB; trim ~`39 ms` dead head in mastering). Peak at `660.3 ms`, `T95 = 814 ms`, dur `1.2 s`.
- **`shd_raise_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Clear smooth rising shield hum that players recognize at once, but loses `-2.9` to `-3.0 dB` of upper glow and `-5.0 dB` on attack in mono fold; channel L alone avoids cancellation cleanly.
  2. **Bass (<500 Hz):** Yes (`94.7%` below 500 Hz stereo, `96.4%` mono). Measured stereo `94.7%` <500 Hz (`0.0%` <20 Hz), `2.7%` in 500 Hz to 2 kHz, `2.6%` >2 kHz; mono centroid `3912 Hz`, dominant `48.3 Hz`, `-15.2 dB` stereo RMS (`-16.4 dB` mono, peak `-1.0 dBFS`).
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.52`, fold loss `-1.25 dB` overall (`-1.17 dB` <500 Hz, `-2.94 dB` 500 Hz to 2 kHz, `-2.98 dB` >2 kHz, `-4.97 dB` attack 0 to 60 ms). L/R imbalance `-2.5 dB` (`L -16.7 dB`, `R -14.1 dB`). Single channels: L `-16.7 dB` (pk `-3.2 dBFS`, `93.6/3.2/3.2%`), R `-14.1 dB` (pk `-1.0 dBFS`, `95.3/2.4/2.3%`).
  4. **Onset (<=30 ms):** No, late start (`32.1 ms` at -40 dB, `42.9 ms` at -30 dB, `76.9 ms` at -20 dB; trim ~`30 ms` dead head in mastering). Peak at `427.8 ms`, `T95 = 855 ms`, dur `1.2 s`.
- **Final answer (`shd_raise`):** **channel L of t2**

### 41. `evt_gravity_well` (new: gravity well terrain bed (WELL_PULL), loops, 8.0 s)

- **Today baseline:** none (new moment).
- **`evt_gravity_well_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Immediately reads as an ominous gravity well with a slow pulsing hum and faint metal strain, and loops with zero audible seam.
  2. **Bass (<500 Hz):** Yes (`93.6%` below 500 Hz stereo, `93.4%` mono). Measured stereo `93.6%` <500 Hz (`0.4%` <20 Hz), `6.4%` in 500 Hz to 2 kHz, `0.0%` >2 kHz; mono centroid `582 Hz`, dominant `54.5 Hz`, `-33.8 dB` stereo RMS (`-33.9 dB` mono, peak `-20.4 dBFS`). Loop seam: `+0.25 dB` end-to-start, spectral cosine `0.994`, 0.5 s spread `7.44 dB`, boundary jump `0.0035`.
  3. **Mono:** No loss; rock-solid mono. `corr +0.93`, fold loss `-0.15 dB` overall (`-0.16 dB` <500 Hz, `-0.03 dB` 500 Hz to 2 kHz, `-0.04 dB` >2 kHz, `-0.10 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `251.7 ms`, `T95 = 7792 ms`, dur `8.0 s`.
- **Final answer (`evt_gravity_well`):** **t1**

### 42. `evt_nebula_bed` (new: nebula or ion cloud terrain bed, loops, 8.0 s)

- **Today baseline:** none (new moment).
- **`evt_nebula_bed_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Calm airy rushing wash with soft sparse static crackle that clearly reads as a charged nebula and loops seamlessly with no audible seam, though raw level is very quiet (`-49.4 dB`).
  2. **Bass (<500 Hz):** No (`38.4%` below 500 Hz stereo, `39.0%` mono). Measured stereo `38.4%` <500 Hz (`1.6%` <20 Hz), `46.8%` in 500 Hz to 2 kHz, `14.8%` >2 kHz; mono centroid `2504 Hz`, dominant `200.0 Hz`, `-49.4 dB` stereo RMS (`-51.7 dB` mono, peak `-35.7 dBFS`). Loop seam: `-0.14 dB` end-to-start, spectral cosine `0.979`, 0.5 s spread `1.03 dB`, boundary jump `0.0`.
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.18`, fold loss `-2.27 dB` overall (`-2.21 dB` <500 Hz, `-2.22 dB` 500 Hz to 2 kHz, `-2.61 dB` >2 kHz, `-2.04 dB` attack 0 to 60 ms). Single channels: L `-49.6 dB` (pk `-36.3 dBFS`, `38.4/46.8/14.8%`), R `-49.3 dB` (pk `-35.7 dBFS`, `38.5/46.8/14.7%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `6679.2 ms`, `T95 = 7593 ms`, dur `8.0 s`.
- **Final answer (`evt_nebula_bed`):** **t1**

### 43. `evt_asteroid_scrape` (new: a ship grazing asteroid rock, 1.4 s)

- **Today baseline:** none (new moment).
- **`evt_asteroid_scrape_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Unmistakable heavy grinding rock-against-steel scrape with loose stone knocks in pure mono and instant onset.
  2. **Bass (<500 Hz):** Yes (`55.7%` below 500 Hz stereo, `56.5%` mono). Measured stereo `55.7%` <500 Hz (`0.4%` <20 Hz), `22.6%` in 500 Hz to 2 kHz, `21.8%` >2 kHz; mono centroid `3422 Hz`, dominant `120.6 Hz`, `-19.9 dB` stereo RMS (`-20.0 dB` mono, peak `-2.0 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +0.97`, fold loss `-0.07 dB` overall (`-0.01 dB` <500 Hz, `-0.04 dB` 500 Hz to 2 kHz, `-0.27 dB` >2 kHz, `-0.06 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.2 ms` at -20 dB). Peak at `853.6 ms`, `T95 = 920 ms`, dur `1.36 s`.
- **`evt_asteroid_scrape_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Crisp midrange stone-on-hull scrape and knocks in clean mono, pairing nicely with `t1`.
  2. **Bass (<500 Hz):** No (`33.0%` below 500 Hz stereo, `31.3%` mono). Measured stereo `33.0%` <500 Hz (`0.2%` <20 Hz), `53.4%` in 500 Hz to 2 kHz, `13.6%` >2 kHz; mono centroid `2380 Hz`, dominant `58.8 Hz`, `-21.5 dB` stereo RMS (`-22.1 dB` mono, peak `-1.2 dBFS`).
  3. **Mono:** Holds up cleanly with minor softening. `corr +0.73`, fold loss `-0.62 dB` overall (`-0.85 dB` <500 Hz, `-0.51 dB` 500 Hz to 2 kHz, `-0.54 dB` >2 kHz, `-0.86 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.2 ms` at -20 dB). Peak at `389.7 ms`, `T95 = 876 ms`, dur `1.36 s`.
- **Final answer (`evt_asteroid_scrape`):** **t1 and t2**

### 44. `evt_hull_alarm` (new: the player's flagship at low hull, 1.6 s)

- **Today baseline:** `evt_hull_alarm_today0.ogg` (`-21.0 dB`, `87.3/12.3/0.4%`, `T95 2374 ms`).
- **`evt_hull_alarm_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Unmistakable urgent two-tone electromechanical starship damage klaxon right in the midrange (`580 Hz`, zero harsh >2 kHz) that clearly says space warship danger.
  2. **Bass (<500 Hz):** No (`0.2%` below 500 Hz stereo, `0.2%` mono). Measured stereo `0.2%` <500 Hz (`0.0%` <20 Hz), `99.5%` in 500 Hz to 2 kHz, `0.3%` >2 kHz; mono centroid `2491 Hz`, dominant `580.0 Hz`, `-12.7 dB` stereo RMS (`-12.7 dB` mono, peak `-1.9 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +1.00`, fold loss `-0.01 dB` overall (`-0.34 dB` <500 Hz, `-0.00 dB` 500 Hz to 2 kHz, `-0.21 dB` >2 kHz, `-0.00 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`5.2 ms` at -40 dB, `10.0 ms` at -30 dB, `17.0 ms` at -20 dB). Peak at `722.5 ms`, `T95 = 956 ms`, dur `1.6 s`.
- **`evt_hull_alarm_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Low `192.5 Hz` horn sounds like a naval tugboat foghorn, breaking Ryan's space-never-sea rule.
  2. **Bass (<500 Hz):** Yes (`65.0%` below 500 Hz stereo, `65.0%` mono). Measured stereo `65.0%` <500 Hz (`0.0%` <20 Hz), `34.6%` in 500 Hz to 2 kHz, `0.4%` >2 kHz; mono centroid `1301 Hz`, dominant `192.5 Hz`, `-14.0 dB` stereo RMS (`-14.0 dB` mono, peak `-1.3 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +1.00`, fold loss `-0.00 dB` overall (`-0.00 dB` <500 Hz, `-0.00 dB` 500 Hz to 2 kHz, `-0.05 dB` >2 kHz, `-0.00 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** No, late start (`31.0 ms` at -40 dB, `33.2 ms` at -30 dB, `37.7 ms` at -20 dB; trim ~`29 ms` dead head in mastering). Peak at `647.7 ms`, `T95 = 972 ms`, dur `1.6 s`.
- **Final answer (`evt_hull_alarm`):** **t1**

### 45. `ui_command_issue` (new: a fleet command or ability order issued (COMMANDS), 1.2 s)

- **Today baseline:** `ui_command_issue_today0.ogg` (`-30.0 dB`, `1.5/12.0/86.5%`, `T95 190 ms`).
- **`ui_command_issue_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Heavy decisive mechanical bridge lever thrown home with a solid acoustic latch, though the prompted low brass call is barely present.
  2. **Bass (<500 Hz):** Yes (`55.7%` below 500 Hz stereo, `59.9%` mono). Measured stereo `55.7%` <500 Hz (`1.3%` <20 Hz), `18.3%` in 500 Hz to 2 kHz, `26.0%` >2 kHz; mono centroid `4090 Hz`, dominant `165.8 Hz`, `-21.6 dB` stereo RMS (`-22.0 dB` mono, peak `-1.1 dBFS`).
  3. **Mono:** Holds up cleanly with minor softening. `corr +0.81`, fold loss `-0.43 dB` overall (`-0.11 dB` <500 Hz, `-0.73 dB` 500 Hz to 2 kHz, `-0.96 dB` >2 kHz, `-0.49 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, within 30 ms (`25.9 ms` at -40 dB, `30.2 ms` at -30 dB, `38.5 ms` at -20 dB; trim ~`25 ms` head for tight sync). Peak at `69.3 ms`, `T95 = 314 ms`, dur `1.2 s`.
- **`ui_command_issue_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Tighter, faster pure-mono mechanical lever slam that feels unmistakably like issuing a firm bridge command.
  2. **Bass (<500 Hz):** Yes (`60.0%` below 500 Hz stereo, `61.2%` mono). Measured stereo `60.0%` <500 Hz (`4.7%` <20 Hz), `16.4%` in 500 Hz to 2 kHz, `23.6%` >2 kHz; mono centroid `4140 Hz`, dominant `113.3 Hz`, `-26.0 dB` stereo RMS (`-26.1 dB` mono, peak `-5.1 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +0.94`, fold loss `-0.12 dB` overall (`-0.04 dB` <500 Hz, `-0.06 dB` 500 Hz to 2 kHz, `-0.40 dB` >2 kHz, `-0.29 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`6.4 ms` at -40 dB, `8.6 ms` at -30 dB, `20.8 ms` at -20 dB). Peak at `52.1 ms`, `T95 = 295 ms`, dur `1.2 s`.
- **Final answer (`ui_command_issue`):** **t1 and t2**

### 46. `map_fleet_jump` (new: campaign map, the fleet jumps to a stop, 2.0 s)

- **Today baseline:** `map_fleet_jump_today0.ogg` (`-22.3 dB`, `91.6/8.4/0.0%`, `T95 732 ms`).
- **`map_fleet_jump_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Clearly reads as a fleet surging into hyperspace with a swelling engine pull and deep clean launch thump, though wide stereo loses `-2.7` to `-2.8 dB` of upper detail if folded to mono.
  2. **Bass (<500 Hz):** Yes (`91.1%` below 500 Hz stereo, `93.4%` mono). Measured stereo `91.1%` <500 Hz (`2.7%` <20 Hz), `3.4%` in 500 Hz to 2 kHz, `5.5%` >2 kHz; mono centroid `4302 Hz`, dominant `77.0 Hz`, `-19.4 dB` stereo RMS (`-20.8 dB` mono, peak `-0.9 dBFS`).
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.45`, fold loss `-1.41 dB` overall (`-1.30 dB` <500 Hz, `-2.68 dB` 500 Hz to 2 kHz, `-2.76 dB` >2 kHz, `-4.44 dB` attack 0 to 60 ms). Single channels: L `-19.3 dB` (pk `-0.9 dBFS`, `91.8/3.3/4.9%`), R `-19.5 dB` (pk `-1.7 dBFS`, `90.4/3.5/6.1%`).
  4. **Onset (<=30 ms):** No, late start (`49.1 ms` at -40 dB, `71.9 ms` at -30 dB, `97.3 ms` at -20 dB; trim ~`47 ms` dead head in mastering). Peak at `246.0 ms`, `T95 = 604 ms`, dur `2.0 s`.
- **`map_fleet_jump_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Wider stereo, `16.6%` sub-20 Hz rumble, and a weaker launch thump than `t1`.
  2. **Bass (<500 Hz):** Yes (`84.4%` below 500 Hz stereo, `86.2%` mono). Measured stereo `84.4%` <500 Hz (`16.6%` <20 Hz), `5.2%` in 500 Hz to 2 kHz, `10.4%` >2 kHz; mono centroid `4541 Hz`, dominant `3.5 Hz`, `-21.0 dB` stereo RMS (`-23.1 dB` mono, peak `-1.6 dBFS`).
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.24`, fold loss `-2.07 dB` overall (`-1.98 dB` <500 Hz, `-2.74 dB` 500 Hz to 2 kHz, `-2.54 dB` >2 kHz, `-1.58 dB` attack 0 to 60 ms). Single channels: L `-20.9 dB` (pk `-3.0 dBFS`, `85.6/4.9/9.5%`), R `-21.1 dB` (pk `-1.6 dBFS`, `83.1/5.6/11.3%`).
  4. **Onset (<=30 ms):** No, late start (`52.3 ms` at -40 dB, `81.8 ms` at -30 dB, `110.3 ms` at -20 dB; trim ~`50 ms` dead head in mastering). Peak at `328.5 ms`, `T95 = 554 ms`, dur `2.0 s`.
- **Final answer (`map_fleet_jump`):** **t1**

### 47. `map_fleet_arrive` (new: campaign map, the fleet arrives at a stop, 1.6 s)

- **Today baseline:** `map_fleet_arrive_today0.ogg` (`-22.3 dB`, `91.6/8.4/0.0%`, `T95 732 ms`).
- **`map_fleet_arrive_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Deep rushing hyperspace arrival boom settling into a calm engine thrum with rock-solid mono lock; players know at once the fleet arrived after trimming the `65 ms` dead head.
  2. **Bass (<500 Hz):** Yes (`87.3%` below 500 Hz stereo, `88.0%` mono). Measured stereo `87.3%` <500 Hz (`5.9%` <20 Hz), `5.4%` in 500 Hz to 2 kHz, `7.2%` >2 kHz; mono centroid `4422 Hz`, dominant `46.2 Hz`, `-19.0 dB` stereo RMS (`-19.1 dB` mono, peak `-1.3 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +0.95`, fold loss `-0.12 dB` overall (`-0.09 dB` <500 Hz, `-0.41 dB` 500 Hz to 2 kHz, `-0.30 dB` >2 kHz, `-0.04 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** No, late start (`70.5 ms` at -40 dB, `76.8 ms` at -30 dB, `80.5 ms` at -20 dB; trim ~`68 ms` dead head in mastering). Peak at `203.2 ms`, `T95 = 439 ms`, dur `1.6 s`.
- **`map_fleet_arrive_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Punchier arrival with a shorter lead-in, though wider stereo softens `-1.4 dB` in mono compared with `t1`.
  2. **Bass (<500 Hz):** Yes (`86.9%` below 500 Hz stereo, `86.7%` mono). Measured stereo `86.9%` <500 Hz (`2.8%` <20 Hz), `4.9%` in 500 Hz to 2 kHz, `8.1%` >2 kHz; mono centroid `4383 Hz`, dominant `50.6 Hz`, `-17.9 dB` stereo RMS (`-19.3 dB` mono, peak `-1.1 dBFS`).
  3. **Mono:** Mild softening; holds up cleanly by ear. `corr +0.44`, fold loss `-1.43 dB` overall (`-1.43 dB` <500 Hz, `-0.88 dB` 500 Hz to 2 kHz, `-1.64 dB` >2 kHz, `-2.14 dB` attack 0 to 60 ms). Single channels: L `-18.0 dB` (pk `-2.1 dBFS`, `84.2/7.5/8.3%`), R `-17.7 dB` (pk `-1.1 dBFS`, `89.5/2.5/8.0%`).
  4. **Onset (<=30 ms):** No, late start (`33.1 ms` at -40 dB, `46.9 ms` at -30 dB, `55.7 ms` at -20 dB; trim ~`31 ms` dead head in mastering). Peak at `178.1 ms`, `T95 = 406 ms`, dur `1.6 s`.
- **Final answer (`map_fleet_arrive`):** **t1**

### 48. `ui_purchase` (new: shipyard or shop purchase, 1.0 s)

- **Today baseline:** `ui_purchase_today0.ogg` (`-30.0 dB`, `1.5/12.0/86.5%`, `T95 190 ms`).
- **`ui_purchase_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Solid acoustic supply-crate unlatch and metal clunk in pure mono with zero electronic tone, clearly reading as a shipyard transaction.
  2. **Bass (<500 Hz):** Yes (`66.3%` below 500 Hz stereo, `66.3%` mono). Measured stereo `66.3%` <500 Hz (`0.0%` <20 Hz), `30.0%` in 500 Hz to 2 kHz, `3.7%` >2 kHz; mono centroid `2360 Hz`, dominant `139.0 Hz`, `-20.2 dB` stereo RMS (`-20.2 dB` mono, peak `-1.3 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +1.00`, fold loss `-0.00 dB` overall (`-0.00 dB` <500 Hz, `-0.00 dB` 500 Hz to 2 kHz, `-0.03 dB` >2 kHz, `-0.00 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `8.9 ms` at -30 dB, `23.3 ms` at -20 dB). Peak at `130.1 ms`, `T95 = 234 ms`, dur `1.0 s`.
- **`ui_purchase_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Weightier, fuller crate unlatch and heavy ingots set down in pure mono, pairing cleanly with `t1`.
  2. **Bass (<500 Hz):** Yes (`75.2%` below 500 Hz stereo, `75.3%` mono). Measured stereo `75.2%` <500 Hz (`0.9%` <20 Hz), `20.6%` in 500 Hz to 2 kHz, `4.2%` >2 kHz; mono centroid `2661 Hz`, dominant `58.0 Hz`, `-17.6 dB` stereo RMS (`-17.6 dB` mono, peak `-1.2 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +1.00`, fold loss `-0.01 dB` overall (`-0.00 dB` <500 Hz, `-0.01 dB` 500 Hz to 2 kHz, `-0.06 dB` >2 kHz, `-0.02 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`8.4 ms` at -40 dB, `19.7 ms` at -30 dB, `28.7 ms` at -20 dB). Peak at `139.8 ms`, `T95 = 260 ms`, dur `1.0 s`.
- **Final answer (`ui_purchase`):** **t1 and t2**

### 49. `ui_module_install` (new: a module or refit fitted to a ship, 1.2 s)

- **Today baseline:** `ui_module_install_today0.ogg` (`-30.0 dB`, `1.5/12.0/86.5%`, `T95 190 ms`).
- **`ui_module_install_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Smooth acoustic hydraulic slide into a firm mechanical clamp and driven bolts; players know at once a ship module locked into its bay.
  2. **Bass (<500 Hz):** No (`20.9%` below 500 Hz stereo, `25.0%` mono). Measured stereo `20.9%` <500 Hz (`3.1%` <20 Hz), `3.4%` in 500 Hz to 2 kHz, `75.7%` >2 kHz; mono centroid `5308 Hz`, dominant `0.8 Hz`, `-19.4 dB` stereo RMS (`-20.9 dB` mono, peak `-1.8 dBFS`).
  3. **Mono:** Mild softening; holds up cleanly by ear. `corr +0.43`, fold loss `-1.46 dB` overall (`-0.66 dB` <500 Hz, `-1.32 dB` 500 Hz to 2 kHz, `-1.69 dB` >2 kHz, `-0.91 dB` attack 0 to 60 ms). Single channels: L `-19.7 dB` (pk `-1.8 dBFS`, `19.3/3.3/77.4%`), R `-19.2 dB` (pk `-1.9 dBFS`, `22.3/3.5/74.2%`).
  4. **Onset (<=30 ms):** Yes, immediate (`4.4 ms` at -40 dB, `8.1 ms` at -30 dB, `13.6 ms` at -20 dB). Peak at `92.7 ms`, `T95 = 452 ms`, dur `1.2 s`.
- **`ui_module_install_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Very wide stereo loses `-3.0 dB` of midrange and `-3.7 dB` of top end when folded to mono.
  2. **Bass (<500 Hz):** No (`32.9%` below 500 Hz stereo, `48.8%` mono). Measured stereo `32.9%` <500 Hz (`0.5%` <20 Hz), `6.4%` in 500 Hz to 2 kHz, `60.7%` >2 kHz; mono centroid `4982 Hz`, dominant `30.8 Hz`, `-19.1 dB` stereo RMS (`-21.5 dB` mono, peak `-0.6 dBFS`).
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.14`, fold loss `-2.44 dB` overall (`-0.72 dB` <500 Hz, `-3.02 dB` 500 Hz to 2 kHz, `-3.68 dB` >2 kHz, `-2.78 dB` attack 0 to 60 ms). Single channels: L `-19.8 dB` (pk `-3.6 dBFS`, `28.5/7.5/64.0%`), R `-18.4 dB` (pk `-0.6 dBFS`, `36.0/5.6/58.4%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.3 ms` at -40 dB, `6.1 ms` at -30 dB, `14.1 ms` at -20 dB). Peak at `155.0 ms`, `T95 = 457 ms`, dur `1.2 s`.
- **Final answer (`ui_module_install`):** **t1**

### 50. `ui_relic_socket` (new: a relic equipped, 1.6 s)

- **Today baseline:** `ui_relic_socket_today0.ogg` (`-21.4 dB`, `90.8/8.7/0.5%`, `T95 1015 ms`).
- **`ui_relic_socket_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Solemn stone-on-metal seat, firm latch, and warm low bronze bloom in pure mono; reads clearly as equipping a relic once the `150 ms` dead head is trimmed.
  2. **Bass (<500 Hz):** Yes (`69.1%` below 500 Hz stereo, `69.4%` mono). Measured stereo `69.1%` <500 Hz (`0.0%` <20 Hz), `22.2%` in 500 Hz to 2 kHz, `8.7%` >2 kHz; mono centroid `4080 Hz`, dominant `62.5 Hz`, `-23.7 dB` stereo RMS (`-23.8 dB` mono, peak `-0.5 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +0.99`, fold loss `-0.02 dB` overall (`-0.01 dB` <500 Hz, `-0.03 dB` 500 Hz to 2 kHz, `-0.12 dB` >2 kHz, `+0.00 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** No, late start (`156.4 ms` at -40 dB, `160.6 ms` at -30 dB, `177.3 ms` at -20 dB; trim ~`154 ms` dead head in mastering). Peak at `179.7 ms`, `T95 = 490 ms`, dur `1.6 s`.
- **`ui_relic_socket_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Equally solemn stone seat and warm bronze resonance in pure mono after trimming the `90 ms` dead head.
  2. **Bass (<500 Hz):** Yes (`69.9%` below 500 Hz stereo, `69.9%` mono). Measured stereo `69.9%` <500 Hz (`0.0%` <20 Hz), `25.9%` in 500 Hz to 2 kHz, `4.3%` >2 kHz; mono centroid `3276 Hz`, dominant `57.5 Hz`, `-25.6 dB` stereo RMS (`-25.6 dB` mono, peak `-1.3 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +1.00`, fold loss `-0.01 dB` overall (`-0.00 dB` <500 Hz, `-0.00 dB` 500 Hz to 2 kHz, `-0.04 dB` >2 kHz, `+0.00 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** No, late start (`94.6 ms` at -40 dB, `100.0 ms` at -30 dB, `111.1 ms` at -20 dB; trim ~`92 ms` dead head in mastering). Peak at `119.6 ms`, `T95 = 363 ms`, dur `1.6 s`.
- **Final answer (`ui_relic_socket`):** **t1 and t2**

### 51. `ui_rank_up` (new: a captain or ship ranks up, 1.8 s)

- **Today baseline:** `ui_rank_up_today0.ogg` (`-21.4 dB`, `90.8/8.7/0.5%`, `T95 1015 ms`).
- **`ui_rank_up_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Tiny quiet case snap peaking late at `329 ms` with almost no brass or timpani flourish; players would not know a ship ranked up.
  2. **Bass (<500 Hz):** Yes (`73.0%` below 500 Hz stereo, `73.4%` mono). Measured stereo `73.0%` <500 Hz (`0.5%` <20 Hz), `15.2%` in 500 Hz to 2 kHz, `11.8%` >2 kHz; mono centroid `4319 Hz`, dominant `167.6 Hz`, `-28.9 dB` stereo RMS (`-29.0 dB` mono, peak `-1.1 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +0.97`, fold loss `-0.06 dB` overall (`-0.04 dB` <500 Hz, `-0.04 dB` 500 Hz to 2 kHz, `-0.26 dB` >2 kHz, `-0.04 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** No, late start (`124.3 ms` at -40 dB, `307.0 ms` at -30 dB, `325.2 ms` at -20 dB; trim ~`122 ms` dead head in mastering). Peak at `329.2 ms`, `T95 = 378 ms`, dur `1.76 s`.
- **`ui_rank_up_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Crisp acoustic case snap into a dignified low brass and timpani flourish that clearly reads as a military promotion honor once the `50 ms` dead head is trimmed.
  2. **Bass (<500 Hz):** Yes (`67.8%` below 500 Hz stereo, `71.3%` mono). Measured stereo `67.8%` <500 Hz (`0.0%` <20 Hz), `29.4%` in 500 Hz to 2 kHz, `2.9%` >2 kHz; mono centroid `2146 Hz`, dominant `152.8 Hz`, `-23.0 dB` stereo RMS (`-24.6 dB` mono, peak `-1.4 dBFS`).
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.39`, fold loss `-1.59 dB` overall (`-1.37 dB` <500 Hz, `-2.08 dB` 500 Hz to 2 kHz, `-2.26 dB` >2 kHz, `-0.31 dB` attack 0 to 60 ms). Single channels: L `-23.6 dB` (pk `-4.2 dBFS`, `69.2/28.5/2.3%`), R `-22.5 dB` (pk `-1.4 dBFS`, `66.7/30.0/3.3%`).
  4. **Onset (<=30 ms):** No, late start (`50.7 ms` at -40 dB, `55.7 ms` at -30 dB, `65.3 ms` at -20 dB; trim ~`48 ms` dead head in mastering). Peak at `152.9 ms`, `T95 = 512 ms`, dur `1.76 s`.
- **Final answer (`ui_rank_up`):** **t2**

### 52. `ui_event_comm` (new: a campaign event opens (incoming transmission), 1.2 s)

- **Today baseline:** `ui_event_comm_today0.ogg` (`-26.3 dB`, `14.4/78.1/7.6%`, `T95 106 ms`).
- **`ui_event_comm_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Heavy mechanical bridge comms switch thrown into soft radio crackle and a warm signal tone; players immediately recognize an incoming transmission.
  2. **Bass (<500 Hz):** Yes (`63.9%` below 500 Hz stereo, `67.7%` mono). Measured stereo `63.9%` <500 Hz (`0.6%` <20 Hz), `26.7%` in 500 Hz to 2 kHz, `9.4%` >2 kHz; mono centroid `2995 Hz`, dominant `50.8 Hz`, `-26.0 dB` stereo RMS (`-26.6 dB` mono, peak `-6.7 dBFS`).
  3. **Mono:** Holds up cleanly with minor softening. `corr +0.78`, fold loss `-0.51 dB` overall (`-0.26 dB` <500 Hz, `-0.72 dB` 500 Hz to 2 kHz, `-1.89 dB` >2 kHz, `-2.22 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`7.1 ms` at -40 dB, `9.7 ms` at -30 dB, `29.4 ms` at -20 dB). Peak at `329.6 ms`, `T95 = 467 ms`, dur `1.2 s`.
- **`ui_event_comm_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Crisper, louder pure-mono switch throw with clean static burst and settling tone, pairing cleanly with `t1`.
  2. **Bass (<500 Hz):** Yes (`67.1%` below 500 Hz stereo, `67.2%` mono). Measured stereo `67.1%` <500 Hz (`7.2%` <20 Hz), `19.4%` in 500 Hz to 2 kHz, `13.6%` >2 kHz; mono centroid `3868 Hz`, dominant `60.8 Hz`, `-22.9 dB` stereo RMS (`-22.9 dB` mono, peak `-1.5 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +0.99`, fold loss `-0.02 dB` overall (`-0.01 dB` <500 Hz, `-0.02 dB` 500 Hz to 2 kHz, `-0.09 dB` >2 kHz, `-0.05 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`7.8 ms` at -40 dB, `10.9 ms` at -30 dB, `29.0 ms` at -20 dB). Peak at `35.7 ms`, `T95 = 396 ms`, dur `1.2 s`.
- **Final answer (`ui_event_comm`):** **t1 and t2**

### 53. `ui_ship_lost` (new: a fleet ship lost for good (campaign), 2.4 s)

- **Today baseline:** `ui_ship_lost_today0.ogg` (`-21.0 dB`, `87.3/12.3/0.4%`, `T95 2374 ms`).
- **`ui_ship_lost_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Higher `825 Hz` bell sounds like a regular watch bell and overlaps with `ui_round_bell_t1` instead of a grave memorial toll.
  2. **Bass (<500 Hz):** No (`8.4%` below 500 Hz stereo, `8.3%` mono). Measured stereo `8.4%` <500 Hz (`0.0%` <20 Hz), `91.6%` in 500 Hz to 2 kHz, `0.0%` >2 kHz; mono centroid `881 Hz`, dominant `825.4 Hz`, `-17.7 dB` stereo RMS (`-17.7 dB` mono, peak `-1.1 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +0.99`, fold loss `-0.02 dB` overall (`-0.04 dB` <500 Hz, `-0.02 dB` 500 Hz to 2 kHz, `-0.25 dB` >2 kHz, `-0.03 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.7 ms` at -40 dB, `3.1 ms` at -30 dB, `10.1 ms` at -20 dB). Peak at `153.8 ms`, `T95 = 888 ms`, dur `2.4 s`.
- **`ui_ship_lost_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Deep, grave, mournful single bronze memorial bell (`230 Hz`, long decay) in pure mono that unmistakably marks a permanent ship loss.
  2. **Bass (<500 Hz):** Yes (`75.3%` below 500 Hz stereo, `75.3%` mono). Measured stereo `75.3%` <500 Hz (`0.0%` <20 Hz), `24.7%` in 500 Hz to 2 kHz, `0.0%` >2 kHz; mono centroid `526 Hz`, dominant `230.4 Hz`, `-21.0 dB` stereo RMS (`-21.0 dB` mono, peak `-5.2 dBFS`).
  3. **Mono:** No loss; rock-solid mono. `corr +1.00`, fold loss `-0.00 dB` overall (`-0.00 dB` <500 Hz, `-0.00 dB` 500 Hz to 2 kHz, `-0.14 dB` >2 kHz, `-0.00 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** No, late start (`32.7 ms` at -40 dB, `34.2 ms` at -30 dB, `34.5 ms` at -20 dB; trim ~`30 ms` dead head in mastering). Peak at `120.1 ms`, `T95 = 1325 ms`, dur `2.4 s`.
- **Final answer (`ui_ship_lost`):** **t2**

## Group 4: Variety Round-Robin Takes (27 Wave F IDs, 54 Takes)

### 54. `imp_metal_light_more` (variety: 2 more takes of keeper imp_metal_light (D t1, its exact prompt) for the round robin, 0.6 s)

- **Today baseline:** `imp_metal_light_more_today0.ogg` (`-24.9 dB`, `19.7/33.2/47.1%`, `T95 165 ms`).
- **In-game keeper (`godot/audio/clips/imp_metal_light_0.ogg`):** `-24.9 dB` RMS, `19.7/33.2/47.1%` (<500 / 500-2k / >2k), centroid `5468 Hz`, `T95 165 ms`, dur `0.597 s`.
- **`imp_metal_light_more_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Slightly heavier armored-steel shell clang that stays close enough to join `imp_metal_light_0.ogg`, though moderate stereo drops `-1.7` to `-1.9 dB` in mono.
  2. **Bass (<500 Hz):** No (`36.4%` below 500 Hz stereo, `40.0%` mono). Measured stereo `36.4%` <500 Hz (`1.0%` <20 Hz), `26.8%` in 500 Hz to 2 kHz, `36.9%` >2 kHz; mono centroid `4273 Hz`, dominant `175.0 Hz`, `-16.9 dB` stereo RMS (`-18.4 dB` mono, peak `-1.1 dBFS`). vs `imp_metal_light_0.ogg`: spectral cosine `0.594`, `T95` ratio `1.37x`, above-30 Hz deltas `+19/-7/-12%`.
  3. **Mono:** Mild softening; holds up cleanly by ear. `corr +0.40`, fold loss `-1.53 dB` overall (`-1.12 dB` <500 Hz, `-1.68 dB` 500 Hz to 2 kHz, `-1.87 dB` >2 kHz, `-1.45 dB` attack 0 to 60 ms). Single channels: L `-16.9 dB` (pk `-1.1 dBFS`, `34.1/27.2/38.7%`), R `-16.9 dB` (pk `-1.4 dBFS`, `38.6/26.3/35.1%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `69.0 ms`, `T95 = 226 ms`, dur `0.6 s`.
- **`imp_metal_light_more_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Spot-on bright steel clang sibling matching `imp_metal_light_0.ogg` in length and tone, but wide stereo collapses `-3.5 dB` of mids and highs in mono; channel R alone joins the round robin cleanly.
  2. **Bass (<500 Hz):** No (`32.9%` below 500 Hz stereo, `41.1%` mono). Measured stereo `32.9%` <500 Hz (`0.2%` <20 Hz), `28.0%` in 500 Hz to 2 kHz, `39.2%` >2 kHz; mono centroid `4957 Hz`, dominant `165.0 Hz`, `-19.9 dB` stereo RMS (`-22.8 dB` mono, peak `0.0 dBFS`). vs `imp_metal_light_0.ogg`: spectral cosine `0.616`, `T95` ratio `0.77x`, above-30 Hz deltas `+21/-8/-13%`.
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.02`, fold loss `-2.92 dB` overall (`-1.95 dB` <500 Hz, `-3.47 dB` 500 Hz to 2 kHz, `-3.51 dB` >2 kHz, `-2.43 dB` attack 0 to 60 ms). Single channels: L `-20.7 dB` (pk `0.0 dBFS`, `29.4/25.9/44.6%`), R `-19.2 dB` (pk `-0.5 dBFS`, `35.3/29.4/35.3%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `21.2 ms`, `T95 = 127 ms`, dur `0.6 s`.
- **Final answer (`imp_metal_light_more`):** **channel R of t2**

### 55. `imp_metal_heavy_more` (variety: 2 more takes of keeper imp_metal_heavy (A2 t1, its exact prompt) for the round robin, 1 s)

- **Today baseline:** `imp_metal_heavy_more_today0.ogg` (`-25.1 dB`, `54.1/27.4/18.6%`, `T95 349 ms`), `imp_metal_heavy_more_today1.ogg` (`-20.1 dB`, `98.4/1.2/0.4%`, `T95 668 ms`).
- **In-game keeper (`godot/audio/clips/imp_metal_heavy_0.ogg`):** `-25.1 dB` RMS, `54.1/27.4/18.6%` (<500 / 500-2k / >2k), centroid `3560 Hz`, `T95 349 ms`, dur `0.992 s`.
- **`imp_metal_heavy_more_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Natural matching heavy armor crunch (`cos 0.858`), but wide stereo loses `-2.7` to `-3.2 dB` of mids and highs in mono; channel L alone is clean.
  2. **Bass (<500 Hz):** Yes (`64.8%` below 500 Hz stereo, `72.8%` mono). Measured stereo `64.8%` <500 Hz (`0.4%` <20 Hz), `16.9%` in 500 Hz to 2 kHz, `18.3%` >2 kHz; mono centroid `3301 Hz`, dominant `71.0 Hz`, `-20.0 dB` stereo RMS (`-21.8 dB` mono, peak `-1.4 dBFS`). vs `imp_metal_heavy_0.ogg`: spectral cosine `0.858`, `T95` ratio `0.74x`, above-30 Hz deltas `+19/-14/-5%`.
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.31`, fold loss `-1.84 dB` overall (`-1.33 dB` <500 Hz, `-2.71 dB` 500 Hz to 2 kHz, `-3.20 dB` >2 kHz, `-1.84 dB` attack 0 to 60 ms). Single channels: L `-19.8 dB` (pk `-1.4 dBFS`, `63.6/18.0/18.4%`), R `-20.1 dB` (pk `-2.6 dBFS`, `66.1/15.8/18.2%`).
  4. **Onset (<=30 ms):** Yes, immediate (`4.7 ms` at -40 dB, `8.0 ms` at -30 dB, `11.5 ms` at -20 dB). Peak at `43.9 ms`, `T95 = 257 ms`, dur `1.0 s`.
- **`imp_metal_heavy_more_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Dead-ringer second performance of `imp_metal_heavy_0.ogg` (`cos 0.894`, matching `373 ms` decay) with solid mono lock.
  2. **Bass (<500 Hz):** Yes (`68.4%` below 500 Hz stereo, `72.4%` mono). Measured stereo `68.4%` <500 Hz (`0.6%` <20 Hz), `18.8%` in 500 Hz to 2 kHz, `12.8%` >2 kHz; mono centroid `3021 Hz`, dominant `56.0 Hz`, `-20.3 dB` stereo RMS (`-20.8 dB` mono, peak `-1.3 dBFS`). vs `imp_metal_heavy_0.ogg`: spectral cosine `0.894`, `T95` ratio `1.07x`, above-30 Hz deltas `+18/-10/-8%`.
  3. **Mono:** Holds up cleanly with minor softening. `corr +0.77`, fold loss `-0.54 dB` overall (`-0.29 dB` <500 Hz, `-0.88 dB` 500 Hz to 2 kHz, `-1.49 dB` >2 kHz, `-0.72 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`8.6 ms` at -40 dB, `27.6 ms` at -30 dB, `30.6 ms` at -20 dB). Peak at `49.3 ms`, `T95 = 373 ms`, dur `1.0 s`.
- **Final answer (`imp_metal_heavy_more`):** **t2**

### 56. `imp_las_more` (variety: 2 more takes of keeper imp_las (D t1, its exact prompt) for the round robin, 0.55 s)

- **Today baseline:** `imp_las_more_today0.ogg` (`-24.6 dB`, `58.1/4.5/37.4%`, `T95 222 ms`).
- **In-game keeper (`godot/audio/clips/imp_las_0.ogg`):** `-24.6 dB` RMS, `58.1/4.5/37.4%` (<500 / 500-2k / >2k), centroid `4416 Hz`, `T95 222 ms`, dur `0.517 s`.
- **`imp_las_more_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Quiet hollow midrange clank (`cos 0.138`) that misses the hot laser sear bite of `imp_las_0.ogg`.
  2. **Bass (<500 Hz):** No above 30 Hz (raw `51.3%` below 500 Hz is skewed by `1.7%` sub-20 Hz DC/rumble; above 30 Hz it is `49.3%` in 30 to 500 Hz, `35.6%` in 500 Hz to 2 kHz, `15.1%` above 2 kHz). Measured stereo `51.3%` <500 Hz (`1.7%` <20 Hz), `34.2%` in 500 Hz to 2 kHz, `14.5%` >2 kHz; mono centroid `4347 Hz`, dominant `100.0 Hz`, `-32.7 dB` stereo RMS (`-32.9 dB` mono, peak `-13.9 dBFS`). vs `imp_las_0.ogg`: spectral cosine `0.138`, `T95` ratio `1.02x`, above-30 Hz deltas `-8/+32/-24%`.
  3. **Mono:** No loss; rock-solid mono. `corr +0.93`, fold loss `-0.14 dB` overall (`-0.06 dB` <500 Hz, `-0.08 dB` 500 Hz to 2 kHz, `-0.62 dB` >2 kHz, `-0.12 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `35.2 ms`, `T95 = 226 ms`, dur `0.52 s`.
- **`imp_las_more_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Matching armored-steel hit and tight hot laser sear (`T95 205 ms` vs `222 ms`), but mono fold strips `-3.0` to `-3.2 dB` of mids and highs; channel L alone keeps the full sear.
  2. **Bass (<500 Hz):** Yes (`68.2%` below 500 Hz stereo, `81.1%` mono). Measured stereo `68.2%` <500 Hz (`0.0%` <20 Hz), `13.5%` in 500 Hz to 2 kHz, `18.3%` >2 kHz; mono centroid `3408 Hz`, dominant `138.5 Hz`, `-17.7 dB` stereo RMS (`-18.6 dB` mono, peak `-1.1 dBFS`). vs `imp_las_0.ogg`: spectral cosine `0.647`, `T95` ratio `0.92x`, above-30 Hz deltas `+23/+4/-27%`.
  3. **Mono:** Yes, loses top end/midrange. `corr +0.63`, fold loss `-0.88 dB` overall (`-0.12 dB` <500 Hz, `-3.02 dB` 500 Hz to 2 kHz, `-3.23 dB` >2 kHz, `-0.63 dB` attack 0 to 60 ms). Single channels: L `-17.8 dB` (pk `-1.1 dBFS`, `66.1/15.5/18.4%`), R `-17.7 dB` (pk `-1.6 dBFS`, `70.3/11.5/18.2%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `51.0 ms`, `T95 = 205 ms`, dur `0.52 s`.
- **Final answer (`imp_las_more`):** **channel L of t2**

### 57. `imp_energy_sear_more` (variety: 2 more takes of keeper imp_energy_sear (D t1, its exact prompt) for the round robin, 0.7 s)

- **Today baseline:** `imp_energy_sear_more_today0.ogg` (`-25.1 dB`, `69.2/2.9/27.9%`, `T95 217 ms`).
- **In-game keeper (`godot/audio/clips/imp_energy_sear_0.ogg`):** `-25.1 dB` RMS, `69.2/2.9/27.9%` (<500 / 500-2k / >2k), centroid `6677 Hz`, `T95 217 ms`, dur `0.677 s`.
- **`imp_energy_sear_more_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Over 7 dB quieter and weaker than `imp_energy_sear_0.ogg` with wide stereo cancellation.
  2. **Bass (<500 Hz):** Yes (`81.7%` below 500 Hz stereo, `83.3%` mono). Measured stereo `81.7%` <500 Hz (`0.3%` <20 Hz), `3.8%` in 500 Hz to 2 kHz, `14.6%` >2 kHz; mono centroid `6241 Hz`, dominant `64.7 Hz`, `-32.0 dB` stereo RMS (`-34.1 dB` mono, peak `-11.8 dBFS`). vs `imp_energy_sear_0.ogg`: spectral cosine `0.747`, `T95` ratio `0.88x`, above-30 Hz deltas `+14/+2/-15%`.
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.23`, fold loss `-2.11 dB` overall (`-2.03 dB` <500 Hz, `-1.60 dB` 500 Hz to 2 kHz, `-2.80 dB` >2 kHz, `-1.77 dB` attack 0 to 60 ms). Single channels: L `-31.6 dB` (pk `-13.1 dBFS`, `80.1/3.5/16.4%`), R `-32.3 dB` (pk `-11.8 dBFS`, `83.5/4.1/12.4%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `21.8 ms`, `T95 = 192 ms`, dur `0.68 s`.
- **`imp_energy_sear_more_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Trapped `96.2%` below 500 Hz with only `3.5%` above 2 kHz, reading as a dull bass thud instead of the keeper's bright plasma sear.
  2. **Bass (<500 Hz):** Yes (`96.2%` below 500 Hz stereo, `96.6%` mono). Measured stereo `96.2%` <500 Hz (`0.1%` <20 Hz), `0.3%` in 500 Hz to 2 kHz, `3.5%` >2 kHz; mono centroid `6038 Hz`, dominant `69.1 Hz`, `-17.6 dB` stereo RMS (`-18.5 dB` mono, peak `-2.9 dBFS`). vs `imp_energy_sear_0.ogg`: spectral cosine `0.789`, `T95` ratio `1.21x`, above-30 Hz deltas `+28/-3/-25%`.
  3. **Mono:** Holds up cleanly with minor softening. `corr +0.62`, fold loss `-0.92 dB` overall (`-0.90 dB` <500 Hz, `-1.29 dB` 500 Hz to 2 kHz, `-1.46 dB` >2 kHz, `-0.70 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`6.3 ms` at -40 dB, `13.8 ms` at -30 dB, `18.4 ms` at -20 dB). Peak at `70.2 ms`, `T95 = 263 ms`, dur `0.68 s`.
- **Final answer (`imp_energy_sear_more`):** **re-roll: keep the same prompt at higher influence (0.75) and add 'bright crackling arc' so takes keep `imp_energy_sear_0.ogg`'s 28% >2 kHz plasma sear instead of turning into quiet or dark thuds.**

### 58. `imp_bio_flesh_more` (variety: 2 more takes of keeper imp_bio_flesh (A2 t1, its exact prompt) for the round robin, 1 s)

- **Today baseline:** `imp_bio_flesh_more_today0.ogg` (`-26.9 dB`, `73.2/13.4/13.4%`, `T95 359 ms`).
- **In-game keeper (`godot/audio/clips/imp_bio_flesh_0.ogg`):** `-26.9 dB` RMS, `73.2/13.4/13.4%` (<500 / 500-2k / >2k), centroid `3899 Hz`, `T95 359 ms`, dur `1.0 s`.
- **`imp_bio_flesh_more_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Dead-ringer second performance of `imp_bio_flesh_0.ogg` (`cos 0.904`, `T95 331 ms`) in pure mono once high-passed at 65 Hz with the keeper's bio EQ.
  2. **Bass (<500 Hz):** Yes (`92.1%` below 500 Hz stereo, `92.2%` mono). Measured stereo `92.1%` <500 Hz (`12.1%` <20 Hz), `5.4%` in 500 Hz to 2 kHz, `2.5%` >2 kHz; mono centroid `2527 Hz`, dominant `108.0 Hz`, `-24.1 dB` stereo RMS (`-24.1 dB` mono, peak `-4.3 dBFS`). vs `imp_bio_flesh_0.ogg`: spectral cosine `0.904`, `T95` ratio `0.92x`, above-30 Hz deltas `+18/-7/-11%`.
  3. **Mono:** No loss; rock-solid mono. `corr +1.00`, fold loss `-0.01 dB` overall (`-0.00 dB` <500 Hz, `-0.01 dB` 500 Hz to 2 kHz, `-0.10 dB` >2 kHz, `-0.00 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `13.6 ms`, `T95 = 331 ms`, dur `1.0 s`.
- **`imp_bio_flesh_more_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Punchier, slightly tighter bone-impact sibling (`cos 0.811`) in pure mono that fits naturally in the round robin with the keeper's EQ.
  2. **Bass (<500 Hz):** Yes (`82.1%` below 500 Hz stereo, `82.5%` mono). Measured stereo `82.1%` <500 Hz (`0.6%` <20 Hz), `11.5%` in 500 Hz to 2 kHz, `6.5%` >2 kHz; mono centroid `2688 Hz`, dominant `152.0 Hz`, `-19.7 dB` stereo RMS (`-19.7 dB` mono, peak `-0.9 dBFS`). vs `imp_bio_flesh_0.ogg`: spectral cosine `0.811`, `T95` ratio `0.56x`, above-30 Hz deltas `+9/-2/-7%`.
  3. **Mono:** No loss; rock-solid mono. `corr +0.99`, fold loss `-0.03 dB` overall (`-0.01 dB` <500 Hz, `-0.04 dB` 500 Hz to 2 kHz, `-0.31 dB` >2 kHz, `-0.03 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `28.8 ms`, `T95 = 201 ms`, dur `1.0 s`.
- **Final answer (`imp_bio_flesh_more`):** **t1 and t2**

### 59. `imp_glass_armor_more` (variety: 2 more takes of keeper imp_glass_armor (B t1, its exact prompt) for the round robin, 1.1 s)

- **Today baseline:** `imp_glass_armor_more_today0.ogg` (`-25.6 dB`, `82.7/14.6/2.7%`, `T95 511 ms`).
- **In-game keeper (`godot/audio/clips/imp_glass_armor_0.ogg`):** `-25.6 dB` RMS, `82.7/14.6/2.7%` (<500 / 500-2k / >2k), centroid `2035 Hz`, `T95 511 ms`, dur `1.08 s`.
- **`imp_glass_armor_more_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Near-identical sibling to `imp_glass_armor_0.ogg` (`cos 0.983`, `T95 461 ms` vs `511 ms`) in pure mono.
  2. **Bass (<500 Hz):** Yes (`83.6%` below 500 Hz stereo, `83.6%` mono). Measured stereo `83.6%` <500 Hz (`1.5%` <20 Hz), `12.0%` in 500 Hz to 2 kHz, `4.4%` >2 kHz; mono centroid `2187 Hz`, dominant `137.0 Hz`, `-25.1 dB` stereo RMS (`-25.1 dB` mono, peak `-5.9 dBFS`). vs `imp_glass_armor_0.ogg`: spectral cosine `0.983`, `T95` ratio `0.9x`, above-30 Hz deltas `+1/-2/+2%`.
  3. **Mono:** No loss; rock-solid mono. `corr +1.00`, fold loss `-0.00 dB` overall (`-0.00 dB` <500 Hz, `-0.01 dB` 500 Hz to 2 kHz, `-0.02 dB` >2 kHz, `-0.00 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `32.8 ms`, `T95 = 461 ms`, dur `1.08 s`.
- **`imp_glass_armor_more_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Matching glacier-crystal impact sibling (`cos 0.847`, `T95 524 ms`) in pure mono once `14.7%` sub-20 Hz rumble is high-passed.
  2. **Bass (<500 Hz):** Yes (`89.4%` below 500 Hz stereo, `89.5%` mono). Measured stereo `89.4%` <500 Hz (`14.7%` <20 Hz), `7.8%` in 500 Hz to 2 kHz, `2.8%` >2 kHz; mono centroid `3201 Hz`, dominant `59.3 Hz`, `-28.4 dB` stereo RMS (`-28.4 dB` mono, peak `-10.3 dBFS`). vs `imp_glass_armor_0.ogg`: spectral cosine `0.847`, `T95` ratio `1.03x`, above-30 Hz deltas `+4/-5/+1%`.
  3. **Mono:** No loss; rock-solid mono. `corr +0.99`, fold loss `-0.01 dB` overall (`-0.01 dB` <500 Hz, `-0.07 dB` 500 Hz to 2 kHz, `-0.07 dB` >2 kHz, `-0.01 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `6.1 ms`, `T95 = 524 ms`, dur `1.08 s`.
- **Final answer (`imp_glass_armor_more`):** **t1 and t2**

### 60. `imp_obsidian_eclipse_more` (variety: 2 more takes of keeper imp_obsidian_eclipse (C t1, its exact prompt) for the round robin, 1 s)

- **Today baseline:** `imp_obsidian_eclipse_more_today0.ogg` (`-20.2 dB`, `99.5/0.5/0.0%`, `T95 976 ms`), `imp_obsidian_eclipse_more_today1.ogg` (`-22.6 dB`, `88.5/5.9/5.6%`, `T95 83 ms`).
- **In-game keeper (`godot/audio/clips/imp_obsidian_eclipse_0.ogg`):** `-26.2 dB` RMS, `63.3/17.9/18.9%` (<500 / 500-2k / >2k), centroid `3712 Hz`, `T95 237 ms`, dur `0.997 s`.
- **`imp_obsidian_eclipse_more_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Matching cold brittle obsidian crack and knock (`T95 220 ms` vs `237 ms`) in pure mono, needing a `27 ms` head trim.
  2. **Bass (<500 Hz):** Yes (`59.3%` below 500 Hz stereo, `60.6%` mono). Measured stereo `59.3%` <500 Hz (`0.3%` <20 Hz), `21.3%` in 500 Hz to 2 kHz, `19.4%` >2 kHz; mono centroid `3945 Hz`, dominant `46.0 Hz`, `-20.6 dB` stereo RMS (`-20.7 dB` mono, peak `-0.9 dBFS`). vs `imp_obsidian_eclipse_0.ogg`: spectral cosine `0.757`, `T95` ratio `0.93x`, above-30 Hz deltas `-3/+3/-1%`.
  3. **Mono:** No loss; rock-solid mono. `corr +0.95`, fold loss `-0.10 dB` overall (`-0.01 dB` <500 Hz, `-0.12 dB` 500 Hz to 2 kHz, `-0.38 dB` >2 kHz, `-0.03 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, within 30 ms (`27.0 ms` at -40 dB, `34.4 ms` at -30 dB, `35.6 ms` at -20 dB; trim ~`27 ms` head for tight sync). Peak at `156.8 ms`, `T95 = 220 ms`, dur `1.0 s`.
- **`imp_obsidian_eclipse_more_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Dead-ringer sibling (`cos 0.890`, `0.2 ms` onset, `T95 229 ms`) in pure mono that blends right into the round robin.
  2. **Bass (<500 Hz):** Yes (`69.5%` below 500 Hz stereo, `71.0%` mono). Measured stereo `69.5%` <500 Hz (`0.5%` <20 Hz), `13.3%` in 500 Hz to 2 kHz, `17.2%` >2 kHz; mono centroid `3786 Hz`, dominant `53.0 Hz`, `-18.8 dB` stereo RMS (`-18.9 dB` mono, peak `-1.0 dBFS`). vs `imp_obsidian_eclipse_0.ogg`: spectral cosine `0.89`, `T95` ratio `0.97x`, above-30 Hz deltas `+6/-4/-3%`.
  3. **Mono:** No loss; rock-solid mono. `corr +0.95`, fold loss `-0.10 dB` overall (`-0.01 dB` <500 Hz, `-0.05 dB` 500 Hz to 2 kHz, `-0.54 dB` >2 kHz, `-0.11 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.2 ms` at -40 dB, `16.0 ms` at -30 dB, `29.7 ms` at -20 dB). Peak at `88.0 ms`, `T95 = 229 ms`, dur `1.0 s`.
- **Final answer (`imp_obsidian_eclipse_more`):** **t1 and t2**

### 61. `shd_hit_absorb_more` (variety: 2 more takes of keeper shd_hit_absorb (B t1, its exact prompt) for the round robin, 0.65 s)

- **Today baseline:** `shd_hit_absorb_more_today0.ogg` (`-23.0 dB`, `90.1/9.8/0.1%`, `T95 350 ms`).
- **In-game keeper (`godot/audio/clips/shd_hit_absorb_0.ogg`):** `-23.0 dB` RMS, `90.1/9.8/0.1%` (<500 / 500-2k / >2k), centroid `746 Hz`, `T95 350 ms`, dur `0.637 s`.
- **`shd_hit_absorb_more_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Very close soft tonal shield deflection (`cos 0.876`) in rock-solid mono, just slightly fuller and longer than `shd_hit_absorb_0.ogg`.
  2. **Bass (<500 Hz):** Yes (`93.7%` below 500 Hz stereo, `95.5%` mono). Measured stereo `93.7%` <500 Hz (`0.1%` <20 Hz), `6.3%` in 500 Hz to 2 kHz, `0.1%` >2 kHz; mono centroid `981 Hz`, dominant `39.1 Hz`, `-17.0 dB` stereo RMS (`-17.3 dB` mono, peak `-6.4 dBFS`). vs `shd_hit_absorb_0.ogg`: spectral cosine `0.876`, `T95` ratio `1.37x`, above-30 Hz deltas `+6/-6/-0%`.
  3. **Mono:** Yes, loses top end/midrange. `corr +0.94`, fold loss `-0.27 dB` overall (`-0.18 dB` <500 Hz, `-1.77 dB` 500 Hz to 2 kHz, `-3.26 dB` >2 kHz, `-0.31 dB` attack 0 to 60 ms). L/R imbalance `+3.2 dB` (`L -15.7 dB`, `R -18.9 dB`). Single channels: L `-15.7 dB` (pk `-6.4 dBFS`, `93.8/6.2/0.1%`), R `-18.9 dB` (pk `-9.6 dBFS`, `93.5/6.5/0.0%`).
  4. **Onset (<=30 ms):** Yes, within 30 ms (`20.4 ms` at -40 dB, `26.4 ms` at -30 dB, `31.3 ms` at -20 dB; trim ~`20 ms` head for tight sync). Peak at `345.0 ms`, `T95 = 480 ms`, dur `0.64 s`.
- **`shd_hit_absorb_more_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Dead-ringer tonal match (`cos 0.965`) in stereo, but wide stereo drops `-3.1 dB` of midrange in mono; channel L alone is clean.
  2. **Bass (<500 Hz):** Yes (`81.3%` below 500 Hz stereo, `86.0%` mono). Measured stereo `81.3%` <500 Hz (`0.4%` <20 Hz), `18.5%` in 500 Hz to 2 kHz, `0.2%` >2 kHz; mono centroid `616 Hz`, dominant `40.6 Hz`, `-19.6 dB` stereo RMS (`-21.4 dB` mono, peak `-7.9 dBFS`). vs `shd_hit_absorb_0.ogg`: spectral cosine `0.965`, `T95` ratio `1.36x`, above-30 Hz deltas `-4/+4/-0%`.
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.31`, fold loss `-1.87 dB` overall (`-1.62 dB` <500 Hz, `-3.10 dB` 500 Hz to 2 kHz, `-9.61 dB` >2 kHz, `-2.87 dB` attack 0 to 60 ms). L/R imbalance `+2.5 dB` (`L -18.5 dB`, `R -21.0 dB`). Single channels: L `-18.5 dB` (pk `-7.9 dBFS`, `78.8/21.1/0.1%`), R `-21.0 dB` (pk `-9.9 dBFS`, `85.8/14.0/0.2%`).
  4. **Onset (<=30 ms):** Yes, immediate (`8.7 ms` at -40 dB, `17.5 ms` at -30 dB, `21.9 ms` at -20 dB). Peak at `201.3 ms`, `T95 = 477 ms`, dur `0.64 s`.
- **Final answer (`shd_hit_absorb_more`):** **t1**

### 62. `wep_sunward_autocannon_more` (variety: 2 more takes of keeper wep_sunward_autocannon (B t1, its exact prompt) for the round robin, 0.5 s)

- **Today baseline:** `wep_sunward_autocannon_more_today0.ogg` (`-28.1 dB`, `1.9/10.9/87.1%`, `T95 161 ms`).
- **In-game keeper (`godot/audio/clips/wep_sunward_autocannon_0.ogg`):** `-23.3 dB` RMS, `74.8/8.3/16.9%` (<500 / 500-2k / >2k), centroid `4927 Hz`, `T95 92 ms`, dur `0.477 s`.
- **`wep_sunward_autocannon_more_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Completely different sound: tiny thin metallic tink (`93.3%` above 2 kHz, `cos 0.131`) with zero autocannon punch.
  2. **Bass (<500 Hz):** No (`4.2%` below 500 Hz stereo, `3.8%` mono). Measured stereo `4.2%` <500 Hz (`0.2%` <20 Hz), `2.4%` in 500 Hz to 2 kHz, `93.3%` >2 kHz; mono centroid `7086 Hz`, dominant `9154.2 Hz`, `-23.4 dB` stereo RMS (`-23.7 dB` mono, peak `-1.3 dBFS`). vs `wep_sunward_autocannon_0.ogg`: spectral cosine `0.131`, `T95` ratio `0.72x`, above-30 Hz deltas `-71/-6/+77%`.
  3. **Mono:** No loss; rock-solid mono. `corr +0.91`, fold loss `-0.22 dB` overall (`-0.62 dB` <500 Hz, `-0.14 dB` 500 Hz to 2 kHz, `-0.20 dB` >2 kHz, `-0.16 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `0.9 ms`, `T95 = 66 ms`, dur `0.48 s`.
- **`wep_sunward_autocannon_more_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Quiet muffled sub-500 Hz thud (`-31.2 dB`, `96.4%` below 500 Hz in mono) that lacks the keeper's crisp mechanical report.
  2. **Bass (<500 Hz):** Yes (`92.0%` below 500 Hz stereo, `96.4%` mono). Measured stereo `92.0%` <500 Hz (`3.1%` <20 Hz), `0.8%` in 500 Hz to 2 kHz, `7.2%` >2 kHz; mono centroid `4209 Hz`, dominant `52.1 Hz`, `-31.2 dB` stereo RMS (`-31.5 dB` mono, peak `-12.6 dBFS`). vs `wep_sunward_autocannon_0.ogg`: spectral cosine `0.803`, `T95` ratio `1.29x`, above-30 Hz deltas `+21/-8/-14%`.
  3. **Mono:** Yes, loses top end/midrange. `corr +0.89`, fold loss `-0.29 dB` overall (`-0.10 dB` <500 Hz, `-0.65 dB` 500 Hz to 2 kHz, `-4.31 dB` >2 kHz, `-0.31 dB` attack 0 to 60 ms). Single channels: L `-30.5 dB` (pk `-12.6 dBFS`, `91.8/1.0/7.3%`), R `-31.9 dB` (pk `-13.3 dBFS`, `92.4/0.6/7.0%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `19.2 ms`, `T95 = 119 ms`, dur `0.48 s`.
- **Final answer (`wep_sunward_autocannon_more`):** **re-roll: raise influence to 0.75 or shift to v3 with explicit tight mechanical cannon punch so takes match `wep_sunward_autocannon_0.ogg` instead of flipping between a tinny click and a muffled thud.**

### 63. `wep_sunward_turret_more` (variety: 2 more takes of keeper wep_sunward_turret (C t2, its exact prompt) for the round robin, 0.6 s)

- **Today baseline:** `wep_sunward_turret_more_today0.ogg` (`-21.6 dB`, `100.0/0.0/0.0%`, `T95 594 ms`), `wep_sunward_turret_more_today1.ogg` (`-21.8 dB`, `58.9/31.6/9.5%`, `T95 292 ms`).
- **In-game keeper (`godot/audio/clips/wep_sunward_turret_0.ogg`):** `-24.5 dB` RMS, `31.5/51.7/16.8%` (<500 / 500-2k / >2k), centroid `3186 Hz`, `T95 100 ms`, dur `0.597 s`.
- **`wep_sunward_turret_more_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Broken whisper-quiet dud (`-50.0 dB` RMS, peak `-33.0 dBFS`) that cannot join any round robin.
  2. **Bass (<500 Hz):** Yes (`90.4%` below 500 Hz stereo, `90.4%` mono). Measured stereo `90.4%` <500 Hz (`8.6%` <20 Hz), `4.2%` in 500 Hz to 2 kHz, `5.5%` >2 kHz; mono centroid `3872 Hz`, dominant `23.3 Hz`, `-50.0 dB` stereo RMS (`-50.0 dB` mono, peak `-33.0 dBFS`). vs `wep_sunward_turret_0.ogg`: spectral cosine `0.061`, `T95` ratio `2.74x`, above-30 Hz deltas `+48/-43/-5%`.
  3. **Mono:** No loss; rock-solid mono. `corr +1.00`, fold loss `-0.01 dB` overall (`-0.01 dB` <500 Hz, `-0.02 dB` 500 Hz to 2 kHz, `-0.04 dB` >2 kHz, `-0.01 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `13.9 ms`, `T95 = 274 ms`, dur `0.6 s`.
- **`wep_sunward_turret_more_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Heavy muffled low thump (`84.5%` below 500 Hz, only `5.7%` midrange vs `52.3%` on `wep_sunward_turret_0.ogg`, `cos 0.01`), sounding like a different weapon.
  2. **Bass (<500 Hz):** Yes (`84.5%` below 500 Hz stereo, `84.5%` mono). Measured stereo `84.5%` <500 Hz (`11.9%` <20 Hz), `5.7%` in 500 Hz to 2 kHz, `9.8%` >2 kHz; mono centroid `4732 Hz`, dominant `45.0 Hz`, `-15.0 dB` stereo RMS (`-15.0 dB` mono, peak `0.3 dBFS`). vs `wep_sunward_turret_0.ogg`: spectral cosine `0.01`, `T95` ratio `1.24x`, above-30 Hz deltas `+51/-46/-5%`.
  3. **Mono:** No loss; rock-solid mono. `corr +1.00`, fold loss `-0.00 dB` overall (`-0.00 dB` <500 Hz, `-0.01 dB` 500 Hz to 2 kHz, `-0.02 dB` >2 kHz, `-0.00 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `22.2 ms`, `T95 = 124 ms`, dur `0.6 s`.
- **Final answer (`wep_sunward_turret_more`):** **re-roll: drop low-punch weight or move to v3 emphasizing a bright forged-steel breech crack so takes match `wep_sunward_turret_0.ogg`'s 52% midrange bark.**

### 64. `wep_sunward_hbattery_more` (variety: 2 more takes of keeper wep_sunward_hbattery (C t2, its exact prompt) for the round robin, 1 s)

- **Today baseline:** `wep_sunward_hbattery_more_today0.ogg` (`-21.6 dB`, `100.0/0.0/0.0%`, `T95 594 ms`), `wep_sunward_hbattery_more_today1.ogg` (`-21.8 dB`, `58.9/31.6/9.5%`, `T95 292 ms`).
- **In-game keeper (`godot/audio/clips/wep_sunward_hbattery_0.ogg`):** `-22.1 dB` RMS, `58.5/26.1/15.4%` (<500 / 500-2k / >2k), centroid `3372 Hz`, `T95 304 ms`, dur `0.997 s`.
- **`wep_sunward_hbattery_more_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Clips hot (`+1.1 dBFS`), loses midrange iron ring (`8.4%` vs `26.4%`), and swells into a drawn-out late peak at `205 ms` instead of one sharp cannon crack.
  2. **Bass (<500 Hz):** Yes (`84.1%` below 500 Hz stereo, `85.2%` mono). Measured stereo `84.1%` <500 Hz (`16.6%` <20 Hz), `8.4%` in 500 Hz to 2 kHz, `7.5%` >2 kHz; mono centroid `3852 Hz`, dominant `35.0 Hz`, `-7.2 dB` stereo RMS (`-7.3 dB` mono, peak `1.1 dBFS`). vs `wep_sunward_hbattery_0.ogg`: spectral cosine `0.776`, `T95` ratio `1.33x`, above-30 Hz deltas `+23/-16/-7%`.
  3. **Mono:** No loss; rock-solid mono. `corr +0.97`, fold loss `-0.06 dB` overall (`-0.00 dB` <500 Hz, `-0.15 dB` 500 Hz to 2 kHz, `-0.63 dB` >2 kHz, `-0.01 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `205.3 ms`, `T95 = 405 ms`, dur `1.0 s`.
- **`wep_sunward_hbattery_more_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Spot-on heavy main battery blast (`cos 0.839`, `0.0 ms` onset, `T95 258 ms` vs `304 ms`) in rock-solid mono once 40 Hz high-passed and peak-trimmed.
  2. **Bass (<500 Hz):** Yes (`74.8%` below 500 Hz stereo, `76.6%` mono). Measured stereo `74.8%` <500 Hz (`9.9%` <20 Hz), `15.6%` in 500 Hz to 2 kHz, `9.5%` >2 kHz; mono centroid `3331 Hz`, dominant `45.0 Hz`, `-10.0 dB` stereo RMS (`-10.1 dB` mono, peak `0.8 dBFS`). vs `wep_sunward_hbattery_0.ogg`: spectral cosine `0.839`, `T95` ratio `0.85x`, above-30 Hz deltas `+15/-9/-6%`.
  3. **Mono:** No loss; rock-solid mono. `corr +0.95`, fold loss `-0.12 dB` overall (`-0.01 dB` <500 Hz, `-0.22 dB` 500 Hz to 2 kHz, `-0.78 dB` >2 kHz, `-0.08 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `8.6 ms`, `T95 = 258 ms`, dur `1.0 s`.
- **Final answer (`wep_sunward_hbattery_more`):** **t2**

### 65. `wep_flak_airburst_more` (variety: 2 more takes of keeper wep_flak_airburst (B t1, its exact prompt) for the round robin, 0.5 s)

- **Today baseline:** `wep_flak_airburst_more_today0.ogg` (`-26.1 dB`, `28.0/50.8/21.2%`, `T95 57 ms`).
- **In-game keeper (`godot/audio/clips/wep_flak_airburst_0.ogg`):** `-22.6 dB` RMS, `69.0/19.5/11.5%` (<500 / 500-2k / >2k), centroid `3628 Hz`, `T95 153 ms`, dur `0.477 s`.
- **`wep_flak_airburst_more_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Tight sharp flak crack sibling (`cos 0.827`, `0.0 ms` onset) in pure mono that blends naturally with `wep_flak_airburst_0.ogg` after 40 Hz high-pass.
  2. **Bass (<500 Hz):** Yes (`86.5%` below 500 Hz stereo, `87.3%` mono). Measured stereo `86.5%` <500 Hz (`15.6%` <20 Hz), `8.3%` in 500 Hz to 2 kHz, `5.3%` >2 kHz; mono centroid `3645 Hz`, dominant `50.0 Hz`, `-12.1 dB` stereo RMS (`-12.1 dB` mono, peak `0.8 dBFS`). vs `wep_flak_airburst_0.ogg`: spectral cosine `0.827`, `T95` ratio `0.66x`, above-30 Hz deltas `+16/-10/-6%`.
  3. **Mono:** No loss; rock-solid mono. `corr +0.98`, fold loss `-0.04 dB` overall (`-0.00 dB` <500 Hz, `-0.03 dB` 500 Hz to 2 kHz, `-0.80 dB` >2 kHz, `-0.05 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `1.3 ms`, `T95 = 101 ms`, dur `0.48 s`. Tail tone scan: `3050 Hz` at `-54.7 dBFS` (`+27.1 dB` prominence at `150 ms`).
- **`wep_flak_airburst_more_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Much shorter hollow pop (`T95 84 ms`, `cos 0.347`) dominated by `49.8%` sub-20 Hz DC rumble and thin midrange.
  2. **Bass (<500 Hz):** Yes (`86.3%` below 500 Hz stereo, `86.3%` mono). Measured stereo `86.3%` <500 Hz (`49.8%` <20 Hz), `5.4%` in 500 Hz to 2 kHz, `8.3%` >2 kHz; mono centroid `4238 Hz`, dominant `12.5 Hz`, `-14.7 dB` stereo RMS (`-14.7 dB` mono, peak `-0.0 dBFS`). vs `wep_flak_airburst_0.ogg`: spectral cosine `0.347`, `T95` ratio `0.55x`, above-30 Hz deltas `+2/-8/+6%`.
  3. **Mono:** No loss; rock-solid mono. `corr +1.00`, fold loss `-0.00 dB` overall (`-0.00 dB` <500 Hz, `-0.00 dB` 500 Hz to 2 kHz, `-0.01 dB` >2 kHz, `-0.00 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `9.5 ms`, `T95 = 84 ms`, dur `0.48 s`.
- **Final answer (`wep_flak_airburst_more`):** **t1**

### 66. `wep_directorate_laser_b_more` (variety: 2 more takes of keeper wep_directorate_laser_b (A3 t1, its exact prompt) for the round robin, 0.7 s)

- **Today baseline:** `wep_directorate_laser_b_more_today0.ogg` (`-21.4 dB`, `86.3/3.0/10.8%`, `T95 148 ms`), `wep_directorate_laser_b_more_today1.ogg` (`-17.6 dB`, `75.6/8.8/15.6%`, `T95 279 ms`).
- **In-game keeper (`godot/audio/clips/wep_directorate_laser_0.ogg`):** `-22.0 dB` RMS, `78.5/8.1/13.4%` (<500 / 500-2k / >2k), centroid `4784 Hz`, `T95 314 ms`, dur `0.701 s`.
- **`wep_directorate_laser_b_more_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Darker (`91.7%` below 500 Hz) with a soft late swell peaking at `192.5 ms` instead of the keeper's immediate plasma snap.
  2. **Bass (<500 Hz):** Yes (`91.7%` below 500 Hz stereo, `93.5%` mono). Measured stereo `91.7%` <500 Hz (`0.0%` <20 Hz), `4.5%` in 500 Hz to 2 kHz, `3.7%` >2 kHz; mono centroid `4073 Hz`, dominant `125.0 Hz`, `-25.2 dB` stereo RMS (`-25.4 dB` mono, peak `-11.2 dBFS`). vs `wep_directorate_laser_0.ogg`: spectral cosine `0.816`, `T95` ratio `1.03x`, above-30 Hz deltas `+15/-5/-10%`.
  3. **Mono:** No loss; rock-solid mono. `corr +0.91`, fold loss `-0.21 dB` overall (`-0.12 dB` <500 Hz, `-1.37 dB` 500 Hz to 2 kHz, `-1.11 dB` >2 kHz, `-0.39 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `192.5 ms`, `T95 = 322 ms`, dur `0.68 s`.
- **`wep_directorate_laser_b_more_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Close plasma-cannon sibling (`cos 0.831`, `0.0 ms` onset, `pk 8.4 ms`, `T95 341 ms` vs `314 ms`) in pure mono once gain-matched.
  2. **Bass (<500 Hz):** Yes (`85.5%` below 500 Hz stereo, `86.6%` mono). Measured stereo `85.5%` <500 Hz (`0.1%` <20 Hz), `7.3%` in 500 Hz to 2 kHz, `7.2%` >2 kHz; mono centroid `3920 Hz`, dominant `86.7 Hz`, `-27.2 dB` stereo RMS (`-27.3 dB` mono, peak `-11.7 dBFS`). vs `wep_directorate_laser_0.ogg`: spectral cosine `0.831`, `T95` ratio `1.09x`, above-30 Hz deltas `+8/-1/-7%`.
  3. **Mono:** No loss; rock-solid mono. `corr +0.95`, fold loss `-0.11 dB` overall (`-0.06 dB` <500 Hz, `-0.10 dB` 500 Hz to 2 kHz, `-0.79 dB` >2 kHz, `-0.16 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `8.4 ms`, `T95 = 341 ms`, dur `0.68 s`.
- **Final answer (`wep_directorate_laser_b_more`):** **t2**

### 67. `wep_directorate_turbo_more` (variety: 2 more takes of keeper wep_directorate_turbo (B t2, its exact prompt) for the round robin, 0.85 s)

- **Today baseline:** `wep_directorate_turbo_more_today0.ogg` (`-21.4 dB`, `86.3/3.0/10.8%`, `T95 148 ms`), `wep_directorate_turbo_more_today1.ogg` (`-23.8 dB`, `0.2/0.8/99.1%`, `T95 380 ms`).
- **In-game keeper (`godot/audio/clips/wep_directorate_turbo_0.ogg`):** `-20.7 dB` RMS, `77.3/9.3/13.4%` (<500 / 500-2k / >2k), centroid `3818 Hz`, `T95 344 ms`, dur `0.861 s`.
- **`wep_directorate_turbo_more_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Close timbre (`cos 0.915`), but peaks late at `159 ms` and drops `-3.2 dB` of midrange and `-2.8 dB` of top end in mono.
  2. **Bass (<500 Hz):** Yes (`81.2%` below 500 Hz stereo, `89.0%` mono). Measured stereo `81.2%` <500 Hz (`0.0%` <20 Hz), `7.2%` in 500 Hz to 2 kHz, `11.6%` >2 kHz; mono centroid `3099 Hz`, dominant `114.3 Hz`, `-17.2 dB` stereo RMS (`-17.8 dB` mono, peak `-2.4 dBFS`). vs `wep_directorate_turbo_0.ogg`: spectral cosine `0.915`, `T95` ratio `1.36x`, above-30 Hz deltas `+12/-5/-6%`.
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.73`, fold loss `-0.63 dB` overall (`-0.23 dB` <500 Hz, `-3.24 dB` 500 Hz to 2 kHz, `-2.78 dB` >2 kHz, `-2.46 dB` attack 0 to 60 ms). Single channels: L `-17.4 dB` (pk `-2.7 dBFS`, `80.3/8.0/11.8%`), R `-17.1 dB` (pk `-2.4 dBFS`, `82.1/6.4/11.5%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.2 ms` at -30 dB, `7.9 ms` at -20 dB). Peak at `159.1 ms`, `T95 = 467 ms`, dur `0.84 s`.
- **`wep_directorate_turbo_more_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Dead-ringer medium-heavy plasma sibling (`cos 0.896`, `pk 19.8 ms`) in stereo, but loses `-2.3 dB` of midrange and `-2.1 dB` of attack in mono fold; channel L alone matches the keeper cleanly.
  2. **Bass (<500 Hz):** Yes (`80.9%` below 500 Hz stereo, `86.4%` mono). Measured stereo `80.9%` <500 Hz (`0.0%` <20 Hz), `8.4%` in 500 Hz to 2 kHz, `10.8%` >2 kHz; mono centroid `3667 Hz`, dominant `120.2 Hz`, `-22.7 dB` stereo RMS (`-23.1 dB` mono, peak `-2.3 dBFS`). vs `wep_directorate_turbo_0.ogg`: spectral cosine `0.896`, `T95` ratio `1.2x`, above-30 Hz deltas `+9/-4/-5%`.
  3. **Mono:** Mild softening; holds up cleanly by ear. `corr +0.82`, fold loss `-0.41 dB` overall (`-0.12 dB` <500 Hz, `-2.29 dB` 500 Hz to 2 kHz, `-1.63 dB` >2 kHz, `-2.09 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.3 ms` at -30 dB, `13.1 ms` at -20 dB). Peak at `19.8 ms`, `T95 = 412 ms`, dur `0.84 s`.
- **Final answer (`wep_directorate_turbo_more`):** **channel L of t2**

### 68. `wep_directorate_hturbo_more` (variety: 2 more takes of keeper wep_directorate_hturbo (B t1, its exact prompt) for the round robin, 1 s)

- **Today baseline:** `wep_directorate_hturbo_more_today0.ogg` (`-21.4 dB`, `86.3/3.0/10.8%`, `T95 148 ms`), `wep_directorate_hturbo_more_today1.ogg` (`-23.8 dB`, `0.2/0.8/99.1%`, `T95 380 ms`).
- **In-game keeper (`godot/audio/clips/wep_directorate_hturbo_0.ogg`):** `-21.9 dB` RMS, `83.4/3.4/13.2%` (<500 / 500-2k / >2k), centroid `4610 Hz`, `T95 410 ms`, dur `1.0 s`.
- **`wep_directorate_hturbo_more_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Dead-ringer heavy plasma blast sibling (`cos 0.878`, `83.4/6.8/9.9%`) in rock-solid mono, just slightly fuller in the tail.
  2. **Bass (<500 Hz):** Yes (`83.4%` below 500 Hz stereo, `84.6%` mono). Measured stereo `83.4%` <500 Hz (`0.1%` <20 Hz), `6.8%` in 500 Hz to 2 kHz, `9.9%` >2 kHz; mono centroid `3883 Hz`, dominant `99.0 Hz`, `-18.9 dB` stereo RMS (`-18.9 dB` mono, peak `-2.7 dBFS`). vs `wep_directorate_hturbo_0.ogg`: spectral cosine `0.878`, `T95` ratio `1.35x`, above-30 Hz deltas `+1/+3/-4%`.
  3. **Mono:** No loss; rock-solid mono. `corr +0.96`, fold loss `-0.08 dB` overall (`-0.02 dB` <500 Hz, `-0.22 dB` 500 Hz to 2 kHz, `-0.54 dB` >2 kHz, `-0.34 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`7.0 ms` at -40 dB, `10.9 ms` at -30 dB, `20.8 ms` at -20 dB). Peak at `234.0 ms`, `T95 = 555 ms`, dur `1.0 s`.
- **`wep_directorate_hturbo_more_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Equally close sibling (`cos 0.875`, `T95 479 ms` vs `410 ms`, `4.5 ms` onset) in pure mono once gain-matched.
  2. **Bass (<500 Hz):** Yes (`79.6%` below 500 Hz stereo, `79.9%` mono). Measured stereo `79.6%` <500 Hz (`0.0%` <20 Hz), `8.8%` in 500 Hz to 2 kHz, `11.6%` >2 kHz; mono centroid `4421 Hz`, dominant `151.0 Hz`, `-25.4 dB` stereo RMS (`-25.4 dB` mono, peak `-8.7 dBFS`). vs `wep_directorate_hturbo_0.ogg`: spectral cosine `0.875`, `T95` ratio `1.17x`, above-30 Hz deltas `-4/+5/-2%`.
  3. **Mono:** No loss; rock-solid mono. `corr +0.99`, fold loss `-0.02 dB` overall (`-0.00 dB` <500 Hz, `-0.02 dB` 500 Hz to 2 kHz, `-0.15 dB` >2 kHz, `-0.10 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`4.5 ms` at -40 dB, `6.8 ms` at -30 dB, `13.4 ms` at -20 dB). Peak at `59.1 ms`, `T95 = 479 ms`, dur `1.0 s`.
- **Final answer (`wep_directorate_hturbo_more`):** **t1 and t2**

### 69. `wep_directorate_picket_more` (variety: 2 more takes of keeper wep_directorate_picket (E t1, its exact prompt) for the round robin, 0.5 s)

- **Today baseline:** `wep_directorate_picket_more_today0.ogg` (`-26.1 dB`, `28.0/50.8/21.2%`, `T95 57 ms`).
- **In-game keeper (`godot/audio/clips/wep_directorate_picket_0.ogg`):** `-24.5 dB` RMS, `39.8/22.5/37.7%` (<500 / 500-2k / >2k), centroid `4467 Hz`, `T95 128 ms`, dur `0.453 s`.
- **`wep_directorate_picket_more_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Dead-ringer crisp point-defense laser crack (`30/20/51%`, `T95 98 ms`, `3.5 ms` onset) in rock-solid mono that matches `wep_directorate_picket_0.ogg` seamlessly.
  2. **Bass (<500 Hz):** No (`29.5%` below 500 Hz stereo, `29.7%` mono). Measured stereo `29.5%` <500 Hz (`0.0%` <20 Hz), `19.8%` in 500 Hz to 2 kHz, `50.6%` >2 kHz; mono centroid `4872 Hz`, dominant `120.8 Hz`, `-25.8 dB` stereo RMS (`-25.9 dB` mono, peak `-3.0 dBFS`). vs `wep_directorate_picket_0.ogg`: spectral cosine `0.621`, `T95` ratio `0.77x`, above-30 Hz deltas `-10/-2/+12%`.
  3. **Mono:** No loss; rock-solid mono. `corr +0.94`, fold loss `-0.13 dB` overall (`-0.11 dB` <500 Hz, `-0.06 dB` 500 Hz to 2 kHz, `-0.17 dB` >2 kHz, `-0.16 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`3.5 ms` at -40 dB, `6.3 ms` at -30 dB, `13.9 ms` at -20 dB). Peak at `26.2 ms`, `T95 = 98 ms`, dur `0.48 s`.
- **`wep_directorate_picket_more_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Much heavier and darker (`72.5%` below 500 Hz, nearly 2x longer `T95 185 ms`) so it sounds like a larger gun than the light picket bolt.
  2. **Bass (<500 Hz):** Yes (`72.5%` below 500 Hz stereo, `72.7%` mono). Measured stereo `72.5%` <500 Hz (`4.9%` <20 Hz), `14.1%` in 500 Hz to 2 kHz, `13.4%` >2 kHz; mono centroid `2838 Hz`, dominant `37.5 Hz`, `-20.2 dB` stereo RMS (`-20.2 dB` mono, peak `-1.8 dBFS`). vs `wep_directorate_picket_0.ogg`: spectral cosine `0.648`, `T95` ratio `1.45x`, above-30 Hz deltas `+30/-7/-23%`.
  3. **Mono:** No loss; rock-solid mono. `corr +0.99`, fold loss `-0.02 dB` overall (`-0.02 dB` <500 Hz, `-0.02 dB` 500 Hz to 2 kHz, `-0.06 dB` >2 kHz, `-0.01 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `53.2 ms`, `T95 = 185 ms`, dur `0.48 s`.
- **Final answer (`wep_directorate_picket_more`):** **t1**

### 70. `wep_hullbreaker_scatter_more` (variety: 2 more takes of keeper wep_hullbreaker_scatter (B t2, its exact prompt) for the round robin, 0.8 s)

- **Today baseline:** `wep_hullbreaker_scatter_more_today0.ogg` (`-21.6 dB`, `100.0/0.0/0.0%`, `T95 594 ms`), `wep_hullbreaker_scatter_more_today1.ogg` (`-21.8 dB`, `58.9/31.6/9.5%`, `T95 292 ms`).
- **In-game keeper (`godot/audio/clips/wep_hullbreaker_scatter_0.ogg`):** `-20.3 dB` RMS, `51.4/30.9/17.7%` (<500 / 500-2k / >2k), centroid `3615 Hz`, `T95 275 ms`, dur `0.823 s`.
- **`wep_hullbreaker_scatter_more_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Spot-on dirty scrap cannon blast and loose iron rattle (`cos 0.870`, `T95 282 ms` vs `275 ms`, `0.0 ms` onset) that holds up cleanly in mono once peak-trimmed.
  2. **Bass (<500 Hz):** Yes (`66.1%` below 500 Hz stereo, `68.1%` mono). Measured stereo `66.1%` <500 Hz (`0.3%` <20 Hz), `19.2%` in 500 Hz to 2 kHz, `14.7%` >2 kHz; mono centroid `3814 Hz`, dominant `46.2 Hz`, `-10.2 dB` stereo RMS (`-11.1 dB` mono, peak `1.4 dBFS`). vs `wep_hullbreaker_scatter_0.ogg`: spectral cosine `0.87`, `T95` ratio `1.03x`, above-30 Hz deltas `+16/-12/-5%`.
  3. **Mono:** Holds up cleanly with minor softening. `corr +0.64`, fold loss `-0.86 dB` overall (`-0.74 dB` <500 Hz, `-0.90 dB` 500 Hz to 2 kHz, `-1.43 dB` >2 kHz, `-1.24 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `71.9 ms`, `T95 = 282 ms`, dur `0.8 s`.
- **`wep_hullbreaker_scatter_more_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Matching scrap blast timbre (`cos 0.867`), but longer (`T95 415 ms`) and wide stereo drops `-1.7` to `-2.0 dB` across every band in mono.
  2. **Bass (<500 Hz):** No (`44.7%` below 500 Hz stereo, `46.2%` mono). Measured stereo `44.7%` <500 Hz (`0.4%` <20 Hz), `32.8%` in 500 Hz to 2 kHz, `22.5%` >2 kHz; mono centroid `3623 Hz`, dominant `28.8 Hz`, `-9.0 dB` stereo RMS (`-10.7 dB` mono, peak `1.2 dBFS`). vs `wep_hullbreaker_scatter_0.ogg`: spectral cosine `0.867`, `T95` ratio `1.51x`, above-30 Hz deltas `-7/+3/+4%`.
  3. **Mono:** Yes, loses punch. `corr +0.35`, fold loss `-1.70 dB` overall (`-1.55 dB` <500 Hz, `-1.70 dB` 500 Hz to 2 kHz, `-1.99 dB` >2 kHz, `-1.74 dB` attack 0 to 60 ms). Single channels: L `-8.9 dB` (pk `1.0 dBFS`, `56.5/26.8/16.7%`), R `-9.1 dB` (pk `1.2 dBFS`, `32.3/39.0/28.7%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `137.0 ms`, `T95 = 415 ms`, dur `0.8 s`.
- **Final answer (`wep_hullbreaker_scatter_more`):** **t1**

### 71. `wep_hullbreaker_junk_gun_more` (variety: 2 more takes of keeper wep_hullbreaker_junk_gun (D t2, its exact prompt) for the round robin, 0.6 s)

- **Today baseline:** `wep_hullbreaker_junk_gun_more_today0.ogg` (`-21.6 dB`, `100.0/0.0/0.0%`, `T95 594 ms`), `wep_hullbreaker_junk_gun_more_today1.ogg` (`-21.8 dB`, `58.9/31.6/9.5%`, `T95 292 ms`).
- **In-game keeper (`godot/audio/clips/wep_hullbreaker_junk_gun_0.ogg`):** `-22.3 dB` RMS, `6.1/43.0/50.9%` (<500 / 500-2k / >2k), centroid `5062 Hz`, `T95 199 ms`, dur `0.597 s`.
- **`wep_hullbreaker_junk_gun_more_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Dead-ringer rough clanking scrap turret sibling (`cos 0.919`, `0.0 ms` onset, zero high tinnitus whine) in clean mono once 40 Hz high-passed and peak-trimmed.
  2. **Bass (<500 Hz):** No (`12.3%` below 500 Hz stereo, `13.3%` mono). Measured stereo `12.3%` <500 Hz (`11.5%` <20 Hz), `38.9%` in 500 Hz to 2 kHz, `48.8%` >2 kHz; mono centroid `4879 Hz`, dominant `1155.0 Hz`, `-14.8 dB` stereo RMS (`-15.2 dB` mono, peak `1.2 dBFS`). vs `wep_hullbreaker_junk_gun_0.ogg`: spectral cosine `0.919`, `T95` ratio `1.25x`, above-30 Hz deltas `-4/+4/+0%`.
  3. **Mono:** Holds up cleanly with minor softening. `corr +0.78`, fold loss `-0.49 dB` overall (`-0.13 dB` <500 Hz, `-0.20 dB` 500 Hz to 2 kHz, `-0.78 dB` >2 kHz, `-0.60 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `2.8 ms`, `T95 = 249 ms`, dur `0.6 s`.
- **`wep_hullbreaker_junk_gun_more_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Carries `71.2%` sub-20 Hz DC rumble, a 6.7 dB left-right imbalance, and loses `-2.5 dB` of top end in mono.
  2. **Bass (<500 Hz):** No above 30 Hz (raw `74.8%` below 500 Hz is skewed by `71.2%` sub-20 Hz DC/rumble; above 30 Hz it is `11.1%` in 30 to 500 Hz, `29.5%` in 500 Hz to 2 kHz, `59.4%` above 2 kHz). Measured stereo `74.8%` <500 Hz (`71.2%` <20 Hz), `8.4%` in 500 Hz to 2 kHz, `16.8%` >2 kHz; mono centroid `4306 Hz`, dominant `1.7 Hz`, `-15.4 dB` stereo RMS (`-16.9 dB` mono, peak `0.5 dBFS`). vs `wep_hullbreaker_junk_gun_0.ogg`: spectral cosine `0.784`, `T95` ratio `1.02x`, above-30 Hz deltas `+6/-10/+3%`.
  3. **Mono:** Mild softening; holds up cleanly by ear. `corr +0.44`, fold loss `-1.50 dB` overall (`-1.21 dB` <500 Hz, `-1.50 dB` 500 Hz to 2 kHz, `-2.49 dB` >2 kHz, `-1.62 dB` attack 0 to 60 ms). L/R imbalance `-6.7 dB` (`L -19.9 dB`, `R -13.2 dB`). Single channels: L `-19.9 dB` (pk `-0.5 dBFS`, `39.7/20.9/39.4%`), R `-13.2 dB` (pk `0.5 dBFS`, `81.2/6.1/12.7%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `7.5 ms`, `T95 = 202 ms`, dur `0.6 s`.
- **Final answer (`wep_hullbreaker_junk_gun_more`):** **t1**

### 72. `wep_chorus_spines_more` (variety: 2 more takes of keeper wep_chorus_spines (A3 t2, its exact prompt) for the round robin, 0.8 s)

- **Today baseline:** `wep_chorus_spines_more_today0.ogg` (`-30.5 dB`, `13.3/6.4/80.3%`, `T95 137 ms`).
- **In-game keeper (`godot/audio/clips/wep_chorus_spines_0.ogg`):** `-23.8 dB` RMS, `79.0/16.0/5.0%` (<500 / 500-2k / >2k), centroid `2418 Hz`, `T95 386 ms`, dur `0.797 s`.
- **`wep_chorus_spines_more_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Far too thin, quiet (`-31.9 dB`), and short (`T95 153 ms` vs `386 ms`), reading as a dry snap instead of `wep_chorus_spines_0.ogg`'s heavy spine launch.
  2. **Bass (<500 Hz):** No (`25.0%` below 500 Hz stereo, `25.3%` mono). Measured stereo `25.0%` <500 Hz (`0.1%` <20 Hz), `32.6%` in 500 Hz to 2 kHz, `42.5%` >2 kHz; mono centroid `4213 Hz`, dominant `28.8 Hz`, `-31.9 dB` stereo RMS (`-32.0 dB` mono, peak `-5.7 dBFS`). vs `wep_chorus_spines_0.ogg`: spectral cosine `0.481`, `T95` ratio `0.4x`, above-30 Hz deltas `-56/+18/+38%`.
  3. **Mono:** No loss; rock-solid mono. `corr +0.95`, fold loss `-0.11 dB` overall (`-0.05 dB` <500 Hz, `-0.04 dB` 500 Hz to 2 kHz, `-0.19 dB` >2 kHz, `-0.07 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `3.0 ms`, `T95 = 153 ms`, dur `0.8 s`.
- **`wep_chorus_spines_more_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Matching hard bone crack and pressurized launch rush (`cos 0.874`, `T95 370 ms` vs `386 ms`, `0.0 ms` onset) in rock-solid mono.
  2. **Bass (<500 Hz):** No (`47.1%` below 500 Hz stereo, `48.4%` mono). Measured stereo `47.1%` <500 Hz (`0.3%` <20 Hz), `29.1%` in 500 Hz to 2 kHz, `23.8%` >2 kHz; mono centroid `3463 Hz`, dominant `355.0 Hz`, `-25.1 dB` stereo RMS (`-25.3 dB` mono, peak `-5.4 dBFS`). vs `wep_chorus_spines_0.ogg`: spectral cosine `0.874`, `T95` ratio `0.96x`, above-30 Hz deltas `-31/+14/+17%`.
  3. **Mono:** No loss; rock-solid mono. `corr +0.94`, fold loss `-0.13 dB` overall (`-0.02 dB` <500 Hz, `-0.02 dB` 500 Hz to 2 kHz, `-0.51 dB` >2 kHz, `-0.05 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `11.5 ms`, `T95 = 370 ms`, dur `0.8 s`.
- **Final answer (`wep_chorus_spines_more`):** **t2**

### 73. `wep_chorus_spore_cloud_more` (variety: 2 more takes of keeper wep_chorus_spore_cloud (C t2, its exact prompt) for the round robin, 0.9 s)

- **Today baseline:** `wep_chorus_spore_cloud_more_today0.ogg` (`-26.1 dB`, `28.0/50.8/21.2%`, `T95 57 ms`).
- **In-game keeper (`godot/audio/clips/wep_chorus_spore_cloud_0.ogg`):** `-24.4 dB` RMS, `81.8/7.6/10.7%` (<500 / 500-2k / >2k), centroid `4131 Hz`, `T95 173 ms`, dur `0.877 s`.
- **`wep_chorus_spore_cloud_more_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Natural woody pod pop and seed-husk puff (`cos 0.798`, `81/9/10%`), but wide stereo collapses `-2.7 dB` in mono; channel R alone is a dead-ringer sibling.
  2. **Bass (<500 Hz):** Yes (`81.3%` below 500 Hz stereo, `76.9%` mono). Measured stereo `81.3%` <500 Hz (`0.0%` <20 Hz), `8.9%` in 500 Hz to 2 kHz, `9.9%` >2 kHz; mono centroid `3776 Hz`, dominant `122.7 Hz`, `-21.0 dB` stereo RMS (`-23.6 dB` mono, peak `-1.4 dBFS`). vs `wep_chorus_spore_cloud_0.ogg`: spectral cosine `0.798`, `T95` ratio `0.76x`, above-30 Hz deltas `-5/+4/+1%`.
  3. **Mono:** Yes, loses punch. `corr +0.09`, fold loss `-2.66 dB` overall (`-2.90 dB` <500 Hz, `-1.51 dB` 500 Hz to 2 kHz, `-1.99 dB` >2 kHz, `-1.86 dB` attack 0 to 60 ms). L/R imbalance `-3.2 dB` (`L -22.8 dB`, `R -19.7 dB`). Single channels: L `-22.8 dB` (pk `-2.8 dBFS`, `78.0/9.6/12.4%`), R `-19.7 dB` (pk `-1.4 dBFS`, `82.8/8.5/8.7%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.3 ms` at -20 dB). Peak at `15.6 ms`, `T95 = 131 ms`, dur `0.88 s`.
- **`wep_chorus_spore_cloud_more_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Much brighter hissy character (`45.2%` above 2 kHz, `cos 0.563`) and fails mono at `corr +0.07`.
  2. **Bass (<500 Hz):** No (`43.3%` below 500 Hz stereo, `44.3%` mono). Measured stereo `43.3%` <500 Hz (`0.2%` <20 Hz), `11.6%` in 500 Hz to 2 kHz, `45.2%` >2 kHz; mono centroid `4758 Hz`, dominant `120.5 Hz`, `-22.7 dB` stereo RMS (`-25.4 dB` mono, peak `-0.5 dBFS`). vs `wep_chorus_spore_cloud_0.ogg`: spectral cosine `0.563`, `T95` ratio `0.79x`, above-30 Hz deltas `-38/+5/+33%`.
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.07`, fold loss `-2.71 dB` overall (`-2.61 dB` <500 Hz, `-2.33 dB` 500 Hz to 2 kHz, `-2.92 dB` >2 kHz, `-2.79 dB` attack 0 to 60 ms). Single channels: L `-22.2 dB` (pk `-0.5 dBFS`, `45.2/9.9/44.8%`), R `-23.2 dB` (pk `-0.7 dBFS`, `40.8/13.6/45.6%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `65.2 ms`, `T95 = 137 ms`, dur `0.88 s`.
- **Final answer (`wep_chorus_spore_cloud_more`):** **channel R of t1**

### 74. `wep_chorus_sporeb_more` (variety: 2 more takes of keeper wep_chorus_sporeb (C t1, its exact prompt) for the round robin, 0.6 s)

- **Today baseline:** `wep_chorus_sporeb_more_today0.ogg` (`-16.5 dB`, `60.3/33.5/6.2%`, `T95 158 ms`).
- **In-game keeper (`godot/audio/clips/wep_chorus_sporeb_0.ogg`):** `-24.1 dB` RMS, `88.6/6.3/5.2%` (<500 / 500-2k / >2k), centroid `3386 Hz`, `T95 78 ms`, dur `0.597 s`.
- **`wep_chorus_sporeb_more_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Very quiet (`-33.9 dB`) and muffled (`98.7%` below 500 Hz), losing the crisp woody bone-pod pop of `wep_chorus_sporeb_0.ogg`.
  2. **Bass (<500 Hz):** Yes (`98.7%` below 500 Hz stereo, `98.7%` mono). Measured stereo `98.7%` <500 Hz (`0.0%` <20 Hz), `1.0%` in 500 Hz to 2 kHz, `0.2%` >2 kHz; mono centroid `1308 Hz`, dominant `175.0 Hz`, `-33.9 dB` stereo RMS (`-33.9 dB` mono, peak `-17.3 dBFS`). vs `wep_chorus_sporeb_0.ogg`: spectral cosine `0.89`, `T95` ratio `2.09x`, above-30 Hz deltas `+10/-5/-5%`.
  3. **Mono:** No loss; rock-solid mono. `corr +1.00`, fold loss `-0.00 dB` overall (`-0.00 dB` <500 Hz, `-0.02 dB` 500 Hz to 2 kHz, `-0.05 dB` >2 kHz, `-0.00 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.2 ms` at -20 dB). Peak at `5.2 ms`, `T95 = 163 ms`, dur `0.6 s`.
- **`wep_chorus_sporeb_more_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Matching hollow bone-pod pop and puff (`cos 0.885`, `0.0 ms` onset) in pure mono, with a slightly longer woody rattle (`210 ms` vs `78 ms`) that still blends cleanly.
  2. **Bass (<500 Hz):** Yes (`89.7%` below 500 Hz stereo, `89.9%` mono). Measured stereo `89.7%` <500 Hz (`0.0%` <20 Hz), `2.5%` in 500 Hz to 2 kHz, `7.8%` >2 kHz; mono centroid `2285 Hz`, dominant `133.3 Hz`, `-27.6 dB` stereo RMS (`-27.6 dB` mono, peak `-6.0 dBFS`). vs `wep_chorus_sporeb_0.ogg`: spectral cosine `0.885`, `T95` ratio `2.69x`, above-30 Hz deltas `+1/-4/+2%`.
  3. **Mono:** No loss; rock-solid mono. `corr +0.99`, fold loss `-0.01 dB` overall (`-0.01 dB` <500 Hz, `-0.04 dB` 500 Hz to 2 kHz, `-0.09 dB` >2 kHz, `-0.02 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `3.6 ms`, `T95 = 210 ms`, dur `0.6 s`.
- **Final answer (`wep_chorus_sporeb_more`):** **t2**

### 75. `wep_ithar_shard_more` (variety: 2 more takes of keeper wep_ithar_shard (A3 t1, its exact prompt) for the round robin, 0.8 s)

- **Today baseline:** `wep_ithar_shard_more_today0.ogg` (`-16.5 dB`, `60.3/33.5/6.2%`, `T95 158 ms`), `wep_ithar_shard_more_today1.ogg` (`-22.0 dB`, `2.5/93.6/3.8%`, `T95 35 ms`).
- **In-game keeper (`godot/audio/clips/wep_ithar_shard_0.ogg`):** `-22.6 dB` RMS, `74.2/15.2/10.5%` (<500 / 500-2k / >2k), centroid `3266 Hz`, `T95 301 ms`, dur `0.79 s`.
- **`wep_ithar_shard_more_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Matching crystalline ice-crack (`cos 0.753`), but wide stereo drops `-2.4 dB` of low body in mono; channel L alone is clean.
  2. **Bass (<500 Hz):** Yes (`79.7%` below 500 Hz stereo, `72.4%` mono). Measured stereo `79.7%` <500 Hz (`0.0%` <20 Hz), `10.9%` in 500 Hz to 2 kHz, `9.3%` >2 kHz; mono centroid `3447 Hz`, dominant `156.2 Hz`, `-18.7 dB` stereo RMS (`-20.6 dB` mono, peak `-1.3 dBFS`). vs `wep_ithar_shard_0.ogg`: spectral cosine `0.753`, `T95` ratio `0.67x`, above-30 Hz deltas `-2/-0/+2%`.
  3. **Mono:** Yes, loses punch. `corr +0.29`, fold loss `-1.93 dB` overall (`-2.35 dB` <500 Hz, `-0.65 dB` 500 Hz to 2 kHz, `-0.53 dB` >2 kHz, `-0.38 dB` attack 0 to 60 ms). Single channels: L `-19.5 dB` (pk `-2.4 dBFS`, `75.9/12.7/11.5%`), R `-18.0 dB` (pk `-1.3 dBFS`, `82.5/9.7/7.8%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `7.4 ms` at -30 dB, `11.4 ms` at -20 dB). Peak at `123.0 ms`, `T95 = 202 ms`, dur `0.8 s`.
- **`wep_ithar_shard_more_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Close crystal shard sibling (`cos 0.827`, `0.0 ms` onset, `T95 229 ms` vs `301 ms`) whose midrange holds solid (`-0.1 dB`) in mono.
  2. **Bass (<500 Hz):** Yes (`88.0%` below 500 Hz stereo, `86.1%` mono). Measured stereo `88.0%` <500 Hz (`1.8%` <20 Hz), `6.1%` in 500 Hz to 2 kHz, `5.9%` >2 kHz; mono centroid `2434 Hz`, dominant `51.2 Hz`, `-17.5 dB` stereo RMS (`-18.6 dB` mono, peak `-1.2 dBFS`). vs `wep_ithar_shard_0.ogg`: spectral cosine `0.827`, `T95` ratio `0.76x`, above-30 Hz deltas `+11/-7/-4%`.
  3. **Mono:** Mild softening; holds up cleanly by ear. `corr +0.53`, fold loss `-1.17 dB` overall (`-1.27 dB` <500 Hz, `-0.12 dB` 500 Hz to 2 kHz, `-1.02 dB` >2 kHz, `-0.44 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `93.3 ms`, `T95 = 229 ms`, dur `0.8 s`.
- **Final answer (`wep_ithar_shard_more`):** **t2**

### 76. `wep_ithar_needle_more` (variety: 2 more takes of keeper wep_ithar_needle (B t1, its exact prompt) for the round robin, 0.8 s)

- **Today baseline:** `wep_ithar_needle_more_today0.ogg` (`-16.5 dB`, `60.3/33.5/6.2%`, `T95 158 ms`), `wep_ithar_needle_more_today1.ogg` (`-22.0 dB`, `2.5/93.6/3.8%`, `T95 35 ms`).
- **In-game keeper (`godot/audio/clips/wep_ithar_needle_0.ogg`):** `-23.0 dB` RMS, `79.6/7.0/13.3%` (<500 / 500-2k / >2k), centroid `3269 Hz`, `T95 304 ms`, dur `0.797 s`.
- **`wep_ithar_needle_more_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Matching thin prism snap and pure glass note (`cos 0.791`, `T95 263 ms`) in pure mono once 50 Hz high-passed and given the keeper's presence EQ.
  2. **Bass (<500 Hz):** Yes (`91.3%` below 500 Hz stereo, `91.4%` mono). Measured stereo `91.3%` <500 Hz (`9.8%` <20 Hz), `1.3%` in 500 Hz to 2 kHz, `7.3%` >2 kHz; mono centroid `3645 Hz`, dominant `120.0 Hz`, `-26.4 dB` stereo RMS (`-26.4 dB` mono, peak `-8.9 dBFS`). vs `wep_ithar_needle_0.ogg`: spectral cosine `0.791`, `T95` ratio `0.87x`, above-30 Hz deltas `+11/-6/-5%`.
  3. **Mono:** No loss; rock-solid mono. `corr +1.00`, fold loss `-0.00 dB` overall (`-0.00 dB` <500 Hz, `-0.01 dB` 500 Hz to 2 kHz, `-0.04 dB` >2 kHz, `-0.01 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `14.1 ms`, `T95 = 263 ms`, dur `0.8 s`.
- **`wep_ithar_needle_more_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Cleaner, fuller luminous sibling (`cos 0.804`, `T95 238 ms`, `0.0 ms` onset) in pure mono that pairs seamlessly with `wep_ithar_needle_0.ogg` after the keeper's EQ.
  2. **Bass (<500 Hz):** Yes (`90.6%` below 500 Hz stereo, `90.8%` mono). Measured stereo `90.6%` <500 Hz (`0.1%` <20 Hz), `2.9%` in 500 Hz to 2 kHz, `6.5%` >2 kHz; mono centroid `2961 Hz`, dominant `122.5 Hz`, `-19.7 dB` stereo RMS (`-19.7 dB` mono, peak `-3.8 dBFS`). vs `wep_ithar_needle_0.ogg`: spectral cosine `0.804`, `T95` ratio `0.78x`, above-30 Hz deltas `+11/-4/-7%`.
  3. **Mono:** No loss; rock-solid mono. `corr +0.99`, fold loss `-0.03 dB` overall (`-0.02 dB` <500 Hz, `-0.10 dB` 500 Hz to 2 kHz, `-0.10 dB` >2 kHz, `-0.03 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.1 ms` at -20 dB). Peak at `30.3 ms`, `T95 = 238 ms`, dur `0.8 s`.
- **Final answer (`wep_ithar_needle_more`):** **t1 and t2**

### 77. `wep_eclipse_gsentry_more` (variety: 2 more takes of keeper wep_eclipse_gsentry (D t2, its exact prompt) for the round robin, 0.6 s)

- **Today baseline:** `wep_eclipse_gsentry_more_today0.ogg` (`-21.6 dB`, `100.0/0.0/0.0%`, `T95 594 ms`), `wep_eclipse_gsentry_more_today1.ogg` (`-20.5 dB`, `87.0/9.3/3.7%`, `T95 17 ms`).
- **In-game keeper (`godot/audio/clips/wep_eclipse_gsentry_0.ogg`):** `-23.3 dB` RMS, `37.4/18.1/44.5%` (<500 / 500-2k / >2k), centroid `7103 Hz`, `T95 162 ms`, dur `0.597 s`.
- **`wep_eclipse_gsentry_more_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Whisper-quiet (`-39.6 dB`, 16.3 dB below `wep_eclipse_gsentry_0.ogg`) wispy tick (`cos 0.286`) that cannot join the round robin.
  2. **Bass (<500 Hz):** No (`35.8%` below 500 Hz stereo, `37.2%` mono). Measured stereo `35.8%` <500 Hz (`1.1%` <20 Hz), `16.0%` in 500 Hz to 2 kHz, `48.2%` >2 kHz; mono centroid `7736 Hz`, dominant `98.3 Hz`, `-39.6 dB` stereo RMS (`-40.7 dB` mono, peak `-14.6 dBFS`). vs `wep_eclipse_gsentry_0.ogg`: spectral cosine `0.286`, `T95` ratio `1.19x`, above-30 Hz deltas `-2/-6/+7%`.
  3. **Mono:** Mild softening; holds up cleanly by ear. `corr +0.56`, fold loss `-1.09 dB` overall (`-0.93 dB` <500 Hz, `-2.29 dB` 500 Hz to 2 kHz, `-0.87 dB` >2 kHz, `-1.05 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `2.7 ms`, `T95 = 192 ms`, dur `0.6 s`.
- **`wep_eclipse_gsentry_more_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Much darker (`76.6%` below 500 Hz, `cos 0.132`) and phase-inverted (`corr -0.13`) so it collapses `-3.6 dB` in mono.
  2. **Bass (<500 Hz):** Yes (`76.6%` below 500 Hz stereo, `72.8%` mono). Measured stereo `76.6%` <500 Hz (`5.4%` <20 Hz), `8.1%` in 500 Hz to 2 kHz, `15.3%` >2 kHz; mono centroid `5861 Hz`, dominant `40.0 Hz`, `-24.9 dB` stereo RMS (`-28.5 dB` mono, peak `-2.6 dBFS`). vs `wep_eclipse_gsentry_0.ogg`: spectral cosine `0.132`, `T95` ratio `0.7x`, above-30 Hz deltas `+30/-8/-22%`.
  3. **Mono:** Yes, loses top end/midrange and punch. `corr -0.13`, fold loss `-3.57 dB` overall (`-3.78 dB` <500 Hz, `-3.34 dB` 500 Hz to 2 kHz, `-2.72 dB` >2 kHz, `-3.57 dB` attack 0 to 60 ms). L/R imbalance `-2.5 dB` (`L -26.4 dB`, `R -23.8 dB`). Single channels: L `-26.4 dB` (pk `-2.6 dBFS`, `66.0/10.9/23.1%`), R `-23.8 dB` (pk `-5.1 dBFS`, `82.4/6.6/10.9%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `51.8 ms`, `T95 = 113 ms`, dur `0.6 s`.
- **Final answer (`wep_eclipse_gsentry_more`):** **re-roll: lead with a loud crisp high-voltage snap and drop heavy obsidian weight words so takes match `wep_eclipse_gsentry_0.ogg`'s level and 45% >2 kHz bite.**

### 78. `wep_eclipse_gauss_fire_ctl_more` (variety: 2 more takes of keeper wep_eclipse_gauss_fire_ctl (A3 t2, its exact prompt) for the round robin, 0.9 s)

- **Today baseline:** `wep_eclipse_gauss_fire_ctl_more_today0.ogg` (`-21.6 dB`, `100.0/0.0/0.0%`, `T95 594 ms`), `wep_eclipse_gauss_fire_ctl_more_today1.ogg` (`-20.5 dB`, `87.0/9.3/3.7%`, `T95 17 ms`).
- **In-game keeper (`godot/audio/clips/wep_eclipse_gauss_fire_0.ogg`):** `-21.9 dB` RMS, `91.4/2.5/6.2%` (<500 / 500-2k / >2k), centroid `3975 Hz`, `T95 223 ms`, dur `0.877 s`.
- **`wep_eclipse_gauss_fire_ctl_more_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Matching seismic void snap and sub-bass drop (`cos 0.861`), but wide stereo drops `-3.2` to `-4.1 dB` of mids and highs in mono with a 4.9 dB L/R split.
  2. **Bass (<500 Hz):** Yes (`90.8%` below 500 Hz stereo, `93.7%` mono). Measured stereo `90.8%` <500 Hz (`0.9%` <20 Hz), `4.1%` in 500 Hz to 2 kHz, `5.1%` >2 kHz; mono centroid `3536 Hz`, dominant `109.1 Hz`, `-18.8 dB` stereo RMS (`-20.8 dB` mono, peak `-0.9 dBFS`). vs `wep_eclipse_gauss_fire_0.ogg`: spectral cosine `0.861`, `T95` ratio `0.98x`, above-30 Hz deltas `+2/+1/-3%`.
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.28`, fold loss `-2.07 dB` overall (`-1.94 dB` <500 Hz, `-3.22 dB` 500 Hz to 2 kHz, `-4.08 dB` >2 kHz, `-1.80 dB` attack 0 to 60 ms). L/R imbalance `-4.9 dB` (`L -21.9 dB`, `R -17.0 dB`). Single channels: L `-21.9 dB` (pk `-0.9 dBFS`, `69.9/13.3/16.9%`), R `-17.0 dB` (pk `-2.4 dBFS`, `97.6/1.1/1.3%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.2 ms` at -30 dB, `0.2 ms` at -20 dB). Peak at `18.0 ms`, `T95 = 219 ms`, dur `0.88 s`.
- **`wep_eclipse_gauss_fire_ctl_more_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Dead-ringer seismic null-cannon sibling (`cos 0.909`, `3.7 ms` onset), but wide stereo drops `-2.9 dB` of midrange in mono fold; channel R alone matches the keeper's band split cleanly.
  2. **Bass (<500 Hz):** Yes (`83.0%` below 500 Hz stereo, `85.8%` mono). Measured stereo `83.0%` <500 Hz (`0.1%` <20 Hz), `6.8%` in 500 Hz to 2 kHz, `10.2%` >2 kHz; mono centroid `3796 Hz`, dominant `169.3 Hz`, `-18.1 dB` stereo RMS (`-19.9 dB` mono, peak `-1.4 dBFS`). vs `wep_eclipse_gauss_fire_0.ogg`: spectral cosine `0.909`, `T95` ratio `1.3x`, above-30 Hz deltas `-6/+3/+3%`.
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.39`, fold loss `-1.81 dB` overall (`-1.67 dB` <500 Hz, `-2.86 dB` 500 Hz to 2 kHz, `-2.43 dB` >2 kHz, `-1.83 dB` attack 0 to 60 ms). L/R imbalance `-5.8 dB` (`L -21.9 dB`, `R -16.1 dB`). Single channels: L `-21.9 dB` (pk `-2.0 dBFS`, `41.3/21.1/37.6%`), R `-16.1 dB` (pk `-1.4 dBFS`, `93.9/3.1/3.0%`).
  4. **Onset (<=30 ms):** Yes, immediate (`3.7 ms` at -40 dB, `5.5 ms` at -30 dB, `13.4 ms` at -20 dB). Peak at `33.8 ms`, `T95 = 289 ms`, dur `0.88 s`.
- **Final answer (`wep_eclipse_gauss_fire_ctl_more`):** **channel R of t2**

### 79. `wep_craft_guns_more` (variety: 2 more takes of keeper wep_craft_guns (B t2, its exact prompt) for the round robin, 0.6 s)

- **Today baseline:** `wep_craft_guns_more_today0.ogg` (`-16.5 dB`, `60.3/33.5/6.2%`, `T95 158 ms`).
- **In-game keeper (`godot/audio/clips/wep_craft_guns_0.ogg`):** `-22.5 dB` RMS, `75.9/14.7/9.3%` (<500 / 500-2k / >2k), centroid `4259 Hz`, `T95 150 ms`, dur `0.597 s`.
- **`wep_craft_guns_more_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Collapses to one short `99 ms` pop (vs the keeper's `150 ms` multi-round burst) with `45.6%` sub-20 Hz DC rumble.
  2. **Bass (<500 Hz):** Yes (`82.7%` below 500 Hz stereo, `84.3%` mono). Measured stereo `82.7%` <500 Hz (`45.6%` <20 Hz), `7.7%` in 500 Hz to 2 kHz, `9.5%` >2 kHz; mono centroid `3764 Hz`, dominant `13.3 Hz`, `-16.4 dB` stereo RMS (`-16.6 dB` mono, peak `0.1 dBFS`). vs `wep_craft_guns_0.ogg`: spectral cosine `0.642`, `T95` ratio `0.66x`, above-30 Hz deltas `-9/+1/+8%`.
  3. **Mono:** No loss; rock-solid mono. `corr +0.88`, fold loss `-0.27 dB` overall (`-0.19 dB` <500 Hz, `-0.37 dB` 500 Hz to 2 kHz, `-0.93 dB` >2 kHz, `-0.27 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `3.8 ms`, `T95 = 99 ms`, dur `0.6 s`.
- **`wep_craft_guns_more_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Also a compressed `98 ms` pop peaking late at `90 ms` (`cos 0.587`) with `23.2%` sub-20 Hz rumble instead of a rapid multi-round fighter burst.
  2. **Bass (<500 Hz):** Yes (`73.7%` below 500 Hz stereo, `73.9%` mono). Measured stereo `73.7%` <500 Hz (`23.2%` <20 Hz), `14.1%` in 500 Hz to 2 kHz, `12.2%` >2 kHz; mono centroid `5071 Hz`, dominant `1.7 Hz`, `-13.5 dB` stereo RMS (`-13.5 dB` mono, peak `1.2 dBFS`). vs `wep_craft_guns_0.ogg`: spectral cosine `0.587`, `T95` ratio `0.65x`, above-30 Hz deltas `-11/+4/+7%`.
  3. **Mono:** No loss; rock-solid mono. `corr +0.98`, fold loss `-0.04 dB` overall (`-0.03 dB` <500 Hz, `-0.02 dB` 500 Hz to 2 kHz, `-0.11 dB` >2 kHz, `-0.05 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `3.2 ms` at -30 dB, `9.2 ms` at -20 dB). Peak at `89.9 ms`, `T95 = 98 ms`, dur `0.6 s`.
- **Final answer (`wep_craft_guns_more`):** **re-roll: ask explicitly for a tight three-round rapid fighter cannon burst lasting about 200 ms so takes match `wep_craft_guns_0.ogg`'s burst cadence instead of collapsing to one short pop.**

### 80. `ui_confirm_latch_more` (variety: 2 more takes of keeper ui_confirm_latch (B t1, its exact prompt) for the round robin, 0.5 s)

- **Today baseline:** `ui_confirm_latch_more_today0.ogg` (`-30.0 dB`, `1.5/12.0/86.5%`, `T95 190 ms`).
- **In-game keeper (`godot/audio/clips/ui_confirm_latch_0.ogg`):** `-30.0 dB` RMS, `1.5/12.0/86.5%` (<500 / 500-2k / >2k), centroid `5429 Hz`, `T95 190 ms`, dur `0.462 s`.
- **`ui_confirm_latch_more_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Matching two-stage console lever clunk (`cos 0.743`), but wide stereo loses `-2.0` to `-2.4 dB` in mono (usable only if kept stereo like `ui_confirm_latch_0.ogg`).
  2. **Bass (<500 Hz):** No (`14.6%` below 500 Hz stereo, `19.3%` mono). Measured stereo `14.6%` <500 Hz (`0.0%` <20 Hz), `14.5%` in 500 Hz to 2 kHz, `71.0%` >2 kHz; mono centroid `5040 Hz`, dominant `104.2 Hz`, `-29.4 dB` stereo RMS (`-31.4 dB` mono, peak `-3.0 dBFS`). vs `ui_confirm_latch_0.ogg`: spectral cosine `0.743`, `T95` ratio `0.89x`, above-30 Hz deltas `+18/+3/-20%`.
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.25`, fold loss `-2.05 dB` overall (`-0.83 dB` <500 Hz, `-2.01 dB` 500 Hz to 2 kHz, `-2.36 dB` >2 kHz, `-2.07 dB` attack 0 to 60 ms). Single channels: L `-29.3 dB` (pk `-5.1 dBFS`, `17.9/16.8/65.3%`), R `-29.5 dB` (pk `-3.0 dBFS`, `11.1/12.0/76.9%`).
  4. **Onset (<=30 ms):** Yes, within 30 ms (`14.2 ms` at -40 dB, `23.9 ms` at -30 dB, `29.6 ms` at -20 dB; trim ~`14 ms` head for tight sync). Peak at `142.5 ms`, `T95 = 170 ms`, dur `0.48 s`.
- **`ui_confirm_latch_more_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Dead-ringer sibling (`cos 0.881`, `T95 160 ms` vs `190 ms`, `6/8/86%`) in rock-solid mono that blends seamlessly into the round robin.
  2. **Bass (<500 Hz):** No (`6.0%` below 500 Hz stereo, `5.9%` mono). Measured stereo `6.0%` <500 Hz (`0.0%` <20 Hz), `8.2%` in 500 Hz to 2 kHz, `85.8%` >2 kHz; mono centroid `5596 Hz`, dominant `3308.3 Hz`, `-28.1 dB` stereo RMS (`-28.4 dB` mono, peak `-1.4 dBFS`). vs `ui_confirm_latch_0.ogg`: spectral cosine `0.881`, `T95` ratio `0.84x`, above-30 Hz deltas `+4/-4/-0%`.
  3. **Mono:** No loss; rock-solid mono. `corr +0.89`, fold loss `-0.24 dB` overall (`-0.31 dB` <500 Hz, `-0.39 dB` 500 Hz to 2 kHz, `-0.22 dB` >2 kHz, `-0.07 dB` attack 0 to 60 ms).
  4. **Onset (<=30 ms):** Yes, within 30 ms (`11.8 ms` at -40 dB, `16.8 ms` at -30 dB, `17.3 ms` at -20 dB; trim ~`11 ms` head for tight sync). Peak at `138.3 ms`, `T95 = 160 ms`, dur `0.48 s`.
- **Final answer (`ui_confirm_latch_more`):** **t2**

## Group 5: Wave A Extras (2 IDs, 4 Takes)

### 81. `wep_sunward_battery` (Wave A extra: Sunward main battery cannon, 0.8 s)

- **Today baseline:** `wep_sunward_battery_today0.ogg` (`-21.6 dB`, `100.0/0.0/0.0%`, `T95 594 ms`), `wep_sunward_battery_today1.ogg` (`-21.8 dB`, `58.9/31.6/9.5%`, `T95 292 ms`).
- **`wep_sunward_battery_t1.mp3` -> REJECT.**
  1. **Verdict:** Reject: Huge weighty forged-iron main battery cannon bang at `0.0 ms` beating today's split `boomLow` and `shellBang`, but wide stereo loses `-2.5 dB` of mids and highs in mono; channel L alone is clean.
  2. **Bass (<500 Hz):** Yes (`89.0%` below 500 Hz stereo, `90.6%` mono). Measured stereo `89.0%` <500 Hz (`0.2%` <20 Hz), `8.3%` in 500 Hz to 2 kHz, `2.6%` >2 kHz; mono centroid `2491 Hz`, dominant `50.0 Hz`, `-10.5 dB` stereo RMS (`-12.4 dB` mono, peak `0.4 dBFS`).
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.30`, fold loss `-1.88 dB` overall (`-1.80 dB` <500 Hz, `-2.53 dB` 500 Hz to 2 kHz, `-2.54 dB` >2 kHz, `-1.36 dB` attack 0 to 60 ms). Single channels: L `-9.7 dB` (pk `0.4 dBFS`, `89.8/7.6/2.6%`), R `-11.6 dB` (pk `0.3 dBFS`, `87.8/9.5/2.7%`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.0 ms` at -30 dB, `0.0 ms` at -20 dB). Peak at `79.1 ms`, `T95 = 369 ms`, dur `0.8 s`.
- **`wep_sunward_battery_t2.mp3` -> KEEP.**
  1. **Verdict:** Keep: Massive authoritative forged-iron main battery blast at `0.0 ms` that holds together firmly in mono and upgrades today's `boomLow` and `shellBang` once 40 Hz high-passed and peak-trimmed.
  2. **Bass (<500 Hz):** Yes (`88.9%` below 500 Hz stereo, `90.7%` mono). Measured stereo `88.9%` <500 Hz (`0.3%` <20 Hz), `7.1%` in 500 Hz to 2 kHz, `4.0%` >2 kHz; mono centroid `3086 Hz`, dominant `96.2 Hz`, `-8.6 dB` stereo RMS (`-9.3 dB` mono, peak `1.0 dBFS`).
  3. **Mono:** Mild softening; holds up cleanly by ear. `corr +0.73`, fold loss `-0.71 dB` overall (`-0.63 dB` <500 Hz, `-1.08 dB` 500 Hz to 2 kHz, `-2.27 dB` >2 kHz, `-0.49 dB` attack 0 to 60 ms). L/R imbalance `+2.6 dB` (`L -7.5 dB`, `R -10.1 dB`).
  4. **Onset (<=30 ms):** Yes, immediate (`0.0 ms` at -40 dB, `0.3 ms` at -30 dB, `8.9 ms` at -20 dB). Peak at `76.3 ms`, `T95 = 370 ms`, dur `0.8 s`.
- **Final answer (`wep_sunward_battery`):** **t2**

### 82. `ui_click_switch` (Wave A extra: acoustic UI console switch click, 0.5 s)

- **Today baseline:** `ui_click_switch_today0.ogg` (`-22.9 dB`, `0.0/97.7/2.3%`, `T95 43 ms`).
- **`ui_click_switch_t1.mp3` -> KEEP.**
  1. **Verdict:** Keep: Crisp weighty fully acoustic console toggle switch click with zero electronic tone, beating today's bright ping `uiClick` cleanly once the `24 ms` lead-in is trimmed.
  2. **Bass (<500 Hz):** No (`3.4%` below 500 Hz stereo, `4.1%` mono). Measured stereo `3.4%` <500 Hz (`0.0%` <20 Hz), `17.0%` in 500 Hz to 2 kHz, `79.6%` >2 kHz; mono centroid `6190 Hz`, dominant `81.2 Hz`, `-34.8 dB` stereo RMS (`-36.2 dB` mono, peak `-6.3 dBFS`).
  3. **Mono:** Mild softening; holds up cleanly by ear. `corr +0.44`, fold loss `-1.43 dB` overall (`-0.60 dB` <500 Hz, `-0.28 dB` 500 Hz to 2 kHz, `-1.77 dB` >2 kHz, `-1.42 dB` attack 0 to 60 ms). Single channels: L `-35.4 dB` (pk `-6.3 dBFS`, `4.7/19.3/76.1%`), R `-34.2 dB` (pk `-8.1 dBFS`, `2.4/15.2/82.3%`).
  4. **Onset (<=30 ms):** Yes, within 30 ms (`25.3 ms` at -40 dB, `28.6 ms` at -30 dB, `35.2 ms` at -20 dB; trim ~`25 ms` head for tight sync). Peak at `41.6 ms`, `T95 = 211 ms`, dur `0.48 s`.
- **`ui_click_switch_t2.mp3` -> REJECT.**
  1. **Verdict:** Reject: Quieter, late (`70.0 ms` dead head), and wide stereo that drops `-2.4 dB` overall, `-3.0 dB` of top end, and `-3.4 dB` on attack in mono.
  2. **Bass (<500 Hz):** No (`7.6%` below 500 Hz stereo, `11.4%` mono). Measured stereo `7.6%` <500 Hz (`2.0%` <20 Hz), `14.4%` in 500 Hz to 2 kHz, `77.9%` >2 kHz; mono centroid `6844 Hz`, dominant `20.8 Hz`, `-38.8 dB` stereo RMS (`-41.2 dB` mono, peak `-11.5 dBFS`).
  3. **Mono:** Yes, loses top end/midrange and punch. `corr +0.16`, fold loss `-2.39 dB` overall (`-0.65 dB` <500 Hz, `-0.92 dB` 500 Hz to 2 kHz, `-2.97 dB` >2 kHz, `-3.42 dB` attack 0 to 60 ms). Single channels: L `-38.5 dB` (pk `-11.5 dBFS`, `8.2/17.7/74.2%`), R `-39.1 dB` (pk `-12.3 dBFS`, `7.0/10.7/82.2%`).
  4. **Onset (<=30 ms):** No, late start (`70.0 ms` at -40 dB, `73.6 ms` at -30 dB, `80.8 ms` at -20 dB; trim ~`68 ms` dead head in mastering). Peak at `100.1 ms`, `T95 = 288 ms`, dur `0.48 s`.
- **Final answer (`ui_click_switch`):** **t1**

