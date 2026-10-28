Filed copy note (chair): em dashes in the original normalized to hyphens; wording otherwise verbatim.

## Proof of reading

- `data.js` lines 545-616: HULL_VARIANTS, mastery, favour, HEAT, ARCHETYPES, NODE_MODS.
- `campaign3d.js` FULL (136 lines): map generation, patrons in range, runRenown, battle setup.
- `core.js` lines 175-200: reward roll and offer construction.
- `CHAIR SHEET`: no line span given; census only.

OVERALL VERDICT: RUNS DIFFER AT THE EDGES - faction/admiral/aspect and route choices vary, but battle texture is capped by 3 archetypes and exactly 2 node modifiers, and the map generator itself is not actually shown in the pack.

## Findings

1. FIX - Battle texture is structurally thin. OBSERVED: `ARCHETYPES` has three entries, and `NODE_MODS` has exactly two: `bounty:{n:'Bounty'` and `veteran`. The chair sheet confirms “exactly 2 node modifiers.” Every battle node draws from a very small texture set. OBSERVED.
2. NOTE - The map generator is not in the pack despite the header. OBSERVED: `campaign3d.js` FULL contains `nodeSeeds`, `battleScreen`, and calls like `regionMap(RUN.map.region` and `rollEncounter(nd.type,nd.col)`, but does not define the map-generation functions. I cannot audit route structure, node mix, or reward placement from this pack. OBSERVED.
3. NOTE - Run shape is heavily set before the first battle. OBSERVED: chair sheet says each admiral has “a fixed starting fleet”; code says mastery level 2 gives “four aspects instead of three.” One faction, one admiral, one starting fleet, one aspect from 3/4, and 4 of 6 cores in range are fixed early. Whether aspect choice “reopens” shape depends on aspect effects, which are not in the pack. OBSERVED / INFERRED.
4. NOTE - Reward routing is visible and formulaic. OBSERVED: reward labels are visible before choosing route, and `rollNodeReward` uses fixed thresholds: `return x<.62?{k:'boon',p}:x<.78?{k:'mod'}`. Elite/boss are boon `min:1`. Route choice is therefore more about visible reward type than hidden uncertainty. OBSERVED.
5. NOTE - Faction/admiral mostly change loadout and economy, not clearly decisions. OBSERVED: `FAC_WPOOL`, `FAC_PRICE`, faction hull variants, and `a Corsair capture pays a bonus refit`; admirals have fixed fleets and mastery perks. I cannot see full boons/aspects/events, so I cannot prove faction/admiral change route or fight-taking decisions rather than names/numbers. OBSERVED / INFERRED.
6. NOTE - A single run touches a small content slice. OBSERVED: chair census gives `45 hulls, 48 protocols (boons), 13 modules, 12 relics, 18 hull variants`; per run you see 1 faction, 1 admiral, 1 aspect, and 4 of 6 cores. Events/encounters are subsets, but node counts are absent. Exact fraction is not derivable; it is a small fraction. OBSERVED / INFERRED.
7. NOTE - Sector conditions and HEAT add run-level texture, not per-node variety. OBSERVED: `const SECTOR_CONDS={` has five entries and `const HEAT={` has seven optional rules. These vary a run or difficulty, but do not expand the 3-archetype / 2-node-mod set that carries battle-node texture. OBSERVED.
8. NOTE - Seeding aids replay, not variety. OBSERVED: the comment says “a reload replays the same node and enemy fleet.” This is good for determinism, but it does not make two different runs more different. OBSERVED.
9. NOTE - Hull variants are progression sidegrades. OBSERVED: `HULL_VARIANTS` has 18 entries, including arc-unlock variants at `cost:0`. They broaden faction shipyards and long-term progression, but per run they are constrained by faction and unlock state. OBSERVED.
10. NOTE - Archetype names are faction-flavoured but mechanically the same three. OBSERVED: `names:{voidsworn:'Frontier flotilla'` etc. The same `swarm`, `heavy`, `carrier` budget shapes are renamed per faction. OBSERVED.

## Checks

a. THE START. The pack shows fixed admiral starting fleets and an alternate at mastery level 1; aspect choice is 3 offered, 4 at mastery 2+, from 6 total aspects. That means faction, admiral, starting fleet, and most of the early fleet identity are decided before the first battle. The aspect pick can reopen shape only if aspects materially change fleet decisions; the pack does not show aspect effects, so that part is INFERRED and cannot be confirmed.

b. THE MAP. I cannot judge two maps’ route structure or node mix from this pack because the actual map-generation code is absent. `campaign3d.js` shows node seeding, battle setup, and references to `RUN.map` / `regionMap` / `rollEncounter`, but not how the map graph, columns, node types, or rewards are generated. The visible randomness bites in node seeds and battle setup; reward placement is governed by `rollNodeReward`, which is formulaic. Route structure is not auditable here.

c. THE TEXTURE COUNTS. Three enemy archetypes and two node modifiers are very thin for a 3-sector run. Sector conditions and HEAT add some run-level variation, but each battle node still resolves into a small set of archetype/modifier combinations. Repetition likely sets in after a handful of battle nodes, probably within the first sector or by early sector 2, though exact node counts are not in the pack. INFERRED.

d. FACTION AND ADMIRAL. Faction clearly changes available hulls, prices, variants, and at least one capture bonus; admiral changes starting fleet and mastery perks. But the pack does not show full boon pools, aspect effects, event pools, or faction-specific route/reward incentives. From what is shown, faction/admiral mostly change loadout, economy, and names/numbers; whether they change route or fight-taking decisions is not demonstrated. OBSERVED / INFERRED; much is NOT CHECKED.

e. CONTENT SEEN PER RUN. A run touches one faction of six, one admiral of 24, one aspect of six, and four of six cores; it sees some subset of 48 protocols, 33 events, and 8 encounters. Because map node counts and event frequency are absent, I cannot give a precise fraction. The implication is that a single run samples a small slice, so run 5 can feel fresh only if the player deliberately rotates faction/admiral/aspect or if unseen content materially changes decisions. INFERRED.

## RUN 1 / RUN 5 / RUN 10

RUN 1: Baseline. One faction, one admiral, fixed starting fleet, one aspect from three, 4/6 cores, 3-sector map. Texture is already limited to 3 archetypes and 2 node mods.

RUN 5: Likely fresher if the player has rotated faction/admiral/aspect and unlocked variants/mastery/HEAT. But the battle-node texture remains the same 3-archetype / 2-modifier set, so novelty comes mostly from loadout and route labels, not new battle shapes.

RUN 10: Likely noticeably samey unless the player intentionally chases different factions/admirals/aspects or higher HEAT. The pack shows progression unlocks and named faction flavour, but not enough per-node texture to prevent repetition across many runs.

## NOT CHECKED

- Actual map-generation algorithm, route topology, node counts, and reward placement.
- Full boon/protocol list, aspect effects, event content, encounter content, and faction kits.
- How patrons are selected or what “in range” means mechanically.
- Whether aspects or admirals materially change route/reward decisions.
- Frequency and assignment of node modifiers and sector conditions.
- Balance effects of HEAT, variants, mastery, and favour.
- Whether the unseen event/encounter pools compensate for the thin battle-node texture.

## QUESTIONS FOR THE DESIGNER

1. Should node modifiers expand beyond the two shown, or is sector-condition variation intended to carry that load?
2. Is visible reward labelling on map nodes a deliberate route-planning feature, or should reward type be more hidden to create uncertainty?
3. Do faction, admiral, and aspect need to change route/reward decisions, or is it acceptable that they mainly change fleet loadout and economy?
