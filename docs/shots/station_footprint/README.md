# Station footprint: issue 983

R314: the big station covers 19 hexes, so the rules block all 19 and every rule that measured from the station centre now measures from its edge. This report covers run 2 on top of the run 1 partial branch.

## What changed

- `battle.js` (`genTerrain`, station map): the station is every hex within distance 2 of its centre (19 hexes). The site check keeps the whole 19-hex footprint on the board and rejects any hole cell within 4 of the centre (radius 2 plus the old 2-hex margin). The debris band moved to distance 3 to 4 at the same 42 percent density. `TERRAIN_META.stationR = 2`.
- `battle.js` (edge-feature teaching station): keeps its 3 hexes and sets `TERRAIN_META.stationR = 1`, so the first fight keeps its scale.
- `battle.js` and `godot/rules/rules.gd`: `stationRad()` added; `objZone`, `stationFire`, `aiObjScore`, `objectiveTick` and `sqObjNear` add it to their distance constant. Run 1 had already ported the battle.js side; run 2 fixed the hole distance to 4 in both copies and verified the port.
- `godot/rules/test/scenarios.json`: run 1's three station scenarios stay (`s983_station_defend`, `s983_station_plain`, `s983_teaching_station_defend`). Run 2 also reseeded 22 tree fixture seeds, test data only, because the terrain random stream moved and those fixtures stopped firing their picks. This is the same reseed method used for issue 371 (`contrib/opus/tools/issue371/reseed_fixtures.js`, seeds 37100 and up).
- `godot/render/board.gd`: no edit needed. See the board check below.
- `docs/shots/station_footprint/capture.gd`: the top-down picture script.

## Every station rule, measured from the edge

The number in the rule is now the number of hexes from the station's edge.

| Rule | Old (7-hex station, radius 1) | New (19-hex station, radius 2) |
|---|---|---|
| Defend guard zone (`objZone`) | 2 from the centre (1 from the edge) | 2 from the edge (4 from the centre) |
| Defend damage per enemy ship (`objectiveTick`) | within 2 of the centre | within 2 of the edge (4 from the centre) |
| Station guns (`stationFire`) | within 5 of the centre | within 5 of the edge (7 from the centre) |
| Veteran AI pull to the station (`aiObjScore`) | 2 from the centre | 2 from the edge (4 from the centre) |
| Wing support near the station (`sqObjNear`) | 3 from the centre | 3 from the edge (5 from the centre) |
| Debris ring | distance 2 to 3 from the centre, 1 to 2 beyond the edge | distance 3 to 4, still 1 to 2 beyond the edge |
| Small station pieces on other maps | separate, smaller model | unchanged; the `station` entries in the pieces lists only affect the scattered set pieces |

`stationR` is the only new save field, inside `B.map`. No rule field was renamed.

## Geometry and site check evidence

A scratch harness ran 240 seeded station battles over six shapes (`open`, `shoals`, `colossus`, `dense`, `archipelago`, `corner`), half rout and half defend:

```
station cells {"19":240} battles 240 exceptions 0
holes present: nearest hole to centre 5 cells within 4 of centre (should be 0): 0
```

Every battle had all 19 cells, every cell was within 2 of the recorded centre, and no hole cell was inside the 4-hex clearance. The fallback site path still uses the old ring filter, but no battle in this sample needed it.

## Board check (no edit)

`godot/render/board.gd` builds one structure per contiguous station cluster. A 19-hex disc is one cluster of 19 cells, which is above `STATION_BIG_HEXES` (5), so it picks `STATION_BIG_LEN` (46). `hex_world` is affine in q and r and the 19-hex offsets sum to zero, so the cluster centroid equals the centre hex; the station is centred on its footprint. The top-down capture shows one big station over the cluster, not several small ones.

## Callers, saves, twins, UI, CI

| Item | Finding |
|---|---|
| Callers | `stationR` is read only by `stationRad()` in `battle.js` and `rules.gd`. It is set in the station map and the edge-feature station. The five readers above are the only rule paths that measured from the centre. |
| Saves | New maps keep `stationR` through a JSON save round trip (checked: `2` before and after). An old save with no `stationR` gets `stationRad() = 0`; the guard ring returns to distance 2 and the old 7-hex station behaves exactly as before. The Godot `stationRad()` has the same default. |
| Twins | `battle.js` and `godot/rules/rules.gd` changed together. Rules parity re-exported the tables; campaign tables were unchanged. `oracle_copy_test.js` passes on both committed tables. |
| UI | `ui3d.js` and `board.gd` draw zones from `objZone` in the view, so the guard ring follows the new edge. The defend text still says "within 2 hexes of it", which now means 2 from the edge. No other screen reads the station distance. |
| CI | GitHub runs the standard four jobs: standing checks (`run_all_checks.js`), Godot rules and campaign parity, the Godot-only safety net, and the Godot game checks. No new test file was added, so nothing needs registering in `run_all_checks.js`. |

## Balance report (deltas only)

Mode: a `stationsim` harness built from `sim3d.js`'s own battle loop. Six player factions take turns against six enemy factions, fixed skirmish lists, 20 battles per pairing, 120 battles per mode per side. Seeds are paired (`983000 + i`) and both sides use the same seeds and fleet lists. Before is `origin/main` `battle.js`; after is this branch. "First hit" is the first round any damage lands. "Guard ring" is the first round an enemy non-squad ship is within 2 of the station edge. The player bot's own defend heuristic in `sim3d.js` (it camps at a fixed distance 3) was not changed, so both sides are measured with the same bot.

| Mode | n | Metric | Before | After | Delta |
|---|---:|---|---:|---:|---:|
| Defend | 120 | Player win | 12% | 0% | -12 points |
| Defend | 120 | Withdraw | 106 | 120 | +14 |
| Defend | 120 | Station falls (integrity 0) | 88% | 100% | +12 points |
| Defend | 120 | Mean station integrity | 0.28 / 5 | 0.00 / 5 | -0.28 |
| Defend | 120 | Mean rounds | 5.01 | 3.68 | -1.33 |
| Defend | 120 | First guard ring round | 2.33 | 1.57 | -0.76 |
| Defend | 120 | Hull left | 58% | 75% | +17 points |
| Plain station, rout | 120 | Player win | 54% | 54% | 0 |
| Plain station, rout | 120 | Mean rounds | 7.80 | 8.09 | +0.29 |
| Plain station, rout | 120 | Hull left | 21% | 20% | -1 point |
| Plain station, rout | 120 | First hit round | 1.02 | 1.06 | +0.04 |

Defend becomes clearly harder. The bigger station puts its edge two rings out, so the 2-hex damage band is now rings 3 and 4 (18 and 24 cells) instead of the old single ring of 12 cells at distance 2, and the guard ring moves from distance 2 to 4. More attackers fit in the band and the defender has a longer perimeter to cover. Plain station rout is unchanged in win rate; the extra station body only costs a little time. No numbers were retuned, as the job asked.

Robustness in the same runs: 0 ships stood on a blocking hex and 0 exceptions in all 480 station battles. The standard sims also pass: `fuzz 100 battles: exceptions 0, invariant breaks 0` and `fuzz 60 battles` with `ENC=defend`: `exceptions 0, invariant breaks 0`.

## Checks run

Standing checks, `node contrib/opus/tools/run_all_checks.js`. Final run: 61 PASS, 2 KNOWN, 1 FAIL.

```
PASS: tree_effects_test (222 tree fixtures fired their pick; 0 waiting rows are inert)
PASS: tree_last_rows_test (issue 529, the last seven tree rows and the you-may prompts move their numbers)
PASS: oracle_copy_test (no oracle folders exist and both committed tables equal a fresh export)
KNOWN: findings_tests (7 listed failures: KIT-1, KIT-3, ROS-9, MOD-2, EVT-1, NEM-6, UI-5)
KNOWN: oracle_drift_guard (12 constant differences within the baseline)
FAIL: memory_lint_tests (contrib/opus/FINDINGS.md:346 row R317: its "landed in" path LOOP.md is not a file in the repo)
```

The memory lint failure is pre-existing on `origin/main`: this branch does not touch `contrib/opus/FINDINGS.md` or `LOOP.md`. All other standing rows PASS. The first full run before the tree reseed failed `tree_effects_test` and `tree_last_rows_test` because the station terrain moved the random stream; after the reseed both pass as shown.

Rules parity and campaign parity, `tools\pc\parity.bat nopause`:

```
battle s983_station_defend: PASS (106 records identical, result: end loss)
battle s983_station_plain: PASS (113 records identical, result: end win)
battle s983_teaching_station_defend: PASS (92 records identical, result: end loss)
PASS: the Godot port matches the game's rules exactly.
PASS: the Godot campaign matches the game on all 30 seeded runs, and the cross-twin save hand-off check passes.
```

All 284 seeded battles passed.

Rules safety net, `tools\pc\rules_safety.bat nopause`:

```
Cache check: 284 battles, 0 failures
ruled numbers: 15 checks, 0 failures
PASS: Rules safety net (Godot only), 511.085 s
```

## Pictures

All are 1338 by 720 and live in `out/shots` for the reviewer.

| Picture | What to inspect |
|---|---|
| `station_board_start.png` | Battle start on the station map. The big station stands over the blocked cluster; the guard ring and the Hold the station marker are visible. |
| `station_topdown.png` | Top-down of the same map. The station body spans the 19-hex cluster; every hex under it is blocked. |
| `station_block_tooltip.png` | A target tip that names the blocking hexes: "Blocked by the station at 4,11, the station at 5,11 ... the station at 8,11." Direct in-game proof that the station now blocks line of fire across its footprint. |

Capture method: `docs/shots/station_footprint/capture.gd` is a SceneTree script that instantiates the battle scene, focuses the defend objective hex, switches the camera top-down and saves one PNG. This checkout has no `godot/gen` or built hull files, so the picture run used the PC build's installed assets with this branch's `rules.gd` swapped in for the run and restored afterwards. The two HUD pictures were also taken with the build's assets. Nothing was committed or pushed.
