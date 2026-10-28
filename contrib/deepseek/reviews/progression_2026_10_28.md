Filed copy note (chair): em dashes in the original normalized to hyphens; wording otherwise verbatim.

1. Proof of reading
Slice	Line span as given
data.js - FACTIONS tail, ADMIRALS (cost field), LEGACY, name pools	lines 195-280
data.js - HULL_VARIANTS, MASTERY_XP, MASTERY_PERKS, FAVOUR_TIERS, HEAT, ARCHETYPES, NODE_MODS	lines 545-616
core.js - defaultMeta and the first-load progression credit	lines 45-70
campaign3d.js - runRenown	lines 25-35
main3d.js - boot, including the unlock grant	lines 1-20
campaign_meta.js - title, admiral select, run options, aspect, Progression screens, buy actions, help, end-of-run	FULL (216 lines)
CHAIR SHEET	computed, not a file slice

OVERALL VERDICT: BYPASSED - the boot path sets META.unlocked and META.admirals true for every entry on every load, so 1,565 of the chair's 1,815 renown of sinks cost nothing and renown's only live spend is the 250 of bought variants.

2. Findings, most severe first

1. BLOCKER (OBSERVED). The boot grant is on by default, not opt-in: if(o.unlockAll!==false){ for(const k in LEGACY) META.unlocked[k]=true; and the same loop for ADMIRALS. defaultMeta() returns opts:{}, so o.unlockAll is undefined, and undefined!==false is true. Every player gets all 12 LEGACY items and all 24 admirals on first boot.

2. BLOCKER (OBSERVED). Even with the grant disabled, the admiral ladder has no purchase UI. legacyScreen() builds tabs variants/mastery/favour/heat/fallen only; the admiral cards render the string Unlock for ${a.cost} renown in Legacy - a screen this file no longer contains. ACT.buyAdmiral exists but no button reaches it. The 930-renown admiral sink is orphaned, and the "0/30/45/80" ladder is dead text.

3. FIX (INFERRED from OBSERVED tables). Renown has no repeatable sink. Live spend = 12 variants = 250 renown. At the chair's ~100/win that is filled in about 2.5 winning runs; after that renown accumulates with no consumer at all. This, not slowness, is the pacing break.

4. FIX (OBSERVED arithmetic). The chair's win estimate checks: 12x2 + 3x4 + 3x15 + floor(48/4) + (3-1)x5 = 24+12+45+12+10 = 103, and the code is return s.battles*2+s.elites*4+s.bosses*15+Math.floor(s.kills/4)+(RUN.sector-1)*5;. Totals also check: LEGACY sums to 635, variants to 250, admirals to 155x6=930. But the two loss figures (44, 8) are given with no stated assumptions, so they cannot be checked - only the win case has assumptions.

5. FIX (INFERRED). The chair is generous on mastery. endRun pays s.battles+s.elites*2+s.bosses*5+(victory?10:0) = 12+6+15+10 = 43 of the 50 needed for level 4 in a single winning run. So "about 2 winning runs" is really ~1.2: the second win is only needed for 7 XP. Level 4 arrives early in run 2.

6. NOTE (OBSERVED). Mastery level 1 - "Choose a second starting fleet" - costs 6 XP, i.e. one battle won. The first meaningful perk is nearly free, so the per-admiral ladder is a very short clock; it is stretched only by there being 24 admirals.

7. NOTE (OBSERVED). Core sync is the only clock that survives past run 3, and its tier 2 payoff is real power ("you start with one of its protocols"). But the Progression prose says rare counts double and epic triple, while the backfill arithmetic is m.favour[p]=(m.favour[p]||0)+1+(e.r||0); - the multiplier lives in a logged e.r whose computation is not in the pack. The prose and the arithmetic cannot be reconciled from this evidence alone.

8. NOTE (OBSERVED). Heat's reward is nominal. The UI prints +${hl*10}% renown and the code comment says "each level adds 10% renown" - roughly 10 renown per level against a 250 sink that is already exhausted by then. The durable reward in the code is the record: if(victory&&hl){ META.heatBest=META.heatBest||{}; META.heatBest[RUN.fac]=....

9. NOTE (OBSERVED, on intent). Two signals say the bypass is a leftover, not design: defaultMeta() ships admirals:{vex:true} (one free starter), and every faction's first admiral has cost:0. The schema's own default gates admirals; the boot line ungates them.

10. NOTE (OBSERVED). The only currency a new player starts with is the capped backfill: m.renown=(m.renown||0)+Math.min(60,m._back||0); - 60 renown buys three of the cheapest variants (15 each) out of twelve. Abandoned runs also pay out (ACT.abandonRun calls endRun(false,true)), so there is no penalty path, only a slower one.

3. Checks

a. THE BYPASS. Renown stops being a currency: 1,565 of 1,815 renown of sinks are pre-satisfied at boot, so the only thing money buys is 250 renown of hull variants. The admiral cost ladder (0/30/45/80 per faction) is not merely bypassed but unreachable - no tab or button calls buyAdmiral, and the card text points at a "Legacy" screen that no longer exists. A new player's first run therefore has no gating anywhere: 24 admirals, all commands, 60 renown, and the choice is a pure build decision. The pack does contain evidence of intent: defaultMeta unlocks only vex, and cost:0 marks the starter admiral in every faction, both of which presuppose locked peers. Combined with the !==false idiom (a dev "default on" flag, not a player-facing option - nothing in the pack ever writes opts.unlockAll), this reads as a leftover debug default rather than a deliberate all-access design. I cannot prove intent from the pack; I can say the surrounding schema contradicts the boot line.

b. PACING. Verified the formula and totals first (finding 4). Filling each sink at ~100 renown per win: LEGACY 635 is about 6.4 wins; one faction's admiral ladder 155 is about 1.6 wins; all admirals 930 is about 9.3 wins; bought variants 250 is about 2.5 wins. Chair's "18+ winning runs" for 1,815 is arithmetic-correct (18.15). The break is not the rate, it is the availability: three of those four sinks are not purchasable in the shipped build, so the effective sink set is 250 renown, about 2.5 wins, and after that income has no destination. The chair sheet measures a market that the boot line and the missing tab have closed.

c. SINK QUALITY. Power: u_battleship/u_dread, cmd1/cmd2, vets, and every variant hull (variants are sidegrades with real stat/arc changes). Options: u_carrier, the admirals themselves (fleet + Command). Convenience/economy: chest1-3, founder, wrights, salvagers. Yes, there is a classic save-for-it item in the table - u_dread at 120 renown ("may take one Daybreak-class dreadnought") is exactly the multi-run trophy - but it is granted at boot, so no player ever saves for it. Post-bypass, the largest single purchase available is 30 renown, i.e. nothing is a trophy.

d. MASTERY AND SYNC. They are earned by different behaviours (renown by raw wins/kills, mastery by repeatedly flying one admiral, favour by routing toward a core's signals), so on paper they complement: three playstyles, three tracks. In practice two of the three are short. Mastery level 4 lands in ~1.2 wins (finding 5), and renown is exhausted at ~2.5 wins. Favour is the only clock still running at run 5 - but the pack does not show how many protocol picks a run offers or how signal routing allocates them, so its real length can only be estimated from the 0/4/12/25 tiers. What a player chases on run 5 that they were not chasing on run 1: favour tiers on a chosen core (and Heat records if they have won). On run 1 they chase variants and a first admiral mastery level - both of which they will have finished by run 3.

e. HEAT. Wrong reward shape for this economy. At a ~17% win rate most Heat runs end in a loss, and a loss still pays, so Heat is a tax on a currency with nothing left to buy - +10% of ~100 renown per level against a 250-renown sink already filled. The one part of the implementation that is correctly shaped is the record: heatBest per faction is a durable, comparable achievement that does not depend on the dead currency. If Heat is to matter, its payoff has to be a record, a cosmetic, or access - not renown.

4. RUN 1 / RUN 5 / RUN 10

Run 1. Everything is already unlocked at boot; 60 backfill renown; the player picks any of 24 admirals and any faction. Ends with ~8-100 renown, one mastery level or two on the admiral flown, and maybe one cheap variant. Rewarded by the run, not by the systems.

Run 5. Roughly two to three wins of income: most or all of the 12 bought variants owned, mastery 4 on the one to three admirals actually flown, favour at tier 1-2 on one core, Heat open with a heatBest on one faction. Still something to chase (favour), but the renown line has gone quiet.

Run 10. All variants bought, mastery capped on every admiral used, renown piling up with no sink, favour still climbing on whichever core the player routes to, Heat records the only novelty. The recap screen's "Carried forward: +N renown... Spend it on hull variants" would be pointing at an empty shelf.

5. NOT CHECKED

The body of heatLevel() (so whether "+10% per rule" scales with w:1 vs w:2); whether shipyards actually stock META.variants (the claim "sits beside the standard hull" is UI prose only - no stock code in the pack); the ASPECTS, BOONS, PATRONS, MODULES tables; how many protocol picks a run offers and how map signals assign cores; the arc-variant unlock trigger (ARC_VARIANT, v.arc) and whether it writes META.variants; whether LEGACY/admiral fx are actually applied in derive()/newRun; whether any UI writes opts.unlockAll; and the ~17% win rate itself, which is asserted by the brief and not present in the pack.

6. QUESTIONS FOR THE DESIGNER

Is unlockAll meant to ship on (demo/all-access build) or should it default off at release - and if off, where does the admiral purchase UI live now that "Legacy" is gone?

Are admirals intended to be free from the start, with cost as vestigial data, or is the 0/30/45/80 ladder supposed to be a real gate?

Once the 12 bought variants are owned, what is renown for - is a repeatable sink planned, or does renown become a Heat/record currency only?
