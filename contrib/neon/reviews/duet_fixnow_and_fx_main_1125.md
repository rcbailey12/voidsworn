# Neon (audit): PR #2183 (Issue 2170 Duet FIX NOW) and Main Post-Merge Check (PRs #2128 and #2133)

Commits audited:
- **PR #2183 (`origin/codex/issue-2170`):** `427e9c202889b0ece607d370954873571490e231` (`427e9c202`, merge-base `96149fbb0`).
- **Live `main` (`origin/main`):** `38de52f028f1a84fd6c21ac2898f213c8f7ec588` (`38de52f02`, after PR #2128 merge `f0f187871` and PR #2133 merge `69b994bf4`, with Wounds V2 on by default).

## Lead Verdicts

1. **PR #2183 (`codex/issue-2170` @ `427e9c202`): HOLD / REQUEST CHANGES (1 High bug in Fix 2; Fixes 1, 3 and 4 are real and tested).**
   - Fix 1 (death cut race in `fx_ship.gd` / `fx_death.gd`), Fix 3 (symmetric Swivel Arc Mounts in `rules.gd`, 0 saved-battle deltas), and Fix 4 (fixed arc-T bearing test in `fx_hull.gd`) are real, tested, and merge cleanly against `main` `38de52f02`. No game rules change beyond the Swivel Arc flank change (`chaserArc`).
   - Fix 2 (`battle.gd` threat-worker input queue) has a real replay bug confirming and extending Artoo's review on PR #2183: `_replay_threat_inputs()` keeps popping queued inputs after an earlier replayed input starts `_cmd()` (`busy = true`), dropping follow-up intents and turning queued `Space` or `Enter` presses into unintended playback skips. Queued ledger actions and `_auto_end_finish` can also run behind an open modal Esc menu (`hud.menu`).
2. **Post-merge `main` (`38de52f02` after PR #2128 and PR #2133): BLOCKING CI BREAK ON `main` RIGHT NOW.**
   - **Direct PR #2128 x PR #2133 break:** PR #2128 added a 13th parameter `seed_override := -1.0` to `fx.gd:839-840` (`func ring`), while PR #2133 added `RecordFX.ring` in `godot/fx/test/weapon_layers_check.gd:36-37` with only 12 parameters. Running `weapon_layers_check.gd` on `main` fails immediately with a GDScript parse error (`EXIT=1`), breaking `Godot game checks` on `main` and every branch rebased onto it.
   - **Secondary `main` issues:** `look_bench.gd:962` still fails `--strict-moments` / `"strict": true` rows headlessly even after PR #2128 skipped headless grabs; `BOLT_BOMB` (sprite kind 32) writes premultiplied opacity (`0.72`) in `pools["spr"]` (`render_priority = 1`) instead of `pools["smk"]` (`-1`); PR #2128's `CORE_READ_PX` post-divisor floor enlarges bright death cores above `CORE_FLASH_PX / divisor` without raising the booked diameter in `fx.flash_ok()`; PR #2133's `STREAK_VERTEX` view-space axis (`k = 9..12`) ignores perspective foreshortening along PR #2128's low-angle chase cut-ins.
   - **Clean on `main`:** zero sprite, streak, or ring kind ID collisions across PR #2128, PR #2133, and Wounds V2; zero shader uniform collisions; Wounds V2 hooks in `look_bench.gd`, `fx_weapons.gd`, `fx_breach.gd`, and `fx_shaders.gd` remain intact (`big_moments_check.gd`, `frame_rate_steady_check.gd`, `wounds_v2_check.gd`, `hit_recipe_check.gd`, and `approved_effects_check.gd` all pass headlessly on `38de52f02`).

---

## Findings Table

### Blocking

| # | finding | OBSERVED/INFERRED | file:line | exact quote | why it matters | your fix | confidence |
|---|---|---|---|---|---|---|---|
| 1 | PR #2128 x PR #2133 clash breaks `main` CI: `RecordFX.ring()` overrides `fx.gd:ring()` with 12 params instead of 13 (`seed_override`). | OBSERVED | `godot/fx/test/weapon_layers_check.gd:36-37` (vs `godot/fx/fx.gd:839-840`) | `speed := 0.0, drag := 0.0, px := 0.0) -> void:` | Godot 4.7.2 fails `weapon_layers_check.gd` with `Parse Error: The function signature doesn't match the parent` (`EXIT=1`). `main` and any PR rebased onto `main` fail `Godot game checks`. | Add `seed_override := -1.0` to `RecordFX.ring()` and pass `seed_override` to `super.ring(...)` on `main` immediately. | high |

### High / Medium

| # | finding | OBSERVED/INFERRED | file:line | exact quote | why it matters | your fix | confidence |
|---|---|---|---|---|---|---|---|
| 2 | PR #2183 Fix 2: `_replay_threat_inputs()` keeps popping queued inputs after an earlier callback sets `busy = true`, dropping keys or turning `Space`/`Enter` into playback skip. | OBSERVED | `godot/scenes/battle/battle.gd:4647-4648` (`427e9c202`; also `:4993`, `threat_input_2170_check.gd:27-29`) | `while not _stale(g) and not quitting and not _threat_busy and not _threat_inputs.is_empty():` | First queued action calling `_cmd()` starts `_runner()` and sets `busy = true` synchronously. Remaining queued actions drop in `_can_act()`, and queued `Space`/`Enter` hits `:4993` (`skip = true`, `hurry_death()`). `TestBattle._cmd` never sets `busy`, so the new check missed it. | Stop the loop when `busy`, `thinking`, `warming`, `ended`, `api.phase != "player"`, or `hud.menu != null`; resume remaining same-activation intents when safe or drop stale ones on phase/activation change, and test with a `_cmd` that sets `busy = true`. | high |
| 3 | PR #2183 Fix 2: queued ledger buttons (`_end_ship`, `_undo`, `_confirm`) and `_auto_end_finish` can fire behind an open modal Esc menu. | OBSERVED | `godot/scenes/battle/battle.gd:3933` (`427e9c202`; also `:4964`, `:5000`) | `return not busy and not thinking and not warming and not _threat_busy and not ended and api != null and api.phase == "player"` | `KEY_ESCAPE` is not queued, so pressing Esc while `_threat_busy` opens `hud.menu` immediately. When the worker finishes, `_on_key` guards `hud.menu` (`:4964`), but `_end_ship`, `_undo`, `_confirm`, and `_auto_end_finish` only check `_can_act()`. | Guard `_can_act()` or `_replay_threat_inputs()` on `hud == null or hud.menu == null` (and clear or pause queued battle intents when opening the modal menu). | high |
| 4 | Main (`look_bench.gd`): headless runs of `--strict-moments` or `"strict": true` rows always fail because `clip_bad` still rejects `img == null` when headless. | OBSERVED | `godot/bench/look_bench.gd:962-963` (`38de52f02`; also `:949`, `:1000`) | `elif strict and keep:` / `clip_bad.append("cell %d (no frame grabbed)" % ci)` | PR #2128 skipped `_grab()` and `save_png()` when `headless` is true (`:949`, `:1002`) so timing checks run headlessly, but left `:962` unguarded, forcing `_fail_moment` at `:1000` on every strict row in headless mode. | Change line `962` to `elif strict and keep and not headless:` (and guard clip frame grabs at `:951` similarly if headless clip timing checks are used). | high |
| 5 | Main (`fx.gd` / `fx_shaders.gd`): `BOLT_BOMB` (sprite kind 32) writes premultiplied opacity (`0.72`) in `pools["spr"]` (`render_priority = 1`) instead of `pools["smk"]` (`-1`). | OBSERVED | `godot/fx/fx.gd:762,790` and `godot/fx/fx_shaders.gd:471-472` (`38de52f02`) | `var smoke := kind == SH.ROCKET_SMOKE or SMOKY.has(kind)` / `alpha = bolt.y * 0.72;` | Old bomb sprite `23` was in `SMOKY` so its opaque silhouette drew behind rings (`0`) and glow (`1`). Kind `32` replaced `23` with an opaque premultiplied capsule but stayed in `pools["spr"]`, where it can darken overlapping additive flashes and rings. | Add `32: true` to `SMOKY` in `godot/fx/fx.gd:762` (or include `kind == 32` at `:790`). | high |
| 6 | Main (`fx_death.gd` / `fx_shaders.gd`): PR #2128's `CORE_READ_PX` post-divisor floor enlarges bright (`soft == false`) core quads above `CORE_FLASH_PX / divisor`, understating bloomed area in `fx.flash_ok()`. | INFERRED | `godot/fx/fx_death.gd:113,116,4144` and `godot/fx/fx_shaders.gd:139-140` (`38de52f02`) | `size = max(size, px_world(read_pixels, -view_c.z, PROJECTION_MATRIX));` | Inferred from shader math: `CORE_FLASH_PX / divisor` is smaller than `CORE_READ_PX` on all 4 normal bands (small `88.2 < 112`, destroyer `110.4 < 135`, cruiser `153.3 < 178`, capital `308.8 < 330`), while `fx.flash_ok()` still books `CORE_FLASH_PX`. `big_moments_check.gd:124` compares `216 >= 112` (post-bloom vs pre-bloom), missing bloom overshoot. | Measure actual post-bloom bright diameters on GPU sheets (`2032_Torpedo_kill`, `2032_Capital_death`) and either book `maxf(px, CORE_READ_PX[band] * divisor)` in `flash_ok()` or recalibrate `CORE_READ_PX`. | med |
| 7 | Main (`fx_shaders.gd`): PR #2133 `STREAK_VERTEX` kinds `9..12` use raw view-space `h.xy - t.xy` with a horizontal fallback, which can skew or snap horizontal along PR #2128's chase cut-ins. | INFERRED | `godot/fx/fx_shaders.gd:658,660` (`38de52f02`; vs `camera_rig.gd:559`) | `vec2 delta = h.xy - t.xy;` / `vec2 axis = screen_length > 1e-4 ? delta / screen_length : vec2(1.0, 0.0);` | Inferred from projection math: unlike `k == 8` (`fx_shaders.gd:586-597`), `h.xy - t.xy` ignores perspective shift when `h.z != t.z` and falls back to `(1, 0)`. PR #2128's chase cut-ins look nearly down the line of fire (32-deg shoulder), where off-center bolts travel largely in view `-Z`. | Project `hc.xy/hc.w - tc.xy/tc.w` like `k == 8` (`fx_shaders.gd:586-597`) and fall back to projected `wdir` rather than `vec2(1.0, 0.0)`. | med |

### Low

| # | finding | OBSERVED/INFERRED | file:line | exact quote | why it matters | your fix | confidence |
|---|---|---|---|---|---|---|---|
| 8 | Minor gaps on `main` and PR #2183: `board.gd` `ReachOutline` omits `cut_overlay_alpha`; `look_bench.gd` `_frame_moment_volley` skips `_fail_moment()` warning prefix; PR #2183 `tables.json` `chaser` card text still says "one arc wider" without noting bow-only flanks. | OBSERVED | `godot/render/board.gd:629,221`; `godot/bench/look_bench.gd:633,645`; `godot/rules/rules.gd:483-485` (`427e9c202`) | `ALBEDO = vcol.rgb * vcol.a;` / `return side >= -0.5 and side <= 150.5` | `ReachOutline` stays bright if an enemy cut-in fires before `_clear_overlay()`; `_frame_moment_volley` omits the `"LOOK_BENCH "` log tag on failure; `MODULES.chaser.d` could mislead players about flank aft bearings (though saved rules results had 0 changes). | Add `cut_overlay_alpha` to `OUTLINE_SHADER` and `board.gd:629`; route `_frame_moment_volley` failures through `_fail_moment()`; confirm with Ryan whether to tighten `MODULES.chaser.d` wording. | high |

---

## Ready / Verified

- **PR #2183 Fix 1 (Death cut vs damage rebuild race, `fx_ship.gd` + `fx_death.gd`):** Verified. `_dmg_surfs` isolates joined worker output from in-flight `_dmg_job` (`fx_ship.gd:2298, 2477-2483`); `damage_revision` and `cut_matches_damage()` (`fx_ship.gd:2273, 2493`) block stale `cut_job`/`cut_prev` splits (`fx_death.gd:2955`); `flush_damage()` drains `_dmg_dirty` after death with `mesh_on_worker = false` and starts the cut via `DEATH.damage_settled()`; `death_poses` and `death_hull_motion` keep tell motion out of deferred cuts; covered by `death_damage_2170_check.gd` (`godot_checks.txt:138`). Minor non-blocking note: `fx_death.gd:1576` reads live turret node `global_transform.origin` rather than `death_poses` (only relevant if a turret root is itself a `MeshInstance3D` in `s.meshes`).
- **PR #2183 Fix 3 (Swivel Arc Mounts, `rules.gd:477-486`):** Verified symmetric (`S` `[0, 150]`, `P` `[-150, 0]`, dead astern `-180.0` rejected on both flanks per `ships.md` 4.2 / R456), exhaustively tested across all 6 facings in `swivel_flanks_2170_check.gd` (`godot_checks.txt:97`). Hosted CI `Godot rules (saved results)` and `Rules safety net` both passed green with 0 changed saved battles (all 379 battles including `r1653_chaser` unchanged). No other game rules changed.
- **PR #2183 Fix 4 (Fixed arc-T bearing test, `fx_hull.gd:1439`):** Verified. Non-turret arc-T mounts now run `maxf((pt["f"] as Vector3).dot(d), (pt["n"] as Vector3).dot(d)) > 0.2`; rotating turrets (`pt.has("tur")`) stay on `turret_reaches()`; covered by `fixed_t_bearing_2170_check.gd` (`godot_checks.txt:133`) and updated `attach_check.gd:423-433`. Zero rules impact.
- **PR #2183 merge compatibility with `main` (`38de52f02`):** `git merge-tree` against `origin/main` reports zero conflict markers across all 5 files touched on both sides (`fx_death.gd`, `fx_hull.gd`, `fx_ship.gd`, `battle.gd`, `godot_checks.txt`), and no semantic overlap with PR #2128 or PR #2133 hunks.
- **Main (`38de52f02`) sprite, streak, ring IDs and uniform/Wounds V2 audit:**
  - Sprites: Wounds V2 uses `25, 26, 27`; Build B uses `30..37` (`37` = `ROCKET_SMOKE` routed to `pools["smk"]`). Zero collisions.
  - Streaks: existing `0..8` (`5` routed to `pools["null"]`); Build B uses `9..12`. Zero collisions.
  - Rings: existing `0..4`; PR #2128 reserves `RING_DEATH_FRONT = 5` and checks `k == RING_DEATH_FRONT` before the `else` branch for kind 4 (`fx_shaders.gd:830-837`). Zero collisions.
  - Uniforms and pools: no cross-PR uniform collisions (`fx_power`, `fx_flick`, `fx_weather`, `fx_scorch_*`, `fx_v2`, `cut_overlay_alpha`, `read_pixels`, `gate`). `read_pixels` is only set in `_core_flash_inner`'s dedicated `"fbs|" + b` pool and does not leak into `_pic` (`"pic|..."`) or weapon `_burst` (`"fb|...|weapon"`).
  - Wounds V2 + R46 + faction rules: `look_bench.gd` retains Wounds V2 `focus == "wound"`, `open_mouths`, and `sync_t` flush alongside `cutin` and `shot_focus`. `fx_weapons.gd:252` applies `PLASMA_COL` to both `plasma` and `plasma_cannon` from muzzle to impact (R46), and `fx_weapons.gd:2277-2279` maps `plasma_cannon -> "plasma"` and keeps Wounds V2 `nlance` three-cut marks. Headless checks `big_moments_check.gd`, `frame_rate_steady_check.gd`, `wounds_v2_check.gd`, `hit_recipe_check.gd`, and `approved_effects_check.gd` all passed (`EXIT=0`) on `38de52f02`.

---

## Recommended Next Step

Land a 2-line hotfix PR on `main` first to add `seed_override := -1.0` to `RecordFX.ring()` in `godot/fx/test/weapon_layers_check.gd:36-39` (and guard `look_bench.gd:962` with `and not headless` plus add `32: true` to `SMOKY` in `fx.gd:762`), so `main` CI is green again; in parallel, run a short Codex follow-up on PR #2183 (`codex/issue-2170`) to fix `_replay_threat_inputs()` stopping on `busy` / modal `hud.menu` with a regression test whose `_cmd` sets `busy = true`.

---

## Files Read (Proof per `docs/REVIEW_PROTOCOL.md`)

### On `origin/main` (`38de52f02`)

| File | Total lines | First 40 chars of last line | Ranges read (for files > 1,500 lines or 60 KB) |
|---|---|---|---|
| `godot/fx/fx.gd` | 2544 | `\treturn hk` | `410-430`, `580-735`, `760-875`, `2215-2310` (plus full PR #2128 / #2133 diff hunks and greps) |
| `godot/fx/fx_shaders.gd` | 3043 | `"""` | `1-145`, `250-900` (plus all `k ==` / `kind ==` and uniform greps) |
| `godot/fx/fx_weapons.gd` | 2878 | `` (trailing blank; line 2876: `\t\t_craft_run(fx, C.faction, kind, from + `) | `1-150`, `230-360`, `420-630`, `698-764`, `860-1060`, `1110-1185`, `1215-1375`, `1665-1800`, `2270-2290` (plus full PR #2133 diff) |
| `godot/fx/fx_death.gd` | 4888 | `\t\tnd.global_position -= back` | `110-120`, `355-425`, `3195-3245`, `4105-4170` (plus full PR #2128 diff) |
| `godot/fx/fx_breach.gd` | 2437 | `\tm.set_shader_parameter("glow", Vector3(` | `855-960`, `1815-1935` |
| `godot/bench/look_bench.gd` | 1169 | `\t_clear()` | `600-1030` (plus full PR #2128 and #2133 diffs) |
| `godot/render/board.gd` | 1508 | `\t\tBV.outline(blocker_highlights, hex_wor` | `210-265`, `285-335`, `620-650` (plus full PR #2128 diff and mesh/overlay greps) |
| `godot/render/camera_rig.gd` | 459 | `\treturn p` | Full PR #2128 diff (`520-687` of diff covering all added/edited functions) |
| `godot/render/ship_view.gd` | 2348 | `\t\tring.rotation.y = -rotation.y` | Full PR #2128 diff (`630-825`, `885-925`) |
| `godot/render/weapon_layer_masks.gd` | 77 | `"""` | `1-77` (full file) |
| `godot/scenes/battle/battle.gd` | 8152 | `\tget_tree().quit(code)` | `7255-7290` and full PR #2128 diff (`165-175`, `2940-3070`, `3570-3655`, `7240-7345`) |
| `godot/fx/test/weapon_layers_check.gd` | 211 | `\tquit(0 if failures == 0 else 1)` | `1-211` (full file) |
| `godot/render/test/big_moments_check.gd` | 188 | `\tawait process_frame` | `1-188` (full file) |
| `godot/fx/API.md` | 657 | `neither these tools nor their pictures r` | PR #2133 diff (`430-445`, `485-505`) and Wounds V2 section (`270-300`) |

### On PR #2183 (`origin/codex/issue-2170` @ `427e9c202`)

| File | Total lines | First 40 chars of last line | Ranges read (for files > 1,500 lines or 60 KB) |
|---|---|---|---|
| `godot/fx/fx_ship.gd` | 3238 | `\treturn changed` | `2226-2350`, `2463-2500` and full PR #2183 diff |
| `godot/fx/fx_death.gd` | 4918 | `\t\tnd.global_position -= back` | `1471-1630`, `2531-2650`, `2893-2970` and full PR #2183 diff |
| `godot/fx/fx_hull.gd` | 2200 | `\t\t\t\t(lb["node"] as Node3D).transform = (` | `1391-1470` and full PR #2183 diff |
| `godot/rules/rules.gd` | 8015 | `\tB["aiActive"] = null; u["activated"] = ` | `456-510`, `relAng`/`inArc`/`_in_arc_angle`, and full PR #2183 diff |
| `godot/scenes/battle/battle.gd` | 8220 | `\tget_tree().quit(code)` | `1641-1695`, `4621-4695`, `4961-5080`, `5661-5780`, and full PR #2183 diff |
| `godot/fx/test/attach_check.gd` | 531 | `\treturn n` | Full PR #2183 diff (`420-435`) |
| `godot/fx/test/death_damage_2170_check.gd` | 95 | `\tquit(1 if failures else 0)` | `1-95` (full file) |
| `godot/fx/test/fixed_t_bearing_2170_check.gd` | 19 | `\t\tquit(0)` | `1-19` (full file) |
| `godot/rules/test/swivel_flanks_2170_check.gd` | 26 | `\tquit(1 if failures else 0)` | `1-26` (full file) |
| `godot/scenes/battle/test/threat_input_2170_check.gd` | 113 | `\tquit(1 if failures else 0)` | `1-113` (full file) |
| `godot/tools/ci/godot_checks.txt` | 300 | `headless|main/test/export_ship_check_tes` | Full PR #2183 diff (`90-145`) |

---

Not checked:
- Live GPU renders or frame-time captures for PR #2128 (`look_bench_2032.bat`), PR #2133 (`BUILD_B_2043.bat`), or Wounds V2 combined with them (no GPU capture run in this review-only pass; Findings 6 and 7 are marked INFERRED accordingly).
- Running the full 235-check Godot test suite or `--import` in this worktree (only `weapon_layers_check.gd`, `big_moments_check.gd`, `frame_rate_steady_check.gd`, `wounds_v2_check.gd`, `hit_recipe_check.gd`, and `approved_effects_check.gd` were executed locally on `38de52f02`; PR #2183's four new checks were inspected by code and verified via hosted CI green `All checks` on `427e9c202`).
- Unchanged sections of the large files (`battle.gd`, `rules.gd`, `fx_death.gd`, `fx_ship.gd`, `fx_weapons.gd`, `fx_shaders.gd`, `fx_breach.gd`, `fx.gd`, `fx_hull.gd`, `ship_view.gd`, `board.gd`) outside the listed line ranges and diff hunks.
- Interactive keyboard/mouse play in a windowed battle session.
