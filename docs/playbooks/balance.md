# Balance

The headless Godot balance simulator measures single battles, reward carry, faction matchups, and full campaigns.
[Simulator guide](../../godot/rules/sim/README.md)

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

Full-run win rates from 240 seeds per faction and level. The option C projections came from the frozen browser
`tools/late_run_1178/sim_1178.js`. The Godot measurements used main at `bf9b9652d`, which also includes the R430
encounter curve, the build-variety changes, and the rule that a boss fight requires the boss's death for victory.

| Level | Source | Crusade | Hegemony | Hullbreakers | Chorus | Glasswrights | Eclipse |
|---|---|---|---|---|---|---|---|
| Veteran | R414 projection | 31% | 37% | 44% | 36% | 48% | 47% |
| Veteran | Godot | 31.7% | 47.5% | 49.2% | 44.6% | 40.8% | 30.8% |
| Standard | R414 projection | 70% | 64% | 74% | 72% | 70% | 74% |
| Standard | Godot | 63.3% | 74.6% | 77.9% | 72.9% | 70.0% | 66.3% |

The measurement ran the command below for each faction and level with `PAIRSEED` offsets 0, 12, 24 through 228.
Together the batches covered seeds 1 through 240 and completed all 2,880 runs with zero engine errors.

```bat
set "PFACTION=voidsworn"
set "AI=standard"
set "PAIRSEED=0"
set "SIM_ARM=current"
"%GODOT_EXE%" --headless --path godot --script res://rules/sim/balance_sim.gd -- run 12
```

To reproduce the grid in one process, leave `PFACTION` and `AI` unset and run the same 240 seeds per cell.

```bat
set "PFACTION="
set "AI="
set "PAIRSEED=0"
tools\pc\balance_sim.bat run 240 nopause
```

Each cell plays 240 complete campaigns with its own faction's admirals and fleet, including repairs and spending
through the shipyard. Use `campaign` for battle-level checks of `RAMP` and `run` for full-campaign checks of
`RAMP` and shop prices.
