# Balance reference (B0 baseline)

Opus, Oct 25 2026. Game code as at main d5d0227 (unchanged since Oct 22; the only harness change is the B-14 guard in sim3d.js). Every later balance change (B2, B3, B4) is compared against these numbers.

Raw logs: `raw/`. CSVs in this folder. Rebuild the CSVs with `python3 contrib/opus/tools/mega_report.py`.

## How it ran

| Leg | Command | Time | Result |
|---|---|---|---|
| fmatrix | `node sim3d.js fmatrix 48` | 12 min | exit 0 |
| bossmatrix | `node sim3d.js bossmatrix 32` | 22 min | exit 0 |
| archmatrix | `node sim3d.js archmatrix 2` | 13 min | exit 0 |
| campaign | `node sim3d.js campaign 200` | 24 min | exit 0 |
| matrix | `node sim3d.js matrix 50 sk` | 45 min | exit 0 |
| fuzz | `node sim3d.js fuzz 2000` | 29 min | exit 0 |
| bossmatrix_s2 | `BS=2 node sim3d.js bossmatrix 32` | 20 min | exit 0 |
| bossmatrix_s3 | `BS=3 node sim3d.js bossmatrix 32` | 20 min | exit 0 |

Cloud sandbox, two legs at a time on 2 CPUs. Check pack (contrib/opus/tools/checkpack): 0 FAIL, 15 CHECK.

## 1. Crash test (fuzz 2000)

fuzz 2000 battles: exceptions 0, invariant breaks 0 (0 distinct), avg rounds 6.9

Random faction pairs, skirmish and fleet modes. No exceptions and no broken rules in 2,000 battles.

## 2. Campaign nodes (campaign 200 per cell)

Reference fleets from campaignSim, 200 battles per cell. Two 'battle' rows per sector are the two battle columns the harness runs. Waits: 'new' is today's animation timing model, 'old' the pre-v53 one.

| Sector | Node | Win | Rounds | Hull left | Ships lost | Timeouts | Wait (new) |
|---|---|---|---|---|---|---|---|
| 1 | battle | 100% | 4.0 | 74% | 0.5 | 0 | 40 s |
| 1 | battle | 99% | 4.6 | 66% | 0.8 | 0 | 46 s |
| 1 | elite | 84% | 6.4 | 40% | 1.9 | 0 | 63 s |
| 1 | boss | 82% | 9.5 | 38% | 1.9 | 0 | 72 s |
| 2 | battle | 94% | 6.9 | 55% | 2.1 | 0 | 81 s |
| 2 | battle | 89% | 7.0 | 51% | 2.5 | 0 | 81 s |
| 2 | elite | 52% | 8.2 | 23% | 3.8 | 0 | 96 s |
| 2 | boss | 79% | 10.1 | 36% | 3.1 | 1 | 92 s |
| 3 | battle | 95% | 6.4 | 62% | 2.2 | 0 | 101 s |
| 3 | battle | 85% | 7.1 | 51% | 2.7 | 0 | 116 s |
| 3 | elite | 64% | 8.7 | 36% | 3.4 | 0 | 130 s |
| 3 | boss | 98% | 10.0 | 61% | 2.3 | 2 | 114 s |

Reading: wins fall from 84% (sector 1 elite) to 52% (sector 2 elite) and 64% (sector 3 elite); elites are the hard nodes, not bosses (sector 3 boss 98%). Waits run 40 to 130 s per battle and grow with sector. 3 timeouts in 2,400 battles.

## 3. Faction against faction (fmatrix 48, 8 command points a side)

Rows: the player-side faction. Columns: the enemy. Both sides are bots. Percent is the row side winning.

| | voidsworn | hegemony | corsair | chorus | ithar | deathless | avg |
|---|---|---|---|---|---|---|---|
| voidsworn | 54 | 65 | 65 | 56 | 46 | 54 | 57 |
| hegemony | 65 | 79 | 60 | 56 | 73 | 73 | 68 |
| corsair | 50 | 73 | 65 | 81 | 73 | 69 | 68 |
| chorus | 65 | 90 | 58 | 58 | 77 | 60 | 68 |
| ithar | 77 | 46 | 75 | 48 | 77 | 50 | 62 |
| deathless | 69 | 85 | 46 | 54 | 77 | 48 | 63 |

Mirror cells run 48 to 79%, so the player side has a built-in edge of a few points. Spread between factions is moderate (averages 57 to 68).

## 4. Skirmish matrix (matrix 50, skirmish fleets)

| | voidsworn | hegemony | corsair | chorus | ithar | deathless | avg |
|---|---|---|---|---|---|---|---|
| voidsworn | 94 | 90 | 64 | 48 | 36 | 80 | 69 |
| hegemony | 86 | 84 | 40 | 32 | 46 | 68 | 59 |
| corsair | 100 | 100 | 100 | 94 | 92 | 100 | 98 |
| chorus | 100 | 100 | 64 | 96 | 96 | 100 | 93 |
| ithar | 100 | 100 | 92 | 74 | 78 | 96 | 90 |
| deathless | 96 | 98 | 14 | 36 | 38 | 92 | 62 |

Mirror cells run 78 to 100%, so the player bot is far stronger than the enemy AI in this mode; read the rows against each other, not as absolute balance. Corsair (98 avg), Chorus (93) and Ithar (90) far outrun Voidsworn (69), Deathless (62) and Hegemony (59). Deathless against Corsair is 14%.

## 5. Boss matrix (bossmatrix 32, starting fleets only)

Each admiral's **starting fleet only** (no added ships, no upgrades, no boons) against every other faction's boss at that sector. Sector 1 measures the opening; sectors 2 and 3 measure how much a run must grow, not whether bosses are fair.

| Sector | Overall | vs Hegemony | vs Corsair | vs Chorus | vs Ithar | vs Deathless | vs Voidsworn |
|---|---|---|---|---|---|---|---|
| 1 | 71% | 47% | 81% | 66% | 71% | 77% | 81% |
| 2 | 24% | 16% | 15% | 9% | 43% | 28% | 30% |
| 3 | 3% | 0% | 0% | 0% | 8% | 2% | 6% |

Sector 1 by admiral: weakest grax 36%, vex 54%; strongest voice 94%, vesh 94%. Full list: bossmatrix_admirals.csv. The Hegemony boss is the hardest opener (47%).

## 6. Enemy archetypes (archmatrix, sector 2)

| Enemy archetype | Win | Rounds | Player ships left |
|---|---|---|---|
| none | 90% | 6.3 | 4.2 |
| swarm | 86% | 5.5 | 6.0 |
| heavy | 88% | 6.6 | 3.4 |
| carrier | 90% | 6.7 | 3.5 |

All four archetypes land within 4 points of each other. Swarm fights are shortest.

## 7. Hulls (from fmatrix)

Damage dealt per fielding, divided by command points. Top 5 and bottom 5:

| Hull | CP | Damage per fielding | Per CP | Death rate |
|---|---|---|---|---|
| cathedral | 5 | 293.6 | 59 | 47% |
| h_dominion | 6 | 301.8 | 50 | 66% |
| d_harvester | 4 | 197.4 | 49 | 56% |
| penitent | 3 | 146.3 | 49 | 61% |
| h_vanguard | 4 | 192.8 | 48 | 52% |
| c_raider | 1 | 38.6 | 39 | 62% |
| b_spitter | 2 | 76.4 | 38 | 60% |
| reliquary | 4 | 150.9 | 38 | 78% |
| d_scythe | 1 | 36.1 | 36 | 76% |
| h_interdictor | 2 | 71.6 | 36 | 65% |

## What this baseline says (inputs to B2 and B3)

1. The game is stable: 0 crashes across about 19,500 sim battles (fuzz also checks the rules: 0 breaks in 2,000).
2. Elites, not bosses, are the difficulty wall in sectors 2 and 3 (52% and 64%).
3. Waits already reach about 130 s per battle in sector 3 at today's sizes, before battles grow (supports speed first in B2).
4. Faction spread is wide in skirmish (Corsair, Chorus, Ithar on top; Hegemony and Deathless at the bottom) and moderate in fmatrix. B3 faction work starts from here.
5. A starting fleet cannot beat a sector 2 or 3 boss (about 22% and 3%). Growth over a run carries the whole difficulty curve, which the B2 ramp has to respect.
