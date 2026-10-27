# Stream B pass 3: everything built so far, against pass 1

Ryan's PC, lane B, Oct 27. Code: main bcc7e47 rules (B3 faction identity with pass 2 tuning, B4 ship-five, step 3 backlog, B-21, admiral band 5b, arc variants vc2). Before: pass 1 "after" (5294612, B3 step 1 before any tuning, `pass1_report.md`). Samples: fmatrix 64 per cell (pass 1: 96), skirmish matrix 16 per cell (50), campaign 60 per cell (200), archmatrix 1 (2), runsim 80 runs (240), fuzz 2000. Raw: `pass3_raw.txt`.

## fmatrix (row = player-side faction, % wins)
| | voidsworn | hegemony | corsair | chorus | ithar | deathless | avg | pass 1 avg |
|---|---|---|---|---|---|---|---|---|
| voidsworn | 50 | 50 | 56 | 48 | 45 | 45 | 49 | 54 |
| hegemony | 70 | 67 | 72 | 45 | 83 | 48 | 64 | 65 |
| corsair | 53 | 63 | 61 | 53 | 67 | 53 | 58 | 59 |
| chorus | 69 | 70 | 59 | 56 | 80 | 72 | 68 | 70 |
| ithar | 64 | 45 | 73 | 42 | 52 | 50 | 54 | 50 |
| deathless | 69 | 77 | 56 | 39 | 77 | 45 | 60 | 66 |

As the enemy side (100 minus column average): voidsworn 38 (37), hegemony 38 (42), corsair 37 (36), chorus 53 (51), ithar 33 (26), deathless 48 (44). Strength (row average and enemy side, halved): voidsworn 43.5 (45.5), hegemony 51 (53.5), corsair 47.5 (47.5), chorus 60.5 (60.5), ithar 43.5 (38), deathless 54 (55). Rounds 8.47 (8.36), timeouts 11 of 2304.
Faction identity holds: Chorus fights at 1.8 hexes with 94% of incoming damage on hull and 22 hull regrown per ship; Ithar 43% on shields, no armour cut; Deathless 12% armour cut and 10 regrown; Hegemony longest range (3.0).
Read: Chorus still runs ahead and Voidsworn and Ithar trail (B3 exit "no faction runs away" not met). Tuning t2 below.

## Skirmish matrix (16 per cell; player bot edge is large in this mode, mirrors 56 to 100%)
Row averages: voidsworn 63 (64), hegemony 75 (68), corsair 94 (96), chorus 90 (93), ithar 86 (85), deathless 60 (61). Deathless against Corsair 13 (14), against Chorus 6 (20).

## Campaign (60 per cell), win %, then wait per round (real model)
Changes of 5 points or more against pass 1: sector 1 elite 75 to 83; sector 1 boss 83 to 88; sector 2 battle (col 4) 74 to 85; sector 3 battle (col 4) 81 to 90; sector 3 elite 59 to 70. Waits: every cell 8.1 to 13.6 s per round (limit 15, target 12; sector 3 battles 12.8 and 13.6 are above target). No timeouts.

## Run sim (80 full runs, no Nemesis in this harness)
Reach: sector 2 69% (72), sector 3 30% (41), won 12.5% (22). Per node: s2 boss 69 (77), s3 boss 63 of 16 fights (84), s3 battle 87 (86). Flag for Opus: the full-run win rate fell; the loss is spread over the sector 2 boss and sector 3. The pass 2 tuning, B-21 (refit escorts now shoot down wings) and the step 3 backlog all landed in between; this harness has no target, so no change made here.

## Archetypes (sector 2, column 3)
none 79 (84), swarm 78 (85), heavy 90 (90), carrier 83 (83).

## Crash check
fuzz 4 x 500 = 2000 battles: exceptions 0, invariant breaks 0, average 7.1 rounds.

## Nemesis (nemmatrix, separate split run): see `nem_split.txt`.

## Addendum (Oct 27): what drives the sector 3 round time
Campaign sim, `real` timing model (the browser's own animation durations), CATS breakdown, 16 per cell, seconds per round:
| Cell | Total | Player fire | Player move | Enemy fire | Enemy move | Enemy deaths | Banner and gaps |
|---|---|---|---|---|---|---|---|
| Sector 1 battle (col 1) | 10.6 | 2.9 | 3.9 | 1.0 | 1.0 | 1.0 | 0.7 |
| Sector 3 battle (col 1) | 13.8 | 3.8 | 3.2 | 2.0 | 1.7 | 1.4 | 0.8 |
| Sector 3 battle (col 4) | 12.9 | 3.0 | 2.8 | 2.7 | 1.8 | 0.9 | 0.8 |
| Sector 3 elite | 12.5 | 3.2 | 2.8 | 2.3 | 1.8 | 0.9 | 0.8 |
Read: about half of every round is the player's own five ships moving and firing (6 to 7 s, the same in every sector). The sector 3 excess over sector 1 (about 3 s) is the enemy phase with 12 to 14 ships: their fire (+1 to 1.7 s), moves (+0.7 to 0.8 s) and deaths (+0.4 s), even with the existing big-fleet speed-up (`enemyPaceK`, floor `PACE.bigMin` .5). No rule drives it; it is presentation time. The Godot battle scene (G2) owns the real timings now (its cinematic movement, R50), so any fix belongs there: overlap enemy activations or shorten the enemy tail in big fights. The JS `PACE` constants only feed the browser and this sim model. The step 9 easing (smaller sector 3 enemy fleets) shortens these rounds a little; numbers in the step 9 confirmation.
