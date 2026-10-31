# Voidsworn: Monte Carlo Policy Sensitivity Extension

Date: Oct 30, 2026. Chair: Rey (Muse). Game pin: 264f441d43a54e3679950dcc4457133b40811807 (clone voidsworn-fresh, read-only; no game files edited, nothing pushed). Harness: the first program's, unmodified (loader_main.js, bot.js, driver.js, shard.js), plus policies.js (profile overrides) and aggregate_profiles.js. Raw shards: raw/pol_<policy>_<faction>.json, 24 files.

Purpose: the first campaign Monte Carlo (montecarlo_evidence_2026_10_30.md) measured a 63.0 percent Veteran bot win rate under one documented campaign policy, and flagged its own headline as policy-sensitive: wave 3's undocumented driver had produced 20 percent from the same game. This extension turns that caveat into bounds. It runs three additional documented campaign policies alongside a fresh baseline control arm, at Veteran, across all six factions, and re-tests the first report's four load-bearing conclusions under each.

Scale: 26,400 full campaign runs in this extension (1,100 per faction per policy, 4 policies, 6 factions), 260,094 battles, 49,100 Nemesis meetings, 0 harness errors. 370 runs contained at least one battle that hit the 30-round cap (373 capped battles; treatment as in the first report). All proportions carry Wilson 95 percent confidence intervals. Seed discipline: each faction has one seed block (voidsworn 400000, corsair 420000, deathless 440000, hegemony 460000, ithar 480000, chorus 500000) and all four policies run the identical 1,100 seeds within the block, so policy comparisons are paired per seed, not just pooled. At n = 1,100 the widest interval half-width on a headline win rate is about plus or minus 2.95 points (at p = 0.5). Admirals cycle round-robin within each shard, 275 runs per admiral per cell.

## Headline: the win rate is a range, and the range is wide

Overall Veteran win rate by policy (n = 6,600 each): baseline 63.9 percent [63, 65], economy turtle 66.4 percent [65, 68], Nemesis hunter 59.6 percent [58, 61], rusher 36.8 percent [36, 38]. The spread between the best and worst documented policy is 29.6 points. The first report's caveat is now measured fact: any run win rate cited without its campaign policy named is not a property of the game.

Win rate range per faction across the four policies:

| Faction | Low (policy) | High (policy) | Range |
|---|---|---|---|
| Chorus | 43.5% (rusher) | 85.8% (turtle) | 42.3 pp |
| Ashfall Hullbreakers (corsair) | 27.6% (rusher) | 68.4% (turtle) | 40.8 pp |
| Eclipse (deathless) | 37.6% (rusher) | 71.0% (turtle) | 33.4 pp |
| Hegemony | 43.5% (rusher) | 65.7% (turtle) | 22.2 pp |
| Glasswrights (ithar) | 35.1% (rusher) | 56.2% (baseline) | 21.1 pp |
| Sunward Crusade (voidsworn) | 33.4% (rusher) | 51.7% (turtle) | 18.3 pp |

The control arm validates the harness against the first program: on fresh seeds the baseline policy reproduces the first report's per-faction Veteran rates within 2 points everywhere (Chorus 85.0 vs 85.0, Eclipse 69.6 vs 68.0, Hullbreakers 62.3 vs 61.0, Hegemony 60.6 vs 61.0, Glasswrights 56.2 vs 55.0, Sunward 49.8 vs 50.0; pooled 63.9 vs 63.0).

## The four policies, in full

Shared by all four: the battle pilot is the game's own simulator bot (sim3d.js), untouched, so battle play is comparable with the first program and with wave 3. Profiles differ only in campaign-layer decisions. Aspect picks, prize, salvage, relic, perk and module reward picks, and faction-verb use keep the baseline rules in every profile. Every run starts from a fresh profile (no LEGACY unlocks, no mastery, no banked favour), exactly as in the first program.

Baseline (the first report's policy, rerun as the control arm). Node routing: score by node type (elite 50, boss 45, battle 32, shipyard 26 plus 8 when credits exceed 180, event 20, drydock and field 14), with a damage override (at fleet hull under about 55 percent, drydock +120, field +100, shipyard +90, elite -25) and reward bonuses (boon nodes for patrons with fewer than 2 boons held, repair rewards when damaged). Boon picks: rarity-weighted score over the boon's scaled fx, duo +2, legendary +4; decline only when every offered boon is useless to the fleet kit; never reroll. Shipyard: repair all first; buy the highest-CP fitting stock hulls keeping a 40 credit floor; buy stock modules keeping a 120 credit reserve and auto-fit each; Mk upgrades flagship first keeping a 250 credit reserve; never sell. Event options score by a stated value function (credits, xp, heals scaled by missing hull, relic, module, ship joins, intel positive; costs, damage, payRelic, payXp, payMod negative; fight options only at fleet hull 70 percent or better).

Rusher. Objective: reach sector bosses by the shortest path and spend as little time and as few fights getting there as the map allows. (Sector maps are 7 columns and every column before the boss holds a fight, so shortest path means avoiding optional fights, not fewer columns.) Node routing: boss 1000. Non-fight nodes outrank fights (event 100, field 90, drydock 80, shipyard 70 over battle 30, elite 10; a forced fight takes a plain battle over an elite). Two overrides: at fleet hull under 50 percent, repair stops outrank everything but the boss (drydock 300, field 280, shipyard 260); and a shipyard detour scores 300 only when the fleet is below its peak size this run, that is, only to replace a loss. Shipyard: repair all first; buy stock hulls (highest CP first) only until fleet size returns to the run's peak, spending to a 0 credit floor; no modules, no Mk upgrades, never sell. Events: leave fast. The scorer keeps credits, xp and heals and heavily penalizes anything that costs time or hull: fight options -10000, costs at 20x face value, damage at 400 to 600 per point of fleet fraction, payRelic -200, payXp -60, payMod and loseMod -80. Boon picks keep the baseline rule (boons are free power and cost no time). Battles fought per run: 7.0, against the baseline's 11.0. That gap is the profile in one number.

Economy turtle. Objective: maximal credit routing and conversion; arrive at every yard rich and leave it empty. Node routing: credit-reward nodes +60; event 34, shipyard 30 plus 25 when credits reach 150, battle 30, elite 38, boss 45, drydock and field 15; damage override at missing hull over 30 percent (drydock +120, field +100, shipyard +90, elite -25). Events: net credits dominate at 10x weight; a free ship is worth 150, relic 40, upgrade 30, module 20; fight options score +20 at fleet hull 60 percent or better and -500 below that; damage and pay options penalized as baseline. Shipyard: repair all first; buy stock hulls to the CP cap with a 0 credit floor; buy every affordable stock module and auto-fit; Mk upgrades for every ship, flagship first, with a 0 credit floor; never sell. Boon picks keep the baseline rule.

Nemesis hunter. Objective: meet him early and often, know him, and build to kill him. Node routing: fight nodes first (elite 60, battle 55, boss 45, event 30, shipyard 18, drydock and field 12), plus 200 for any node nemNodeIs flags as his (a fight node in the last 3 columns, or any fight node while a strike is pending), so the meeting is taken at the first converted node rather than the clock's schedule; damage override at missing hull over 45 percent. Events: intel first (nemIntel +500), clock second (nemClock +150 per point, so options that delay him score negative), then baseline value with xp doubled; fight options +80 at fleet hull 55 percent or better, -100 below. Boon picks: the baseline scorer plus 100 for the anti-Nemesis set, defined by the chair as boons that concentrate fire on one priority hull or kill a flagship outright, which is what a Nemesis fight turns on: a_mark (marks one ship for the whole fleet), L_star (lances always hit and pierce shields), a_lance, a_aim, a_crit (lance damage, aim, crit), d_hunter (crits after long moves), e_hunt (damage scaling against a burning target). Shipyard keeps the baseline rule unchanged, to isolate the routing, event and boon effects.

## Win rates, sector reach

Win rate by faction by policy (n = 1,100 per cell, Wilson 95 percent CI):

| Faction | Baseline | Rusher | Turtle | Hunter |
|---|---|---|---|---|
| Chorus | 85.0% [83, 87] | 43.5% [41, 46] | 85.8% [84, 88] | 81.9% [80, 84] |
| Eclipse | 69.6% [67, 72] | 37.6% [35, 41] | 71.0% [68, 74] | 63.0% [60, 66] |
| Hullbreakers | 62.3% [59, 65] | 27.6% [25, 30] | 68.4% [66, 71] | 59.8% [57, 63] |
| Hegemony | 60.6% [58, 63] | 43.5% [41, 46] | 65.7% [63, 68] | 55.2% [52, 58] |
| Glasswrights | 56.2% [53, 59] | 35.1% [32, 38] | 55.7% [53, 59] | 52.6% [50, 56] |
| Sunward Crusade | 49.8% [47, 53] | 33.4% [31, 36] | 51.7% [49, 55] | 44.9% [42, 48] |

Paired per-seed deltas against the baseline control arm (same 1,100 seeds; positive means the profile wins more of the identical seeds):

| Faction | Rusher | Turtle | Hunter |
|---|---|---|---|
| Chorus | -41.5 pp [-45.7, -37.4] | +0.8 pp [-1.6, +3.3] | -3.1 pp [-5.1, -1.1] |
| Eclipse | -32.0 pp [-36.0, -28.0] | +1.4 pp [-1.7, +4.4] | -6.6 pp [-9.1, -4.2] |
| Hullbreakers | -34.6 pp [-38.7, -30.6] | +6.1 pp [+2.8, +9.4] | -2.5 pp [-4.9, 0.0] |
| Hegemony | -17.1 pp [-20.8, -13.4] | +5.2 pp [+1.8, +8.6] | -5.4 pp [-8.0, -2.7] |
| Glasswrights | -21.1 pp [-24.8, -17.4] | -0.4 pp [-3.7, +2.8] | -3.5 pp [-6.2, -0.9] |
| Sunward Crusade | -16.4 pp [-20.0, -12.9] | +1.9 pp [-1.3, +5.1] | -4.9 pp [-7.2, -2.6] |

Sector reach (percent of runs reaching the sector):

| Faction | Baseline S2 / S3 | Rusher S2 / S3 | Turtle S2 / S3 | Hunter S2 / S3 |
|---|---|---|---|---|
| Chorus | 92.7 / 87.4 | 89.2 / 61.0 | 94.0 / 88.6 | 91.4 / 84.6 |
| Eclipse | 85.9 / 73.0 | 86.9 / 56.4 | 89.5 / 76.2 | 81.6 / 66.9 |
| Hullbreakers | 82.1 / 68.3 | 82.1 / 46.5 | 88.6 / 75.4 | 80.5 / 65.5 |
| Hegemony | 81.5 / 67.3 | 85.5 / 58.8 | 87.7 / 71.5 | 80.5 / 62.8 |
| Glasswrights | 80.5 / 63.3 | 82.0 / 51.6 | 83.1 / 64.8 | 78.9 / 60.6 |
| Sunward Crusade | 70.5 / 53.6 | 75.6 / 48.3 | 78.2 / 57.9 | 67.8 / 50.5 |

The rusher's shape is diagnostic: it reaches sector 2 as often as or more often than the baseline in five of six factions (it rushes, and sector 1 is survivable underfed), then collapses in sector 3, where the skipped fights were the power curve. The losses are not navigation losses. They are starvation losses, booked in the last sector.

The turtle is worth less than its design promises: +2.5 points overall, significant only for Hullbreakers (+6.1) and Hegemony (+5.2), noise elsewhere. Aggressive credit conversion buys real power, but the baseline policy was already converting most of what the yards offer; the remaining headroom is small. The hunter pays for its obsession: -4.3 points overall, negative in all six factions, significant in five. Taking his meetings at the first converted node and spending event picks on intel costs more run than the intel returns, at least as this pilot values the trade.

## Nemesis meeting outcomes

Player win rate by meeting number (pooled across factions):

| Policy | Meeting 1 | Meeting 2 | Meeting 3 |
|---|---|---|---|
| Baseline | 86.8% [86, 88] (n 6,249) | 91.0% [90, 92] (n 4,835) | 94.4% [93, 95] (n 2,322) |
| Rusher | 79.8% [79, 81] (n 5,877) | 73.1% [71, 75] (n 2,787) | 79.9% [76, 83] (n 472) |
| Turtle | 88.9% [88, 90] (n 6,326) | 89.1% [88, 90] (n 5,005) | 94.2% [93, 95] (n 2,037) |
| Hunter | 85.4% [85, 86] (n 6,220) | 89.0% [88, 90] (n 4,694) | 94.3% [93, 95] (n 2,276) |

Player win rate in Nemesis fights by adaptations he carries in (pooled):

| Policy | 0 adaptations | 1 adaptation | 2 or more |
|---|---|---|---|
| Baseline | 85.9% (n 5,029) | 89.9% (n 3,998) | 93.7% (n 4,379) |
| Rusher | 83.4% (n 3,458) | 73.6% (n 3,246) | 75.1% (n 2,432) |
| Turtle | 88.2% (n 4,774) | 88.6% (n 4,095) | 92.5% (n 4,499) |
| Hunter | 84.5% (n 5,066) | 88.9% (n 3,898) | 92.2% (n 4,226) |

Meetings per run by faction (baseline / rusher / turtle / hunter): Chorus 2.30 / 1.48 / 2.21 / 2.27; Hullbreakers 2.26 / 1.47 / 2.26 / 2.21; Eclipse 2.10 / 1.45 / 2.08 / 2.06; Hegemony 1.96 / 1.39 / 1.99 / 1.92; Glasswrights 1.92 / 1.32 / 1.89 / 1.90; Sunward 1.64 / 1.19 / 1.73 / 1.64. Two surprises here. The hunter barely meets him more often than the baseline (its +200 node bonus mostly fires on nodes the baseline was taking anyway; the clock is battle-driven, and the hunter fights the same number of battles). And the rusher meets him less, not more, despite rushing: fewer battles means a slower clock, and its runs die before the later meetings. Adaptations carried into meeting 1 average 0.20 (baseline), 0.26 (turtle), 0.19 (hunter), but 0.48 for the rusher, whose clock strikes land on a thinner run. Weakness reveals stay front-loaded under every policy: gains per meeting average about 1.30 to 1.42 at meeting 1, 0.34 to 0.42 at meeting 2, and 0.01 to 0.03 at meeting 3.

The rusher rows are the analytic prize of this extension. Under the three engaged policies the first report's pattern holds exactly: he gets easier to beat as meetings and adaptations accumulate. Under the rusher the sign flips. At 1 adaptation the rusher's Nemesis win rate is 73.6 percent against 83.4 percent at 0, a cost of about 10 points, and meeting 2 (73.1 percent) is his most dangerous meeting, not his easiest. The first report explained the baseline pattern as a confound: adaptation count proxies for run progress, and campaign power growth outruns his capped adaptations. The rusher breaks the proxy by holding fleet growth near zero, and underneath it the adaptation system does visible, real work, consistent with the isolated-battle measurement (an adaptation step worth about 14.6 points in sector 2 at fixed fleets, from the wave 5 measurements). No-snowball is therefore a statement about engaged play, not about the adaptation mechanic: the mechanic bites, and growth outruns it.

## Economy and the regroup question

Regroup binding under the first report's operationalization (shipyard arrival with the fleet missing at least 25 percent of max hull AND credits below full repair cost plus the cheapest useful purchase):

| Policy | Yard visits | Binding visits | Bind rate | Median purse | Median worst-ship missing HP |
|---|---|---|---|---|---|
| Baseline | 24,297 | 95 | 0.4% | 378 | 0 |
| Rusher | 27,481 | 57 | 0.2% | 417 | 0 |
| Turtle | 29,893 | 321 | 1.1% | 276 | 1 |
| Hunter | 21,872 | 65 | 0.3% | 398 | 0 |

Spend shares replicate the first report under the baseline (hulls 71.0 percent, modules 20.0, repairs 4.1, Mk 4.9; first report: 70 / 21 / 4 / 5). The turtle manufactures the most yard visits and the lowest median purse (it spends to zero by design) and still binds only 1.1 percent of arrivals; its worst faction, the Sunward Crusade, reaches 1.9 percent. The rusher's repair share of spend rises to 10.6 percent (hulls 89.4, modules and Mk zero by design) because replacement hulls and patches are all it buys, and it binds least of all: it arrives damaged less often than it arrives poor, and the shipped repair price is low enough that poor is rarely binding. Across four policies and, counting the Oct 29 model, three methods, the repair-versus-buy tension does not bind at shipped values. Ryan's accept-as-is ruling is reinforced, not revisited.

## Utilization flags under changed pick behavior

Pick rates (picked as a share of offered) for the first report's trap-flag boons:

| Boon | Baseline | Rusher | Turtle | Hunter |
|---|---|---|---|---|
| e_spread | 0.7% (15 of 2,237) | 0.2% (2 of 854) | 0.5% (11 of 2,130) | 0.6% (14 of 2,182) |
| a_mark | 2.9% (102 of 3,516) | 1.2% (21 of 1,785) | 2.4% (72 of 3,066) | 31.1% (847 of 2,728) |
| s_regen | 3.0% (119 of 3,949) | 2.6% (55 of 2,121) | 3.2% (113 of 3,581) | 3.3% (132 of 3,997) |
| s_ion | 3.2% | 2.3% | 3.0% | 3.8% |
| i_plate | 3.9% | 3.8% | 3.8% | 4.2% |
| r_shock | 3.6% | 3.0% | 3.9% | 3.5% |

e_spread and s_regen are policy-robust flags: no pick philosophy tested takes them (the hunter's set does not include them, and the turtle and rusher scorers, which revalue everything else, leave them at the bottom too). a_mark is the exception, and it is an honest one: the hunter takes it 31.1 percent of the time because the chair's anti-Nemesis definition puts it in the +100 set. That does not vindicate a_mark's power (the hunter's whole package costs 4.3 points of win rate, and no single boon's contribution can be isolated from these data), but it does refile the flag: a_mark is dominated under fx-value pick rules and has a coherent focus-fire use that a value heuristic cannot see. It belongs on the contested list, not the trap list. The other three near-bottom boons (s_ion, i_plate, r_shock) sit at 2 to 4 percent under every policy and keep their flag. Boon declines: 0 in all 26,400 runs under all four policies (55,945 baseline offer sets, 31,224 rusher, 51,120 turtle, 55,118 hunter). The all-three-useless decline case never fires, whatever the pilot.

## Per-admiral breakdown, baseline policy

Method: the first program's Veteran baseline shards (1,800 per faction) pooled with this extension's baseline control arm (1,100 per faction, fresh seeds), for 2,900 runs per faction and n of 724 to 726 per admiral. The two sources agree: pooled rates sit within 2.6 points of the first-program-only rates for every admiral, so the pool is reported as one table. No cell is too small to read (the smallest Nemesis fight count is 928). Attrition is ships lost per battle, the cleaner read; ships lost per run is confounded by run length and is not tabulated.

| Faction | Admiral | n | Win rate | Reach S3 | Lost / battle | Battles / run | Nemesis win |
|---|---|---|---|---|---|---|---|
| Sunward Crusade | thale | 724 | 77.8% [75, 81] | 81.6% | 0.43 | 12.2 | 87.2% |
| Sunward Crusade | vex | 726 | 55.5% [52, 59] | 61.2% | 0.49 | 10.4 | 88.3% |
| Sunward Crusade | ashgrove | 724 | 37.3% [34, 41] | 43.2% | 0.53 | 8.9 | 81.6% |
| Sunward Crusade | malek | 726 | 29.5% [26, 33] | 34.2% | 0.75 | 7.9 | 78.0% |
| Hullbreakers | vesh | 725 | 78.8% [76, 82] | 83.6% | 0.47 | 12.2 | 92.6% |
| Hullbreakers | mott | 725 | 61.5% [58, 65] | 70.5% | 0.50 | 11.3 | 91.7% |
| Hullbreakers | grax | 725 | 57.2% [54, 61] | 60.6% | 0.41 | 10.2 | 92.3% |
| Hullbreakers | sable | 725 | 48.7% [45, 52] | 53.0% | 0.64 | 9.6 | 90.9% |
| Eclipse | nekhet | 725 | 79.6% [77, 82] | 83.9% | 0.23 | 12.2 | 90.9% |
| Eclipse | anuket | 725 | 71.3% [68, 74] | 75.0% | 0.31 | 11.5 | 92.9% |
| Eclipse | sekhmar | 725 | 62.5% [59, 66] | 66.6% | 0.39 | 10.9 | 87.5% |
| Eclipse | khepra | 725 | 60.0% [56, 64] | 64.0% | 0.34 | 10.7 | 88.3% |
| Hegemony | reyes | 725 | 68.8% [65, 72] | 73.5% | 0.41 | 11.4 | 90.2% |
| Hegemony | kassar | 725 | 68.3% [65, 72] | 73.9% | 0.40 | 11.5 | 90.5% |
| Hegemony | maren | 725 | 60.4% [57, 64] | 69.4% | 0.48 | 11.1 | 80.5% |
| Hegemony | vorn | 725 | 46.6% [43, 50] | 53.0% | 0.59 | 9.7 | 84.4% |
| Glasswrights | aelith | 726 | 72.2% [69, 75] | 78.8% | 0.37 | 12.0 | 90.0% |
| Glasswrights | vaelen | 726 | 65.8% [62, 69] | 72.0% | 0.36 | 11.5 | 91.7% |
| Glasswrights | mirelle | 724 | 47.1% [43, 51] | 54.3% | 0.52 | 10.1 | 84.6% |
| Glasswrights | thorne | 724 | 37.4% [34, 41] | 46.1% | 0.62 | 9.4 | 85.0% |
| Chorus | mending | 725 | 87.2% [85, 89] | 89.0% | 0.41 | 12.6 | 94.5% |
| Chorus | matriarch | 725 | 84.5% [82, 87] | 87.2% | 0.39 | 12.5 | 94.5% |
| Chorus | razormaw | 725 | 84.5% [82, 87] | 86.8% | 0.35 | 12.4 | 95.8% |
| Chorus | voice | 725 | 84.0% [81, 86] | 86.9% | 0.37 | 12.4 | 94.6% |

The admiral layer is bigger than the faction layer. The spread inside the Sunward Crusade (29.5 to 77.8 percent, 48.3 points) exceeds the spread between faction means under the baseline (35.2 points), and Glasswrights (34.8 points inside) and Hullbreakers (30.1) are close behind. Only Chorus is admiral-proof (84.0 to 87.2, a 3.2 point spread at the ceiling) and Eclipse has both the highest floor (khepra, 60.0) and the lowest attrition in the game (0.23 to 0.39 ships lost per battle, the reanimate economy showing up in the admiral table).

Outliers worth Opus's eye, in order:

1. malek (Sunward) is the weakest admiral cell in the game at 29.5 percent, and the manner of it matters: the worst attrition in the table (0.75 ships lost per battle; the next worst is sable at 0.64) and the fewest battles per run (7.9). His runs do not stall, they bleed out early. Whatever his kit is priced as, the bot cannot keep his fleet alive long enough to use it.
2. thale (Sunward) at 77.8 percent plays 28 points above his own faction's pooled mean and level with the best admirals of the strongest factions. The same faction holding both the game's near-best and outright-worst admiral is the single largest balance fact in this table.
3. thorne (Glasswrights, 37.4 percent) and ashgrove (Sunward, 37.3) are the other two sub-40 cells, both with attrition above 0.5 per battle. vorn (Hegemony, 46.6) is the weakest admiral of a mid faction and the only Hegemony cell below 60.
4. nekhet (79.6), vesh (78.8) and thale (77.8) are the top three. None is a Chorus admiral; Chorus wins on uniformity, not on a star.
5. maren (Hegemony) is a Nemesis-specific dip: a respectable 60.4 percent overall but an 80.5 percent Nemesis win rate against 90.2 and 90.5 for reyes and kassar on similar fight counts. Narrow, but it is the largest within-faction Nemesis gap outside the Sunward spread.

## Synthesis: what survives a change of pilot

Policy-robust (hold under every profile tested):

1. The regroup conclusion. Binding stays at 0.2 to 1.1 percent of yard visits across four policies that include one designed to maximize yard pressure. With the Oct 29 model and the first Monte Carlo, that is three methods and five pilots. Closed.
2. The faction ordering under engaged play. Baseline, turtle and hunter produce the identical ordering (Chorus, Eclipse, Hullbreakers, Hegemony, Glasswrights, Sunward) and a spread of 34.1 to 37.0 points. Any policy that plays the campaign economy gets this ordering.
3. The trap flags on e_spread and s_regen (0.2 to 0.7 percent and 2.6 to 3.3 percent pick rates under every scorer), the near-bottom status of s_ion, i_plate and r_shock, and the never-firing boon decline (0 in 26,400 runs).
4. Weakness reveals are front-loaded (about 1.3 to 1.4 gained at meeting 1, about 0.02 at meeting 3) under every policy, including the one that hunts intel. There is no late-game intel economy to balance; the reveal system lives and dies at meeting 1.
5. The baseline numbers themselves. The control arm reproduced the first report within 2 points per faction on fresh seeds, and the pooled per-admiral table agrees with the first program's slice within 2.6 points per admiral. The first report's measurements are stable, not seed luck.

Policy-fragile (move materially by profile):

1. The absolute win rate, decisively: 36.8 to 66.4 percent overall across documented policies, and up to 42.3 points within a single faction (Chorus). The first report's retirement of the 20 percent figure stands, and this extension adds the corollary: no replacement single number exists. Quote the range and name the policy.
2. The faction spread and ordering at the starvation extreme. The rusher compresses the spread to 15.9 points and reorders the table (Hegemony and Chorus tied at the top, Hullbreakers last). Chorus is the most policy-fragile faction in the game: first by about 15 points under every engaged policy, tied-first and 42 points off its own ceiling under the rusher. Its strength is growth-dependent; skip the fights that feed the growth and the dominance goes with them. Hullbreakers are the second most fragile (68.4 turtle to 27.6 rusher).
3. The no-snowball Nemesis result, as a conditional. It holds under the three engaged policies and reverses under the rusher, where adaptations cost about 10 points of Nemesis win rate instead of correlating with easier fights. Read together, the two results are stronger than either alone: adaptations work, and engaged campaign growth outruns them. A design that wants him dangerous to engaged players cannot get there by raising adaptation counts alone, because engaged growth is the thing beating them; it needs the fit-scale lever the first report named.
4. The a_mark trap flag. It is a property of fx-value pick rules (1.2 to 2.9 percent) and not of the boon under a focus-fire philosophy (31.1 percent). Refiled as contested in the section above.
5. Sector 3 reach as the policy separator. Sector 2 reach is nearly policy-invariant (the rusher reaches it at least as often as the baseline in five of six factions); everything a campaign policy is worth shows up in sector 3 reach and in the final win rate. Evaluations of future policy or tuning changes should read S3 reach first.

## Method, determinism, and limits

The harness, approximations and timeout treatment are the first report's, unchanged; policies.js gates every override on the run's policy field and the baseline path calls the driver's original functions untouched. Pre-batch validation, recorded when the profiles were built: the baseline passthrough reproduced the first program's Chorus shard exactly (30 of 30 traces identical under canonical deep-compare, seeds 10000, Veteran); the rusher was deterministic 10 of 10 across two independent processes. Post-batch spot checks for this report: rusher (hegemony, n = 12, seed 777000) reproduced 12 of 12 traces identically across two processes; hunter (corsair, n = 12, seed 888000) reproduced 3 of 12 traces byte-identically and 12 of 12 on run outcome and sector reached, with the divergence localized to the salvage tow-eligibility flag, a field the first report already flagged as sensitive to async stub timing, cascading into a different trajectory in 2 of the 12 runs. That is the known trace-level caveat operating at trace level; the aggregate-level check is the control arm's replication of the first program (within 2 points per faction at n = 1,100), and it passes. Two batch queues ran in parallel under load, which is precisely the condition the caveat names; intervals at n = 1,100 absorb it, and the paired-seed design means any residual timing noise is shared across arms rather than biasing one policy.

Limits, stated once: all four policies are chair-built heuristics over the shipped campaign layer, not human play and not optimal play; the hunter's anti-Nemesis set is a chair definition (stated in full above) and a different set would move its boon numbers; per-admiral Nemesis win rates pool all meetings and inherit the meeting-mix of each admiral's runs. Nothing here measures a human first run.

Files: policies.js (profile definitions, commented to match this report), shard.js runs (24 shards in raw/, named pol_<policy>_<faction>.json with seed blocks in each file's meta), aggregate_profiles.js and profiles_aggregate.json (every number cited), run_queue1.sh and run_queue2.sh (batch drivers). Total runs executed for this extension, including validation and spot checks: 26,400 batch runs, plus about 100 validation and determinism runs.
