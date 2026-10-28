Filed copy note (chair): em and en dashes in the original normalized to hyphens; wording otherwise verbatim.

Proof of reading

- data.js lines 150-200: MODULES and RELICS.
- data.js lines 617-697: PATRONS intro, BOONS (all 48), ASPECTS (all 6).
- core.js lines 175-250: fleetKit, modulePool, relicUseful, rollBoonOffer, rollNodeReward.
- campaign_run.js lines 390-544: full post-battle reward flow.
- CHAIR SHEET: no line span; computed summary.

OVERALL VERDICT: REWARDS ARE MIXED - protocol offers, rerolls/declines and map labels create real choices, but fallback bugs, default bias, and shallow relic/module pools make many reward picks value comparisons or click-throughs.

Findings

1. FIX (OBSERVED) - Patron-branded boon offers can fall back to other patrons, breaking patron identity and duo planning. Quote: `BOONS[id].p!==p&&RUN.patrons.includes(BOONS[id].p)`.

2. FIX (OBSERVED) - Legendary insertion happens after duo insertion and can overwrite the third slot, deleting a duo offer. Quote: `if(out.length>=3) out[2]={id:L,r:3};`.

3. FIX (OBSERVED) - `modulePool` falls back to all modules when fewer than three are useful, so refit/salvage can offer unusable modules. Quote: `return ok.length>=3?ok:all;`.

4. NOTE (OBSERVED/INFERRED) - Prize screen defaults to Add when the ship fits and has ≥40% hull, and confirmation is one click; this biases players toward adding. Quote: `dk=room&&(p.hpf||1)>=.4?'add':`.

5. NOTE (OBSERVED/INFERRED) - Normal nodes are heavily boon-weighted; credits and repairs are narrow alternatives. Quote: `x<.62?{k:'boon',p}:x<.78?{k:'mod'}`.

6. NOTE (OBSERVED/INFERRED) - First reroll costs 25, low against modules costing 55-90 and normal battle base credits; it may be underpriced. Quote: `return 25+15*((RUN&&RUN.boonRerolls)||0);`.

7. NOTE (OBSERVED) - Salvage yield chooses the first eligible module deterministically, not randomly among eligible modules. Quote: `m=intact&&pickM.length?pickM[0]:null`.

8. NOTE (OBSERVED/INFERRED) - Relic pool is only 12, with elites offering 2 and bosses 3; repetition likely before protocols repeat. Quote: `slice(0,cfg.kind==='boss'?3:2)`.

9. NOTE (OBSERVED/INFERRED) - Aspects are set at run start from three random options, so reward choices refine rather than create the flagship identity. Quote: `from three offered at random`.

10. NOTE (OBSERVED) - Boon fallback can also push junk boons when useful same-patron pool is short. Quote: `while(out.length<3&&junk.length) out.push`.

a. THE OFFER
The choice is real but partly softened by pricing. A player rerolls when the three offers lack a needed patron/duo, have low rarity, or miss the build’s kit; decline is for credits when none fit or after a failed reroll. Reroll starts at 25 and rises by 15 per prior reroll; decline is `30+10*sector`. Against module costs of 55-90 and normal battle base credits of `25+12*s+3*col`, reroll looks cheap early. The pack does not show full credit sinks/income, so the pricing is plausible but not fully judgeable.

b. THE DISTRIBUTION
Seeing the reward before the fight makes routing informed, not blind. Because the map shows the patron sigil, routing can target a patron for duo/legendary progress. But normal nodes are 62% boon, with only 12% credits and 10% repairs; unless the fleet is damaged or broke, most routes likely prefer the boon node. So routing is a real strategic decision, but often a shallow one.

c. SOLVED CHOICES
The battle reward layer does not show the same wholesale solved-choice disease as the events audit: offers filter for useful kit, rarity/duo/legendary vary, and reroll/decline exist. Still, there are default/dominant paths: prize Add is default when it fits, salvage often prefers a useful module, and module/relic picks are mostly numeric. These are softer than “one option always right,” but they reduce decision pressure.

d. THE POOL
The protocol pool is deep on paper: 48 total, but normal offers exclude legendaries and only four of six patrons are active. Modules are 13 and relics 12; aspects are 6 but only three are offered at run start. Relics and modules will saturate first; protocols will repeat across runs, especially if many boon nodes are taken. The pack lacks map node counts, so exact repetition timing cannot be computed.

e. THE CHAIN
Prize decisions carry the most weight: add vs strip vs ransom involves command points, hull, faction gate, and ransom decay. Salvage is medium weight: one wreck, module vs credits vs tow. The node reward is high-value but often one pick; promotions are click-through when no captain has pending XP. The order hurts adaptation slightly: prize and salvage are committed before the node boon/refit is seen, so a player can duplicate or misalign refits.

RUN 1 / RUN 5 / RUN 10

- Run 1: Novelty dominates. Three aspects, four patrons, varied protocol offers, reroll/decline, and map labels make rewards feel responsive.
- Run 5: Pools become familiar. Relics/modules repeat, prize defaults are known, and duo/legendary planning starts to matter. Choices shift from discovery to optimization.
- Run 10: Most relics/modules have been seen; protocols repeat by patron and build. Reward screens become value/default checks unless a duo or legendary is in reach. Aspect and patron pairing define the build more than individual reward picks.

NOT CHECKED
Exact map node counts, full credit income/sinks, shop prices beyond modules, enemy difficulty scaling, `MOD_NEED`, full event audit, actual player behavior, UI readability, and whether specific boon effects are balanced in battle. The pack also does not show aspect selection code beyond the comment.

QUESTIONS FOR THE DESIGNER

1. Is the off-patron fallback in `rollBoonOffer` intentional, or should patron rewards always be same-patron or duo?
2. Should a legendary overwrite the third slot even when that slot is a duo offer?
3. What credit-income/sink target should reroll and decline prices be balanced against?
