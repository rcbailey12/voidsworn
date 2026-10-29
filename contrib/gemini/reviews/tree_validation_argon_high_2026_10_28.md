# Argon blind leg: skill tree and leveling proposal validation (Oct 28, 2026)

Chair note: filed from the model's reply (Gemini, 4 Argon, Thinking level High; picker verified "Argon High" before sending and still Argon High after; inline citation chips omitted per instruction). Em dashes and en dashes normalized to hyphens per house rule; wording otherwise unchanged. Chat: https://gemini.google.com/app/8ee4223a05153414. Evidence pack: the Oct 28 battle program tree validation pack (the chair's tree_proposal_v1.md under review, plus ruled premises and as-built systems). Method notes and screening live outside this file. (Session note: after the completed response the new-prompt picker displayed Flash-Lite with a limit reset notice for 8:10 PM; the report itself was generated under the verified Argon High submission.)

## 1. Proof of reading

Sections read: EVIDENCE PACK: skill tree and admiral leveling proposal validation (a design proposal, not code) (title line), THE COMMISSIONER'S QUESTION, PREMISES (P1-P5), THE SYSTEMS AS BUILT, and THE PROPOSAL UNDER REVIEW: # Skill tree and admiral leveling: initial proposal v1 (1. What exists today (the backbone), 2. The proposal in one paragraph, 3. Structure, 4. Skill design rules (proposed), 5. Worked example (Kassar, Hegemony: synchronized fire), 6. Respec and catch-up (proposed, flagged as open), 7. What this does to the neighboring systems, 8. Scaling across runs 1, 5, 10, 15 (traced on measured earn rates), 9. Known risks the draft concedes).

Overall verdict: NOT READY - Five internal math and structural contradictions break the progression timeline, the content budget, the renown horizon, and Premise P5, while the worked example violates all five of the proposal's own skill design rules.

## 2. Findings

### [BLOCKER] Sharing Branch A at Tiers 1 and 2 contradicts Premise P5 and the definition of Branch A.

Basis: READ / INFERRED.

Analysis: Premise P5 rules that an admiral's design "must match their special ability (their Command)" and that all 24 admirals have a "distinct Command" (e.g., Chorus Commands are "a spawning surge, a free fleet-wide volley, and a fleet-wide regrowth"). Section 3 defines Branch A as deepening "the admiral's signature ability," yet budgets Tier 1 as "shared within a faction" and Tier 2 as "shared within an archetype pair". Kassar's own worked example proves this is impossible: his Branch A Tier 1 (Wide Net, Second Volley) and Tier 2 (Shared Solution, Cold Drill) are hard-coded to synchronized fire (READ). Admirals with distinct Commands cannot share Command-specific Tier 1 and Tier 2 skills; either Branch A Tiers 1-2 must be unique per admiral (adding 96 more unique skills) or Branch A becomes generic faction buffs, violating P5 (INFERRED).

### [BLOCKER] The authorship budget arithmetic in Section 3 undercounts unique skills by 60% (192 vs. 120) and total skills by more than double (300 vs. ~120).

Basis: READ.

Analysis: Section 3 defines the skeleton as "3 branches x 3 tiers x 2 choices = 18 skill slots plus a 2-choice capstone" and specifies that "tier 3 and the capstone are unique per admiral. Unique authored content per admiral: about 5 skills". Across 3 branches, Tier 3 has 3x2=6 skills, plus a 2-choice capstone (2 skills), which equals 8 unique skills per admiral (8x24=192 unique skills), not 5 per admiral or 120 total (READ). Including the shared sets - Tier 1 (6 skills x 6 factions=36) and Tier 2 (6 skills x 12 archetype pairs=72) - requires 300 distinct skills before even fixing the Branch A sharing failure in Finding 1 (INFERRED). Section 3 also contradicts itself in the same bullet on whether capstones are "chosen from two evolutions" (48 capstones) or "One capstone per admiral, hand-authored" (24 capstones, which eliminates the Level 8 choice) (READ).

### [BLOCKER] Section 3 and Section 8 contradict each other on how many tree skills an admiral unlocks per level.

Basis: READ.

Analysis: Section 3 states that across "Levels 5 to 8 (proposed XP 75, 110, 160, 230): tree levels. At each, the player picks one skill from the admiral's tree," with Level 8 reserved for the capstone. That grants only 3 branch skill picks total (at Levels 5, 6, and 7) out of 9 branch-tiers before hitting the level cap (READ). Yet the next bullet states "at each tier the player chooses ONE of two skills" across three branches (implying 9 branch picks), and Section 8 claims at Run 10 "the favorite is level 6 to 7 with three or four tree choices locked" (READ). A Level 6-7 admiral has only made 2 or 3 choices under a 1-pick-per-level rule, or 6 to 9 choices under a 1-pick-per-branch-tier rule; "three or four" at Level 6-7 is impossible under either rule (INFERRED).

### [BLOCKER] Keeping 4 rail levels (50 XP) before the first tree choice (75 XP) fails Premise P1 and P2 under an 80% loss rate.

Basis: READ / INFERRED.

Analysis: P1 sets the spine as "admiral leveling with skill choices in a small tree," while P2 states "about 80% losses by design; run 1 is near impossible". Because Levels 1-4 (6, 16, 30, 50 XP) keep "the trunk perks, unchanged" with "no choices anywhere in it," the very first tree choice does not occur until Level 5 (75 XP) (READ). Section 3 notes Level 5 lands after "roughly two winning runs on one admiral" (86 XP at 43 XP/win) and Level 8 (230 XP) is a "5-to-6-win project per admiral" (READ). At a 20% win rate (P2), 5-6 wins takes 25-30 runs (or ~11-13 runs on a single admiral when counting loss XP), and any player who rotates across 2-3 admirals early (as P1 encourages) spends their first 6-10 runs entirely on the Level 1-4 rails with zero skill tree choices made (INFERRED).

### [BLOCKER] Section 8's renown horizon (1,815 sinks) forgets that Section 7 deleted 930 renown of admiral unlocks.

Basis: READ.

Analysis: THE SYSTEMS AS BUILT states that total renown sinks are 1,815: 635 for LEGACY items, 930 for the admiral unlock ladder, and 250 for hull variants (READ). Section 7 deletes the 930-renown ladder ("The unlock ladder for admirals goes away as a renown purchase"), which cuts total renown sinks by 51% down to 885 renown (635 LEGACY + 250 hull variants) (INFERRED). Section 8 nevertheless claims that at Run 15+ "doctrine (renown) still unfinished (1,815 total sinks measured as a 30-plus run horizon)" (READ). On the proposal's own numbers (~100 renown per win, ~45 per mid-run death), 635 renown of LEGACY doctrine is bought out around Run 12-14, not Run 30+ (INFERRED).

### [FIX] Kassar's worked example breaks all five of Section 4's skill design rules and Premise P4.

Basis: READ.

Analysis: In Section 5, Reinforced Bridge ("flagship +10% hull") explicitly breaks Rule 1 ("If it only changes a number by less than 15 percent, it does not ship") (READ). Shared Solution and Cadet Volleys put passive aim stat buffs on Branches A and B, breaking Rule 2 ("those live on Branch C") (READ). Screen Doctrine and Replacement Pool grant fleet point/shipyard discounts, breaking Rule 4 by duplicating LEGACY doctrine's "price cuts" (READ). Registry Priority ("starting protocol from the line's favored core") violates P4 by crossing into the separate core sync track (READ). Finally, Martyr Protocol, Replacement Pool, Iron Tempo, and Second Anchor trigger on losing ships or taking crippling hits, violating Rule 5 ("nothing in a tree may reward losing, dying, or retreating") (READ).

### [FIX] Heir Apparent (Branch C, Tier 3) requires benching the admiral to function and becomes a dead slot at cap.

Basis: READ / INFERRED.

Analysis: Heir Apparent grants double shadow XP only "if this admiral's line is benched" (READ). It provides zero benefit while flying Kassar, changes no decision in battle, map, or debrief (violating Rule 1), uses meta-system jargon ("benched", "shadow rate", violating Rule 3), and becomes permanently useless once the other three Hegemony admirals hit Level 8 (INFERRED).

### [FIX] Trunk Level 3 ("a second Command option") collides with Branch A and Capstones that are hard-coded to the primary Command.

Basis: READ / INFERRED.

Analysis: Trunk Level 3 at 30 XP grants "a second Command option" (READ). However, Section 3 states that Branch A and the Level 8 Capstone are authored specifically to evolve "the admiral's signature ability" (for Kassar, every Branch A and Capstone skill modifies synchronized fire) (READ). If a player equips the Trunk Level 3 "second Command option," their entire Branch A and Capstone either break mechanically or force the player never to use the Level 3 trunk perk (INFERRED).

### [FIX] Renown-priced respec starves LEGACY doctrine early and becomes free once the 885-renown shop empties.

Basis: INFERRED.

Analysis: Section 6 prices a full tree respec in renown at "roughly one winning run's pay" (~100 renown) so that "free respec" does not delete "the BattleTech feeling" (READ). During Runs 1-14, 100 renown equals ~16% of the entire 635-renown LEGACY doctrine budget, punishing players who experiment with horizontal skills; after Run ~15, when all 885 renown of LEGACY and hull variants are purchased, renown has no other sink and respecs become effectively free anyway (INFERRED).

### [NOTE] The 25% shadow XP rate skips the Level 1-4 onboarding rails for same-faction admirals while leaving 20 cross-faction admirals at 0 XP.

Basis: INFERRED.

Analysis: Taking one admiral to Level 8 (230 XP) passively grants 230x0.25=57.5 XP to the other three admirals in that faction (INFERRED). That pushes all three bench admirals past Level 4 (50 XP) before they ever fly a run - bypassing Section 3's design intent that "Every player learns the system on rails first" - while giving 0 XP to the 20 admirals in the other five factions (READ / INFERRED).

## 3. Explicit checks

### a. THE SPINE

Trunk-plus-tree does not deliver timely choices at Run 5 if the player samples multiple admirals, and it caps out too early (around Run 11-13) if the player mains a single admiral (INFERRED). Because THE SYSTEMS AS BUILT specifies a win pays ~43 XP and renown pays 100 (win) / 45 (mid-run death) / <10 (early death), proportional loss XP is approximately ~4 XP for an early death and ~19 XP for a mid-run death (INFERRED). Tracing one favorite admiral across a realistic 15-run career with an 80% loss rate (3 wins, 1 early loss on Run 1, 11 mid-run losses) if flown every run:

Run 1 (early loss, ~4 XP -> 4 XP total): Admiral stays at Level 0; doesn't even reach Trunk Level 1 (6 XP) (INFERRED).

Runs 2-4 (3 mid-run losses at ~19 XP each -> 61 XP total): Admiral unlocks Level 1 (6 XP), Level 2 (16 XP), Level 3 (30 XP), and Level 4 (50 XP). All four are fixed trunk perks; zero player choices occur across the first 4 runs (READ / INFERRED).

Run 5 (1st win, +43 XP -> 104 XP total): Crosses Level 5 (75 XP). Choice 1 lands after Run 5, sitting 6 XP short of Level 6 (110 XP) (INFERRED). (Note: If the player flew a second admiral on even two of those five runs, their main admiral is around ~66 XP at Level 4 and has made zero tree choices by Run 5 (INFERRED).)

Runs 6-10 (4 mid-run losses at ~19 XP + 1 win at 43 XP -> 223 XP total): Crosses Level 6 (110 XP, Choice 2) on Run 6 and Level 7 (160 XP, Choice 3) on Run 8, ending Run 10 at 223 XP (INFERRED). If instead the player diverted 2 runs to a second admiral (as Section 8 assumes), the favorite is at ~185 XP (Level 7, 3 choices made) and the second admiral has ~46 shadow XP + ~38 direct XP = ~84 XP (Level 5, 1 choice made) (INFERRED).

Runs 11-15 (4 mid-run losses + 1 win -> 342 XP total solo, or ~265 XP split): The favorite crosses Level 8 (230 XP, Choice 4 / Capstone) on Run 11 (solo) or Run 12-13 (split) (INFERRED). Under the 1-pick-per-level rule, that admiral has no further levels or choices after Run 11-13, failing P2's requirement that power "must still be scaling at runs 5, 10, 15, and beyond" for a player's main admiral (INFERRED).

### b. THE RULES

Auditing Kassar's 20 skills in Section 5 against Section 4's five rules and Premise P4 reveals 13 of the 20 skills break at least one rule (READ / INFERRED):

Rule 1 violations (must change a decision in battle, map, or debrief; cannot only change a number by <15%):

Reinforced Bridge (Branch C, Tier 1: "flagship +10% hull") - Direct violation: pure stat bump under 15% that changes no decision (READ).

Ceremonial Broadside (Branch C, Tier 1: "flagship's first volley each battle aims 10 better") - Passive +10 aim buff on the opening shot (<15%); changes no targeting or positioning decision (READ / INFERRED).

Shared Solution (Branch A, Tier 2: "synced ships share their best aim modifier") - Passive numeric aim buff for ships already in sync (READ / INFERRED).

Cold Drill (Branch A, Tier 2: "sync forms at round start even if the flagship has not moved") - Removes an activation/movement constraint rather than introducing a decision (READ / INFERRED).

Iron Tempo (Branch A, Tier 3: "sync survives the flagship's first crippling hit each battle") - Passive failure-mitigation shield; involves no active player choice (READ / INFERRED).

Cadet Volleys (Branch B, Tier 2: "ships below cruiser class gain the sync aim bonus at half value even unsynced") - Passive aim buff that reduces positional decision weight by rewarding ships even when out of formation (READ / INFERRED).

Line Standard (Branch C, Tier 2: "the flagship's presence extends the debrief: one extra named lesson shown") - Since debrief lessons are visibility notifications ("all ruled visible"), displaying one extra text line changes no player decision (READ / INFERRED).

Heir Apparent (Branch C, Tier 3: "if this admiral's line is benched, its successor earns XP at double shadow rate") - Has zero effect in battle, on the map, or at the debrief while flying Kassar (READ).

Living Relay (Capstone: "the flagship projects sync from its position at double radius, and sync no longer requires line of sight to the anchor") - Rather than increasing "per-activation decision weight" (P3), doubling radius and removing LOS erases the positioning puzzle of Kassar's Command (READ / INFERRED).

Rule 2 violations (at most 1 in 3 pure stat effects, and those must live on Branch C):

Wide Net (Branch A, Tier 1: "+1 hex"), Shared Solution (Branch A, Tier 2: aim modifier), Screen Doctrine (Branch B, Tier 1: "-1 command point"), and Cadet Volleys (Branch B, Tier 2: half aim bonus) place numeric/stat modifiers on Branches A and B (READ / INFERRED).

Rule 3 violations (written in the faction's learning idiom; lineage document, not a vending machine):

Heir Apparent (Branch C, Tier 3) is phrased in raw meta-game mechanics ("benched", "double shadow rate"), reading like a vending-machine meta-perk rather than a Hegemony lineage playbook (READ).

Rule 4 & P4 violations (must not duplicate a LEGACY doctrine item's effect; must respect track separation):

Replacement Pool (Branch B, Tier 2: "once per sector, a lost escort class is available at the next shipyard at half price") - Directly duplicates LEGACY doctrine's "price cuts" (READ).

Screen Doctrine (Branch B, Tier 1: "escorts cost 1 less command point on the first two escorts") - Duplicates faction-wide doctrine ("standing orders, war chests, price cuts"), even naming itself "Doctrine" while being shared by all 4 admirals in the faction (READ).

Registry Priority (Branch B, Tier 3: "starting protocol from the line's favored core") - Violates P4 by encroaching on the third meta-track, core sync ("cores recognizing a line whose crews have mastered their protocols") (READ).

Rule 5 violations (never face backward: nothing may reward losing, dying, or retreating):

Martyr Protocol (Branch C, Tier 2: "when the flagship falls, the fleet keeps sync for 2 rounds") - Triggers strictly on flagship death (READ).

Replacement Pool (Branch B, Tier 2: "...a lost escort class is available at the next shipyard at half price") - Rewards losing escort ships (READ).

Iron Tempo (Branch A, Tier 3: "sync survives the flagship's first crippling hit") and Second Anchor (Branch B, Tier 3: "loss of the flagship no longer collapses sync entirely") - Both reward suffering crippling damage or losing the flagship (READ).

Heir Apparent (Branch C, Tier 3) - Rewards benching the admiral rather than fighting with them (READ / INFERRED).

### c. THE BUDGET

The sharing scheme is neither mathematically accurate nor structurally coherent (READ / INFERRED):

The real numbers: With 3 branches x 2 choices per tier, Tier 3 (6 skills) + Capstone (2 skills) equals 8 unique skills per admiral x 24 = 192 unique skills, plus 36 faction-shared Tier 1 skills (6x6) and 72 pair-shared Tier 2 skills (6x12), totaling 300 distinct skills - not the claimed 120 unique plus shared sets (READ / INFERRED).

Why sharing fails on Branch A: Because P5 gives every admiral a distinct Command, Branch A ("deepens the Command") cannot share Tier 1 across a faction or Tier 2 across a pair without violating P5 (INFERRED). Making Branch A Tiers 1 and 2 unique per admiral adds another 4x24=96 unique skills (minus 12 faction and 24 pair skills), pushing unique skills to 288 and total skills to 360 (INFERRED).

Where sameness leaks back in:

Levels 1 to 4 (0-50 XP): All 24 admirals across every faction have the exact same 4 fixed trunk perks in the exact same order (READ).

Levels 5 and 6 (75 and 110 XP): Because Tier 1 is shared across all 4 faction admirals and Tier 2 is shared across an archetype pair, two paired admirals in the same faction have 100% identical skill trees for their first 6 levels (110 XP) (INFERRED). A player does not encounter a single admiral-unique tree node until Level 7 (160 XP, Tier 3) (READ / INFERRED).

### d. THE SPLIT

The line between faction-wide doctrine (renown) and personal lineage (XP) does not hold because Tier 1 lineage skills are shared by every admiral in a faction (making them faction-wide upgrades bought with XP) and Section 3 explicitly defines Branch B as shaping "formation, doctrine, and composition effects" (READ / INFERRED).

Lineage (Tree) items closest to / crossing the line:

Replacement Pool (Branch B, Tier 2: half-price shipyard replacement for lost escorts - a pure war-chest/price-cut doctrine effect) (READ).

Screen Doctrine (Branch B, Tier 1: -1 command point on the first two escorts, shared by all 4 admirals of the faction) (READ).

Registry Priority (Branch B, Tier 3: grants a starting core protocol, crossing into P4's core sync track) (READ).

Line Standard (Branch C, Tier 2: alters the debrief UI by showing an extra lesson) (READ).

Doctrine (Renown) & Trunk items closest to the line:

Renown-funded Respec (Section 6: "costs renown (doctrine pays to retrain a line)" - directly spends faction doctrine currency to alter personal lineage perks) (READ).

LEGACY's "standing orders, war chests, price cuts" (Section 7) vs. Branch B's fleet composition/cost discounts (READ).

Hull variants (250 renown) vs. Trunk Level 1 (alternate starting fleet, 6 XP) - both modify starting fleet hulls across the currency divide (READ / INFERRED).

### e. SHADOW XP AND RESPEC

25% Shadow XP (same-faction only):

Incentivized behavior: Incentivizes single-faction mono-grinding (INFERRED). Every run flown gives +75% bonus total XP across the 3 benched admirals of that faction (3x25%), while giving 0% to the 20 admirals in the other 5 factions (INFERRED). Furthermore, if a player rushes Heir Apparent on Admiral 1 (doubling shadow rate to 50% per bench admiral) and benches them, their successor generates +150% total shadow XP across the faction bench (INFERRED). By the time Admiral 1 reaches Level 8 (230 XP), the 3 bench admirals have 57.5 XP (Level 4), meaning the player skips the Level 1-4 onboarding rails on Admirals 2, 3, and 4 and jumps straight into tree choices without ever having flown their Commands - undermining P3's emphasis on learning per-activation decision weight (INFERRED).

Renown-Priced Respec (~100 renown = one winning run's pay):

Incentivized behavior: Incentivizes risk-aversion early, then free respec spam late (INFERRED). Under P2's 80% loss rate, ~100 renown takes ~2.2 mid-run deaths (~45 renown each) or 10+ early deaths (<10 renown) to earn (READ / INFERRED). Charging 100 renown during Runs 1-14 forces the player to sacrifice permanent LEGACY doctrine items (635 renown total), discouraging experimentation with horizontal builds (harming P3) (INFERRED). Then, once the 885 renown of LEGACY + hull variants is bought out around Run 15, renown becomes a dead currency and respecs become free (INFERRED).

### f. HEAT

Having Heat pay "bonus XP to the flown admiral's line (plus its renown modifier as built)" is a short-lived fix that worsens cap exhaustion (READ / INFERRED):

Against Renown-only (as built, +10% renown per rule): Renown-only fails because deleting the 930-renown admiral unlock ladder leaves only 885 renown in total sinks (INFERRED).

Against the Proposal (Bonus Admiral XP + Renown): Because Heat is gated on the first win (around Run 5), adding bonus XP helps push a favorite admiral from Level 5 (75 XP) to Level 8 (230 XP) faster during Runs 6-11 (INFERRED). However, once that favorite admiral reaches Level 8 (230 XP), any bonus XP paid to the "flown admiral's line" is completely wasted whenever the player flies their favorite admiral (INFERRED)! Meanwhile, keeping the +10% renown modifier per Heat rule burns through the remaining 885 renown sinks even faster (INFERRED).

Against Implied Pack Alternatives (Core Sync / Nemesis / High-Heat Mastery): P4 names a third progression track (core sync: "cores recognizing a line whose crews have mastered their protocols"), and the debrief names Nemesis adaptation (READ). Tying Heat payouts to Core Sync mastery or gating Capstone evolutions behind Heat milestones would keep Heat rewarding when flying a Level 8 favorite without prematurely exhausting the XP and renown curves (INFERRED).

## 4. RUN 5 / RUN 10 / RUN 15

Run 5: Under an 80% loss rate (4 losses and 1 win), a player who flew the exact same admiral every run has just reached ~104 XP (Level 5), unlocking the full 4-step trunk and making their very first Tier 1 tree choice (which is faction-shared, not unique to the admiral), while the other 3 admirals in that faction sit at ~26 XP (Level 2 via shadow XP) and the 20 admirals in other factions sit at 0 XP. If the player instead tried 2 or 3 different admirals across their first 5 runs, no admiral has reached 75 XP yet, meaning zero tree choices have been made and only fixed trunk perks are pending. Worth chasing: Level 6 (110 XP, 6 XP away on a solo-mained admiral), the newly unlocked Heat toggle after the first win, and the remaining ~400 renown of LEGACY doctrine.

Run 10: Assuming 8 runs on the favorite admiral and 2 runs on a same-faction second admiral (at an 80% loss rate, with modest Heat XP active after Run 5), the favorite is at ~185-200 XP (Level 7) with 3 tree choices locked (1 per tier at Levels 5, 6, and 7, finally seeing their first admiral-unique Tier 3 skill at Level 7), and the second admiral is at ~85-95 XP (Level 5) with 1 tree choice locked. The choice pending is the second admiral's Level 6 (110 XP) Tier 2 pick or pushing the favorite 30-45 XP further to Level 8 (230 XP). Worth chasing: the favorite's Level 8 Capstone evolution, the ~250-300 renown remaining in the 885-renown LEGACY + hull variant pool, and 5 untouched factions still at 0 XP.

Run 15: The favorite admiral hit Level 8 (230 XP) around Run 11-13, locked their 4th and final choice (Capstone), and is now completely capped on XP, while the three same-faction bench admirals sit between Level 4 (50+ XP via shadow XP) and Level 6 (110+ XP if flown). Contrary to Section 8's claim of 1,815 renown sinks, the 635-renown LEGACY doctrine track is already 100% bought out (and the 250-renown hull variants are nearly finished), leaving renown with no sink except respecs. The only choices pending are leveling secondary admirals through shared Tier 1/2 nodes or cold-starting one of the 5 other factions from 0 XP, as the main admiral and faction doctrine have nothing left to scale.

## 5. Not checked

Full Rule 4 audit against all 12 LEGACY items: The pack states LEGACY has 12 items totaling 635 renown and summarizes them as "standing orders, war chests, price cuts", but does not list all 12 items individually to check every Kassar skill for exact mechanical duplication.

Exact loss XP formula: The pack gives win XP (~43 XP) and renown payouts (100 win / 45 mid-run death / <10 early death), but does not state the exact XP formula per sector/battle on a lost run.

Core Sync mechanics: P4 names "core sync" as the third progression track alongside lineage and doctrine, and Registry Priority references a "starting protocol from the line's favored core", but the pack contains no rules on how core sync is earned or spent.

Archetype pair definitions across the 24 admirals: The pack does not list the other 20 admirals' Commands or explain how 4 distinct Commands per faction map cleanly into 2 "archetype pairs" at Tier 2.

Simulation balance ("bossmatrix admiral band"): Section 9 references a "bossmatrix admiral band measured earlier (55 to 85 percent)" that is not included in the pack and cannot be verified.

## 6. Questions for the designer

1. At Levels 5, 6, and 7, does the player unlock 1 skill total per level (3 branch skills before the Level 8 Capstone, leaving 6 of 9 branch-tiers permanently unpicked) or 1 skill per branch at each tier (9 branch skills before Capstone)? Stakes: Under 1-pick-per-level, two-thirds of every admiral's tree is unreachable before hitting the level cap and Section 8's choice counts are mathematically impossible; under 9 picks, the XP curve must add 6 more level thresholds.
2. Now that removing the 930-renown admiral unlock ladder cuts total renown sinks from 1,815 down to 885 (635 LEGACY + 250 hull variants), what is the long-term sink for renown after Run ~15? Stakes: Without a replacement renown sink, players exhaust all LEGACY doctrine and hull variants in ~12-15 runs, collapsing both the renown economy and the cost of renown-based respecs.
3. Why are the 4 fixed trunk perks (0-50 XP) kept strictly in front of the tree rather than interleaved with tree choices from Level 1? Stakes: Putting 50 XP of zero-choice rail levels in front of Level 5 (75 XP) means a player experiencing an 80% loss rate who samples 2 or 3 admirals makes zero skill tree choices during their first 6 to 10 runs, directly undermining P1.
