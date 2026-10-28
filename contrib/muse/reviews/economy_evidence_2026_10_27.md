# Economy evidence pack (Oct 27 program, item 8)

Pinned commit: 68b42ce406286eb95ea7df6aaf3f683c1231b51d (rcbailey12/voidsworn, main).
Scope: the browser source at that commit (data.js, core.js, campaign_run.js, campaign3d.js, sim3d.js). The Godot port economy was not read; see Not checked.
Verdict up front: the credit economy is closed and conservative. Every way of turning a ship back into credits pays a fraction of the same single number, the hull template's shop cost, and no path pays out more than the ship cost to buy. The one question this pack was commissioned to answer, whether a captured ship's value can leak through equipment it carries, comes back no: at this commit a capture's value never sees equipment at all. Detail and evidence below.

## Sources and method

- Read in full or in the cited ranges: data.js (hull, module, relic, legacy, event, sector condition and heat tables; the B3 price ladder block at lines 533 to 547), core.js (shipValue, runFx, price and repair multipliers, newRun), campaign_run.js (reward flow, shipyard, wreck salvage, the prize screen), campaign3d.js (battle end: prize collection, auto-scrap, Corsair bonus, win patch), sim3d.js (mode dispatch and the economy-adjacent modes).
- Ran the harness modes that actually exist and finish fast: `budgetcheck` and `capcheck` (both synchronous, seconds). Raw output: ~/workspace/voidsworn-oct27-program/economy_budgetcheck.txt and economy_capcheck.txt.
- Ran one full campaign sim: `SEED=42 node sim3d.js runsim 12` (about 4 minutes). Raw output: ~/workspace/voidsworn-oct27-program/economy_runsim12.txt. runSim does not log a credit curve (it tracks credits internally to make shipyard decisions but prints only battle aggregates and reach), so the end-to-end credit picture below is a worked model computed from the shipped formulas, labelled INFERRED where it is a model rather than a measurement.
- Computed the effective ship values with a dump script that loads data.js, core.js, battle.js, campaign_meta.js and campaign_run.js the way sim3d.js loads them, then calls the game's own shipValue, prizeScrap and prizeRansom functions for every roster and boss hull. Script and output: ~/workspace/voidsworn-oct27-program/economy_dump.js and economy_dump.txt. Every value in the hull table below is the game's own function output at this commit, not a hand calculation.

## The numbers

### Starting position (core.js)

| Item | Value | Source |
|---|---|---|
| Starting credits | 120 | core.js:324 (`credits:120` in newRun) |
| War chest legacy I/II/III | +75 starting credits each, +225 total | core.js:326; bought with renown, data.js:243 to 245 (renown costs 20, 40, 65) |
| Starting command points | 10, raised to at least starting fleet CP + 3 | core.js:324, core.js:334 |
| Admiral starting fleet | Free (the hulls are granted, not bought) | core.js, newRun start list |
| CP cap growth | +3 per sector flagship beaten | campaign_run.js, afterBattle boss branch (line 536 area) |

### Hull prices: one ladder drives everything (data.js)

Only the six Sunward Crusade hulls carry hand-set costs (data.js:63 to 68): Warden 70, Harrow 130, Vigil cruiser 200, Hearth carrier 260, Bastion 340, Daybreak 520. Every other hull gets a derived base cost at load, `Math.round((60*cp+10)/5)*5` (data.js:545), which gives 70 at 1 CP, 130 at 2, 190 at 3, 250 at 4, 310 at 5, 370 at 6, 490 at 8. A per-faction, per-class multiplier then applies (FAC_PRICE, data.js:539 to 540): Hegemony is the 1.0 baseline, Crusade carriers pay 1.25, Hullbreakers run 0.8 frigate to 1.15 carrier, Chorus 0.65 frigate to 1.2 carrier, Glasswrights 1.1 to 1.3, Eclipse 1.45 to 1.55. The multiplier applies even to hand-set costs, so the Hearth carrier's effective price is 325, not 260 (dump-verified). The design comment at data.js:536 states the intent in one line: "Shipyard prices, ransom, strip and scrap values all follow h.cost." Enemy fleets are built by command points, not prices (data.js:537), and budgetcheck confirms the enemy budget is a CP budget (see Harness evidence).

Effective values per hull, from the game's own functions (scrap = 35% of value; ransom = 55% of value scaled by hull remaining; strip credit = 15% of value, plus a refit):

| Hull | Faction | Class | CP | Value | Scrap 35% | Ransom, full hull, 1st | Ransom, half hull, 1st | Ransom, full hull, 3rd | Strip credit 15% |
|---|---|---|---|---|---|---|---|---|---|
| warden | voidsworn | Frigate | 1 | 70 | 25 | 39 | 31 | 28 | 11 |
| harrow | voidsworn | Destroyer | 2 | 130 | 46 | 72 | 57 | 52 | 20 |
| penitent | voidsworn | Cruiser | 3 | 200 | 70 | 110 | 88 | 79 | 30 |
| reliquary | voidsworn | Carrier | 4 | 325 | 114 | 179 | 143 | 129 | 49 |
| cathedral | voidsworn | Battleship | 5 | 340 | 119 | 187 | 150 | 135 | 51 |
| ascendant | voidsworn | Dreadnought | 8 | 520 | 182 | 286 | 229 | 207 | 78 |
| h_picket | hegemony | Frigate | 1 | 70 | 25 | 39 | 31 | 28 | 11 |
| h_interdictor | hegemony | Destroyer | 2 | 130 | 46 | 72 | 57 | 52 | 20 |
| h_vanguard | hegemony | Cruiser | 4 | 250 | 88 | 138 | 110 | 99 | 38 |
| h_dominion | hegemony | Battleship | 6 | 370 | 130 | 204 | 163 | 147 | 56 |
| c_raider | corsair | Frigate | 1 | 55 | 19 | 30 | 24 | 22 | 8 |
| c_reaver | corsair | Destroyer | 2 | 110 | 39 | 61 | 48 | 44 | 17 |
| c_marauder | corsair | Cruiser | 3 | 200 | 70 | 110 | 88 | 79 | 30 |
| c_hulk | corsair | Carrier | 4 | 290 | 102 | 160 | 128 | 115 | 44 |
| b_drone | chorus | Frigate | 1 | 45 | 16 | 25 | 20 | 18 | 7 |
| b_spitter | chorus | Destroyer | 2 | 100 | 35 | 55 | 44 | 40 | 15 |
| b_razor | chorus | Cruiser | 3 | 190 | 67 | 105 | 84 | 76 | 29 |
| b_brood | chorus | Carrier | 5 | 370 | 130 | 204 | 163 | 147 | 56 |
| i_wisp | ithar | Frigate | 1 | 90 | 31 | 50 | 40 | 36 | 14 |
| i_blade | ithar | Destroyer | 2 | 170 | 59 | 94 | 75 | 68 | 26 |
| i_song | ithar | Cruiser | 4 | 290 | 102 | 160 | 128 | 115 | 44 |
| i_carrier | ithar | Carrier | 5 | 340 | 119 | 187 | 150 | 135 | 51 |
| d_scythe | deathless | Frigate | 1 | 100 | 35 | 55 | 44 | 40 | 15 |
| d_jackal | deathless | Destroyer | 2 | 195 | 68 | 107 | 86 | 77 | 29 |
| d_harvester | deathless | Cruiser | 4 | 390 | 137 | 215 | 172 | 155 | 59 |

Boss hulls (h_boss, c_boss, b_boss, i_boss, d_boss) print values of 400 to 480 in the dump, but those come from the shipValue fallback of 40 per CP for hulls with no price (core.js:193), and bosses can never be prizes (campaign3d.js excludes boss hulls from the prize list) or sold, so the numbers are unreachable in play.

### Income

| Source | Value | Source |
|---|---|---|
| Battle pay, base | round((25 + 12 x sector + 3 x column) x kind multiplier); kind multiplier 1 battle, 1.6 elite, 3 boss | campaign_run.js:400 |
| Battle pay, worked range | Sector 1: battle 40 to 55, elite 64 to 88, boss 165 (column 6). Sector 3: battle 64 to 79, elite 102 to 126, boss 237 | computed by the dump script from the same formula |
| Credit percentage bonuses | Added together inside one factor: Smuggler's ledger relic +25% (data.js:194), Recovery crews legacy +20% (core.js:196), sector conditions Wreck belt +15%, War zone +20%, Scarcity +25% (data.js:605 to 607) | as cited |
| Bounty node modifier | Battle pay x 1.5 for that fight | campaign_run.js:400 |
| Partial objective | Battle pay halved | campaign_run.js:401 |
| Node spoils reward | +35 + 10 x sector (45, 55, 65) when the node's rolled reward is credits | campaign_run.js:407 |
| Scrap rig relic | +15 credits and 8% hull repair after each battle | data.js:197; applied campaign_run.js:402 |
| Wreck salvage, scrap option | round((10 + 9 x CP) x 1.3 if the wreck was flayed or dissolved, else x 1): CP 1 pays 19 (25 flayed), CP 4 pays 46 (60), CP 8 pays 82 (107), CP 12 pays 118 (153) | campaign_run.js:427 to 432 |
| Wreck salvage, strip option | One refit, chosen by the wreck's weapon kinds (lance wreck yields the lance crystal, torpedo wreck the magazine, and so on); only one wreck per battle can be worked | campaign_run.js:427 to 432, salvageStep |
| Wreck tow (Hullbreakers only) | An intact wreck of 2 CP or less joins the fleet at 35% hull instead of paying out | campaign_run.js:431 to 432 |
| Prize strip | A refit (by weapon kinds, as salvage) plus 15% of ship value in credits | campaign_run.js:441 to 443 |
| Prize ransom | 55% of ship value, scaled 60% to 100% by hull remaining, times 0.85 per ransom already taken this run, floored at 0.4 of the factor | campaign_run.js:440 |
| Prize auto-scrap (fleet at CP cap) | 35% of ship value, paid at battle end with no screen | campaign3d.js:90; prizeScrap, core.js:194 |
| Corsair prize bonus | First prize of a battle also pays a free refit and +20 credits at battle end, before the prize screen | campaign3d.js:93 |
| Events | Credit gains run +30 to +120 (largest: the Archive trade at data.js:367 pays 120; faction shake-down data.js:381 pays 100); credit costs run 30 to 120 (auction bid 120, data.js:403) | data.js EVENTS, sampled lines 278 to 416 |
| Faction verb, Hullbreaker shake-down | +30 credits, plus 10 per greedy choice made this run | campaign_run.js, useVerb |
| Boon decline | +30 + 10 x sector (40, 50, 60) for declining a protocol offer | campaign_run.js:496 |
| Nemesis raid (a sink, not income) | When the Corsair-persona Nemesis clock fills he takes 25% of your credits, or a crippled ship if you hold under 30 | data.js:463; campaign_run.js:276 |

### Spending

| Sink | Value | Source |
|---|---|---|
| Buy a hull | Effective hull cost (table above) x priceMult | campaign_run.js, ACT.buyHull (line 196) |
| priceMult | Master shipwrights legacy x 0.85; Heat "Lean coffers" x 1.25; sector condition price factor (Scarcity x 1.2). Stacks multiplicatively; range 0.85 to 1.5 | core.js:227; data.js:607, 613 |
| Buy a refit (module) | 55 to 90 by module: flakplus 55, gyro 60, prow 70, regen 70, drive 75, cogitator 75, auspex 80, capacitor 80, crystal 80, damcon 85, magazine 85, loaders 90, hangar 90; x priceMult | data.js:154 to 166; campaign_run.js, ACT.buyMod (line 197) |
| Shipyard repair | ceil(missing hull / 2 x priceMult): half a credit per hull point, rounded up | campaign_run.js:174, 198 to 199 |
| Mark upgrade | round((40 x CP x current Mark + 30) x priceMult): a 2 CP ship pays 110 to reach Mk II; a 5 CP ship pays 230 to Mk II and 430 to Mk III; an 8 CP ship pays 350 to Mk II | core.js:230 |
| Class refit track | 60, then 110, then 160 (x priceMult), per class, max level 3, benefits every ship of the class owned now or later | core.js:222 |
| Decommission a ship | Pays you 35% of ship value (the same prizeScrap); its fitted refits return to the hold, its Mark investment does not come back | campaign_run.js:202 to 203; core.js:194 |
| Boon reroll | 25 + 15 per reroll already used this run, once per reward | campaign_run.js:497 |
| Free repairs (the offsetting flow) | Win patch +15% of max hull after every won battle (campaign3d.js:88); drydock node restores 60% of missing hull free (campaign_run.js:207); field repairs node 20% of max hull free (campaign3d.js:41); sector transit after a boss restores 40% of max hull free (campaign_run.js, afterBattle); repair strength is scaled by repairMult (Heat "Short supplies" x 0.5, Scarcity x 0.75; core.js:229) | as cited |
| Legacy and variants | Bought with renown, not credits: legacy items cost 20 to 120 renown (data.js:241 to 252), hull variants 15 to 25 renown (data.js, HULL_VARIANTS) | as cited |

### Harness evidence

- budgetcheck (enemy budget, not money): generated enemy fleets are CP budgets. Against the check's sector 3 reference fleet (16 hull CP, power 25.7), the current generator averages about 20.0 CP at column 0, 25.0 at column 3 and 30.0 at column 6 over 40 fleets each. OBSERVED: difficulty is set by CP, so the price ladder cannot accidentally make a faction harder or easier to fight.
- capcheck (boarding capture odds): shown capture chance against rolled capture chance over 8 crew matchups at 10,000 rolls each; largest gap 1.0 percentage points. OBSERVED: the capture odds the game shows are the odds it rolls.
- runsim 12, seed 42: 12 runs started, 6 reached sector 2, 5 reached sector 3, 3 won. Battle detail in economy_runsim12.txt. OBSERVED: the harness bot plays a simplified economy (see Finding 5), so its spending is not evidence about the shipped game's balance, only about battle outcomes.

## What a run's economy looks like end to end

INFERRED (worked model from the shipped formulas, not a simulation): a run is 3 sectors of 7 map columns each (genSector, core.js:251), one node per column on the player's path, ending in a boss at the last column. A representative winning sector 1 path (four battles at columns 1, 2, 3 and 5, an elite at column 4, the boss at column 6) pays base battle pay of about 424 credits; sector 2 on the same shape pays about 528; sector 3 about 631. Base battle pay for a full winning run is therefore roughly 1,580 credits, before credit percentage bonuses (a ledger plus Recovery crews stack to +45% on every battle), node spoils, wreck salvage (one wreck worked per win, worth 19 to 82 credits as scrap or a refit worth 55 to 90), prize income, and event swings of plus or minus 30 to 120.

Against that income: the player starts with 120 credits and a free admiral fleet. The first shipyard opens sector 2, so sector 1 income (roughly 420 to 550 with extras) is the first real budget: one destroyer or cruiser class hull (110 to 390 depending on faction), or two to four refits (55 to 90 each), or a Mark upgrade on a mid-size ship (110 to 230), with repairs competing for the same credits at half a credit per hull point (a half-damaged 220 hull Bastion costs 55 to repair). Nothing in the price list is affordable twice over in sector 2, and the big hulls (Bastion 340, Daybreak 520, a captured-value Eclipse cruiser at 390) each cost about a full sector's base pay. The economy is a one-big-decision-per-sector economy, and free repair nodes (drydock, field, the post-boss transit, the +15% win patch) do much of the sustain work that credits would otherwise have to do.

Renown runs beside this as a second, slower currency (legacy items 20 to 120, variants 15 to 25) and buys permanent economy levers: +75 starting credits per War chest tier, -15% prices from Master shipwrights, +20% battle credits from Recovery crews. Those are the only permanent economy modifiers in the game.

## The capture-value answer

Question (from the Oct 26 customization follow-up): if captured ships could carry custom equipment, would scrap or
...[truncated 6193 chars]