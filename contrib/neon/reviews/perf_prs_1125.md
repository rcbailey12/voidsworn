# Neon (audit): Perf PRs 2215 (issue 2198) and 2213 (issue 2199)

Neon (audit): reviewed PR 2215 (`codex/issue-2198`, brief head `1f148565`, plus its landed run-2 merge `4f265d64` / `b193fe726` now on `origin/main` `3078d5a4`) and PR 2213 (`codex/issue-2199`, brief head `f1714af0` and refreshed head `14086a91`) against `origin/main` (`6c99aa10` at start of audit, `3078d5a4` at completion).

## Verdicts

- **PR 2215 (`codex/issue-2198`)**:
  - On brief head `1f148565`: **FIX FIRST** (three blockers: merge conflict in `fx_ship.gd` against Build A `throttle_k` and `_apply_plume_palette`, R458 settled-hulk `thin_hulk` freeze at about 14 s when combined with PR 2068, and `death_audio.deaths` breaking `TestDeathAudio` in `multi_kill_pace_check`).
  - On landed `origin/main` (`4f265d64` / `b193fe726`, verified at `3078d5a4`): **LANDED CLEANLY WITH TWO FOLLOW-UPS** (all three blockers above were fixed before merge and 12 of 12 targeted headless checks pass; keep the two medium follow-ups below for physics-wreck wake hardening and issue 2194 cut-in plate handoff).
- **PR 2213 (`codex/issue-2199`, head `14086a91`, brief head `f1714af0`)**: **FIX FIRST** (reconcile the `flush_damage` death handoff with open PR 2183, move first-hit surface spatial-grid building off the main thread or prove zero hitch on an installed capital, guard `_dmg_drawn_surfs` against early `BREACH.apply` returns, and rebase onto `main` `3078d5a4` to verify PR 2193's layered-shell path and look-bench flicker parity).

---

## Proof of Read (docs/REVIEW_PROTOCOL.md section 1)

| Commit | File | Total lines | Ranges read | First 40 chars of last line |
|---|---|---:|---|---|
| `1f148565` | `godot/fx/fx.gd` | 2,565 | 140-155, 690-790 | `	return hk` |
| `1f148565` | `godot/fx/fx_death.gd` | 4,954 | 595-720, 2460-2675, 2855-2960, 3540-4090, 4470-4954 | `		nd.global_position -= back` |
| `1f148565` | `godot/fx/fx_ship.gd` | 3,290 | 255-430, 515-710, 1560-1840, 2690-3065 | `	return changed` |
| `1f148565` | `godot/scenes/battle/battle.gd` | 8,222 | 2470-2540, 3680-3825, 7290-7365 | `	get_tree().quit(code)` |
| `1f148565` | `godot/ui/battle/hud.gd` | 1,560 | 885-1010 | `	ledger.mark()` |
| `1f148565` | `godot/fx/test/death_retirement_check.gd` | 164 | 1-164 | `	print("%s F1 wreck retirement" % ("PASS` |
| `1f148565` | `godot/scenes/battle/test/death_view_retirement_check.gd` | 145 | 1-145 | `	quit(1 if failures > 0 else 0)` |
| `1f148565` | `godot/render/ship_view.gd` | 2,348 | 845-920, 2245-2348 | `		ring.rotation.y = -rotation.y` |
| `1f148565` | `godot/render/squadron_wing.gd` | 488 | 370-460, 488 | `	mesh.surface_end()` |
| `3078d5a4` | `godot/fx/fx_death.gd` | 5,181 | 30-45, 3920-3965, 4800-5140 | `		nd.global_position -= back` |
| `3078d5a4` | `godot/fx/fx_ship.gd` | 3,409 | 650-715, 2805-2830 | `	return changed` |
| `3078d5a4` | `godot/fx/fx_damage_plume.gd` | 114 | 1-114 | `		plume.queue_free()` |
| `3078d5a4` | `godot/fx/test/death_retirement_check.gd` | 185 | 1-185 | `	print("%s F1 wreck retirement" % ("PASS` |
| `3078d5a4` | `godot/scenes/battle/battle.gd` | 8,272 | 3755-3825, 7360-7380 | `	get_tree().quit(code)` |
| `f1714af0` | `godot/fx/fx.gd` | 2,544 | 1600-1700 | `	return hk` |
| `f1714af0` | `godot/fx/fx_breach.gd` | 2,463 | 850-1840, 2050-2463 | `	m.set_shader_parameter("glow", Vector3(` |
| `f1714af0` | `godot/fx/fx_death.gd` | 4,887 | 2670-2820 | `		nd.global_position -= back` |
| `f1714af0` | `godot/fx/fx_hull.gd` | 2,220 | 1-250, 340-550, 900-1200 | `				(lb["node"] as Node3D).transform = (` |
| `f1714af0` | `godot/fx/fx_ship.gd` | 3,249 | 120-200, 1895-1960, 2230-2520, 3050-3170, 3220-3249 | `	return changed` |
| `14086a91` | `godot/fx/fx_breach.gd` | 2,466 | 850-1060, 1780-1810 | `	m.set_shader_parameter("glow", Vector3(` |
| `14086a91` | `godot/fx/fx_death.gd` | 5,101 | 2860-2880 | `		nd.global_position -= back` |
| `14086a91` | `godot/fx/fx_hull.gd` | 2,223 | 410-515 | `				(lb["node"] as Node3D).transform = (` |
| `14086a91` | `godot/fx/fx_ship.gd` | 3,310 | 2290-2560, 3120-3200 | `	return changed` |
| `14086a91` | `godot/fx/test/damage_worker_flicker_2199_check.gd` | 170 | 1-170 | `	quit(1 if failures else 0)` |

---

## PR 2215 (codex/issue-2198): Battle Slowdown Retirement + Deferred Queue Heap

### 1. Blocking (on brief head `1f148565`; all three fixed in run 2 / landed `3078d5a4`)

| # | Finding | OBSERVED/INFERRED | File:line | Exact quote | Why it matters | Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 1 | `fx_ship.gd` conflicts with `main`'s Build A engine plume code (`PR 2055`) and drops `throttle_k` and `_apply_plume_palette` | OBSERVED | `godot/fx/fx_ship.gd:497`, `573` (`1f148565`) | `_eng_gate_written = -1.0`; `_write_engine_gate(fx, g)` | All CI jobs on `1f148565` failed during merge-main with a conflict in `fx_ship.gd`, and `_write_engine_gate` did not write or cache `throttle_k` on `_eng_rib_mat` or `_sick_rib_mat`. | Rebase on `main`, keep `_apply_plume_palette` in `_build_engines`, and cache `throttle_k` in `_write_engine_gate` (done on `3078d5a4:656-688`). | High |
| 2 | Settled hulks skip PR 2068's `thin_hulk` before 60 s, freezing thick hulk smoke forever (R458) | OBSERVED | `godot/fx/fx_death.gd:4637`, `4844-4845` (`1f148565`); `fx_damage_plume.gd:11, 104-106` (`fdc29703`) | `if w.get("settled", false): continue`; `w["settled"] = true` | A hulk cools and stops drifting around 14 s (`WRECK_SETTLE_AGE = 13.5`, `WRECK_COOL = 14.0`). On `1f148565`, `w["settled"] = true` skips `update()`, which froze PR 2068's 60 s `thin_hulk` fade around density 0.66 instead of 0.11. | Decouple `thin_hulk` from the wreck update loop (see exact combined fix below; landed via `_thin_hulk_vent` on `fx.later` at `3078d5a4:3942, 3948-3956`). | High |
| 3 | `_death_audio_pending` reads `death_audio.deaths` directly, failing `multi_kill_pace_check` test double | OBSERVED | `godot/scenes/battle/battle.gd:3801` (`1f148565`) | `for cue in death_audio.deaths:` | `TestDeathAudio` in `multi_kill_pace_check` lacked a `deaths` property, causing a runtime error on hosted CI Shard 4 until `29b288d93` patched the stub. | Add `deaths` on test stubs or expose a `has_pending(ship)` query on `DeathAudio` (stub patched in `29b288d93`). | High |

### 2. High / Medium (still open on landed `origin/main` `3078d5a4`)

| # | Finding | OBSERVED/INFERRED | File:line | Exact quote | Why it matters | Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 4 | Physics wreck can settle while merely `sleeping` (not frozen), leaving it unbraked and unleashed if woken | INFERRED from observed code | `godot/fx/fx_death.gd:5051`, `5065`, `5072` (`3078d5a4`; `4824, 4838, 4845` on `1f148565`) | `if is_instance_valid(nd) and nd is RigidBody3D and not nd.freeze and not nd.sleeping:`; `w["settled"] = true` | Unfrozen `RigidBody3D` pieces still hold collision masks (`HULL_LAYER` or `DEBRIS_LAYER`). If a body sleeps before `_wreck_leave_physics` or without freezing, a later hull or plate hit can wake it while `update()` and `_leash()` permanently skip the settled wreck. | Require `nd.freeze` (or freeze any remaining bodies inside the settle block) before setting `w["settled"] = true`. | Med-High |
| 5 | Immediate `_retire_dead_plate` and `if sv.dead: continue` will drop R458 kill cut-in target plates when issue 2194 lands | OBSERVED | `godot/scenes/battle/battle.gd:3760`, `7368` (`3078d5a4`; `3723, 7325` on `1f148565`) | `_retire_dead_plate(str(id), sv)`; `if sv.dead:` | `_play_death` removes the killed ship's plate and sets `plate_off` before waiting out `kill_hold_until`. When issue 2194 restores R458 item 6 (attacker and target plates visible during kill cut-ins), this branch will hide the target immediately. | In issue 2194, defer `_retire_dead_plate` and exempt the active kill cut-in target from the `if sv.dead: continue` shortcut until `kill_hold_until` ends. | High |
| 6 | Hidden-death emitter retirement does not explicitly set `e.light["on"] = false` on Build C wound lights | OBSERVED | `godot/fx/fx_ship.gd:2808-2816` (`3078d5a4`) | `if gone or (dead and has_meta("death_hidden")):` | `e.node.hide()` stops lighting immediately via `is_visible_in_tree()` and `queue_free()` drops the light next frame, so nothing leaks, but explicit `e.light["on"] = false` keeps cleanup immediate and matches `_hide_attachments()`. | Add `if e.has("light"): e.light["on"] = false` inside the `for e in emitters:` loop in `_update_damage_emitters`. | Medium |

### 3. Exact Combined Fix for R458 Hulk Smoke (`settled` x PR 2068 `thin_hulk`)

- **Why the clash occurred on `1f148565`:** PR 2215 set `w["settled"] = true` after `age > WRECK_SETTLE_AGE` (13.5 s) and `w["cold"]` (14.0 s), skipping `update()` for the wreck. PR 2068 put `DAMAGE_PLUME.thin_hulk(w["vent_material"], age)` inside that same `for w in fx.dstate["wrecks"]:` loop for 60.0 s (`HULK_SETTLE_S`), so a hulk settling at 14 s froze thick smoke forever.
- **Exact combined fix (two valid options; option 1 is already landed on `3078d5a4`, option 2 removes the remaining CPU ticks):**
  1. **Landed on `origin/main` (`3078d5a4`, `fx_death.gd:36, 3942, 3948-3956`):** Keep `w["settled"] = true` at ~14 s so physics, lights, and leash retire on time, remove `vent_material`/`vent_next` from `update()`, and schedule `_thin_hulk_vent(fx, weakref(vent), born)` on `fx.later` every `HULK_VENT_TICK = 0.1` s until `age >= HULK_SETTLE_S` (60.0 s), clamping the final tick to `end = born + HULK_SETTLE_S` so `density` hits exact `HULK_WISP_DENSITY = 0.11` and stops rescheduling. Verified by `death_retirement_check.gd` at 30 s, 59.95 s, 60 s, and 120 s on `3078d5a4`.
  2. **Zero-CPU shader upgrade (optional follow-up):** `fx_damage_plume.gd:88` already passes `born` and `SH.DAMAGE_PLUME` already reads `scene_t`. Adding `uniform float density_end = 0.0; uniform float thin_s = 0.0;` to `SH.DAMAGE_PLUME` and computing `float d = thin_s > 0.0 ? mix(density, density_end, smoothstep(0.0, thin_s, age)) : density;` eliminates all 600 deferred ticks per hulk while keeping the exact same `smoothstep(0.0, 60.0, age)` curve.

### 4. Ready / Verified on PR 2215

- **R459 (fires burn through death tell until break):** Verified (`fx_ship.gd:2723-2741` on `1f148565`, `2808-2828` on `3078d5a4`). `_damage_emitters` and `_fading_emitters` stay visible while `dead and not has_meta("death_hidden")`, move with `_dmg_root` attached under `_ref_mi` during `_update_dying`, and are hidden, freed, and cleared in one pass once `death_hidden` is set.
- **Risen Eclipse ships:** Verified (`battle.gd:2497-2501, 3727, 3762-3769` on `1f148565`; `death_view_retirement_check.gd` PASS). `_death_can_rise` inspects `batch_view` for `rising`, keeps FX registered (`keep_fx = true`), parks `sv` once tails drain, and `_reassemble` clears `plate_off`, calls `sv.revive()`, clears `death_view_parked`, restores `sv.set_process(true)`, and re-registers fresh FX.
- **AR1 `_later` min-heap (`fx.gd:697-775`):** Verified. Preserves `(time, _later_serial)` tie order, pops only entries with `t <= cutoff`, leaves future-only frames untouched, and handles callbacks that schedule immediate (`t <= now`, run synchronously in `later`) or future work without scanning the queue. Note: open PR 2209 (`work/issue-2172-deepseek`) also edits `_later`/`_run_later`; keep PR 2215's min-heap when merging PR 2209.
- **Wounds V2 paths:** Verified. `_hide_attachments()` (`fx_ship.gd:356-358`) turns off and clears `_hole_lights` at `hide_live_hull()`, so kept-FX wrecks and Eclipse rise candidates do not leak cavity lights against `BATTLE_HOLE_LIGHTS`; `wounds_v2_check.gd` passes on `3078d5a4`.
- **HUD `set_plate` (`hud.gd:978-985`):** Verified. Early-return on `not on` only hides an existing control and never allocates a plate for a dead or absent unit.

---

## PR 2213 (codex/issue-2199): Damage Worker Thread Race + Power Flicker Re-Uploads

### 1. Blocking / High

| # | Finding | OBSERVED/INFERRED | File:line | Exact quote | Why it matters | Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 1 | `flush_damage` returns early on `if dead or gone:` before publishing `work.out["surfs"]`, clashing with PR 2183's fatal-hit wound fix | OBSERVED | `godot/fx/fx_ship.gd:2355-2360` (`14086a91`; `2298-2303` on `f1714af0`); PR 2183 `fx_ship.gd:2295-2311` | `if dead or gone:`; `_dmg_drawn_surfs = work.out.get("surfs", [])` | When a lethal hit starts a rebuild and `death()` runs before the worker finishes, PR 2213 discards the joined geometry so `DEATH.precompute` cuts the pre-hit hull. Taking PR 2213's early return overwrites PR 2183's eligible death-only publication. | Join via `wait_damage()`, keep `if gone or (dead and (get_meta("death_hulk", true) or has_meta("death_hidden"))): return`, publish `_dmg_drawn_surfs = work.out.get("surfs", [])` before skipping `BREACH.apply` when `dead`, and notify `DEATH.damage_settled` when combined with PR 2183. | High |
| 2 | First-hit surface spatial-grid build (`prepare_surfaces`) moves onto the main thread, risking a hit-frame hitch on high-tri installed capitals | OBSERVED move; INFERRED hitch on installed capitals | `godot/fx/fx_ship.gd:2328` (`14086a91`; `2271` on `f1714af0`); `godot/fx/fx_breach.gd:867-880`, `1015-1050` | `var active := BREACH.prepare_surfaces(_orig, ents, cell)`; `for t in idx.size() / 3:` | Previously `_prepare_surface` ran on the worker thread. Moving vertex transform (`xf * V`) and per-triangle 3D grid hashing (up to 64 `Vector3i` dictionary buckets per tri) into `_dmg_request` puts the full cost on the battle thread on the first hit to each surface. Box fixtures do not measure installed capital tri counts. | Have the worker build missing `P`/`idx`/`grid`/`big` entries into a private `work.out["prepared"][k]` dictionary (zero worker writes to `_orig`) and attach them to `_orig[k]` on the main thread in `flush_damage` after `wait_damage()`. | High |

### 2. Medium

| # | Finding | OBSERVED/INFERRED | File:line | Exact quote | Why it matters | Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 3 | `_dmg_drawn_surfs` is overwritten even if `BREACH.apply` returns early without swapping `mi.mesh` | OBSERVED | `godot/fx/fx_ship.gd:2359-2360` (`14086a91`; `2302-2303` on `f1714af0`); `godot/fx/fx_breach.gd:1659-1663` | `BREACH.apply(fx, self, _dmg_job)`; `_dmg_drawn_surfs = work.out.get("surfs", [])` | If `BREACH.apply` exits early (`res.is_empty()` or `not s.root.is_inside_tree()`), `mi.mesh` still holds the previous rebuild while `_dmg_drawn_surfs` advances to the unapplied arrays, causing `current_arrays` to serve mismatched geometry if `mi.mesh != src`. | Have `BREACH.apply` return `bool` (true only when meshes were applied) and update `_dmg_drawn_surfs` only when it returns `true` (or on PR 2183's explicit death-only publish path). | Medium |
| 4 | Branch `14086a91` is 53 commits behind `main` (`3078d5a4`, now carrying PR 2215 and PR 2193); live-path layered-shell test and look-bench parity remain unrun on the combined tip | OBSERVED | `godot/fx/fx_breach.gd:895-902` (`14086a91`); `godot/fx/test/wounds_v2_check.gd:240-257` (`3078d5a4`) | `if job.has("active"):`; `var rebuilt := BREACH.compute({"surfs": surfs,` | `wounds_v2_check.gd`'s new PR 2193 layered-shell check calls `BREACH.compute` without `"active"`, exercising the fallback copy branch rather than the live `prepare_surfaces` branch (note: math check confirms `sqrt(e.inf2) + e.ov >= 4.85 * R > sqrt(e.cutr2) = 1.6 * R`, so `prepare_surfaces` will include every cuttable layer). Look-bench flicker parity is also still pending. | Rebase onto `origin/main` (`3078d5a4`), add a live-path (`prepare_surfaces` + `"active"`) assertion on the layered-shell fixture, and run the look-bench flicker parity check on a GPU lane. | Medium |

### 3. Ready / Verified on PR 2213

- **Worker private output and thread safety:** Verified (`fx_breach.gd:857-863, 885-986, 1054-1279`; `fx_ship.gd:2330-2360, 2463-2495, 3228-3249`; `fx_hull.gd:962-971`). `BREACH.rebuild` writes solely into `work.out` on its private `RebuildWork` object; `_surface`, `_walls`, `_throat`, `_patch`, `dress`, `conduits`, and `spines` do not write back into `sd`, `ents`, or `hull` (`hull.ray` only queries read-only `TriangleMesh`). Main-thread mark updates (`_place_mark`, `_regrade_marks`) replace `Ent` objects rather than mutating existing entries in place.
- **Main thread never reads a dict the worker writes:** Verified (`fx_ship.gd:2535-2546`). `current_arrays` reads only `_orig` and `_dmg_drawn_surfs`, never `_dmg_job["out"]` or `work.out` while `_dmg_task >= 0`. Confirmed by `damage_worker_flicker_2199_check.gd` holding a real worker thread inside `compute()` while `DEATH.precompute` runs.
- **Flicker look unchanged and zero per-material uniform uploads:** Verified (`fx_hull.gd:415, 461, 511`; `fx_death.gd:2865`; `fx_ship.gd:3133-3195`). `power_flicker()` and `_power_step()` math are identical to `main`; `fx_flick` is now `instance uniform float fx_flick = 1.0;` on live damage shaders (and stripped on `fixed_wreck` and `power_material`, which still matches PR 2193's `fx_hull.gd:460` cleanly). `damage_worker_flicker_2199_check.gd` verified 0 `set_shader_parameter("fx_flick")` sites and 0 material values across 180 frames in both normal and `reduce_flashing` modes.
- **Wounds V2 paths and Eclipse revive:** Verified. `_inside_overlay` (`fx_breach.gd:1805`) tracks every damage-bearing mesh via `track_damage_mesh(mi)` and initializes `fx_flick` to `_power_shown`; V2 interior materials (`_interior_v2`) and `fx_damage_inside`/`fx_damage_marks` do not use `fx_flick`; `wounds_v2_check.gd`, `live_wounds_1587_check.gd`, and `wave_1a_check.gd` all pass on `14086a91` and on the local merge onto `3078d5a4`.

---

## Godot Headless Check Evidence

Ran `Godot_v4.7.2-stable_win64_console.exe --headless --import` followed by targeted headless checks in temporary detached worktrees (cleaned up afterward):

1. **`origin/main` `3078d5a4` (includes merged PR 2215 `b193fe726`, PR 2068, PR 2193):** 12/12 PASS (exit 0, 0 failures, 0 `SCRIPT ERROR`s):
   - `tools/ci/load_all.gd` (484 scripts, 17 scenes, 0 failed)
   - `fx/test/death_retirement_check.gd` (PASS AR1, F3/W1, F1 + R458 hulk thinning at 30/59.95/60/120 s)
   - `scenes/battle/test/death_view_retirement_check.gd` (PASS F2 retired views, plates and Eclipse rise)
   - `fx/test/damage_plume_check.gd`, `fx/test/death_leap_check.gd`, `fx/test/death_plane_check.gd`, `fx/test/destruction_staging_check.gd`, `fx/test/cold_kill_check.gd`, `fx/test/kill_slowmo_check.gd`, `fx/test/effect_clock_1970_check.gd`, `fx/test/wounds_v2_check.gd`, `scenes/battle/test/wreck_hex_check.gd` (all 0 failures).
2. **PR 2213 `14086a91` standalone:** 10/10 PASS (exit 0, 0 failures, 0 `SCRIPT ERROR`s):
   - `tools/ci/load_all.gd` (479 scripts, 17 scenes, 0 failed)
   - `fx/test/damage_worker_flicker_2199_check.gd` (0 failures; 0 `fx_flick` material setter sites and 0 material values)
   - `fx/test/fx_correctness_1933_check.gd`, `fx/test/live_wounds_1587_check.gd`, `fx/test/wave_1a_check.gd`, `fx/test/wounds_v2_check.gd`, `fx/test/damage_surface_check.gd`, `fx/test/graphics_correctness_check.gd`, `fx/test/cold_kill_check.gd`, `fx/test/death_plane_check.gd` (all 0 failures).
3. **Local test-merge of PR 2213 `14086a91` onto `origin/main` `3078d5a4`:** Clean merge (`MERGE_EXIT=0`), 9/9 PASS (exit 0, 0 failures, 0 `SCRIPT ERROR`s):
   - `tools/ci/load_all.gd` (485 scripts, 17 scenes, 0 failed)
   - `fx/test/damage_worker_flicker_2199_check.gd`, `fx/test/wounds_v2_check.gd`, `fx/test/live_wounds_1587_check.gd`, `fx/test/wave_1a_check.gd`, `fx/test/fx_correctness_1933_check.gd`, `fx/test/death_retirement_check.gd`, `scenes/battle/test/death_view_retirement_check.gd`, `fx/test/damage_plume_check.gd`.

---

## Recommended Next Steps

- **PR 2215 (already merged on `main` `3078d5a4`):** Queue a small follow-up to freeze remaining `RigidBody3D` pieces when setting `w["settled"] = true` (and explicitly clear `e.light["on"] = false` on hidden-death emitter retirement), and make sure issue 2194 handles `_retire_dead_plate` during the kill cut-in hold.
- **PR 2213 (`14086a91`):** Rebase onto `origin/main` (`3078d5a4`), reconcile `flush_damage`'s death handoff with PR 2183, move first-hit surface cache creation onto the worker's private `RebuildWork.out` (applied on main thread in `flush_damage`), guard `_dmg_drawn_surfs` on `BREACH.apply` success, and run the GPU look-bench flicker parity check before merge.

---

Not checked: GPU window captures and look-bench flicker visual parity on PR 2213 (headless checks cannot verify rendered appearance); real Windows frame-time measurements (`hull_prepare` cost on an installed capital GLB and late-battle frame times after PR 2215); full 4-shard CI and bot battle replay on the combined `14086a91` + `3078d5a4` merge; live Jolt physics wake reproduction on a settled anchored wreck; combined runtime of PR 2213 with open PR 2183 or PR 2215 with open issue 2194.
