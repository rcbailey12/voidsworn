Gemini (Argon High) blind leg, Oct 28 program item 5 (run variety audit). Filed as a single reviews copy per house rule, with this chair header. Em and en dashes in the original normalized to hyphens; wording otherwise verbatim. Method note from the run: fresh Gemini chat, session signed in as rcbailey12@gmail.com (Google AI Pro), Argon High verified in the picker and prompt bar before sending; both files uploaded together with no error tiles. The first chat errored after about 5 minutes with no report; exactly one fresh-chat retry was used, Argon High re-verified the same way, and the retry completed the full report. A limit notice (reset 3:10 PM) and a picker flip to Flash-Lite appeared only after the report had generated. Chat: https://gemini.google.com/app/092d9f4eab45a0b3

Proof of Reading & Overall Verdict

data.js: lines 545-616
campaign3d.js: FULL (136 lines)
core.js: lines 175-200

OVERALL VERDICT: RUNS DIFFER AT THE EDGES - While 4-of-6 patron filtering and 5 sector conditions vary the macro environment, deterministic kit-filtered boons, fixed starting fleets, and a tiny 3-archetype by 2-modifier battle matrix force mid-run decisions into repetitive grooves.

Findings

1. [FIX] Map node texture is severely under-provisioned, unchanged since the prior audit.

OBSERVED: ARCHETYPES has 3 entries (swarm, heavy, carrier) and NODE_MODS has 2 (bounty, veteran), matching the Chair Sheet note: "3 archetypes and 2 node mods already thin then; both counts are unchanged".

INFERRED: Across a 3-sector run, players will see every archetype and modifier combination within Sector 1 or early Sector 2, reducing tactical preview variety to repetitive math adjustments (+50% credits/+10% ships or one elite captain).

2. [FIX] Protocol (boon) offers strictly filter for current fleet weapons, locking in starting fleet archetypes.

OBSERVED: rollBoonOffer filters the pool via pool=pool.filter(id=>boonUseful(id,kit)) where fleetKit() scans RUN.fleet for torp, lance, battery, flak, broad, still, shields, carrier, and sq.

INFERRED: Because junk (non-matching boons) is only offered if the entire in-range patron pool cannot fill 3 slots (while(out.length<3&&junk.length)), players are never tempted by pivot boons before buying a hull, making runs converge onto the starting fleet's initial weapon tags.

3. [FIX] High patron-boon reward weight and guaranteed legendaries make patron-chasing highly deterministic.

OBSERVED: rollNodeReward yields {k:'boon',p} 100% of the time on elite/boss nodes and 62% (x<.62) on standard nodes, while legendaryFor guarantees slot out[2]={id:L,r:3} at minR>=1 once n>=2 boons are held.

INFERRED: Because node reward sigils are visible on the map ("its sigil shows on the map"), a player only needs to hit two standard nodes of one patron before an elite or flagship to deterministically force that patron's legendary protocol.

4. [NOTE] Evidence pack truncation omits map topology generator, admiral definitions, and patron selection logic.

OBSERVED: Despite the campaign3d.js header stating "map generation, patrons in range, runRenown, battle setup", campaign3d.js is the 3D wrapper; functions like ensurePatrons(), rollEncounter(), ADMIRALS, and map graph creation are absent.

INFERRED: The actual structural variance of map branching, how the 4-of-6 cores are chosen, and how admirals or aspects alter gameplay cannot be verified from code in this pack.

5. [NOTE] Pre-run progression gates early-run starting variety behind grind.

OBSERVED: MASTERY_XP=[0,6,16,30,50] gates 'Alternate fleet' at level 1 (6 XP), 'Wider counsel' (4 aspects instead of 3) at level 2 (16 XP), and 'Second Command' at level 3 (30 XP).

INFERRED: Until mastery XP is earned per admiral and renown is spent on HULL_VARIANTS (or story arcs finished for ARC_VARIANT), an admiral's starting state has zero fleet or command variation.

6. [NOTE] Asymmetric faction economy and Nemesis rules create real mechanical divergence for specific factions.

OBSERVED: finishBattle grants Corsairs a unique capture payout (if(result==='win'&&RUN.fac==='corsair'&&summary.prizes.length) giving a module and RUN.credits+=20), while Hegemony Nemeses force round-3 reinforcements ('reinf_enemy') and Chorus Nemeses scale off player ship losses (nemFeedLosses(lostN)).

INFERRED: Playing as Corsairs actively incentivizes a boarding/capture route economy, and facing Hegemony or Chorus Nemeses alters in-battle tactical priorities compared to other factions.

7. [NOTE] Sector conditions provide meaningful macro-modifiers, though mostly numerical.

OBSERVED: SECTOR_CONDS defines 5 conditions (ion, dark, wreck, war, scarce), modifying shield regen (.75), terrain (storm, neb, debris), battle pay (+.15 to +.25), reinforcement events (war:1), shipyard prices (1.2), and repair efficiency (.75).

INFERRED: Picking 3 of 5 conditions across a 3-sector run changes economy and accuracy/shield math per sector, though 60% of the pool is exhausted in a single run.

Explicit Checks

a. THE START:
Before the first battle, a fresh admiral's fleet is 100% fixed (one of 24 admirals, each with a fixed starting fleet until Mastery Level 1 at 6 XP unlocks 'Alternate fleet', and Mastery Level 3 at 30 XP unlocks 'Second Command'). Because rollBoonOffer immediately filters protocol rewards through fleetKit() based on the weapons, shields, and hangars currently in RUN.fleet, that fixed starting fleet heavily dictates which protocols can even appear in Sector 1. The Chair Sheet notes the player picks 1 aspect from 3 offered (or 4 at Mastery Level 2, 16 XP) out of a tiny pool of 6 total aspects ("1 aspect (from 3 offered, 4 at mastery 2+)", "6 aspects"). Because 3 of 6 is 50% of the entire aspect pool seen every single run (67% at Mastery 2) - and the pack omits the code for aspects - the aspect choice has too small a pool to prevent runs from feeling repetitive at start, and does not override fleetKit()'s weapon-tag filtering unless an aspect directly alters ship weapons (which is not shown in the pack).

b. THE MAP:
Contrary to the prompt and section header, the map graph generator is not in campaign3d.js; campaign3d.js only contains the 3D showcase wrapper, nodeSeeds, battleScreen, and finishBattle, while mapScreen, findNode, rollEncounter, and regionMap are called but defined elsewhere. Consequently, route branching, column counts, and node type ratios cannot be evaluated from the pack. From what is visible in core.js and campaign3d.js, reward placement (rollNodeReward) is visible on the map before choosing a route and strongly skews toward patron boons: 100% on elite/boss nodes ({k:'boon',p,min:1}) and 62% on standard nodes, versus 16% module (x<.78), 12% credits (x<.9), and 10% repair. In battleScreen, randomness bites in deployment (pick(['line','line','flank']) for non-bosses) and war sector reinforcement rolls (rnd()<.6?'reinf_enemy':'reinf_ally'), whereas ARCHETYPES.names (renaming 'swarm' to 'Wolfpack' or 'Brood swarm' per faction) is purely cosmetic.

c. THE TEXTURE COUNTS:
Three enemy archetypes (swarm, heavy, carrier) and 2 node modifiers (bounty, veteran) are not enough texture to sustain a 3-sector run. Even counting unmodified nodes as a third state, there are only 3×3=9 possible archetype-modifier combinations in the entire game (ARCHETYPES only re-skins its 3 budget splits with faction-specific names). Furthermore, bounty ("+50% credits, and they bring 10% more ships") and veteran ("Their largest ship has an elite captain") are minor stat/economy scalers rather than rule-changing mutators. Repetition sets in by late Sector 1 or early Sector 2, as the player will have seen every archetype and both modifiers within the first 3 to 5 battle nodes.

d. FACTION AND ADMIRAL:
Faction choice changes both fleet weapon tags and select campaign mechanics, whereas admiral choice (in the provided slices) is only visible as a starting-fleet and mastery-perk container. On the faction side, FAC_WPOOL and HULL_VARIANTS show distinct weapon/defense profiles per faction (e.g., Chorus hulls use bioplasma/tendril and hull regen; Corsair hulls use scatter/torp; Hegemony uses ion/turbo/flak), which feeds into fleetKit() to filter which patron boons rollBoonOffer can drop, and FAC_PRICE alters hull class pricing per faction. Corsairs also get a hard-coded boarding economy rule in finishBattle (+1 module and +20 credits on capture), and enemy Nemeses have faction-specific behaviors (Hegemony forces round 3 'reinf_enemy'; Chorus grows via nemFeedLosses). However, we cannot see ADMIRALS, COMMANDS, ASPECTS, FAC_MAP, or how RUN.patrons (4 of 6 cores in range) are selected - specifically whether patrons are random or weighted by faction.

e. CONTENT SEEN PER RUN:
Per the Chair Sheet and slices, a single 3-sector run touches:

Aspects: 50% (3 of 6 offered at start; 67% or 4 of 6 at Mastery 2+).

Cores (Patrons) & Protocols: 67% of cores (4 of 6 in range), meaning 32 of the 48 protocols are eligible per run (further narrowed by fleetKit() weapon requirements), with roughly 60%-70% of combat nodes offering 3 protocols at a time.

Sector Conditions: 60% (3 sectors out of 5 SECTOR_CONDS: ion, dark, wreck, war, scarce).

Archetypes & Node Mods: 100% of ARCHETYPES (3 of 3) and 100% of NODE_MODS (2 of 2).

Encounters, Events, Modules, Relics: A subset of the 8 battle encounters, 33 campaign events, 13 modules, and 12 relics (exact node counts per sector are not in the pack, but with 8 total encounters across ~10-15 fights in 3 sectors, nearly 100% of the 8 encounter types will be seen in a single run).

Because a single run exposes 50%-100% of aspects, cores, sector conditions, archetypes, node modifiers, and battle encounters, Run 5 will not feel fresh from map or encounter discovery; its freshness relies almost entirely on switching factions/admirals to change fleetKit() and hull pools.

RUN 1 / RUN 5 / RUN 10

RUN 1: Everything is novel, but options are at their narrowest: AI_LEVEL starts on 'standard', HEAT is locked (requires first victory), MASTERY_XP is 0 (locking the player into the admiral's single base fleet, 3 aspect choices, and 1 Command), FAVOUR_TIERS are at 0 ('Listening'), and none of the 18 HULL_VARIANTS are unlocked. During this single run, the player will likely see all 3 enemy ARCHETYPES, both NODE_MODS, 3 of the 5 SECTOR_CONDS, 4 of the 6 patron cores, 3 of the 6 aspects, and most of the 8 ENCOUNTERS.

RUN 5: Map and encounter novelty is already exhausted - the player has seen all 5 SECTOR_CONDS, all 6 aspects, all 6 patron cores (since 4 of 6 appear per run), all 3 archetypes, and both node modifiers. If the player switches among the 6 factions or 24 admirals, Run 5 differs via new hull weapon kits (FAC_WPOOL), which unlock different boonUseful subsets in rollBoonOffer, alongside early meta-unlocks: FAVOUR_TIERS reaching Tier 1 (at:4, 'Partial sync', +12% rare/+3% epic protocol chance), Mastery Level 1 (at:6 XP, 'Alternate fleet') on a favored admiral, 1-2 renown-purchased HULL_VARIANTS (cost 15-30 renown), and HEAT toggles if a run was won.

RUN 10: Structural and content variety has completely plateaued; runs converge into predictable build-routing where players use visible map sigils to force 2 patron boons into a guaranteed legendaryFor drop at elites/bosses. Differences between Run 10 and earlier runs are driven by meta-progression power and difficulty mutators rather than new situations: FAVOUR_TIERS hitting Tier 2 (at:12, 'Synced', starting the run with a free protocol from an in-range patron), Mastery Levels 2-3 (16-30 XP for 4 aspect choices and 'Second Command'), story-arc sidegrades (ARC_VARIANT earned by beating a faction's Nemesis), and HEAT modifiers (h_undying, h_hunted, etc.). Notably, flagship customization (FIT_SLOTS: pod, module, trim) is still unimplemented ("schema only, nothing reads these for rules yet").

NOT CHECKED
Because the pack only includes slices of data.js (lines 545-616), campaign3d.js (lines 1-136), and core.js (lines 175-200), the following cannot be judged:

Map graph topology and node counts: The actual map generator (mapScreen, node column count, branching factor, event vs. battle vs. shipyard node frequencies) is not in campaign3d.js.

Patron selection (ensurePatrons): How the 4 of 6 cores in range are picked (pure random vs. faction-weighted).

Definitions of core content pools: The actual effects and diversity of the 24 ADMIRALS, 6 ASPECTS, 48 BOONS (and BOON_NEED), 13 MODULES, 12 RELICS, 33 campaign EVENTS, and 8 ENCOUNTERS (rollEncounter, bossEncounter).

Nemesis and Faction Verbs: Full details of NEM_FAC, NEM_WEAK, nemLearn, and RUN.verbNext beyond the brief calls in battleScreen and finishBattle.

Combat & AI mechanics: How startBattle, derive(), captain perks, and WING_PERKS play out on the hex grid.

QUESTIONS FOR THE DESIGNER

Should protocol offers strictly exclude non-matching weapon tags (boonUseful), or offer one "pivot" slot? Right now, rollBoonOffer relegates boons for weapons you don't own to junk, which almost never appears - meaning a player cannot draft a torpedo or carrier protocol early and then buy a ship to use it.

Are 2 node modifiers (bounty, veteran) and 3 enemy archetypes intended to be the final map-reading vocabulary? Since this was flagged on Oct 22 and remains unchanged, do you want node modifiers to stay simple stat/credit bumps, or should they introduce tactical battlefield rules (like SECTOR_CONDS do)?

Is the 100% deterministic legendary protocol rule (legendaryFor triggering automatically at the first elite/boss after taking any 2 boons from that patron) intended? Because node patron sigils are visible on the map, players can reliably force a legendary protocol by Sector 1's boss or Sector 2's first elite on nearly every run.
