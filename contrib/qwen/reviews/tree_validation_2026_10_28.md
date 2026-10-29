# Qwen blind leg: skill tree and leveling proposal validation (Oct 28, 2026)

Chair note: filed verbatim from the model's reply (Qwen3.8-Max, both model gates passed; no Access Verification puzzle this run). Em dashes normalized to hyphens per house rule; wording otherwise unchanged. Chat: https://chat.qwen.ai/c/4c8cfb29-a927-41de-a72d-027b5ad44553. Evidence pack: the Oct 28 battle program tree validation pack (the chair's tree_proposal_v1.md under review, plus ruled premises and as-built systems). Method notes and screening live outside this file.

# BLIND REVIEW REPORT

## Proof of Reading

Sections read:
- EVIDENCE PACK title line: "EVIDENCE PACK: skill tree and admiral leveling proposal validation (a design proposal, not code)"
- THE COMMISSIONER'S QUESTION
- PREMISES (P1 through P5)
- THE SYSTEMS AS BUILT
- THE PROPOSAL UNDER REVIEW, sections 1 through 9 (backbone, one-paragraph summary, structure, skill design rules, Kassar worked example, respec and catch-up, neighboring systems, scaling trace, known risks)

Verdict: SOUND WITH CONDITIONS. The spine delivers on P1-P3 and the trunk-into-tree shape is correct, but the content-budget arithmetic is internally contradictory, one worked-example skill breaks the proposal's own Rule 1, and the "archetype pair" sharing layer is asserted but never defined.

## Findings

1. [BLOCKER] Content-budget arithmetic does not close.
The proposal states tier 3 (3 branches x 2 choices = 6 skills) plus capstone (2 choices) are unique per admiral: 8 unique skills x 24 admirals = 192. It then claims "Unique authored content per admiral: about 5 skills" and "Across 24 admirals: about 120 unique skills plus the shared sets." 8 != 5; 192 != 120. The draft's own section 9 concedes this is "the most attackable number." The number is not merely attackable; it is wrong by the skeleton's own definition. READ.

2. [BLOCKER] "Archetype pair" (tier 2 sharing) is undefined.
Section 3 states "tier 2 skills are shared within an archetype pair" but never defines what an archetype is, how the 24 admirals are paired, or what principle governs the pairing. Without this, the tier-2 budget (12 pairs x 3 branches x 2 choices = 72 skills) is unverifiable and the sharing scheme is incomplete. INFERRED: the designer may intend Command-similarity grouping, but the pack does not say so.

3. [FIX] Reinforced Bridge violates Rule 1.
Rule 1: "If it only changes a number by less than 15 percent, it does not ship." Reinforced Bridge is "flagship +10% hull." Ten percent is below fifteen. The skill fails the proposal's own gate. READ.

4. [FIX] The "5-to-6-win project" framing contradicts the stated XP math at 80% losses.
Section 3 calls level 8 "a 5-to-6-win project per admiral: deep enough to be a run 10 to 15 goal." At 80% losses, 5-6 wins require 25-30 total runs. Section 8 then traces run 15 as "first capstone in reach," which is consistent only if losses pay roughly 8-10 XP each (INFERRED; the pack says losses pay "less" than 43 but gives no figure). The "5-to-6-win" language misleads; the actual pacing depends on an unspecified loss-XP rate. The claim and the trace are in tension. READ / INFERRED.

5. [FIX] Ceremonial Broadside is a pure stat bump that may not clear Rule 1's 15% bar.
"Flagship's first volley each battle aims 10 better." Whether +10 aim exceeds 15% depends on base aim values the pack does not state. INFERRED: if base aim sits around 50-70, +10 is 14-20%, straddling the threshold. The skill also does not obviously change a decision; it makes one volley hit more. At minimum it needs a stated base to validate. READ / INFERRED.

6. [FIX] Heir Apparent (Branch C tier 3) is a meta-progression lever, not a battle/map/debrief decision.
Rule 1 requires a skill to "change a decision the player makes in battle, at the map, or at the debrief." Heir Apparent doubles shadow XP for a benched successor. It changes which admiral the player levels passively, not a decision in any of the three listed arenas. It is a catch-up mechanic wearing a skill slot. READ.

7. [NOTE] Martyr Protocol brushes Rule 5.
Rule 5: "Skills never face backward: nothing in a tree may reward losing, dying, or retreating." Martyr Protocol triggers "when the flagship falls." It does not incentivise the flagship's death, but its value is only realised on a loss event. It is the closest item in the worked example to the Rule 5 line. READ.

8. [NOTE] Screen Doctrine and Replacement Pool sound doctrinal in a lineage slot.
Both are fleet-logistics effects (escort cost reduction, half-price replacement) that read as faction-wide policy. They are per-admiral here, so they do not technically duplicate LEGACY items, but their fiction and function sit closest to the doctrine side of the P4 line. An audit against the 12 LEGACY items (not listed in the pack) is needed. READ / INFERRED.

9. [NOTE] Shadow XP at 25% is self-flagged as unvalidated.
Section 9: "25 percent is a guess wearing a number's clothes." The principle (bench warming) is sound against P2 and P3, but the rate has no supporting math. At 25%, a benched faction-mate earns roughly 11 XP per flown win; over a 15-run career (~3 wins) that is ~33 XP, putting the bench at level 2-3. That is reasonable but untested. READ.

10. [NOTE] Respec priced at "roughly one winning run's pay" (~100 renown) competes with LEGACY sinks.
Total renown sinks are 1,815. A player who respecs twice on one admiral spends ~200 renown, over 10% of the entire doctrine/hull/lineage-unlock budget. This creates a real opportunity cost, which supports P3 decision weight, but could feel punitive in a game where 80% of runs lose and earn under 45 renown. READ / INFERRED.

## Explicit Checks

### a. THE SPINE

Trunk-plus-tree can deliver meaningful choices at runs 5, 10, and 15, but only if loss XP is specified and lands in the 8-12 XP range.

Traced career for one admiral, 80% losses, assuming loss XP ~ 10 (INFERRED):

| Run | W/L | Cumulative XP | Level | Event |
|---|---|---|---|---|
| 1 | L | 10 | 0->1 | First of the line; debrief shows trunk step 1 |
| 5 | ~1W/4L | ~83 | 4->5 | Trunk complete; first tree choice (Branch A tier 1) |
| 10 | ~2W/8L | ~166 | 6->7 | Three or four tree choices locked |
| 15 | ~3W/12L | ~249 | 8 | Capstone choice pending |

The choices land. Run 5 gives the first identity fork; run 10 gives a shaped build; run 15 delivers the Command evolution. The spine works if and only if loss XP is fixed at a rate that makes the above table true. The proposal never states that rate. Without it, the "5-to-6-win project" language implies a 25-30-run horizon, which pushes the capstone past run 15 and breaks the scaling promise. The spine is sound in structure, underspecified in arithmetic.

### b. THE RULES (Kassar audit)

| Rule | Verdict |
|---|---|
| R1 - change a decision | Reinforced Bridge fails (+10% hull, under 15%). Ceremonial Broadside is borderline. Heir Apparent does not change a battle/map/debrief decision. All other 15 skills pass. |
| R2 - <= 1/3 pure stat | 2 pure-stat skills out of 18 (11%). Passes. |
| R3 - faction idiom | All skills are framed in Hegemony military-doctrine language. Passes. Heir Apparent is the weakest fit (it is a meta-progression lever, not a "doctrine revision the line drills"). |
| R4 - no LEGACY duplication | Cannot fully audit: the 12 LEGACY items are not listed in the pack. Screen Doctrine and Replacement Pool are the closest to the line (see Finding 8). INFERRED: no duplication on the evidence available, but the audit is incomplete. |
| R5 - never face backward | Martyr Protocol triggers on flagship destruction. It does not reward the loss, but it is activated by it. Borderline. All others pass. |

Skills that break a rule: Reinforced Bridge (R1). Borderline: Ceremonial Broadside (R1), Heir Apparent (R1), Martyr Protocol (R5).

### c. THE BUDGET

The sharing scheme (faction tier 1 -> archetype tier 2 -> unique tier 3 + capstone) is coherent in principle. It gives every faction a shared vocabulary at tier 1, narrows to pairs at tier 2, and reserves identity for tier 3 and the capstone. The gradient from generic to specific is the right shape for 24 admirals.

Where sameness leaks back in:

- Tier 1 within a faction: four admirals share the same six tier-1 skills (3 branches x 2 choices). Two Hegemony admirals at level 5 will have identical tier-1 picks available. The tree screen will look the same for all four. The faction idiom helps fictionally, but mechanically the first tree choice is not distinguishing admirals from each other.
- Tier 2 within an archetype pair: two admirals share tier 2. If the pairing is by Command similarity (INFERRED), their tier-2 choices will feel alike by design. The differentiation only arrives at tier 3.
- The undefined archetype: because "archetype pair" is never specified, there is no way to verify that the 72 tier-2 skills are actually distinct from the 36 tier-1 faction skills. Sameness could leak between tiers.

The 120-vs-192 arithmetic error (Finding 1) means the stated budget is fictional. The real unique-skill count per the skeleton is 192, which is 60% higher than claimed. That is a real production risk.

### d. THE SPLIT

The doctrine-vs-lineage line holds in principle: LEGACY is faction-wide and bought with renown; the tree is per-admiral and earned with XP. P4 draws the constitution clearly.

Closest items to the line:

- Doctrine side: Screen Doctrine (escort command-point cost reduction) and Replacement Pool (half-price escort replacement) are logistics effects that read as faction policy. They are per-admiral in the tree, but a player encountering "Screen Doctrine" in a Hegemony tree will wonder why it is not a LEGACY item. Deep Magazine (torpedoes pre-loaded) also has a supply-chain flavour.
- Lineage side: Cadet Volleys (small ships inherit sync at half value) and Second Anchor (a cruiser inherits partial sync) are mechanically inseparable from Kassar's specific Command. They cannot be doctrine because they reference a single admiral's ability. Martyr Protocol is likewise Command-specific.

The line holds, but the faction-flavour language of Branch B tier 1 and 2 skills will need a post-draft audit against the 12 LEGACY items to confirm no functional overlap. The proposal itself flags this in section 9.

### e. SHADOW XP AND RESPEC

Shadow XP (25%):

- Against P2 (power accumulates, still scaling at run 15): 25% keeps bench admirals levelling slowly enough that switching at run 10 is a real decision, not a free reset. A benched faction-mate at run 15 sits around level 2-3, well behind the favourite at level 8. The bench is warm, not hot. This supports long-tail scaling.
- Against P3 (horizontal first): shadow XP widens the roster without granting vertical power to the benched admiral beyond trunk perks. It does not inflate numbers.
- Behaviour incentivised: the player keeps flying their favourite (the flown admiral earns 4x the XP) but does not abandon the faction. It makes the faction bench a slow-burn project rather than a dead zone. Sound in intent, unvalidated in rate.

Respec (renown-priced, ~100 renown):

- Against P2: the cost does not gate progression; it gates experimentation. A player who picks wrong at level 5 can fix it, but at the cost of a winning run's renown. This is fair in an 80%-loss game where wins are scarce.
- Against P3: locked choices with a real cost are the definition of decision weight. Free respec would delete the BattleTech gate, as the proposal correctly notes.
- Behaviour incentivised: commit to a build for several runs; respec only when the current build is clearly wrong or the player wants to experiment after the tree is mature. This is the right incentive for a roguelite.
- Risk: 100 renown per respec against 1,815 total sinks means two respecs consume 11% of the lifetime renown budget. In a game where a loss pays under 45 renown, that is several runs of income. This could make players risk-averse about experimentation, which cuts against P3's "widen options" goal. The price may need to scale down for early tree tiers. INFERRED.

### f. HEAT

The proposal answers the parked question: Heat pays bonus admiral XP (in addition to its existing +10% renown per Heat level).

Judgment: This is the correct answer. If Heat paid only renown, it would feed doctrine (faction-wide, LEGACY) and leave the new per-admiral spine untouched. Heat would become irrelevant to the core loop the redesign is building. By paying XP, Heat feeds lineage directly, making every Heat level a reason to re-fly an admiral who still has tree levels to earn. Because 24 admirals x 8 levels = 192 tree levels total, the XP sink is effectively bottomless; Heat remains valuable from run 1 to run 50.

Against alternatives the pack names or implies:

- Heat pays bonus renown only: feeds doctrine, ignores the spine. Rejected by the proposal's logic.
- Heat pays hull variants or unlocks: overlaps with the existing 250-renown variant sink; does not scale.
- Heat pays nothing new (keeps +10% renown): leaves the question open; the redesign cannot ship without an answer.

The proposal's answer is the strongest of the available options. The risk is that bonus XP compresses the level timeline: if Heat adds, say, +20% XP per Heat level, a player at Heat 3 earns 43 x 1.6 ~ 69 XP per win, accelerating the capstone by several runs. The tuning of the Heat-XP rate is as unvalidated as the shadow-XP rate. NOTE: the proposal does not specify the Heat-XP multiplier.

## RUN 5 / RUN 10 / RUN 15

Run 5. The player has one admiral they keep returning to - probably Kassar, probably the one whose Command clicked. Trunk complete: they have the alt fleet, the wider counsel, the second Command option, and the flag captain. At level 5 they have just made their first tree choice, say Wide Net over Second Volley. The pending question is the tier-2 fork: Shared Solution or Cold Drill? That choice will reshape how they position escorts. The faction bench is cold (shadow XP has trickled maybe 10-15 XP to the other three Hegemony admirals). What is still worth chasing: the rest of the tree, the capstone, and the second admiral's trunk.

Run 10. Kassar is level 6 or 7. Three or four tree choices are locked. The build is recognisable: maybe Wide Net -> Cold Drill -> Rolling Fire, a sync-chain build that plays aggressively around the flagship. The pending choice is tier 3 or the level-8 capstone. A second Hegemony admiral is mid-trunk, level 3 or 4, kept alive by shadow XP. Doctrine purchases are partway through the 1,815 renown budget. What is still worth chasing: the capstone (Living Relay vs One Voice), the second admiral's first tree choice, and the remaining LEGACY items.

Run 15. Kassar is level 8. The capstone is unlocked or one run away. The player has chosen Living Relay: sync projects at double radius, no line-of-sight needed. The fleet plays completely differently than at run 5. The second Hegemony admiral is at their first tree choice. The third is mid-trunk. Doctrine is maybe 60% purchased. Heat is unlocked and paying bonus XP, keeping the grind alive. What is still worth chasing: the other 23 admirals' trees, the remaining doctrine items, and the question of whether One Voice would have been better. The endgame is finishing lines, not filling a shop. The proposal's own words, and they hold.

## Not Checked

- The 12 LEGACY doctrine items are not listed in the pack. Rule 4 (no tree skill duplicates doctrine) cannot be fully audited.
- Loss-XP rate is stated as "less" than 43 but never quantified. All run-tracing above depends on an INFERRED value of 8-12 XP per loss.
- The 24 Commands beyond Kassar and the three Chorus examples are not described. Whether the skeleton (3 branches themed on Command / fleet / flagship) fits every Command type (e.g., the Chorus spawning surge or fleet-wide regrowth) is untested.
- Hull variants (250 renown) and their interaction with the tree are declared "untouched" but not examined.
- Nemesis adaptation is ruled visible at the debrief but is not in this proposal's scope.
- The "testing grant" bypass in the shipped build is acknowledged as a leftover bug; the review assumes the redesign context as instructed.
- Balance pass on 24 capstones (the "bossmatrix admiral band 55-85%") is flagged by the draft but not modelled here.
- The fiction and writing tone of the lineage idiom (Rule 3) across all six factions is not assessed; only Hegemony is worked.

## Questions for the Designer

1. What is the loss-XP rate? The entire run-5/10/15 trace and the "5-to-6-win project" claim depend on a number the pack never states. If losses pay 2 XP, the capstone is a run-30 event; if they pay 15, it is run 8. The pacing promise lives or dies on this single figure.
2. How do you resolve the 120-vs-192 unique-skill discrepancy? The skeleton as written produces 8 unique skills per admiral (192 total). The draft claims 5 (120 total). Either the skeleton shrinks (drop a branch, reduce choices) or the budget is 60% larger than stated. Which is it, and does the answer change the tier-sharing scheme?
3. What is an "archetype pair"? Tier-2 sharing depends on this grouping, but the pack never defines it. Without the definition, the 72 tier-2 skills cannot be authored, budgeted, or audited for sameness against tier 1. Name the pairs or name the principle.

Assumptions stated: loss XP estimated at 8-12 per losing run (INFERRED throughout). Base aim values for Ceremonial Broadside audit assumed in the 50-70 range (INFERRED). Heat-XP multiplier unspecified in the proposal; treated as unvalidated. All other claims marked READ or INFERRED inline.
