# Astra audit fixes for November 22

Refs #1747. Rechecked the ten findings from `origin/codex/issue-1723` against main `a6ec7c3a0`. The nine fixes below are uncommitted changes on that base. The runner assigns their commit after handoff.

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

## Verification

Godot 4.7.2 loaded 370 scripts and 15 scenes with zero failures. All 177 headless checks selected by the three game shards passed across the initial runs and seven retries. Six retries supplied the expected Windows test profile or repository fixture. The stuck-cut timing check passed separately at 5.05 seconds. The weekly bot battle finished.

All 289 battles matched their saved results. The cache-on and cache-off records were byte-identical for all 289. One 145-battle worker hit its time limit, then passed in smaller groups. All 15 ruled numbers, 30 seeded campaigns and the Nemesis scenarios passed.

The standing suite ran 115 rows on Windows. It reported 104 passes, two known baseline results and nine failures. All nine also failed on an untouched copy of `a6ec7c3a0`. They were `picture_provenance_tests`, `publish_ship_tests`, `pysite_1535_tests`, `relay_push_tests`, `runner_cleanup_tests`, `runner_selftest`, `saved_campaign_update_tests`, `g2_export_selftest` and `stage5_fail_selftest`. The ship publishing check passed on retry with Python available as `python3`.

The death seam check passed on the installed A16. The committed A16 fixture record is stale on the base. Its CI check needs a fresh Blender bake. Lane C is code only, so rendered footage, GPU timing and that bake were outside this run. Hosted All checks awaits the runner's push.
