# Astra audit fixes for November 22

Refs #1747. Run 1 rechecked the ten findings from `origin/codex/issue-1723` against main `a6ec7c3a0`. PR 1759 carries its nine fixes in `f1930b04`.

The game changes are in `godot/scenes/battle/battle.gd`, `godot/fx/fx_death.gd`, `godot/fx/fx_death_beats.gd` and `godot/render/build_assets.gd`. The install readback now computes the ship stamp once. The prompt baseline change is in `.claude/hooks/guard.cjs`.

| Finding | Result | Check and evidence |
| --- | --- | --- |
| 1. Enter after a refused shot | Fixed | `plan_commit_check.gd` arms a gun that bears from the real hex, moves its ghost out of arc, clicks the enemy and presses Enter. Before, the ghost vanished and Enter queued nothing. Now the ghost stays and Enter queues the displayed move. |
| 2. Sheet over the final volley | Fixed | `plan_commit_check.gd` fires on the last enemy and gets both fire and victory in the batch. Before, the sheet blocked clicks while the winning batch waited. Now playback keeps the sheet hidden until the batch ends. The ordinary move-and-fire case still restores it. |
| 3. Acid-killed fighter smoke | Fixed | `death_variety_1586_check.gd` follows a Navy wing from the death call through its delayed effects. Before, it emitted six smoke sprites and a puff. Now the wing gets the melt flag and emits neither. The blast control still smokes. |
| 4. Installed hull stamp | Fixed | `install_refresh_check.gd` moves one vertex while preserving GLB length and modification time. The install stamp changes and the rebuilt scene contains the dent. Hull, damage and wreck GLBs all use the content hash. |
| 5. Wing debris material | Fixed | `death_variety_1586_check.gd` checks the particles emitted by a wing death. Glasswright wings shed two glass shards and Chorus wings shed two wet flecks in their damage colour. The wing calls the existing faction debris helper. |
| 6. Metal wear on glass and flesh | already fixed on main by `54936d6d9` | `hull_wear_check.gd` passes. Wave 1B gates metal weather and scorch patches by material while retaining electrical dimming. |
| 7. Timed ship refresh | Fixed | `install_refresh_check.gd` runs the builder twice with a small time budget. The first run finishes the dented hull. The second resumes at the next ship, builds it and clears the saved cursor. |
| 8. Dirty paths at prompt time | Fixed | `guard.test.cjs` starts with a modified tracked script and an untracked broken script. A docs-only turn skips the loader. Editing either script triggers it, including an edit committed during the turn. PR 1729 (`09f2fb274`) left the prompt baseline at HEAD. |
| 9. Torpedo launch coverage | Fixed | `torpedo_flat_flight_check.gd` checks all six launch cases at each of three targets before sampling height. It requires four rockets per rack launch and one round for each other launch. All 27 rounds passed. |
| 10. Death-frame sampling | Fixed | `death_variety_1586_check.gd` samples sprite counters before calling `fx.death`. The blast wing control includes the initial corkscrew and the acid-wing check covers the same interval. |

Older ship caches rebuild once when the builder first sees the new GLB stamp. Timed runs spread this work across launches.

## Run 1 verification

Godot 4.7.2 loaded 370 scripts and 15 scenes with zero failures. All 177 headless checks selected by the three game shards passed across the initial runs and seven retries. Six retries supplied the expected Windows test profile or repository fixture. The stuck-cut timing check passed separately at 5.05 seconds. The weekly bot battle finished.

All 289 battles matched their saved results. The cache-on and cache-off records were byte-identical for all 289. One 145-battle worker hit its time limit, then passed in smaller groups. All 15 ruled numbers, 30 seeded campaigns and the Nemesis scenarios passed.

The standing suite ran 115 rows on Windows. It reported 104 passes, two known baseline results and nine failures. All nine also failed on an untouched copy of `a6ec7c3a0`. They were `picture_provenance_tests`, `publish_ship_tests`, `pysite_1535_tests`, `relay_push_tests`, `runner_cleanup_tests`, `runner_selftest`, `saved_campaign_update_tests`, `g2_export_selftest` and `stage5_fail_selftest`. The ship publishing check passed on retry with Python available as `python3`.

The death seam check passed on the installed A16. The committed A16 fixture record is stale on the base. Its CI check needs a fresh Blender bake. Lane C is code only, so rendered footage, GPU timing and that bake were outside this run. Hosted All checks awaits the runner's push.

## Run 2 verification

The supplied sparse checkout was at `c9596825d` (`origin/main`). I verified `18b979bb1` in a full scratch checkout and used a full checkout of `c9596825d` for the baseline. The runner needs a full checkout at `18b979bb1` to retain the run 1 fixes and include the standing check inputs. This run updates the report only.

- Godot 4.7.2 loaded 379 scripts and 15 scenes with zero failures. The weekly bot battle passed at seed 361. The hook regression suite passed.
- The three game shards completed 68, 58 and 58 checks, all passing. The Windows rerun used a longer local shard budget to allow for slower checks.
- `plan_commit_check.gd` passed both regression cases. Enter committed the move shown after a refused shot, and the sheet stayed hidden through the winning volley. `death_variety_1586_check.gd` recorded zero smoke sprites and no delayed puff for the acid-killed wing. It also passed the Glasswright shard and Chorus fleck assertions. The torpedo launch and installed hull refresh checks passed.
- `run_parity.js` matched all 354 saved battle results with zero differences. `run_campaign_checks.sh 1 30` matched all 30 seeded runs and the Nemesis scenarios. The Nemesis read check and all 119 map read-only assertions passed.
- `run_cache_check.js` matched all 354 battles byte for byte with the scoring cache on and off. All 15 ruled numbers passed.

The full serial `node contrib/opus/tools/run_all_checks.js` exited 0 with 113 passes, two known baseline results and zero failures. The earlier parallel run had 110 passes, two known results and three failures. `runner_cleanup_tests`, `runner_job_tests` and `runner_selftest` each passed on individual retry. The matching parallel run on untouched main passed 111 rows, reported the same two known results and printed these failure lines.

```text
FAIL: runner_selftest (98.33 s) | FAIL runner687: AssertionError [ERR_ASSERTION]: drive C: has 128 GB free (min_free_gb floor 60)
FAIL: runner_cleanup_tests (180.34 s) | FAIL: exit 1
Error: spawnSync powershell.exe ETIMEDOUT
```

The branch's parallel run printed `AssertionError [ERR_ASSERTION]: Error: spawnSync powershell.exe ETIMEDOUT` for `runner_job_tests` and `Error: spawnSync powershell.exe ETIMEDOUT` for `runner_cleanup_tests`. Its `runner_selftest` printed `FAIL runner687: AssertionError [ERR_ASSERTION]: drive C: has 68.4 GB free (min_free_gb floor 60)` and `runner status: partial (spend accounting unknown)` from the accounting fixture. The runner code and tests are identical on both revisions.

The supplied sparse checkout also failed two standing rows on main. The same sparse patterns reproduced both failures at `18b979bb1`. Both rows passed in full checkouts. These are the lines from sparse main.

```text
Error: fatal: ../godot/rules/sim/README.md: '../godot/rules/sim/README.md' is outside repository at 'C:/Users/rcbai/Downloads/voidsworn_test/board_d/repo'
FAIL fleet list: voidsworn|Frigate: concept file is missing: docs/ship_pipeline/build_sheets/voidsworn_S9/concept_beauty.jpg
FAIL: 31 of 10 fleet list checks failed
```

The A16 fixture check printed `FAIL fixture record is stale or the compressed GLB changed. Rebuild with --bake.` on both revisions. The separate A16 CI job handles a stale record with a fresh bake. This re-verification used headless game checks, with no Blender bake or GPU capture.

## Run 3 fixes

`battle.gd` now keeps the Burn and fire plan intact when a weapon is armed. `plan_commit_check.gd` plans a battery shot that needs a Burn, then presses 1 to arm a torpedo that could fire from the current hex. Before the fix, the hotkey replaced the plan with a stationary shot and cleared the armed weapon. After the fix, the battery's planned shot, stop and target stay intact, the torpedo stays armed, and one Backspace restores the state before planning the battery shot.

The older `armed_preview_test.gd` expected arming flak to clear a Burn and fire plan. Its updated check covers the ghost, path and card, and verifies that Enter still fires the planned main gun. `godot_checks.txt` describes the new expectation.

The timed ship refresh cursor was already restored in `9c5427b48`. To verify the original failure, I forced the scan to start at the first ship in a scratch copy of `build_assets.gd`. `install_refresh_check.gd` then reported `FAIL the second bounded refresh reaches the next ship` and `FAIL the completed ship scan clears its resume point`. The branch's unmodified builder passed both assertions and rebuilt the hull with the changed vertex.

## Run 3 verification

- Godot 4.7.2 parsed the three edited scripts and loaded 379 scripts and 15 scenes with zero failures. The hook regression suite passed. The bot battle passed at seed 361.
- All 184 listed game checks passed across the three shards and a focused rerun of two checks. The shard 2 timing check first reported `a stuck cut holds the battle 5.67 s, no longer than the 5.0 s cap`. It passed on retry at 5.05 s. The updated flak preview check also passed on the shard 2 retry. The local Windows run used precreated temp folders, isolated Godot profiles and a longer shard budget.
- All 354 generated battle records matched the saved records byte for byte. All 30 seeded campaign records and the Nemesis records matched. The table checksum, tree hand-off, Nemesis read and 119 map read-only assertions passed. The branch changes zero saved results compared with `origin/main`.
- Cache-on and cache-off records matched byte for byte for all 354 battles. All 15 ruled numbers passed. The cache harness still flagged the worker logs.
- The Windows engine printed `ERROR: Failed to read the root certificate store.` on this branch and untouched main `de943c787`. I reproduced the saved-results failure on main with `s1` and the cache failure with `s1` and the ruled numbers. The saved-results harness reports `original Godot batch failed or did not finish`, and the cache harness reports `Godot error in worker log`. The campaign harness printed `FAIL: 2 campaign check(s) differ (0 changed)` on both revisions for the same error.
- The A16 fixture record is stale on both revisions. The headless seam check on the committed fixture reported `DEATH_SEAM failures=1` for the stale record. The fresh Blender bake and GPU captures were outside this run.

`node contrib/opus/tools/run_all_checks.js` ran 117 rows. The first run recorded 111 passes, two known baseline results and four failures. `lane_tools_refresh_selftest` passed on retry after its first run printed `Error: kill EPERM`. `g2_export_selftest` passed on retry with Node copied to the run's writable temp folder. Its original run and untouched main both printed `Error: EPERM: operation not permitted, link` while hard-linking the installed `node.exe` to `Voidsworn.exe`.

The two remaining standing failures reproduced on untouched main `de943c787`.

```text
godot_shard_tests
FAIL: the shard plan is broken; no check was run.
mkdir: cannot create directory ?C:\\Users/rcbai?: Permission denied

runner_selftest
Error: EPERM: operation not permitted, mkdtemp 'C:\Users\rcbai\AppData\Local\Temp\runner687 proof XXXXXX'
```

Hosted All checks remains unverified. The run 3 changes are uncommitted.
