# Balance

Run [the headless Godot balance simulator](../../godot/rules/sim/README.md) for campaign, campaign with rewards, and faction matrix measurements.

Use `campaign` or `campaignrewards` to measure a player ability. Set `PFACTION` to the faction id you want to field,
such as `deathless` for Eclipse or `chorus` for the Chorus. Leave it unset for a row per faction in each cell.
Set `ONLY_BOSS=1` for the boss cells and the elite comparison.

Use matching `PAIRSEED`, difficulty, mode, cell filters, and battles per cell for both arms. Give each arm a distinct
`SIM_ARM` label and save its output through the `TRIALS_COMPLETE` line. Run
`node godot/rules/sim/compare_trials.js <control-log> <treatment-log>` to check both trial counts and matching keys
before printing paired deltas. Report the ability id, the seeds where it fired, and the counts from those `TRIAL`
rows with the result. Use firing evidence from the arm that received the ability change.

## Faction balance after the torpedo change (R414, Ryan Nov 22 2026, option C)

The issue 1379 torpedo merge (Nov 20) raised Veteran full-run win rates by 13 to 15 points for four of the six factions.
No sim measured it at the time, because the Monte Carlo bot was broken from that merge until PR 1638. Ryan picked option C
from `/mnt/project-files/sim_recheck_1632/rebalance_options.md` (tables on issues 1298, 1354 and 1484). Option C sets two
levers, both in the two Godot table files (`godot/rules/data/tables.json`, `godot/campaign/data/campaign_tables.json`):

- **Difficulty, every faction at once.** `RAMP.vet` 1.1 to 1.15 and `RAMP.std` 0.9 to 0.95 (enemy fleet budget per AI level).
  Each 0.1 moved every faction's full-run win rate by about 11 points.
- **One faction, player only.** `SHOP_DISCOUNT` per faction: Hegemony 0.7, Crusade 1.1, Hullbreakers 1.15, Chorus 0.75,
  Glasswrights 1.2, Eclipse 1.4. These multiply what the shipyard charges (`h.cost`). `h.val` keeps the ladder price, so
  ransom, strip, scrap, captured-hull prices and every enemy ship are unchanged. The tables hold the baked `cost` and `val`
  per hull, so a change to this table also rewrites those hull fields in both files and reseals them.

Projected full-run win rates for option C (240 seeds per cell; frozen browser full-run sim `tools/late_run_1178/sim_1178.js`
on the rules as they were at retirement, not the Godot sim):

| Level | Crusade | Hegemony | Hullbreakers | Chorus | Glasswrights | Eclipse |
|---|---|---|---|---|---|---|
| Veteran | 31 | 37 | 44 | 36 | 48 | 47 |
| Standard | 70 | 64 | 74 | 72 | 70 | 74 |

The Godot balance sim plays single battles with a fixed fleet, so it cannot measure shop prices or a run's win rate. Use
it only as a battle-level check of `RAMP` changes. Reach for these two levers first, and keep the Veteran spread near
these numbers, until a full-run Godot sim exists (issue 1705). Then re-measure this table on it.
