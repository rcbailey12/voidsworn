# Issue 457: campaign sim with real rewards

Workhorse: DeepSeek. Branch `work/issue-457-deepseek`. 2026-11-11.
Report only plus one sim mode. Nothing on screen changes, so there are no screenshots.

## Answer first

`node sim3d.js campaignrewards N` is in and `campaign` is untouched. In 480 battles per mode at N=40 with SEED=457, carrying the rewards a run would plausibly have by each sector and column is worth about +3.7 points of win rate on average, about 1.7 fewer rounds per fight, about 17.5 points more hull left, and about 0.85 fewer ships lost per fight. The biggest moves are the later boss and elite cells: sector 2 boss hull left 43% to 74% and rounds 9.3 to 6.1; sector 3 boss hull left 59% to 91% and rounds 10.0 to 5.3.

Ten of the 12 rewards cells are above 95% win, which the job asks me to flag. That is a real result, not a crash: the campaign cells are already 83% to 100%, the two modes share the campaign reference fleets, and the new mode assumes the run won every earlier stop. It means win rate has hit its ceiling in this setup; rounds, hull left and ships lost are the useful columns from here.

## What changed

- `sim3d.js`: a new mode and its helpers only (`campaignEarlierFights`, `rewardBestOffer`, `rewardTakeBoon`, `rewardApplyNode`, `carryFightReward`, `carryYardSpend`, `carryRunRewards`, `campaignRewardsSim`), plus the `campaignrewards` dispatch line. `campaignSim` and every existing mode are unchanged.
- `contrib/deepseek/reviews/campaign_rewards_sim.md`: this report.

## How the mode carries rewards

It plays exactly the same 12 cells as `campaign` (sectors 1 to 3, battle col 1, battle col 4, elite col 4, boss col 6), with the same reference fleets, the same enemy faction pool, the same objectives and the same alternating-activation battle loop. Before each fight it banks the rewards for the earlier stops.

Reward counts per column, from the map rules rather than a copied table:

- One fight per earlier column, because a run picks one node per column.
- Column 0 is a battle only in sector 1. From sector 2 the run docks at a shipyard first, so it is not a fight.
- Column 4 always offers the elite, so an earlier column 4 fight counts as elite.
- Column 5 is the rest stop before the boss, so it is not a fight.
- Column 6 is the boss and counts only when it is an earlier sector. The targeted cell is played as a normal battle in this mode, exactly as in `campaign`.
- Prior sectors are carried in full (including their boss) because a run at sector 2 or 3 has finished them. That is the cumulative reading of "by sector and column". It also means sector 2 and 3 cells stack prior rewards on top of the already grown campaign reference fleet, so they read as an upper bound.

All reward selection and every effect is the game's own function, called from `data.js`, `core.js` and `battle.js`:

- Fight credits use the documented `rewardFlow` formula `round((25 + 12*s + 3*col) * kindMult * (1 + runFx().credPct))`, plus the salvage relic's 15 credits and 8% repair. `campaign_run.js` is not loaded by the sim harness, so this one arithmetic line is the formula from the game, not a new rule.
- Node payout: `rollNodeReward(kind)`, then `rollBoonOffer(p, minR)` for a boon, `modulePool()` for a refit, or the game's credit and repair values.
- Elite and boss salvage: `randomRelic()` from the same useful pool the reward screen uses.
- Boons are pushed with the same `{id, r}` shape the save uses, inside `changeFleet` so max-hull changes keep the fleet at full hull.
- Yards: fit everything in the hold with `canFitModule` and `changeShip`, then buy Marks with `mkCost` for the strongest hulls first, then buy and fit one or two refits. Hull purchases are not made, so the fleets stay the campaign fleets.

Pick policy, fixed and reproducible: always the first offered protocol of the highest rarity (ties go to the first card in the seeded offer). Every offer, rarity roll, relic and refit comes from the sim RNG after `SEED`, so a run replays exactly.

## Comparison at N = 40

Command: `SEED=457 node sim3d.js campaign 40` and `SEED=457 node sim3d.js campaignrewards 40`. 480 battles per mode, 0 timeouts and 0 crashes in both. Deltas are rewards minus campaign.

| Cell | camp win | rew win | d win | camp rounds | rew rounds | d rounds | camp hull | rew hull | d hull | camp lost | rew lost | d lost |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| s1 battle col1 | 100% | 100% | +0 | 3.1 | 3.2 | +0.1 | 85% | 88% | +3 | 0.2 | 0.1 | -0.1 |
| s1 battle col4 | 98% | 100% | +2 | 4.8 | 4.4 | -0.4 | 64% | 70% | +6 | 0.9 | 0.6 | -0.3 |
| s1 elite col4 | 83% | 98% | +15 | 6.2 | 4.8 | -1.4 | 46% | 61% | +15 | 1.8 | 0.8 | -1.0 |
| s1 boss col6 | 93% | 100% | +7 | 8.1 | 6.5 | -1.6 | 53% | 65% | +12 | 1.3 | 0.8 | -0.5 |
| s2 battle col1 | 100% | 100% | +0 | 4.4 | 3.6 | -0.8 | 75% | 84% | +9 | 1.3 | 0.7 | -0.6 |
| s2 battle col4 | 95% | 95% | +0 | 5.3 | 3.6 | -1.7 | 61% | 81% | +20 | 2.0 | 1.1 | -0.9 |
| s2 elite col4 | 90% | 100% | +10 | 6.2 | 4.2 | -2.0 | 51% | 74% | +23 | 2.3 | 1.4 | -0.9 |
| s2 boss col6 | 95% | 100% | +5 | 9.3 | 6.1 | -3.2 | 43% | 74% | +31 | 2.8 | 1.5 | -1.3 |
| s3 battle col1 | 100% | 100% | +0 | 4.2 | 3.0 | -1.2 | 82% | 94% | +12 | 0.7 | 0.1 | -0.6 |
| s3 battle col4 | 95% | 100% | +5 | 5.2 | 3.4 | -1.8 | 73% | 92% | +19 | 1.4 | 0.3 | -1.1 |
| s3 elite col4 | 93% | 93% | +0 | 5.6 | 3.5 | -2.1 | 63% | 91% | +28 | 1.9 | 0.4 | -1.5 |
| s3 boss col6 | 100% | 100% | +0 | 10.0 | 5.3 | -4.7 | 59% | 91% | +32 | 1.9 | 0.5 | -1.4 |
| Average | 95.2% | 98.8% | +3.7 | 6.03 | 4.30 | -1.73 | 62.9% | 80.4% | +17.5 | 1.54 | 0.69 | -0.85 |

What was carried per cell (per run, from the mode's own carried line):

| Cell | protocols | relics | refits | Mk sum | credits left |
|---|---|---|---|---|---|
| s1 battle col1 | 0.6 | 0.0 | 0.2 | 5.0 | 12 |
| s1 battle col4 | 2.6 | 0.0 | 0.6 | 6.5 | 18 |
| s1 elite col4 | 2.5 | 0.0 | 0.6 | 6.4 | 17 |
| s1 boss col6 | 3.5 | 1.0 | 0.5 | 7.3 | 25 |
| s2 battle col1 | 4.6 | 2.0 | 0.7 | 8.5 | 29 |
| s2 battle col4 | 6.1 | 2.0 | 1.1 | 7.8 | 21 |
| s2 elite col4 | 6.7 | 2.0 | 1.1 | 7.6 | 25 |
| s2 boss col6 | 7.5 | 3.0 | 1.3 | 8.2 | 27 |
| s3 battle col1 | 8.1 | 4.0 | 1.3 | 7.7 | 39 |
| s3 battle col4 | 10.3 | 4.0 | 1.8 | 8.4 | 33 |
| s3 elite col4 | 10.3 | 4.0 | 1.6 | 8.4 | 28 |
| s3 boss col6 | 11.1 | 5.0 | 2.2 | 9.0 | 29 |

Mk sum is the sum of Marks across the campaign ships (four ships in sector 1, five in sectors 2 and 3), so subtract the ship count to read the upgrades: 7.3 at sector 1 boss is 4.0 base plus 3.3 Marks. Credits left are what the yard policy did not spend.

## Protocols carried most often

Ranked by the sum of the per-run carry rates across the 12 cell top-five lists (so an approximate ranking, not an exact count of every pick):

| Protocol | Name | Sum of per-run rates |
|---|---|---|
| `e_chain` | Chain Reaction | 1.2 |
| `e_kindle` | Kindling | 1.1 |
| `e_reload` | Hot Tubes | 1.0 |
| `i_brace` | Iron Discipline | 1.0 |
| `i_plate` | Unbent Plating | 0.9 |
| `e_war` | Incendiary Warheads | 0.9 |
| `a_crit` | Killing Light | 0.9 |
| `h_board` | Boarding Frenzy | 0.8 |
| `e_hunt` | Funeral Pyre | 0.8 |
| `i_line` | Unbroken Line | 0.8 |

Ember and Iron protocols dominate: fire, torpedo damage, armor and hull protection. The brace and post-fire movement protocols sit lower, matching the known bot blind spots below.

## Anything that looks broken

- Ten of the 12 rewards cells are above 95% win (98% to 100%); the other two are 95% (s2 battle col4) and 93% (s3 elite col4). No cell is below 50% in either mode, and there were 0 timeouts and 0 crashes in 480 battles. This is the ceiling effect described above, not a rule break: the campaign cells are already 83% to 100% and the enemy fleet is still generated at the cell's sector and column.
- Sector 2 battle col1 is the noisiest row: campaign 100%, rewards 100%, but rounds fall from 4.4 to 3.6 and hull left rises 75% to 84%. A single cell at 40 runs has a standard error of about 1 to 2 points on win rate and about 0.3 to 0.5 on rounds, so treat the small rows as directional. The large boss and elite deltas are well outside that noise.
- The carried reward load grows to about 11 protocols and 5 relics at sector 3 boss. That is the full cumulative path where every earlier stop is won. A real run that loses a fight, declines an offer or skips an elite carries less, so these are upper bounds.
- The mode keeps the campaign sector, column and fleet sizes, but adding rewards raises `fleetPower`, and the enemy budget and `bossFit` read that. So the two modes do not have byte-identical enemy seed draws; they have the same generation inputs and are compared in aggregate over 40 seeded battles per cell.

## The two known bot blind spots (described, not changed)

Per the job, I did not change the bot. Two small, safe changes would make the unmeasured protocols measurable:

- Shield Wall (`i_wall`) and Iron Discipline (`i_brace`): `botUnit` decides to brace only after the firing loop, so `!u.weapons.some(w => w.fired)` is already false whenever the ship had a shot, and the brace almost never happens. A safe change is to make the brace decision before firing, using the pre-fire state, and, when the fleet has `wallBrace`, prefer to brace a ship that is adjacent to allies and under a real threat. That changes no rule, only the order of the bot's own actions.
- Slip the Net (`r_slip`): `botUnit` already calls `fadeMove` after firing when `canFade(u)` is true, but the movement scoring spends every movement point before firing, so there is nothing left to fade with. A safe change is to add a small score bonus in the `computeReach` state loop for states that keep 2 movement points when `canFade(u)`, so the bot reserves them. Again no rule change.

I did not apply either, as instructed.

## How the change reaches the rest of the game

- Callers: searched the repo for `campaignRewardsSim`, `campaignrewards`, `carryRunRewards`, `carryFightReward`, `rewardTakeBoon` and `campaignEarlierFights`. The only hits are the new block and the dispatch line in `sim3d.js`, plus this report and the task text. No game function, constant or save field was changed, and no other mode calls the new helpers.
- Saves: no save field was added or changed. The new mode only reads and writes the in-memory `RUN` fields the game already uses (`boons`, `relics`, `inventory`, `fleet[].mods`, `fleet[].mk`, `credits`, `patrons`). A profile or run save written before this job loads and behaves unchanged. Checked by the standing save checks below (`save_fuzz`, `softlock_sweep`, `b1_tests`), all PASS.
- Twins: no rule lives in both the JS root files and the Godot port changed, so no tables were re-exported. `oracle_copy_test` PASS, rules parity PASS on all 271 seeded scenarios, campaign parity PASS on all 30 seeded runs plus the cross-twin save hand-off.
- UI: no screen shows anything new. `sim3d.js` is a command-line harness and is not loaded by the game, so the campaign map, intel, panels and HUD are untouched.
- CI: no new test file was added, so `contrib/opus/tools/run_all_checks.js` needs no new entry. GitHub runs the standing checks, the no em dashes check, Godot rules parity and Godot game checks; I ran the same standing pack and parity locally.

## Checks run

- `node contrib/opus/tools/run_all_checks.js`: every row PASS or KNOWN, no FAIL. Key rows:
  - `b1_tests | PASS | PASS: exit 0`
  - `save_fuzz | PASS | PASS: exit 0`
  - `softlock_sweep | PASS | PASS: exit 0`
  - `oracle_copy_test | PASS | PASS: no oracle folders exist and both committed tables equal a fresh export from the root game files`
  - `findings_tests | KNOWN | 7 listed failure(s): KIT-1, KIT-3, ROS-9, MOD-2, EVT-1, NEM-6, UI-5`
  - `oracle_drift_guard | KNOWN | 12 constant difference(s) within the baseline`
  - The KNOWN rows are the same listed failures and twelve baseline drift differences that were present before this job.
- Campaign byte-identical: captured `SEED=457 node sim3d.js campaign 4` before and after the edit and diffed the result lines. Result: `CAMPAIGN_IDENTICAL`. The only lines excluded from the diff are the `[swarm]` `console.debug` lines, whose ids come from `Date.now()` and therefore differ on every run, before and after.
- `SEED=457 node sim3d.js campaignrewards 40`: 480 battles, all 12 cells, 0 timeouts, 0 crashes. Printed the same result lines as campaign plus the carried line.
- `SEED=457 node sim3d.js campaign 40`: 480 battles, all 12 cells, 0 timeouts, 0 crashes, used for the table.
- `cmd.exe //c "tools\\pc\\parity.bat nopause"`:
  - `PASS: the Godot port matches the game's rules exactly.`
  - `PASS: the Godot campaign matches the game on all 30 seeded runs, and the cross-twin save hand-off check passes.`
- Em dash scan on `sim3d.js` and this report: 0.

## What I skipped and why

- Promotions and captain perks: a real run also gains XP and picks perks after fights. I did not carry them because the quick earlier stops have no per-ship damage or kill totals, so any XP number would be invented rather than the game's own. The job names protocols, relics and upgrades; the upgrades here are Mark refits and yard refits bought through the game's own costs.
- Hull purchases and prize ships at yards: skipped so the fleets stay exactly the campaign reference fleets, as the job requires. Credits therefore go to Marks and refits only.
- Events and shipyard node outcomes: skipped; only the fight rewards are carried.
- The fleet bot changes described above: not applied, as instructed.
- No screenshots: nothing the player sees changed.
