# AAA UI step 0

This change supplies data for SY-A, ST-A, CM-A and AR-A. It does not build those screens or change combat math, rewards, or captain perks.

- **CaptainData.** Ships keep the record in `ship.cap`. Existing ship, reserve, fallen-roll and saved victory names and XP migrate on load. Hulls that return from a Nemesis hold also migrate. Callsigns use a faction pool keyed by captain identity without consuming a rules random draw. Portraits use one indexed face per subject from the same faction, including unframed Nemesis faces. Once that faction's pool is exhausted, an unassigned portrait stays blank so a screen can use its silhouette. Trait text comes from the existing perk descriptions.
- **CombatEvent and LostShipRecord.** `BattleAPI.combat_report()` returns the hit sequence, totals by battle ship ID, and lost fleet ships as copies. Totals count actual shield and hull spent. Existing shot effects, section damage, and XP rules are separate. The campaign adds XP actually earned at settlement. Each fleet killmail is written to `RUN.timeline` at death and holds its own captain, killer, weapon, and up to two assists. A successful Eclipse reassembly removes the fleet loss but keeps the combat history. `RUN.last_battle_report` keeps the finished report for victory, defeat, and retreat.
- **PreviewOp.** `Campaign.preview_op(action, key, slot)` returns rows for `repair`, `repairAll`, `upgradeMk`, `refit` from the hold, `buyHull`, and `buyMod`. Use the ship UID for repair, Mark and fitting, the template ID for new hulls, and the stock or hold index for refits. Each row includes the cost, currency, and a disabled reason when needed. A click rebuilds and applies the same plan from current state. The prospective hull includes an available reserve captain's perks without taking that captain.

## Saved results

All 379 rule battles now store the new CombatEvent, ship rollup and damage-status data in their snapshots. Comparing the rest of the state matched all 39,524 records, including the RNG, actions and outcomes.

All 30 seeded campaign runs first differ when CaptainData enters the run. The campaign fixtures now record captain identities in ships, reserves, rewards and fallen rolls, and an empty loss timeline in stub battles. The Nemesis fixture first differs when it records the captain of a held ship. A comparison that removed only the new fields and restored the old captain layout matched all 4,789 campaign steps and 223 Nemesis records, including actions and RNG.

## Check

`godot --headless --path godot --script res://campaign/test/aaa_ui_data_test.gd` covers old saves, portrait reuse and exhaustion, the four preview-to-commit paths, hit accounting, final-blow and hazard killmail, assists, data ownership, and actual XP at settlement.

The Godot rules and campaign checks matched the resealed results. All 379 battles also matched with the rules cache on and off. The scene load check and a real headless bot battle passed.

After retries, 217 of 220 headless game checks passed locally. `formation_check` lacked measurements for SF3 and SB4, `showcase_quiet_check` had no kit hulls, and `prefetch_wait_check` did not reproduce clip reads in flight. The standing Windows suite recorded 114 passes, 2 known results, and 8 runner failures. No visuals or GPU captures were changed or run.
