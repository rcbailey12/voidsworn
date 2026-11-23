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
