# Battle Rules Audit on `main` (`godot/rules` and `tables.json`)

- **Issue**: #2203
- **Seat**: Neon (read-only audit; no files edited outside `contrib/neon/`)
- **Commit reviewed**: `adfce465e` (`main`, Nov 25 2026)
- **Method**: Full read of `godot/rules/*.gd`, `godot/rules/data/tables.json`, `godot/rules/sim/*.gd`, 16 rules test scripts, `docs/RULEBOOK.md`, `docs/playbooks/ships.md`, `docs/playbooks/balance.md`, `.claude/rules/godot-battle.md`, and `.claude/rules/ships.md`; headless Godot rules test runs; static table analysis; and scan of all 379 saved battles in `godot/rules/test/saved/records/*.jsonl.br`. Per the brief, no balance sims were run for numbers.

## Executive Verdict

Three **Blocking** defects, six **High** defects, and five **Medium** defects are live on `main` (`adfce465e`):
1. **Dead/crashing rules & unproved abilities**: Legacy orders (`full`, `lock`, `helm`) are still accepted by `canOrder` and advertised by `battle_api.ui_info` but crash `_giveOrder_raw` because `tables.json` `ORDERS` only defines `brace`; Sunward's shared `flagshipLedger` skill is logically contradicted and fired **0 times across all 379 saved battles** (including its own `t_flagshipLedger` fixture); and Issue #1705's ability-firing proof covers only **2 of 13 abilities** in `balance_sim_abilities_test.gd` (`phase` and `frenzy`), while `launch` is uncounted (`0` in `B.usage.ab`), 5 abilities have zero unit tests, and `sim_bot` cannot use post-move abilities.
2. **Contradictions with `ships.md` and `RULEBOOK.md`**: `chaserArc` (Swivel Arc Mounts) lets fixed broadsides fire directly astern (180 degrees), `treeSpit` and `treeArcLegal` bypass fixed-gun arcs completely, and R246's single-pool shield rule is still violated by `weakSide` (Brin T1a), `sim_battle._shield_total`, and the combat log's four-facing wording.
3. **Faction skews**: `wingKind` locks enemy Sunward, Directorate, and Glasswright carriers to fighters (6 anti-cap DPR) while player carriers launch bombers (18 anti-cap DPR, 60% pierce); Glasswrights are priced at swarm CP (1 CP `i_wisp`, 2 CP `i_blade`) and spawned in swarm counts by `genEnemyFleet`; and Chorus `b_drone` (42 raw DPR/CP) and Eclipse `d_jackal` (45 DPR, 60% shield pierce, 50% armor pierce, 133.3 EHP) outclass peers per CP.
4. **Determinism risks**: `JSM.rng_s` and `JSM.not_ported` are process-global statics unprotected by `BattleAPI`'s per-instance mutex; `startBattle` falls back to stale PRNG state when `seed` is omitted; and 11 rules sites depend on Dictionary insertion order for RNG draws, terrain erasure, or tie-breaks.

### Godot Rules Checks Run on `adfce465e` (No Balance Sims Run)

| Script | Result |
| --- | --- |
| `res://rules/test/rules_1649_test.gd` | PASS (5/5) |
| `res://rules/test/rules_1650_test.gd` | PASS (5/5) |
| `res://rules/test/rules_1651_test.gd` | PASS (27/27) |
| `res://rules/test/rules_1653_test.gd` | PASS (18/18) |
| `res://rules/test/rules_1560_test.gd` | PASS (27/27) |
| `res://rules/test/safety/ruled_numbers_test.gd` | PASS (15/15) |
| `res://rules/test/balance_sim_abilities_test.gd` | PASS (checks only `phase` and `frenzy`) |

---

## Findings

### Blocking

| # | finding | OBSERVED/INFERRED | file:line | exact quote | why it matters | your fix | confidence (high/med/low) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| B1 | Legacy orders `full`, `lock`, `helm` pass `canOrder` and `ui_info`, then crash `_giveOrder_raw` on `ORDERS[o]["n"]`; refused orders still spend undo and increment usage | OBSERVED | `godot/rules/rules.gd:4794-4796`, `4808-4810`, `4824`; `godot/rules/battle_api.gd:663`; `godot/rules/test/rules_1560_test.gd:197` | `if o == "full": return not jt(u.get("moved")) and not jt(u.get("isSq"))` (`rules.gd:4794`); `logm(String(u["name"]) + ": " + String(ORDERS[o]["n"]) + ".", pp(u))` (`rules.gd:4824`) | `tables.json` `ORDERS` has only `brace`. Calling `giveOrder` with `full`, `lock`, or `helm` mutates ship state and crashes at `ORDERS[o]["n"]`. Also `_giveOrder_raw` calls `undoSpend()` (4808) and increments `B["usage"]["ord"][o]` (4809) before `if not canOrder(u, o): return` (4810), repeating the issue 1481 bug. | Restrict `canOrder` and `battle_api._ui_info_raw` to `ORDERS.has(o)` (`brace` only), move `if not canOrder(u, o): return` above `undoSpend()`, and update `rules_1560_test.gd:197`. | high |
| B2 | `flagshipLedger` (Sunward shared C1a, 4 admirals) is dead: requires an already-fired ship, then rejects its weapon with `canFire` (0 fires in 379 saved battles, including `t_flagshipLedger`) | OBSERVED | `godot/rules/rules.gd:3835`, `3848` | `if x != u and not jt(x.get("isSq")) and jt(x.get("treeHasFired")): other = x; break` (`3835`); `if best != null and canFire(other, lw, best):` (`3848`) | Line 3835 picks an ally that already fired (`treeHasFired`), picks `best` across all enemies without checking range/arc/LOS (3845-3847), then blocks `treeExtraShot` with `canFire(other, lw, best)` (3848), which fails because `weaponReady(lw)` requires `fired == false`. Confirmed 0 fires across all 379 saved battles, including its dedicated fixture `t_flagshipLedger`. | Filter `t2` by `inReach(other, lw, t2)` and call `treeExtraShot(other, lwi, best, {"half": true})` directly instead of pre-gating with `canFire`. | high |
| B3 | Issue #1705 ability-firing proof is incomplete: `balance_sim_abilities_test.gd` checks only 2 of 13 abilities; `launch` is uncounted (`0` in `B.usage.ab`) with dead bot code; `sim_bot` never calls abilities after moving | OBSERVED | `godot/rules/test/balance_sim_abilities_test.gd:6-8`; `godot/rules/rules.gd:7148`; `godot/rules/sim/sim_bot.gd:39`, `87`; `godot/rules/battle_api.gd:915` | `if ab == "launch": return u["side"] != "player" and launchReady(u)` (`rules.gd:7148`); `_use_ability(ship, false)` (`sim_bot.gd:39`) | Only `phase` and `frenzy` are asserted in `balance_sim_abilities_test.gd`; 5 abilities (`evasive`, `reload`, `overburn`, `regrow`, `reclaim`) have no unit tests at all; `sim_bot.gd:87-95` and `battle_api.gd:915-918` have unreachable `launch` branches; `replaceWings` never increments `B.usage.ab["launch"]`; and `sim_bot` calls `_use_ability` only before `_move` (39 vs 42), so player `ionpulse` cannot fire after closing into range 4 and `focus`/`frenzy`/`phase` fire before target checks. | Expand `balance_sim_abilities_test.gd` to assert all 13 abilities on both sides (plus Thorne's rider and the 3 unproved Mastery III capstones), count player `replaceWings` launches in `B.usage.ab`, remove dead `launch` bot branches, and split `sim_bot` ability calls into pre-move and post-move phases. | high |

### High

| # | finding | OBSERVED/INFERRED | file:line | exact quote | why it matters | your fix | confidence (high/med/low) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| H1 | Player-vs-enemy faction skew in `wingKind`: enemy Sunward, Directorate, and Glasswright carriers always launch fighters while player carriers launch bombers | OBSERVED | `godot/rules/rules.gd:6984-6985`, `6989` | `if jt(set_) and u["side"] == "enemy": return own` (`6985`); `if not air: return "bomber"` (`6989`) | For `voidsworn`, `hegemony`, and `ithar` (`FACTIONS[fac].sq == "fighter"`), enemy carriers are locked to fighters (`guns`: 3x4, `vsCap: 0.5` = 6 raw capital dmg, 0 pierce, 18 HP), while player carriers of the same factions launch bombers (`bombs`: 2x9 = 18 raw capital dmg, 60% pierce, 28 HP: 3x capital damage and 55% more HP). Corsair (`bomber`) and Chorus (`spore`) are symmetric at line 6984. | Remove the `u["side"] == "enemy"` branch at `rules.gd:6985` so player and enemy carriers of the same faction use identical wing-selection rules. | high |
| H2 | Fixed-gun arc contradictions with RULEBOOK 4.2 / 6.17 and `ships.md`: `chaserArc` fires fixed broadsides directly astern (180 degrees); `treeSpit` and `treeArcLegal` fire fixed guns 360 degrees | OBSERVED | `godot/rules/rules.gd:479`, `482-483`, `5308`, `5888` | `if w["arc"] == "S": return a >= -0.5 and a <= 180.5` (`482`); `u["facing"] = treeFacingTo(u, tt); w2["fired"] = false; w2["cdLeft"] = 0; w2["off"] = 0` (`5888`) | RULEBOOK 4.2 forbids rear-facing guns and RULEBOOK 6.17 requires fixed side guns to stay fixed. `chaserArc` (Swivel Arc Mounts) lets `P`/`S` fixed broadsides shoot straight astern (`+/-180.5` deg), and line 479 tests dead `w.get("k") == "turret"`. `treeSpit` (Voice T1b, 5888) temporarily rotates `u["facing"]` to fire fixed `F` guns directly behind the hull, and `treeArcLegal` (Kassar T1b `secondVolley`, 5305-5308) drops `inArc` completely. | Cap `chaserArc` `P`/`S` aft angle below 150.5 degrees (widen forward only, never past stern) and replace `treeSpit`/`secondVolley` out-of-arc fixed-gun shots with turret-only or free-turn-before-fire rules. | high |
| H3 | R246 single-pool shield violations: `weakSide` (Brin T1a) and `sim_battle._shield_total` still sum the four `sh` side catches (~2.35x-2.90x `shp`); combat log still names four facing shields | OBSERVED | `godot/rules/rules.gd:6476`, `4165`; `godot/rules/sim/sim_battle.gd:350`, `358` | `for v in a["sh"]: sa += z0(v)` (`rules.gd:6476`); `for shield in unit.sh:` (`sim_battle.gd:350`); `if jt(res.shield): parts.append(ns(res.shield) + " to " + String(QUAD_NAME[quad]) + " shields")` (`rules.gd:4165`) | `SHIELD_COV` sums differ by hull class (Frigate 2.35, Destroyer 2.50, Cruiser 2.70, Battleship 2.85, Dreadnought 2.90). Summing `sh` in `weakSide` sorts mixed-class fleets backwards relative to their real R246 pool `shp`, and `sim_battle._shield_total` inflates weapon shield-damage telemetry ~2.35x-2.90x. Also `sim_battle.gd:358` uses `ionOf` and raw `w.pierce` instead of `ionVs` and effective pierce. | Compare `z0(a.get("shp"))` in `weakSide`, return `float(unit.get("shp", 0.0))` in `sim_battle._shield_total` (and read `result.shield` from `super.applyHit`), and remove the four-facing phrasing at `rules.gd:4165`. | high |
| H4 | Glasswrights are priced at swarm CP (1 CP `i_wisp`, 2 CP `i_blade`) and spawned as swarms by `genEnemyFleet`; Chorus `b_drone` and Eclipse `d_jackal` outclass peers per CP | OBSERVED | `godot/rules/rules.gd:1729`; `godot/rules/data/tables.json` (`HULLS.i_wisp`, `HULLS.i_blade`, `HULLS.b_drone`, `HULLS.d_jackal`) | `if x.cp <= mn + 1 and not x.car: light.append(x)` (`rules.gd:1729`); `"i_wisp":{"n":"Glasswright sliver","cls":"Frigate","fac":"ithar","size":0.46,"cp":1` (`tables.json`) | `genEnemyFleet` budgets purely in CP and `arch == "swarm"` swarms `cp <= mn + 1`. Because `i_wisp` is CP 1 (`val: 90`, speed 7, ev 28, Crystal Vanes -18 at 2 hexes, `blink`, `fade`) and `i_blade` is CP 2 (`val: 170`), Glasswrights field the same hull counts as 45-val Chorus drones and 55-val Corsair raiders, contradicting "Glasswrights are elite, not a swarm." Static outliers: Chorus `b_drone` (CP 1, `val: 45`) outputs 42 sustained raw DPR/CP (`bioplasma` 2x10/spines + `tendril` 2x11/acid/p0.5) plus 3 regen and `regrow` vs 15-20 non-flak DPR/CP for peer 1-CP frigates; Eclipse `d_jackal` (CP 2, `val: 210`) combines 45 sustained DPR (22.5/CP) with 60% shield pierce + 50% armor pierce, 133.3 EHP (66.7 EHP/CP), 2 regen, `reanimate`, and `phase`. | Raise Glasswright CP costs (e.g. `i_wisp` CP 2, `i_blade` CP 3) and exclude `ithar` from `swarm` in `effArch`; audit `b_drone` dual-weapon DPR and `d_jackal` pierce/EHP once #1705 clears balance sims. | high |
| H5 | Additional player-vs-enemy battle rule skews: `reanimate` chance (35% player vs 20% enemy), carrier auto-launch timing (`replaceWings` vs `aiAbilities`), and `clearSpawns` lane width | OBSERVED | `godot/rules/rules.gd:4396`, `1912`, `7763`, `1345` | `and rnd() < (0.2 if t["side"] == "enemy" else 0.35):` (`4396`); `if side == "player" and not jt(B.get("over")): replaceWings(side)` (`1912`); `near.call(u, 2 if side == "player" else 1)` (`1345`) | Non-legion `reanimate` favors player hulls by +15 percentage points (35% vs 20%). Player carriers auto-launch replacement wings at start of turn (before bracing or dying), while enemy carriers only launch during their own `"aim"` step (7763, skipped if braced or destroyed first). `clearSpawns` clears radius 2 + 6-hex width-1 lane for player vs radius 1 + 4-hex width-0 lane for enemy. (Documented `SHOP_DISCOUNT` economy tuning in `docs/playbooks/balance.md` and enemy `adapt` anti-carrier tech are intentional and excluded.) | Make `reanimate` chance, `replaceWings` launch timing, and `clearSpawns` clearance symmetric between player and enemy (or document any intended difficulty offset in `docs/playbooks/balance.md`). | high |
| H6 | Process-global `static var rng_s` and `static var not_ported` in `jsm.gd` break thread/instance isolation; unseeded `startBattle` fallback and `balance_sim.gd` `randi()` risk nondeterminism | OBSERVED | `godot/rules/jsm.gd:59`, `81`; `godot/rules/battle_api.gd:20`; `godot/rules/rules.gd:1426`; `godot/rules/sim/balance_sim.gd:70` | `static var rng_s: int = 0` (`jsm.gd:59`); `var _mutex := Mutex.new()` (`battle_api.gd:20`); `JSM.rnd_seed(int(seed) if not seed.is_empty() else randi())` (`balance_sim.gd:70`) | `BattleAPI`'s mutex is per-instance while `JSM.rng_s` and `JSM.not_ported` are process-global statics. Two `Rules`/`BattleAPI` instances running concurrently in one process corrupt each other's RNG stream and halt state. In `startBattle` (`rules.gd:1426`), omitting `cfg["seed"]` draws from leftover `JSM.rng_s`; `balance_sim.gd:70` falls back to Godot's unseeded `randi()`. | Move `rng_s` and `not_ported` onto each `Rules` instance (or a per-battle RNG object), require an explicit integer seed in `startBattle`, and log/fix a default seed in `balance_sim.gd`. | high |

### Medium

| # | finding | OBSERVED/INFERRED | file:line | exact quote | why it matters | your fix | confidence (high/med/low) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| M1 | `killCauseOf` checks `w.get("k")` against 12 weapon `id`s that do not exist in `W.k`, breaking bomber (`bombs`) kill causes | OBSERVED | `godot/rules/rules.gd:4371`, `4374`; `godot/rules/data/tables.json` (`W.bombs`) | `if trt == "gauss" or k == "gauss" or k == "doom": return "flay"` (`4371`); `if k == "torp" or k == "htorp" or k == "startorp" or k == "bombs": return "big"` (`4374`) | `tables.json` `W` only has 7 `k` values (`battery`, `flak`, `lance`, `torp`, `bio`, `gauss`, `sq`). `W.bombs` has `k: "sq"` and no trait, so `k == "bombs"` is always false and bomber kills fall through to `"blast"` instead of `"big"`. The other 11 `id`-in-`k` checks (`doom`, `bioplasma`, `tendril`, `sporeb`, `beam`, `htorp`, `startorp`, `hbattery`, `turret`, `autocannon`, `scatter`) are dead branches masked by `trt` or other `k` matches. | Check `var wid = w.get("id")` for `wid == "bombs"` (and remove the 11 dead weapon-`id` checks against `k`). | high |
| M2 | Pre-gating `treeExtraShot` with `canFire` silently skips already-fired ships in `weldedFight`, `oneOrder`, and `barrage` follow-ups; `salvoEnd` Mastery III logs before shot confirmation | OBSERVED | `godot/rules/rules.gd:5863`, `6422`, `6719`, `3659-3660` | `var keep = [w.get("fired"), w.get("cdLeft")]; w["fired"] = false; w["cdLeft"] = 0; var ok = false` (`5863`); `if not canFire(u, wW, tW): continue` (`6719`) | `treeExtraShot` clears `fired`/`cdLeft` so spent weapons can make bonus shots, but `weldedFight` (6719), `oneOrder` (6422), and the `barrage` follow-ups (`6226`, `6238`, `6253`, `6274`, `6283`, `6296`) pre-filter with `canFire`, silently dropping ships that already fired earlier in the round. In `salvoEnd` (3659-3661), `m3Fx` fires before `treeExtraShot` confirms the fallback target is in range/arc/LOS. | Replace pre-`treeExtraShot` `canFire` filters with `inReach` (plus `not off` and `k != "flak"`), and emit `salvoEnd` `m3Fx` only after `treeExtraShot` returns `true`. | high |
| M3 | `SIM_BUILD` `"mastery"` writes top-level `run["mastery"]`, leaving `run["lineage"]["mastery"]` at 0 so Mastery I-III capstone rules never activate from `SIM_BUILD.mastery` | OBSERVED | `godot/rules/sim/balance_sim.gd:203`, `205`; `godot/rules/rules.gd:388` | `for field in ["admiral", "mastery"]:` (`balance_sim.gd:203`); `return int(z0(RUN["lineage"].get("mastery")))` (`rules.gd:388`) | `rules.gd:388` reads `RUN["lineage"].get("mastery")` for `capMastery()` (Mastery I-III), while `balance_sim.gd:203-205` only sets top-level `run["mastery"]` (campaign admiral mastery level). Any `SIM_BUILD` passing `{"lineage": {...}, "mastery": 3}` fails to enable Mastery I-III in battles unless `"mastery"` is duplicated inside `lineage`. | Copy `build["mastery"]` into `run["lineage"]["mastery"]` as well when `run.lineage` has a `capstone` (or validate a distinct `capstone_mastery` field). | high |
| M4 | Dictionary iteration order drives RNG draws, terrain mutation, and tie-breaks across 11 rules sites; `CaptainData` uses engine-dependent `String.hash()`; native `sqrt(3.0)`/`PI`/`pow`/`sqrt` mix with `JSM` | OBSERVED | `godot/rules/rules.gd:42`, `269`, `364`, `622`, `812`, `1478-1479`, `6324`; `godot/rules/captain_data.gd:19`, `57`; `godot/rules/jsm.gd:192`, `452` | `var perks: Array = [pick(PERKS.keys())] if jt(vet) else []` (`rules.gd:364`); `for k in T.keys():` (`rules.gd:1478`); `var SQRT3 = sqrt(3.0)` (`rules.gd:42`); `return x * pow(2.0, float(n))` (`jsm.gd:192`) | `PERKS.keys()` (364), `BEVENTS.keys()` (622), `ROCK_KINDS.keys()` (685), `inner.keys()` (812), and boss rock deletion `T.keys()` (1478-1479) consume `rnd()` in Dictionary insertion order, while `volleyHits.keys()` (6324), `spatSet.keys()` (6305), and `sec.keys()` (3996, 4013, 6591, 6729) break ties by key order; any table or serialization reorder breaks saved hashes. `CaptainData` uses Godot's `String.hash()` (19, 57), and `rules.gd:42, 269` / `jsm.gd:192, 452` rely on platform `libm` `sqrt`/`pow` and Godot `PI` rather than exact IEEE words. | Sort key arrays explicitly before RNG draws or tie-breaks where future edits won't break saved baselines, use FNV-1a/SHA-256 instead of `String.hash()` in `CaptainData`, and replace `sqrt(3.0)` with an exact `JSM.words(...)` constant. | med |
| M5 | Asymmetric single-side broadside on `c_reaver` (`scatter:S` with no port gun), plus dead `"R"` rear-arc plumbing and unused `B.tr` fields | OBSERVED | `godot/rules/data/tables.json` (`HULLS.c_reaver`); `godot/rules/rules.gd:22`, `284`, `5424`, `5428` | `if arc == "R": return A >= 119.5` (`rules.gd:284`); `B["tr"]["swarmHitBy"] = {}; B["tr"]["volleyShips"] = {}; B["tr"]["volleyHit"] = {}; B["tr"]["burnStays"] = null` (`rules.gd:5424`) | `c_reaver` mounts `[["torp","F"],["scatter","S"]]` (P=0, S=1), the only hull in `tables.json` with an asymmetric broadside, breaking `ships.md` port/starboard symmetry. `"R"` rear arc (`rules.gd:22, 284`) is unused by any hull, and `B["tr"]["volleyHit"]` (1492, 5424) and `B["tr"]["wingCapFirst"]` (1494, 5428) are initialized every round and never read or written anywhere else. | Change `c_reaver`'s `scatter` to a symmetrical mount (`F`/`T` or paired `P`/`S` per `c_reaver`'s hull mesh) and remove dead `"R"` arc and unused `B.tr` keys once saved records are next refreshed. | high |

---

## Issue #1705 Ability-Firing Proof Status (All 13 Abilities + Riders + Mastery III)

Evidence from `godot/rules/test/balance_sim_abilities_test.gd`, `godot/rules/test/*.gd`, and all **379 saved battles** (`godot/rules/test/saved/records/*.jsonl.br`):

| Ability | Name | In `balance_sim_abilities_test.gd`? | Dedicated unit test in `godot/rules/test/*.gd`? | `B.usage.ab` (Player, 379 saved) | Log count Player [scens] | Log count Enemy [scens] | Proof status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `phase` | Fold skip | YES (battle + boss) | `rules_1649_test.gd`, `thread_test.gd`, `threat_preview_test.gd` | 143 | 143 [53] | 64 [24] | Proved (both sides + sim test) |
| `frenzy` | Blood frenzy | YES (battle) | `rules_1649_test.gd` | 67 | 81 [29] | 17 [7] | Proved (both sides + sim test) |
| `evasive` | Evasive burn | NO | NONE | 239 | 239 [104] | 289 [150] | Saved battles only; no unit or sim assertion |
| `reload` | Reload torpedoes | NO | NONE | 154 | 154 [94] | 49 [35] | Saved battles only; no unit or sim assertion |
| `focus` | Concentrated fire | NO | `threat_preview_test.gd` | 140 | 140 [78] | 13 [9] | Saved battles only; no sim assertion |
| `launch` | Automatic wings | NO | `undo_test.gd` | **0** | 122 [61] | 98 [77] | **Uncounted in `B.usage.ab`** (player `canAbility` false; bot code dead) |
| `surge` | Shield surge | NO | `rules_1560_test.gd`, `rules_1651_test.gd` | 106 | 106 [59] | **1 [1]** | Enemy `surge` barely exercised (1 fire across 379 battles); no sim assertion |
| `nova` | Spinal cannon | NO | `rules_1481_test.gd`, `undo_test.gd` | **2** | **2 [1]** | 31 [19] | Player `nova` barely exercised (2 fires in 1 scen); no sim assertion |
| `ionpulse` | Ion pulse | NO | `ion_pulse_ai_test.gd` | 19 | 19 [13] | 111 [77] | Player bot cannot fire post-move (`sim_bot.gd:39`); no sim assertion |
| `overburn` | Overburn | NO | NONE | 66 | 66 [35] | 105 [46] | Saved battles only; no unit or sim assertion |
| `regrow` | Rapid regrowth | NO | NONE | 64 | 64 [35] | 24 [8] | Saved battles only; no unit or sim assertion |
| `blink` | Phase jump | NO | `rules_1481_test.gd`, `undo_test.gd` | 89 | 89 [42] | **8 [2]** | Enemy `blink` lightly exercised (2 scens); no sim assertion |
| `reclaim` | Repair swarm | NO | NONE | 44 | 44 [40] | 32 [18] | Saved battles only; no unit or sim assertion |

Additional coverage gaps observed across the 379 saved battles:
- **`TREE_FX`**: `flagshipLedger` fired **0 times** across all 379 battles (including `t_flagshipLedger`, see B2). All other 213 distinct `TREE_FX` kinds fired on at least one admiral (66 shared B/C branch copies on alternate admirals did not).
- **`CMD_RIDERS`**: 23/24 recorded fires in saved battles. **`thorne`** recorded **0** because `spendTurn` (`rules.gd:2119`) intentionally skips `riderCount()` so turns remain undoable (unit-tested in `rules_1651_test.gd`).
- **`CAPSTONE_MASTERY_FX` (Mastery III)**: 45/48 recorded fires in saved battles. **`malek:cap:0` (`salvoEnd`)**, **`matriarch:cap:1` (`broodNoStop`)**, and **`razormaw:cap:1` (`preyEveryMouth`)** recorded **0** in saved battles (covered only by unit tests in `rules_1650_test.gd`).
- **`BOONS`**: Only 9/48 boons emit `boonFx` / `B.boonStats` entries in saved battles (passive stat boons do not log to `boonStats`).
- **All `PERKS`, `MODULES`, `RELICS`, `ASPECTS`, `BOONS`, `ADMIRALS`, `FAC_VERBS` keys**: verified referenced across `godot/rules/` and `godot/campaign/` (no orphaned table keys; `salvage`/`xpPct`/`shake`/`gorge` are campaign-side).

---

## One Recommended Next Step

Land a focused rules-fix PR before opening any balance-sim pass: fix **B1** (remove crashing legacy orders and guard `undoSpend`), **B2** (`flagshipLedger` target/readiness filter), **B3** (extend `balance_sim_abilities_test.gd` to assert all 13 abilities on both sides, fix `sim_bot` post-move ability timing, count player `replaceWings` launches), **H1** (symmetric `wingKind`), and **H3** (`weakSide` + `sim_battle._shield_total` using `shp`), then re-baseline the saved results and run the #1705 ability-proof gate before collecting balance numbers.

---

## File Read Ledger (`REVIEW_PROTOCOL.md` Section 1)

| File | Total lines | Ranges read (for files >1,500 lines or >60 KB) | First 40 chars of last line |
| --- | --- | --- | --- |
| `godot/rules/rules.gd` | 8013 | 1-650, 651-1300, 1301-1950, 1951-2600, 2601-3212, 3213-3250, 3251-3833, 3834-4369, 4370-4380, 4381-4930, 4931-5480, 5481-6030, 6031-6580, 6581-7130, 7131-7680, 7681-8013 | `\tB["aiActive"] = null; u["activated"] = ` |
| `godot/rules/battle_api.gd` | 1261 | 1-650, 651-1261 (68 KB) | `\treturn why` |
| `godot/rules/jsm.gd` | 654 | full | `\treturn s if i < 0 else s.substr(0, i) +` |
| `godot/rules/threat_preview.gd` | 623 | full | `\t\treturn result` |
| `godot/rules/battle_snapshot.gd` | 115 | full | `\treturn v` |
| `godot/rules/combat_records.gd` | 107 | full | `\t\treturn` |
| `godot/rules/captain_data.gd` | 82 | full | `\treturn used` |
| `godot/rules/data/tables.json` | 1 | parsed full JSON (247 KB, minified single line) | `{"sha256":"568c6920fc26a06cedd765948e53a` |
| `godot/rules/sim/balance_sim.gd` | 462 | full | `\treturn fleet` |
| `godot/rules/sim/sim_battle.gd` | 445 | full | `\treturn report` |
| `godot/rules/sim/sim_bot.gd` | 183 | full | `\treturn rules.jt(weapon.get("fired"))` |
| `godot/rules/sim/README.md` | 80 | full | ``  `PAIRED_RUN` rows summarize deltas by `` |
| `godot/rules/test/balance_sim_abilities_test.gd` | 83 | full | `\tsuper._print_campaign(player_faction, c` |
| `godot/rules/test/balance_sim_refit_test.gd` | 46 | full | `\treturn false` |
| `godot/rules/test/balance_sim_run_test.gd` | 53 | full | `\tprint("PASS: two full campaign runs, %d` |
| `godot/rules/test/rules_1479_test.gd` | 123 | full | `\treturn [str(B.get("over")) == "win" and` |
| `godot/rules/test/rules_1481_test.gd` | 213 | full | `\treturn [ok2 and R.z0(B["usage"]["ab"].g` |
| `godot/rules/test/rules_1560_test.gd` | 256 | full | `\treturn [near(weak, minf(95.0, plain + 1` |
| `godot/rules/test/rules_1649_test.gd` | 88 | full | `\treturn [kept and missed and s1 == [fals` |
| `godot/rules/test/rules_1650_test.gd` | 122 | full | `\treturn [R.hdist(u, t) == 1 and absf(m3 ` |
| `godot/rules/test/rules_1651_test.gd` | 390 | full | `\treturn [true, ""]` |
| `godot/rules/test/rules_1653_test.gd` | 268 | full | `\treturn [R.jt(u.get("mirrorUsed")) and t` |
| `godot/rules/test/shield_pool_test.gd` | 50 | full | `\tquit(1 if bad > 0 else 0)` |
| `godot/rules/test/ion_pulse_ai_test.gd` | 52 | full | `\tquit(1 if bad > 0 else 0)` |
| `godot/rules/test/boss_1885_test.gd` | 61 | full | `\tquit(1)` |
| `godot/rules/test/effect_caps_test.gd` | 32 | full | `\tquit(1 if bad > 0 else 0)` |
| `godot/rules/test/thread_test.gd` | 92 | full | `\tquit(0 if bad == 0 else 1)` |
| `godot/rules/test/tree_prompt_test.gd` | 66 | full | `\tquit(0 if fails == 0 else 1)` |
| `godot/rules/test/safety/run_cache_check.js` | 194 | full | `main().catch(e => { console.error('FAIL:` |
| `godot/rules/test/saved/README.md` | 122 | full | `This upload is for access to the files; ` |
| `docs/REVIEW_PROTOCOL.md` | 35 | full | `- Claude checks every claim against the ` |
| `docs/RULEBOOK.md` | 739 | 1-739 (78 KB) | `draws meshes at full detail. Set: Ryan, ` |
| `docs/playbooks/ships.md` | 668 | 1-668 (71 KB) | `` (empty trailing line) |
| `docs/playbooks/balance.md` | 72 | full | `` `RAMP` and shop prices.`` |
| `.claude/rules/godot-battle.md` | 155 | full | `R37). Set: Ryan (R37, R40). Ids: R37b, R` |
| `.claude/rules/ships.md` | 183 | full | `stage 6's hand chain stays an analysis p` |

---

## Not checked:
- Balance simulation win rates or faction power numbers (explicitly excluded by the brief until Issue #1705 proves all abilities fire).
- Full replay of all 379 saved battles through `godot/rules/test/saved/check.js` and `run_cache_check.js` (`VS_NO_MEMO=1` vs cached parity sweep), beyond verifying the 7 focused Godot rules test suites above.
- `godot/campaign/campaign.gd` full line-by-line audit (searched only to confirm campaign-owned `RELICS`, `FAC_VERBS`, and `mastery` keys), `godot/rules/sim/sim_run_policy.gd`, and `godot/rules/sim/sim_rewards.gd`.
- Visual/3D hull meshes (`hulls*/`, `weapon_match.py`, `godot/scenes/battle.gd`) to verify physical weapon-mount alignment against `tables.json` arcs and `c_reaver`'s starboard-only `scatter:S`.
- Remaining standalone test scripts not run in this audit (`api_smoke.gd`, `arrival_preview_test.gd`, `map_trial_test.gd`, `threat_preview_test.gd`, `undo_test.gd`, `balance_sim_refit_test.gd`, `balance_sim_run_test.gd`, `boss_1885_test.gd`, `effect_caps_test.gd`, `ion_pulse_ai_test.gd`, `rules_1479_test.gd`, `rules_1481_test.gd`, `shield_pool_test.gd`, `thread_test.gd`, `tree_prompt_test.gd`).
