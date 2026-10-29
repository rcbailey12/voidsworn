# Argon blind leg: encounter and boss fight audit (Oct 28, 2026)

Chair note: filed from the model's reply (Gemini, 4 Argon, Thinking level High; picker verified "Argon High" before sending and still Argon High after; inline citation chips omitted per instruction). Em dashes, en dashes, and unicode minus signs normalized to hyphens per house rule; wording otherwise unchanged. Chat: https://gemini.google.com/app/3b26fd299c7e2e7d. Evidence pack: the Oct 28 battle program fights pack (code slices pinned to main 264f441d). Method notes and screening live outside this file.

## 1. Proof of reading

Pack sections read:

EVIDENCE PACK title line (EVIDENCE PACK: encounter and boss fight audit (code slices from the shipped browser build, main 264f441d; the Godot port mirrors this design))

THE COMMISSIONER'S QUESTION

CHAIR CENSUS (verified from the code in this pack)

WHAT TO JUDGE

Code slice 1: === battle.js 55-70: encounters and boss encounter roll === (ENCOUNTERS and boss roll)

Code slice 2: === data.js 76-135: boss hulls and faction rosters === (boss hulls and rosters)

Code slice 3: === core.js 285-300: archetypes and node modifiers === (archetype assignment)

Code slice 4: === data.js 593-640: ARCHETYPES === (ARCHETYPES)

Overall Verdict: DISTINCT ON PAPER - While the eight objectives specify genuinely different win conditions in code, half of the encounter pool collapses into fleet-attrition or VIP-snipe variants, 38% of ordinary nodes roll no archetype at all, and sector bosses reuse standard roster abilities inside randomized objectives that can render their fixed escorts irrelevant.

## 2. Findings

### [BLOCKER] Deathless nodes roll the carrier archetype (15%) despite the faction having no carrier hull and sq:null, making the map preview false.

READ: In core.js, every battle and elite node rolls n.arch independently of faction (x<.47?'heavy':x<.62?'carrier':null, a 15% share). ARCHETYPES.carrier displays "Built around a carrier and its wings. Fighters and flak pay off." and gives Deathless the name deathless:'Repair host'. However, FACTIONS.deathless defines roster:['d_scythe','d_jackal','d_harvester'] (Frigate, Destroyer, Cruiser) and sq:null, with zero cls:'Carrier' or hangar hulls in data.js.

INFERRED: In Sector 3 (SECTOR_POOL includes 'deathless'), 15% of Deathless battles and elites tell the player to bring fighters and flak against a carrier and wings that do not exist in the faction roster, either spawning a wingless cruiser fleet or failing silently.

### [BLOCKER] Rolling flagship (Decapitation) on 25% of sector bosses invalidates the fixed boss escort and reduces the climax to a single-target rush.

READ: bossEncounter() rolls pick(['rout','rout','ambush','flagship']), giving Decapitation ("Destroy their flagship and the rest of their fleet scatters.") a 25% chance, while "bosses keep their own escort rather than a rolled archetype". Boss hulls have high HP (hp:470 to hp:650) and low speed (sp:1 on h_boss/d_boss, sp:2 on c_boss/b_boss, sp:3 on i_boss).

INFERRED: On a flagship roll, shooting the boss's escort is a trap because the escort vanishes the instant the boss dies; conversely, on a rout roll (50%, "It flees once it has lost about two thirds of its strength"), either killing the escort makes the sector boss flee alive, or the boss's cp:10-12 weight forces the player to kill both the boss and its escort, creating wildly uneven climax difficulty from a hidden coin flip.

### [FIX] Boss hulls are high-HP stat blocks that recycle standard roster active abilities (launch, surge, nova) rather than bespoke boss mechanics.

READ: In data.js, c_boss (ab:'launch',hangar:2) has the exact same ability and hangar capacity as the regular Corsair carrier c_hulk (ab:'launch',hangar:2). b_boss (ab:'launch',hangar:3) has the exact same ability and hangar capacity as the regular Chorus carrier b_brood (ab:'launch',hangar:3). i_boss (ab:'surge') duplicates the Ithar cruiser i_song (ab:'surge'), and h_boss and d_boss both use ab:'nova'. Furthermore, d_boss omits reanimate:true, which every standard Deathless ship (d_scythe, d_jackal, d_harvester) has.

INFERRED: Because boss hulls execute standard cruiser/carrier actions with hp:470-650 and sp:1-3, they act as damage sponges rather than mechanical tests - explaining why prior simulations found "boss fights are long, 7.3 to 8.0 rounds, but not the most lethal class" (81.5% to 92.1% win rate vs 69.9% for Sector 2 elites).

### [FIX] Preview descriptions for defend, intercept, and break omit critical numerical thresholds, turning defend + swarm into an unpriced trap.

READ: defend states "Every enemy ship within 2 hexes of it at the start of a round knocks out 1 integrity", without stating the station's total integrity or battery firepower. intercept ("Destroy them before they get through.") omits transport count, speed, and leak tolerance, while break ("Get ships off the far edge") omits how many player ships must exit to win.

INFERRED: Because defend scales station integrity loss by ship count within 2 hexes rather than enemy weapon damage, a swarm ("Many light hulls. Broadsides and flak shine") of sp:5-7 frigates (c_raider, b_drone, i_wisp) strips station integrity far faster than a heavy fleet, even when the player brings the anti-swarm weapons advised by the archetype text.

### [FIX] hunt and flagship share the same kill target and identical 11-shape pools, duplicating the VIP-snipe objective inside ENC_SPECIAL.

READ: Both hunt ("Their flagship is running and jumps out at the end of round 6. Destroy it before then.") and flagship ("Destroy their flagship and the rest of their fleet scatters.") require killing the enemy flagship, share the identical 11-shape array (['open','corridor','lanes','ring','dense','deadstar','rift','shoals','hourglass','archipelago','colossus']), and both sit in ENC_SPECIAL.

INFERRED: Because the column logic only forbids adjacent identical encounter keys, a column can pair hunt next to flagship as its non-Engagement options, offering two fights that both reward the exact same high-alpha torpedo/lance dive.

### [FIX] ambush is a spawn formation disguised as an objective, allowing a map column's guaranteed "non-Engagement" slot to still be a pure attrition brawl.

READ: ambush ("Two enemy groups close in from both sides. Break their fleet.") shares the "Break their fleet." objective with rout ("Break their fleet. It flees once it has lost about two thirds of its strength."), and ambush is included in ENC_SPECIAL.

INFERRED: When ambush fulfills the column guarantee of "at least one non-Engagement encounter per map column after the first" alongside rout nodes, the entire column reduces to "kill two-thirds of their ships" with zero positional, escort, or timer objectives.

### [FIX] A .38 null archetype rate with no column deduplication leaves nearly two-fifths of fights without fleet identity and guarantees vanilla sector openers.

READ: core.js assigns n.arch=x<.25?'swarm':x<.47?'heavy':x<.62?'carrier':null via raw rnd() with no adjacency or column filter, while rollEncounter hardcodes col===0?'rout':pick(ENC_POOL) and n.mod requires n.col>=2.

INFERRED: Every sector's col 0 is 100% rout with 0% node modifiers and a 38% chance of null archetype; in later columns, independent rnd() rolls allow an entire column of nodes to roll null archetype (or all roll the same archetype), blunting route-planning choices.

### [FIX] hunt and break do not filter out extreme faction-mobility mismatches (sp:1-2 vs sp:5-7 + Crystal vanes).

READ: In data.js, Ithar cruisers and carriers move at sp:5 and sp:4 (i_song, i_carrier) with MOVE_RULES.ithar granting "After moving 2+ hexes, enemies get -18 to hit it" (Crystal vanes), whereas Hegemony and Deathless capital ships move at sp:1-2 (h_dominion, d_harvester). Both hunt and break roll obstructed shapes like 'dense', 'corridor', and 'archipelago' across all factions.

INFERRED: A 6-round hunt on 'corridor' or 'dense' against an Ithar flagship running at sp:4-5 with a permanent -18 to hit penalty (and -33 in a dark nebula sector) is an extreme mobility/accuracy gate compared to hunting a sp:2 Deathless cruiser under the exact same encounter label.

### [NOTE] ENCOUNTERS.rout.shapes lists 'archipelago' twice, and ENC_ARENA omits five of the eight encounter types.

READ: In battle.js, rout.shapes is ['open','lanes','ring','dense','deadstar','rift','shoals','hourglass','archipelago','archipelago','colossus'] (11 items, 'archipelago' duplicated), and ENC_ARENA only defines aspect weights (strip, square, round) for rout, hold, and flagship.

INFERRED: 'archipelago' rolls at double weight (18.2% vs 9.1%) in the game's most common encounter (rout), while break and intercept - which conceptually depend on crossing to a far edge - lack dedicated 'strip' or 'square' arena aspect entries in ENC_ARENA.

### [NOTE] Node modifiers (bounty, veteran) are gated to col>=2 and leave 74% of battles and 86% of elites unmodified.

READ: core.js sets n.mod=n.col>=2&&y<.14?'bounty':n.col>=2&&n.type==='battle'&&y<.26?'veteran':null.

INFERRED: Because columns 0 and 1 have zero modifiers, elites can never roll veteran, and nearly three-quarters of col>=2 battles roll null, node modifiers are too sparse to rescue nodes that also roll n.arch = null (28.1% of col>=2 battles and 32.7% of col>=2 elites have neither an archetype nor a modifier).

## 3. Explicit checks

### 1. DISTINCTNESS

Ranking from most to least distinct as games:

break (Breakthrough): Most distinct. It inverts the combat loop from destruction to extraction ("a ship that ends its move on a green hex jumps clear" while enemies block ahead and pursue from behind), making forward movement and hull survival the sole win condition.

hold (Relay): Second most distinct. Winning requires uncontested hex adjacency ("Have a ship next to the relay, with no enemy there, at the start of 3 rounds"), turning the fight into a positional king-of-the-hill contest.

defend (Hold the station): Third. A 6-round defensive survival clock centered on an allied firing structure with a 2-hex danger zone ("Every enemy ship within 2 hexes of it at the start of a round knocks out 1 integrity").

intercept (Intercept): Fourth. Forces target prioritization against non-combatant movers ("Enemy transports are crossing to the far side (red hexes). Destroy them before they get through") while absorbing enemy escort fire.

hunt (Hunt): Fifth. A 6-round VIP chase ("Their flagship is running and jumps out at the end of round 6. Destroy it before then"), which forces aggressive forward commitment even though the win condition is still killing one ship.

rout (Engagement): Sixth. The baseline fleet-attrition game ("Break their fleet. It flees once it has lost about two thirds of its strength") against which all other modes are measured.

flagship (Decapitation): Seventh (bottom two). Requires killing the enemy flagship ("Destroy their flagship and the rest of their fleet scatters"), overlapping heavily with hunt (same target, same 11 shapes, no 6-round flee clock) and with rout whenever the flagship comprises a large share of fleet CP.

ambush (Ambush): Least distinct (bottom two). Uses the exact same win condition as rout ("Break their fleet.") with a split starting deployment ("Two enemy groups close in from both sides").

Single change to separate each of the bottom two:

For flagship (Decapitation): Give the enemy flagship a Command Link rule (while any escort ship is within 3 hexes of the flagship, the flagship redirects 50% of incoming damage to that escort), forcing the player to either strip/displace the bodyguard screen first or bring area/piercing tools rather than treating it as an untimed hunt.

For ambush (Ambush): Change the objective from "Break their fleet" to Hold out / Regroup (your fleet deploys split into two groups on opposite sides of an enemy center; win by surviving 5 rounds or linking both groups within 2 hexes of a central beacon), or demote ambush from ENCOUNTERS into NODE_MODS.

### 2. TELEGRAPHING

The map preview (name, description, archetype, modifier, shape) honestly prices rout, hold, and flagship, whose descriptions state complete, self-contained win conditions. Five encounters undersell or obscure their difficulty in the preview text:

defend (Hold the station) - Severely undersells: States that each enemy within 2 hexes knocks out 1 integrity, but hides the station's total integrity pool and battery strength. Worse, it hides the interaction with swarm: the player sees swarm ("Many light hulls. Broadsides and flak shine") and expects low hull threat, not realizing that 6+ cheap frigates rushing the 2-hex ring each tick 1 integrity per round regardless of their weak guns.

intercept (Intercept) - Undersells: States "Destroy them before they get through", omitting how many transports spawn, their HP/armor class, and whether leaking a single transport is an instant defeat.

break (Breakthrough) - Undersells: States "Get ships off the far edge: a ship that ends its move on a green hex jumps clear", omitting how many ships must jump clear to win and whether slow ships (sp:1-2) left on the board when the fight ends take penalties.

hunt (Hunt) - Undersells faction/condition synergy: States "Their flagship is running and jumps out at the end of round 6", which hides that an Ithar flagship (sp:4-5, -18 to hit after moving 2+ hexes via Crystal vanes) on 'dense' or 'corridor' in a 'dark' (-15 to hit in nebulae) or 'ion' sector is a vastly harder 6-round DPS/mobility check than hunting a sp:2 Hegemony or Deathless hull.

ambush (Ambush) - Undersells turn-1 crossfire: "Two enemy groups close in from both sides. Break their fleet." reads like a standard Engagement, underselling that starting flanked invalidates directional shield facings and punishes slow turners (tn:1) on round 1.

### 3. THE BOSS ROLL

What bossEncounter() buys: Rolling pick(['rout','rout','ambush','flagship']) across ['ring','open','hourglass'] buys run-to-run variety in turn-1 deployment and prevents the player from memorizing a single opening formation against each faction's boss.

What it costs: It sacrifices authored climax pacing and creates severe objective/hull mismatches. In rout (50%), "It flees once it has lost about two thirds of its strength" means either the sector boss anticlimactically flees alive when its escort dies, or its cp:10-12 weight forces a near-total wipe anyway. Furthermore, restricting boss shapes to ['ring','open','hourglass'] (and only ['ring','open'] when ambush rolls, since ENCOUNTERS.ambush.shapes excludes 'hourglass') means boss arenas have very low spatial variety.

What happens to the boss hull's identity under Decapitation (flagship, 25%): The boss hull's identity collapses into a stationary HP check (hp:470-650) and its fixed escort becomes decorative noise. Sustaining/summoning bosses like c_boss (Warlord's Pyre-Barge, hangar:2), b_boss (The Ninefold Maw, hangar:3, regen:20), and d_boss (The Unsetting, regen:8) are designed around 7-8 round attrition where escorts screen for hangars and per-round regeneration compounds; under flagship, the optimal play is to ignore every escort ship, burn all cooldowns (focus, reload) onto the sp:1-2 boss hull, and end the fight in 3-4 rounds so the escort scatters for free.

### 4. DISTRIBUTION

Reconstructed three-sector fight menu (READ rules from battle.js, core.js, data.js; INFERRED ~5 columns of ordinary/elite nodes + 1 boss column = 6 fights per sector, 18 fights per run):

Sector 1 (corsair or hegemony, e.g., ion condition):

Col 0: rout (100% forced) | null arch (38%) or swarm/heavy/carrier | no mod (col<2).

Cols 1-4 (4 nodes): Drawn from ENC_POOL (8 types, 12.5% each) with >=1 ENC_SPECIAL per col and no adjacent same-type in a col. Expect ~1 more rout or ambush, plus 3 objective fights (e.g., defend, hunt, hold). Archetypes: ~1-2 null, ~1 swarm, ~1 heavy, ~0-1 carrier. Modifiers (col>=2): 0-1 node gets bounty (14%) or veteran (12% on battles).

Boss (c_boss or h_boss): 50% rout / 25% ambush / 25% flagship on open, ring, or hourglass, fixed escort.

Sector 2 (chorus, ithar, or hegemony, new SECTOR_CONDS e.g., dark):

Col 0: Forced rout | 38% null arch | no mod.

Cols 1-4: Same ENC_POOL (8 types) and same ARCHETYPES probabilities (38% null / 25% swarm / 22% heavy / 15% carrier), ~1 modified node.

Boss (b_boss, i_boss, or h_boss): 50% rout / 25% ambush / 25% flagship on open, ring, or hourglass.

Sector 3 (deathless, chorus, or ithar, new SECTOR_CONDS e.g., wreck):

Col 0: Forced rout | 38% null arch | no mod.

Cols 1-4: Same ENC_POOL and same ARCHETYPES (with 15% of deathless nodes rolling broken carrier 'Repair host').

Boss (d_boss, b_boss, i_boss, or mirror ascendant): 50% rout / 25% ambush / 25% flagship on open, ring, or hourglass.

Where repetition actually sets in:

Archetypes repeat first (within Sector 1 and across the whole run): With a .38 null share, only 3 non-null archetypes (swarm, heavy, carrier), and zero column/adjacency deduplication in core.js, the player sees null (default roster) on ~6 of 15 non-boss nodes and the exact same 3 archetype buckets in every sector.

Encounter types repeat second (by Sector 2): Although 8 keys exist, col===0 is always rout (3 per run), bosses are 75% rout/ambush and 25% flagship, and inside ENC_POOL rout + ambush (25%) are both fleet-break brawls while hunt + flagship (25%) are both kill-the-flagship races. Over an 18-fight run, roughly 10 to 12 fights are either "break their fleet" or "kill their flagship".

Shapes repeat only on bosses (and 'archipelago' in rout): Ordinary fights draw from 5 to 10 shapes per encounter and are well varied (except 'archipelago' rolling at 2x weight in rout), whereas bosses only ever use open, ring, or hourglass.

### 5. ARCHETYPES

The .38 no-archetype share: In col===0, a null archetype serves as a clean control group to introduce the sector faction's baseline mechanics (MOVE_RULES and roster mix). In col>=1, .38 null is a variety failure: it strips tactical telegraphing from nearly two out of five map nodes and leaves ~30% of col>=2 nodes with neither an archetype nor a modifier.

Do the three archetypes change how a fight is flown, or only what the enemy fleet contains?

In their text definitions, they are framed primarily as loadout checks (swarm: "Broadsides and flak shine; lances are wasted on them."; heavy: "Bring lances, torpedoes and a flank."; carrier: "Fighters and flak pay off.").

In actual flight execution (INFERRED from hull stats and MOVE_RULES), heavy and swarm do change how a fight is flown: heavy hulls have tn:1 and sp:1-4, enabling and rewarding flanking arcs ("and a flank"), while swarm floods the board with sp:5-7, ev:14-28 frigates that threaten hex-count objectives (defend, hold) and require broadside positioning (MOVE_RULES.voidsworn: "Port and starboard guns hit 40% harder after moving 2+ hexes"). carrier, however, mainly changes target selection (snipe the sp:2-4 carrier or screen its squadrons) - and on deathless (sq:null, no carrier hull) it fails to even change what the fleet contains.

## 4. Not checked

This evidence pack does not contain the code required to judge:

Fleet spawning & CP budgeting logic: How n.arch (swarm, heavy, carrier, null) selects hulls from FACTIONS[fac].roster, what carrier actually spawns when fac === 'deathless', and what fixed escort compositions accompany each sector boss.

Missing hull and weapon definitions: The stat blocks for the player faction (voidsworn roster 'warden', 'harrow', 'penitent', 'reliquary', 'cathedral' and mirror boss 'ascendant'), Hegemony light hulls ('h_picket', 'h_interdictor'), weapon damage/range/arc tables (turbo, hturbo, ion, scatter, bioplasma, pulsar, gauss, doom, etc.), and active ability values (nova, surge, phase, reclaim, frenzy, regrow).

Objective parameters and AI behaviors: The station's starting integrity and battery stats in defend, transport count/HP/speed in intercept, required ship extraction count in break, and whether AI ships actively play the objective (e.g., rushing the station in defend or running away in hunt).

Map shape and column geometry code: How many columns (COLS) and nodes per column a sector generates, how fitEncounter(n) enforces column rules, and how ENC_ARENA interacts with ENCOUNTERS[enc].shapes.

Elite node scaling: What makes an elite node harder than a battle node and why Sector 2 elites drop bot win rates to 69.9%.

## 5. Questions for the designer

1. What does the fleet generator actually spawn when a Deathless (deathless) node rolls the 15% carrier archetype ('Repair host') given sq:null and no carrier in FACTIONS.deathless.roster? Stakes: If it spawns wingless d_harvester cruisers while the map preview advises "Fighters and flak pay off", players are actively misled by the UI in Sector 3.
2. In a boss fight that rolls rout (50% of bosses), can the player win by killing the escort and chipping the boss to the two-thirds fleet loss threshold so the sector flagship flees alive, and in flagship (25% of bosses), why does the boss have an escort if killing the boss immediately scatters it? Stakes: If rout lets bosses flee and flagship makes escorts pointless, three-quarters of boss fights undermine the sector climax's narrative and tactical framing.
3. Why is n.arch left null on 38% of battles and elites beyond col 0 instead of guaranteeing an archetype (or a fourth 'balanced'/'raider' archetype) with column-level deduplication? Stakes: Cutting the null rate after col 0 and preventing same-column archetype repeats is the single cheapest way to eliminate mid-run node repetition without authoring new hulls.
