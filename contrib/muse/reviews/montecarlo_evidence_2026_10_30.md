# Voidsworn: Real Campaign Monte Carlo Evidence Pack

Date: Oct 30, 2026. Chair: Rey (Muse). Game pin: 264f441d43a54e3679950dcc4457133b40811807 (clone voidsworn-fresh, read-only; no game files edited, nothing pushed). Harness and raw outputs: ~/workspace/voidsworn-montecarlo/ (loader_main.js, bot.js, driver.js, shard.js, aggregate.js; raw/ holds every shard file).

Purpose: replace the filed "20 percent run win rate" figure, which was produced by a simulator whose campaign layer never spawns the campaign Nemesis, with powered numbers from the real campaign loop: sector maps, node traversal, the shipped battle engine, boon offers, the economy, regroups, and all three Nemesis meetings with adaptations and weakness reveals under the shipped rules.

Scale: 12,600 full campaign runs (10,800 Veteran, 1,800 per faction; 1,800 Standard, 300 per faction), fixed seed sets recorded in the shard files, 140,979 battles, 0 harness errors. 146 runs contained at least one battle that hit the 30-round cap (treatment under Approximations). All proportions carry Wilson 95 percent confidence intervals; means carry normal 95 percent intervals.

## Headline numbers

True run win rate under the stated policy (Methodology): 66.0 percent overall [65.0, 67.0]. Veteran (the shipped steady state): 63.0 percent [63.0, 64.0]. Standard (the literal first-run configuration): 80.0 percent [79.0, 82.0]. The Standard number runs higher because Standard scales enemy budgets down and weakens enemy activation play while the player pilot is unchanged; it measures this bot's first run, not a new human's (a first-time human is far weaker than this pilot, so do not read 80 percent against Ryan's near-impossible run 1 ruling; read it as "the bot finds Standard easy," which is itself the firstrun-relevant signal).

Veteran win rate by faction (n = 1,800 each):

| Faction | Win rate | 95% CI |
|---|---|---|
| Chorus | 85.0% | [83.0, 87.0] |
| Eclipse (deathless) | 68.0% | [65.0, 70.0] |
| Ashfall Hullbreakers (corsair) | 61.0% | [59.0, 63.0] |
| Hegemony | 61.0% | [59.0, 64.0] |
| Glasswrights (ithar) | 55.0% | [53.0, 58.0] |
| Sunward Crusade (voidsworn) | 50.0% | [48.0, 52.0] |

A 35-point spread between the strongest and weakest faction under identical play. Sector reach (all runs): sector 2 reached by 84.0 percent [84.0, 85.0], sector 3 by 71.0 percent [70.0, 71.0], run won by 66.0 percent.

## Battle classes (all runs)

| Class | n | Win rate | Ships lost (mean) | Rounds (mean) |
|---|---|---|---|---|
| S1 battle | 37,274 | 97.0% | 0.20 | 4.07 |
| S1 elite | 4,421 | 89.0% | 0.49 | 4.70 |
| S1 Nemesis | 9,606 | 87.0% | 0.60 | 4.91 |
| S1 boss | 11,304 | 94.0% | 0.43 | 6.66 |
| S2 battle | 18,856 | 95.0% | 0.44 | 3.74 |
| S2 elite | 5,125 | 88.0% | 0.74 | 4.09 |
| S2 Nemesis | 8,772 | 90.0% | 0.75 | 4.36 |
| S2 boss | 9,461 | 94.0% | 0.55 | 5.91 |
| S3 battle | 15,520 | 97.0% | 0.29 | 2.98 |
| S3 elite | 4,387 | 94.0% | 0.50 | 3.25 |
| S3 Nemesis | 7,697 | 95.0% | 0.60 | 3.70 |
| S3 boss | 8,556 | 97.0% | 0.44 | 5.20 |

Bosses are the longest fights in every sector and among the least lethal per fight: wave 3's "long, not lethal" holds at scale. The sector 2 elite attrition peak also holds by ordering: sector 2 elites and sector 2 Nemesis fights tie for the highest ships lost per fight (0.74 and 0.75), ahead of every other class. Wave 3's absolute figure (1.32 lost) does not reproduce; this pilot takes fewer losses in every class, but the shape of the curve is the same shape wave 3 reported.

## The Nemesis in real campaign conditions

Meetings per run: 12,006 first meetings, 9,494 second, 4,575 third (of 12,600 runs). Player win rate by meeting: 88.0 percent [87.0, 88.0] at meeting 1, 91.0 percent [91.0, 92.0] at meeting 2, 95.0 percent [94.0, 95.0] at meeting 3. He gets easier to beat as the run goes on, not harder.

Adaptations: he carries 0.21 adaptations into meeting 1 on average (clock strikes can force an early extra), 1.48 into meeting 2, 2.30 into meeting 3. Grouping all Nemesis fights by the adaptations he carries in reverses the isolated-battle result: player win rate is 87.0 percent [86.0, 88.0] against 0 adaptations (n = 9,606), 90.0 percent [90.0, 91.0] against 1 (n = 7,809), and 94.0 percent [93.0, 94.0] against 2 or more (n = 8,660). This is a confound, not a benefit: adaptation count proxies for run progress, and a fleet that has survived long enough to face a twice-adapted Nemesis is a fleet stacked with boons, relics, modules and Mk upgrades. The same confound lifts the weakness-reveal grouping (88.0 percent at 0 revealed, 90.0 at 1, 93.0 at 2). What the campaign data establishes is the net effect: the shipped adaptation system does not close the gap against real campaign power growth. The filed isolated-battle measurement (an adaptation step worth roughly 15 points in sector 2 at fixed fleets) is not wrong about battles; it just does not survive contact with the campaign, where the player's power grows faster than his capped adaptation count (sector minus 1, hard cap 6, and only 2.3 carried into the final meeting on average). Weakness reveals land early: 1.40 gained at meeting 1 on average (win reveals plus in-battle triggers), 0.41 at meeting 2, 0.02 at meeting 3; by the final meeting the player almost always knows both weaknesses already. The Chorus feeding channel stays small in practice (fed before meeting: 0.12, 0.39, 0.49 by meeting, of a cap of 8).

Answer to the Q6 "measure first" commission, at campaign scale: no snowball. He keeps rough pace in isolated hull-for-hull terms and loses ground every sector in real runs. If he is meant to be a run-defining threat for competent players, adaptations alone will not do it; the lever that matches the boss system (a fit scale against player strength) is the kind of change that would, and that is a design call for Ryan and Opus, not a tuning row in this pack.

## Economy curves and the regroup question

Mean credits: 120 at run start, 405.1 [402.0, 408.2] at the end of sector 1 (n = 12,595 runs with a sector 1 post-battle snapshot), 501.0 [496.7, 505.3] at the end of sector 2 (n = 10,566). Shipyard spending across 47,625 shipyard visits splits: hulls 70 percent, modules 21 percent, Mk upgrades 5 percent, repairs 4 percent. Repairs are a rounding error in this economy, not because repair is cheap per point (it is 0.5 credits per HP at base price) but because fleets arrive nearly whole: median missing hull on the worst ship at yard arrival is 0 HP, median missing fraction 0, median purse 378 credits. The transit patch leaves 31 percent of sector transitions with some damage still unhealed, and it still does not matter, because drydocks, field repairs, and the next yard are close.

Regroup binding under the stated operationalization (fleet missing at least 25 percent of max hull AND credits below full repair cost plus the cheapest useful purchase): 199 of 47,625 visits, 0.42 percent. Together with the Oct 29 model's 0.0 percent, the verdict is robust across two methods and two pilots: at shipped values the repair-versus-buy tension does not bind. Ryan's accept-as-is ruling stands on solid ground; the tuning pack's grid (b) maps what each healing lever is worth in win rate if the regroup ever feels flat in real play.

Prizes and salvage: 6,302 prize decisions resolved Add 3,522, Strip 1,872, Ransom 908 under the game's own prizePlan defaults. Salvage picks: module 75,651, credits 55,819, tow 109. The tow home option is nearly dead (0.08 percent of salvage picks): it needs a wreck of CP 2 or less and spare CP at the same moment, and that conjunction almost never occurs under this policy.

## Content utilization

Utilization is reported against this harness's stated pick heuristics, so pick rates measure the heuristic's valuation as much as the content's power; win-rate-in-runs-with-pick is confounded by run progress and is given for triage, not as a power ranking. Offer and pick counts are exact.

Boons (325,136 offer slots): every boon in the pool was offered and every offered boon was picked at least once. Near-always picked when offered under the heuristic: e_chain 99 percent (5,795 of 5,875), i_brace 99 percent (5,702 of 5,749), d_hunter 99 percent (2,458 of 2,490), r_jink 94 percent, s_arc 93 percent (5,508 of 5,949). Bot-avoided: e_spread picked 40 of 4,100 offers (1.0 percent), a_mark 137 of 6,040 (2.3 percent), s_regen 219 of 6,806 (3.2 percent), s_ion 496 of 13,013 (3.8 percent), i_plate 491 of 12,913 (3.8 percent), r_shock 408 of 10,404 (3.9 percent). These five are the trap candidates to hand Opus first: under a transparent fx-value heuristic they are almost never the best of three, which means either their effects are undervalued by flat fx scoring (spread and mark are positional, regen is sustain) or they are genuinely dominated. That distinction needs a human read per boon; the pack flags, it does not convict. Boon declines: 0 in 12,600 runs (the decline rule, all three offers useless to the fleet kit, never fired).

Modules: all 13 offered and picked; pick rates cluster between 14 percent (loaders) and 43 percent (auspex). No dead modules under this policy.

Relics: the fx-heuristic relic scorer produces one extreme outlier: armourweave picked 6 times in 16,416 offers (0.04 percent), with banner and martyr at 11 percent (about 1,600 picks each) and everything else at 43 percent or better (logbook 100 percent, ledger 90 percent, spore 81 percent). The relics synthesis already found armourweave duplicates a boon key at the same value; the utilization data agrees it is the pool's dead slot under any fx-based valuation.

Hulls: base hulls convert from yard stock at 27 to 65 percent. Variant hulls almost never convert: d_jackal_h bought 2 of 631 offers and fielded in 3 battles all program; b_razor_e 70 of 707; h_interdictor_e 9 of 499; vs_penitent_l 51 of 454; c_marauder_g 75 of 682. Under a CP-greedy purchase policy the variant is never the pick over its base hull at the same shelf; whether that is price, stats, or the policy's CP-first sort is Opus's read, but the shelf data says variants are decorative in the current yard economy. Most fielded hulls overall: d_jackal (54,150 battle appearances), b_razor (53,534), d_scythe (37,752).

Events: 7,737 event nodes across the program. 32 of 33 events appear; the missing one, quiet, is the EVENT_FALLBACK, excluded from the normal draw by code and shown only when a run has seen every other event, which never happened (a run sees at most about 9). No event ever presented with zero enabled options. The event pool is healthy at this scale.

Faction verbs: 25,808 uses across 12,600 runs (about 2 per run under the affordability policy).

## Methodology: what is real, what is policy, what is approximation

Real shipped code, executed unmodified (loaded in build order: data.js, core.js, battle.js, campaign_meta.js, campaign_run.js, campaign3d.js):

- Run construction: newRun (starting fleet, credits, CP cap, patrons, gift boon), aspect offer and pick effects.
- Sector maps: genSector, including the column 4 elite guarantee (with its known silent no-op when column 4 rolls all rest nodes), node rewards, sector conditions, region maps.
- Battles: startBattle and the full battle engine (objectives, faction rules, encounter generation, boss fit scaling, RAMP thinning), the shipped enemy AI (aiUnit, aiPickActivation, swarmPhase), finishBattle settlement (captain xp, the post-win patch, prizes, wrecks, the pyrrhic reinforcement), and battle events.
- The Nemesis system entire: newNemesis, the clock and strikes (nemClockAdd, nemStrike), node conversion (nemNodeIs), nemBattleCfg, applyNemesis in battle, nemAfterBattle (reveals, scars, fed, revive, arc completion), nemAdapt, nemLearn, nemFoundMerge, nemFeedLosses.
- Rewards: rewardFlow and the ACT chain (prizePlan defaults for prizes, salvageYield for salvage, boon offers via rollBoonOffer with the shipped backfill and duo behavior, module offers, relic offers via relicUseful, promotions).
- Economy: the battle pay formula, shipyard stock and prices (shipyardStock, priceMult), repair costs, Mk upgrades, drydock and field repairs, events (nextEvent, eventOptOk, applyOutcome), sector transit (cpCap +3, the 40 percent transit patch, per-sector nemAdapt).
- The player pilot in battle is the game's own simulator bot (sim3d.js botUnit, botCommand, botObj), the same pilot wave 3 used, so battle behavior stays comparable with the filed evidence.

Bot policy (chair choices, stated here so Opus can re-run under a different policy):

- Node routing: score by node type (elite 50, boss 45, battle 32, shipyard 26 plus 8 when credits exceed 180, event 20, drydock and field 14), with a damage override (at fleet hull under about 55 percent, drydock +120, field +100, shipyard +90, elite -25) and reward bonuses (boon nodes for patrons with fewer than 2 boons held, repair rewards when damaged).
- Boon picks: rarity weighted score over the boon's scaled fx, duo +2, legendary +4; decline only when every offered boon is useless to the current fleet kit; never reroll.
- Shipyard: repair all first; buy the highest-CP fitting stock hulls keeping a 40 credit floor; buy stock modules keeping a 120 credit reserve and auto-fit each to the first compatible ship with a free slot; Mk upgrades flagship first keeping a 250 credit reserve; never sell; class tracks not bought in the baseline policy.
- Prizes take the game's own prizePlan defaults (Add when it fits CP, passes the faction gate and holds at least 40 percent hull; otherwise Strip vs Ransom by value). Salvage takes module over tow over credits. Relic and module reward picks score by fx key weight. Promotion perks score by fx weight. Event options score by a stated value function (credits, xp, heals scaled by missing hull, relic, module, ship joins, intel positive; costs, damage, payRelic, payXp, payMod negative; fight options only at fleet hull 70 percent or better).
- The faction verb is used at the map when its cost is free, flag-gated, or comfortably affordable. Aspect pick scores the three offered aspects by fx weight.
- Every run starts from a fresh profile (defaultMeta: no LEGACY unlocks, no mastery, no banked favour). Runs are therefore independent and measure the game as a new profile plays it repeatedly. Real players accumulate mastery and favour across runs, which makes later real runs easier than these numbers; treat these figures as the fresh-profile floor.

Approximations (flagged, none hidden):

- battleScreen and ACT.enterNode are replicated line for line in the driver minus rendering (node seed handling with both salts, the free warden garrison rule, encounter and map assembly, the battle-event roll). prepBattle reduces to its rules content: alternating activations on (the shipped default), units unactivated, enemy side turn seeded.
- Battles run under a 30-round cap, as sim3d does. A non-boss timeout resolves as a retreat (the shipped withdraw flow). A boss timeout resolves as a loss: retreating out of a boss node would complete it and strand the run on the map, a state the shipped game cannot reach because it has no round cap. 146 runs contained a capped battle.
- Presentation stubs follow sim3d's semantics (animPath forwards onLate, animMove and animRotate commit position and facing, everything else is a no-op). SPEED is 0, so presentation waits are instant; zero-delay timers resolve as microtasks in the harness only. Individual battle traces are sensitive to async stub timing; aggregate statistics are the product, and the harness is deterministic under its stated environment (verified: two independent loaders produce identical traces on fixed seeds).
- AI level: Veteran is the headline configuration (the shipped steady state once a profile has any completed runs, and the level wave 3 reported). A Standard slice is included for the literal first-run number.
- The regroup tension metric is operationalized as: a shipyard arrival binds when the fleet is missing at least 25 percent of its max hull AND credits on arrival are less than the full repair cost plus the cheapest useful purchase on offer (stock hull, stock module, or Mk upgrade). The Oct 29 chair metrics (median missing HP on the worst ship, median purse at arrival) are reported alongside for direct comparison.

## Validation against wave 3 (60 runs, 10 per faction, Veteran, seeds 1000+)

Wave 3's filed battle table (60 bot runs, 425 battles) against this harness at the same nominal configuration:

- Bosses are long, not lethal: this harness measured boss fights at 8.7 rounds (sector 1), 6.4 (sector 2), 5.8 (sector 3) in validation against wave 3's 7.9, 6.5, 6.2, and the full batch confirms the shape (6.66, 5.91, 5.20). The sector 1 boss is the hardest boss here too.
- Regular sector 1 battles are near-free in both: 0.24 ships lost per fight in validation, 0.28 in wave 3; the full batch lands at 0.20.
- The sector 2 elite attrition peak reproduces by ordering at full scale (see Battle classes), though not at wave 3's absolute loss rate.
- The 20 percent run win rate does NOT reproduce: 60 percent in validation (36 of 60, 95 percent CI 47 to 71 percent) and 63.0 percent in the full Veteran batch. The battle-level numbers sit in wave 3's family while the campaign outcome does not, and the difference is the campaign layer: wave 3's pack does not document any purchase, repair, or routing policy for its campaign driver, while this harness plays the full loop with the stated policy above. Conclusion: the run win rate is strongly policy-sensitive. Any tuning decision that cites a win rate needs to name its pilot and its campaign policy; the 20 percent figure should be retired as a property of the game and re-filed as a property of an undocumented driver.
- Harness errors: 1 of 60 validation runs, a boss timeout under the pre-fix timeout rule (since corrected to resolve as a loss; see Approximations). The full 12,600-run batch recorded 0 harness errors.
