# DeepSeek blind leg: skill tree and leveling proposal validation (Oct 28, 2026)

Chair note: filed verbatim from the model's reply (DeepSeek, DeepThink ON + Search ON, verified by toggling). Em dashes and en dashes normalized to hyphens per house rule; wording otherwise unchanged. Chat: https://chat.deepseek.com/a/chat/s/3cff14e9-ed3b-4243-af31-51c87f3451a7. Evidence pack: the Oct 28 battle program tree validation pack (the chair's tree_proposal_v1.md under review, plus ruled premises and as-built systems). Method notes and screening live outside this file.

## 1. Proof of reading

Read: EVIDENCE PACK title line; THE COMMISSIONER'S QUESTION; PREMISES P1-P5; THE SYSTEMS AS BUILT; THE PROPOSAL UNDER REVIEW sections 1-9.

Overall verdict: NOT READY - the tree/pick counts and content math contradict themselves, the renown horizon uses sinks the proposal removes, and the Kassar example breaks the proposal's own rules.

## 2. Findings

1. [BLOCKER] [READ] The tree cannot be mapped onto the stated level picks. Section 3 says levels 5-8 each give "one skill from the admiral's tree," but the skeleton is "3 branches x 3 tiers x 2 choices = 18 skill slots plus a 2-choice capstone." Three tier levels plus one capstone cannot fill or even define an 18-slot tree; if each branch tier unlocks at levels 5-7, the player gets 9 tier picks, not 3.

2. [BLOCKER] [READ] The content budget is undercounted under its own sharing scheme. Tier 3 is "unique per admiral": 3 branches x 2 choices = 6 unique tier-3 skills, plus 2 capstone evolutions = 8 unique per admiral, or ~192 unique skills across 24 admirals - not "about 5 skills" and "about 120 unique skills." If capstone is counted as one, it is still ~168 unique.

3. [BLOCKER] [READ] The renown scaling claim contradicts section 7. Section 7 removes the admiral unlock ladder; section 8 still cites "1,815 total sinks" as a "30-plus run horizon." Removing the 930-renown admiral ladder leaves 885 renown (635 LEGACY + 250 hull variants), not 1,815. At ~45-100 renown per run, doctrine is far shorter than the proposal claims, weakening P2 scaling at run 15+.

4. [BLOCKER] [READ] Kassar's "Replacement Pool" violates P4/rule 4. It makes a lost escort class available "at half price," while section 7 says doctrine includes "price cuts." A tree skill duplicating doctrine's price-cut territory breaks the doctrine/lineage split. "Registry Priority" ("starting protocol from the line's favored core") is also close to core-sync/doctrine territory and needs audit against the missing LEGACY item list.

5. [FIX] [READ] The Kassar example breaks rules 1 and 2 repeatedly. Rule 2 says stat effects live on Branch C and at most one in three skills may be pure stat; the example puts stat/economic effects in A/B: Wide Net (+1 hex), Shared Solution (aim sharing), Screen Doctrine (CP cost), Cadet Volleys (aim bonus), Replacement Pool (half price). Branch C also has Reinforced Bridge ("+10% hull"), which directly fails rule 1's under-15% floor, and Ceremonial Broadside (pure aim boost).

6. [FIX] [READ] "Martyr Protocol" violates rule 5: "when the flagship falls, the fleet keeps sync for 2 rounds" rewards dying. Rule 5 says "nothing in a tree may reward losing, dying, or retreating." This is a direct internal contradiction.

7. [FIX] [READ] Renown-priced respec blurs the P4 split. The proposal says respec "costs renown" and "doctrine pays to retrain a line," but renown is the doctrine currency. It also incentivizes commitment over experimentation, in tension with P3's horizontal-first, decision-weight target.

8. [FIX] [INFERRED] Shadow XP at 25% is directionally right but unproven. At ~43 XP per win, a benched same-faction admiral earns ~10.75 per flown win; level 5 takes ~7 faction wins versus ~2 for the flown admiral. That makes switching a decision, not a reset, but with 80% losses and low loss XP the bench may warm too slowly; at a higher rate the flown-admiral premium vanishes.

9. [FIX] [READ] Per-admiral scaling stops at level 8. The proposal calls level 8 "a 5-to-6-win project per admiral," but P2 requires scaling at runs 15 and beyond. After a favorite caps, scaling rests on breadth across 24 lines and doctrine - and finding 3 shows the doctrine horizon is overstated.

10. [NOTE] [READ] Heat paying bonus XP to the flown admiral's line is plausible, but "flown admiral only" concentrates progress on the favorite and fights the shadow-XP anti-benching logic. The direction fits P4 better than renown-only Heat, but the recipient and rate are not settled.

## 3. Explicit checks

a. THE SPINE. Assumption: loss XP = 8 per loss, marked INFERRED; the pack only says "losses less" than 43. Trace on one favored admiral flown every run at 80% losses: run 1 loss -> 8 XP, level 2; run 2 loss -> 16, level 3; run 4 loss -> 32, level 4; run 5 win -> 75, level 5 and first tree choice. Run 10: two wins + eight losses ~ 150 XP -> level 6, second tree pick, not level 7. Run 15: three wins + twelve losses ~ 225 XP -> level 7, third tree pick; capstone at 230 is just out of reach. With 10 XP per loss, run 10 reaches level 7 and run 15 reaches level 8. So choices land at run 5, run 10, and run 15, but they are sparse - one pick per level band - and the 18-slot tree structure makes the actual number of picks incoherent.

b. THE RULES. Kassar audit: rule 1 breaks or borderline breaks: Reinforced Bridge ("+10% hull," below the 15% floor), Ceremonial Broadside (pure aim), Line Standard (extra debrief lesson, not a decision), Heir Apparent (bench meta, not battle/map/debrief decision); Wide Net and Shared Solution are numeric and likely fail the decision test. Rule 2 breaks: Wide Net, Shared Solution, Screen Doctrine, Cadet Volleys, Replacement Pool, Reinforced Bridge, Ceremonial Broadside - stat/economic effects outside Branch C and more than one in three. Rule 3 is mostly obeyed in idiom; no clear break. Rule 4: Replacement Pool is a price cut, directly doctrine-shaped; Registry Priority is a likely core/doctrine overlap but cannot be fully confirmed without the 12 LEGACY item effects. Rule 5: Martyr Protocol rewards the flagship dying. Rule 4 and rule 5 are the clearest failures.

c. THE BUDGET. The sharing scheme is coherent only as a label, not as a budget. Faction tier 1: 3 branches x 2 = 6 per faction, 36 shared. Archetype tier 2: 12 pairs x 6 = 72 shared. Unique tier 3: 6 per admiral; capstone two evolutions: 2; ~8 x 24 = ~192 unique. Total distinct authored content is closer to ~300 than "about 120 unique plus shared sets." Sameness leaks back at tier 1: four admirals in a faction share tier-1 skills even though each admiral's tree is supposed to be themed to their own distinct Command; tier 2 sharing within an undefined "archetype pair" has the same identity risk.

d. THE SPLIT. The split mostly holds at the level of XP/lineage versus renown/doctrine, but the closest items cross the line: Replacement Pool ("half price") is doctrine's "price cuts"; Registry Priority ("favored core") is close to core sync/doctrine; respec spends renown on lineage. On the lineage side, shadow XP, debrief lessons, Heir Apparent, and capstone evolutions are clearly lineage-shaped. The split needs an explicit doctrine-effect audit before shipping.

e. SHADOW XP AND RESPEC. Shadow XP at 25% supports P2 by letting a faction bench warm without erasing the flown admiral's premium; it supports P3 by making breadth possible. But it is a guess: too low and the rational player never switches; too high and leveling the bench is free. Renown-priced respec supports build identity but discourages experimentation, which is in tension with P3's horizontal-first target; it also spends doctrine currency on lineage, blurring P4.

f. HEAT. Bonus XP to the flown admiral's line is a reasonable candidate: difficulty feeds lineage, not doctrine, and trees across 24 admirals give it long-term value. But "flown admiral only" concentrates progress and conflicts with shadow XP's breadth incentive. A split between flown XP and faction shadow XP, or a faction-lineage XP pool, would fit P3/P4 better. Renown-only Heat would feed doctrine and worsen the split; XP-only Heat is directionally correct but not fully specified.

## 4. RUN 5 / RUN 10 / RUN 15

Run 5: The favored admiral is level 5 with the trunk complete and the first tree choice pending or just made; the rest of the faction is low. The pending choice is the first branch tier, and the chase is level 6 and a second tree pick.

Run 10: The favorite is level 6-7 with two or three tree choices locked; a second same-faction admiral may be mid-trunk from shadow XP. The pending choice is the next tier or capstone approach, and the chase is capstone access, faction bench depth, and remaining doctrine - though the doctrine horizon is shorter than section 8 claims.

Run 15: The favorite is level 7-8 with the capstone in reach or taken; a second admiral is likely around level 5. The pending choice is the capstone or another admiral's first tree pick, and the chase is finishing lines across 24 admirals plus the remaining renown sinks - but per-admiral scaling has stopped, so P2 beyond 15 depends heavily on breadth.

## 5. Not checked

Not checked: the 12 LEGACY item effects (only total renown is given), exact loss XP rates, exact Heat payout numbers, full Command mechanics beyond the named examples, bossmatrix balance, story-gating shape, Nemesis adaptation, hull variants, UI/debrief implementation, and actual player tolerance for 80% losses.

## 6. Questions for the designer

1. How many tree picks does an admiral actually get at levels 5-8, and does a level unlock one branch tier or all three branch tiers? Stakes: this fixes the 18-slot versus 3-pick contradiction and determines the content budget.
2. Is unique tier-3 content two skills per branch plus two capstone evolutions per admiral? Stakes: this determines whether unique authored skills are ~120 or ~200+.
3. With the admiral unlock ladder removed, is the intended renown horizon 885 remaining sinks, and what keeps doctrine scaling past run 15? Stakes: P2's run-15-and-beyond scaling claim depends on the answer.
