# Sim matrix at scale, plus harness defects

Run Oct 23, 2026, on repo main at eca489e, at the owner's request while his other model quotas reset. Method: the game's own harness (sim3d.js under Node 24), every mode run once at the sizes below, output kept verbatim in the run log. Balance numbers are bot versus bot with the harness's standard bot on both sides unless a mode says otherwise; treat them as directional, not as human play.

## Correctness: the net is clean

- fuzz 300 battles: exceptions 0, invariant breaks 0, average 6.6 rounds.
- booncheck: all pass (every boon and aspect spot-checked by the harness produces its stated effect, including duo boon offers at 25 of 60 once both patrons are held).
- cmdcheck: all pass (all 24 admirals' Commands fire, respect the once-per-battle rule, and keep weapon state).
- progcheck: PASSED. rulecheck: PASSED.
- capcheck: displayed capture odds match rolled odds (shown 82% vs rolled 82.3%; shown 59% vs rolled 59.4%; the 100% cases roll 100%).
- stalecheck: no stale-unit actions across battle boundaries; battles differ as expected.
- mapcheck, 300 sectors: every pre-boss column offers a fight (0 missing), and all 900 pre-boss nodes are rest nodes (drydock 306, field 297, shipyard 297).
- enccount, 300 sectors: encounter offers are near-uniform across the eight types (rout 331, flagship 315, ambush 299, hold 298, defend 296, intercept 288, break 275, hunt 264).
- budgetcheck: enemy budgets scale from about 4.0 CP at sector 1 column 0 to about 19.8 at sector 3 column 6 under the new formula, consistently above the old flat numbers in every cell.

## Faction and fleet matrices

fmatrix 12 (FLEET_LISTS fleets, 432 battles, 3 timeouts): row win rates against the field are compressed (most cells 58 to 83), with two outliers worth a look: Hegemony fleet lists beat Voidsworn lists in 100% of reps, and Chorus lists beat Voidsworn only 17% of the time. Per-hull damage dealt: the Deathless harvester is the top hull by a wide margin (31,819 damage over 152 deployments), then the Chorus brood (21,861 over 84) and the Hegemony vanguard (17,419 over 85). Per-weapon total damage: gauss first (50,154 over 4,451 shots), turret second by volume (32,243 over 2,937 shots), squadron bombs third (26,722). Boarding is nearly absent in this mode (player 6, enemy 0 across 432 battles).

matrix 10 sk (admiral starting fleets, 360 battles, 0 timeouts): average win rates by attacking faction: Corsair 98, Ithar 90, Chorus 88, Voidsworn 80, Hegemony 55, Deathless 50. Per battle: 6.9 rounds, 1.9 rams, 0.5 boardings, 0.20 captures, 17.0 sections lost. Note the inversion against fmatrix for Hegemony (strongest fleet lists there, second weakest starting fleets here): the two modes draw fleets from different sources, so neither table should be used to tune the other.

bossmatrix 8 (sector 1 boss, each admiral's fleet converted to their own faction): admiral win rates spread from 38% (Grax) and 40% (Sekhmar) to 98% (Maren) and 98% (Voice), with Vesh and Mending at 90%. By boss faction, the player win rate is: Hegemony boss 51%, Chorus 63%, Deathless 71%, Ithar 74%, Corsair 76%, Voidsworn 80%. Carrier fleets average 74%, gun fleets 67%. Read together: at sector 1 the admiral pick alone is worth roughly 30 points of boss win rate, which makes the admiral screen a hidden difficulty setting, and the Hegemony boss is the sector 1 wall.

## Campaign shape (campaign 30, harness patched, see defects)

Thirty runs per cell with the harness's fixed per-sector fleets:

| Cell | Win | Rounds | Hull left | Ships lost | Anim wait (new clock) |
|---|---|---|---|---|---|
| S1 battle (col 1) | 100% | 4.1 | 75% | 0.6 | 40s |
| S1 battle (col 4) | 100% | 4.9 | 66% | 1.0 | 49s |
| S1 elite | 73% | 6.4 | 38% | 2.1 | 60s |
| S1 boss | 77% | 10.0 | 35% | 2.2 | 73s |
| S2 battle (col 1) | 93% | 6.9 | 54% | 2.4 | 79s |
| S2 battle (col 4) | 83% | 7.1 | 47% | 2.4 | 83s |
| S2 elite | 57% | 8.1 | 23% | 3.8 | 95s |
| S2 boss | 87% | 9.9 | 40% | 3.0 | 93s |
| S3 battle (col 1) | 93% | 5.8 | 65% | 1.9 | 94s |
| S3 battle (col 4) | 83% | 7.2 | 51% | 2.6 | 114s |
| S3 elite | 53% | 7.5 | 40% | 3.2 | 120s |
| S3 boss | 100% | 9.6 | 64% | 1.9 | 109s |

Zero timeouts in all 360 battles. The shape confirms the council gamer lens at three times its sample: sector 1 battles are a formality, the elite cells are the wall (S2 elite is the single hardest cell in the game for these fleets), and the S3 boss 100% is an artifact of the scripted dreadnought fleet rather than a soft boss. Animation wait is the other confirmed problem: even on the new clock, elite and boss fights in sectors 2 and 3 carry 95 to 120 seconds of pure animation time (the old clock prices the same fights at 160 to 213 seconds).

## Archetypes (archmatrix, reduced)

archMatrix at its default size did not finish (see defects). A reduced run (n=1, 480 battles aggregated, sector 2, column 3) gives player win rates by enemy archetype: none 90% (6.3 rounds, 4.2 enemy ships), heavy 89% (6.5 rounds, 3.3 ships), carrier 87% (6.7 rounds, 3.5 ships), swarm 85% (5.8 rounds, 5.9 ships). No archetype is an outlier; swarm fields the most ships and still loses most often, which is a mild surprise worth a human look before any tuning.

## Harness defects found by this run (tooling, not game code)

1. campaignSim crashes intermittently. It pre-registers objective bookkeeping only for the objectives it picks itself (rout, flagship, hold, and rout for bosses), but the campaign battle it launches can roll any of the eight encounter types. When the rolled type is ambush, defend, intercept, break or hunt, the post-battle accounting reads an undefined entry and throws a TypeError, killing the whole run. OBSERVED at sim3d.js campaignSim, the line that increments OBJS_SEEN for B.obj.type after a win. The one-line guard used for the rerun (in a scratch copy only, the repo file was not edited): register the entry before incrementing, i.e. `(OBJS_SEEN[B.obj.type]=OBJS_SEEN[B.obj.type]||{n:0,w:0}).w++`. Until that lands, campaign results will keep dying at random depending on the encounter roll, which is a plausible explanation for flaky campaign numbers in past sessions.
2. archMatrix is impractical at its default workload: 4 archetypes x 24 admirals x 5 enemy factions x n battles is 1,920 battles at n=4, and it produced no output inside a 20-minute limit. Either the default n needs to come down or the mode needs progress output so a long run is distinguishable from a hung one.

## Not checked

Human play (all numbers are the harness bot on both sides, whose player-side decisions are documented in the engineer lens report to differ from the veteran AI the enemy uses). The campaign table uses the harness's fixed fleets, not admiral starting fleets or grown fleets. fmatrix and matrix disagree by construction (different fleet sources) and were not reconciled here. No mode was run at Heat above 0.
