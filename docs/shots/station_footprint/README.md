# Station footprint: issue 983

R314: the big station covers 19 hexes, so the rules block all 19 and every rule that measured from the station centre now measures from its edge. This report covers run 3: run 2 landed the 19 hexes but made defend much harder, and this run brings defend back to its old difficulty without touching the footprint.

## What changed

- `battle.js` (`genTerrain`, station map): unchanged from run 2. The station is every hex within distance 2 of its centre (19 hexes). The site check keeps the whole 19-hex footprint on the board and rejects any hole cell within 4 of the centre. The debris band is distance 3 to 4 at the same 42 percent density. `TERRAIN_META.stationR = 2`.
- `battle.js` (edge-feature teaching station): unchanged. It keeps its 3 hexes and sets `TERRAIN_META.stationR = 1`, so the first fight keeps its scale.
- `battle.js` and `godot/rules/rules.gd` (this run): the defend distances moved back to the old 7-hex station's edge distances. The damage band and the guard ring are the hexes touching the station body (`stationRad() + 1`), station guns reach 4 hexes past the edge (`stationRad() + 4`), and wing support reaches 2 hexes past the edge (`stationRad() + 2`). The enemy pull stays at `stationRad() + 2`, one ring outside the damaging perimeter.
- `battle.js` (`ENCOUNTERS.defend`): the player text now reads "Every enemy ship next to the station at the start of a round knocks out 1 integrity." The old text said "within 2 hexes of it", which no longer matched the rule.
- `godot/rules/test/scenarios.json`: run 1's three station scenarios stay (`s983_station_defend`, `s983_station_plain`, `s983_teaching_station_defend`); the defend note now states the edge distances. Run 2's 22 reseeded tree fixture seeds are kept, test data only.
- `godot/rules/data/tables.json` and `godot/campaign/data/campaign_tables.json`: re-exported from the root JS files.
- `docs/shots/station_footprint/capture.gd`: the top-down picture script from run 2, unchanged.

## Every station rule, measured from the edge

The number in the rule is the number of hexes from the station's edge. The old 7-hex station had radius 1, so its old centre distances were edge distances one smaller.

| Rule | Old (7-hex station, radius 1) | Run 2 (19-hex station) | This run (19-hex station) |
|---|---|---|---|
| Defend guard ring (`objZone`) | 1 from the edge | 2 from the edge (4 from the centre) | 1 from the edge (3 from the centre) |
| Defend damage per enemy ship (`objectiveTick`) | 1 from the edge | 2 from the edge (4 from the centre) | 1 from the edge (3 from the centre) |
| Station guns (`stationFire`) | 4 from the edge | 5 from the edge (7 from the centre) | 4 from the edge (6 from the centre) |
| Veteran AI pull to the station (`aiObjScore`) | 1 from the edge | 2 from the edge (4 from the centre) | 2 from the edge (4 from the centre) |
| Wing support near the station (`sqObjNear`) | 2 from the edge | 3 from the edge (5 from the centre) | 2 from the edge (4 from the centre) |
| Debris ring | 1 to 2 beyond the edge | 1 to 2 beyond the edge | 1 to 2 beyond the edge |
| Small station pieces on other maps | separate, smaller model | unchanged | unchanged |

`stationR` is the only new save field, inside `B.map`. No rule field was renamed. The teaching station (radius 1) sets `stationR = 1`, so its damage band is 2 from the centre and its guns reach 5 from the centre, exactly as on main.

## How the defend text reads now

The battle objective popup and the campaign text read: "Hold the station. Keep enemy ships off the friendly station until round 6 ends. Every enemy ship next to the station at the start of a round knocks out 1 integrity. Its batteries fire on enemies that come close."

"Next to the station" means the hexes touching the station body. The legend still calls the drawn ring the "Station perimeter" and says "Every enemy ship this close to the station at the start of a round knocks out 1 integrity", which is now true at the drawn distance.

## Why defend got harder, and what carries the change

Run 2 guessed the guard ring moving out to distance 4 was a cause. The sims say the damage band carries nearly all of it. At 120 battles per mode per side, with the same harness and seeds:

| Change from run 2 | Player win | Station falls | Mean rounds |
|---|---:|---:|---:|
| None (run 2) | 0% | 100% | 3.49 |
| Damage band only: 2 to 1 from the edge | 17% | 83% | 5.20 |
| Enemy pull only: 2 to 1 from the edge | 0% | 100% | 3.41 |

The damage band alone recovers the whole loss. The enemy pull alone changes nothing. The 2-hex band covered rings 3 and 4 around the bigger station (42 cells) instead of the old single ring of 12 cells, so many more attackers were damaging the station and they started a round sooner. The fix is to measure the band from the edge with the old 1-hex distance, which is the smallest possible ring outside the blocking body, and to draw the guard ring on the same hexes.

## Geometry and site check evidence

A scratch harness ran 240 seeded station battles over six shapes (`open`, `shoals`, `colossus`, `dense`, `archipelago`, `corner`), half rout and half defend:

```
station cells {"19":240} battles 240 exceptions 0
holes present: nearest hole to centre 5 cells within 4 of centre (should be 0): 0
```

Every battle had all 19 cells, every cell was within 2 of the recorded centre, and no hole cell was inside the 4-hex clearance. The fallback site path still uses the old ring filter, but no battle in this sample needed it. Run 3 does not touch `genTerrain`, so this evidence still applies.

## Board check (no edit)

`godot/render/board.gd` builds one structure per contiguous station cluster. A 19-hex disc is one cluster of 19 cells, which is above `STATION_BIG_HEXES` (5), so it picks `STATION_BIG_LEN` (46). `hex_world` is affine in q and r and the 19-hex offsets sum to zero, so the cluster centroid equals the centre hex; the station is centred on its footprint. The top-down capture shows one big station over the cluster, not several small ones.

## Callers, saves, twins, UI, CI

| Item | Finding |
|---|---|
| Callers | `stationR` is read only by `stationRad()` in `battle.js` and `rules.gd`. It is set in the station map and the edge-feature station. The five readers are the only rule paths that measured from the centre. |
| Saves | A run save stores the fight's seed, not the battle board. On a mid-battle reload `battleScreen` reseeds from the node seed and `startBattle` regenerates the terrain, so `stationR` is set fresh. Older saves get their missing node seeds on load (`nodeSeeds`). The save and campaign start checks pass. |
| Twins | `battle.js` and `godot/rules/rules.gd` changed together. Both tables were re-exported; rules and campaign parity pass; `oracle_copy_test` passes on both committed tables. |
| UI | `objZone` draws the guard ring in the view and the battle popup reads the exported `ENCOUNTERS` text, so both follow the new edge. The objective bar reads integrity, not a distance. No other screen reads the station distance. |
| CI | GitHub runs the standard four jobs: standing checks (`run_all_checks.js`), Godot rules and campaign parity, the Godot-only safety net, and the Godot game checks. No new test file was added, so nothing needs registering in `run_all_checks.js`. The three new scenarios are picked up by parity and the saved-results gate automatically. |

## Balance report (deltas only)

Harness: a `stationsim` built from `sim3d.js`'s own battle loop. Six player factions take turns against six enemy factions, fixed skirmish lists, 20 battles per pairing, 120 battles per mode per side. Seeds are paired (`983000 + i`) and both sides use the same seeds and fleet lists. Before is `origin/main` `battle.js`; run 2 is the branch as it stood at PR 1001; this run is this branch.

One harness fix was needed for a fair comparison: the run 2 harness built the fleets before `startBattle` reseeded, so the player fleet came from the process load-time random state and the same build did not repeat. The harness now calls `rndSeed(seed)` before the fleets are built, so before, run 2 and this run replay exactly and pair. The `before` and `run 2` columns below are re-run with that fix, which is why they differ slightly from the run 2 report.

"First guard ring" is the first round an enemy non-squad ship is within 1 hex of the station edge (2 of the centre on main, 3 of the centre here) so it compares the same ring.

| Mode | Metric | Before (main) | Run 2 | This run | Delta vs main | Delta vs run 2 |
|---|---|---:|---:|---:|---:|---:|
| Defend | Player win | 8% | 0% | 16% | +8 points | +16 points |
| Defend | Station falls (integrity 0) | 93% | 100% | 84% | -9 points | -16 points |
| Defend | Mean rounds | 4.76 | 3.49 | 5.21 | +0.45 | +1.72 |
| Defend | First guard ring round | 2.29 | 1.68 | 2.27 | -0.02 | +0.59 |
| Defend | Hull left | 56% | 76% | 53% | -3 points | -23 points |
| Defend | Withdraw | 111 | 120 | 101 | -10 | -19 |
| Plain station, rout | Player win | 56% | 54% | 54% | -2 points | 0 |
| Plain station, rout | Mean rounds | 7.67 | 7.73 | 7.73 | +0.06 | 0 |
| Plain station, rout | Hull left | 20% | 20% | 20% | 0 | 0 |
| Plain station, rout | First hit round | 1.08 | 1.09 | 1.09 | +0.01 | 0 |

Defend is back to main's win and station-fall rates and its first guard ring round (2.27 against main's 2.29, run 2's 1.68). Battles run 0.45 of a round longer than main instead of 1.27 shorter. Plain station rout does not move at all from run 2, as expected: this run changes defend rules only.

Robustness in the same runs: 0 ships stood on a blocking hex and 0 exceptions in all 720 station battles (before, run 2 and this run, defend and rout). Run 2's broader fuzz runs still apply because this run changes defend distances only and does not add a code path.

## Saved Godot results

The saved-results gate (PR 997) is now required. On the first complete parity run after the change it flagged 127 of 284 battles, the same count as run 2's PR 1001:

- 22 are the reseeded tree fixtures from run 2. Only their input seed changed, so the saved input hash changed. They are test data, not a rules change.
- 105 are battles whose own terrain map is station. Their terrain footprint (R314) and, where the objective is defend, the defend edge rules changed. This includes `threat_s4`, whose saved threat map follows the station board.
- 3 more are the new `s983_*` scenarios, which had no saved entry.

I checked the reason for every one: read the first record of each changed battle and looked at `b.map.map` and `b.obj.type`. Every changed battle outside the 22 reseeds has a station map; no battle on any other map changed. Station-only code draws no random numbers on other maps. The 22 fixtures use `map: open`, which rolls one of the five terrain maps; any that rolls station sees the station branch draw a different number of values, so run 2 reseeded them and the goldens still fire (`tree_effects_test`: 222 fixtures pass).

I accepted the differences with the documented updater and reran the check:

```
node godot/rules/test/saved/update.js --from C:\Users\rcbai\AppData\Local\Temp\voidsworn-parity-3z2E7Y
node godot/rules/test/saved/check.js --from C:\Users\rcbai\AppData\Local\Temp\voidsworn-parity-3z2E7Y
PASS: saved Godot results; 284 battles checked, 0 changed, 0 other files changed, 0 failures; 25.549 s
```

`godot/rules/test/saved/results.json`, the changed archives and `godot/rules/test/saved/changes.txt` are in this branch. `changes.txt` lists every accepted battle with its first changed field. No hash was replaced by hand.

## Checks run

Standing checks, `node contrib/opus/tools/run_all_checks.js`: 63 PASS, 2 KNOWN, 1 FAIL.

```
PASS: tree_effects_test (222 tree fixtures fired their pick; 0 waiting rows are inert)
PASS: tree_last_rows_test (issue 529, the last seven tree rows and the you-may prompts move their numbers)
PASS: oracle_copy_test (no oracle folders exist and both committed tables equal a fresh export)
KNOWN: findings_tests (7 listed failures: KIT-1, KIT-3, ROS-9, MOD-2, EVT-1, NEM-6, UI-5)
KNOWN: oracle_drift_guard (12 constant differences within the baseline)
FAIL: runner_selftest (timed out after 600 s)
```

The only failure is the runner self-test hitting its own 600 s limit on this PC; its first 15 lines are passes and it does not load the game rules. It is not caused by this change. The memory lint, doc check, save checks, tree checks and naming lint all pass.

Rules parity and campaign parity, `tools\pc\parity.bat nopause`:

```
battle s983_station_defend: PASS (135 records identical, result: end loss)
battle s983_station_plain: PASS (113 records identical, result: end win)
battle s983_teaching_station_defend: PASS (124 records identical, result: end win)
all 284 seeded battles: PASS
PASS: the Godot port matches the game's rules exactly.
PASS: the Godot campaign matches the game on all 30 seeded runs, and the cross-twin save hand-off check passes.
```

Rules safety net, `tools\pc\rules_safety.bat nopause`:

```
Cache check: 284 battles, 0 failures
ruled numbers: 15 checks, 0 failures
PASS: Rules safety net (Godot only), 701.106 s
```

## Pictures

All pictures are current for this branch. The drawn guard ring sits one hex out from the station body: three hexes out from the station centre, because the body is the 19-hex disc within two hexes of its centre. Every hex at that distance touches the body, and the ring is the 18 hexes at distance 3.

| Picture | What to inspect |
|---|---|
| `station_board_start.png` | Battle start on the station map, defend objective, seed 983, round 1 (4 player ships against 5 Hegemony ships), in the default isometric battle view. The big station and its guard ring are on the right. The guard ring is the outlined ring of hexes one hex out from the body (three from the station centre). Run 2 drew that ring one ring further out, so this picture replaces that one. |
| `station_guard_ring_topdown.png` | Top-down over the station with the HUD off. The painted station covers the 19-hex body (the centre hex, the 6 hexes at distance 1 and the 12 at distance 2). The drawn guard ring is the ring of 18 hexes at distance 3, the hexes that touch the body. A script check against the board data found 18 guard hexes, all at distance 3, and every one touches a station hex. |
| `station_topdown.png` | Top-down from run 2, kept for the 19-hex footprint. The station body spans the 19-hex cluster and every hex under it is blocked. Its guard ring is the run 2 ring at distance 4; `station_guard_ring_topdown.png` shows the current ring. |
| `station_block_tooltip.png` | A target tip that names the blocking hexes: "Blocked by the station at 4,11, the station at 5,11 ... the station at 8,11." Direct in-game proof that the station blocks line of fire across its footprint. Unchanged by this run. |

Capture method: this checkout has the PC build's installed `gen` and ship assets, so the capture ran here. This run started the battle from `s983_station_defend` with seed 983 and used a temporary SceneTree script, modeled on `docs/shots/station_footprint/capture.gd`. It saved the default battle view for `station_board_start.png`, then hid the HUD, focused the station centre, switched the camera top-down and saved `station_guard_ring_topdown.png`. Both pictures are 1338x720 and carry a provenance strip made with `tools/picture_provenance.py`. This run changed no rules.
