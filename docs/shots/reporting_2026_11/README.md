# Issue 238 reporting outputs

Branch `work/issue-238-deepseek`, Nov 12 2026. Report only: no game, rules or save code changed.

This folder holds the scripts' outputs. The scripts are in `contrib/opus/tools/`.

| Item | Output | Script |
| --- | --- | --- |
| ST4 station count and timing, PL12 cold planet bakes, BD2 sky steps | `env_audit.json` | `env_batch_audit.js` |
| PL12 raw bake rows | `planet_bake_timings.json` | `planet_bake_timing.gd` |
| ST4 raw station rows | `station_audit.json` | measured by `tools/blender/hs/station_check.gd --measure` on the PC |
| BD6 star density | `star_count.json` | `star_count_report.js` |
| S8 defer rule, proving S9 | `sound_defer.json` | `sound_defer_report.js` |
| HD6 battle log soak | `soak.json`, `hd6_battle_log_soak.png` | `battle_log_soak.gd` |
| MP8 danger bands | `danger_bands.json` | `danger_bands_montecarlo.js` |

The soak capture is also copied to the reviewer's `out/shots` folder.

## Choices made

- ST4 uses the existing station measurement from the PC (`board/issue-195/shots`). It is the same fleet and refinery kit the current build draws, and the raw `detail_audit.json` and `detail_gpu.json` carry the triangle count and the paired GPU timing. A new Blender build would measure the same shipped GLBs again.
- PL12 measures the shipped GPU compute bake, not the headless raster fallback: the script runs without `--headless`, clears the shared cache and points `VS_WORLD_CACHE` at a fresh folder for every seed, then times both planet passes at the max 4096 by 2048 size.
- BD2 is a data comparison of the loader's per-tier `steps` and the shader's uniform and loop cap. No bake is needed to answer it.
- BD6 counts the cells the three star layers can keep, with the band-density term and the exact threshold rule from `world_sky.gd`. It also counts a relaxed set (each threshold 0.01 lower) to show how far a threshold change moves the density.
- S8 reads both sound tables. It reports the rule and runs the largest legal salvo through the playable scheduler's own defer arithmetic. The JS oracle still carries S9; the Godot port's `cues.json` already carries defers large enough to start every voice.
- HD6 uses the scene gate's 20-ship battle (10 Sunward hulls against two hulls from each other faction) on a storm map, played out by the bot.
- MP8 uses the existing campaign sim harness with the baseline policy and veteran AI, 12 runs per faction, 6 factions. The danger estimate is copied from `godot/ui/campaign/map_intel.gd`.

## Findings

### ST4: station count and timing

Measured on the RTX 5080 at 3840x2160, paired median viewport GPU time with the station shown minus hidden, 5 pairs.

| Station | Triangles | Parts | Guns | Median delta ms | Paired range ms |
| --- | ---: | ---: | ---: | ---: | --- |
| Fleet | 11636 | 98 | 8 | 0.044 | -0.016 to 0.048 |
| Refinery | 6656 | 61 | 0 | 0.038 | -0.005 to 0.083 |

Both are far below the 20k triangle target and the 0.35 ms design target; the paired ranges cross zero, so the station cost is inside timing noise at 4K. The 1.0 ms ceiling is not close.

### PL12: cold planet bake timings across seeds

Eight seeds, both planet passes, fresh cache for each seed, 4096 by 2048.

| Seeds | Min total | Median total | Max total | Wait cap | Cache max |
| --- | ---: | ---: | ---: | ---: | ---: |
| 4101 to 4108 | 3150 ms | 3680 ms | 4359 ms | 20000 ms | 24 |

All eight bakes returned both images. The slowest cold bake is 4.36 s, under the 20 s wait cap and under the 6 to 9 s figure the audit carried. The cache max is unchanged at 24.

### BD2: sky march steps

| Quality | Steps passed by the loader |
| --- | ---: |
| max | 48 |
| high | 40 |
| low | 26 |

The shader default is 40 and the loop cap is 64. Every tier is inside the cap. The loader always passes `steps` into the bake params, and `world_sky.gd` divides the march by `steps` and breaks at `i >= steps`, so the per-tier values are live, not ignored. The default 40 is the high tier value, not a second law. BD2's "loader versus shader" question is a defaulting question, not a dead dial.

### BD6: star density

Expected kept cells, three layers (scales 120, 300, 650), per region.

| Region | Band | Stars, whole sphere | Stars per steradian | In a 1.14 sr battle view | Relaxed thresholds, whole sphere |
| --- | ---: | ---: | ---: | ---: | ---: |
| frontier | 0.6 | 92933 | 7395 | 8431 | 192286 (+106.9%) |
| nebula | 0.4 | 90448 | 7198 | 8205 | 189800 (+109.8%) |
| world | 0.8 | 95419 | 7593 | 8656 | 194771 (+104.1%) |
| boneyard | 0.45 | 91069 | 7247 | 8262 | 190422 (+109.1%) |
| deep | 1.0 | 97904 | 7791 | 8882 | 197257 (+101.5%) |
| deadstar | 0.7 | 94176 | 7494 | 8544 | 193529 (+105.5%) |

Thresholds this close to 1.0 are very sensitive: lowering all three by 0.01 roughly doubles the star count. That is the measurement the owner round for BD6 needed.

### S8 and S9: sound defer

JS oracle `sfx.js` still carries the measured defect. `gun_sq` (gap 0.05, defer 0.08) fails S8's 2.5x rule at 1.6x. More importantly, every gun cue in the JS table drops voices in its largest legal salvo:

| Cue | Gap | Defer | Cap | Starts, worst case |
| --- | ---: | ---: | ---: | ---: |
| gun_shell | 0.045 | 0.14 | 6 | 4 of 6 |
| gun_flak | 0.04 | 0.10 | 4 | 3 of 4 |
| gun_sq | 0.05 | 0.08 | 3 | 2 of 3 |
| gun_las | 0.045 | 0.14 | 6 | 4 of 6 |
| gun_plasma | 0.05 | 0.14 | 5 | 3 of 5 |
| gun_tracer | 0.06 | 0.16 | 5 | 3 of 5 |
| gun_spine | 0.05 | 0.14 | 5 | 3 of 5 |
| gun_needle | 0.045 | 0.14 | 6 | 4 of 6 |
| gun_rail | 0.06 | 0.16 | 4 | 3 of 4 |
| gun_glob | 0.05 | 0.14 | 5 | 3 of 5 |

So S9 is confirmed in the playable JS oracle, and S8's 2.5x form is too weak: it passes several cues whose full salvo still loses voices. The requirement that covers the largest legal salvo is `defer >= 0.004 + (max - 1) * gap`. The Godot port's `godot/audio/cues.json` already has defers around 65x gap and starts every voice in every case, so it does not reproduce S9. The remaining fix, if the Board wants the JS oracle and the port to match, is data only: raise the JS gun defers to the full requirement or to the port's values.

### HD6: battle log soak

One 20-ship battle, seed 4238, 14 rounds, result win.

- Rules log array: 346 entries.
- HUD RichTextLabel: 346 entries, 424 display lines (wrapping included), 24763 characters.
- No entry cap found in the HUD add path: the port keeps growing past the JS DOM cap of 200.
- Capture: `hd6_battle_log_soak.png` (full log opened with L).

The data half is settled: the port's log array is unbounded too, so the two builds diverge in what survives a long fight. The cap decision is the Board's.

### MP8: danger bands against bot outcomes

12 runs per faction, veteran AI, baseline policy, 763 fights (403 battle, 204 elite, 156 boss).

| Band | Fights | Won | Win rate | 95% interval |
| --- | ---: | ---: | ---: | --- |
| Easy | 261 | 255 | 97.7% | 95.1 to 98.9% |
| Even | 220 | 212 | 96.4% | 93.0 to 98.1% |
| Hard | 172 | 160 | 93.0% | 88.2 to 96.0% |
| Deadly | 110 | 85 | 77.3% | 68.6 to 84.1% |

Logistic fit: `P(win) = sigmoid(4.139 - 1.263 * ratio)`, AUC 0.772.

| Ratio | Fitted P(win) |
| ---: | ---: |
| 0.80 | 95.8% |
| 1.05 | 94.3% |
| 1.40 | 91.5% |

The current cut points do not separate the bot's results: a fight at 1.4 still wins about 91% of the time. The fitted win probability falls through 90% at ratio 1.54, 75% at 2.41, 60% at 2.96 and 50% at 3.28. The non-boss fit (607 fights) gives `P(win) = sigmoid(3.733 - 0.946 * ratio)`, AUC 0.747, with 90% at ratio 1.62 and 50% at 3.95.

This is bot data, not player data. It says the labels are currently conservative relative to this bot; it does not by itself say where a player's cut points should sit.

## Commands

```
node contrib/opus/tools/env_batch_audit.js --station-folder "C:/Users/rcbai/Downloads/voidsworn_test/board/issue-195/shots"
godot --path godot --script "$PWD/contrib/opus/tools/planet_bake_timing.gd" -- --out docs/shots/reporting_2026_11/planet_bake_timings.json
node contrib/opus/tools/star_count_report.js --out docs/shots/reporting_2026_11/star_count.json
node contrib/opus/tools/sound_defer_report.js --out docs/shots/reporting_2026_11/sound_defer.json
godot --path godot --resolution 1920x1080 --script "$PWD/contrib/opus/tools/battle_log_soak.gd" -- --out docs/shots/reporting_2026_11 --seed 4238
node contrib/opus/tools/danger_bands_montecarlo.js --runs 12 --out docs/shots/reporting_2026_11/danger_bands.json
node contrib/opus/tools/reporting_238_tests.js
```

## Cross-checks

- Callers: no game function, constant or save field changed. The new scripts call existing functions (`WorldBake.bake`, `WorldSky.PLANETS`, the campaign sim's `runOne` and the battle scene's HUD); no caller needed a change.
- Saves: no profile or run save field changed, so an older save loads and behaves as before. The sim and soak use the normal `defaultMeta` and campaign paths; no save migration was needed.
- Twins: `battle.js`, `data.js` and `core.js` are unchanged, and so is `godot/audio/cues.json`. No table re-export was needed. `contrib/opus/tools/oracle_copy_test.js` runs in the standing checks.
- UI: no screen value changed. The scripts read the existing HUD log and the existing campaign danger bands; no screen needed a new value.
- CI: `contrib/opus/tools/reporting_238_tests.js` ends in `_tests.js`, so `run_all_checks.js` discovers it with the other `_tests.js` files and GitHub runs it in the standing checks. The Godot helper scripts here are report generators, not CI checks; GitHub's game check job does not run them.
