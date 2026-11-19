# Issue 1125: Campaign save and resume

The Godot campaign can replay a boosted fight, finish a paid boss exit, resume salvage, and return to the same shipyard. A ship that jumped clear counts as a survivor. Continue and Career both recover from bad primary files.

| Audit finding | What changed |
| --- | --- |
| 1. Boosted fight | The fight spends the boost in memory. The save keeps the earlier playable checkpoint until the result is settled. An old save at an unfinished fight retries it. The recorded story choice restores its one-fight modifier without paying any other part of that choice again. |
| 2. Breakthrough | The campaign uses the same survivor predicate as the battle rules. The card and Career record say Withdrawal when a lost objective still leaves a surviving ship, including one already through the exit. |
| 3. Continue | The title and campaign loader use the same save selection. A missing, empty or damaged primary can fall back to a valid backup. A sound profile-only primary takes precedence and offers no Continue. |
| 5. Boss exit | The finished reward goes straight to the next sector or run result. A previously stranded save at a paid boss finishes the exit without paying it twice. |
| 7. Captured ship | A prize and its next reward stage are saved together. Older saves with an empty prize list at the prize stage resume with salvage or the next reward. |
| 8. Yard doctrine | Paying for doctrine in the yard fleet keeps its Done route to the same yard. Continue from the purchase save reopens that yard. The map entrance still returns to the map. |
| 9. Career | The writer checks the temporary file before replacing the live profile. Only a readable primary can replace the backup. |

## Finding 4: Standard difficulty, for the Board

If approved, pass Standard into [enemy setup](../../../godot/rules/rules.gd) before the fleet is rolled, and pass the same setting into [map intel](../../../godot/ui/campaign/map_intel.gd). The existing Standard rule multiplies the enemy command-point budget by **0.90**, including the budget for a boss's escorts. The boss hull itself is still guaranteed, with its existing hull and damage scaling. Fleets buy whole ships, so a given seed could roll the same fleet, a cheaper mix, or fewer escorts. The map would estimate that lower threat for its briefing, danger bands, and route planner. Expect Standard runs to be easier on average. No win-rate change was measured, and difficulty was not changed here.

## Browser oracle and checks

The root browser game still has the save bugs in findings 1, 5, and 7, and its backup loader has the empty-primary case in finding 3. These are persistence and resume differences. The battle result, boost effect for a resolved fight, reward amounts, and sector advancement rules use the same rules as before. The browser already counts escaped ships for withdrawal. The root JS files and both exported tables were left alone.

Raw campaign parity first differed on the saved prize stage. Comparing past that field also exposed the boosted checkpoint and two actual reloads that skipped salvage in the browser. The [campaign parity driver](../../../godot/campaign/test/node/golden_campaign.js) now models the Godot save boundaries for boosted fights and paid prizes in the test only. The same browser gameplay functions still supply all actions and outcomes, and the comparison still checks every click, available action, save, and random state. The boss payout split takes place between writes and does not change the snapshots parity compares.

[The headless regression](../../../godot/campaign/test/run_resume_test.gd) failed on main `950e1a2f8435e4da702bcbe9104546a9ac2168ac` for each of the seven findings. It passes against the fixes, including five [unmodified test saves generated on that revision](../../../godot/campaign/test/fixtures/issue_1125/): a boosted boss in progress, paid Sector I and III bosses, a paid capture before salvage, and a Career backup with an earned medal. The test uses isolated files and the game loaders. It also checks a blocked Career writer twice in a row.

Local checks: 76 listed Godot checks passed, the real campaign bot battle passed, and the standing runner exited 0 with its existing known exceptions. Rules parity matched all 284 saved battles. Campaign parity matched all 30 seeded runs and the cross-twin save hand-off.

## Impact sweep

- **Callers:** Traced node entry and Continue, the host's battle hand-off, the battle card, Career recording, prize and boss completion, and both entrances to fleet doctrine.
- **Saves:** Five real old saves load with their modifier, remaining rewards, progress or medal restored. No save format or version change.
- **Twins:** Shared battle and payout rules still agree. Browser save differences are listed above and the Godot recovery has separate headless coverage.
- **UI:** Title reads the loaded run state, the battle card and Career agree on withdrawal, and the existing salvage, sector and shipyard screens read the restored campaign state. Standard map intel is report-only.
- **CI:** [The Godot check list](../../../godot/tools/ci/godot_checks.txt) runs the new GDScript test in the Godot game job. The standing Node checks, rules parity, campaign parity, and Godot rules safety have their existing jobs.
