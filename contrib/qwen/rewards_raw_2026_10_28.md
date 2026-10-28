Filed copy note (chair): en and em dashes in the original normalized to hyphens; wording otherwise verbatim.

VOIDSWORN REWARDS AUDIT - BLIND LEG REPORT

Proof of Reading

File slice - Line span as given

data.js - MODULES and RELICS - lines 150-200

data.js - PATRONS intro, BOONS (all 48), ASPECTS (all 6) - lines 617-697

core.js - fleetKit, modulePool, relicUseful, rollBoonOffer, rollNodeReward - lines 175-250

campaign_run.js - full post-battle reward flow - lines 390-544

CHAIR SHEET - appended summary, no line span

OVERALL VERDICT

REWARDS ARE MIXED. The protocol offer (3-take-1, reroll, decline) and the prize-ship decision create genuine decision points, but pool depth per patron, deterministic salvage yields, and a coded default algorithm for prizes push several steps toward solved or click-through territory.

FINDINGS (ranked most severe first)

1. BLOCKER - The prize-ship step ships with a solved default.
OBSERVED. prizePlan computes a deterministic answer: "Add a ship that fits with at least 40% hull, otherwise whichever of Strip or Ransom is worth more (a refit counted at half its shop price)." The UI pre-selects this default and asks the player to confirm. A player who clicks Confirm without reading is playing the optimal line. The sister audit's "strictly dominated option" disease is present here.

2. BLOCKER - Salvage is "work one wreck" with deterministic yields.
OBSERVED. salvageYield returns a fixed module or credit value per wreck. The player picks one wreck from a list, but the yield is fully known before clicking. When one wreck carries a module the fleet needs and the others do not, the choice is solved. When no module drops, every wreck is just a credit number and the pick is a formality.

3. FIX - Pool exhaustion per patron inside a single run.
INFERRED. Seven boons per patron, minus any filtered out by boonUseful/BOON_NEED. Over a 3-sector run a player sees roughly 4-6 offers per active patron (62 % of ~20 normal nodes split across 4 patrons, plus elites). By sector 3 the offer pool for a committed patron can be empty; the code handles this ("Nothing left to offer. +60 credits."). The decline-for-credits path becomes the default rather than a meaningful alternative.

4. FIX - Reroll is once-per-reward and escalates; it rarely competes.
OBSERVED. boonRerollOk gates to one reroll per reward. Cost is 25+15*((RUN&&RUN.boonRerolls)||0), so the second reroll in a run is 40, the third 55. Against a sector-1 normal-battle income of roughly 37 credits (base, before multipliers), the first reroll is affordable but the escalation quickly outpaces income. The "once" cap means a player cannot fish for a specific boon, reducing the reroll to a "this trio is bad" panic button rather than a strategic tool.

5. FIX - 62 % protocol dominance flattens the node-reward mix.
OBSERVED. rollNodeReward: x<.62?{k:'boon',p}:x<.78?{k:'mod'}:x<.9?{k:'cred'}:{k:'repair'}. Nearly two-thirds of normal nodes pay a protocol. The map shows the patron sigil in advance, so routing to a specific patron is informed, but most nodes look the same in reward type. The 16 % refit, 12 % credit, 10 % repair slots are too sparse to create meaningful routing trade-offs.

6. FIX - boonUseful filtering can thin the 3-take-1 to a take-it-or-leave-it.
OBSERVED. BOON_NEED maps 21 boons to fleet-kit requirements (e.g. h_brood:'carrier', a_mark:'lance'). rollBoonOffer filters the pool by boonUseful. A fleet without lances, carriers, or torpedoes loses access to a large slice of the 48-boon pool, and the offer can degrade to 2 or even 1 relevant boon plus filler.

7. NOTE - Legendary boons are gated and slotted deterministically.
OBSERVED. legendaryFor requires minR>=1 (elite/boss), two prior boons from that patron, and kit fit. The legendary then occupies slot 3 unconditionally: out[2]={id:L,r:3}. The appearance is earned, but the player never chooses whether to see it; it simply replaces whatever would have been in slot 3.

8. NOTE - Ransom diminishing returns create a soft solved curve.
OBSERVED. prizeRansom applies Math.pow(.85,n||0) per prior ransom, floored at 40 %. The first ransom is near full value; by the third or fourth, ransoming is clearly inferior to stripping. The decision is real early but converges on "always strip" as the run progresses.

9. NOTE - Module pool (13 items) is shallow for a 3-sector run.
OBSERVED. 13 modules, filtered by modulePool for fleet kit. At 16 % of ~20 normal nodes, a player sees roughly 3 refit offers of 3 modules each, about 9 modules shown. Most of the pool surfaces; by run 2 or 3 the refit step feels repetitive.

10. NOTE - Decline-for-credits is priced low relative to a boon's run-long value.
OBSERVED. boonDeclineCred returns 30+10*sector (40 / 50 / 60). A Common boon with multiplier 1 still changes a stat for the rest of the run. The decline is attractive only when the offer is genuinely irrelevant, making it a cleanup valve rather than a strategic alternative.

EXPLICIT CHECKS

a. THE OFFER
The offer is 3 protocols from one patron, take 1, with a once-per-reward reroll and a decline-for-credits fallback. The choice is real when the patron's pool still holds 3+ boons the fleet can use. A player declines when all three boons are irrelevant to the build or the patron's pool is exhausted; they reroll when the trio is weak but the patron is one they are investing in. Reroll pricing (25 first, then +15 per prior reroll in the run) is steep against the pack's visible income: a sector-1 normal battle pays roughly (25+12*1+3*col)*1, about 37 credits before multipliers. The first reroll is within reach; the second (40) and third (55) are not, which means the escalation effectively caps rerolls at 1-2 per run. The decline (40/50/60 by sector) is a reasonable consolation but does not compete with a useful boon's run-long value. The choice architecture is sound; the economy makes reroll a rare luxury rather than a routine lever. (OBSERVED for prices and formulas; INFERRED for income comparison, since the pack does not state a full-run credit budget.)

b. THE DISTRIBUTION
Normal nodes pay 62 % protocol / 16 % refit / 12 % credits / 10 % repairs; elites and bosses always pay a protocol at rare-or-better minimum. The map shows each node's reward label and patron sigil in advance (per the chair sheet). Seeing the reward before the fight makes routing informed, which is good, but it also makes it optimisable to the point of being solved when one or two patrons dominate a player's build plan. If a player has committed to Kharon and Vyre, every node bearing their sigil is strictly better than a Crucible or Astra node, and routing collapses to "take the path with the most matching sigils." The 62 % protocol weight means most nodes differ only in patron colour, not in reward type. The 16/12/10 tail is too thin to create a genuine "do I skip a protocol node for a refit node?" trade-off. The distribution supports informed routing but does not yet support difficult routing. (OBSERVED for percentages; INFERRED for routing impact.)

c. SOLVED CHOICES
The sister audit's disease is partially present. The prize-ship step is the clearest case: prizePlan computes a default with an explicit algorithm ("Add if it fits at 40 % hull or more, else whichever of Strip or Ransom is worth more, counting a refit at half shop price"). The UI pre-selects this default; a player who confirms is playing the solved line. Salvage is softer but similar: the yield per wreck is deterministic, so when one wreck carries a needed module the choice is obvious, and when none do it is a credit-number click. In the boon offer, boonUseful filtering can reduce the 3-take-1 to a take-it-or-leave-it when the fleet's kit is narrow. The legendary boon's guaranteed slot-3 placement removes any element of surprise or choice about its timing. I do not see a case where one protocol in an offer is always the correct pick regardless of build state - the rarity multiplier and build context prevent that - but the structural pressure toward a "correct" answer is visible in prizes and salvage. (OBSERVED for prizePlan and salvageYield code; INFERRED for degree of dominance in boon offers.)

d. THE POOL
48 protocols (7 per core x 6 cores + 6 duo), 13 modules, 12 relics, 6 aspects. For a 3-sector run with 4 active patrons: a player sees roughly 15-21 protocol offers (62 % of ~20 normal nodes + 3-4 elites + bosses). Split across 4 patrons, that is ~4-5 offers per patron against a pool of 7. After boonUseful filtering removes boons the fleet cannot use, the effective pool is smaller. Repetition sets in around sector 2 for a committed patron; by sector 3 the "Nothing left to offer. +60 credits" fallback is reachable. Duo boons (6) and legendaries (6) add late-run spice but require specific patron combinations and kit. The module pool (13) is surfaced almost entirely in one run (~3 refit nodes x 3 shown = 9 of 13). Relics (12) are offered 2-at-a-time at elites and 3-at-a-time at bosses; a 3-sector run with ~3-4 elites and 3 bosses shows most of the pool but the player only takes 3-4. Builds can differ, but the pool is shallow enough that a player who runs the same patron pair repeatedly will see the same boons by run 3-4. (OBSERVED for pool counts and filtering; INFERRED for node counts per sector, which the pack does not state.)

e. THE CHAIN
The post-battle chain runs: prize decisions, then wreck stripping, then node reward (protocol / refit / credits / repairs), then relic step (elites/bosses), then promotions.
The step with the most decision weight is the node reward pick (protocol 3-take-1 with reroll/decline, or the 3-module refit choice). It is the step where build identity is shaped and the pool interacts with player intent.
The step most likely to be a click-through is wreck stripping: "work one wreck," yields are deterministic, and when no module drops the choice is just picking the highest credit number. The prize step can also be a click-through when the default algorithm's answer is obviously correct (one prize, no room to add, strip > ransom).
The order slightly hurts: it front-loads the lower-stakes decisions (prize, salvage) before the main event (protocol pick). A player fatigued by confirming prize defaults and clicking a salvage scrap arrives at the boon offer with reduced attention. Conversely, placing prizes first when the fleet state (command points, hull percentages) is freshest in mind is defensible. The promotion step at the tail is fine as a low-key capstone. The relic step between boon and promotion is well-placed for elite/boss fights. (OBSERVED for chain order and UI flow; INFERRED for attention/fatigue impact.)

RUN 1 / RUN 5 / RUN 10
Run 1. The patron themes, boon names, and rarity tiers are all new. The 3-take-1 feels generous; the player reads every description. The reroll and decline buttons are confusing extras. The module and relic pools feel deep because nothing repeats. The prize step's default is a helpful guide. The reward layer carries the run's sense of discovery.
Run 5. The player has internalised 2-3 patron identities and knows which boons synergise. The boonUseful filter means offers are consistently relevant, which is good, but also predictable: the player can read the offer and pick in a few seconds. The first reroll is a known tool; the escalation makes a second reroll a real splurge. Prize defaults are now obvious and the confirm-click becomes routine. The module pool's 13 items start to repeat. The reward layer is efficient but no longer surprising.
Run 10. A committed patron's 7-boon pool is exhausted or nearly so; the "Nothing left to offer. +60 credits" fallback fires. The decline-for-credits becomes the default action for that patron's nodes. Duo boons and legendaries are the remaining excitement, but they are gated and deterministic in slot. The player routes the map almost entirely on patron sigil and node type, treating the 62 % protocol nodes as "which patron" rather than "what kind of reward." The reward layer is a solved optimisation pass; the roguelite variance that kept runs fresh is largely spent. Meta-progression (favour tiers, referenced in code but not detailed in this pack) may partially offset this, but the pack does not show how.

NOT CHECKED
- Map generation (genSector is called but not in the pack). I cannot verify node counts per sector, path topology, or how reward labels are rendered on the map.
- Full-run credit income and expenditure. The pack shows the per-battle credit formula but not total run income, shipyard prices in full, or repair costs across a sector. I cannot confirm whether reroll/decline prices are tuned against a full economy.
- The events system. The sister audit covers events; this pack does not.
- Meta-progression details. Favour tiers (favourTier, FAVOUR_TIERS), mastery levels (aspect count at admiral mastery 2+), and META.unlocked effects (e.g. salvagers +20 % credits, wrights -15 % prices) are referenced but not defined in the pack.
- Nemesis adaptation. nemAdapt is called at sector transitions but the system is not shown.
- Shipyard and between-battle economy. Class refit tracks (classTrackCost, buyClassTrack) are visible, but the full shop, ship purchase, and repair economy is not.
- Faction-specific reward differences beyond the Corsair tow option and the nodeFaction 1-in-5 rival-faction roll.
- The promotion perk choice UI. promotionsStep and promoteModal are called but the modal contents and perk selection logic are not in the pack.

QUESTIONS FOR THE DESIGNER
1. Prize default algorithm. prizePlan computes and pre-selects the optimal answer for each prize. Is this meant as a convenience suggestion the player is expected to override, or is it an acknowledgement that the choice is solved? If the former, should the default be hidden or randomised to force engagement?
2. Patron pool depth vs. run length. With 7 boons per patron and kit filtering, a committed player can exhaust a patron's pool by sector 3, hitting the +60-credit fallback. Is 7 the intended pool size, or should the patron pool be deeper (or the offer wider than 3-take-1) to keep the decision alive across a full run?
3. Salvage scarcity. "Work one wreck" regardless of how many ships were destroyed is a hard cap. Is this a deliberate scarcity lever (to keep module income low and refit nodes valuable) or a simplification that could be relaxed, e.g. work one wreck per surviving ship, to make the salvage step a real multi-pick decision in large battles?
