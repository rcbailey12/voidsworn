Chair note: filed verbatim from the DeepSeek DeepThink run of Oct 29, 2026 (toggles verified on; first chat hung about 10 minutes and was abandoned, second chat completed), except em dashes in the model's text are normalized to hyphens.

1. Proof of reading:
Read: EVIDENCE PACK title line; THE COMMISSIONER'S QUESTION; CHAIR CENSUS; WHAT TO JUDGE; data.js 538-544 FAC_PRICE/FAC_GATES; core.js 220-235 priceMult/repairMult/mkCost; campaign_run.js 155-200 shipyard; campaign_run.js 431-460 capture/strip/ransom; core.js 251-300 genSector/sectorCond.

Overall verdict: MIXED - Chorus partly reads as swarm economics and capture has a real three-way shape, but repair is a near-dominant cheap action, FAC_PRICE is mostly a blind class tax, and the pack omits the income/hull-HP data needed to prove credits create decisions.

2. Findings:

[FIX] Repair-specific modifiers are dead in the shown shipyard path. READ: repairMult() exists and includes heatOn('h_repair') and sector repair; READ: shipyard repair uses Math.ceil(miss/2*priceMult()) and repairAll also uses priceMult(). INFERRED: Heat repair and sector repair conditions do not affect shipyard repairs in this slice, so repair economics ignore the modifiers the pack says exist. Quote: "Repairs cost 1 credit per 2 hull."

[FIX] Repair is too cheap for the post-boss regroup to be a real tradeoff. READ: repair is 1 credit per 2 hull. INFERRED case: a cruiser at 100 max hull, half hull, priceMult=1 costs 25 to repair; a 3-CP cruiser replacement is roughly 180 before faction multiplier; Mk II is roughly 150. Repair dominates hull restoration. The regroup becomes "repair if you can, then maybe upgrade," not repair/upgrade/buy as competing strategies. Quote: "tradeoffs after a boss."

[FIX] FAC_PRICE is mostly a class tax/subsidy, not faction character. READ: Chorus is .65/.75/1/1.2; Corsair .8/.85/1.05/1.15; Voidsworn only Carrier:1.25; Ithar 1.3/1.3/1.15/1.1; Deathless 1.45/1.5/1.55; Hegemony empty. INFERRED: Chorus small hulls read swarm; Deathless reads blanket tax; Voidsworn reads a single-class surcharge; Hegemony has no price identity. Quote: "voidsworn:{Carrier:1.25}".

[FIX] Capture is not a balanced three-way decision when command points fit. READ: add is available if CP allows; ransom is 55% of ship value scaled by hull and decay; strip is refit plus 15% value. INFERRED: add gives the full hull with no upkeep, so it usually dominates if CP room exists; strip/ransom become the real choice only when CP is tight or the faction gate blocks the prize. Quote: "Add it (only if command points allow)".

[NOTE] Ransom decay matters mainly in the no-CP strip/ransom edge. READ: ransom decays 15% per prior ransom, floor 40%. INFERRED example: a 189-value prize at 70% hull ransoms for about 91 at run start and about 56 after three ransoms; strip credits are 28 plus half a refit's shop cost. If the refit half-cost is above roughly 56, strip overtakes ransom by the third ransom. The decay can flip the right answer, but only after add is off the table. Quote: "decaying 15 percent per ransom".

[NOTE] Price-per-command-point spread is large; Deathless lies most upward. READ: hull cost is "roughly 60 per cp" before FAC_PRICE. INFERRED: implied credits/CP at priceMult=1 is 39 for Chorus Frigate, 48 Corsair Frigate, 60 Hegemony, 75 Voidsworn Carrier, 78 Ithar Frigate, 87 Deathless Frigate, 90 Deathless Destroyer, 93 Deathless Cruiser. Deathless is the clearest upward lie; Chorus is the clearest downward subsidy on small hulls. Per-hit-point pricing cannot be built from this pack because no hull HP values are present.

[NOTE] Sector flow cannot be judged from the pack. READ: genSector places battles, elites, events, shipyards, drydocks, fields, and a boss across 7 columns; it guarantees a mid shipyard and a pre-boss rest stop. INFERRED: there are many spend opportunities, but the pack gives no battle/elite/event/boss credit reward amounts, so "money solved by sector 2" cannot be verified. Quote: "places the nodes that pay" - but not how much they pay.

[NOTE] Voidsworn carrier 1.25 is not enough to express carrier identity. READ: only Voidsworn price entry is Carrier:1.25. INFERRED: this is a carrier surcharge, not a faction-shape statement; if Voidsworn are meant to be carrier-led, taxing their signature hull needs a designer rationale not present in the pack.

[NOTE] Class refits do not carry faction price identity. READ: classTrackCost uses priceMult() but not FAC_PRICE. INFERRED: Chorus's cheap-frigate identity does not extend to class refits, and Deathless's blanket hull tax does not either; class-wide upgrades are priced faction-blind.

Explicit checks:

PRICE HONESTY: The pack supports a per-command-point comparison, not a true per-hit-point comparison. Using "roughly 60 per cp" and priceMult=1, implied credits/CP after FAC_PRICE: Chorus Frigate 39; Corsair Frigate 48; Hegemony 60; Voidsworn Carrier 75; Ithar Frigate 78; Deathless Frigate 87; Deathless Destroyer 90; Chorus Carrier 72; Corsair Carrier 69. This is a 2.23x spread from Chorus Frigate to Deathless Cruiser. Per HP cannot be honestly built: the pack gives no hp values for named hulls. Any per-HP table would be invented. On the supported CP proxy, Deathless's prices lie most upward; Chorus's small-hull prices lie most downward.

FAC_PRICE AS IDENTITY: Chorus at .65 frigates and .75 destroyers does read as swarm economics at the low end, but Carrier:1.2 makes the set only partially swarm-shaped. Voidsworn Carrier:1.25 reads as "carriers cost more," not as a full identity, because no other Voidsworn classes are priced. Corsair .8/.85/1.05/1.15 plausibly reads cheap raider smalls and dearer larges. Ithar 1.3/1.3/1.15/1.1 makes small hulls expensive and large hulls cheaper, which is an odd shape for a no-brace "glass" faction. Deathless 1.45/1.5/1.55 is a blanket tax, not character. Hegemony empty means no price identity. The pack has no Eclipse data, so the Eclipse-elite/Chorus-swarm ruling cannot be verified here; Chorus only partly follows it.

REPAIR ECONOMICS: Assume a 100-HP, 3-CP cruiser at half hull, priceMult=1, Chorus cruiser multiplier 1.0. Repair costs ceil(50/2)=25. Replacement costs roughly 180 before faction multiplier. Mk II costs (40*3*1+30)=150. Repair is clearly right. Repair becomes wrong only if credits have higher marginal value in an upgrade/buy, if repair is unavailable and fighting damaged reaches a cheaper yard, or if missing HP exceeds twice replacement cost - not shown plausible by this pack. The post-boss regroup does not survive as a real tradeoff: cheap repair collapses it into "repair first." If repairMult were actually applied at .5, repair would be even more dominant.

THE CAPTURE TRIANGLE: Take a mid-tier prize worth 189, 70% hull, priceMult=1. At run start, ransom is about 91; strip credits are 28 plus half a refit's shop cost. At three prior ransoms, ransom is about 56. If the refit half-cost is above roughly 56, strip beats ransom after three ransoms but not at start; if it is above roughly 126, strip beats ransom even at start. So the decay rule can flip strip versus ransom mid-run. But add dominates both whenever CP fits and the prize is fieldable: it gives the full hull with no upkeep. The triangle is real only when CP is scarce or the faction gate blocks add.

FLOW: A typical sector has 7 columns: a starting yard/battle, several middle columns with fights/events/yards, a guaranteed mid shipyard, a pre-boss rest stop, and a boss. That is many spend nodes. But the pack gives no credit income per battle, elite, event, or boss, and no event payout table. Therefore I cannot say when a competent player stops making credit decisions. Structurally, the risk is that cheap repair plus no upkeep on kept prizes makes credits accumulate if fight payouts exceed repair costs; the likely pinch points are the first post-boss yard and the pre-boss rest stop, but that is INFERRED, not proven.

Not checked:
- Actual HULLS hp, cp, and cost values for named hulls; exact per-HP pricing.
- Battle/elite/boss/event credit reward amounts and node reward tables.
- Module shop costs, actual refit values, and prize CP/hull distributions.
- Whether repairMult() is used outside the shown shipyard slice.
- Eclipse faction data and the full faction-shape ruling.
- Drydock/field/event mechanics and the exact post-boss regroup UI.
- Heat and sector-condition full lists beyond the snippets.
- Player skill, capture rates, and encounter difficulty.

Questions for the designer:
- Are shipyard repairs intended to use repairMult() - including Heat h_repair and sector repair conditions - or is priceMult()-only repair deliberate? Stakes: if unintended, repair economics and Heat/condition balance are wrong.
- What are the actual hull HP/CP/cost table and node credit reward amounts? Stakes: without them, price-per-HP honesty and "money solved by sector 2" cannot be audited.
- Should Voidsworn Carrier:1.25 and Deathless 1.45-1.55 be read as faction identity or as balance taxes? Stakes: if identity, the multiplier sets need class shape; if tax, the target needs to be stated.
