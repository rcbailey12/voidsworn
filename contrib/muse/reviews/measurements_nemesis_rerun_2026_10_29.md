# Nemesis snowball measurement: high-power rerun (Oct 29, 2026)

Rerun of Measurement 1 from measurements.md (battle program Q6, ruled MEASURE FIRST), answering the red-team review of that measurement. The review's objections were: (1) n=20 per cell is underpowered and only the sector 2 gap nears significance; (2) sector snapshots are not full three-meeting trajectories; (3) adaptation types are not isolated; (4) the weakness deltas (+20pp sector 2, +10pp sector 3) are inside noise; (5) round-count claims lack distributions. A second review leg added: (6) battered-arrival arms at about 60 percent and about 40 percent hull, since the original seats the player at full strength; (7) a Chorus arm with its real adaptation cadence and fed stacking; (8) spread on the base CP ratio alongside the 1.36 / 1.34 / 1.29 means.

## Method

Tool: the game's own sim3d.js, driven through a recording wrapper (nem_rerun.js in this folder). The stock nemmatrix mode prints only a rounded win percent and a mean round count per cell, which cannot support confidence intervals or round distributions, so the wrapper loads sim3d with its CLI dispatcher removed and runs a recording variant of its nemMatrix loop inside the same code scope. Fleet building (admiral start fleet grown with roster hulls to CP targets 7, 12, 18), Nemesis construction (two random traits, sector minus 1 random adaptations drawn from the generic pool plus the faction special, scars max(0, sector-2), fed and riches per faction behaviour), the bot pilot and the alternating-activation battle loop are sim3d's own, unchanged. The wrapper only records per-battle results and, for the extra arms, changes the Nemesis object or the fleet hull points handed to startBattle. Game files were not edited. The wave 1 harness loader was not used for battles because it has no pilot; it was used in the original only for the fleet power spot check.

Run sizes: 130 battles per main cell (was 20), 120 per adaptation, adaptation-cap and Chorus cell, 100 per battered cell. Total 3,930 battles. Arms are unpaired (independent draws per arm), as in the original. Win rates carry Wilson score intervals; deltas between arms carry Wald (normal approximation) intervals on the difference of two independent proportions, with two-proportion z-test p values. Round counts carry mean, standard deviation, median and interquartile range. A Nemesis who flees (Corsair, Ithar) ends the battle as a player win, as in the original and as in the campaign (he escapes, the feud continues). Timeouts were negligible: 2 in 3,930 battles.

Extra arm definitions:

- Adaptation isolation (sector 2): the nemNoWeak Nemesis with its one adaptation forced to a single named type (shields, pd, armor, evasion, aim, or the enemy faction's special), plus a noAdapt arm (Nemesis with zero adaptations) as the baseline. 120 battles each.
- Second adaptation (sector 3): nem and nemNoWeak arms with the adaptation count capped at 1 instead of 2.
- Battered arrival: every player ship set to 65, 60 or 40 percent of maximum hull before the battle, in the nem and nemNoWeak arms, sectors 2 and 3. Enemy fleet generation still indexes on the battered fleet's fleetPower, exactly as the shipped code would, so the compensation that indexing provides is part of the measurement (CP ratios reported per arm).
- Chorus cadence: enemy faction forced to Chorus. chorusStd is the sim's standard schedule (adaptations = sector minus 1, fed = sector minus 1). chorusFast is parameterized from campaign_run.js nemAdapt: the Chorus cap is max(0, sector-1) + beaten + scars (absolute cap 6) and adaptFast adapts after every meeting as well as per sector advance. The arm assumes the snowball-relevant path, a player who beat him in each prior meeting with his flagship destroyed: sector 2 gets 3 adaptations, 1 scar, fed 4; sector 3 gets 5 adaptations, 2 scars, fed 8 (the fed cap). Weaknesses live in both Chorus arms, matching the nem arm.

## Main cells (130 battles each)

Player win rate, percent with Wilson 95% interval. Rounds: mean (sd), median [Q1, Q3].

| sector | arm | win rate | rounds |
|---|---|---|---|
| 1 | plain elite | 80.0 [72.3, 86.0] | 6.5 (2.2), 6 [5, 8] |
| 1 | nemesis | 67.7 [59.2, 75.1] | 6.6 (2.5), 6 [5, 8] |
| 1 | nemesis, no weaknesses | 71.5 [63.3, 78.6] | 7.0 (2.7), 7 [5, 8] |
| 2 | plain elite | 73.1 [64.9, 80.0] | 6.9 (2.8), 7 [5, 8] |
| 2 | nemesis | 62.3 [53.7, 70.2] | 7.3 (3.2), 7 [5, 9] |
| 2 | nemesis, no weaknesses | 58.5 [49.9, 66.6] | 7.4 (2.7), 7 [6, 9] |
| 3 | plain elite | 76.2 [68.1, 82.7] | 6.8 (2.2), 6 [5, 8] |
| 3 | nemesis | 52.3 [43.8, 60.7] | 7.7 (2.8), 8 [6, 9] |
| 3 | nemesis, no weaknesses | 48.5 [40.0, 57.0] | 7.7 (3.4), 7 [6, 9] |

Original n=20 cells for comparison: plain 65 / 80 / 60, nemesis 60 / 65 / 45, nemNoWeak 65 / 45 / 35. Several original cells were small-sample artefacts (sector 3 plain was 12 of 20; its rerun interval [68.1, 82.7] excludes 60). The deltas below are the robust objects.

## Deltas (percentage points, Wald 95% interval)

| delta | estimate | interval | p |
|---|---|---|---|
| Growth cost sector 1 (plain minus nemNoWeak: the trait package, zero adaptations) | +8.5 | -1.9 to +18.8 | 0.11 |
| Growth cost sector 2 (plain minus nemNoWeak: traits plus one adaptation) | +14.6 | +3.2 to +26.0 | 0.012 |
| Growth cost sector 3 (plain minus nemNoWeak: traits, two adaptations, one scar, faction extras) | +27.7 | +16.4 to +39.0 | <0.001 |
| Growth cost change, sector 3 minus sector 2 | +13.1 | -3.0 to +29.1 | n/a |
| Weakness value sector 1 (nem minus nemNoWeak) | -3.8 | -15.0 to +7.3 | 0.50 |
| Weakness value sector 2 | +3.8 | -8.0 to +15.7 | 0.53 |
| Weakness value sector 3 | +3.8 | -8.3 to +16.0 | 0.53 |
| Full nemesis cost sector 1 (plain minus nem) | +12.3 | +1.7 to +22.9 | 0.023 |
| Full nemesis cost sector 2 | +10.8 | -0.5 to +22.1 | 0.062 |
| Full nemesis cost sector 3 | +23.8 | +12.6 to +35.1 | <0.001 |

## Verdicts on the original claims

1. **Base premium flat at about 1.3x, narrowing slightly (spot check 1.36 / 1.34 / 1.29): CONFIRMED.** Measured inside live battles (plain arm, per-battle enemy CP over player CP, n=130 per sector): means 1.36, 1.33, 1.27, matching the spot check to within 0.02 and narrowing the same way. Spread, which the original lacked: standard deviations 0.15, 0.19, 0.08; sector 2 individual meetings range from 0.67 to 1.67, so the premium is a stable mean over wide per-meeting variance, not a per-meeting guarantee.
2. **Sector 1: the compounding layer costs nothing measurable (growth cost 0pp): WEAKENED.** The trait package alone (nemNoWeak sector 1 has zero adaptations) costs a best-estimate +8.5pp, interval -1.9 to +18.8: zero is still inside the interval, so "nothing measurable" survives in the narrow statistical sense, but the point estimate moved and the full sector 1 package with weaknesses live costs a significant +12.3pp [+1.7, +22.9]. The original's clean zero was an artefact of two identical 13-of-20 cells.
3. **First adaptation step, sector 2 growth cost 35pp: WEAKENED.** The step is real and significant, but the rerun puts it at +14.6pp [+3.2, +26.0]; 35 lies outside the interval. The original's sector 2 nemNoWeak cell was 9 of 20, a low draw. The step is also not mostly the adaptation: it decomposes into the trait package (about +8.5pp, from sector 1) plus one adaptation (about +2 to +7pp, from the isolation arms below), two medium effects stacking, not one hard step.
4. **Sector 3 growth cost 25pp, and it does not widen (a step, not a slope): size CONFIRMED, no-widening WEAKENED.** Sector 3 growth cost reruns at +27.7pp [+16.4, +39.0], consistent with 25. But the change from sector 2 is a best-estimate +13.1pp [-3.0, +29.1]: the interval includes flat and excludes any real narrowing, so the honest summary is "probably widens somewhat, may be flat, does not narrow". The widening is not the second adaptation (next section); the remaining candidates riding in every sector 3 arm are the first scar (+10% flagship damage) and the faction extras (fed, riches, honed), which this rerun did not isolate.
5. **Weakness value +20pp sector 2, +10pp sector 3: sector 2 REFUTED, sector 3 WEAKENED.** Rerun estimates are +3.8pp in both sectors, neither significant. The sector 2 interval [-8.0, +15.7] excludes +20 outright. In sector 3, +10 sits inside the interval but so does zero. At this power, the intel loop's measured payback in the bot's hands is small (about 4pp) and statistically indistinguishable from zero in every sector. Caveat: the bot knows and plays around the weaknesses perfectly in both arms because nemWeak applies the penalties regardless of the revealed list; a human who has not revealed a weakness gets less, a human who has revealed one may exploit it better than this delta shows. What is refuted is the +20pp figure, not the existence of the effect.
6. **Full nemesis win rates 60 / 65 / 45: CONFIRMED.** Rerun: 67.7, 62.3, 52.3, and all three original points fall inside the rerun intervals.
7. **Nemesis fights run long (nemesis arms 7.2 to 9.3 rounds vs plain 6.4 to 7.8): CONFIRMED, modestly, now with distributions.** Rerun means rise with sector in both nemesis arms (sector 3: 7.7 and 7.7 vs plain 6.8; sector 2: 7.3 and 7.4 vs 6.9; sector 1: 6.6 and 7.0 vs 6.5). Standard deviations are 2.2 to 3.4 rounds and the interquartile ranges overlap heavily ([5, 8] plain vs [6, 9] nemesis at sector 3, medians 6 vs 8), so the lengthening is a mean shift of about half a round to one round, not a different kind of fight.
8. **Headline verdict, KEEPING PACE, not snowballing: CONFIRMED for the standard cadence, WEAKENED as a blanket claim.** For a standard-cadence Nemesis the design caps still bind (at most 2 adaptations by the final meeting, scars capped at 2, fed capped at +32%, base indexed to player power) and the bot wins about half the sector 3 meetings. The Chorus exception in the next-but-one section is large enough that the blanket statement no longer stands unqualified.

## Adaptation isolation, sector 2 (120 battles per arm)

Win rate with the one adaptation forced, on the nemNoWeak base. Baseline noAdapt: 60.8 [51.9, 69.1]. The standard nemNoWeak arm (one random adaptation) reruns at 58.5, only +2.4pp below noAdapt, interval -9.8 to +14.5: not significant.

| forced adaptation | win rate | cost vs noAdapt | interval |
|---|---|---|---|
| armor (Ram plating, +10 armor points) | 48.3 [39.6, 57.2] | +12.5 | +0.0 to +25.0, p=0.050 |
| aim (Gunnery drills, +8 aim) | 50.0 [41.2, 58.8] | +10.8 | -1.7 to +23.3, p=0.089 |
| evasion (+8 evasion) | 54.2 [45.3, 62.8] | +6.7 | -5.8 to +19.1 |
| pd (point defense on two ships) | 55.0 [46.1, 63.6] | +5.8 | -6.6 to +18.3 |
| shields (+20% shields) | 57.5 [48.6, 66.0] | +3.3 | -9.1 to +15.8 |
| faction special (pooled) | 60.0 [51.1, 68.3] | +0.8 | -11.5 to +13.2 |

No single adaptation drives the sector 2 step. Armor is the largest point estimate and the only one at the edge of significance; aim is second; the faction specials pooled are worth about nothing as a first adaptation. One honest tension: the six forced arms average about 6.9pp of cost, while the random-draw arm sits only 2.4pp below noAdapt. The arms are unpaired and every delta carries roughly plus or minus 12pp of noise, so the two pictures are consistent within their intervals, but the exact ordering of armor over aim over the rest is suggestive, not settled.

## The second adaptation, sector 3 (120 battles per capped arm)

- nemNoWeak with one adaptation instead of two: 46.7 [38.0, 55.6] vs full 48.5. Difference -1.8pp [-14.2, +10.6]: the second adaptation costs nothing measurable without weaknesses in play.
- nem with one adaptation instead of two: 64.2 [55.3, 72.2] vs full 52.3. Difference +11.9pp [-0.3, +24.0], p=0.056: borderline, and in the opposite direction from the weakness-free arm.

The two arms disagree, so the second adaptation's cost is not settled by this rerun (see the not-settled list). It is bounded: at most about 12pp, possibly zero.

## Battered arrivals (100 battles per cell)

Player win rate when every ship starts at the stated fraction of maximum hull. Full-strength references: sector 2 nem 62.3, nemNoWeak 58.5; sector 3 nem 52.3, nemNoWeak 48.5.

| sector | arm | 65% | 60% | 40% |
|---|---|---|---|---|
| 2 | nem | 55.0 [45.2, 64.4] | 51.0 [41.3, 60.6] | 36.0 [27.3, 45.8] |
| 2 | nemNoWeak | 45.0 [35.6, 54.8] | 39.0 [30.0, 48.8] | 35.0 [26.4, 44.7] |
| 3 | nem | 47.0 [37.5, 56.7] | 47.0 [37.5, 56.7] | 46.0 [36.6, 55.7] |
| 3 | nemNoWeak | 47.0 [37.5, 56.7] | 44.0 [34.7, 53.8] | 35.0 [26.4, 44.7] |

Findings:

- Sector 2 is where battered arrivals bite. Growth cost (full-strength plain minus battered nemNoWeak) widens from +14.6pp at full strength to +28.1pp at 65%, +34.1pp at 60% and +38.1pp at 40%, all significant. The nemNoWeak win rate degrades monotonically with damage (45.0, 39.0, 35.0).
- Sector 3 is much flatter, and the reason is visible in the CP ratios: a battered sector 3 fleet's fleetPower drops enough that the generated enemy budget falls with it (enemy over player CP ratio 1.27 at full strength, 1.04 to 1.08 at 65 to 60%, 0.92 to 0.93 at 40%). At sector 2 the same indexing only reaches 1.07 to 1.17. So the shipped indexing already compensates battered arrivals, and compensates more at sector 3 scale than at sector 2. Only the 40% sector 3 nemNoWeak cell shows a significant drop (+13.5pp [+0.8, +26.2]).
- The original limitation stands corrected in one direction: the full-strength snapshot overstates the player's sector 2 position against a grown Nemesis by roughly 15 to 25pp of win rate at realistic arrival damage. It does not overstate sector 3, thanks to the indexing.

## Chorus cadence (120 battles per arm, weaknesses live)

| sector | standard cadence | fast cadence | cadence cost | interval |
|---|---|---|---|---|
| 2 | 50.8 [42.0, 59.6] | 31.7 [24.0, 40.4] | +19.2 | +6.9 to +31.4, p=0.002 |
| 3 | 46.7 [38.0, 55.6] | 15.8 [10.4, 23.4] | +30.8 | +19.8 to +41.9, p<0.001 |

The original limitation said the Chorus was understated. Confirmed, and it is the largest single effect in this rerun. On the always-beaten path the campaign rules allow (adaptation cap max(0, sector-1) + beaten + scars, adaptFast after every meeting, fed stacking to the +32% cap), the sector 3 Chorus meeting is a 15.8% win rate fight for the bot: that is snowball-shaped, driven by adaptation count (5 of a possible 6) plus fed at cap, not by the base fleet, whose CP ratio stays at 1.28. Two qualifications. First, the path matters: the fast cap only grows when he is beaten or scarred, so a player who loses the sector 1 meeting faces something much closer to the standard cadence; the snowball feeds on the player's earlier wins. Second, Chorus at standard cadence is already a bit harder than the pooled Nemesis (sector 2: 50.8 vs 62.3, -11.5pp, interval -23.7 to +0.7), so a slice of the fast-cadence gap is the faction itself. Fast-cadence fights also end faster (rounds 6.2 and 6.6, sd 1.9), losses come quickly rather than by attrition. The fast arms' rounds and the standard arms' (6.7, 7.0) are in the cell tables in the analysis output.

## Trajectory

A true three-meeting trajectory is NOT SETTLED: the tooling does not support it cleanly, and no new simulator was built. sim3d's runSim plays full campaigns but never spawns the campaign Nemesis object (its battles carry no nemesis parameter), and nemMatrix is a snapshot design; chaining meetings would require carrying one fleet's damage, repairs, purchases and one Nemesis's adaptation history through campaign progression that lives in campaign_run.js, which the sim does not load. The strongest available substitutes are in this report: per-sector snapshots at full strength (main cells), snapshots at three battered-arrival levels (the state a trajectory most often delivers you in), adaptation-count arms that walk the growth variable directly (0, 1, 2 adaptations, plus the Chorus 3 and 5), and the Chorus cadence arms parameterized from the campaign code. What those substitutes cannot show is path dependence within a run (for example, a fleet that wins sector 1 cheaply arriving at sector 2 stronger than any snapshot assumes, or the reverse spiral), and any verdict that depends on that remains open.

## What this rerun could not settle

- The second adaptation's cost: the weakness-free arm says zero (-1.8pp), the weaknesses-live arm says about 12pp (borderline, p=0.056). Bounded, not resolved.
- The exact adaptation ordering: armor and aim lead on point estimates, but every pairwise interval overlaps; only "no single driver, specials about zero" is settled.
- The sector 1 trait package's exact size: +8.5pp with an interval from -1.9 to +18.8.
- Whether the sector 3 growth widening (+13.1pp, interval -3.0 to +29.1) is real, and if so which of the scar or the faction extras drives it; neither was isolated.
- The true trajectory question, per the section above.
- Chorus cadence on other paths (losing meetings, flagship left alive): the arm measures the always-beaten path only, by design.

## Bottom line for the Q6 ruling (MEASURE FIRST, tune only on data)

The standard-cadence Nemesis keeps pace: growth costs of about +15pp at sector 2 and +28pp at sector 3 against a plain elite, weaknesses worth about +4pp back (not the +20 / +10 originally measured), full-meeting win rates of 68 / 62 / 52 percent for the bot at full strength. If tuning is wanted, the data now points at three levers in order: (1) the Chorus fast cadence, the one genuinely snowball-shaped channel (+19 to +31pp over its own standard cadence); (2) sector 2 battered arrivals, where the fleetPower indexing compensates least (growth cost up to +38pp at 40% hull); (3) the trait package, which is most of the sector 2 step, rather than the adaptations the original named. The first adaptation itself is worth only about 2 to 7pp, and the second adaptation's cost is unsettled but bounded at about 12pp.

## Reproducibility

Scripts and raw data in this folder: nem_rerun.js (the recording wrapper), nem_jobs_a.json through nem_jobs_d2.json (arm definitions), nem_out_a.json through nem_out_d2.json (every battle's result, rounds, factions, adaptations, weaknesses and CP totals), nem_analyze.py (intervals and deltas), nem_analysis_out.txt (its full output). Seed bases 7100 to 7500 by batch. Code pin: main 264f441d, clone ~/workspace/voidsworn-fresh, no game files edited.
