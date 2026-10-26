# Stream B pass 1: B3 step 1 against the B-19 baseline

Ryan's PC, Oct 26. Before = main at beae728 (B-18 and B-19 fixed, no B3 rules), folder base1 (runsim from base2). After = 5294612 (B3 data pass, faction rules and travelling torpedoes, before tuning), folder s1a (runsim from s1b). Samples: fmatrix 96 per cell, bossmatrix 96 per admiral per boss (480 per admiral), campaign 200 per cell, matrix 50 per cell, archmatrix 2, runsim 240 runs, fuzz 2000. Raw outputs without the swarm debug lines are the base1_*.txt and s1a_*.txt files here. The tuning in c7b1a78 answers this pass; pass 2 measures HEAD.


## fmatrix (row = player-side faction, % wins; avg; delta of avg vs before)
| | voidsworn | hegemony | corsair | chorus | ithar | deathless | avg | before avg |
|---|---|---|---|---|---|---|---|---|
| voidsworn | 58 | 43 | 65 | 52 | 64 | 44 | 54 | 57 |
| hegemony | 68 | 64 | 70 | 46 | 82 | 59 | 65 | 62 |
| corsair | 55 | 57 | 57 | 53 | 66 | 66 | 59 | 69 |
| chorus | 70 | 67 | 68 | 60 | 83 | 72 | 70 | 70 |
| ithar | 56 | 42 | 60 | 38 | 67 | 39 | 50 | 62 |
| deathless | 71 | 76 | 61 | 45 | 84 | 58 | 66 | 71 |

As the enemy side (100 minus column average): voidsworn 37 (was 38), hegemony 42 (was 32), corsair 36 (was 33), chorus 51 (was 41), ithar 26 (was 28), deathless 44 (was 36)
rounds per battle 8.36 (was 8.20), timeouts 16

## faction identity (FID): range = average firing distance; shield/cut/hull = share of incoming damage; regen per ship; loss rate; damage dealt per ship
| faction | range | shieldPct | cutPct | hullPct | regenPerShip | lossPct | dealtPerShip | charge | feed | revive | syncShots | torpDodge | torpGone | torpHit | torpLaunch |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| voidsworn | 2.75 (2.71) | 35 (34) | 5 (6) | 60 | 0 | 69 | 102 (106) |  |  |  |  | 0.6 | 0.2 | 0.9 | 2.7 |
| hegemony | 2.9 (2.93) | 35 | 6 | 59 | 0 | 63 (69) | 106 (98) |  |  |  | 8.2 |  |  |  |  |
| corsair | 2.41 (2.45) | 26 | 4 (5) | 69 (70) | 2 (1) | 64 (62) | 81 |  |  |  |  | 1.3 | 0.4 | 2.4 | 5.1 |
| chorus | 1.84 (1.85) | 0 | 6 | 94 | 21 | 59 (63) | 84 (79) |  | 49.6 |  |  |  |  |  |  |
| ithar | 2.76 (2.75) | 42 | 0 | 60 | 0 | 71 (65) | 86 (91) | 8 |  |  |  | 0.6 | 0.4 | 1 | 2.7 |
| deathless | 2.75 (2.73) | 0 | 12 | 88 | 11 (10) | 60 (62) | 101 (96) |  |  | 1 |  |  |  |  |  |

## campaign (200 per cell)
after:
  sector 1 battle win 100%  rounds 3.4  hull left 82%  ships lost 0.2  timeouts 0  wait old 59s new 34s  real 34s  per round 10.2s  max round 17.8s  ships 4.0+3.6
  sector 1 battle win 96%  rounds 5.1  hull left 58%  ships lost 1.1  timeouts 0  wait old 99s new 57s  real 52s  per round 10.2s  max round 17.8s  ships 4.0+5.0
  sector 1 elite  win 75%  rounds 6.2  hull left 37%  ships lost 2.1  timeouts 0  wait old 120s new 69s  real 59s  per round 9.6s  max round 18.6s  ships 4.0+5.3
  sector 1 boss   win 83%  rounds 9.5  hull left 47%  ships lost 1.4  timeouts 0  wait old 126s new 73s  real 72s  per round 7.7s  max round 17.9s  ships 4.0+3.2
  sector 2 battle win 98%  rounds 5.1  hull left 64%  ships lost 1.7  timeouts 0  wait old 127s new 73s  real 63s  per round 12.5s  max round 25.0s  ships 5.0+6.8
  sector 2 battle win 74%  rounds 7.2  hull left 38%  ships lost 3.1  timeouts 0  wait old 180s new 102s  real 80s  per round 11.2s  max round 24.3s  ships 5.0+8.1
  sector 2 elite  win 64%  rounds 6.7  hull left 31%  ships lost 3.5  timeouts 0  wait old 178s new 101s  real 76s  per round 11.6s  max round 24.6s  ships 5.0+8.4
  sector 2 boss   win 62%  rounds 11.5  hull left 24%  ships lost 3.7  timeouts 2  wait old 199s new 114s  real 97s  per round 8.4s  max round 23.2s  ships 5.0+6.4
  sector 3 battle win 95%  rounds 5.5  hull left 70%  ships lost 1.7  timeouts 0  wait old 201s new 113s  real 77s  per round 14.4s  max round 27.1s  ships 5.0+11.6
  sector 3 battle win 81%  rounds 6.7  hull left 53%  ships lost 2.6  timeouts 0  wait old 258s new 144s  real 86s  per round 13.3s  max round 29.0s  ships 5.0+13.6
  sector 3 elite  win 59%  rounds 7.7  hull left 39%  ships lost 3.2  timeouts 0  wait old 292s new 162s  real 93s  per round 12.4s  max round 29.0s  ships 5.0+13.7
  sector 3 boss   win 77%  rounds 16.5  hull left 31%  ships lost 3.6  timeouts 8  wait old 353s new 197s  real 139s  per round 8.5s  max round 27.6s  ships 5.0+11.5
before:
  sector 1 battle win 100%  rounds 3.3  hull left 83%  ships lost 0.2  timeouts 0  wait old 59s new 35s  real 35s  per round 10.7s  max round 21.0s  ships 4.0+3.6
  sector 1 battle win 99%  rounds 4.5  hull left 64%  ships lost 0.9  timeouts 0  wait old 93s new 54s  real 49s  per round 10.9s  max round 22.2s  ships 4.0+4.9
  sector 1 elite  win 89%  rounds 5.6  hull left 48%  ships lost 1.6  timeouts 0  wait old 113s new 65s  real 57s  per round 10.2s  max round 22.6s  ships 4.0+5.2
  sector 1 boss   win 88%  rounds 9.4  hull left 47%  ships lost 1.5  timeouts 0  wait old 128s new 74s  real 72s  per round 7.7s  max round 20.2s  ships 4.0+3.2
  sector 2 battle win 99%  rounds 4.7  hull left 69%  ships lost 1.4  timeouts 0  wait old 124s new 72s  real 63s  per round 13.6s  max round 27.8s  ships 5.0+6.8
  sector 2 battle win 91%  rounds 6.5  hull left 48%  ships lost 2.6  timeouts 0  wait old 173s new 99s  real 78s  per round 12.2s  max round 31.5s  ships 5.0+8.2
  sector 2 elite  win 77%  rounds 6.9  hull left 35%  ships lost 3.2  timeouts 0  wait old 186s new 106s  real 80s  per round 11.9s  max round 28.8s  ships 5.0+8.3
  sector 2 boss   win 76%  rounds 10.7  hull left 30%  ships lost 3.5  timeouts 0  wait old 195s new 112s  real 96s  per round 8.9s  max round 25.3s  ships 5.0+6.4
  sector 3 battle win 95%  rounds 5.4  hull left 70%  ships lost 1.8  timeouts 0  wait old 199s new 114s  real 78s  per round 14.6s  max round 32.4s  ships 5.0+11.4
  sector 3 battle win 82%  rounds 6.8  hull left 53%  ships lost 2.6  timeouts 0  wait old 262s new 147s  real 89s  per round 13.3s  max round 32.6s  ships 5.0+13.5
  sector 3 elite  win 69%  rounds 7.4  hull left 41%  ships lost 3.2  timeouts 0  wait old 284s new 158s  real 90s  per round 12.4s  max round 32.8s  ships 5.0+13.9
  sector 3 boss   win 81%  rounds 15.2  hull left 34%  ships lost 3.4  timeouts 6  wait old 341s new 193s  real 135s  per round 8.9s  max round 31.6s  ships 5.0+11.6

## skirmish matrix (50 per cell)
after:
             void hege cors chor itha deat
  voidsworn    98   82   68   40   32   66   avg 64
  hegemony     94   72   76   46   64   54   avg 68
  corsair     100  100  100   80   94  100   avg 96
  chorus       98  100   92   72   96  100   avg 93
  ithar       100   98   90   48   80   92   avg 85
  deathless    98   96   14   20   60   80   avg 61
  per battle: rounds 7.0, timeouts 0/1800, rams 2.0, boardings 0.6, captures 0.25, sections lost 16.6
before:
             void hege cors chor itha deat
  voidsworn    98   96   56   44   36   84   avg 69
  hegemony     90   76   36   36   30   52   avg 53
  corsair     100  100   98   98   98  100   avg 99
  chorus       96  100   62   88   92  100   avg 90
  ithar       100   94   96   80   82   94   avg 91
  deathless    86  100   18   36   54   76   avg 62
  per battle: rounds 6.8, timeouts 0/1800, rams 1.9, boardings 0.5, captures 0.17, sections lost 16.7

## boss matrix
after:
  bossmatrix s1 {"vex":"56% r10.5","malek":"42% r11.2","ashgrove":"62% r11.1 (carrier)","thale":"69% r13.7","kassar":"91% r8.9 (carrier)","vorn":"79% r9.7","reyes":"88% r10.4 (carrier)","maren":"87% r15.3 (carrier)","grax":"35% r9.3","sable":"49% r8.7","mott":"65% r8.6 (carrier)","vesh":"72% r12.1 (carrier)","matriarch":"64% r12.3 (carrier)","razormaw":"83% r8.7","mending":"87% r9.2","voice":"85% r8.7","aelith":"74% r11.5 (carrier)","vaelen":"66% r9.6","thorne":"57% r13.1","mirelle":"59% r11.2","nekhet":"83% r13.5","sekhmar":"61% r11.9","anuket":"80% r10.1","khepra":"75% r11.8"}
  by boss {"hegemony":"41%","corsair":"85%","chorus":"63%","ithar":"68%","deathless":"76%","voidsworn":"85%"}
  carrier fleets 75% gun fleets 67%
before:
  bossmatrix s1 {"vex":"64% r10.1","malek":"69% r9.4","ashgrove":"71% r10.9 (carrier)","thale":"76% r13.4","kassar":"90% r9.4 (carrier)","vorn":"77% r10.3","reyes":"86% r10.7 (carrier)","maren":"88% r15.8 (carrier)","grax":"54% r8.6","sable":"68% r8.1","mott":"72% r8.4 (carrier)","vesh":"73% r12.0 (carrier)","matriarch":"65% r12.0 (carrier)","razormaw":"77% r8.8","mending":"88% r8.9","voice":"81% r8.7","aelith":"80% r11.0 (carrier)","vaelen":"78% r9.1","thorne":"73% r11.8","mirelle":"67% r10.7","nekhet":"79% r14.2","sekhmar":"61% r12.0","anuket":"86% r9.8","khepra":"78% r11.3"}
  by boss {"hegemony":"51%","corsair":"85%","chorus":"75%","ithar":"71%","deathless":"83%","voidsworn":"85%"}
  carrier fleets 78% gun fleets 73%

## archetypes
after:
  archmatrix s2 col3 {"none":"84% r6.5 ships 7.2","swarm":"85% r5.6 ships 8.3","heavy":"90% r6.3 ships 4.8","carrier":"83% r6.9 ships 6.3"}
before:
  archmatrix s2 col3 {"none":"91% r5.7 ships 7.3","swarm":"94% r5.0 ships 8.3","heavy":"95% r6.1 ships 4.7","carrier":"88% r6.3 ships 6.3"}

## fuzz
after:
  fuzz 2000 battles: exceptions 0, invariant breaks 0 (0 distinct), avg rounds 7.3

## run sim
after:
   "s1 battle": "687 battles, won 95%, lost/fight 0.27, e/p cp 1.00, rounds 4.1",
   "s1 boss": "188 battles, won 91%, lost/fight 0.53, e/p cp 1.89, rounds 7.5",
   "s1 elite": "122 battles, won 87%, lost/fight 0.67, e/p cp 1.37, rounds 4.8",
   "s2 battle": "289 battles, won 91%, lost/fight 0.71, e/p cp 1.41, rounds 4.7",
   "s2 boss": "128 battles, won 77%, lost/fight 1.27, e/p cp 2.08, rounds 9.2",
   "s2 elite": "87 battles, won 80%, lost/fight 0.94, e/p cp 1.72, rounds 4.9",
   "s3 battle": "167 battles, won 86%, lost/fight 0.60, e/p cp 1.76, rounds 4.1",
   "s3 boss": "63 battles, won 84%, lost/fight 1.03, e/p cp 2.20, rounds 6.8",
   "s3 elite": "42 battles, won 74%, lost/fight 1.00, e/p cp 1.84, rounds 4.3"
  reach {"1":240,"2":172,"3":98,"won":53}
before:
   "s1 battle": "691 battles, won 97%, lost/fight 0.22, e/p cp 1.00, rounds 4.0",
   "s1 boss": "203 battles, won 90%, lost/fight 0.68, e/p cp 1.87, rounds 7.6",
   "s1 elite": "128 battles, won 90%, lost/fight 0.63, e/p cp 1.39, rounds 4.5",
   "s2 battle": "316 battles, won 89%, lost/fight 0.60, e/p cp 1.39, rounds 4.4",
   "s2 boss": "127 battles, won 84%, lost/fight 0.91, e/p cp 1.95, rounds 8.5",
   "s2 elite": "89 battles, won 76%, lost/fight 0.96, e/p cp 1.59, rounds 5.2",
   "s3 battle": "180 battles, won 91%, lost/fight 0.50, e/p cp 1.63, rounds 4.3",
   "s3 boss": "85 battles, won 82%, lost/fight 1.11, e/p cp 2.34, rounds 6.7",
   "s3 elite": "57 battles, won 89%, lost/fight 0.96, e/p cp 1.89, rounds 4.5"
  reach {"1":240,"2":182,"3":107,"won":70}
