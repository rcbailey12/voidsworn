# Neon (audit): Nov 25-26 merged PR interaction audit at 157746b7

**Neon (audit):** Audited `main` at commit `157746b7` (`157746b79`, the live playtest build; `HEAD` at `2956a5678` only updates `contrib/opus/LOOP.md`, so all `godot/` files match `157746b7` byte-for-byte).

**Scope (10 PRs merged Nov 25-26, 2026):**
- PR #2068 (`d602b4e9b`) fire and damage plumes
- PR #2069 (`8944beb47`) Build D Nova, warp, blink, fold, ability pulses
- PR #2084 (`4ff279d58`) Build G (small-death vent jet, layered idle motion, shield collapse edge wave, terrain scorch, dust glint)
- PR #2049 (`8fa7ac8f1`) shared sparks (`fx.spark` / `fx.flight_streak`)
- PR #2215 (`b193fe726`) wreck and dead-ship retirement
- PR #2232 (`264d3c92b`) Neon 2211 fixes
- PR #2233 (`157746b79`) portraits in game
- PR #2193 (`3078d5a41`) Wounds V2 follow-up
- PR #2219 (`9cd055a11`) Duet rules R1-R7
- PR #2202 (`233476291`) Glasswright music

**Verdict:** 1 Blocking interaction bug, 3 High and 3 Medium cross-PR findings (7 total). The biggest live playtest defect is Glasswright Blink stretching an unbroken world-space engine trail across the hex grid between old and new hexes, followed by fled ships bypassing PR #2215/#2049 retirement, Glasswright smoke/soot leaks in PR #2084 and PR #2069, and hulk/wing plumes omitting PR #2068 Wounds V2 tints and profiles.

---

## Summary Table

| # | finding | OBSERVED/INFERRED | file:line | exact quote | why it matters | your fix | confidence |
|---|---|---|---|---|---|---|---|
| 1 | Blink (`fx.fold`) drags engine trail across battlefield and triggers false thrust/cough | OBSERVED | `godot/scenes/battle/battle.gd:2263`, `godot/fx/fx_ship.gd:745` | `var at: float = gfx.fold(id, speed, func blink_snap() -> void: sv.position = dst)` | Every Glasswright Blink stretches a bright multi-hex ribbon across the board for up to 2.6 s and spikes `_moving = 0.4`. | Add `ship.reset_trail_on_teleport()` called right after `transfer.call()` in `SPECIAL.fold` to clear `_trails[i]["hist"]` and sync `_last_pos`, and pause trail sampling while `_rift_start >= 0.0`. | High |
| 2 | Fled ships (`jump_out`) bypass `fx.remove_ship`, `_clear_thrust_spark_sink`, and `_park_dead_view` | OBSERVED | `godot/fx/fx_special.gd:225`, `godot/scenes/battle/battle.gd:2466` | `ship.teardown(fx, false)` | Torn-down fled `FxShip` stays in `fx.ships`, keeps PR #2049 `_thrust_spark_sink` closure on `ShipView`, and leaves fled `ShipView._process` running (missed by PR #2215). | In `SPECIAL.jump` `escape()`, call `fx.remove_ship(ship.id)` (after `hide_live_hull`) and in `battle.gd` `"fled"`, call `_retire_dead_plate` and `_park_dead_view(sv)` after `await _await_fx(at)`. | High |
| 3 | Glasswrights (`ithar`) get dark soot-grey gas in `_split_vent` (`SH.VENT_JET=40`) and smoke (`k=27`) in `SPECIAL.bay` | OBSERVED | `godot/fx/fx_death.gd:3055`, `godot/fx/fx_special.gd:267` | `base = mix(vCol.rgb * 0.30, vec3(0.14, 0.14, 0.16), 0.55) * (0.65 + 0.55 * n1);` | Violates the zero-smoke Glasswright crystal palette on small hull deaths (PR #2084) and `i_carrier`/`i_carrier_a` wing launches (PR #2069). | Gate `SH.VENT_JET` dark gas body on `smoke_k > 0.01` (or emit clean prism/spark burst for `ithar`), and branch `ship.faction == "ithar"` in `SPECIAL.bay` to crystal/light motes instead of `k=27`. | High |
| 4 | Hulk cold vents and damaged squadron wings omit `_plume_glow()` and `profile` in `DAMAGE_PLUME.build` | OBSERVED | `godot/fx/fx_death.gd:3940`, `godot/fx/fx_ship.gd:2858` | `DAMAGE_PLUME.Form.HULK, s.fac, 0.12, "fx_hulk_vent")` | Chorus hulks/wings vent bright lime instead of R420 ochre (`chorus_gas`); Meridian hulks/wings vent metal soot instead of `Profile.ELECTRIC`; Eclipse misses `Profile.VIOLET`. | Pass `s._plume_glow()` and a shared `s._plume_profile()` helper from both `fx_death._hulk` and `fx_ship._build_wing_smoke`. | High |
| 5 | `SPECIAL.GHOST` warms only on `BoxMesh` (not hull vertex formats); `SH.IDLE_MOTION` is un-warmed | OBSERVED (warmup code) / INFERRED (driver hitch) | `godot/fx/fx.gd:2319`, `godot/fx/fx_special.gd:178`, `godot/fx/fx_idle.gd:270` | `mats.append(mat(SPECIAL.GHOST, -2))` | Same primitive-vs-GLB vertex-format gap PR #2232 fixed for `RCS_JET` and `conduit`; first `fold`/`blink` on an imported hull can compile a late pipeline. `SH.IDLE_MOTION` compiles outside warmup when enabled. | Warm `SPECIAL.GHOST` once per hull vertex format in `fx._warm_hull_meshes` (like `SH.MELT_GLOW`), and warm `SH.IDLE_MOTION` in `fx.warmup()` when `IDLE.enabled()`. | Medium |
| 6 | Tidal `tick_flare` computes pale blue-white `tint` then drops it in `fx.spark()` | OBSERVED | `godot/fx/fx_ship.gd:3386` | `var tint: Color = fac.damage_glow if faction == "deathless" else Color(0.7, 0.8, 1.0)` | PR #2049 migration left `tint` unused; non-Eclipse tidal stress sparks silently draw as orange/faction `SparkRole.HULL` instead of pale tidal blue-white. | Pass `fx.SparkRole.HULL, tint` as the trailing arguments to `fx.spark(...)` on `fx_ship.gd:3388`. | High |
| 7 | `godot/fx/API.md` still documents retired idle-motion sprites (`kind 18`) and omits PR #2084/#2049 contract changes | OBSERVED | `godot/fx/API.md:77` | `one batch of soft sprites (kind 18, no peak)` | Violates R214 (working docs land with code changes) and misleads future seats touching `fx_idle.gd`, `SH.VENT_JET`, or `fx.spark`/`fx.flight_streak`. | Update `godot/fx/API.md` section 2 (idle motion uses `SH.IDLE_MOTION`), section 5 (small deaths use `SH.VENT_JET`), and document `fx.spark` / `fx.flight_streak`. | High |

---

## Blocking

### 1. Blink (`fx.fold`, PR #2069) drags engine trails across the battlefield and triggers false thrust/cough (`fx_ship.gd`) [OBSERVED]

- **Where:**
  - `godot/scenes/battle/battle.gd:2263`: `var at: float = gfx.fold(id, speed, func blink_snap() -> void: sv.position = dst) if gfx != null else -1.0`
  - `godot/fx/fx_special.gd:196-205`: `ship.start_rift_pose(t, depart, false, fx.reduce_motion)` ... `if blink: transfer.call()` ... `ship.start_rift_pose(t + depart, reveal, true, fx.reduce_motion)`
  - `godot/fx/fx_ship.gd:623-627`: `var moved = pos.distance_to(_last_pos) if _last_pos != Vector3.INF else 0.0` / `if moved > 1e-4:` / `_moving = 0.4`
  - `godot/fx/fx_ship.gd:742-745`: `var active_burn: bool = (not dead or flaring) and lvl > 0.12 and not (_moving > 0.0 and engine_level < 0.12)` / `hist.push_front([start, _tclock, lvl_t])`
- **Why it happens (cross-PR interaction):**
  1. Parked ships hold `IDLE_GLOW * engine_level = 0.3 > 0.12`, so `active_burn` is `true` and `hist` already contains a nozzle point at the origin hex (and more points if the ship moved earlier in the turn or during the depart pinch, where `_apply_rift_pose` shifts `hull_pivot.position` by `0.43 * L` and `xf()` reads `hull_motion()`).
  2. When `fold_release()` runs inside `_run_later()` (`fx.gd:557-564`), `transfer.call()` snaps `sv.position = dst` (1 to 4+ hexes away, 17 to 70+ world units). Neither `SPECIAL.fold` nor `battle.gd` clears `ship._trails` or updates `ship._last_pos`.
  3. On the very same frame's `ship.update()`, `pos.distance_to(_last_pos)` measures the full teleport jump (`> 1e-4`), forcing `_moving = 0.4` (flaring `_eng_cur` toward `1.6`, and firing damaged-nozzle `_cough`/`_stern_sparks` if `sick_nozzle >= 0` at `fx_ship.gd:645-648`).
  4. `_update_trails()` sees `(hist[0][0]).distance_to(start) > 1.2 * fx.unit`, pushes the destination nozzle straight onto the front of `hist` while `hist[1]` is still at the origin hex, and renders an unbroken glowing trail ribbon across the entire battlefield for up to `TRAIL_LIFE` (2.6 s).
- **Fix:** Add `reset_trail_on_teleport()` on `FxShip` that clears each `t["hist"]`, hides `t["mi"]`, and sets `_last_pos = root.global_position` (clearing `_moving = 0.0`). Call it inside `SPECIAL.fold` right after `transfer.call()`. Also guard `active_burn` (or skip pushing new trail samples) while `_rift_start >= 0.0` so the pinched `hull_pivot.scale` (`(1.54, 0.16, 0.09)`) never stamps distorted nozzle coordinates into `hist`.

---

## High / Medium

### 2. Fled ships (`jump_out`, PR #2069) bypass PR #2215 retirement and PR #2049 spark-sink cleanup [OBSERVED, High]

- **Where:**
  - `godot/fx/fx_special.gd:221-225`: `ship.clear_rift_pose()` / `ship.hide_live_hull()` / `ship.teardown(fx, false))`
  - `godot/fx/fx.gd:1936-1942`: `_clear_thrust_spark_sink(ships[id].root)` / `(ships[id] as SHIP).teardown(self)` / `ships.erase(id)`
  - `godot/scenes/battle/battle.gd:2461-2476`: `var at: float = gfx.jump_out(str(e["unit"]), speed) if gfx != null else -1.0` / `sv.dead = true`
- **Why it happens (cross-PR interaction):**
  - PR #2215 added `_retire_death_view` and `_park_dead_view(sv)` for `"death"`, and PR #2049 added `_clear_thrust_spark_sink(ships[id].root)` inside `fx.remove_ship` and `fx.release` (not inside `SHIP.teardown`).
  - PR #2069's `"fled"` path calls `ship.teardown(fx, false)` directly inside `SPECIAL.jump`'s `escape()` lambda instead of `fx.remove_ship(ship.id)`.
  - Consequence: (1) the torn-down `FxShip` stays in `fx.ships[id]` until battle end (visited in `fx.step` and `fx_death.update` loops), (2) `sv._thrust_spark_sink` retains its bound `fx` closure until `fx.release()`, and (3) `battle.gd` never calls `_park_dead_view(sv)` on a fled ship, so the hidden `ShipView` keeps running `_process` every frame for the rest of the battle.
- **Fix:** Have `SPECIAL.jump`'s `escape()` call `ship.hide_live_hull(); fx.remove_ship(ship.id)` (note `teardown` already calls `clear_rift_pose` and cleans all children), and in `battle.gd`'s `"fled"` branch call `_retire_dead_plate(str(e["unit"]), sv)` immediately and `_park_dead_view(sv)` once `await _await_fx(at)` finishes.

### 3. Glasswright (`ithar`) smoke/soot leaks in PR #2084 (`_split_vent`) and PR #2069 (`SPECIAL.bay`) [OBSERVED, High]

- **Where:**
  - `godot/fx/fx_death.gd:3055-3057`: `fx.spr(p, fx.now, 0.30, fire_col, 2.2 if ignited else 0.45, s.hull.L * 0.28, s.hull.L * 0.52, SH.VENT_JET, jet_vel, 1.8)` / `if smoke_k > 0.01:`
  - `godot/fx/fx_shaders.gd:547-548`: `alpha = clamp(body * (0.55 + 0.55 * n2) * gas_fade * 0.65, 0.0, 1.0);` / `base = mix(vCol.rgb * 0.30, vec3(0.14, 0.14, 0.16), 0.55) * (0.65 + 0.55 * n1);`
  - `godot/fx/fx_special.gd:267`: `fx.spr(lip, t + 0.2, 0.65, c, 0.43, k * 0.6, k * 3.2, 20 if ship.faction == "chorus" else 27, axis * 3.1 + side * rail, 1.8)`
- **Why it happens:**
  1. In `_split_vent` (PR #2084), Layer 2 (`fx_death.gd:3057-3069`) carefully branches on `if smoke_k > 0.01:` so Glasswrights (`smoke: 0.0` in `faction_looks.json`) get crystal shards (`k=16`) instead of smoke (`k=27`). However, Layer 1 on line 3055 runs unconditionally before that check and emits `SH.VENT_JET` (`k=40`), whose fragment shader (`fx_shaders.gd:547-548`) renders an opaque dark-grey soot body (`vec3(0.14, 0.14, 0.16)`, `alpha` up to `0.65`) in `blend_premul_alpha` (`pools["spr"]`). When `ignited` is `false` (flash budget refused), the hot core drops to `0.45` and the dark grey soot cone dominates on a Glasswright hull.
  2. In `SPECIAL.bay` (PR #2069), carrier launch emits `20 if ship.faction == "chorus" else 27` (`k=27`, unlit ragged smoke sheet routed to `pools["smk"]` via `SMOKY` in `fx.gd:791`) on Glasswright carriers (`i_carrier` and `i_carrier_a` in `godot/rules/data/tables.json`, both `ab: "launch"`).
- **Fix:** In `_split_vent`, either gate `SH.VENT_JET` on `smoke_k > 0.01` (using a clean prismatic/crystal jet for `ithar`) or pass a smoke weight / separate non-soot mode so `ithar` draws zero dark grey alpha body. In `SPECIAL.bay`, replace `k=27` for `ship.faction == "ithar"` with clean prism/light motes (`k=16` / `k=18`).

### 4. Hulk cold vents and damaged squadron wings omit PR #2068 Wounds V2 glow tint and profile [OBSERVED, High]

- **Where:**
  - `godot/fx/fx_death.gd:3940-3941`: `var vent := DAMAGE_PLUME.build(fx, node, p, (n + Vector3.UP * 0.3).normalized(), maxf(s.hull.L * 0.20, 0.12),` / `DAMAGE_PLUME.Form.HULK, s.fac, 0.12, "fx_hulk_vent")`
  - `godot/fx/fx_ship.gd:2858-2859`: `_wing_smoke = DAMAGE_PLUME.build(fx, parent, p, Vector3.LEFT, length, DAMAGE_PLUME.Form.WING,` / `fac, phase, "fx_wing_damage_smoke")`
  - `godot/fx/fx_ship.gd:2786-2803`: `var plume := DAMAGE_PLUME.build(fx, _dmg_root, p, axis, length, form, fac, phase, "fx_damage_" + e.id, glow, profile)`
  - `godot/fx/fx_damage_plume.gd:57-75`: `var sheath := Color(0.075, 0.085, 0.10) if cold else Color(0.030, 0.026, 0.025)`
- **Why it happens (cross-PR interaction):**
  - PR #2068 added `_plume_glow()` and `profile` (`Profile.ELECTRIC` for `hegemony`, `Profile.VIOLET` for `deathless`) in `fx_ship._attach_damage_plume()` to honour R420 / Wounds V2 (`chorus_gas` ochre for Chorus, cool blue electric vent for Meridian Directorate, muted violet for Eclipse).
  - Neither `fx_death._hulk` (touched by both PR #2068 and PR #2215) nor `fx_ship._build_wing_smoke` passes `tint` or `profile`, so both fall back to `fac.damage_glow` and `Profile.BASE`:
    - Chorus hulks and damaged spore squadrons vent bright bile lime (`[0.55, 0.85, 0.15]`) instead of R420 ochre (`chorus_gas`).
    - Meridian Directorate hulks and damaged wings vent dark metal soot (`Color(0.075, 0.085, 0.10)`) and warm `damage_glow` instead of `Profile.ELECTRIC`.
    - Eclipse hulks and wings use raw `damage_glow` instead of `wound.interior_accent` and `Profile.VIOLET`.
- **Fix:** Extract `func _plume_profile() -> DAMAGE_PLUME.Profile` on `FxShip` alongside `_plume_glow()`, and pass both from `_build_wing_smoke` (`fx_ship.gd:2858`) and `_hulk` (`fx_death.gd:3940`).

### 5. Warmup vertex-format gap for `SPECIAL.GHOST` (PR #2069) and un-warmed `SH.IDLE_MOTION` (PR #2084) [OBSERVED / INFERRED, Medium]

- **Where:**
  - `godot/fx/fx.gd:2319`: `mats.append(mat(SPECIAL.GHOST, -2))` (drawn on `BoxMesh` at `fx.gd:2388`)
  - `godot/fx/fx_special.gd:178-179`: `echo.mesh = part.mesh` / `echo.material_override = m`
  - `godot/fx/fx.gd:2546-2606`: `_warm_hull_meshes` warms `SH.TEAR`, `SH.MELT_GLOW`, and `INTERIOR` per hull vertex format, omitting `SPECIAL.GHOST`
  - `godot/fx/fx_idle.gd:270`: `var material: ShaderMaterial = fx.mat(SH.IDLE_MOTION, 1)` (not referenced in `fx.gd:warmup()`)
- **Why it happens (cross-PR interaction):**
  - PR #2232 specifically fixed primitive-`BoxMesh` vs live-`ArrayMesh` vertex-format warmup mismatches for `RCS_JET` and `conduit` (`fx.gd:2392-2398`).
  - PR #2069 warmed `SPECIAL.GHOST` only on `BoxMesh` (`fx.gd:2319`), whereas live `_ghost()` applies it to imported GLB hull `part.mesh`es whose surface vertex formats differ from `BoxMesh`. On Forward+, the first `fold`/`blink` on an imported hull can trigger a late pipeline compile (INFERRED; not GPU-captured here).
  - PR #2084 replaced idle-motion kind-18 sprites with `SH.IDLE_MOTION`, which is absent from `fx.gd:warmup()`. Safe today only because `VS_IDLE_MOTION` defaults off; once enabled, late-arriving ships or first-frame draw will compile it outside warmup.
- **Fix:** In `fx._warm_hull_meshes`, warm `SPECIAL.GHOST` once per hull vertex format (`fmt_key`, mirroring `SH.MELT_GLOW` on `fx.gd:2558-2562`), and in `fx.warmup()` append `mat(SH.IDLE_MOTION, 1)` when `IDLE.enabled()`.

### 6. Tidal `tick_flare` drops its computed `tint` after PR #2049 `fx.spark()` migration [OBSERVED, Medium]

- **Where:**
  - `godot/fx/fx_ship.gd:3386-3388`: `var tint: Color = fac.damage_glow if faction == "deathless" else Color(0.7, 0.8, 1.0)` / `fx.spark(wp + fx.rdir() * 3.0 * k, T + fx.rng.randf() * 0.3, 0.5, faction, 4.0, 0.15, 0.1, fx.rdir() * 6.0, 0.5)`
- **Why it happens:**
  - PR #2049 converted the tidal stress burst to `fx.spark(...)` but omitted the optional `role` and `tint` trailing arguments, leaving `tint` computed and unused on line 3386. Non-Eclipse metal hulls now emit orange/faction `SparkRole.HULL` sparks instead of pale tidal blue-white (`Color(0.7, 0.8, 1.0)`).
- **Fix:** Pass `0.0, 0.0, fx.SparkRole.HULL, tint` to `fx.spark(...)` at `fx_ship.gd:3388`.

### 7. `godot/fx/API.md` contract drift after PR #2084 and PR #2049 [OBSERVED, Medium]

- **Where:**
  - `godot/fx/API.md:77`: `one batch of soft sprites (kind 18, no peak)`
  - `godot/fx/fx_idle.gd:270`: `var material: ShaderMaterial = fx.mat(SH.IDLE_MOTION, 1)`
- **Why it happens:**
  - PR #2084 replaced `fx_idle.gd`'s soft sprite batch (`kind 18`) with the layered `SH.IDLE_MOTION` shader and replaced small-death bow vent flipbook puffs with `SH.VENT_JET = 40` (`fx_death.gd:3055`), without updating `godot/fx/API.md:77` or `API.md:120` (R214: doc changes land with working method changes).
- **Fix:** Update `godot/fx/API.md` section 2 (idle motion uses `SH.IDLE_MOTION` layered anchor + motion quads) and section 5 (small deaths use `SH.VENT_JET = 40` directional rupture jet).

---

## Ready / Verified

Cross-PR interactions checked in live `157746b7` code and verified clean:

1. **PR #2215 (dead-ship retirement) x PR #2232 (`ShipView.dead` setter) x Eclipse `risen`:**
   - `ship_view.gd:38-42` clears top-level RCS puffs as soon as `sv.dead = true`, so `battle.gd:3844-3846` (`_death_view_has_tail`) never stalls retirement on lingering puffs.
   - `battle.gd:2535-2539` (`_reassemble`) clears `plate_off`, removes `death_view_parked`, and re-enables `sv.set_process(true)` before re-registering FX on Eclipse `risen`.
   - `fx_death.gd:4670` (`_glue`) populates `wreck["heat_births"]` for glued pieces in `"two"` and `"late"` breakups, so PR #2215's `w["cold"]` and `w["settled"]` flags retire all 3 breakup variants cleanly.
   - `fx_death.gd:3942, 3948-3956` (`_thin_hulk_vent`) ticks hulk vent thinning independently on `fx.later` to `HULK_SETTLE_S = 60.0` s even after the hulk wreck itself settles and stops ticking per frame.
2. **PR #2068 (`DEATH_FLIPBOOK` pools) x PR #2069 (`nova`) x PR #2232 (`read_pixels`):**
   - `nova` (`fx_special.gd:91-99`, `pool_tag = "nova"`), `status_fire` (`fx_status_tick.gd:30-40`, `pool_tag = "status_fire"`), weapon impacts (`pool_tag = "weapon"`), and staged death cores (`fx_death.gd:4383`, key `"fbs|" + b`) use distinct picture pool keys, preventing `read_pixels`, `soft_flash`, and `calm_intensity` uniform bleed across callers.
3. **PR #2193 (Wounds V2 follow-up) x PR #2068 (`fx_shaders.gd`):**
   - `fx_shaders.gd:3057-3081` (Glasswright pearl fracture lines + Eclipse obsidian step chip with `hs = 1.0` guarded by `wound_v2 != 5`) and `fx_shaders.gd:3297-3342` (Glasswright `glass_reveal` pearl fill and `METALLIC`/`SPECULAR` suppression) merged cleanly without colliding with PR #2068 or PR #2232 edits in `fx_shaders.gd`.
4. **PR #2219 (Duet rules R1-R7):**
   - `rules.gd:2828` (`TORP_GHOST_KEYS`) includes both `"treeHuntRearNext"` and `"treeTeethUsed"`, so spending one-shot rear bonuses on the torpedo ghost in `_landVolley_raw` (`rules.gd:4001-4002`) propagates back to the real ship.
   - `o["per"]` in `_landVolley_raw` (`rules.gd:4000`) has only one caller (`torpImpact`, `rules.gd:2867`), which matches the 2-argument signature `func(rear, first_rear)`.
   - `oathEscorted` (`rules.gd:2704`) iterates `caps("player")` (`rules.gd:595-599`), which already filters dead/off-board units and squadrons.
5. **PR #2202 (Glasswright music):**
   - Both `godot/music/tracks/glasswright_combo2_calm.ogg` (2.55 MB) and `glasswright_combo2_full.ogg` (3.53 MB) exist on disk and match `godot/music/stem_pairs.json:6,33-44`.
   - `music_player.gd:254-275` selects `ithar` stem pair on normal Glasswright battles (`bed_id = ""`) and cleanly falls back to `music.json:548-551` (`fac_ithar`) for boss fights and `play_faction_preview("ithar")`.
6. **PR #2233 (Portraits in game):**
   - All 12 run-4 paintings (`godot/portraits/painted/*.webp`) and 9 preserved previous picks (`godot/portraits/alts/*_pre1897.webp`) are present and match `godot/portraits/index.json`.
   - `godot/rules/captain_data.gd:65-71` claims existing valid portrait IDs before assigning faces, so adding `ashgrove`, `maren`, and `anuket` to `captain_pool` does not churn faces on older saves.
7. **PR #2084 (`terrain_scorch.gd` & `world_rocks.gd`):**
   - `godot/fx/terrain_scorch.gd` is registered in `godot/render/static_caches.gd:18`, so its four static `ImageTexture` caches are released cleanly on exit (`clear_static()`).
   - `world.gd:1547` and `world_living.gd:380-529` use `TIME` consistently with all existing backdrop shaders in `world_living.gd`.

---

## Recommended Next Step

Open a small follow-up fix PR on `main` addressing Findings 1 to 4 first (highest player-facing impact in the live playtest: Blink trail reset in `fx_special.gd`/`fx_ship.gd`, fled-ship retirement via `fx.remove_ship` + `_park_dead_view`, Glasswright non-smoke guards in `_split_vent` and `SPECIAL.bay`, and passing `_plume_glow()` + `_plume_profile()` in `_hulk` and `_build_wing_smoke`), bundling Findings 5 to 7 (`SPECIAL.GHOST` hull-format warmup, `tick_flare` `tint`, and `API.md`) in the same cleanup pass.

---

## File Read Receipts

| file | total lines | last line (first 40 chars) | line ranges read (files > 1,500 lines) |
|---|---|---|---|
| `godot/scenes/battle/battle.gd` | 8272 | `\tget_tree().quit(code)` | 2245-2285, 2450-2585, 3680-3865, 7355-7420 |
| `godot/fx/fx_special.gd` | 273 | `\tfx.sprx(6.0, p, t, 0.18, c, 1.0, k * 1.` | full |
| `godot/fx/fx_ship.gd` | 3414 | `\treturn changed` | 1-3414 (full, in chunks) |
| `godot/fx/fx.gd` | 2606 | `\treturn hk` | 1-2606 (full, in chunks) |
| `godot/fx/fx_death.gd` | 5185 | `\t\tnd.global_position -= back` | 1-560, 620-1000, 2680-3150, 3350-4450, 4600-5185 |
| `godot/fx/fx_shaders.gd` | 3762 | `"""` | 1-1600, 1900-2350, 2950-3762 |
| `godot/fx/fx_damage_plume.gd` | 114 | `\t\tplume.queue_free()` | full |
| `godot/fx/fx_idle.gd` | 273 | `\t\t"layers": LAYERS_PER_SPOT, "particles"` | full |
| `godot/fx/fx_boarding.gd` | 110 | `\tfx.light(p + n * 0.9, t, 2.15, 3.8, tin` | full |
| `godot/fx/fx_breach.gd` | 2445 | `\tm.set_shader_parameter("glow", Vector3(` | 1-400 + PR #2193 diff |
| `godot/fx/fx_status_tick.gd` | 139 | `\tfx.light(p + n * 0.7, t, STORM_LIFE, 2.` | 1-120 |
| `godot/fx/terrain_scorch.gd` | 212 | `\t_plasma = ImageTexture.create_from_imag` | full |
| `godot/fx/faction_look.gd` | 110 | `\treturn tint if tint is Color else look[` | full |
| `godot/fx/faction_looks.json` | 124 | `}` | full |
| `godot/fx/API.md` | 679 | `neither these tools nor their pictures r` | 1-180 |
| `godot/render/ship_view.gd` | 2420 | `\t\tring.rotation.y = -rotation.y` | 1-120, 780-1200, 1600-1800, 2100-2420 |
| `godot/render/fx_conduit.gd` | 105 | `\treturn node` | full |
| `godot/world/world.gd` | 1651 | `\tif _living != null: _living.use_ship_de` | PR #2084 diff (1525-1560) |
| `godot/world/world_living.gd` | 1763 | `\t\tif c != null: m.set_shader_parameter(p` | 300-600 + `TIME` grep |
| `godot/world/world_rocks.gd` | 610 | `\t\t\t(entry["decal"] as Decal).transform =` | 495-610 |
| `godot/music/music_player.gd` | 434 | `\t\t"bed_db": _bed.volume_db, "single": _s` | full |
| `godot/music/stem_pairs.json` | 46 | `}` | full |
| `godot/music/music.json` | 556 | `}` | 1-250, 470-556 |
| `godot/portraits/portraits.gd` | 377 | `\t_rfac.clear()` | full |
| `godot/portraits/index.json` | 1295 | `}` | 1-250 + PR #2233 diff |
| `godot/rules/rules.gd` | 8046 | `\tB["aiActive"] = null; u["activated"] = ` | 595-606 + full PR #2219 diff |
| `godot/rules/test/rules_2204_test.gd` | 230 | `\t\t"R7 a reserve carrier arrives and exha` | full |

---

## Not checked

- Live GPU execution, frame-time profiling, and visual screenshot/video capture (Forward+ or Compatibility renderer) were not run in this audit; Finding 5's pipeline hitch on `SPECIAL.GHOST` is therefore marked `INFERRED` from the warmup code.
- Headless Godot test suites (`godot_checks.txt`) were not re-executed here (CI already ran them on `main` at `157746b7`).
- Binary `.webp` portrait image aesthetics (PR #2233), `.ogg` audio mix/loop seams (PR #2202), and compressed `.jsonl.br` saved campaign/rules recordings (PR #2219, PR #2233) were verified for file presence and loader contracts only, not visually/aurally inspected.
- Compatibility renderer (`gl_compatibility`) runtime behavior of `Decal` nodes in `terrain_scorch.gd` / `world_rocks.gd` was not executed on GPU.
