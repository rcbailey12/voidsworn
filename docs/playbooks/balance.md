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

## Full-run faction balance

Ryan's Nov 24 pick (issue 1992) gives all six factions the same full-run win-rate target at each difficulty.
On 240 seeds per faction, aim for every faction within 3 percentage points of its difficulty's six-faction mean.
Keep the means within 3 points of the reference means of 40.8% on Veteran and 70.8% on Standard.

The issue 1379 torpedo merge (Nov 20) raised Veteran full-run win rates by 13 to 15 points for four of the six factions.
No sim measured it at the time, because the Monte Carlo bot was broken from that merge until PR 1638. Ryan picked option C
from `/mnt/project-files/sim_recheck_1632/rebalance_options.md` (tables on issues 1298, 1354 and 1484). Option C sets two
levers, both in the two Godot table files (`godot/rules/data/tables.json`, `godot/campaign/data/campaign_tables.json`):

- **Difficulty, every faction at once.** `RAMP.vet` 1.1 to 1.15 and `RAMP.std` 0.9 to 0.95 (enemy fleet budget per AI level).
  Each 0.1 moved every faction's full-run win rate by about 11 points.
- **One faction, player only.** R414 set `SHOP_DISCOUNT` to Hegemony 0.7, Crusade 1.1, Hullbreakers 1.15, Chorus 0.75,
  Glasswrights 1.2, Eclipse 1.4. The shipyard's baked `h.cost` is `h.val` times this multiplier, rounded to the nearest 5.
  Captured hulls sold at the Crusade's shipyard also use its multiplier (issue 1384). Ransom, strip and scrap use the ladder
  value. Enemy fleets use combat stats. Recalculate each affected hull's `cost` in both tables and reseal them.

The reference means came from 240 seeds per faction and difficulty on `bf9b9652d`. Both measurements below use Godot
4.7.2 `run` mode, seeds 1 through 240 per cell, on `256071fee` with the Chorus refit fix from issue 1992. The baseline
uses R414 prices. The tuned rows use the selected price for each faction, with 2,880 pairs of baseline and tuned campaigns.
The combined tables reproduced all 24 campaigns on seeds 1 and 2 across both difficulties and all six factions.

| Level | Price set | Crusade | Hegemony | Hullbreakers | Chorus | Glasswrights | Eclipse | Mean |
|---|---|---|---|---|---|---|---|---|
| Veteran | Baseline | 31.7% | 47.1% | 49.2% | 45.4% | 40.8% | 29.2% | 40.6% |
| Veteran | Tuned | 43.8% | 40.0% | 41.7% | 45.0% | 40.8% | 40.8% | 42.0% |
| Standard | Baseline | 62.9% | 73.3% | 77.9% | 73.8% | 69.6% | 66.3% | 70.6% |
| Standard | Tuned | 71.7% | 71.7% | 69.6% | 72.5% | 69.6% | 74.6% | 71.6% |

The widest faction gap from its own difficulty mean is 2.99 percentage points on each level, calculated from the win
counts. The tuned shipyard multipliers are 0.70 for Crusade, 0.84 for Hegemony, 1.48 for Hullbreakers, 0.98 for Chorus,
1.20 for Glasswrights, and 1.10 for Eclipse.

To split a 240-seed measurement into batches, run the command below for each faction and difficulty with `PAIRSEED`
offsets 0, 20, 40 through 220. Together the batches cover seeds 1 through 240 and 2,880 full campaigns.

```bat
set "PFACTION=voidsworn"
set "AI=standard"
set "PAIRSEED=0"
set "SIM_ARM=current"
tools\pc\balance_sim.bat run 20 nopause
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
