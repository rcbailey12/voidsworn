# Neon (audit): Five Green AAA Effects PRs (2133, 2136, 2132, 2137, 2128)

- **Issue:** `#2165`
- **Seat:** Neon (T3)
- **Reviewed against `origin/main`:** `d5a0ce610` (`d5a0ce610` LOOP Nov 25 16:00 UTC, after PRs 1755 Wounds V2, 1904 Acid Thorns, 1763 Interior Kit V2, 2102 Camera Zoom, 2105 Step 0, 2138 Shader Pow, 2154 Battle to Title)
- **PR heads reviewed:**
  - PR `#2133` (`codex/issue-2043`): `48deac499` (base `649f694d6`, 154 commits behind `main`)
  - PR `#2136` (`codex/issue-2047`): `57b7943d0` (base `deec695cb`, 152 commits behind `main`)
  - PR `#2132` (`codex/issue-2046`): `4cb23fa78` (base `649f694d6`, 154 commits behind `main`)
  - PR `#2137` (`codex/issue-2022`): `7a23418ed` (base `deec695cb`, 152 commits behind `main`)
  - PR `#2128` (`codex/issue-2032`): `03d963155` (base `17b151f03`, 155 commits behind `main`)
- **Checklist:** `.agents/skills/independent-audit/SKILL.md` and `docs/REVIEW_PROTOCOL.md`

---

## Summary Verdicts

None of the five PRs should be merged straight onto `d5a0ce610` as-is: four of the five already fail `git merge-tree` against `origin/main`, the two clean-merging pairs (`2133` vs `2132`) contain a silent `SPRITE` kind-ID collision (`30..31`), `2136` and `2128` collide on `RING` kind `5`, `2136` collides with merged `origin/main` Wounds V2 on breach style `16`, and three PRs (`2133`, `2132`, `2137`) break binding faction or colour rules. All five are solid implementations underneath and need targeted rebases and fixes, not rewrites.

| PR | Issue | Head SHA | Verdict | `merge-tree` vs `main` | Cross-PR Clash | Faction / Rule Break | Frame-Time Impact |
|---|---|---|---|---|---|---|---|
| `#2133` | `#2043` Build B (bolts, ordnance, muzzles) | `48deac499` | **fix first** | Clean (exit 0) | Silent `SPRITE` `30..31` clash with `#2132`; `look_bench.gd` conflict with `#2128` | **Yes:** breaks RULEBOOK 6.13 / R46 (Sunward plasma turns orange) | Low-moderate (24/s smoke quads per kit rocket; corona warmed) |
| `#2136` | `#2047` Build F (beams) | `57b7943d0` | **fix first** | **Conflict** (`fx_breach.gd`, `fx_shaders.gd`, `fx_weapons.gd`) | `RING` kind `5` clash with `#2128`; `S_NULL_BURN := 16` clashes with `main` `S_PRISM := 16` | None (Glasswright no-refraction R421 and Eclipse violet clean) | Low (`nlance` pool warmed; 5 Max-only distortion quads on `nlance`) |
| `#2132` | `#2046` Build E (ticks, storm, boarding) | `4cb23fa78` | **fix first** | **Conflict** (`look_bench.gd`) | Silent `SPRITE` `30..31` clash with `#2133`; `look_bench.gd` + `look_bench_sheets.py` with `#2128` | **Yes:** `_fire` emits dark grey soot (`kind 8`) on Glasswrights and Chorus | Low steady-state (3 to 7 main-thread `SurfaceTool` meshes per event; shader warmed) |
| `#2137` | `#2022` (wreck scorched edges + kit fill) | `7a23418ed` | **fix first** | **Conflict** (`fx_death.gd`) | None among the 5 (touches `fx_death.gd` disjoint from `#2128`; wait/sync with `#2007`) | **Yes:** Glasswright cap near-black (`0.028` linear); Chorus cap keeps pre-V2 magenta-plum | Worker-thread cut cost (`TriangleMesh` + ray fit); lit `SLAG` GPU cost small |
| `#2128` | `#2032` (big moments, cut-ins, c170 kills) | `03d963155` | **fix first** | **Conflict** (`look_bench.gd`, `godot_checks.txt`) | `RING` kind `5` clash with `#2136`; `look_bench.gd` with `#2133`/`#2132`; `look_bench_sheets.py` with `#2132` | None (faction death light colours kept; drops off-plane drop-lines uncovered in cut-ins) | Negligible steady-state (1 soft ring per death; check first-cut torus `transparency` switch) |

---

## Proof of Files Read (`docs/REVIEW_PROTOCOL.md` Section 1)

All five full PR diffs (`git diff -U4 <merge-base>..<head>`) were read end-to-end: `pr_2133.diff` (1301 lines), `pr_2136.diff` (1273 lines), `pr_2132.diff` (1470 lines), `pr_2137.diff` (1177 lines), and `pr_2128.diff` (1269 lines). Big files (over 1,500 lines) were inspected by exact cited line ranges listed below.

| Ref | File | Total Lines | First 40 Chars of Last Line | Ranges Read (Big Files) |
|---|---|---:|---|---|
| `origin/main` (`d5a0ce610`) | `godot/fx/fx_weapons.gd` | 2822 | `` (trailing blank; L2820: `\t\t_craft_run(fx, C.faction, kind, from +`) | L50-59, L236-315, L395-439, diff vs `deec695cb` |
| `origin/main` (`d5a0ce610`) | `godot/fx/fx_shaders.gd` | 2973 | `"""` | L2010-2043, diff vs `deec695cb` (Wounds V2, styles 16-18) |
| `origin/main` (`d5a0ce610`) | `godot/fx/fx_breach.gd` | 2399 | `\tm.set_shader_parameter("glow", Vector3(` | L45-79, diff vs `deec695cb` (`marks_for`) |
| `origin/main` (`d5a0ce610`) | `godot/fx/fx_death.gd` | 4874 | `\t\tnd.global_position -= back` | L110-214, `_core_flash`, `flipbook`, diff vs `deec695cb` |
| `origin/main` (`d5a0ce610`) | `godot/fx/fx_ship.gd` | 3227 | `\treturn changed` | L103-112, `setup`, `sync`, `tick_flare`, `_acid_colour` |
| `origin/main` (`d5a0ce610`) | `godot/fx/fx.gd` | 2542 | `\treturn hk` | `SMOKY`, `_emit_spr`, `dst`, diff vs `17b151f03` |
| `origin/main` (`d5a0ce610`) | `godot/fx/faction_looks.json` | 118 | `}` | Full file (L1-118) |
| `origin/main` (`d5a0ce610`) | `godot/bench/look_bench.gd` | 1059 | `\t_clear()` | Diff vs `17b151f03` |
| `origin/main` (`d5a0ce610`) | `godot/render/ship_view.gd` | 2315 | `\t\tring.rotation.y = -rotation.y` | `drop`/`drop_dot`, `_ring`, `set_marker`, diff vs `17b151f03` |
| `origin/main` (`d5a0ce610`) | `godot/render/board.gd` | 1491 | `\t\tBV.outline(blocker_highlights, hex_wor` | Overlay declarations, diff vs `17b151f03` |
| `origin/main` (`d5a0ce610`) | `godot/render/camera_rig.gd` | 354 | `\treturn p` | Diff vs `17b151f03` (`zoom_at`, `_set_pose`) |
| `origin/main` (`d5a0ce610`) | `godot/scenes/battle/battle.gd` | 8183 | `\tget_tree().quit(code)` | `_cine_*`, `show_tip`, `plates_root`, diff vs `17b151f03` |
| `codex/issue-2043` (`48deac499`) | `godot/fx/fx_weapons.gd` | 2877 | `` (trailing blank; L2875: `\t\t_craft_run(fx, C.faction, kind, from +`) | L60-74, L432-511, L871-935, L971-1020, L1405-1416 + full diff |
| `codex/issue-2043` (`48deac499`) | `godot/fx/fx_shaders.gd` | 2581 | `"""` | L458-479 + full diff |
| `codex/issue-2043` (`48deac499`) | `godot/fx/fx.gd` | 2509 | `\treturn hk` | Full diff |
| `codex/issue-2043` (`48deac499`) | `godot/render/weapon_layer_masks.gd` | 77 | `"""` | Full file (L1-77) |
| `codex/issue-2043` (`48deac499`) | `godot/fx/test/weapon_layers_check.gd` | 185 | `\tquit(0 if failures == 0 else 1)` | Full file (L1-185) |
| `codex/issue-2047` (`57b7943d0`) | `godot/fx/fx_breach.gd` | 1883 | `\t\t_tube(pt, points, e.R * 0.06, e.R * 0.` | L50-57 + full diff |
| `codex/issue-2047` (`57b7943d0`) | `godot/fx/fx_shaders.gd` | 2637 | `"""` | L674-683, L717-728, L2228-2245 + full diff |
| `codex/issue-2047` (`57b7943d0`) | `godot/fx/fx_weapons.gd` | 2871 | `` (trailing blank; L2869: `\t\t_craft_run(fx, C.faction, kind, from +`) | L2258-2265 + full diff |
| `codex/issue-2047` (`57b7943d0`) | `godot/fx/fx.gd` | 2515 | `\treturn hk` | Full diff |
| `codex/issue-2046` (`4cb23fa78`) | `godot/fx/fx_shaders.gd` | 2521 | `"""` | L242-249 + full diff |
| `codex/issue-2046` (`4cb23fa78`) | `godot/fx/fx.gd` | 2428 | `\treturn hk` | L755-762 + full diff |
| `codex/issue-2046` (`4cb23fa78`) | `godot/fx/fx_status_tick.gd` | 137 | `\tfx.light(p + n * 0.7, t, STORM_LIFE, 2.` | Full file (L1-137) |
| `codex/issue-2046` (`4cb23fa78`) | `godot/fx/fx_boarding.gd` | 109 | `\tfx.light(p + n * 0.9, t, 2.15, 3.8, tin` | Full file (L1-109) |
| `codex/issue-2046` (`4cb23fa78`) | `godot/fx/fx_event_paths.gd` | 88 | `\tlive.clear()` | Full file (L1-88) |
| `codex/issue-2046` (`4cb23fa78`) | `godot/render/fx_conduit.gd` | 103 | `\treturn node` | Full file (L1-103) |
| `codex/issue-2046` (`4cb23fa78`) | `godot/fx/fx_ship.gd` | 3096 | `\treturn changed` | Full diff |
| `codex/issue-2046` (`4cb23fa78`) | `godot/bench/look_bench.gd` | 967 | `\t_clear()` | L780-810 + full diff |
| `codex/issue-2046` (`4cb23fa78`) | `godot/fx/test/event_layers_2046_check.gd` | 182 | `\tquit(1 if fails else 0)` | Full file (L1-182) |
| `codex/issue-2022` (`7a23418ed`) | `godot/fx/fx_death.gd` | 5021 | `\t\tnd.global_position -= back` | L155-178, L1570-1577, L1765-1776, L2351-2385 + full diff |
| `codex/issue-2022` (`7a23418ed`) | `godot/fx/test/faction_death_style_check.gd` | 262 | `\treturn int(pool.get("emitted"))` | Full diff |
| `codex/issue-2032` (`03d963155`) | `godot/fx/fx_shaders.gd` | 2537 | `"""` | L676-683, L718-731 + full diff |
| `codex/issue-2032` (`03d963155`) | `godot/fx/fx_death.gd` | 4864 | `\t\tnd.global_position -= back` | L4118-4133 + full diff |
| `codex/issue-2032` (`03d963155`) | `godot/render/ship_view.gd` | 2347 | `\t\tring.rotation.y = -rotation.y` | L755-778, L800-831 + full diff |
| `codex/issue-2032` (`03d963155`) | `godot/render/board.gd` | 1472 | `\t\tBV.outline(blocker_highlights, hex_wor` | L606-617 + full diff |
| `codex/issue-2032` (`03d963155`) | `godot/render/camera_rig.gd` | 396 | `\t\tpose_applied.emit()` | L348-367 + full diff |
| `codex/issue-2032` (`03d963155`) | `godot/scenes/battle/battle.gd` | 8075 | `\tget_tree().quit(code)` | L7178-7191 + full diff |
| `codex/issue-2032` (`03d963155`) | `godot/bench/look_bench.gd` | 1018 | `\t_clear()` | L820-855 + full diff |
| `codex/issue-2032` (`03d963155`) | `tools/pc/jobs/look_bench_sheets.py` | 318 | `    sys.exit(main())` | Full diff |

---

## PR `#2133` (`codex/issue-2043` @ `48deac499`) -- Verdict: **fix first**

- **Issue `#2043` match:** Covers all three requested Build B items: (1) layered core + tapered sheath masks in `STREAK` (`9..12`) and `SPRITE` (`30..32`) for `macro`, `auto`, `junk`, `scatter`, `las`, `prism`, `plasma`, `plasma_cannon`, `flak`/`pflak`/`mflak`/`gflak`/`gsentry`, `guns`, `bombs` (new capsule mask `BOLT_BOMB`, no longer craft silhouette `23`), `spores`, `sporeb`, `bioplasma`; (2) star torpedo corona (`ORDNANCE_CORONA`), rocket smoke wake (`ROCKET_SMOKE`), procedural fallback torpedo wake via `_kit_trail_start`, layered PD intercept tracer + flash + ring; (3) unified `_muzzle` kit (`33..36`) removing ballistic Cone-B smoke from `las`/`prism` and layering `auto`/`plasma`/`flak`/`bioplasma`. Leaves Acid Thorns (`#1904`), torpedo bodies, and `#2018` sparks alone.
- **Faction & colour rules:** **Fails RULEBOOK 6.13 / R46 ("Plasma is light blue").** Overrides `PLASMA_COL` with `fac["weapon"]` for `plasma` and `plasma_cannon` flight/muzzle tints (Sunward turns orange, Eclipse turns violet) while leaving their impacts light blue. Glasswright `prism` and `mflak` clean (no smoke, pale cyan-white sheath); Chorus `bioplasma`/`spores` clean (no metal sparks, bile tint).
- **Clashes (`main` & peer PRs):** `git merge-tree` against `origin/main` exits `0`, and against `#2136`/`#2137` exits `0`. **Silent semantic collision** with `#2132` (`SPRITE` kinds `30..31`; `git merge-tree` exits `0`!) and open PRs `#2084` (`30`) and `#2069` (`34`). Textual conflict with `#2128` in `godot/bench/look_bench.gd`.
- **Frame time:** Low-moderate. `ORDNANCE_CORONA` is warmed in `fx.warmup()` (0 late shader compiles). Rocket salvos (`4` rockets) now run `_projectile_exhaust` alongside `_kit_trail_push` at `24` smoke puffs/s per rocket (up from `10/s` fallback-only, `0.30 s` life = ~29 live `fbm` quads per salvo in `pools["smk"]`, scaled `0.6x` on `low`).

### Findings (`#2133`)

#### Blocking

| # | Finding | OBSERVED/INFERRED | File:Line | Exact Quote | Why It Matters | Your Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 1 | `plasma` and `plasma_cannon` override `PLASMA_COL` with `fac["weapon"]`, breaking RULEBOOK 6.13 (R46). | OBSERVED | `godot/fx/fx_weapons.gd:436` (and `491-492`, `498-499`), vs `origin/main:godot/fx/fx_weapons.gd:53,239` | `var weapon_tint: Color = fac["weapon"]` / `_sprite_bolt(fx, from, tf, dist / spd, weapon_tint, 2.8,` | Sunward plasma bolts and muzzles turn orange (`[1.0, 0.55, 0.2]`) while plasma impacts and craters stay light blue (`PLASMA_COL`), contradicting Ryan's R46 ruling ("Plasma is light blue"). `weapon_layers_check.gd:104-106` locks in this regression. | Pass `col` (`PLASMA_COL * power`) to `_muzzle`, `_sprite_bolt`, shimmer, and travel light for `plasma` and `plasma_cannon`, and assert `PLASMA_COL` in `weapon_layers_check.gd`. | High |
| 2 | `SPRITE` kinds `30..36` collide silently with PR `#2132` (`30..31`) and open PRs `#2084` (`30`) and `#2069` (`34`). | OBSERVED | `godot/fx/fx_weapons.gd:66-72`, `godot/fx/fx_shaders.gd:463-473` | `const BOLT_PLASMA := 30` / `} else if (k >= 30 && k <= 32) {` | `git merge-tree` with `#2132` exits `0` with no conflict, but `#2132`'s `k == 15 \|\| k == 31` intercepts `BOLT_BIO` (31) before `k >= 30`, routes `31` into `SMOKY`, and `#2133`'s `k >= 30` intercepts `#2132`'s `TICK_EMBER` (30). | Keep `30..37` for `#2133` in the shared allocation table (see Merge Order) and move `#2132` to `38..39` (and `#2084`/`#2069` to `40+`) before combining. | High |

#### High / Medium

| # | Finding | OBSERVED/INFERRED | File:Line | Exact Quote | Why It Matters | Your Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 3 | `look_bench.gd` conflicts with PR `#2128` (`_moment` volley framing). | OBSERVED (`git merge-tree`) | `godot/bench/look_bench.gd:710-728` | `elif shot_focus == "ordnance" or shot_focus == "intercept":` | Merging `#2133` and `#2128` requires manual resolution in `look_bench.gd`. | Merge `#2128` first, then rebase `#2133` onto `main` + `#2128`. | High |

#### Ready / Verified

- Zero em dashes, zero unsafe `pow(..., 2.0)` calls, `ORDNANCE_CORONA` warmed in `fx.warmup()`, `star` corona properly hidden on launch slide and PD intercept, `las`/`prism` muzzle smoke leak cleanly fixed, `bombs` decoupled from craft silhouette `23`, `fx.torpedo_shot_down` on `main` untouched.

---

## PR `#2136` (`codex/issue-2047` @ `57b7943d0`) -- Verdict: **fix first**

- **Issue `#2047` match:** Covers all four Rank 7 items: (1) `lance` and `nlance` get hot core + moving sheath + pre-fire charge rings (`_beam_charge`), `nlance` gets 5 shaft distortion lenses (`DISTORT_BEAM`), premultiplied dark-violet sheath (`pools["nlance"]`), and violet hull scar; (2) `ion` gets 2 secondary dancing arcs around its core; (3) `pulsar` gets 3 staggered hexagonal harmonic rings (`RING_HARMONIC`) with zero refraction; (4) `needle` gets thin core + RGB spectral dispersion and travelling shimmer with zero refraction. Leaves `doom`, Chorus `tendril`/Acid Thorns, and lance audio untouched.
- **Faction & colour rules:** Clean. Glasswright `pulsar` and `needle` never emit `fx.dst` and never sample `hint_screen_texture` (R421); Eclipse `nlance` uses `eclipse_sheath` and `eclipse_core` (deep violet, no green/orange) and suppresses orange heat spots and Chorus green mist on contact flares.
- **Clashes (`main` & peer PRs):** **Fails `git merge-tree` against `origin/main` in 3 files** (`godot/fx/fx_breach.gd`, `godot/fx/fx_shaders.gd`, `godot/fx/fx_weapons.gd`) because PR `#1755` (Wounds V2) already merged onto `main` claiming `S_PRISM := 16`, `S_STAR := 17`, `S_NLANCE := 18`. Also **conflicts with `#2128`** in `godot/fx/fx_shaders.gd` because both claim `RING` kind `5`.
- **Frame time:** Low. Adds one 96-slot `pools["nlance"]` (warmed in `fx.warmup()`). Replaces 1 large distortion quad on `lance`/`ion` with 3 tighter shaft quads and adds 5 distortion quads on `nlance` (`quality == "max"` only, discarded when `fx_calm > 0.5`).

### Findings (`#2136`)

#### Blocking

| # | Finding | OBSERVED/INFERRED | File:Line | Exact Quote | Why It Matters | Your Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 1 | `S_NULL_BURN := 16` collides with merged `origin/main` `S_PRISM := 16` (PR `#1755`), and conflicts in 3 files. | OBSERVED | `godot/fx/fx_breach.gd:55`, `godot/fx/fx_shaders.gd:2234`, `godot/fx/fx_weapons.gd:2264` vs `origin/main:godot/fx/fx_breach.gd:60-62` | `const S_NULL_BURN := 16` / `if (style == 16) {` vs `const S_PRISM := 16` / `const S_NLANCE := 18` | Taking `#2136`'s `style == 16` overwrites Glasswright Prism's crystal star fracture on `main`, and duplicates `main`'s existing `S_NLANCE := 18` three-cut Null Lance scar. | Rebase on `origin/main`, remove `S_NULL_BURN := 16`, route `"nlance"` to `S_NLANCE := 18` (and apply Build F's violet trench style when `WOUNDS.v2()` is off if a V2-off fallback is needed), preserving `S_PRISM := 16`. | High |
| 2 | `RING_HARMONIC := 5` collides with PR `#2128`'s `RING` kind `5` (soft death front). | OBSERVED | `godot/fx/fx_shaders.gd:679,720` vs `#2128` `godot/fx/fx_shaders.gd:682,723` | `const RING_HARMONIC := 5` / `if (rk == 5) {` | Direct merge conflict in `fx_shaders.gd`; keeping both under kind `5` breaks either Pulsar harmonic rings or c170 death fronts. | Reassign `RING_HARMONIC := 6` in `fx_shaders.gd` (vertex + fragment + constant) and keep `5` for `#2128`'s death front. | High |

#### High / Medium

| # | Finding | OBSERVED/INFERRED | File:Line | Exact Quote | Why It Matters | Your Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 3 | `RING_HARMONIC` uses `frame_world(36.0, ...)` instead of `px_world(36.0, ...)`, bypassing `fx_px`. | OBSERVED | `godot/fx/fx_shaders.gd:724` | `size = max(size, frame_world(36.0, dv, PROJECTION_MATRIX, 1080.0));` | Unlike every other ring/sprite pixel floor (`px_world` multiplies by `fx_px`), setting `fx_px = 0.0` cannot disable the 36 px harmonic ring floor during diagnostics or floor-off checks. | Replace with `px_world(36.0, dv, PROJECTION_MATRIX)`. | High |

#### Ready / Verified

- Zero em dashes; `pow(abs(trench - 0.91) / 0.42, 2.0)` and `pow(abs(sin(lane)), 0.7)` pass `shader_pow_2092.js` (bases guarded by `abs()`); `layered_beam_check.gd` and `pixel_scale_check.gd` properly cover 1080p/2160p scaling, Reduce Flashing, and Glasswright no-refraction; `pools["nlance"]` warmed in `fx.warmup()`.

---

## PR `#2132` (`codex/issue-2046` @ `4cb23fa78`) -- Verdict: **fix first**

- **Issue `#2046` match:** Covers both Build E items: (1) layered turn-start ticks (`fx_status_tick.gd`) for `fire` (baked vent plume + embers + light), `acid` (etch ring + droplets + vapour), `tidal` (3 pull streams toward `fx.well` + rim stress + motes), and `storm` (cloud-to-ship jagged arc + 2 forks hitting live shield or 0-shield bare hull); (2) six faction boarding looks (`fx_boarding.gd` + `fx_conduit.gd` + `fx_event_paths.gd`: assault/precision/salvage pods, Eclipse violet phase beams, Glasswright prismatic phase-lock, Chorus bio-umbilicals) with matching cutter rings, keeping R401's 4x hatch and 1.6 s hold. Leaves `_emit_acid` and `ion_arc` untouched.
- **Faction & colour rules:** **Fails Glasswright and Chorus soot rules in `_fire`:** emits 5 dark grey soot puffs (`kind 8`, `Color(0.17, 0.16, 0.20)`) and `fac_smoke = 0.12` on all 6 factions, including Glasswrights (`ithar`) and Chorus (`chorus`). Boarding looks respect all 6 factions cleanly (Eclipse violet, no warm sparks; Chorus umbilicals + acid fume, no metal sparks; Glasswright pale prism).
- **Clashes (`main` & peer PRs):** **Fails `git merge-tree` against `origin/main`** in `godot/bench/look_bench.gd` (conflicts with PR `#1904`'s `clip`/`strict` row support). **Silent semantic collision** with PR `#2133` on `SPRITE` kinds `30..31` and `SMOKY` (`git merge-tree` exits `0`). Conflicts with PR `#2128` in `godot/bench/look_bench.gd` and `tools/pc/jobs/look_bench_sheets.py`.
- **Frame time:** Low steady-state, minor event-frame allocation. `fx_conduit.gd` shader is cached via `fx.mat` and warmed in `fx.warmup()` (0 late shaders), and `fx_event_paths.gd` caps live paths at `LIMIT := 96`. Each boarding builds up to 7 `SurfaceTool` `ArrayMesh`es + `ShaderMaterial`s on the main thread (3 per tidal/storm tick). `DEATH.flipbook` uses isolated `pool_tag = "status_fire"` so it does not pollute death flipbooks.

### Findings (`#2132`)

#### Blocking

| # | Finding | OBSERVED/INFERRED | File:Line | Exact Quote | Why It Matters | Your Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 1 | `TICK_EMBER := 30` and `TICK_DROPLET := 31` collide silently with PR `#2133` (`BOLT_PLASMA=30`, `BOLT_BIO=31`). | OBSERVED | `godot/fx/fx_shaders.gd:245-246`, `godot/fx/fx.gd:760` | `const TICK_EMBER := 30` / `const TICK_DROPLET := 31` / `SH.TICK_DROPLET: true}` | `git merge-tree` with `#2133` exits `0`, silently breaking both PRs: `BOLT_BIO` (31) gets routed to `SMOKY` and caught by `k == 15 \|\| k == 31`, while `TICK_EMBER` (30) gets caught by `#2133`'s `k >= 30 && k <= 32`. | Move `TICK_EMBER := 38` and `TICK_DROPLET := 39` in `fx_shaders.gd` (and update `k == 30`/`k == 31` branches in `SPRITE`). | High |
| 2 | `_fire` status tick emits dark grey soot smoke (`kind 8`) and `fac_smoke = 0.12` on Glasswrights and Chorus. | OBSERVED | `godot/fx/fx_status_tick.gd:38-44`, `godot/fx/test/event_layers_2046_check.gd:71` | `mat.set_shader_parameter("fac_smoke", 0.12)` / `fx.sprx(16.0, p, t + i * 0.07, 0.9 + i * 0.10, Color(0.17, 0.16, 0.20),` | Breaks independent-audit Trap #2 and R402/R416 (`ithar`: `death.smoke = 0.0`, `soot_weight = 0.0`, `prism = 1.0`; `chorus`: `soot_weight = 0.0`). Glasswrights never emit soot smoke, and Chorus hulls should emit bile vapour (`kind 20`), not grey metal soot (`kind 8`). | Skip `kind 8` soot and set `fac_smoke = 0.0`, `fac_prism = 1.0` for `ithar`; emit `kind 20` bile vapour (or skip soot) for `chorus`; update `event_layers_2046_check.gd:71` per faction. | High |
| 3 | `look_bench.gd` conflicts with `origin/main` (PR `#1904`) and PR `#2128`; `look_bench_sheets.py` conflicts with PR `#2128`. | OBSERVED (`git merge-tree`) | `godot/bench/look_bench.gd:786-805` vs `origin/main:godot/bench/look_bench.gd:844-895` | `if not headless:` / `var img := _grab()` / `if img != null:` | Cannot merge onto `main` as-is; also leaves blank GPU readbacks silently appended to `cells` (Artoo finding #1), which `origin/main`'s `strict` row path already solves. | Rebase onto `main` + `#2128`, drop the duplicate `look_bench_sheets.py` edit, and mark `look_moments_2046.json` rows `"strict": true` using `main`'s strict handler. | High |

#### High / Medium

| # | Finding | OBSERVED/INFERRED | File:Line | Exact Quote | Why It Matters | Your Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 4 | `_storm` skips live shield contact when `_shield_fraction` is still at its initial `-1.0`. | OBSERVED (code) / INFERRED (unsynced caller) | `godot/fx/fx_status_tick.gd:109` vs `origin/main:godot/fx/fx_ship.gd:112` | `if ship._shield_mat != null and ship._shield_fraction > 0.0:` | `FxShip._shield_fraction` initializes to `-1.0` and only updates when `sync()` gets `shp` and `shMax > 0`. Any shielded ship ticked before a full `shp`/`shMax` sync takes a bare-hull strike through a live shield. | Guard as `ship._shield_mat != null and (ship._shield_fraction > 0.0 or (ship._shield_fraction < 0.0 and ship.shielded))`. | High |
| 5 | `fx_conduit.gd` pixel floor ignores `fx_px` and `storm_*_native` rows are FX-only fixtures. | OBSERVED | `godot/render/fx_conduit.gd:22`, `godot/bench/look_moments_2046.json:41-46` | `float floor_r = pixels * max(-centre.z, .01) / max(abs(PROJECTION_MATRIX[1][1]) * 540.0, .01);` | Minor: `fx_px = 0.0` does not turn off conduit floors (though 1080-line 4K scaling is correct). Also confirm Artoo's note that `rules.gd` still gates storm ticks on `shMax > 0`, so native-shieldless bench labels should note "FX fixture". | Multiply `floor_r` by `fx_px` (declare `global uniform float fx_px;`) and tag native-shieldless bench labels as FX fixture. | Med |

#### Ready / Verified

- Zero em dashes, zero `shader_pow_2092.js` offenders, `DEATH.flipbook` uses isolated `pool_tag="status_fire"`, `fx_event_paths.gd` cleanly cancels on ship death (`anchor()` returns `Vector3.INF`) and `fx.release()`, boarding holds stay on `fx.now` (`fx_correctness_1933_check.gd` updated), and `fx_conduit.gd` shader is warmed in `fx.warmup()`.

---

## PR `#2137` (`codex/issue-2022` @ `7a23418ed`) -- Verdict: **fix first**

- **Issue `#2022` match:** Covers the metal break rewrite and kit-interior fill cleanly: lit `SLAG` shader with continuous wave noise (`bends`, removing hash glitter `grain(p * 160)`), per-faction `scorch_tint` from `fragment_paint`, bent lip with per-vertex colour gradient (`CAP_LIP` -> `CAP_LIP_INSET`), narrow hot seam cooling in `SEAM_COOL := 3.0 s` independent of outer hull scorch, and `SectionFit` + `_section_kit` generating hull-fitted recessed bulkheads (`CAP_WALL`), decks (`CAP_DECK`), and ribs (`CAP_RIB`) inside authored and legacy torn openings (checked to stay inside tapered hulls by `death_authored_check.gd` and `death_seam_check.gd`). Audited Glasswright and Chorus caps separately (though both need albedo fixes below).
- **Faction & colour rules:** **Fails Glasswright and Chorus wreck-cap looks:**
  1. Glasswright (`cap_kind == 1`) multiplies `scorch_tint` (`[0.53, 0.61, 0.66]`) by `0.052` on the recessed bulkhead (`[0.028, 0.032, 0.034]` linear = near-black charcoal) and `0.12` on the lip (`[0.064, 0.073, 0.079]`), violating Ryan's Nov 24 pale frosted pearl glass ruling (`faction_looks.json:81-82`, `wall_max: 0.45`).
  2. Chorus (`cap_kind == 2`) retains the pre-V2 magenta-plum flesh literals `vec3(0.085, 0.018, 0.031)` (`B > G`), violating independent-audit Trap #2 and clashing with `origin/main`'s Wounds V2 crimson-umber organ (`vec3(0.075, 0.03, 0.022)`).
  3. All 4 metal factions (Sunward, Directorate, Hullbreakers, Eclipse) get distinct `fragment_paint` bases and `death.rim` heat hues; Eclipse stays obsidian-violet.
- **Clashes (`main` & peer PRs):** **Fails `git merge-tree` against `origin/main`** in `godot/fx/fx_death.gd` (conflicts with PR `#1755` Wounds V2 in `precompute`, `_piece_materials`, `_blank_pieces`). Clean (`exit 0`) against `#2133`, `#2136`, `#2132`, and `#2128` (`#2128` only touches `_core_flash_inner` in `fx_death.gd`). Note open PR `#2007` (`codex/issue-1991`, red CI) adds `faction_fx_1991_check.gd` asserting old `SLAG` strings; reconcile when `#2007` lands.
- **Frame time:** Worker-thread cut cost increases because `_cut()` builds `TriangleMesh`es (`_section_envelope`, `_section_shell`, per-opening `fit.opening`) and runs cached ray/segment checks in `SectionFit`. Runs off the main thread when precomputed (zero hitch), but adds main-thread time if a ship dies before precompute finishes. Lit `SLAG` PBR + Glasswright `CLEARCOAT` covers small screen area, so GPU cost is small.

### Findings (`#2137`)

#### Blocking

| # | Finding | OBSERVED/INFERRED | File:Line | Exact Quote | Why It Matters | Your Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 1 | `fx_death.gd` conflicts with merged `origin/main` (PR `#1755` Wounds V2) in `precompute`, `_piece_materials`, and `_blank_pieces`. | OBSERVED (`git merge-tree`) | `godot/fx/fx_death.gd:1575-1577,1767-1774` vs `origin/main:godot/fx/fx_death.gd:1554,1735-1757` | `var inputs := {"seeds": seeds, "surfs": surfs, "cause": cause, "organic": s.faction == "chorus",` | Cannot merge onto `main`; dropping `main`'s hunk would break Wounds V2 `"faction"`/`"L"` passing, `_restamp_interiors`, `HULL.set_v2`, and V2 `wreck_interior`. | Rebase on `origin/main`, keeping both `cap_kind`/`scorch_tint` and `main`'s `"faction"`, `"L"`, `_restamp_interiors`, `HULL.set_v2`, and `wreck_interior` calls. | High |
| 2 | Glasswright (`cap_kind == 1`) wreck cap albedo evaluates to near-black charcoal (`~0.028` linear) instead of pale frosted pearl glass. | OBSERVED | `godot/fx/fx_death.gd:167` with `origin/main:godot/fx/faction_looks.json:79,81-82` | `ALBEDO = scorch_tint * (lip ? 0.12 : 0.052) * (0.72 + coarse * 0.28);` | With `ithar.fragment_paint = [0.53, 0.61, 0.66]`, the recessed glass wall renders at linear `[0.028, 0.032, 0.034]` (dark charcoal), violating Ryan's Nov 24 pearl-glass ruling (`glass: [0.32, 0.32, 0.32]`, `wall_max: 0.45`, "never dark grey" in `fx_shaders.gd` `INTERIOR`). | Raise Glasswright `cap_kind == 1` `ALBEDO` to pale frosted pearl glass (e.g. `scorch_tint * (lip ? 0.55 : 0.40)` ~ `0.21..0.33` linear, matching `INTERIOR` wreck pearl glass and staying under `wall_max: 0.45`). | High |
| 3 | Chorus (`cap_kind == 2`) wreck cap retains the pre-V2 magenta-plum flesh palette. | OBSERVED | `godot/fx/fx_death.gd:162` vs `origin/main:godot/fx/faction_looks.json:63` | `vec3 flesh = mix(vec3(0.025, 0.005, 0.013), vec3(0.085, 0.018, 0.031), coarse * 0.7 + fibre * 0.3);` | `B > G` (`0.031 > 0.018`) reads magenta-plum, breaking independent-audit Trap #2 and clashing with `origin/main`'s Wounds V2 crimson-umber Chorus organ (`vec3(0.075, 0.03, 0.022)`). (Matches Artoo's finding against `#1997`.) | Replace the two `flesh` endpoints with crimson-umber tones matching V2 (e.g. `mix(vec3(0.028, 0.012, 0.008), vec3(0.085, 0.04, 0.018), ...)`) and assert `flesh` has `r > g > b` in `faction_death_style_check.gd`. | High |

#### High / Medium

| # | Finding | OBSERVED/INFERRED | File:Line | Exact Quote | Why It Matters | Your Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 4 | Open PR `#2007` (`faction_fx_1991_check.gd`) asserts removed `SLAG` strings; no standalone capture `.bat` file delivered. | OBSERVED | `godot/fx/test/faction_death_style_check.gd:235-237`, `docs/playbooks/deaths_and_hits.md:83-85` | `check(slag.contains("base = scorch_tint") and slag.contains("hot * seam * temperature * temperature")` | Issue 2022 notes `#2007`'s `faction_fx_1991_check.gd` must be updated once `#2007` lands (still open/red today). Bench instructions live in `deaths_and_hits.md`, so the Board needs to pass `LB_ARGS` manually or add a `.bat`. | Track updating `faction_fx_1991_check.gd` when `#2007` merges; optionally add a small wrapper `.bat` matching the other FX PRs before GPU capture. | High |

#### Ready / Verified

- Zero em dashes, zero `shader_pow_2092.js` offenders, `SLAG` hash glitter (`grain`) removed, `SEAM_COOL := 3.0 s` cleanly decoupled from outer hull scorch, `SectionFit` prevents tapered-hull protrusion (verified in `death_authored_check.gd` and `death_seam_check.gd`), `deaths_and_hits.md` updated cleanly (R214).

---

## PR `#2128` (`codex/issue-2032` @ `03d963155`) -- Verdict: **fix first**

- **Issue `#2032` match:** Covers all three items: (1) three cut-in camera presets in `camera_rig.gd` (broadside low shoulder 62 deg, chase 32 deg for `lance`/`torp`, tight victim hold `impact_cut` with blocker avoidance for `kill`/`nova`), grid/ring/marker/plate/float/tip fade during cut-ins, smooth `0.72 s` eased return (`return_from_cut`), preserving `reduce_motion` and R193 kill holds; (2) c170 kill readability via post-calibration `CORE_READ_PX` (`112/135/178/330` px) + soft camera-facing death front (`RING` kind `5`, `CORE_RING_S = 0.64`, `alpha <= 0.18`), respecting R186 (0.70 s flame cap) and R193 flash counter; (3) `contrib/opus/pc/2032/look_moments.json` + `look_bench_2032.bat` for lance hit, torpedo kill, and capital death at camera 170 and cut-in.
- **Faction & colour rules:** Clean. Death core front tints via `dcol(src, "light", tint)` so every faction keeps its approved death light colour; no shield facings restored.
- **Clashes (`main` & peer PRs):** **Fails `git merge-tree` against `origin/main`** in `godot/bench/look_bench.gd` and `godot/tools/ci/godot_checks.txt`. **Collides with `#2136`** on `RING` kind `5` (`fx_shaders.gd`). Conflicts with `#2133` and `#2132` in `godot/bench/look_bench.gd` and with `#2132` in `tools/pc/jobs/look_bench_sheets.py`. Also note Artoo's warning for future rebase with open PR `#2104` (`battle.gd:7187` ship plates).
- **Frame time:** Negligible steady-state (1 soft ring quad per staged death; `cut_overlay_alpha` uniform writes gated on change). One minor first-cut pipeline-switch risk in `ship_view.gd:814` (`TRANSPARENCY_DISABLED` <-> `TRANSPARENCY_ALPHA`).

### Findings (`#2128`)

#### Blocking

| # | Finding | OBSERVED/INFERRED | File:Line | Exact Quote | Why It Matters | Your Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 1 | Conflicts with `origin/main` in `look_bench.gd` and `godot_checks.txt`, and claims literal `RING` kind `5` colliding with PR `#2136`. | OBSERVED | `godot/fx/fx_shaders.gd:682,723`, `godot/fx/fx_death.gd:4129-4130` | `5 soft death front (camera-facing)` / `if (rk == 5) {` / `5, 0.0, 0.0, ring_px, ring_seed)` | Cannot merge onto `main` as-is (`look_bench.gd` clashes with PR `#1904` `clip`/`strict` and `var W`/`H`). Hardcoding `5` collides with `#2136`'s `RING_HARMONIC := 5`. | Rebase on `origin/main` (unify `--strict-moments` with `main`'s `strict` row path), declare `const RING_DEATH_FRONT := 5` in `fx_shaders.gd`, and use it in `fx_death.gd:4130` so `#2136` takes `6`. | High |

#### High / Medium

| # | Finding | OBSERVED/INFERRED | File:Line | Exact Quote | Why It Matters | Your Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 2 | Altitude drop-lines (`drop`, `drop_dot`) and `blocker_highlights` are not faded during cut-ins. | OBSERVED | `godot/render/ship_view.gd:817-824`, `godot/render/board.gd:609-615` | `if ring != null: _color_ring(ring.material_override)` / `if marker != null: _color_marker(marker.material_override)` | Under RULEBOOK 7.10 (issue 1582), every off-plane cruiser, destroyer, frigate, and squadron draws a vertical drop-line to a hex anchor dot. Leaving `drop` and `drop_dot` at full alpha while the hex grid and markers fade to `0.0` leaves floating lines hanging under ships in cut-ins. | Multiply `_drop_col` alpha in `ship_view.gd` by `_cut_overlay_alpha` (and hide when `<= 0.001`), and fade or toggle `blocker_highlights` in `board.gd:set_cut_overlay_alpha`. | High |
| 3 | Toggling `ring.material_override.transparency` mid-battle risks a first-cut pipeline switch; player input during the 0.72 s cut return does not cancel `_cut_return_elapsed`. | OBSERVED / INFERRED (first-cut hitch) | `godot/render/ship_view.gd:814`, `godot/render/camera_rig.gd:353-360` | `mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if _cut_overlay_alpha < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED` / `if _cut_return_elapsed < CUT_RETURN_S:` | Switching `StandardMaterial3D.transparency` creates a separate opaque vs alpha pipeline variant on the first cut-in. Also, if a player orbits, pans, or calls `zoom_at` (merged PR `#2102`) during the 0.72 s return ease, `_process` keeps lerping from `_cut_return` instead of handing control back cleanly. | Keep `ring` on `TRANSPARENCY_ALPHA` permanently (matching `marker`), and set `_cut_return_elapsed = CUT_RETURN_S` when `orbit()`, `pan_by()`, or `zoom_at()` runs. | Med |

#### Ready / Verified

- Zero em dashes, zero `shader_pow_2092.js` offenders, `hud.letterbox(true)` on `main` already hides active `tip`/`dtip` and PR `#2128` prevents re-showing them while letterboxed, `CORE_READ_PX` stays inside R186 (`<= 0.70 s` flame cap) and R193 (3 bright flashes/s), `big_moments_check.gd` verifies presets, return easing, overlay restoration without reviving dead rings, and flash budgeting.

---

## Shared ID Table and Conflict-Free Merge Order

Before rebasing, pin these shader/style IDs once so textual merges cannot silently cross-wire effects (and note open PRs `#2007`, `#2021`, `#2084`, `#2069` when they rebase):

| Registry | File | Reserved / Merged on `main` | PR `#2128` | PR `#2137` | PR `#2133` | PR `#2136` | PR `#2132` | Open FX PRs (coordinate) |
|---|---|---|---|---|---|---|---|---|
| `SPRITE` kinds | `fx_shaders.gd` | `0..27` | none | none | `30..37` (`BOLT_*`, `MUZZLE_*`, `ROCKET_SMOKE`) | none | **`38..39`** (move `TICK_EMBER`, `TICK_DROPLET`) | `#2007`=28, `#2021`=29, `#2084`/`#2069`=`40+` |
| `STREAK` kinds | `fx_shaders.gd` | `0..8` | none | none | `9..12` (`BOLT_SHELL`..`BOLT_SCRAP`) | none | none | none |
| `RING` kinds | `fx_shaders.gd` | `0..4` | **`5`** (`RING_DEATH_FRONT`) | none | none | **`6`** (move `RING_HARMONIC`) | none | none |
| `RIBBON` kinds | `fx_shaders.gd` | `0..10` | none | none | none | `11` (`RIB_NULL_LANCE`) | none | none |
| `DISTORT` kinds | `fx_shaders.gd` | `0..1` | none | none | none | `2` (`DISTORT_BEAM`) | none | none |
| `BREACH` styles | `fx_breach.gd` | `0..18` (`16=S_PRISM`, `17=S_STAR`, `18=S_NLANCE`) | none | none | none | **drop `16`**, use `18` (`S_NLANCE`) | none | none |

### Recommended Merge Order (After Each PR Applies Its Fixes)

1. **PR `#2128` (Issue `#2032`: big moments)** -- Land first after rebasing on `main`, unifying `--strict-moments` with `main`'s `strict` row path in `look_bench.gd`, naming `RING_DEATH_FRONT := 5`, fading `drop`/`drop_dot` in `ship_view.gd`, and keeping `ring` on `TRANSPARENCY_ALPHA`. Landing `#2128` first settles the shared `look_bench.gd` and `look_bench_sheets.py` harness changes once for the whole pile. (Coordinate `battle.gd:7187` when open PR `#2104` rebases.)
2. **PR `#2137` (Issue `#2022`: wreck scorched edges)** -- Land second after rebasing on `main` + `#2128`, fixing Glasswright `cap_kind == 1` pearl-glass albedo and Chorus `cap_kind == 2` crimson-umber flesh palette, and keeping `main`'s Wounds V2 hooks in `fx_death.gd`. Zero overlap with `#2133`/`#2136`/`#2132` outside `godot_checks.txt` (and disjoint from `#2128` inside `fx_death.gd`). Reconcile `faction_fx_1991_check.gd` when `#2007` lands.
3. **PR `#2133` (Issue `#2043`: Build B bolts/ordnance/muzzles)** -- Land third after restoring `PLASMA_COL` (RULEBOOK 6.13 / R46) and rebasing on `main` + `#2128` (`look_bench.gd`). Locks in `SPRITE` `30..37` and `STREAK` `9..12` in `fx_shaders.gd` and `fx_weapons.gd`.
4. **PR `#2136` (Issue `#2047`: Build F beams)** -- Land fourth after rebasing on `main` + `#2128` + `#2133`, moving `RING_HARMONIC` to `6`, replacing `S_NULL_BURN := 16` with `main`'s `S_NLANCE := 18`, and switching `frame_world(36.0)` to `px_world(36.0)`. Its `fx_weapons.gd` beam blocks are disjoint from `#2133`'s bolt/muzzle/ordnance edits.
5. **PR `#2132` (Issue `#2046`: Build E status ticks/storm/boarding)** -- Land fifth after rebasing on `main` + `#2128` + `#2133`, dropping its duplicate `look_bench_sheets.py` edit, using `main`+`#2128`'s `strict` row path in `look_bench.gd`, moving `TICK_EMBER`/`TICK_DROPLET` to `38..39`, removing dark soot (`kind 8`) from Glasswrights and Chorus in `_fire`, and guarding `_storm` for unsynced shielded ships (`_shield_fraction < 0.0 and ship.shielded`).

---

## Recommended Next Step

Send `#2128` first (smallest fix set, unlocks `look_bench.gd` and `look_bench_sheets.py` for `#2133` and `#2132`), and in parallel queue the targeted fixes on `#2137`, `#2133`, `#2136`, and `#2132` using the Shared ID Table above; run GPU look-bench captures only after each rebased PR is green on the combined head (R407).

---

## Not checked

- Live GPU rendering, Windows look-bench captures, before/after sheets, or real RTX 5080 frame-time measurements (code-only review; no Godot binary or GPU capture run executed here).
- Actual post-rebase combined-head CI runs or shader compilation on Vulkan/Forward+ drivers.
- Full code review of separate open PRs cited only for cross-PR ID/file coordination (`#1997`, `#2007`, `#2021`, `#2049`, `#2068`, `#2069`, `#2084`, `#2104`).
- `rules.gd` gameplay changes for naturally shieldless ships in ion storms (out of scope for `#2046` FX-only brief; noted only where `#2132` bench rows test it as a synthetic fixture).
