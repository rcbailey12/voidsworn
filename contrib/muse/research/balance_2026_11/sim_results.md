# Sim results: measured runs behind the balance synthesis

All runs use the shipped full-run simulator (contrib/opus/tools/run_montecarlo.js), veteran AI, baseline bot policy, fresh profile, seeds 1 to 50 per faction unless a run says otherwise. 50 runs per faction, 300 runs per full execution. Every package below was executed twice; the two executions agreed on every faction win rate both times (one Hullbreaker average-battles figure differed by 0.08 in the v3 pair). Win rates are bot rates under one policy, not human rates. Earlier measurement in this repo shows the absolute rate moves a lot by policy while the faction ordering holds.

## Baseline (shipped data.js, main at 09fb8c9)

Executed three times. Faction win totals were identical in all three executions. The second and third executions also agreed on every admiral split; the first execution's fine detail (admiral splits, one sector split) diverged and is not used. Figures below are the agreed execution.

| Faction | Win rate | 95% CI | Deaths S1/S2/S3 | Avg battles |
|---|---|---|---|---|
| Sunward Crusade | 34.0% | 22.4 to 47.8 | 22/8/3 | 8.12 |
| Hegemony Navy | 54.0% | 40.4 to 67.0 | 7/11/5 | 10.72 |
| Ashfall Hullbreakers | 62.0% | 48.2 to 74.1 | 10/7/2 | 10.62 |
| The Chorus | 80.0% | 67.0 to 88.8 | 2/6/2 | 12.50 |
| The Glasswrights | 64.0% | 50.1 to 75.9 | 8/9/1 | 11.12 |
| Eclipse | 72.0% | 58.3 to 82.5 | 9/3/2 | 11.52 |

Overall 61.0%. Spread 46 points. Six battle timeouts across the 300 runs.

Per-admiral win rates (n of 12 or 13 each, smoke, not signal): Crusade: Thale 83.3, Vex 23.1, Draven 23.1, Ashgrove 8.3. Hegemony: Kassar 69.2, Reyes 66.7, Maren 41.7, Vorn 38.5. Hullbreakers: Vesh 83.3, Mott 66.7, Grax 53.8, Sable 46.2. Chorus: Razormaw 92.3, Mending Throng 83.3, Matriarch 76.9, Voice 66.7. Glasswrights: Saro 76.9, Tamsa 69.2, Brin 66.7, Vell 41.7. Eclipse: Nekhet 84.6, Umbra 76.9, Seveth 66.7, Ostrel 58.3.

## Single-lever isolation runs (50 runs, one faction each)

Each row is baseline data.js plus only the named change, run on the faction the lever was meant to move (plus affected bystanders where noted).

| Lever | Faction run | Result | Baseline | Reading |
|---|---|---|---|---|
| Chorus regen trims only (drone 4 to 3, spitter 5 to 4, razor 7 to 6, brood 8 to 6) | Chorus | 84.0% | 80.0% | No measured effect. |
| Chorus prices only (Frigate .65 to .75, Destroyer .75 to .85) | Chorus | 86.0% | 80.0% | No measured effect. |
| Chorus damage only (tendril 13 to 11, bioplasma 12 to 10) | Chorus | 72.0% | 80.0% | Works. Sector 1 deaths rose 2 to 10. |
| Torpedo evMult 2 to 1.7 only | Crusade | 32.0% | 34.0% | No benefit. |
| Torpedo evMult 2 to 1.7 only | Hullbreakers | 60.0% | 62.0% | No clear effect. |
| Torpedo evMult 2 to 1.7 only | Glasswrights | 66.0% | 64.0% | No clear effect. |
| Ion shield multiplier 2.5 to 2.7 only | Hullbreakers | 62.0% | 62.0% | No harm to the bystander faction. |
| Crusade stack without torpedo change (warden hp 50, harrow hp 85, penitent hp 135, rake .45, Carrier price 1.1) | Crusade | 60.0% | 34.0% | The Crusade fix does not need the torpedo change. |

## Package v1 (tested, superseded)

Contents: torpedo evMult 1.7, ion 2.7, warden hp 50, harrow hp 85, penitent hp 135, Chorus regen trims (3/4/6/6), rake .45, Crusade Carrier 1.1, Eclipse prices (1.55/1.6/1.65). Glasswrights untouched.

Result (one execution): Crusade 58.0%, Hegemony 58.0%, Hullbreakers 50.0%, Chorus 86.0%, Glasswrights 68.0%, Eclipse 68.0%. Overall 64.7%. Spread 36 points. The outliers moved instead of closing: Chorus rose despite the regen trims, and Hullbreakers fell 12 points for reasons the isolation runs could not assign to any single lever in the package.

## Package v2 (the recommended package)

Contents are listed in full in synthesis.md. Result, two identical executions:

| Faction | Win rate | 95% CI | Deaths S1/S2/S3 | Baseline |
|---|---|---|---|---|
| Sunward Crusade | 64.0% | 50.1 to 75.9 | 8/8/2 | 34.0% |
| Hegemony Navy | 70.0% | 56.2 to 80.9 | 4/10/1 | 54.0% |
| Ashfall Hullbreakers | 60.0% | 46.2 to 72.4 | 11/5/4 | 62.0% |
| The Chorus | 64.0% | 50.1 to 75.9 | 8/6/4 | 80.0% |
| The Glasswrights | 68.0% | 54.2 to 79.2 | 5/10/1 | 64.0% |
| Eclipse | 72.0% | 58.3 to 82.5 | 9/4/1 | 72.0% |

Overall 66.3%. Spread 12 points (60 to 72).

## Package v3 (tested, not recommended)

Contents: package v2 with ion reverted to 2.5, Eclipse regen deepened (scythe 1, jackal 1, harvester 2), and Glasswright evasion trims (wisp 28 to 25, blade 24 to 21).

Result, two executions agreeing on every win rate: Crusade 62.0%, Hegemony 66.0%, Hullbreakers 60.0%, Chorus 72.0%, Glasswrights 60.0%, Eclipse 66.0%. Overall 64.0%. Spread 12 points (60 to 72). Same spread as v2, worse composition: weakening Glasswrights and Eclipse lifted Chorus runs (they are Chorus's sector 2 and 3 enemies) and put Chorus back on top.
