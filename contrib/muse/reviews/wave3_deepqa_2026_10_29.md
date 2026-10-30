# Wave 3 deep QA evidence pack, Oct 29, 2026

Chair-run evidence for Opus to verify, all against the browser code at main 264f441d. Tools: softlock_sweep.js (filed with the wave 1 harness at contrib/muse/tools/harness/softlock_sweep.js, runs on game_loader.js) and the game's own simulator sim3d.js (repo file, unmodified). Verdicts below are OBSERVED from the runs cited; design readings are labeled INFERRED.

## 1. Softlock and guarantee sweep: no softlocks, one broken guarantee

4,500 sector maps (seeds 1-1500 x sectors 1-3) checked for structure: 7 columns, exactly 1 entry node, exactly 1 boss in the last column, the pre-boss column all rest types, every middle column offering a fight, column 3 offering a shipyard, node types in the known set, fight encounters existing, the boss reachable by BFS over the edge list, and determinism. 1,920 battle setups (12 shapes x 5 maps x 8 objectives x 4 seeds) checked for: no throw, battle not already over, terrain connected, every unit on board and legally placed, the player side fielding exactly the living fleet, finite hull values.

Results: battle setups 0 failures. Sector maps 84 failures, all one kind: "column 4 offers no elite" (1.87% of maps). The boss was reachable in all 4,500 maps. There is no softlock in either sweep.

The elite failure is a broken design guarantee, not a softlock: the column still offers a fight. Mechanism, OBSERVED by instrumenting genSector on seed 151, sector 1: column 4 rolls [drydock, drydock]; the elite guarantee at core.js:268 looks for a battle or event node to convert and silently does nothing when none exists; the budgets loop then promotes one node to battle, and the lone-node field conversion at core.js:277 (its target column can be 4) turns the other into a field node, leaving [battle, field]. The code comment ("the column before the rest stop always offers an elite") is therefore false whenever column 4 rolls all rest-type nodes. Fix shape, chair observation for Opus: when no battle or event node exists in the column, convert a rest node instead of doing nothing.

## 2. Faction matrix, sim3d matrix mode (216 battles)

Skirmish lists, 6 battles per cell, the player-side bot against the standard AI. Player win percent by row (player faction) against column (enemy faction):

| player | vs Crusade | vs Hegemony | vs Hullbreakers | vs Chorus | vs Glasswrights | vs Eclipse | avg |
|---|---|---|---|---|---|---|---|
| Sunward Crusade | 100 | 83 | 100 | 83 | 100 | 67 | 89 |
| Hegemony | 67 | 67 | 100 | 100 | 100 | 83 | 86 |
| Ashfall Hullbreakers | 83 | 100 | 100 | 33 | 83 | 50 | 75 |
| The Chorus | 67 | 50 | 100 | 83 | 83 | 67 | 75 |
| The Glasswrights | 100 | 50 | 100 | 67 | 67 | 67 | 75 |
| Eclipse | 67 | 100 | 100 | 100 | 83 | 83 | 89 |

Per battle across the matrix: 7.1 rounds, 0 timeouts in 216 battles, 2.4 rams, 0.6 boardings, 0.21 captures, 19.0 sections lost. INFERRED reading: no faction pairing is a degenerate blowout at faction level (averages 75 to 89), and no battle stalled. Caveats: n=6 per cell means one battle is 17 points, so single cells (Hullbreakers 33 vs Chorus, Chorus 50 vs Hegemony) are smoke, not signal; and the player side is the full-toolkit bot, so absolute levels run high by construction. The matrix answers "is any matchup structurally broken", not "is the game balanced".

## 3. Campaign Monte Carlo, sim3d runsim mode (60 bot runs)

Reach: all 60 runs entered sector 1; 34 reached sector 2 (57%); 18 reached sector 3 (30%); 12 won the run (20%). The 20% run win rate cross-validates the Oct 28 progression program's fresh pool (20.8% over 400 runs) on an independent driver.

Battle-level results inside those runs (425 battles):

| class | battles | won | ships lost per fight | enemy/player CP | rounds |
|---|---|---|---|---|---|
| S1 battle | 162 | 94% | 0.28 | 0.97 | 3.8 |
| S1 elite | 36 | 75% | 0.75 | 1.28 | 4.7 |
| S1 boss | 41 | 83% | 0.76 | 1.98 | 7.9 |
| S2 battle | 59 | 88% | 0.73 | 1.40 | 4.4 |
| S2 elite | 22 | 77% | 1.32 | 1.63 | 5.5 |
| S2 boss | 22 | 82% | 0.55 | 2.03 | 6.5 |
| S3 battle | 35 | 89% | 0.49 | 1.49 | 4.5 |
| S3 elite | 12 | 92% | 0.50 | 1.77 | 3.9 |
| S3 boss | 13 | 92% | 0.92 | 1.67 | 6.2 |

OBSERVED patterns, both consistent with the Oct 28 difficulty pack: bosses are long rather than lethal (6.2 to 7.9 rounds, win rates 82 to 92%), and sector 2 elites carry the highest attrition of any class (1.32 ships lost per fight). Sector 3 classes rest on 12 to 35 battles each, so their win rates are indicative only. Difficulty at run level is attrition-driven: the bot wins most individual fights and still loses 80% of runs, which matches the ruled design position (the high loss rate is expected; run 1 near impossible).

## Not checked

- No human-played runs; all pilots are the game's own bot, whose play is not a player proxy for decision quality.
- The matrix used one fleet list per faction (sim3d's skirmish lists); roster-depth extremes (all-swarm, all-capital) were not run as separate probes.
- The sweep checks map structure and battle setup legality only; mid-battle stuck states (a battle that can neither be won nor lost by the AI) are covered indirectly by the matrix's 0 timeouts, not by a dedicated probe.
- Godot-side parity for any of this is Opus's lane (his goldens exist); nothing here runs the Godot build.
