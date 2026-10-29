Chair note: filed verbatim from the Qwen3.8-Max run of Oct 29, 2026 (both model gates passed, single response), except em dashes, en dashes, and unicode minus signs in the model's text are normalized to hyphens.

# IN-RUN ECONOMY AUDIT REPORT

## PROOF OF READING

Sections read:
1. EVIDENCE PACK title line ("EVIDENCE PACK: in-run economy audit…main 264f441d")
2. THE COMMISSIONER'S QUESTION (Voidsworn roguelite fleet-tactics; prior capture-leak check closed; wider economy unjudged)
3. CHAIR CENSUS (60/cp base, FAC_PRICE, priceMult layers, shipyard functions, capture triangle, genSector, designer rulings Q5 and Q11)
4. WHAT TO JUDGE (five numbered questions: price honesty, FAC_PRICE identity, repair economics, capture value, flow)
5. Code slices: data.js 538-544 (FAC_PRICE, FAC_GATES); core.js 220-235 (priceMult, repairMult, mkCost, classTrackCost); campaign_run.js 155-200 (shipyard stock, hull sale, repair, Mk upgrade, class track, decommission); campaign_run.js 431-460 (prizeOffer, prizeRansom, prizePlan, prize UI); core.js 251-300 (genSector, sector conditions, node budgets, edges, archetypes)

Overall verdict: MIXED - The capture triangle and faction-price skeleton are real design, but repair costs are so cheap relative to hull prices that the post-boss regroup tradeoff the designer ruled for is structurally absent, and the pack contains no battle-reward data to judge whether credits ever actually pinch.

## FINDINGS

1. [BLOCKER] Repair cost is trivially cheap; the "regroup tradeoff" ruling cannot survive these numbers.
READ: shipyard lede says "Repairs cost 1 credit per 2 hull." READ: formula is Math.ceil(miss/2*pm). READ: designer ruling Q11 demands "repair, upgrade, or buy" as "a regroup with tradeoffs…not a free restore." INFERRED: even granting a cruiser 60 HP (assumption stated below), half-hull repair is 15 credits against a 180-credit replacement - 8.3 %. At 120 HP it is 30 credits, 16.7 %. At no plausible hull value does repair compete with replacement or upgrade as a real tradeoff. The player repairs everything reflexively and then faces only the upgrade-vs-buy question. The ruling's "not a free restore" is technically met; its "tradeoffs" are not.

2. [BLOCKER] The pack contains no battle-reward data; income per node is invisible.
READ: genSector calls rollNodeReward(n.type) for every battle, elite, and boss node. READ: the commissioner's question explicitly asks "what a won battle actually pays." READ: designer ruling Q5 concedes "credit nodes are to be rebalanced to make sense in the economy (Oct 28)." The reward table, starting credits, and per-node payout values are absent from every code slice. Without them, FLOW cannot be answered from this pack; the audit is structurally blind on the income side.

3. [FIX] Deathless FAC_PRICE scales upward with class (1.45 → 1.5 → 1.55), punishing the large ships the faction identity presumably wants.
READ: deathless:{Frigate:1.45,Destroyer:1.5,Cruiser:1.55}. INFERRED: a faction named "Deathless" with the highest multipliers in the game and an escalating scale reads as "field few, expensive, large ships," yet the pricing makes the large ships progressively harder to buy. If the intent is an elite slow-build, the scale should flatten or invert so the flagship is the payoff, not the penalty. As written, the multiplier set taxes the player hardest at the point where the fantasy should reward commitment.

4. [FIX] Voidsworn FAC_PRICE is a single data point (Carrier 1.25) with no identity expression.
READ: voidsworn:{Carrier:1.25}. INFERRED: one multiplier on one class does not constitute an economic character. Every other Voidsworn hull prices at the Hegemony baseline (1.0). Compare Chorus, which shapes four classes into a curve. The Voidsworn set reads as a leftover tuning pass, not a faction identity. The commissioner's question names this faction; the answer is that it currently reads as nothing.

5. [FIX] Hegemony FAC_PRICE is empty; the baseline faction has zero price identity.
READ: hegemony:{}. INFERRED: an empty multiplier set means every Hegemony hull costs exactly 60 × cp. That is a design-neutral default, fine for a tutorial faction, but if Hegemony is a playable faction with its own roster (the shipyard stock lists warden, harrow, penitent, reliquary, cathedral, ascendant as its hulls), it has no economic personality. Every other faction is defined by deviation from Hegemony; Hegemony itself is defined by absence.

6. [FIX] priceMult stacks three independent multipliers with no visible cap; extreme combinations are possible.
READ: priceMult(){ return (META.unlocked.wrights?.85:1)*(heatOn('h_coffers')?1.25:1)*((c&&c.price)||1); }. INFERRED: LEGACY discount (0.85) × Heat surcharge (1.25) × sector condition (unknown range) multiply freely. If a sector condition sets price to 1.5, the effective multiplier is 0.85 × 1.25 × 1.5 = 1.594. Conversely, a generous condition could push it well below 0.85. No clamp is visible. The player-facing price could swing ±60 % on stacked conditions with no warning.

7. [NOTE] Chorus Carrier at 1.2 partially contradicts the swarm identity the 0.65 Frigate establishes.
READ: chorus:{Frigate:.65,Destroyer:.75,Cruiser:1,Carrier:1.2}. INFERRED: the curve says "small ships cheap, big ships dear," which is coherent for swarm. But 1.2 on the Carrier is the same multiplier Corsair gets on its Carrier (1.15), and close to Voidsworn's (1.25). If Chorus is the swarm faction, the Carrier should arguably be the one class they don't do, or it should be priced more punitively to steer composition. At 1.2 it is merely "a bit more," which muddies the signal.

8. [NOTE] The ransom decay floor at 40 % means the triangle collapses after roughly five ransoms.
READ: formula is Math.max(.4,Math.pow(.85,n)). INFERRED: 0.85^5 ≈ 0.444, 0.85^6 ≈ 0.377 → floor. After five ransoms in a run, every subsequent ransom pays the same 40 % rate. The decay stops mattering; the triangle becomes static. In a long run with many captures, the player stops thinking about ransom timing entirely.

9. [NOTE] Decommission returns a flat 35 % of hull cost; no hull-condition scaling.
READ: sell=Math.round(HULLS[s.tpl].cost*.35). INFERRED: a ship at 10 % hull decommissions for the same return as one at 100 %. This removes any incentive to keep a damaged ship alive for resale and makes the "fight damaged vs scrap" choice binary rather than graded. Minor, but it flattens one more decision.

10. [NOTE] classTrackCost escalates (60 + 50 × level) but is gated by priceMult, coupling fleet-wide upgrades to sector economy.
READ: classTrackCost(cls){ return Math.round((60+50*classTrack(cls))*priceMult()); }. INFERRED: buying a class track in a Heat-surcharge sector costs 25 % more than in a clean sector. The player who tracks class costs will defer purchases to cheap sectors; the player who doesn't is silently taxed. This is a hidden timing optimization, not a visible strategic choice.

## EXPLICIT CHECKS

### PRICE HONESTY

Base cost is "roughly 60 per cp, rounded" (READ). FAC_PRICE then multiplies (READ). I assume standard class cp values of Frigate = 1, Destroyer = 2, Cruiser = 3, Carrier = 4 (INFERRED; the pack does not list per-class cp, but the tow gate w.cp<=2 and the shipyard CP readout are consistent with small integers in this range).

| Faction | Class | CP | Base (60×cp) | FAC_PRICE | Final | Per CP |
|---|---|---|---|---|---|---|
| Chorus | Frigate | 1 | 60 | 0.65 | 39 | 39 |
| Chorus | Destroyer | 2 | 120 | 0.75 | 90 | 45 |
| Corsair | Frigate | 1 | 60 | 0.80 | 48 | 48 |
| Corsair | Cruiser | 3 | 180 | 1.05 | 189 | 63 |
| Hegemony | Frigate | 1 | 60 | 1.00 | 60 | 60 |
| Hegemony | Cruiser | 3 | 180 | 1.00 | 180 | 60 |
| Ithar | Frigate | 1 | 60 | 1.30 | 78 | 78 |
| Ithar | Cruiser | 3 | 180 | 1.15 | 207 | 69 |
| Deathless | Frigate | 1 | 60 | 1.45 | 87 | 87 |
| Deathless | Cruiser | 3 | 180 | 1.55 | 279 | 93 |

Ten hulls across five factions. Price per CP ranges from 39 (Chorus Frigate) to 93 (Deathless Cruiser), a 2.38× spread.

Price per HP cannot be computed. The pack does not include hull hit-point values in any code slice. The repair formula references derive(s).maxHp but the derive function and HULLS stat blocks are not provided. This is a gap.

Which faction's prices lie the most? INFERRED: Deathless, upward. At 93 credits per CP for a Cruiser, Deathless hulls cost 55 % more than the Hegemony baseline. For that surcharge to be honest, a Deathless Cruiser would need roughly 55 % more combat value (hull, shields, weapons, utility) than a Hegemony cruiser. The pack contains no stat comparison, but the escalating scale (1.45 → 1.50 → 1.55) implies the design intends the large ships to be the premium product, yet it is precisely those large ships where the player's investment is most concentrated and the penalty most painful. If Deathless stats do not scale proportionally, the prices lie upward: the player overpays for the flagship. Chorus is the secondary candidate, lying downward: at 39/cp, a Chorus Frigate is 35 % cheaper than baseline. If it is only 15-20 % weaker in stats, it is underpriced and the player is subsidised into swarm compositions rather than choosing them.

### FAC_PRICE AS IDENTITY

Chorus (0.65 / 0.75 / 1.0 / 1.2): READ. The curve is clear: cheap small hulls, expensive large ones. This reads as swarm economics. You are incentivised to flood the board with frigates and destroyers. The 1.0 on Cruiser and 1.2 on Carrier say "you can go big, but the design wants you small." Verdict: works. The multiplier set does character work. The one wrinkle is that 1.2 on Carrier is not punitive enough to truly forbid it; a Chorus player can still build a Carrier and feel only mildly taxed.

Voidsworn (Carrier 1.25 only): READ. One data point. Every other class is 1.0. INFERRED: this does not read as anything. It is not a curve, not a philosophy, not a shape. It is a single number attached to one class. If Voidsworn has a faction identity (and the game is named after them), their economy should express it. A 1.25 Carrier tax in isolation says "carriers cost a bit more." That is not character; that is a line item.

Corsair (0.8 / 0.85 / 1.05 / 1.15): READ. Everything is discounted, with a gentle upward slope. INFERRED: this reads as "scrappy, resourceful, everything is a bargain but the big stuff still costs." It fits a pirate/privateer identity. The FAC_GATES entry (no lance weapons) reinforces close-range brawling. The price set and the gate are coherent.

Ithar (1.3 / 1.3 / 1.15 / 1.1): READ. Expensive across the board, slightly less so at larger classes. INFERRED: the flat 1.3 on Frigate and Destroyer says "even your small ships are precious." Combined with the noBrace gate ("they live by shields and speed"), this reads as glass-cannon economics: few ships, expensive, fragile, relying on speed. The multiplier set supports the identity. However, the curve flattens toward Carrier (1.1), which slightly undercuts the "everything is expensive" message.

Deathless (1.45 / 1.5 / 1.55): READ. Most expensive faction, and the scale escalates. INFERRED: as noted in Finding 3, this punishes the large ships. If Deathless is meant to be an elite slow-build faction, the escalation works against the fantasy. The player should be saving toward a flagship, not being penalised for getting there. The identity reads as "punishment for ambition," which is a valid design emotion but probably not the intended one.

Hegemony (empty): READ. No identity. See Finding 5.

Should price follow the faction-shape ruling? INFERRED: yes, and mostly does for Chorus, Corsair, and Ithar. It fails for Voidsworn (no shape), Hegemony (no shape), and arguably Deathless (wrong-direction shape).

### REPAIR ECONOMICS

READ: "Repairs cost 1 credit per 2 hull." Formula: Math.ceil(miss/2*pm).

Concrete case: a cruiser at half hull after a boss.

Assumption (INFERRED): cruiser maxHp = 60. This is not in the pack; it is a round number consistent with a 3-cp hull at roughly 20 HP per cp. I state it and mark everything downstream INFERRED.

- Miss: 30 HP.
- Repair cost: ceil(30/2 × 1.0) = 15 credits (no Heat, no sector condition).
- Replace cost (Hegemony cruiser): 180 credits.
- Fight damaged: 0 credits, 30 HP short in the next engagement.

Repair is 8.3 % of replacement. Even doubling the HP to 120 (miss = 60, repair = 30), it is 16.7 %. Even with a Heat surcharge (priceMult 1.25), repair from half is 19 credits against 180.

Which is right? Repair, unambiguously, at these numbers. Replace is only correct if the ship is so damaged it will die in the next fight even after repair AND you have the CP and credits for a new hull. Fight damaged is only correct if you have zero credits and no shipyard access, which the sector layout makes unlikely (there is a guaranteed shipyard mid-sector and a rest stop before the boss).

Does the regroup survive? No. The ruling says "repair, upgrade, or buy" should be a tradeoff. In practice, repair is so cheap it is never the tradeoff; it is the prerequisite. The player repairs everything for pocket change, then faces the real question of upgrade vs new hull. The three-way choice collapses to a two-way choice preceded by a non-choice. The "not a free restore" clause is honoured in the letter (you do pay credits), but the payment is trivial. The post-boss regroup is not a real tradeoff at these repair costs.

### THE CAPTURE TRIANGLE

READ: ransom formula: Math.round(shipValue(p.tpl)*.55*(.6+.4*(p.hpf||1))*Math.max(.4,Math.pow(.85,n))). READ: strip = refit + 15 % of ship value. READ: shipValue = shop price, or 40/cp if unpriced.

Concrete mid-tier prize: a Destroyer, 2 cp, full hull (hpf = 1.0).

Assumption (INFERRED): shipValue = 60 × 2 = 120 credits (Hegemony baseline). The module yielded by strip is unknown; I assume a mid-tier module worth ~50 credits at shop, valued at half (25) for comparison per the prizePlan default logic.

At run start (0 prior ransoms):
- Add: free, costs 2 CP. Ship joins at 100 % hull.
- Strip: 120 × 0.15 = 18 credits + module (~25 effective) = ~43 credits equivalent.
- Ransom: 120 × 0.55 × 1.0 × 1.0 = 66 credits.

Ransom wins on credits. Strip wins if the module is specifically useful. Add wins if you need the ship and have CP.

After 3 ransoms (n = 3):
- Ransom: 120 × 0.55 × 1.0 × 0.85³ = 66 × 0.614 = ~41 credits.
- Strip: still ~43 credits equivalent.
- Add: unchanged.

Does the right answer flip? Yes. At run start, ransom (66) beats strip (~43) by 53 %. After three ransoms, ransom (41) falls below strip (~43). The flip is narrow and depends on the module value assumption, but the structure is correct: the decay does shift the optimal choice from ransom to strip over the course of a run. A player who ransoms everything early will find strip becoming the better option by mid-run.

Does the decay rule ever matter? Yes, but with a ceiling. The 15 %-per-ransom decay is meaningful for the first 4-5 ransoms. After that, the floor at 40 % (READ: Math.max(.4,...)) freezes the ransom value. In a long run with many captures, the player stops tracking ransom count because the return is flat. The decay matters in sectors 1-3 and is inert thereafter.

### FLOW

READ: genSector builds 7 columns. Column 0 is shipyard (sector ≥ 2) or battle. Columns 1-4 distribute nodes by weighted random: 48 % battle, 13 % elite, 17 % event, 12 % shipyard, 10 % drydock. Column 5 is a rest stop (shipyard or drydock). Column 6 is the boss. Column 4 is guaranteed an elite. Column 3 is guaranteed a shipyard. Budget rules cap rest stops at one per column and ensure every column before the boss has at least one fight.

READ: rollNodeReward(n.type) is called for every battle, elite, and boss. The reward values are not in the pack.

READ: designer ruling Q5: "credit nodes are to be rebalanced to make sense in the economy (Oct 28)."

INFERRED sector trace (structure only, no income figures):

| Column | Typical content | Credit flow |
|---|---|---|
| 0 | Shipyard (sector 2+) | Spend: hulls, repairs, modules, Mk, class tracks |
| 1-4 | ~6-8 battles, 1-2 elites, 1 event | Earn: per-node rewards (UNKNOWN) |
| 5 | Rest stop (shipyard or drydock) | Spend: repairs, possible upgrade |
| 6 | Boss | Earn: boss reward (UNKNOWN) |

At what point does a competent player stop making credit decisions? I cannot answer this from the pack. The income side is a black box. What I can say structurally:
- Repair costs are so low (Finding 1) that they never create a meaningful credit sink.
- Hull purchases are the primary sink (39-300 credits), but are gated by CP cap as much as by credits.
- Mk upgrades cost 40 × cp × mk + 30 (READ), so Mk2 on a 3-cp cruiser is 150, Mk3 is 270. These are the only escalating money sink.
- Class tracks cost 60, 110, 160 (READ: 60+50*level), capped at 3 levels.
- If battle rewards are generous (and Q5 implies they currently are, since they need "rebalancing to make sense"), the player will hit a surplus by sector 2 where the only question is which hull to buy, not whether to buy anything.

INFERRED: the economy pinches hardest at the first shipyard in sector 1, where the player has limited credits and must choose between a new hull and saving for repairs. After that, if income scales with combat count (6-8 fights per sector), the player is likely in surplus by sector 2 and the credit decision becomes "which of several affordable things to buy" rather than "can I afford anything." That is a shopping decision, not a resource decision. But I cannot confirm without reward numbers.

## NOT CHECKED

This pack does not let me judge:
1. Actual hull stats (HP, shields, weapons, speed). Price-per-HP is impossible. Faction price honesty beyond the multiplier curve is unverifiable.
2. Battle, elite, and boss credit rewards. rollNodeReward is called but its table is absent. Income cannot be traced.
3. Starting credits and credit accumulation across sectors. No initial value, no per-sector income totals.
4. Module costs. Modules appear in shipyard stock and strip yields, but their price table is not in the pack.
5. Sector condition effects on price and repair. SECTOR_CONDS is referenced but its entries are not shown. The price and repair fields are used but their ranges are unknown.
6. The equivHull mapping. Shipyard stock calls equivHull(h, RUN.fac) to translate the base hull list into faction equivalents, but the mapping is not provided. I cannot verify which faction gets which hull or confirm cp values.
7. CP cap progression. RUN.cpCap is checked but never defined in these slices. Fleet size constraints are invisible.
8. The "field" node type that genSector places. Its economic effect (if any) is unspecified.
9. Boss reward structure and post-boss economy. The boss node is generated but its reward logic is not in the pack.
10. The Godot port. The title line says "the Godot port mirrors this design," but no Godot code is provided to verify.

## QUESTIONS FOR THE DESIGNER

1. What does a battle pay, and what do you want it to pay? The entire FLOW question is unanswerable without reward values, and your own Q5 ruling flags them for rebalancing. Until those numbers exist in a reviewable form, no economy audit can close. Stakes: without income data, every spending-side finding is provisional because we cannot say whether the pinch is real or imagined.
2. Should repair cost scale with ship tier or mark? At 1 credit per 2 HP flat, repairing a 3-cp cruiser is trivially cheap, but repairing a Mk3 dreadnought (if such a thing exists) would also be trivially cheap per HP. A flat rate means repair never becomes a meaningful cost on the ships that matter most. Stakes: if repair stays flat, the post-boss regroup ruling is cosmetic and the player never faces the "leave a ship damaged" decision you want.
3. Is the Voidsworn economy intentionally blank? They are the title faction, yet their FAC_PRICE is one Carrier multiplier. If the design intent is that Voidsworn is the "baseline" (like Hegemony), that should be stated. If they are meant to have an economic identity, they currently lack one. Stakes: the player character faction having no price personality is a missed identity lever that every other faction gets.
