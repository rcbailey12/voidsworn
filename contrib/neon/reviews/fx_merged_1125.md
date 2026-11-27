Neon (audit): Pre-playtest FX silent-regression audit of `main` at commit `a0c5d5dbf` (`a0c5d5dbf765724cf3f850050702115cbd7fc54a`), covering PRs 2055 (drive plumes and RCS jets), 2132 (boarding and status ticks), 2136 (layered beams), and 2137 (wreck breaks, scorched edges, and kit interiors), plus their interaction with PRs 2128 (cut-in camera and `CORE_READ_PX`) and 2133 (layered bolts, ordnance, and muzzles) already on `main`.

**Verdict: 0 Blocking, 4 High, 4 Medium.** No kind-number collisions and no headless runtime regressions on `main`, so nothing crashes a playtest exe build. Fix H1 through H4 before building Ryan's playtest exe so Glasswright deaths/ticks/boarding, beam charge rings, and boarding/storm conduits do not ship with silent visual defects.

---

## Files Read (Proof of Read, commit `a0c5d5dbf`)

| File | Lines | Ranges read | First 40 chars of last line |
| --- | ---: | --- | --- |
| `godot/fx/fx_shaders.gd` | 3379 | 1-3379 (full) | `"""` |
| `godot/fx/fx.gd` | 2467 | 1-2467 (full) | `\treturn hk` |
| `godot/fx/fx_weapons.gd` | 2936 | 1-2936 (full) | `` (trailing blank line; L2935: `\t\treturn 1`) |
| `godot/fx/fx_ship.gd` | 3295 | 1-3295 (full) | `\treturn changed` |
| `godot/fx/fx_death.gd` | 5070 | 1-5070 (full) | `\t\tnd.global_position -= back` |
| `godot/fx/fx_death_beats.gd` | 592 | 455-540 (targeted) | `\t\t\t_implode(fx, s, p, T - 0.25)` |
| `godot/fx/fx_breach.gd` | 2440 | 1-800 + PR 2136 diff | `\tm.set_shader_parameter("glow", Vector3(` |
| `godot/fx/fx_boarding.gd` | 109 | 1-109 (full) | `\tfx.light(p + n * 0.9, t, 2.15, 3.8, tin` |
| `godot/fx/fx_status_tick.gd` | 139 | 1-139 (full) | `\tfx.light(p + n * 0.7, t, STORM_LIFE, 2.` |
| `godot/fx/fx_event_paths.gd` | 88 | 1-88 (full) | `\tlive.clear()` |
| `godot/fx/thrust_profile.gd` | 83 | 1-83 (full) | `\t\t\treturn {"core": core, "wash": wash, "` |
| `godot/fx/faction_looks.json` | 118 | 1-118 (full) | `}` |
| `godot/render/fx_conduit.gd` | 103 | 1-103 (full) | `\treturn node` |
| `godot/render/weapon_layer_masks.gd` | 77 | 1-77 (full) | `"""` |
| `godot/render/ship_view.gd` | 2411 | 1-2411 (full) | `\t\tring.rotation.y = -rotation.y` |
| `godot/render/camera_rig.gd` | 459 | 1-459 (full) | `\treturn p` |
| `godot/render/squadron_wing.gd` | 480 | 1-480 (full) | `\tmesh.surface_end()` |
| `godot/bench/look_bench.gd` | 1236 | 1-1236 (full) | `\t_clear()` |
| `godot/render/board.gd` | 1508 | PR 2128 diff | `\t\tBV.outline(blocker_highlights, hex_wor` |
| `godot/render/line_style.gd` | 212 | PR 2128 diff | `\t\tst.add_vertex(v[0])` |
| `godot/scenes/battle/battle.gd` | 8152 | PR 2128 diff | `\tget_tree().quit(code)` |
| `godot/ui/battle/hud.gd` | 1557 | PR 2128 diff | `\tledger.mark()` |
| `godot/fx/test/event_layers_2046_check.gd` | 195 | 1-195 (full) | `\tquit(1 if fails else 0)` |
| `godot/render/test/big_moments_check.gd` | 188 | 1-188 (full) | `\tawait process_frame` |
| `godot/fx/test/trail_kit_isolation_check.gd` | 111 | 1-111 (full) | `\tquit(1 if failures > 0 else 0)` |
| `godot/fx/test/layered_beam_check.gd` | 197 | 1-197 (full) | `\tquit(1 if failures else 0)` |

---

## Godot Headless Checks on `main` (`a0c5d5dbf`)

Ran with Windows Godot `4.7.2.stable.official.ed1daf0bf` (`Godot_v4.7.2-stable_win64_console.exe`) after `godot --headless --path godot --import` (exit 0) to populate `.godot/imported`:

- `fx/test/load_all.gd`: **PASS** (`load all: 468 scripts, 17 scenes, 0 failed`, exit 0).
- All 86 `headless|(fx|render)/` entries in `godot/tools/ci/godot_checks.txt`: **85 passed, 1 failed**.
  - Sole failure: `fx/test/death_seam_check.gd` failed only on `_fixture_fresh()` (`the C19_51 fixture is stale: A16's sheet files changed since it was exported`, line 93), which CI runs in its own fresh-bake step (`step:A16 death seam (fixture or fresh bake)`). All live PR 2137 seam and interior checks inside that run passed (`machines_split=0`, `inside_outside_hull=0`, `fitted_outside=0`, `pieces_with_bulkhead_decks_ribs=3`).
  - All new PR test suites passed: `rcs_cone_jet_check`, `moving_trail_anchor_check`, `trail_kit_isolation_check`, `main_plume_kit_check`, `craft_trail_unify_check` (2055), `event_layers_2046_check` (2132), `layered_beam_check` & `pixel_scale_check` (2136), `death_authored_check` & `faction_death_style_check` (2137), `big_moments_check` (2128), `weapon_layers_check` & `frame_rate_steady_check` (2133).
- 5 related `scenes/battle/test/` checks (`movement_flight_check`, `movement_stage2_check`, `wreck_hex_check`, `shield_overlap_check`, `shield_handoff_check`): **5/5 PASS**.
- `node contrib/opus/tools/check_em_dashes.js`: **PASS**.

---

## Blocking

None.

---

## High

### H1. PR 2055 `RIBBON` kind `0` engine-plume rewrite hijacks Glasswright death light shafts and Hullbreaker tether cables and drops their fade (Trap 5, Trap 8)

- **Location**: `godot/fx/fx_shaders.gd:1099-1102`, `godot/fx/fx_shaders.gd:1158-1159`, `godot/fx/fx_death_beats.gd:476`, `godot/fx/fx_death_beats.gd:508`
- **Quote**:
  - `godot/fx/fx_shaders.gd:1099`: `if (k == 0 || k == 3) {`
  - `godot/fx/fx_shaders.gd:1159`: `ALBEDO = clamp(colour * vCol.a * fx_gain, 0.0, 512.0);`
  - `godot/fx/fx_death_beats.gd:508`: `fx.rib(center, d, L * 0.5, T + j * 0.05, 0.9, cols[j],` (passes `kind = 0`)
- **Status**: OBSERVED
- **Confidence**: High
- **Why it matters**: PR 2055 assumed `RIBBON` kind `0` belonged exclusively to looping ship engine plumes (`fx_ship.gd`), routing all `k == 0 || k == 3` into `custom_plume = true` with turbulent Mach-diamond exhaust geometry (`mach`, `turbulence`, `bell_in`) and skipping `env` (`smoothstep` fade-in and fade-out) at line 1159. One-shot `fx.rib(..., 0)` callers in `fx_death_beats.gd` (`_shafts` for Glasswright deaths and `_cables` for Hullbreaker tethered wreck splits) now render as turbulent Mach-diamond exhaust flames that snap on and off with zero fade instead of soft light shafts or taut cables.
- **One-line fix**: Gate `custom_plume` on `a4.z > 0.0` (looping engine plumes pass `period = 1.0`; one-shot `fx.rib` passes `0.0`), keeping `k == 0` with `a4.z <= 0.0` on the original clean ribbon path with `env`.

### H2. PR 2132 `fx_conduit.gd` omits `fx_gain` (~1.8x over-bright under ACES) and omits `fx_px` (Trap 3, Trap 4)

- **Location**: `godot/render/fx_conduit.gd:8`, `godot/render/fx_conduit.gd:22`, `godot/render/fx_conduit.gd:48`
- **Quote**:
  - `godot/render/fx_conduit.gd:22`: `float floor_r = pixels * max(-centre.z, .01) / max(abs(PROJECTION_MATRIX[1][1]) * 540.0, .01);`
  - `godot/render/fx_conduit.gd:48`: `ALBEDO = mix(hue * .68, core.rgb * 1.65, axial);`
- **Status**: OBSERVED
- **Confidence**: High
- **Why it matters**: Every effect shader in `fx_shaders.gd` multiplies `ALBEDO` by `global uniform float fx_gain` (`0.5556` under Godot's ACES tonemapper, `fx_shaders.gd:11-12`) and scales pixel readability floors by `global uniform float fx_px`. Because `fx_conduit.gd` declares only `fx_calm`, all boarding conduits, pods, cutter rings, storm arcs, and tidal streams draw ~80% hotter than calibrated FX and ignore `fx_px = 0.0` toggles.
- **One-line fix**: Declare `global uniform float fx_gain;` and `global uniform float fx_px;` in `godot/render/fx_conduit.gd`, multiply `ALBEDO` by `fx_gain`, and multiply `floor_r` by `fx_px`.

### H3. PR 2136 `RING_HARMONIC` (`rk == 6`) flat 36 px vertex floor freezes Glasswright beam charge rings at camera 170 (Trap 2, Trap 4)

- **Location**: `godot/fx/fx_shaders.gd:792`, `godot/fx/fx_weapons.gd:660-665`, `godot/fx/fx_weapons.gd:682-687`
- **Quote**:
  - `godot/fx/fx_shaders.gd:792`: `size = max(size, px_world(36.0, dv, PROJECTION_MATRIX));`
  - `godot/fx/fx_weapons.gd:664-665`: `fx.ring(focus + dir * float(j) * 0.42 * k, dir, fire - life, life, col, col_k, (1.75 if needle else 3.6) * k, 0.45 * k, ring_kind,`
- **Status**: OBSERVED
- **Confidence**: High
- **Why it matters**: At the staging camera (`r = 170`, `STAGING_UNITS_PER_PIXEL = 0.1302`), `px_world(36.0, 170) = 4.69` world units. Both `needle` (`1.75 -> 0.45`) and `pulsar` (`3.6 -> 0.45`) charge rings stay below `4.69` for their entire lifetime at `k = 1.0`, so `max(size, 4.69)` pins them to a static 36 px hexagon that never converges into the emitter (unlike `rk == 1..3` at line 801 which eases its floor with `mix(0.15, 1.0, g)`). Pulsar travelling wavefronts (`3.8 -> 5.2`) also stall at 36 px for most of their travel.
- **One-line fix**: Scale the `rk == 6` pixel floor proportionally to `mix(a3.x, a3.y, g) / max(max(a3.x, a3.y), 1e-4)` so converging charge rings shrink and travelling wavefronts grow cleanly at camera 170.

### H4. PR 2132 Glasswright faction violations: fire-tick `fac_prism` is dead without `ROUTE_BAKED`, and boarding a Glasswright hull vents grey smoke (Trap 5, Trap 7)

- **Location**: `godot/fx/fx_status_tick.gd:30-31`, `godot/fx/fx_death.gd:281`, `godot/fx/fx_shaders.gd:198-214`, `godot/fx/test/event_layers_2046_check.gd:74-75`, `godot/fx/fx_boarding.gd:88`, `godot/fx/fx_boarding.gd:108`
- **Quote**:
  - `godot/fx/fx_shaders.gd:198`: `#ifdef ROUTE_BAKED` (wraps the only read of `fac_prism`, line 210)
  - `godot/fx/fx_boarding.gd:88`: `var organic: bool = recipe.look == "umbilical" or target.faction == "chorus"`
- **Status**: OBSERVED
- **Confidence**: High
- **Why it matters**: (1) `fx_status_tick.gd:30-31` calls `DEATH.flipbook(..., staged = false, ..., "status_fire")`, which builds `SH.DEATH_FLIPBOOK` without `#define ROUTE_BAKED` in production (`fx.fx_atlas == ""` at `fx_death.gd:281, 300`). Because `fac_prism` is read only inside `#ifdef ROUTE_BAKED` (`fx_shaders.gd:210`), Glasswright fire ticks never render a prismatic edge even though `event_layers_2046_check.gd:74-75` asserts `fac_prism == 1.0` as passing proof. (2) `fx_boarding.gd:88, 105-108` emits 10 sprites of grey vent smoke (`kind = 7`) on every non-organic target, including Glasswright (`ithar`) hulls, breaking the Glasswright no-smoke rule that `fx_status_tick.gd:38` enforced in the same PR.
- **One-line fix**: Apply `fac_prism` outside `#ifdef ROUTE_BAKED` in `DEATH_FLIPBOOK` (or route `status_fire` through `ROUTE_BAKED`), and exclude `target.faction == "ithar"` from `kind = 7` vent smoke in `fx_boarding.gd:105-108` (emit `kind = 16` prismatic chips or omit smoke).

---

## Medium

### M1. PR 2128 `CORE_READ_PX` widens pre-bloom death cores at camera 170 without updating `fx.flash_ok` area booking (Trap 3, Trap 7)

- **Location**: `godot/fx/fx_death.gd:125`, `godot/fx/fx_death.gd:4312`, `godot/fx/fx_death.gd:4321`, `godot/fx/fx_shaders.gd:150-154`, `godot/render/test/big_moments_check.gd:124`
- **Quote**:
  - `godot/fx/fx_shaders.gd:153`: `size = max(size, px_world(read_pixels, -view_c.z, PROJECTION_MATRIX));`
  - `godot/render/test/big_moments_check.gd:124`: `_check(float(fx.flash_area_log[0][3]) >= float(DEATH.CORE_READ_PX["small"]), "the flash counter accounts for the enlarged core")`
- **Status**: OBSERVED (shader math and booking); INFERRED (post-bloom screen area delta without GPU capture)
- **Confidence**: High
- **Why it matters**: `CORE_FLASH_PX` (`216 / 255 / 302 / 423`) and `size_divisor` (`2.45 / 2.31 / 1.97 / 1.37`) were calibrated together so pre-bloom cards (`88.2 / 110.4 / 153.3 / 308.8 px`) bloom to `CORE_FLASH_PX`. Applying `read_pixels = CORE_READ_PX` (`112 / 135 / 178 / 330`) after dividing by `size_divisor` enlarges pre-bloom cards at camera 170 by +7% to +27% (+61% area on small hulls), while `fx.flash_ok` still books only `CORE_FLASH_PX`, and `big_moments_check.gd:124` passes vacuously (`216 >= 112`). On close cut-ins (`r = 26..45`), `extent / size_divisor` already exceeds `CORE_READ_PX`, so cut-in framing is unaffected.
- **One-line fix**: Pass `maxf(px, float(CORE_READ_PX[band]) * divisor)` to `fx.flash_ok` in `fx_death.gd:4312` so WCAG flash-area accounting matches the enlarged card plus bloom.

### M2. PR 2132 `tick_flare` emits blue-white metal sparks on Eclipse and Glasswright tidal ticks (Trap 5, Trap 7)

- **Location**: `godot/fx/fx_ship.gd:3245`, `godot/fx/fx_ship.gd:3250`
- **Quote**:
  - `godot/fx/fx_ship.gd:3245`: `if kind == "tidal" and faction != "chorus":`
  - `godot/fx/fx_ship.gd:3250`: `fx.stk(wp + fx.rdir() * 3.0 * k, T + fx.rng.randf() * 0.3, 0.5, Color(0.7, 0.8, 1.0),`
- **Status**: OBSERVED
- **Confidence**: High
- **Why it matters**: Every non-Chorus faction hit by a `"tidal"` status tick sheds 20 blue-white `Color(0.7, 0.8, 1.0)` metal sparks (`stk kind = 1`), leaking blue-white sparks onto Eclipse (`deathless`, violet-only rule) and metal sparks onto Glasswrights (`ithar`, crystal/light only). `event_layers_2046_check.gd:92` only exercised `"tidal"` on `"chorus"`.
- **One-line fix**: Tint tidal sparks from `fac.damage_glow` (violet on Eclipse) and skip metal sparks or emit crystal chips (`kind = 16`) on Glasswrights.

### M3. PR 2055 live `top_level` RCS cone jets outlive hull breakup/death and warm up on the wrong vertex format (Trap 1, Trap 2)

- **Location**: `godot/render/ship_view.gd:853-863`, `godot/render/ship_view.gd:2200-2210`, `godot/fx/fx_ship.gd:365-373`, `godot/fx/fx.gd:2184`
- **Quote**:
  - `godot/render/ship_view.gd:2200`: `mi.top_level = true`
  - `godot/fx/fx.gd:2184`: `mat(SH.NULL_SLUG, 1), mat(SH.TRAIL, 1), mat(SH.RCS_JET, 1), mat(DEATH.SLAG, 0)]`
- **Status**: OBSERVED (lifecycle and warmup code); INFERRED (first-use pipeline compile hitch on GPU)
- **Confidence**: Medium-High
- **Why it matters**: (1) RCS cone jets are `top_level = true` children of `ShipView` tracked in `puffs`. When a ship breaks up (`hide_live_hull` hides meshes/attachments while `ShipView` stays visible) or `die(true)` turns it into a wreck, active `puffs` are not cleared and hang at the vanished hull's coordinates until `life` (up to ~0.35 s) expires. (2) Unlike PR 2132 (`fx_conduit` tube warmup at `fx.gd:2257`) and PR 2137 (`SLAG` cap warmup at `fx.gd:2275`), PR 2055 warms `SH.RCS_JET` only on `BoxMesh` (`VERTEX + NORMAL + UV`), whereas `ShipView._rcs_quad_mesh()` (`ship_view.gd:2104-2124`) is a `VERTEX`-only indexed `ArrayMesh`, which can trigger a late Vulkan pipeline compile on the first thruster puff.
- **One-line fix**: Free active `puffs` in `ShipView.die()` (and when `dead` turns true in `_step_motion`), and warm `SH.RCS_JET` using `SHIP_VIEW._rcs_quad_mesh()` in `fx.warmup()`.

### M4. PR 2132 `TICK_DROPLET` (`39`) missing from `SPRITE` vertex `k == 15` brightness and stretch guards (Trap 4)

- **Location**: `godot/fx/fx_shaders.gd:350`, `godot/fx/fx_shaders.gd:359`, `godot/fx/fx_shaders.gd:461`
- **Quote**:
  - `godot/fx/fx_shaders.gd:350`: `boost = (k == 15 || k == 23) ? 1.0 : clamp(spow(gf, dimx), 0.03, 1.0);`
  - `godot/fx/fx_shaders.gd:359`: `if (k == 14 || k == 15 || k == 23 || k == 27 || (k >= 30 && k <= 33) || k == 36 || k == 37) {`
- **Status**: OBSERVED
- **Confidence**: High
- **Why it matters**: `TICK_DROPLET` (`39`) shares `k == 15` (bio glob) in `SPRITE` `fragment()` (line 461) and emits with a 4 px floor (`fx_status_tick.gd:61`), but was omitted from the `k == 15` checks in `SPRITE` `vertex()`. At camera 170, droplets dim by `gf^-0.5` when floored and spin as unstretched sprites instead of stretching along spray velocity.
- **One-line fix**: Add `|| k == 39` beside `k == 15` on `godot/fx/fx_shaders.gd:350` and `godot/fx/fx_shaders.gd:359`.

---

## Ready / Verified

- **Kind-number registry audit (issue 2176 skipped) - ZERO numeric clashes**:
  - `SPRITE`: legacy `0..5, 7, 8, 11..27`; PR 2133 `30..37` (`BOLT_PLASMA=30`, `BOLT_BIO=31`, `BOLT_BOMB=32`, `MUZZLE_BALLISTIC=33..36`, `ROCKET_SMOKE=37`); PR 2132 `38..39` (`TICK_EMBER=38`, `TICK_DROPLET=39`).
  - `STREAK`: legacy `0, 1, 3, 4, 5 (NULL_SLUG), 6, 7, 8`; PR 2133 `9..12` (`BOLT_SHELL=9..BOLT_SCRAP=12`).
  - `RING`: legacy `0..4`; PR 2128 `5` (`RING_DEATH_FRONT=5`); PR 2136 `6` (`RING_HARMONIC=6`).
  - `RIBBON`: legacy `0, 1, 3, 6, 9, 10 (ECLIPSE_ARC)`; PR 2136 `2, 5, 7, 8, 11 (RIB_NULL_LANCE -> nlance pool)`. No numeric overlap; semantic overlap on kind `0` is logged in H1.
  - `DISTORT`: legacy `0, 1`; PR 2136 `2` (`DISTORT_BEAM=2`).
  - `MARK/HOLE` styles (`fx_breach.gd`): `0..15`, `S_PRISM=16`, `S_STAR=17`, `S_NLANCE=18`.
- **Torpedo and rocket trails after PR 2055**: `SH.kit_trail_code()` (`fx_shaders.gd:1375-1400`) strips all `CUSTOM1` references, leaves `use_strip_taper = 0.0`, and preserves `ROCKET_SMOKE` (37) and `ORDNANCE_CORONA` (PR 2133); `trail_kit_isolation_check.gd` passes. Informational note (not a 2055 regression): style 3 intentionally keeps its orange sparkle (`vec3(1.0, 0.5, 0.15)` at `fx_shaders.gd:1362`), and `deathless` (`faction_looks.json:108`) is the only faction configured with `trail: 3`, so Eclipse ship and torpedo trails still show pre-existing orange flecks.
- **Shield-absorbed hits staying quiet (R412 rule 4)**: Verified across `fx_weapons.gd` (`_impact:2288-2313`, `_shield_impact:2439-2525`), `fx_ship.gd` (`shield_hit:1166-1168`, `_show_rcs:1443`, `hit_power:1632`), and PR 2132 `_storm` (`fx_status_tick.gd:111-116`): absorbed hits keep `strained = false`, zero hull marks, zero brownout/power dip, and no RCS stumble.
- **PR 2137 wreck breaks, scorched edges, and kit interiors**: `SLAG` shader cleanly separates `CAP_METAL=0`, `CAP_GLASS=1` (frosted pearl glass from `faction_looks.json`, no metal rim/petals), and `CAP_FLESH=2` (umber hide + bone struts, zero fire emission); `SEAM_COOL = 3.0s` cools seams independently of outer `WRECK_COOL`; `SectionFit` keeps all 34,638 fitted interior vertices inside A16's hull envelope (`fitted_outside=0`).
- **PR 2128 cut-in camera and overlay fade**: `camera_rig.gd` unwraps angles and restores camera poses cleanly; `battle.gd` / `board.gd` / `ship_view.gd` / `hud.gd` fade and restore overlays without reviving dead rings (`big_moments_check.gd` PASS).
- **PR 2133 layered bolts, ordnance, and muzzles**: Plasma keeps R46 light blue across all factions; Glasswright and Chorus muzzles emit no ballistic smoke or metal sparks (`weapon_layers_check.gd` PASS).

---

## Recommended next step

Fix H1 (`RIBBON` kind 0 gating), H2 (`fx_conduit` `fx_gain`/`fx_px`), H3 (`RING_HARMONIC` easing floor), and H4 (Glasswright `fac_prism` and boarding smoke) in one small follow-up PR on `main` (before or alongside PR 2068), then run the GPU look-bench/capture verification before building Ryan's playtest exe.

Not checked: GPU visual captures and frame-time profiling (headless only in this review), real installed ship GLB assets in `godot/gen` (absent from this worktree, so only stand-in box hulls and the A16 fixture were exercised), interaction with unmerged PR 2068 (fire), and non-FX campaign/UI/audio/rules headless test suites (`campaign/`, `rules/`, `ui/`, `audio/`).
