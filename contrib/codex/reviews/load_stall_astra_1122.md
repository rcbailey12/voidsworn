# Why the 24-ship battle load stalls

## Worst cold and warm frames

**PROVED (observed). Both s25 freezes spend most of the frame inside a draw during hull preparation.** On LOAD17 the cold frame spent 6,138 of 6,575 ms in the draw (93%). Warm spent 2,960 of 3,035 ms there (98%). Both rows count 83 pipeline compilations. **SUGGESTED (inferred).** Pipeline creation or a wait for render resources is a better lead than ship setup. The trace locates the wait but gives neither operation its own elapsed time.

All times below are milliseconds unless marked otherwise. C and W mean `load_cold/load_result.txt` and `load_warm/load_result.txt` under `out_20261121_213248_31382/out_new/load10/` at LOAD17 commit `107c3c81e` (board/pc-out-1434r). The timestamps use the bench clock. Only the before-draw and draw columns add to the frame.

| LOAD17, PROVED | Frame began | Before draw | Draw | Frame ended | Step sampled at draw start |
|---|---:|---:|---:|---:|---|
| Cold, C:6 | 13,835 | 437 | 6,138 | 20,410 | `hull prep step at the draw: cuts` |
| Warm, W:6 | 10,960 | 75 | 2,960 | 13,995 | `hull prep step at the draw: shield x011` |

**PROVED.** C:6 records `draw 6138 ms, before the draw 437 ms` and `render cpu 3 ms, gpu 8 ms, 83 pipelines compiled`. W:6 records `draw 2960 ms, before the draw 75 ms` and `render cpu 2 ms, gpu 9 ms, 83 pipelines compiled`. The renderer counters and process-step values are separate observations. They cannot divide the wall-clock draw into compile, upload, wait and GPU execution.

**PROVED.** LOAD15 (`ad0d0364f`, board/pc-out-1434o, same filenames under `out_20261121_183514_32105/out_new/load10/`) saw the same pattern. Cold line 6 reads `draw 5850 ms, before the draw 410 ms` (6,260 total). Warm line 6 reads `draw 2907 ms, before the draw 78 ms` (2,985 total). Use LOAD17 for the draw-start labels.

## What the stage timers prove

**PROVED.** Read the rows below in load order. The ship-build spans ended before the peak. C:3 says `24 ships in 4611 ms over 59 frames`, W:3 says `24 ships in 3835 ms over 59 frames`. Their longest uninterrupted build stretches were 252 and 248 ms respectively. A worker's total effort and a wait visible to the player are different measurements.

| Stage and scope | Cold | Warm | Exact evidence and interpretation |
|---|---:|---:|---|
| File load and worker instancing, combined wait across the fleet | 155 | 5 | PROVED. `load_cold/log.txt:39` and `load_warm/log.txt:39` both say `14 hulls instanced on workers`. The cold log says `waiting on hull files and worker instances 155 ms`. File I/O alone and worker instancing alone have no elapsed-time split. |
| Ship and wing setup, worst unit | 81, Hullbreaker bomber wing | 103, C16s_23 | PROVED. C:7 gives `"wing_load": 8, "wing_inst": 77, "wing_finish": 78322, "wing_make": 165, "wing_copies": 1735` in microseconds. Converted to ms, load 0.008, instance 0.077, finish 78.322, copies 1.735. Making the lead took 0.165 including load and instance. W:7 gives `"inst": 91` and `"look_assign": 79703` for the worst hull (0.091 and 79.703 ms). Warm s25 has no per-wing split. |
| Hull geometry and effects registration, worst hull C16s_23 | 235 geometry, 224 registration | 226 geometry, 219 registration | PROVED. C:7 and W:7 give `"add:analyse": 217083` and `"add:analyse": 206057` (217.083 and 206.057 ms). The registration shield hook was 0.005 and 0.004 ms (`"add:shield": 5` and `"add:shield": 4`). |
| Deferred shield and cut work during hull prep | No named effect reached the logging threshold on the peak | 73 of 75 before draw | PROVED. C:6 says `effects work -` and W:6 says `effects work prep:shield 73 ms`. Neither gives worker shield-bake duration. W:6 also records `prep:shield 99 ms` for x010 on a different frame whose draw was only 2 ms. |
| Draw during hull prep and pipeline count | 6,138 draw, compile ms unknown | 2,960 draw, compile ms unknown | PROVED. Both line 6 rows say `83 pipelines compiled` and `0 world bakes pending, bake worker idle -> idle`. These are the long draws under the cover. The trace has no per-object first-draw timestamp. |

**PROVED.** The LOAD15 Navy fighter figure came from b1. LOAD15 cold line 16 says `worst ship setup 710 ms`. Its line 20 says `setup stages (us) {  }`. LOAD17's separate seven-ship cold close run gives an actual Navy fighter split with `wing_load 0, wing_inst 0, wing_finish 72, wing_make 0, wing_copies 1` (rounded ms, `close_cold/x_battle_30s/game.log:22`). LOAD17 b1 now names V16_37 as its worst setup (C:16, W:16). Neither fighter sample is a timing of the s25 draw.

**PROVED.** The two cover checks answer different questions. Cold s25 exceeded five seconds with the cover visible (C:5, `0 frames without the cover before play, 1 frames of 5 s or more`). Warm passed that check (W:5) and failed the 500 ms frame budget (W:2, `s25 FAIL (slice PASS, ready PASS, cover FAIL)`, W:47, `limit 500 ms for each graded item`). LOAD15 failed the warm 500 ms cover budget in b1 through b3 (LOAD15 warm lines 15, 22 and 29 each say `cover FAIL`). LOAD17's worst warm frames were b1 1,450 ms in world build, b2 579 ms in effects warm-up and b3 395 ms in ship building (W:17 `1450 ms world_build`, W:24 `579 ms fx_warmup`, W:31 `395 ms ships`). Only b3 passed that budget. All three passed the five-second cover check on both profiles (C and W:18,25,32).

**SUGGESTED, leading cause.** A blocking pipeline creation on first use fits the repeated count of 83 and the shorter warm draw. The warm profile already had `shader_cache 250 -> 256 files` (`load10_result.txt:7`). A pipeline count alone cannot show the time on the thread holding up the draw. C:6 even has a shorter 213 ms draw with `130 pipelines compiled`.

**SUGGESTED, competing cause.** The renderer may be waiting for newly prepared mesh or material resources. The cold frame's `cuts` label covers finishing cuts and installing completed shield skins (`godot/fx/fx.gd:1526,1528`). The warm frame's `shield x011` label marks the ship at draw start. Neither identifies the resource that delayed the renderer. **PROVED.** The bench samples the label at pre-draw, measures wall time to post-draw and takes a per-frame pipeline count difference (`godot/bench/load_1434.gd:65,69,76,198`). The viewport GPU counter covers a different interval. Neither upload time nor driver-wait time has a separate field.

## Ranked fixes

1. **SUGGESTED.** Target the hull-prep draw first. If pipeline creation owns it, prepare the measured variants in small batches before their first use. If resource transfers own it, stagger installation of the affected meshes. Judge either change by the longest covered frame. C:6 and W:6 put seconds in this interval on both profiles.
2. **SUGGESTED.** For shorter total load time, reuse the C16s_23 hull analysis across geometry setup and effects registration where the pose and mesh match. Both stages have measured costs above 200 ms on each profile (C:7, W:7). This is a separate saving from the draw stall.

## Evidence and limits

**PROVED.** PR 1445 at `057db2b44` matches LOAD17's `out_20261121_213248_31382/checkouts.txt:1` (`new 057db2b44f759336333f3f1e8e6a3599efc542f9`). The LOAD15 pin was `5c78f326f`. Both benches used the same Windows run sequence. The runner uses `foreach ($pass in @('cold', 'warm'))` on one isolated profile (`contrib/opus/pc/1434/load1434_runs.ps1:58`).

**PROVED.** The sliced build yields while files or instances are pending (`godot/scenes/battle/battle.gd:1072`, `ok = await _ls_yield(gen, true)`). It saves stage detail only for the slowest setup (lines 1113 to 1116). The view copies the wing timers (`godot/render/ship_view.gd:294`, `stage_us = (hull.stage_us as Dictionary).duplicate()`). The wing times finishing the lead before making copies (`godot/render/squadron_wing.gd:104`, `finish(lead, fac)`). Shield setup sets `shield_later = true` (`godot/fx/fx_ship.gd:204`), then hull prep calls `ship_s.build_shield_later(self)` (`godot/fx/fx.gd:1486`).

**PROVED.** The s25 bench starts its own battle (`godot/bench/load_1434.gd:159`, `var b = BattleScene.instantiate()`). The menu showcase sets `showcase.title_backdrop = true` (`godot/main/main.gd:401`). Battle warm-up is guarded by `and not title_backdrop` (`godot/scenes/battle/battle.gd:878`). A title or close frame cannot identify which s25 draw blocked.

<details>
<summary>Raw source readback at the reviewed commits</summary>

Final-line prefixes below use `\t` for one tab. C, W and the logs use the LOAD17 directory above. Ranges identify the sections inspected in the large code files.

| File | Lines | Final line, first 40 characters |
|---|---:|---|
| LOAD17 checkouts.txt | 1 | `new 057db2b44f759336333f3f1e8e6a3599efc5` |
| LOAD15 checkouts.txt | 1 | `new 5c78f326f287652f0003248123f670e6bcfb` |
| C and LOAD15 cold result | 47 each | `[load1434] RESULT FAIL on the cold profi` |
| W and LOAD15 warm result | 47 each | `[load1434] RESULT FAIL on the warm profi` |
| load_cold/log.txt and load_warm/log.txt | 250 / 228 | Same cold / warm prefixes as above |
| load10_result.txt | 45 | `[load10] RESULT FAIL (every line above m` |
| close_cold/x_battle_30s/game.log | 42 | `[main] quit stages: scenes freed + 2 fra` |
| godot/bench/load_1434.gd | 522 | `\tquit(0 if pass_all else 1)` |
| godot/scenes/battle/battle.gd, 865 to 910 and 1020 to 1164 | 6,651 | `\tget_tree().quit(code)` |
| godot/render/ship_view.gd, setup and timer lines in 236 to 457 | 1,841 | `\t\tring.rotation.y = -rotation.y` |
| godot/render/squadron_wing.gd | 481 | `\tmesh.surface_end()` |
| godot/fx/fx_ship.gd, 190 to 208 and 580 to 647 | 1,994 | `\t\t_dmg_request(fx)` |
| godot/fx/fx.gd, 1440 to 1535 | 2,138 | `\treturn hk` |
| godot/main/main.gd | 776 | `\treturn str(v)` |
| contrib/opus/pc/1434/load1434_runs.ps1 | 238 | `if ($ok) { exit 0 } else { exit 1 }` |

</details>

**Not checked.** No footage or game run. The supplied s25 rows have no Vulkan call durations, per-resource upload times or shield worker duration. An exact driver operation, a specific pipeline variant and the object that first used it remain unverified.

## One Windows test

**SUGGESTED. Trace one warm s25 load on the 5080.** Use the LOAD17 build and a copy of its warm profile. On the GPU lane, set `PC_GPU_MODE=solo`, then run through `tools/pc/tmo.bat` and launch the same fullscreen Vulkan bench with `--script res://bench/load_1434.gd -- --cases s25 --pass warm --out <temp-folder>`. Collect a Windows Vulkan API timeline with thread scheduling and GPU copy/queue activity for that launch (for example, Nsight Systems). Enable timestamped marks at the bench's pre-draw and post-draw callbacks so the slow draw can be selected exactly. Budget about one minute of PC run time once tracing is ready. W:3 records `to play 20661 ms`.

**Deciding number.** In the longest reproduced hull-prep draw, measure the percentage of its wall time spent inside graphics pipeline creation (`vkCreateGraphicsPipelines`) on the thread delaying draw completion, including time that thread demonstrably waits for a pipeline worker. Count overlapping intervals once. Over 50% favors pipeline creation (over 1,480 ms in a 2,960 ms draw). If instead over half the same interval is spent waiting for identified mesh uploads or their transfer fences, that favors resource transfer or synchronization. A short draw, an unexplained wait or neither activity reaching a majority leaves the result inconclusive.
