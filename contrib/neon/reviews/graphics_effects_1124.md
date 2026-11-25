# Full Graphics and Effects Review (Nov 24 2026)

- **Issue:** #1935 (run 1)
- **Commit reviewed:** `8551a3384490ab45f9ff946a0973b29313208ffa` (`main`, delivered on `neon/issue-1935`)
- **Seat:** Neon (independent pass; no files under `board/review_1124/` or any Fable review were read)
- **Verdict:** **23 concrete findings** across faction cohesion, rules-vs-code drift, runtime bugs, visual gaps, and 4K/performance scaling. The biggest player-visible gap is that `VS_WOUNDS_V2` defaults OFF on `main`, R416 Milestones 1-2 have not landed, and banned procedural wound shaders (Eclipse neon square grids, Glasswright radial sine webs, Chorus magenta flesh, universal 94% black soot, and hardcoded orange fire/embers) still fire on live ships and wrecks.

---

## Top 10 (Most Important First)

1. **Wounds V2 defaults OFF and R416 Milestones 1-2 are missing** (`godot/fx/fx_wounds_flag.gd:7`, `godot/fx/fx_ship.gd:350, 1904, 2396, 2706`) - every non-Hullbreaker faction leaks Hullbreaker black soot coughs, metal sparks, and zero 3D armor depth until 20% HP.
2. **Banned wound shaders still live on `main`** (`godot/fx/fx_shaders.gd:2055-2067, 1636`, `godot/fx/fx_hull.gd:58, 346, 368`, `godot/fx/fx_death.gd:148`) - Eclipse draws neon square circuit grids (seen on `BATTLE1076_E11_c26_standard.jpg`), Glasswrights draw radial sine spiderwebs, Chorus draws magenta flesh, and all factions get 94% black soot collars + hardcoded orange backfaces.
3. **Hardcoded orange/fire/soot leaks across Eclipse, Glasswrights, Meridian Directorate, and Chorus** (`godot/fx/faction_looks.json:32`, `godot/fx/fx_shaders.gd:385, 453, 964, 1088, 1766`, `godot/fx/fx_death.gd:191, 2717, 2996`, `godot/fx/fx_ship.gd:2352, 2811`, `godot/fx/fx.gd:1925`, `godot/render/ship_view.gd:1661`) - Eclipse trails and implosions spit orange, Directorate wounds glow warm gold-orange, Glasswrights RCS jets puff amber and deaths drop sooty metal plates, and Chorus squadrons/fire/boarding smoke and burn orange.
4. **Nova Cannon and standalone `"hit"` events bypass G4 FX and shield guards** (`godot/scenes/battle/battle.gd:1551, 1606`) - Nova Cannon still uses the placeholder `fx_stub.gd`, and standalone hits pop hardcoded orange sparks even when shields absorb all damage.
5. **Wreck pieces and board hull debris lose `LOOK_RIM` and `NebulaHulls` protection** (`godot/render/look_rim.gd:146-155`, `godot/fx/fx_death.gd:1549`, `godot/world/nebula_hulls.gd:18`) - `_is_hull` ignores `ArrayMesh` surface materials, so broken ship halves and board wrecks drop their rim light and get fogged out in nebulae.
6. **Blocker 3D footprint outlines ignore depth and cut across ships and the Dead Star** (`godot/world/blocker_visuals.gd:135`) - `mat.no_depth_test = true` draws amber boxes on top of the black hole disc (seen directly in `docs/shots/terrain_fx_2/deadstar.jpg`).
7. **Crash bug in `_refresh_damage_emitters` when an anchor is missing** (`godot/fx/fx_ship.gd:2271, 2280`) - uninitialized emitter dicts without `node`/`particles` are appended to `_damage_emitters` and crash on the next update or count pass.
8. **Widespread `fx.now` vs real-time clock desyncs break slow-mo and hit-pause** (`godot/scenes/battle/battle.gd:1739, 2405`, `godot/fx/fx.gd:516, 1325, 1988`, `godot/render/ship_view.gd:1718`, `godot/render/squadron_wing.gd:381`, `godot/world/world_living.gd:882`) - volleys end before shots land, duplicate burnt hulks spawn over live capital deaths, and ships/wings/camera shake/boarding ignore hit-pause and kill slow-mo.
9. **Deathless revive (`_reassemble`) leaves stale board wrecks and flashes fallback engine sprites** (`godot/scenes/battle/battle.gd:1745-1760`, `godot/render/ship_view.gd:452-453`) - revived capitals leave `board.wrecks` and `"hulk"` terrain behind, and revived ships briefly double-draw fallback engine sprites.
10. **4K scaling breaks and mid-battle `Shader.new()` hitches** (`godot/fx/fx_shaders.gd:891, 902, 911, 943`, `godot/world/world.gd:488, 1561`, `godot/world/world_living.gd:375`, `godot/render/line_style.gd:155`, `godot/render/board.gd:280, 321, 1105, 1124`) - ion/needle/null-lance ribbons, ship trails, stars, dust, and black-hole lensing shrink to half size at 4K, and hover/reach/wreck UI compiles fresh shaders mid-battle.

---

## All Findings (Sorted Most Important First)

### 1. [Faction Cohesion / Rules vs Code] Wounds V2 defaults OFF on `main` and R416 Milestones 1-2 are unimplemented
- **Location:** `godot/fx/fx_wounds_flag.gd:7` (`enabled`), `godot/fx/fx_ship.gd:350` (`_build_engines`), `godot/fx/fx_ship.gd:509` (`_trail_setup`), `godot/fx/fx_ship.gd:1904` (`_breach_cuts`), `godot/fx/fx_ship.gd:2396-2406` (`_cough`), `godot/fx/fx_ship.gd:2706-2710` (`_wound_step`)
- **Quote:** `return bool(ProjectSettings.get_setting("rendering/effects/wounds_v2", false))` (`fx_wounds_flag.gd:7`); `var corsair = extra == "soot" or (_eng_sputter and not wounds_v2)` (`fx_ship.gd:350`); `if st < 4 or fx.compat: return out` (`fx_ship.gd:1904`)
- **Evidence:** OBSERVED (code + `docs/shots/battle_baseline_1118/BATTLE1076_A16_c26_standard.jpg` where Hullbreaker Stages 1-3 show almost no 3D depth until Stage 4)
- **Why the player would notice:** `godot/project.godot` never sets `rendering/effects/wounds_v2`, so every battle ships with Wounds V2 off. Damaged Glasswrights, Chorus, Eclipse, Sunward, and Meridian Directorate engines all fall into the Hullbreaker soot path (`corsair = true`, trail `style = 1`, black soot coughs), Chorus engines and jammed turrets throw metal sparks, and Eclipse jammed turrets spark steel-blue instead of violet. Meanwhile R416 requirements in `docs/playbooks/deaths_and_hits.md:265-297` (`wound_kind` 0..5, Stage 2 ~55% HP armor cutouts, 8-ray footprint check, normal-gated overlays, unified triplanar interior PBR shader, pooled `_hole_lights`, 3D faction breach-mouth dressing) are absent: `faction_looks.json` only has `wound_kind` 0..3 and `s._hole_lights` is never populated.
- **Fix:** Complete R416 Milestones 1-2 (`wound_kind` 0..5, Stage 2 cutouts with 8-ray validation, normal-gated overlays, triplanar interior shader, pooled hole lights), enable `rendering/effects/wounds_v2 = true` in `project.godot`, and remove the legacy `not wounds_v2` Hullbreaker-soot fallback branches once verified.
- **Confidence:** high

### 2. [Faction Cohesion / Rules vs Code] Banned procedural wound shaders remain active in `MARK`, `HOLE`, `fx_hull.gd`, and `SLAG`
- **Location:** `godot/fx/fx_shaders.gd:2066-2067` (`MARK` Eclipse), `godot/fx/fx_shaders.gd:2059-2060` (`MARK` Glasswrights), `godot/fx/fx_shaders.gd:2055` (`MARK` Chorus), `godot/fx/fx_shaders.gd:1636` (`HOLE` Chorus), `godot/fx/fx_hull.gd:368` (`_damage_code`), `godot/fx/fx_death.gd:148` (`SLAG`)
- **Quote:** `float circuit = smoothstep(0.46, 0.49, max(grid.x, grid.y));` (`fx_shaders.gd:2067`); `float web = pow(abs(sin(u * 26.0 + ang * 3.0)), 24.0);` (`fx_shaders.gd:2060`); `alb = mix(vec3(0.06, 0.012, 0.07), vec3(0.12, 0.025, 0.045), n1);` (`fx_shaders.gd:2055`)
- **Evidence:** OBSERVED (code + visually confirmed in `docs/shots/battle_baseline_1118/BATTLE1076_E11_c26_standard.jpg`, where bright grey-white square circuit grids paint across the dark violet Eclipse hull on Stages 1-4)
- **Why the player would notice:** Directly violates `docs/playbooks/deaths_and_hits.md:289-291` and `docs/playbooks/factions.md:276`: Eclipse hulls display flat neon square circuit grids, Glasswrights display synthetic radial sine spiderwebs, and Chorus hulls, breach holes, damaged hull backfaces, and cut wreck caps all render purple/magenta flesh instead of olive-umber hide, ivory bone hoops, and yellow-green bile sacs.
- **Fix:** Delete the procedural square-grid, radial-sine-web, and magenta-flesh branches across `SH.MARK`, `SH.HOLE`, `HULL._damage_code`, and `DEATH.SLAG`, replacing them with the 6-faction material interiors defined in `deaths_and_hits.md:286-292`.
- **Confidence:** high

### 3. [Faction Cohesion / Visual Quality] Universal 94% black soot collar, hardcoded orange backface embers, and blackened wreck interiors hit every faction
- **Location:** `godot/fx/fx_hull.gd:346` (`_damage_code`), `godot/fx/fx_hull.gd:58` (`BURNT` / `hull_inside`), `godot/fx/fx_hull.gd:371` (`_damage_code`), `godot/fx/fx.gd:1429` (`hull_damage_template`), `godot/fx/fx.gd:1450-1456` (`wreck_interior`), `godot/fx/fx_death.gd:1526` (`_piece_materials`)
- **Quote:** `ALBEDO *= (1.0 - fx_soot * 0.94) * (1.0 - fx_weather * (0.25 + 0.65 * burnt_hash(fx_hull_p * 1.7)));` (`fx_hull.gd:346`); `+ vec3(0.16, 0.032, 0.006) * ember * clamp(heat, 0.0, 1.0)` (`fx_hull.gd:58`)
- **Evidence:** OBSERVED (code + visually confirmed in `docs/shots/fx/dst4/real_hulls_sheet.jpg` showing dark soot collars on white Meridian Directorate hulls, and `BATTLE1076_E11_c26_standard.jpg` showing orange/yellow glow inside Eclipse cuts)
- **Why the player would notice:** Glasswrights (zero soot, zero black holes), Meridian Directorate (clean white/grey ceramic-steel, zero orange), Chorus (zero soot), and Eclipse (zero orange) all get blackened to 6% brightness around every hit (`fx_soot * 0.94`), show hardcoded orange-ember backfaces inside every cutout (`hull_inside` ignores its `glow` argument), and have their wreck interior meshes darkened by `WRECK_SOOT = 0.33`. `hull_damage_template` keys only on `organic`, so five non-Chorus factions share one steel-and-soot template.
- **Fix:** Key `hull_damage_template` and `wreck_interior` by `wound_kind` (0..5), gate `fx_soot` by a per-faction `soot_gain` uniform (0.0 for Glasswrights and Chorus, low/cool for Directorate), and wire `hull_inside` to read a per-faction interior glow color instead of `vec3(0.16, 0.032, 0.006)`.
- **Confidence:** high

### 4. [Faction Cohesion] Hardcoded orange, fire, and soot leaks across Eclipse, Directorate, Glasswrights, and Chorus shared paths
- **Location:**
  - `godot/fx/faction_looks.json:32` (Directorate `damage_glow`)
  - `godot/fx/fx_shaders.gd:964` (`TRAIL` style 3, used by Eclipse `faction_looks.json:96`)
  - `godot/fx/fx_shaders.gd:385` (`SPRITE` kind 3 orange flash), `godot/fx/fx_shaders.gd:453` (`SPRITE` kind 19 warm start), `godot/fx/fx_shaders.gd:1088` (`SHARD` bio/debris orange emission)
  - `godot/fx/fx_shaders.gd:1766, 1813, 1927, 1991, 2013` (`MARK` `wound_kind == 0` orange embers shared with Directorate)
  - `godot/fx/fx_death.gd:191-192` (`DEBRIS_BODY` sooty metal plates), `godot/fx/fx_death.gd:2715-2717` (lance `cause == "cut"` orange tear), `godot/fx/fx_death.gd:2996` (`_core_gas_veil` passes `src = null`)
  - `godot/fx/fx_death_beats.gd:347-351` (`corkscrew`), `godot/fx/fx_death_beats.gd:523` (`_implode`)
  - `godot/fx/fx_ship.gd:2351-2353` (damaged squadron smoke), `godot/fx/fx_ship.gd:2807-2811` (`tick_flare`)
  - `godot/fx/fx.gd:1925-1935` (`boarding`), `godot/render/ship_view.gd:1661` (`_rcs_puff`), `godot/world/hull_debris.gd:40` (`cut`)
- **Quote:** `col += vec3(1.0, 0.5, 0.15) * spow(vnoise(vec2(s * 60.0 - scene_t, seed * 3.0)), 12.0) * 2.0;` (`fx_shaders.gd:964`); `"damage_glow": [1.0, 0.72, 0.38],` (`faction_looks.json:32`); `m.set_shader_parameter("ember", Vector3(1.0, 0.72, 0.45))` (`fx_death.gd:2717`); `var tint: Color = {"corsair": Color(0.55, 0.48, 0.41), "ithar": Color(1.0, 0.86, 0.53),` (`ship_view.gd:1661`)
- **Evidence:** OBSERVED (code + visually confirmed in `BATTLE1076_E11_c26_standard.jpg` where Eclipse macro/torpedo/separation/wreck shots burst with bright orange fire and yellow-orange slag rims, and `real_hulls_sheet.jpg` where Directorate deaths burn orange)
- **Why the player would notice:** Even outside Wounds V2, every non-Imperial faction leaks another faction's signature colors in routine combat:
  - **Eclipse** engine trails (`TRAIL` style 3) spit orange flecks; `_implode` calls `SPRITE` kind 3 which injects an orange flash (`vec3(1.0, 0.4, 0.1)`); lance kills force orange tear embers (`fx_death.gd:2717`).
  - **Meridian Directorate** defines warm gold-orange `damage_glow` (`[1.0, 0.72, 0.38]`) and shares `wound_kind == 0` orange craters/embers with Hullbreakers, breaking its cold blue/white identity (`factions.md:100`, `deaths_and_hits.md:287`).
  - **Glasswrights** puff warm amber RCS movement jets (`ship_view.gd:1661`), shed sooty dark metal plates on death (`DEBRIS_BODY` lines 191-192), leak full-opacity grey gas veils when `death_story` is off (`_core_gas_veil` passes `src = null` on line 2996, resetting `fac_smoke = 1.0`), and emit soot-smoke on damaged squadrons (`fx_ship.gd:2352`).
  - **Chorus** throws orange-glowing bio shards (`SHARD` line 1088), sparks and smokes grey during `corkscrew` (`fx_death_beats.gd:347-351`) and damaged squadron flight (`fx_ship.gd:2352`), gets metal slag caps when turned into board debris (`hull_debris.gd:40` omits `organic`/`dstyle`), and burns with orange metal sparks during boarding (`fx.gd:1925-1935`) and fire ticks (`fx_ship.gd:2811`).
  - Also `tick_flare` `"storm"` (`fx_ship.gd:2807`) silently does nothing on unshielded Chorus/Eclipse ships or ships whose shields are down.
- **Fix:** Move all faction colors/styles into `faction_looks.json` and read them in every emitter/shader: set Directorate `damage_glow` to cold cyan-blue; remove orange sparks from `TRAIL` style 3, `SPRITE` kinds 3/19, `SHARD`, and `cause == "cut"` (use faction `dstyle` ember); give Glasswrights pearl/cool-white RCS jets and crystalline non-soot death debris; pass `s` to `_core_gas_veil` and `organic`/`dstyle` in `hull_debris.gd:40`; faction-branch `tick_flare`, `boarding`, `corkscrew`, and squadron damage smoke; add a hull-surface lightning fallback for `"storm"` ticks when `_shield_mat == null`.
- **Confidence:** high

### 5. [Faction Cohesion / Rules vs Code] Weapon hull marks and bio impacts collapse `doom`, `nlance`, `prism`, `star`, and `spores` into wrong faction looks
- **Location:** `godot/fx/fx_breach.gd:1850` (`kind_for`), `godot/fx/fx_shaders.gd:1798` (`MARK` `S_ION`), `godot/fx/fx_weapons.gd:2098` (`_land_hit`), `godot/fx/fx_weapons.gd:1612-1614` (`_flak`), `godot/fx/fx_weapons.gd:2405-2407` (`_bio_splat`)
- **Quote:** `"ion", "doom":` (`fx_breach.gd:1850`); `var wound_look: String = tg.get("mark_look", {"nlance": "lance", "plasma_cannon": "plasma", "gsentry": "gflak", "junk": "auto"}.get(lk, lk))` (`fx_weapons.gd:2098`); `_heat_spot(fx, p + n * 0.1 * k, T, k, 0.7, "bio", 5.0, 0.6, Tg)` (`fx_weapons.gd:2407`)
- **Evidence:** OBSERVED
- **Why the player would notice:** `deaths_and_hits.md:296, 397` requires distinct hull marks for `prism`, `star`, and `nlance`, and Eclipse weapons to stay cold violet. On `main`, Eclipse `doom` maps to `S_ION` which hardcodes electric blue (`vec3(0.5, 0.75, 1.0)` at `fx_shaders.gd:1798`), `nlance` remaps to `"lance"` (orange molten slot), and `prism`/`star` collapse into generic orange shell/blast craters with black soot. Chorus spore flak (`lk == "spores"`) throws 7 metal sparks (`fx_weapons.gd:1614`), and `_bio_splat` drops molten orange `_heat_spot` heat patches and grey `"cool"` smoke even on Glasswrights.
- **Fix:** Give `doom`, `nlance`, `prism`, and `star` their own `MARK` recipes (or parameterized tint/pattern uniforms) matching faction palettes; replace metal sparks on `spores` with bile/spore droplets; remove `_heat_spot` and soot smoke from `_bio_splat` (use acidic yellow-green sheen/mist).
- **Confidence:** high

### 6. [Rules vs Code / Bug] Nova Cannon and standalone `"hit"` events bypass G4 FX and shield-absorption guards
- **Location:** `godot/scenes/battle/battle.gd:1606-1609` (`_play_event` `"nova"`), `godot/scenes/battle/battle.gd:1551` (`_play_event` `"hit"`)
- **Quote:** `fx.bolt(_pos(e["unit"]) + Vector3(0, 2, 0), p, Color(1, 0.8, 0.5), 0.35 * speed, 0.0, 3.0)` (`battle.gd:1606`); `_impact(e["target"], e, Color(1, 0.6, 0.3))` (`battle.gd:1551`)
- **Evidence:** OBSERVED
- **Why the player would notice:** Nova Cannon is a marquee battleship superweapon, yet it still fires the retired placeholder `fx_stub.gd` bolt and a flat orange `_flash` sphere instead of G4 FX (`gfx`). Likewise, every standalone `"hit"` event (Nova splash, counter-fire, ram shockwave, reactor blasts) calls `_impact` with hardcoded orange `Color(1, 0.6, 0.3)` and never checks whether `shield > 0` and `hull == 0`: shield-absorbed hits still pop an orange hull explosion instead of a shield ripple, with zero hull scars on hull hits.
- **Fix:** Route `"nova"` through a dedicated G4 weapon/superweapon call in `fx_weapons.gd` (or `gfx.volley` + blast beat) and route standalone `"hit"` events through `gfx` with shield-vs-hull checks (shield ripple when `hull == 0`, faction-correct impact and hull scar when `hull > 0`), then retire `fx_stub.gd`.
- **Confidence:** high

### 7. [Visual Quality / Bug] Wreck pieces and board hull debris lose `LOOK_RIM` and `NebulaHulls` fog protection
- **Location:** `godot/render/look_rim.gd:146-155` (`_is_hull`), `godot/fx/fx_death.gd:1549` (`_piece_materials`), `godot/world/nebula_hulls.gd:18` (`_protect`)
- **Quote:** `for i in mi.get_surface_override_material_count():` (`look_rim.gd:152`); `am.surface_set_material(si, hull_mat)` (`fx_death.gd:1549`); `if not RIM._is_hull(node): return` (`nebula_hulls.gd:18`)
- **Evidence:** OBSERVED
- **Why the player would notice:** `_is_hull` only inspects `material_override` and `get_surface_override_material(i)` and never checks `mesh.surface_get_material(i)` (or `get_active_material(i)`). Because `fx_death.gd` assigns `hull_mat` directly onto the `ArrayMesh` surface (`am.surface_set_material`), every cut wreck half (`fx_wreck_*`), hull fragment (`fx_wreck_frag_*`), and board `HullDebris` piece returns `_is_hull == false`. Dark hulls (Sunward Crusade, Eclipse) suddenly drop their rim outline the moment they split apart, and `NebulaHulls._protect` skips them so nebula fog washes them out.
- **Fix:** In `look_rim.gd` (`_is_hull`, `_is_soft`, `_has_mark`, and rim injection), inspect `mi.get_active_material(i)` (or fall back to `mi.mesh.surface_get_material(i)` when override is null) and ensure `NebulaHulls` runs on cut pieces too.
- **Confidence:** high

### 8. [Visual Quality / Rules vs Code] Blocker 3D footprint outlines set `no_depth_test = true` and draw over ships and the Dead Star
- **Location:** `godot/world/blocker_visuals.gd:135` (`outline`)
- **Quote:** `mat.no_depth_test = true` (`blocker_visuals.gd:135`)
- **Evidence:** OBSERVED (code + visually confirmed in `docs/shots/terrain_fx_2/deadstar.jpg`, where bright amber hex-box outlines slice straight across the glowing black-hole accretion disc)
- **Why the player would notice:** `board.gd:59-67` (`HULL_MASK`) goes to great lengths to keep board lines under ships and 3D terrain, but `blocker_visuals.gd` disables depth testing on `BlockedFootprint` outlines. As a result, flat amber wireframe outlines paint directly on top of asteroids, planets, ships, and the Dead Star event horizon.
- **Fix:** Remove `mat.no_depth_test = true` (or adopt the board `HULL_MASK` depth-tested shader with a subtle Y bias) so blocker footprints sit cleanly in the board plane behind 3D hulls and the Dead Star disc.
- **Confidence:** high

### 9. [Bug - Crash] `_refresh_damage_emitters` appends uninitialized emitter dicts when `_anchor` is empty
- **Location:** `godot/fx/fx_ship.gd:2268-2280` (`_refresh_damage_emitters`, `_build_damage_emitter`), `godot/fx/fx_ship.gd:2207` (`damage_counts`), `godot/fx/fx_ship.gd:2338` (`_update_damage_emitters`)
- **Quote:** `keep.append(e)` (`fx_ship.gd:2271`); `if a.is_empty(): return` (`fx_ship.gd:2280`); `for e in _damage_emitters: e.node.visible = false` (`fx_ship.gd:2338`)
- **Evidence:** OBSERVED
- **Why the player would notice:** If a damaged section lacks a valid anchor (`_anchor(e.sec, "a")` returns `{}`), `_build_damage_emitter` returns early without setting `e["node"]`, `e["particles"]`, or `e["mat"]`. Line 2271 still appends `e` to `_damage_emitters`. On the very next frame or cleanup pass, `e.node` or `e.particles` throws a runtime key-access error and breaks ship damage updates.
- **Fix:** Have `_build_damage_emitter` return `bool` (true only when `node` was created) and append `e` to `keep` only on success; guard `e.has("node") and is_instance_valid(e["node"])` in `damage_counts`, `_update_damage_emitters`, and cleanup.
- **Confidence:** high

### 10. [Bug - Timing] Battle volley waits, `_lay_wreck`, boarding tweens, camera shake, ship/wing motion, and storm bursts desync from `fx.now`
- **Location:**
  - `godot/scenes/battle/battle.gd:2405` (`_play_volleys`)
  - `godot/scenes/battle/battle.gd:1739` (`_lay_wreck`)
  - `godot/fx/fx.gd:516` (`step`), `godot/fx/fx.gd:1325` (`_update_feel`), `godot/fx/fx.gd:1988-1990` (`_board_lines`)
  - `godot/render/ship_view.gd:1718-1740` (`_process`)
  - `godot/render/squadron_wing.gd:381` (`step`)
  - `godot/world/world_living.gd:882-924` (`_start_storm_burst`, `_present_storm_ticks`)
- **Quote:** `await get_tree().create_timer(total * sp).timeout` (`battle.gd:2405`); `get_tree().create_timer(WRECK_CHECK_S).timeout.connect(func() -> void:` (`battle.gd:1739`); `var T = Time.get_ticks_msec() / 1000.0 if not manual else now` (`fx.gd:1325`); `var tw := mi.create_tween()` (`fx.gd:1988`)
- **Evidence:** OBSERVED
- **Why the player would notice:** When `hit_pause` (`0.08x`) or `kill_slowmo` slows `fx.now`:
  - Heavy volleys finish their real-time `create_timer(total * sp)` wait and advance the turn while shots are still mid-flight.
  - `_lay_wreck` fires after 4.0s of real time (`WRECK_CHECK_S = 4.0`) even though capital deaths can hold up to `cold_cut_wall = 5.0`s (`fx_death.gd:2632`) plus slow-mo, allowing `board.add_wreck(..., true)` to drop a duplicate burnt hulk on top of live splitting wreck pieces.
  - Camera shake (`_update_feel`) runs on unscaled `delta` and wall-clock `Time.get_ticks_msec()`, buzzing at full speed during hit-pause and decaying before the impact finishes.
  - Ship translation, RCS puffs (`ship_view.gd:1718`), squadron flight (`squadron_wing.gd:381`), and boarding line fades (`fx.gd:1988`) run at full real-time speed while bobbing and combat FX freeze in slow-mo. Also `fx.gd:1930-1931` uses global `randf()` instead of `fx.rng.randf()`, breaking deterministic replays.
  - Ion storm bolts advance on `world_living.clock` while booking flash lights on `effects.now`, desyncing the flash from the bolt during slow-mo.
- **Fix:** Drive volley completion, `_lay_wreck` checks (or listen to a `death_settled` callback from `gfx`), `_board_lines` fade, camera shake time/decay, ship/wing motion, and storm flash timing from `fx.now` / `fx.dt` (with `fx.rng` in `boarding`).
- **Confidence:** high

### 11. [Bug - Revive / Teardown] Deathless `_reassemble` leaves board wrecks/hulk terrain behind and flashes duplicate fallback engines
- **Location:** `godot/scenes/battle/battle.gd:1745-1760` (`_reassemble`), `godot/render/ship_view.gd:452-453` (`revive`)
- **Quote:** `wrecked.erase(id)` (`battle.gd:1760`); `(e as Sprite3D).visible = true` (`ship_view.gd:453`)
- **Evidence:** OBSERVED
- **Why the player would notice:** When an Eclipse ship reassembles after its wreck has settled onto the board, `_reassemble` clears `gfx.clear_wreck(id)` and `wrecked.erase(id)`, but never removes `board.wrecks[id]` or restores `VW["terrain"][k]` from `"hulk"`: the resurrected ship sits on top of its own permanent burnt hulk. On top of that, `ship_view.revive()` unconditionally turns fallback `Sprite3D` engine glows visible even when `fx_engines == true`, causing a 1-frame double-engine flash.
- **Fix:** Add `board.remove_wreck(id)` (and clear `"hulk"` terrain if placed by that unit) inside `_reassemble`, and guard `ship_view.gd:453` with `if not fx_engines:`.
- **Confidence:** high

### 12. [Bug - Dead-on-Birth FX] Point-defense `_shot_down` spawns 3 of its 5 flak flashes already expired
- **Location:** `godot/fx/fx_weapons.gd:1506-1509` (`_shot_down`)
- **Quote:** `var tj := now - 0.18 + j * 0.06` / `_burst(fx, pp + off, Vector3.UP, tj, 0.35 * k, "flash", 0.06, Color(1.0, 0.85, 0.6), 2.0, 4.0)` (`fx_weapons.gd:1508-1509`)
- **Evidence:** OBSERVED
- **Why the player would notice:** For `j = 0, 1, 2`, `tj` is `now - 0.18`, `now - 0.12`, and `now - 0.06`. Because `life` is `0.06`, those three flashes are already dead (`elapsed >= 0.06`) the instant they are booked, wasting 60% of the PD flak cluster and making intercepts look sparse.
- **Fix:** Start `tj` at `now` (e.g. `now + j * 0.045`) or lengthen `life` so all 5 flak pops actually appear on screen.
- **Confidence:** high

### 13. [Scaling / Rules vs Code] 4K resolution shrinks ion/needle/null-lance beams, engine trails, sky stars, dust, and black-hole chroma by half
- **Location:** `godot/fx/fx_shaders.gd:891` (`RIBBON` `k == 5`), `godot/fx/fx_shaders.gd:902` (`RIBBON` `k == 8`), `godot/fx/fx_shaders.gd:910-911` (`RIBBON` `k == 11`), `godot/fx/fx_shaders.gd:942-943` (`TRAIL`), `godot/world/world.gd:488, 1561` (`_stars`, `_dust`), `godot/world/world_living.gd:375` (`WELL_SHADER`)
- **Quote:** `float d = (vSide - arc) * vPixels * 0.5;` (`fx_shaders.gd:891`); `w = max(w, du * 10.0);` (`fx_shaders.gd:943`); `var h := float(ProjectSettings.get_setting("display/window/size/viewport_height", 1080))` (`world.gd:488`); `vec2 shift = normalize(dv + vec2(0.000001)) / vec2(textureSize(screen_tex, 0)) * chroma_px * rim;` (`world_living.gd:375`)
- **Evidence:** OBSERVED (violates `docs/playbooks/effects.md:49` 1080-line pixel floor/cap rule from issue 1211)
- **Why the player would notice:** At 4K (2160p), `fr = VIEWPORT_SIZE.y / 1080.0 = 2.0`. Unlike `k == 6` (`fx_shaders.gd:884`, which divides by `fr`), `RIBBON` `k == 5` (ion arc), `k == 8` (needle rainbow), and `k == 11` (null-lance rails) use raw `vPixels`/`px`, collapsing beam accents to half width. `TRAIL` clamps width to 10 raw pixels (`du * 10.0`) instead of `10.0 * fr`. Sky stars and board dust read static `viewport_height` once at build time and never update on window resize. Black-hole chromatic aberration (`chroma_px = 1.5`) uses raw `textureSize`, halving the lensing fringe at 4K.
- **Fix:** Scale `TRAIL` pixel floor by `VIEWPORT_SIZE.y / 1080.0`, divide `vPixels`/`px` by `fr` in `RIBBON` kinds 5, 8, and 11, compute `fr` inside star/dust/well shaders using `VIEWPORT_SIZE.y / 1080.0` (instead of a frozen GDScript uniform).
- **Confidence:** high

### 14. [Performance / Stutter] Uncached `Shader.new()` compiles fresh shaders mid-battle and per patch across UI, board, squadrons, and world
- **Location:** `godot/render/line_style.gd:152-158` (`material`), `godot/render/board.gd:280, 321, 1105, 1124`, `godot/render/squadron_wing.gd:83`, `godot/render/squadron_craft.gd:118`, `godot/world/world_living.gd:547, 613, 745` (plus lines 1029, 1147, 1367, 1390)
- **Quote:** `static func material(breath := false) -> ShaderMaterial:` / `sh.code = SHADER` (`line_style.gd:152-155`); `var osh := Shader.new()` (`board.gd:280`); `var shader := Shader.new()` (`squadron_wing.gd:83`)
- **Evidence:** OBSERVED
- **Why the player would notice:** Every hover, reach preview, arrival highlight, or mid-battle `add_wreck -> _rebuild_edges` calls `LS.material()`, compiling a brand-new `Shader` resource on the main thread and causing micro-hitches. Board, squadron wings, craft, and living-world features also rebuild duplicate `Shader` instances per battle instead of sharing static cached `Shader` objects.
- **Fix:** Cache static `Shader` instances per shader string in a shared cache registered with `static_caches.gd` (so `clear_static()` stays clean) and only instantiate lightweight `ShaderMaterial` per node.
- **Confidence:** high

### 15. [Bug - Async / Teardown] Missing validity guards after `await` and 0.5s warmup timer risk crashes on fast scene exit
- **Location:** `godot/fx/fx.gd:2211-2215` (`warmup`), `godot/fx/fx.gd:1666, 2225` (`warm_arrival`, `warmup`), `godot/world/world.gd:519, 671` (`_load_sky`, `_load_planet`), `godot/world/world_bake.gd:440-448` (`_canvas`)
- **Quote:** `for b in dstate["debris"]:` (`fx.gd:2215`); `tmp.queue_free()` (`fx.gd:1666, 2225`); `var img: Image = await _baker.bake(key, code, params, size, 32)` (`world.gd:519`)
- **Evidence:** OBSERVED
- **Why the player would notice:** If a battle exits, restarts, or runs a quick test within 0.5s of `warmup()` (or while a sky/planet bake is in flight), `release()` clears `dstate`, freeing nodes before the timer or `await` resumes. `dstate["debris"]` throws a missing-key error, and `tmp.queue_free()` or `m.set_shader_parameter(...)` operates on freed instances.
- **Fix:** Guard `if not dstate.has("debris"): return` in the warmup callback, check `is_instance_valid(tmp)` before freeing after `await`, and check `is_instance_valid(self) and is_inside_tree() and is_instance_valid(m)` after every `await` in `world.gd` and `world_bake.gd`.
- **Confidence:** high

### 16. [Visual Quality / Bug] Hinged bay doors and rotating turrets receive static hull-frame damage overlays
- **Location:** `godot/fx/fx_ship.gd:1553` (`_ensure_inside`), `godot/fx/fx_breach.gd:1590` (`gather`)
- **Quote:** `BREACH._inside_overlay(fx, self, meshes, [], fac.get("damage_glow", Color(1.0, 0.45, 0.12)))` (`fx_ship.gd:1553`); `if is_turret_mesh(s, mi):` (`fx_breach.gd:1590`)
- **Evidence:** OBSERVED
- **Why the player would notice:** `fx_ship.gd:1553` passes the entire `meshes` array (including rotating turrets and hinged launch-bay doors) into `BREACH._inside_overlay`, baking static ship-local coordinates onto moving parts so breach marks slide across turrets as they track targets. `BREACH.gather` skips turret meshes (`is_turret_mesh`), but does not skip hinged bay doors (`hull._door_above`).
- **Fix:** Filter out both `BREACH.is_turret_mesh(self, mi)` and bay-door meshes before calling `_inside_overlay` and inside `BREACH.gather`.
- **Confidence:** high

### 17. [Visual Quality / Bug] Shield shell lags 1 frame behind hull bob and recoil
- **Location:** `godot/fx/fx_ship.gd:639` (`_build_shield`), `godot/fx/fx_ship.gd:447` (`update`)
- **Quote:** `root.add_child(_shield_mi)` (`fx_ship.gd:639`); `_shield_mi.transform = hull_motion() * _shield_pose` (`fx_ship.gd:447`)
- **Evidence:** OBSERVED
- **Why the player would notice:** Because `_shield_mi` is parented to `root` instead of `_attach` (the node that carries the hull bob/recoil transform), its transform is copied one step later in `update()`. During sharp weapon recoil or tight camera zoom, the shield bubble visibly drifts relative to the hull by 1 frame.
- **Fix:** Parent `_shield_mi` under `_attach` with local transform `_shield_pose` (matching other hull-attached effects) and remove the per-frame `hull_motion()` copy.
- **Confidence:** med

### 18. [Visual Quality / Bug] `NebulaHulls._material` mutates shared `Shader.code` in place on the main thread
- **Location:** `godot/world/nebula_hulls.gd:36` (`_material`)
- **Quote:** `mat.shader.code = code.replace("shader_type spatial;", "shader_type spatial;\nrender_mode fog_disabled;")` (`nebula_hulls.gd:36`)
- **Evidence:** OBSERVED
- **Why the player would notice:** Mutating `mat.shader.code` in place forces a synchronous shader recompile mid-frame and silently modifies every other user sharing that `Shader` resource (including non-hull effects if they ever share a shader).
- **Fix:** Ensure all hull/wreck/debris shaders declare `fog_disabled` at authoring time (verified by a standing check) and, if a runtime fallback is ever needed, duplicate/cache a `fog_disabled` shader variant instead of mutating `mat.shader.code` in place.
- **Confidence:** high

### 19. [Visual Quality / Bug] Planet and sky shaders disable mipmaps (`filter_linear`) and omit UV pole clamping on baked spheres
- **Location:** `godot/world/world_planet.gd:334, 336, 361` (`SPHERE`), `godot/world/world_sky.gd:400` (`SKY`), `godot/world/world_bake.gd:185` (`bake`)
- **Quote:** `uniform sampler2D tex_a : source_color, filter_linear, repeat_enable;` (`world_planet.gd:334`); `uniform sampler2D neb_tex : filter_linear, repeat_enable;` (`world_sky.gd:400`); `if img != null and not img.has_mipmaps(): img.generate_mipmaps()` (`world_bake.gd:185`)
- **Evidence:** OBSERVED
- **Why the player would notice:** `world_bake.gd` spends time generating full mipmap chains for every baked planet and nebula sky texture, but `SPHERE` and `SKY` sample them with `filter_linear` instead of `filter_linear_mipmap`, causing distant planet surface detail and crisp nebula edges to shimmer during camera pan/zoom. `SPHERE` (`uv_of` on line 361) also leaves `repeat_enable` on V without pole clamping, risking polar seam bleeding when `tex_a` is filtered.
- **Fix:** Switch `tex_a`, `tex_b`, and `neb_tex` samplers to `filter_linear_mipmap` and clamp V in `uv_of` (`clamp(v, 0.002, 0.998)`, matching `r01_sample`).
- **Confidence:** high

### 20. [Visual Quality / Bug] RCS thruster puffs omit `disable_fog = true`
- **Location:** `godot/render/ship_view.gd:1689-1695` (`_puff_mat`)
- **Quote:** `static func _puff_mat() -> StandardMaterial3D:` / `_pm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD` (`ship_view.gd:1689, 1695`)
- **Evidence:** OBSERVED (violates `docs/playbooks/effects.md:49` R82 rule that battle FX set `fog_disabled` so nebulae never dull them)
- **Why the player would notice:** In heavy nebula sectors, additive RCS thruster puffs dim and lose contrast against bright hulls that have `fog_disabled`.
- **Fix:** Set `_pm.disable_fog = true` in `_puff_mat()`.
- **Confidence:** high

### 21. [Bug - Settings] Runtime quality downgrade leaves SSAO enabled
- **Location:** `godot/render/look.gd:153-159` (`apply`)
- **Quote:** `if q == "max":` / `env.ssil_enabled = perf_old("ssil")` (`look.gd:153, 159`)
- **Evidence:** OBSERVED
- **Why the player would notice:** `LOOK.apply` turns `env.ssao_enabled = true` when `q == "max"`, but has no `else: env.ssao_enabled = false`. Switching quality down from `"max"` to `"high"` or `"low"` during a session leaves SSAO running and wastes GPU time.
- **Fix:** Explicitly set `env.ssao_enabled = (q == "max")` (and clear `ssil_enabled` when `q != "max"`).
- **Confidence:** high

### 22. [Rules vs Code / Dead Code] R01 Rocky Planet (`install_rocky`), 4 world shaders, and `BREACH.emitters` are dead / unwired on `main`
- **Location:** `godot/world/world_planet.gd:23` (`install_rocky`), `godot/world/world_shaders.gd` (`SKY`, `PLANET`, `CRYSTAL`, `DISC_FRONT`), `godot/fx/fx_breach.gd:1515` (`emitters`)
- **Quote:** `static func install_rocky(planet: MeshInstance3D, air: MeshInstance3D, sun_position: Vector3) -> void:` (`world_planet.gd:23`); `static func emitters(b: POOLS.Batch, bs: POOLS.Batch, E: Ent, ents: Array, ends: Array, r: RandomNumberGenerator, glow: Color) -> void:` (`fx_breach.gd:1515`)
- **Evidence:** OBSERVED (zero call sites across `godot/`)
- **Why the player would notice:** The upgraded rocky-planet shader pipeline (`install_rocky`, which includes pole-clamped sampling and richer rock lighting) is built but never called by `world.gd`, so rocky sectors never get the look improvement. Meanwhile 4 unused shaders in `world_shaders.gd` and `BREACH.emitters` remain as maintenance traps for future edits.
- **Fix:** Either wire `install_rocky` into `world.gd` for rocky planet presets (with a look-sheet check) or remove dead shaders and `BREACH.emitters` so live code matches what renders.
- **Confidence:** high

### 23. [Visual Quality] Wreck cooling cap (`SLAG`) looks overly loud and yellow-tan on Hullbreakers and Eclipse close-ups
- **Location:** `godot/fx/fx_death.gd:148` (`SLAG`), `godot/fx/fx_death.gd:618` (`_spawn_piece` fallback rim)
- **Quote:** `mesh.set_instance_shader_parameter("rim_col", dcol(fx.ships.get(leash), "rim", Color(1.0, 0.34, 0.05)))` (`fx_death.gd:618`)
- **Evidence:** OBSERVED (code + visually seen in `docs/shots/battle_baseline_1118/BATTLE1076_A16_c26_standard.jpg` and `BATTLE1076_E11_c26_standard.jpg` "Cooling wreck" frames, where bright yellow-tan procedural rims sit loudly across cut seams)
- **Why the player would notice:** Once a ship splits into a cooling wreck, the procedural slag cap reads as a flat bright yellow-tan crust rather than dark cooled steel/obsidian with faint dying embers; and if the ship record has already been removed from `fx.ships` when a piece initializes, line 618 silently falls back to orange `Color(1.0, 0.34, 0.05)` regardless of faction.
- **Fix:** Cache the ship's faction `dstyle` directly on the cut/piece spec (never look up `fx.ships.get(leash)` after death teardown) and tone down cooled slag albedo/emission saturation so dead wrecks read as dark structural ribs instead of bright yellow-tan foam.
- **Confidence:** med

---

## Structural Refactors (To Make Effects Safer to Change)

1. **Single Data-Driven Faction Material & Hazard Profile (`faction_looks.json` + `faction_look.gd`):**
   Currently faction art rules are scattered across at least 11 files (`fx_ship.gd`, `fx_death.gd`, `fx_death_beats.gd`, `fx_weapons.gd`, `fx_breach.gd`, `fx_shaders.gd`, `fx_hull.gd`, `fx.gd`, `ship_view.gd`, `squadron_craft.gd`, `hull_debris.gd`). Consolidate `wound_kind` (0..5), `soot_gain`, `damage_glow`, `spark_color`, `rcs_color`, `debris_style`, `fire_tick_style`, `boarding_style`, `smoke_color`, and `wreck_rim` into `faction_looks.json`, and add a standing check that fails if any zero-soot or no-orange faction receives hardcoded orange/soot defaults.
2. **Replace String-Injection Shaders and Scattered `Shader.new()` Calls with Parameterized Shaders + One `ShaderCache`:**
   `HULL._damage_code`, `NEBULA_HULLS._material`, `LS.material()`, `board.gd`, `squadron_wing.gd`, `squadron_craft.gd`, and `world_living.gd` build or mutate shaders ad hoc. Move all static shader compilation into one `ShaderCache` registered in `static_caches.gd`, remove in-place `shader.code` mutation in `nebula_hulls.gd`, and drive faction wound looks through uniforms rather than concatenated shader variants.
3. **One Effect Clock (`fx.now` / `fx.dt`) Across Battle Presentation:**
   Make `fx.now` the single presentation clock for volley completion waits, wreck-settle callbacks, boarding tweens, camera shake, ship/wing movement, and ion-storm burst flashes. That eliminates an entire class of hit-pause, kill-slowmo, and deterministic-capture desync bugs.
4. **Centralize Hull Surface Classification (`LOOK_RIM._is_hull`) and Wreck Lifecycle:**
   Fix `_is_hull` in one place (`get_active_material(i)`) so rim lighting and nebula fog protection automatically cover live hulls, cut wreck pieces, and board hull debris. Pair every `board.add_wreck` with `board.remove_wreck` on revive so Deathless reassembly cannot leave ghost hulks.
5. **Split Monolithic Presentation Files & Retire `fx_stub.gd`:**
   `battle.gd` (7,151 lines), `fx_death.gd` (4,242), `fx_ship.gd` (2,854), `fx_weapons.gd` (2,693), and `fx_shaders.gd` (2,469) mix orchestration, shader text, pooling, and faction art rules. Extract a thin `battle_fx_bridge.gd` (retiring `fx_stub.gd` once Nova Cannon and standalone `"hit"` events move to `gfx`) and split `fx_shaders.gd` by domain (sprites, ribbons, wounds, hull/wreck) so changes to one effect cannot accidentally break another.

---

## One Recommended Next Step

Land a focused **"Wounds V2 + Faction Leak Purge"** PR (implementing R416 Milestones 1-2, flipping `rendering/effects/wounds_v2 = true`, deleting the banned Eclipse grid / Glasswright spiderweb / Chorus magenta / universal soot-and-orange shader branches, and fixing `faction_looks.json` Directorate `damage_glow` + Eclipse trail + Glasswright RCS/debris), then re-capture the `BATTLE1076` A16/E11/Directorate/Chorus/Glasswright close-up look sheets to confirm every faction reads cleanly before touching secondary world or refactor items.

---

## Files Read

Verified against commit `8551a3384490ab45f9ff946a0973b29313208ffa` (line count + first 40 chars of last line per `docs/REVIEW_PROTOCOL.md`):

| File | Lines | Last line (first 40 chars) |
| --- | ---: | --- |
| `AGENTS.md` | 108 | `(seat table, ship sections, PC notes) is` |
| `docs/RULEBOOK.md` | 714 | `draws meshes at full detail. Set: Ryan, ` |
| `.claude/rules/godot-battle.md` | 142 | `R37). Set: Ryan (R37, R40). Ids: R37b, R` |
| `.claude/rules/ships.md` | 182 | `stage 6's hand chain stays an analysis p` |
| `.agents/skills/independent-audit/SKILL.md` | 28 | `3. **Ready / Verified** (1-line summary ` |
| `docs/playbooks/effects.md` | 146 | `and checks from outside. The Board makes` |
| `docs/playbooks/deaths_and_hits.md` | 425 | `Each is one or two Codex runs and one lo` |
| `docs/playbooks/factions.md` | 347 | `on Nov 11 2026. The pictures stay in con` |
| `docs/REVIEW_PROTOCOL.md` | 35 | `- Claude checks every claim against the ` |
| `godot/project.godot` | 80 | `}` |
| `godot/fx/API.md` | 611 | `neither these tools nor their pictures r` |
| `godot/fx/faction_looks.json` | 106 | `}` |
| `godot/fx/faction_look.gd` | 96 | `	return _pick(faction, "shield", "weapon` |
| `godot/fx/fx_wounds_flag.gd` | 7 | `	return bool(ProjectSettings.get_setting` |
| `godot/fx/fx_shield_cache.gd` | 67 | `	return digest.finish()` |
| `godot/fx/fx.gd` | 2277 | `	return hk` |
| `godot/fx/fx_ship.gd` | 2854 | `		_dmg_request(fx)` |
| `godot/fx/fx_shaders.gd` | 2469 | `"""` |
| `godot/fx/fx_hull.gd` | 1917 | `				(lb["node"] as Node3D).transform = (` |
| `godot/fx/fx_breach.gd` | 1926 | `		_tube(pt, points, e.R * 0.06, e.R * 0.` |
| `godot/fx/fx_weapons.gd` | 2693 | `` (blank trailing line) |
| `godot/fx/fx_death.gd` | 4242 | `		nd.global_position -= back` |
| `godot/fx/fx_death_beats.gd` | 592 | `			_implode(fx, s, p, T - 0.25)` |
| `godot/fx/fx_fragments.gd` | 385 | `			uploads += 1` |
| `godot/fx/fx_pool.gd` | 345 | `		return n` |
| `godot/fx/test/approved_effects.json` | 27 | `}` |
| `godot/fx/test/approved_effects_check.gd` | 351 | `	return "marked %s, shot down %s, body t` |
| `godot/render/look.gd` | 270 | `	return m` |
| `godot/render/look_rim.gd` | 155 | `	return false` |
| `godot/render/ship_view.gd` | 1798 | `		ring.rotation.y = -rotation.y` |
| `godot/render/board.gd` | 1217 | `		BV.outline(blocker_highlights, hex_wor` |
| `godot/render/build_assets.gd` | 590 | `				return` |
| `godot/render/squadron_wing.gd` | 460 | `	mesh.surface_end()` |
| `godot/render/squadron_craft.gd` | 206 | `	_orb(Vector3(0.12, 0.11, 0), Vector3(0.` |
| `godot/render/camera_rig.gd` | 255 | `	v_offset = shake_offset.y` |
| `godot/render/line_style.gd` | 178 | `		st.add_vertex(v[0])` |
| `godot/render/mesh_watch.gd` | 84 | `				fn.call(n)` |
| `godot/render/static_caches.gd` | 36 | `			sc.clear_static()` |
| `godot/scenes/battle/battle.gd` | 7151 | `	get_tree().quit(code)` |
| `godot/scenes/battle/fx_stub.gd` | 167 | `	items.clear()` |
| `godot/world/world.gd` | 1574 | `	if _living != null: _living.use_ship_de` |
| `godot/world/world_living.gd` | 1496 | `		if c != null: m.set_shader_parameter(p` |
| `godot/world/world_planet.gd` | 518 | `"""` |
| `godot/world/world_rocks.gd` | 559 | `		return n` |
| `godot/world/world_shaders.gd` | 488 | `"""` |
| `godot/world/world_sky.gd` | 529 | `	return out` |
| `godot/world/world_bake.gd` | 462 | `	return true` |
| `godot/world/ion_storm.gd` | 130 | `"""` |
| `godot/world/nebula_hulls.gd` | 37 | `	if mat.next_pass != null: _material(mat` |
| `godot/world/nebula_wake.gd` | 337 | `		(m as ShaderMaterial).set_shader_param` |
| `godot/world/blocker_visuals.gd` | 226 | `	node.global_position = centre + Vector3` |
| `godot/world/board_look.gd` | 74 | `	return {"plate": true, "underlay": 1.0, ` |
| `godot/world/hull_debris.gd` | 51 | `	return out` |

Look sheets visually inspected:
- `docs/shots/fx/dst4/real_hulls_sheet.jpg`
- `docs/shots/battle_baseline_1118/BATTLE1076_A16_c26_standard.jpg`
- `docs/shots/battle_baseline_1118/BATTLE1076_E11_c26_standard.jpg`
- `docs/shots/vent_fx_2026_11/vent_sheet_close.png`
- `docs/shots/terrain_fx_2/deadstar.jpg`
- `docs/shots/1359/1359_run2_sheet.jpg`
- `docs/shots/1361/AC1361_comets_c26.jpg`

**Not checked:** live GPU frame captures or running the Godot executable in this pass (static code + committed look-sheet audit only); binary `.glb` ship meshes/textures under `godot/assets/ships/`; audio files (`godot/audio/`); non-battle HUD/menu UI (`godot/ui/`); and `board/review_1124/` (intentionally excluded to keep this pass independent).
