# Sims evidence pack: CP asymmetry and repair rate (Oct 29 program follow-up)

Chair evidence pack, Rey leg. Code pin 264f441d, clone at ~/workspace/voidsworn-fresh. Every number below comes from an actual run of the scripts described in the method section; nothing is estimated by hand. This pack serves two designer rulings already on the record: (1) Eclipse ships stronger but more expensive, Chorus the opposite, faction appropriate across the board, with the 20-ship figure never a hard cap, especially for swarm factions; (2) repair must always beat scrap-and-replace per ship, and the economy tradeoff Ryan intends is budget allocation under scarcity (repair the damaged ship vs spend the same credits on a new ship and sail with a vulnerable one).

## Method

Pass 1 route: the game's own code, loaded headlessly in node. data.js was loaded whole into a vm context (it loads clean). From battle.js, three blocks were extracted verbatim by string slice and evaluated unmodified: the RAMP table, effArch, and genEnemyFleet itself. The baseline therefore runs the shipped function, not a reimplementation. Stubs: RUN undefined (so the fleetPower budget feedback is skipped and the board ceiling uses the function's own no-RUN default of a 4-ship player fleet), AI_LEVEL undefined (no Standard discount), heatOn false, mod undefined. Cells: kind 'normal', arch null, col drawn uniform 0 to 6 (the sector map has 7 columns), 4,000 fleets per faction per sector per model.

Pass 1 counterfactuals route: a parameterized clone of the fill loop, transcribed line by line from the extracted source (same budget formula, same weight formula, same guard, same +.3 affordability slack). The clone was validated against the real function in baseline configuration before any counterfactual ran: across all 18 faction-sector cells, mean CP spent agreed within 0.12 CP and mean hull count within 0.03 hulls (worst cell: deathless sector 2, spent 14.90 real vs 15.02 clone). Differences of that size are sampling noise at n=4,000. Model B and Model C numbers come from the validated clone.

Pass 2 route: tables extracted from the loaded data.js (hull costs after the FAC_PRICE pass, exactly as the game computes them), economy formulas transcribed from campaign_run.js, campaign3d.js and core.js with sites cited, and a Monte Carlo (20,000 simulated runs, 60,000 regroups) written for this pack. The scrap-and-replace check in Pass 2 is not a simulation: it is the repair inequality evaluated exactly for every priced hull in HULLS.

Definitions used in Pass 1. Budget B0: the CP budget genEnemyFleet computes for the cell before the fill loop (sector base [4.2, 9.5, 14] plus col term, times RAMP.grow). Spent: CP actually deducted by the loop. Stranded: B0 minus spent, i.e. budget left when the loop exits. Mix: share of generated hulls by the hull's own CP class (1, 2, 3, 4, 5+), so mix is comparable across models even when a model re-prices the classes.

## Pass 1: CP asymmetry

### Baseline, as shipped (real genEnemyFleet)

| Faction : sector | Budget | Spent | Stranded | Hulls | Mix % (1/2/3/4/5+) |
|---|---|---|---|---|---|
| voidsworn : 1 | 8.27 | 7.91 | 0.37 (4.4%) | 4.31 | 43/42/7/5/3 |
| voidsworn : 2 | 15.48 | 15.06 | 0.41 (2.7%) | 7.27 | 32/46/9/7/5 |
| voidsworn : 3 | 21.70 | 21.28 | 0.41 (1.9%) | 10.24 | 32/48/8/7/6 |
| hegemony : 1 | 8.32 | 7.88 | 0.44 (5.3%) | 4.49 | 46/46/0/5/3 |
| hegemony : 2 | 15.52 | 15.04 | 0.48 (3.1%) | 7.48 | 36/51/0/8/5 |
| hegemony : 3 | 21.86 | 21.43 | 0.42 (1.9%) | 10.54 | 34/53/0/8/6 |
| corsair : 1 | 8.30 | 7.89 | 0.41 (4.9%) | 4.54 | 44/44/7/5/0 |
| corsair : 2 | 15.54 | 15.07 | 0.47 (3.0%) | 7.82 | 34/48/10/8/0 |
| corsair : 3 | 21.84 | 21.42 | 0.42 (1.9%) | 11.17 | 33/51/9/8/0 |
| chorus : 1 | 8.24 | 7.84 | 0.40 (4.8%) | 4.50 | 44/45/8/0/4 |
| chorus : 2 | 15.49 | 15.01 | 0.47 (3.1%) | 7.71 | 35/49/10/0/6 |
| chorus : 3 | 21.77 | 21.35 | 0.42 (1.9%) | 10.96 | 33/52/9/0/6 |
| ithar : 1 | 8.30 | 7.87 | 0.43 (5.2%) | 4.48 | 46/45/0/5/4 |
| ithar : 2 | 15.45 | 14.98 | 0.46 (3.0%) | 7.48 | 35/50/0/8/7 |
| ithar : 3 | 21.87 | 21.45 | 0.43 (1.9%) | 10.65 | 34/52/0/8/7 |
| deathless : 1 | 8.26 | 7.80 | 0.46 (5.5%) | 4.71 | 46/49/0/6/0 |
| deathless : 2 | 15.50 | 14.90 | 0.60 (3.9%) | 8.22 | 36/55/0/9/0 |
| deathless : 3 | 21.78 | 21.35 | 0.43 (2.0%) | 11.77 | 35/57/0/8/0 |

Baseline facts the models have to answer to:

1. Stranding is small everywhere (0.37 to 0.60 CP, under 6% of budget). At shipped numbers the fill loop is not wasteful; Argon's stranded-budget concern is a property of the counterfactual models, not of the baseline.
2. Every faction fields nearly the same fleet: 4.3 to 4.7 hulls in sector 1, 10.2 to 11.8 in sector 3, with near-identical class mixes. CP expresses no faction shape at all today, which is the audit finding restated in numbers.
3. The board ceiling already binds before the budget does in early sectors. Measured exit reasons (clone, baseline config): the loop exits on the ceiling in 27% of chorus sector 1 fleets, 17% of chorus sector 2, 32% of deathless sector 1 and 27% of deathless sector 2. Sector 3 is budget-bound (1 to 3% ceiling exits). Any Chorus model that adds purchasing power without touching the ceiling strands its gains in sectors 1 and 2.

### Model B: budget multiplier (DeepSeek's shape)

Modeling, stated exactly: hull CP costs are unchanged. The Eclipse (deathless) budget is divided by 1.5 before the loop, so each hull's CP costs 1.5 budget units of purchasing power. The Chorus budget is divided by 0.7 (multiplied by about 1.43). Other factions are untouched by this model and match baseline.

| Faction : sector | Eff. budget | Spent | Stranded | Hulls | Mix % (1/2/3/4/5+) |
|---|---|---|---|---|---|
| deathless : 1 | 5.53 | 5.09 | 0.44 (8.0%) | 3.27 | 52/45/0/4/0 |
| deathless : 2 | 10.38 | 9.90 | 0.48 (4.6%) | 5.73 | 41/52/0/7/0 |
| deathless : 3 | 14.54 | 14.05 | 0.49 (3.4%) | 8.07 | 39/54/0/7/0 |
| chorus : 1 | 11.77 | 10.23 | 1.54 (13.1%) | 5.30 | 35/50/9/0/6 |
| chorus : 2 | 22.10 | 19.62 | 2.47 (11.2%) | 9.39 | 29/51/12/0/9 |
| chorus : 3 | 31.09 | 29.77 | 1.32 (4.2%) | 14.62 | 30/52/10/0/8 |

Read: on the Eclipse side the multiplier works as intended (hull counts fall 31% in sector 3, from 11.77 to 8.07, with modest stranding). On the Chorus side it collides with the ceiling: ceiling exits jump to 59% (sector 1), 68% (sector 2) and 49% (sector 3) of fleets, and 11 to 13% of the enlarged budget strands unspent in sectors 1 and 2. The extra money cannot become ships because there is no room on the board as the ceiling is computed.

### Model C: integer ladder (Argon's shape) and the Chorus ceiling

Eclipse mapping, documented: the leg's ladder 2-3-5-7 is mapped onto classes by rung, Frigate 2, Destroyer 3, Cruiser 5, Battleship 7. The Eclipse roster's actual hulls re-price as d_scythe (Frigate) 1 to 2, d_jackal (Destroyer) 2 to 3, d_harvester (Cruiser) 4 to 5. (The roster has no cp3 hull, so the 3 to 5 step in the raw mapping question does not arise; the class-rung mapping is the faithful reading.) Spent below is in ladder CP; mix is still reported by original class so it stays comparable.

Chorus choice, documented: of the two options offered, the ceiling raise is the faithful one, and the down-ladder was also run as a sensitivity so the choice is evidenced rather than asserted. Chorus hull CP is unchanged; the fleet list cap rises by 4 (ceiling+4). The down-ladder variant (Destroyer 2 to 1, Cruiser 3 to 2, Carrier 5 to 4) appears in the sensitivity row.

| Faction : sector | Budget | Spent | Stranded | Hulls | Mix % (1/2/3/4/5+) |
|---|---|---|---|---|---|
| deathless ladder : 1 | 8.28 | 7.59 | 0.69 (8.4%) | 2.90 | 50/45/0/6/0 |
| deathless ladder : 2 | 15.53 | 15.03 | 0.50 (3.2%) | 5.44 | 40/51/0/8/0 |
| deathless ladder : 3 | 21.89 | 21.25 | 0.64 (2.9%) | 7.64 | 37/55/0/8/0 |
| chorus ceiling+4 : 1 | 8.35 | 8.07 | 0.29 (3.4%) | 4.66 | 45/44/7/0/4 |
| chorus ceiling+4 : 2 | 15.48 | 15.12 | 0.35 (2.3%) | 7.80 | 35/49/10/0/6 |
| chorus ceiling+4 : 3 | 21.85 | 21.42 | 0.43 (2.0%) | 10.99 | 33/52/9/0/7 |
| chorus down-ladder (sens.) : 1 | 8.25 | 6.84 | 1.41 (17.1%) | 5.47 | 30/55/10/0/5 |
| chorus down-ladder (sens.) : 2 | 15.49 | 13.00 | 2.50 (16.1%) | 9.52 | 26/53/12/0/8 |
| chorus down-ladder (sens.) : 3 | 21.80 | 19.81 | 1.99 (9.1%) | 14.89 | 27/56/10/0/8 |

Read: the ladder cuts Eclipse hulls harder than the multiplier (sector 3: 7.64 vs 8.07; sector 1: 2.90, a very thin fleet against a sector 1 budget) and strands slightly more in sector 1 (8.4%). Its advantage is bookkeeping, not behavior: costs stay integers everywhere they are read. The ceiling raise alone does almost nothing for Chorus (sector 3 hulls 10.99 vs 10.96 baseline), because sector 3 is budget-bound; it only clears the early-sector ceiling exits (to about 0%). The down-ladder produces hulls (14.89 in sector 3) but strands 9 to 17% of budget, mostly to ceiling exits (59 to 76% of fleets), and flattens the frigate/destroyer distinction the mix shows (cp1 share drops because destroyers now cost 1).

### The combination the tables point to

Because the Chorus failure in Model B is a ceiling failure, not a budget failure, the multiplier and the ceiling raise were also run together (budget divided by 0.7, list cap +4):

| Chorus mult + ceiling+4 | Eff. budget | Spent | Stranded | Hulls | Mix % |
|---|---|---|---|---|---|
| sector 1 | 11.87 | 11.46 | 0.41 (3.4%) | 6.10 | 37/49/9/0/5 |
| sector 2 | 22.14 | 21.55 | 0.59 (2.6%) | 10.65 | 32/50/11/0/8 |
| sector 3 | 31.05 | 30.86 | 0.20 (0.6%) | 15.38 | 31/52/9/0/8 |

Ceiling exits fall back to 4 to 12% of fleets and stranding returns to baseline levels, while hull counts rise 36 to 40% over baseline in every sector. This is the only Chorus configuration measured that converts the full discount into ships.

### Pass 1 conclusion

1. Eclipse side: the budget multiplier and the integer ladder both express "stronger but more expensive" with similar hull reductions (sector 3: 8.07 vs 7.64 hulls from an 11.77 baseline) and similar stranding (3.4% vs 2.9% in sector 3; the ladder is worse in sector 1, 8.4% stranded and a 2.90-hull mean fleet). The multiplier distorts the class mix least (cp1 share 39% vs the ladder's 37% in sector 3, both against a 35% baseline) and never rewrites a cost that other systems read. The ladder's only edge is integer bookkeeping. On these numbers the multiplier is the cleaner Eclipse mechanism; the ladder is a defensible second if Opus values integer CP elsewhere.
2. Chorus side: neither half works alone. The multiplier alone strands 11 to 13% of its enlarged budget against the ceiling in sectors 1 and 2; the ceiling alone adds nothing because sector 3 is budget-bound. Together they deliver the swarm: +36 to +40% hulls, baseline-level stranding, mix nearly unchanged from baseline (the swarm is more of the same ships, which is what a swarm should be). The down-ladder is dominated on every metric and also erases the frigate/destroyer price distinction; do not use it.
3. Cross-check against the ruling: Ryan's clarification that 20 was never a hard cap is exactly what the Chorus combination needs, since the measured ceiling here is the generator's own soft cap (RAMP.ceil minus the player fleet), and raising the Chorus list cap is an implementation of that clarification, not a fight against it.

## Pass 2: repair rate sweep

### The shipped numbers, from code

- Paid repair (campaign_run.js:198 and :199): cost = ceil(missing HP / 2 x priceMult()). At the base priceMult of 1 that is exactly 0.5 credits per missing HP. priceMult (core.js:227) is 0.85 with the wrights unlock, times 1.25 under the h_coffers Heat, times the sector condition price (1.2 under Scarcity, otherwise 1). So the shipped effective rate already ranges from about 0.43 to 0.75 depending on run state.
- Buying a hull (campaign_run.js:196): cost = round(HULLS cost x priceMult()). Hull costs as the game computes them (explicit costs where defined, else round((60cp+10)/5)x5, then the FAC_PRICE class multiplier at data.js:538 to 546): examples, warden 70, harrow 130, penitent 200, reliquary 260, cathedral 340, ascendant 520; chorus drone 45, spitter 100, razor 190, brood 370; deathless scythe 100, jackal 195, harvester 390.
- Scrap value (core.js:193 to 194): prizeScrap(tpl) = round(shipValue x 0.35), and shipValue is the hull's full cost regardless of its current HP. Decommissioning a ship at 1 HP therefore returns the same 35% as decommissioning it pristine (campaign_run.js:201 to 203). Net scrap-and-replace cost for a hull = buy price minus that 35%, i.e. 65% of cost at priceMult 1.
- Free healing stack: +15% of max HP to every survivor after every won battle (campaign3d.js, finishBattle); a 'repair' node reward patches +25% (campaign_run.js reward flow; node reward odds at core.js:191: normal nodes pay boon 62%, module 16%, credits 12%, repair 10%); a guaranteed rest stop before the boss (genSector, core.js:251: drydock full repair, field +20%, or a shipyard); +40% of max HP during the post-boss transit (campaign_run.js, afterBattle, scaled by repairMult). The drydock node repairs the whole fleet free.
- Income (rewardFlow, campaign_run.js): every won battle pays round((25 + 12 x sector + 3 x col) x kindMult x (1 + credPct + condition cred bonus)); kindMult is 1 normal, 1.6 elite, 3 boss; condition cred bonuses are 0, 0, +15%, +20%, +25% across the five sector conditions. A credit node pays 35 + 10 x sector. Salvage on a worked wreck pays round((10 + 9 x wreck CP) x 1 or 1.3) when the player takes credits (campaign_run.js:430). Event credit outcomes sit in the +20 to +80 range with some costing credits. Starting credits 120 (core.js:324).

### Part (b) first, because it caps everything: repair vs scrap-and-replace

Repair beats replacement for a ship at HP h exactly when rate x (maxHp - h) is less than 0.65 x cost. The worst case is h = 1. Evaluated exactly over every priced, non-squadron hull in HULLS (42 hulls including variants), the binding crossovers (the rate at which repair from 1 HP stops winning) are:

| Hull | Faction | Class | Cost | HP | Net replace (65%) | Repair wins while rate below |
|---|---|---|---|---|---|---|
| b_drone | chorus | Frigate | 45 | 46 | 29 | 0.64 |
| c_raider | corsair | Frigate | 55 | 46 | 36 | 0.80 |
| b_spitter | chorus | Destroyer | 100 | 82 | 65 | 0.80 |
| b_razor | chorus | Cruiser | 190 | 150 | 123 | 0.83 |
| ascendant | voidsworn | Dreadnought | 520 | 370 | 338 | 0.92 |
| warden | voidsworn | Frigate | 70 | 45 | 45 | 1.02 |

Full sweep result: at rate 0.5, repair from 1 HP beats scrap-and-replace for all 42 hulls. At 0.75, it fails for exactly one (b_drone). At 1.0 it fails for 9 hulls, at 1.25 for 31, at 1.5 for 33, and at 2.0 for 39 of 42. The asked-for worst case, most expensive hull at 1 HP: the ascendant repairs for rate x 369 against a net replacement of 338, so repair wins up to rate 0.92 and loses at 1.0 and above. Note what drives the failures: they are the cheap, high-HP hulls (Chorus above all), because scrap returns 35% of a low price while repair is billed per HP of a large hull. (Repair also keeps the ship's captain, Mark and fitted modules, which the raw credit comparison does not price; the comparison is therefore conservative against repair.)

So the ruling's first half, repair always wins per ship, holds unconditionally only at rates up to about 0.64, and holds for every hull a player is likely to weigh replacing (frigates and up in the player's own roster) up to about 0.8 to 1.0. Any rate at or above 1.0 silently repeals the ruling for the Chorus line and the ascendant.

### Part (a): the Monte Carlo

Model, with assumptions stated. Fleet: six Voidsworn hulls (warden, harrow, penitent, penitent, reliquary, harrow; HP 45 to 130), the kind of fleet the B2 ramp text describes (a small elite player fleet of 4 to 7). Path per sector: four normal battles and one elite (columns 1 to 4), one event node, the guaranteed rest stop (drydock full repair, field +20%, or shipyard, one third each), the boss (column 6), then the post-boss transit patch: a post-boss regroup in the shape of the Oct 28 Q11 ruling. Battle pay uses the shipped formula with the sector condition drawn from the five conditions; credit node at its shipped 12% of normal nodes; salvage credits taken in 55% of normal battles (the other times the player takes the module), wreck CP drawn from 2, 3, 3, 4; event outcome drawn from 0, 0, 20, 40, 40, 80 with a 20% chance of a 30 credit cost. Damage per ship per battle, as a fraction of max HP: 45% of draws lose 0 to 10%, 30% lose 10 to 30%, 18% lose 30 to 55%, 7% lose 55 to 85%; ships bottom out at 1 HP (the model conditions on reaching the regroup, so no ship is lost; losses would only shrink the repair bill). All shipped free healing is applied at its code sites. The balance evolves under a rate-independent policy (at each regroup the worst ship is repaired at the shipped 0.5 rate if affordable; nothing else is bought), and each sweep rate is scored against the balance snapshot at the same regroup, so rates are compared on identical runs. Categories per regroup, against the cheapest useful new hull: BOTH (balance covers full repair of the worst-damaged ship plus the new hull), ONLY ONE (balance covers at least one of the two but not both: the intended tension), NEITHER. Primary new-hull price 70 (warden, the cheapest roster hull); sensitivity at 130 (harrow). 20,000 runs, 60,000 regroups.

What the runs look like at the regroup:

| Sector | Median balance | 10th pct balance | Median worst-ship missing HP | 90th pct worst missing HP | Median total missing HP, whole fleet |
|---|---|---|---|---|---|
| 1 | 737 | 656 | 19 | 53 | 23 |
| 2 | 1466 | 1345 | 19 | 53 | 23 |
| 3 | 2317 | 2162 | 19 | 53 | 24 |

Regroup categories, all sectors pooled, cheapest hull 70:

| Repair rate | BOTH (no tension) | ONLY ONE (tension) | NEITHER |
|---|---|---|---|
| 0.5 (shipped) | 100.0% | 0.0% | 0.0% |
| 0.75 | 100.0% | 0.0% | 0.0% |
| 1.0 | 100.0% | 0.0% | 0.0% |
| 1.25 | 100.0% | 0.0% | 0.0% |
| 1.5 | 100.0% | 0.0% | 0.0% |
| 2.0 | 100.0% | 0.0% | 0.0% |

The sensitivity at a 130 credit hull is identical at every rate in the sweep (100.0% BOTH). Diagnostics beyond the sweep, same model: at rate 12 the tension share is still only 2.1% (hull 70) to 4.0% (hull 130). Adding a plausible 300 credits per sector of mid-run spending (modules, Mark upgrades) changes nothing at rates up to 4 (0.4% tension at rate 4, hull 130); at 500 credits per sector of side spending, tension reaches 5.0% at rate 2.0 and 19.4% at rate 6. For scale: the median full-fleet repair bill (repairAll over all six ships) is 0.8% of the median regroup balance at the shipped rate, 1.6% at rate 1, 3.2% at rate 2.

### Pass 2 conclusion

1. There is no rate in the swept range, and none anywhere near it, where the intended tension binds in 40 to 70% of regroups. The sweep's honest result is a negative: at every rate from 0.5 to 2.0 the player affords both, in 100.0% of 60,000 modeled regroups. The deliverable range the task asked for does not exist on this lever.
2. The reason is measured, and it is not primarily the repair rate. Two numbers do the work. First, the free-healing stack leaves almost nothing to repair: after six fights of 15% patches, a rest stop, and the 40% transit patch, the worst ship in the fleet is missing a median of 19 HP and the entire six-ship fleet is missing a median of 23 to 24 HP at the regroup. Second, battle pay is large against prices: a sector pays several hundred credits (median regroup balance 737 after sector 1 under a no-other-spending policy, and still about 440 after a 300-per-sector side spend), while the most expensive decision on the table, a new hull plus a worst-ship repair, costs 70 to 130 plus single digits to about 100. A per-HP rate cannot create scarcity against a 19 HP bill and a 700 credit purse; even rate 12 only reaches 2 to 4% tension.
3. The two halves of the ruling also squeeze the rate from the other side: above about 0.64 the cheapest Chorus hull stops obeying "repair always wins" at 1 HP, and at 1.0 nine hulls including the ascendant break it. So the admissible rate band under the ruling as stated is roughly 0.5 to 0.8, and inside that band the tension share is 0.0%. Raising the rate to buy tension spends the ruling's first half long before it buys any of the second.
4. Where the tension actually lives, on these numbers: the levers that can produce Ryan's repair-or-new-ship moment are the size of the repair bill (the free-healing stack, above all the 15% after every win and the 40% transit patch arriving immediately before the regroup decision) and the size of the purse (battle pay per fight), not the per-HP price. A regroup that follows a transit patch of, say, 15% instead of 40% would present a worst-ship bill several times larger at the same rate; that is a tuning direction for Opus to price, flagged here as an implication of the measurements, not a recommendation this pack was asked to make.

## Not measured

- Pass 1 boss fleets: the boss hull is pushed onto the list without a budget deduction and the escort budget is then scaled by RAMP.boss[s]; boss cells were not generated. Elite kind (budget x1.05) was not separated out; archetype fleets (swarm, heavy, carrier reshapes inside genEnemyFleet) were not measured, and the carrier and heavy pre-picks change both spent and mix.
- Pass 1 player feedback: RUN was undefined throughout, so the fleetPower budget feedback (a strong player fleet raises the budget by up to x1.3, a battered one lowers it to x0.75) is excluded. In live play this compresses faction differences somewhat, since budget follows the player's strength, not the faction's.
- Pass 1 models price CP and budget only. The ruling's other half, Eclipse ships being stronger per hull, lives in the hull stat tables and FAC_PRICE credit prices, which this pass did not touch; nothing here measures whether an 8-hull Eclipse fleet at multiplier prices is as dangerous as the 11.8-hull baseline fleet.
- Pass 2 conditions on reaching the regroup (no ship losses, no run-ending defeat), assumes the player takes salvage credits in 55% of normal battles, draws one sector condition per fight rather than one per sector (a small upward bias on income), holds damage fractions constant across sectors (enemy damage output grows in the real game, which would raise later-sector repair bills), and prices the new hull at priceMult 1. The mid-run spending variants (300 and 500 per sector) are flat deductions, not a spending model.
- Pass 2 does not measure the non-credit terms of the regroup choice (command point cap room for a new hull, captain availability), and the scrap comparison does not price the captain, Mark and modules a repair keeps and a replacement loses.
