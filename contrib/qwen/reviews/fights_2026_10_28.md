# Qwen blind leg: encounter and boss fight audit (Oct 28, 2026)

Chair note: filed verbatim from the model's reply (Qwen3.8-Max, both model gates passed; no slider challenge appeared). Em dashes and en dashes normalized to hyphens per house rule; wording otherwise unchanged. Chat: https://chat.qwen.ai/c/dd34c910-a33f-46f7-af22-f1dc57d54a10. Evidence pack: the Oct 28 battle program fights pack (code slices pinned to main 264f441d). Method notes and screening live outside this file.

# Encounter & Boss Fight Audit - Voidsworn

## Proof of Reading

Sections read:
EVIDENCE PACK title line ("encounter and boss fight audit... main 264f441d")
THE COMMISSIONER'S QUESTION
CHAIR CENSUS (all bullet points)
WHAT TO JUDGE (items 1-5)
Code slices: battle.js 55-70 (ENCOUNTERS table, ENC_POOL, ENC_SPECIAL, bossEncounter(), rollEncounter()); data.js 76-135 (boss hulls, faction rosters, MOVE_RULES, FACTIONS, SECTOR_POOL, ABILITIES); core.js 285-300 (archetype assignment, node modifiers, sector conditions); data.js 593-640 (ARCHETYPES table, NODE_MODS, SECTOR_CONDS, HEAT, PATRONS, BOONS)

Overall verdict: DISTINCT ON PAPER.
The eight encounters carry genuinely different win conditions in code, but two pairs (Engagement/Ambush, Hunt/Decapitation) share the same core verb or target, so felt distinctness at the table will be narrower than the code implies.

## Findings

1. [BLOCKER] Engagement and Ambush are the same objective with a deployment twist.
READ: Engagement is "Break their fleet. It flees once it has lost about two thirds of its strength." Ambush is "Two enemy groups close in from both sides. Break their fleet." Both resolve on fleet attrition; Ambush adds only a spatial wrinkle (two spawn sides). INFERRED: If Ambush also triggers the two-thirds flee threshold (the code does not specify otherwise), the player's decision tree is identical - focus fire until the rout bar fills - and the "ambush" is purely cosmetic. This is the single closest pair in the set and the one most likely to read as a reskin in session.

2. [BLOCKER] Decapitation as a boss encounter type voids the boss escort and reduces the climax to a single-target DPS check.
READ: "Destroy their flagship and the rest of their fleet scatters." READ: bosses "keep their own escort rather than a rolled archetype." INFERRED: Under Decapitation the escort is mechanically irrelevant; the player ignores it and alpha-strikes the boss hull. The boss's identity collapses to its hit points, armour value, and ability cooldown. The sector climax becomes "kill the big stat block before you die," which is the least interesting version of a boss fight.

3. [FIX] The boss encounter roll weights Engagement at 50 %, the most generic outcome.
READ: pick(['rout','rout','ambush','flagship']) gives rout a 2-in-4 chance. INFERRED: Half of all sector climaxes play as the same attrition objective the player has already completed many times in ordinary nodes. The roll buys variance but spends half its budget on the least distinctive option. A boss rolling Engagement is functionally "a bigger ordinary fight."

4. [FIX] Hunt and Decapitation both centre on killing a flagship; their distinction is only timer vs. scatter.
READ: Hunt: "Their flagship is running and jumps out at the end of round 6." Decapitation: "Destroy their flagship and the rest of their fleet scatters." INFERRED: Both make the flagship the sole meaningful target. Hunt adds time pressure; Decapitation removes the need to clear escorts. In practice both funnel the player into "ignore the fleet, focus the big ship." A player who has done Hunt will read Decapitation as "Hunt without the clock."

5. [FIX] Intercept undersells its time pressure in the preview text.
READ: "Enemy transports are crossing to the far side (red hexes). Destroy them before they get through." INFERRED: The description does not state how many transports there are, how fast they move, or how many rounds the player has. A player committing to this node cannot price the difficulty. The red-hex destination is visible on the shape preview, but the speed/count is hidden, making Intercept the most likely "trap" encounter on the map.

6. [FIX] Relay's win condition is a timing check the description buries.
READ: "Have a ship next to the relay, with no enemy there, at the start of 3 rounds." INFERRED: The check fires at the start of a round, not the end. A player who kills the last contesting enemy during their own turn but cannot reposition before the round starts will fail the check. The word "uncontested" in the CHAIR CENSUS glosses this; the in-game description says "no enemy there," which is clearer but still doesn't flag the start-of-round timing. This is the encounter most likely to produce "why didn't it count?" moments.

7. [NOTE] Shape pools overlap heavily across encounters, reducing shape as a differentiator.
READ: 'open' appears in all eight encounters. 'dense' appears in seven. 'archipelago' appears in seven. 'ring' appears in five. INFERRED: The shape roll does not meaningfully separate the encounters from each other; it varies the terrain within an encounter but does not make, say, a Hold-the-station feel structurally different from an Intercept by board alone. The ENC_ARENA table adds a secondary arena filter (strip/square/round) for rout, hold, and flagship only, leaving five encounters without that layer.

8. [NOTE] Boss hulls are stat blocks with one ability; the pack does not show a multi-phase or scripted behaviour layer.
READ: Boss abilities are 'nova', 'launch', 'regrow', 'surge', 'phase', 'reclaim'. Each is a single keyword. INFERRED: Without evidence of phase transitions, adds-spawning triggers, or scripted movement patterns in this pack, the bosses read as high-HP ships with a cooldown ability. The regenerating bosses (Ninefold Maw regen 20, Unsetting regen 8) do create a distinct feel (DPS race vs. sustain), but the others rely on their weapon loadout and the escort for texture.

9. [NOTE] The .38 no-archetype share is a deliberate control group, but it is the plurality outcome.
READ: x<.25?'swarm':x<.47?'heavy':x<.62?'carrier':null yields 38 % null. INFERRED: More than a third of ordinary fights present no tactical framing beyond "enemy fleet." The ARCHETYPES descriptions do tell the player what to bring ("Broadsides and flak shine; lances are wasted on them"), so the 62 % that do roll an archetype are well-telegraphed. But the plurality outcome is "no archetype," which means the most common single category is the absence of one.

10. [NOTE] Node modifiers (bounty, veteran) arrive only from column 2, leaving sector-1 maps without any per-node twist.
READ: n.col>=2&&y<.14?'bounty':n.col>=2&&n.type==='battle'&&y<.26?'veteran':null. INFERRED: Sector 1 (columns 0-1) never rolls a modifier. The first sector's fight menu is therefore the plainest it will ever be, which may read as the tutorial sector by accident rather than by design.

## Explicit Checks

### DISTINCTNESS

Ranking the eight encounters from most to least distinct as games:
Breakthrough - unique verb (escape off the far edge), asymmetric pressure (blockers ahead, reinforcements behind), green-hex exit mechanic. No other encounter asks the player to disengage rather than destroy.
Hold the station - unique defensive object with its own integrity pool and batteries, fixed round timer, enemy proximity as damage trigger. The only encounter where the player protects a non-ship entity.
Intercept - moving targets with a destination, positional denial. The only encounter where the enemy's goal is traversal, not combat.
Relay - area-control endurance with a timing check. The only encounter where the player must hold rather than destroy or reach.
Hunt - single-target DPS race against a round-6 clock. The timer makes it distinct from pure attrition.
Decapitation - single-target focus fire, fleet scatters on kill. Differs from Hunt by removing the clock and making escorts irrelevant, but the core verb (kill the flagship) is shared.
Ambush - "Break their fleet" with two-sided deployment. The spatial pressure is real but the win condition is identical to Engagement.
Engagement - baseline attrition to two-thirds losses. The default against which the others are measured; by definition the least distinct.

Bottom two - single change to separate them:
Engagement (8th): Give the enemy a scaling morale mechanic: each ship lost after the first raises the remaining fleet's accuracy or speed by a small percentage, so the fight accelerates as it progresses. This turns Engagement into a "race against escalating power" rather than a flat attrition bar, separating it from Ambush's static two-sided pressure.
Ambush (7th): Make the two waves arrive on different rounds (e.g., the second group jumps in at round 3) rather than both being present at start. This forces the player to sequence their focus and creates a mid-fight inflection point that Engagement's single-group structure cannot replicate.

### TELEGRAPHING

The map preview shows encounter name, description, archetype, modifier, and shape before commitment. Assessment per encounter:
Engagement, Ambush, Decapitation: Honestly priced. "Break their fleet" and "Destroy their flagship" are unambiguous. The archetype tag further tells the player what hull mix to expect. No trap.
Hold the station: The description names the integrity mechanic and the round-6 timer. Honest. The player can see the station's batteries mentioned. No trap.
Hunt: "Jumps out at the end of round 6" is a clear clock. The player knows the DPS requirement. Honest.
Breakthrough: "Get ships off the far edge... more close in from behind" telegraphs the pincer. Green hexes are visible on the shape preview. Honest.
Relay: The description says "at the start of 3 rounds" but does not flag that the check is start-of-round, meaning the player must have cleared the point during the previous round's enemy phase. INFERRED: This is the one encounter whose text slightly undersells its timing strictness. A player who reads "hold it for 3 rounds" may not realise they need to clear it before the round starts, not during it.
Intercept: As noted in Finding 5, the description does not state transport count, speed, or the effective round limit. The player sees the red hexes on the shape but cannot calculate the DPS requirement. This is the encounter most likely to ambush the player despite being previewed.
Verdict: Telegraphing is good for six of eight encounters. Intercept undersells its time pressure; Relay slightly undersells its timing check.

### THE BOSS ROLL

READ: pick(['rout','rout','ambush','flagship']) - 50 % Engagement, 25 % Ambush, 25 % Decapitation. Shape restricted to ['ring','open','hourglass'] filtered by the encounter's allowed shapes.
What the roll buys: Variation in how the player must approach the climax. An Ambush boss forces the player to handle escorts arriving from two directions while the boss hull sits in the middle. A Decapitation boss lets the player skip the escort and go straight for the kill, rewarding alpha-strike builds. Without the roll, every boss is Engagement, which is the most-repeated objective in the game.
What it costs: Consistency of climax identity. The sector boss is the narrative and mechanical peak of a sector, but the player cannot know in advance whether the fight will be an attrition slog (Engagement), a two-front pressure test (Ambush), or a single-target burst check (Decapitation). The CHAIR CENSUS notes the boss encounter "rolls... on a restricted shape set," but the player sees the boss node on the map and can read the encounter type before committing, so the cost is mitigated by telegraphing.
Decapitation specifically: This is the problematic outcome. When the boss encounter is Decapitation, the boss's fixed escort becomes irrelevant by rule. The boss hull's identity - its weapon loadout, its ability, its hit points - is all that matters. The Iron Mandate's nova, the Ninefold Maw's regen-20, the Unsetting's doom lance: these are the boss. The escort is set dressing. INFERRED: This makes Decapitation the weakest boss roll because it collapses the fight to "kill the stat block," which is the least mechanically rich version of a boss encounter. The 25 % chance means roughly one in four sector bosses will play this way.
Is a boss hull plus escort sufficient? INFERRED: As delivered in this pack, yes for two of three roll outcomes (Engagement and Ambush give the escort a role). For Decapitation, no - the escort is wasted and the boss is a stat block with a name and one ability. The pack does not show scripted phases, enrage timers, or mid-fight ability escalation that would give the boss hull a second gear.

### DISTRIBUTION

READ: Column 0 is always 'rout' (Engagement). Columns 1+ draw from ENC_POOL (all eight types). Pool logic guarantees "at least one non-Engagement encounter per map column after the first" and "forbids adjacent same-type fights in a column." ENC_SPECIAL (['defend','hunt','intercept','break','ambush','hold','flagship']) is noted as the pool for non-Engagement rolls.
Reconstructed three-sector menu (typical run, ~4 columns per sector, ~12 fights total):
Sector 1, Column 0: Engagement (fixed).
Sector 1, Columns 1-3: one guaranteed non-Engagement per column, drawn from seven types. No adjacent repeats. Expect 2-3 distinct special types plus 1-2 Engagements.
Sector 2, Columns 0-3: Column 0 resets to Engagement. Columns 1-3 again guarantee non-Engagement. By now the player has seen 6-8 of the 8 types at least once.
Sector 3, Columns 0-3: Same structure. The player has likely seen all 8 types at least once. Repeats begin to accumulate.
Where repetition sets in: INFERRED: Across three sectors the player faces roughly 3 forced Engagements (column 0 each sector) plus Engagements that roll naturally in later columns. At the 2-in-8 base rate for rout in ENC_POOL, that adds ~2 more, giving ~5 Engagements out of ~12 fights - about 42 %. The special encounters (7 types) share the remaining ~7 slots across three sectors, meaning each special type appears roughly once per run. Repetition hits types first (Engagement dominates), then shapes (the overlapping shape pools mean two different encounter types can roll the same board), and archetypes last (the .38 null and three-way split keep archetype variety reasonable within a sector).
The adjacency ban helps within a column but does not prevent the same type appearing in column 1 of sector 1 and column 1 of sector 2. INFERRED: A player on an unlucky run could face Hunt in sector 1 column 2, then Hunt again in sector 2 column 2, with no rule preventing it.

### ARCHETYPES

READ: .25 swarm, .22 heavy, .15 carrier, .38 none. Descriptions: swarm = "Many light hulls. Broadsides and flak shine; lances are wasted on them." Heavy = "Few, big hulls. Bring lances, torpedoes and a flank." Carrier = "Built around a carrier and its wings. Fighters and flak pay off."
Is .38 no-archetype a variety failure or a control group?
INFERRED: It functions as a control group. The three archetypes each prescribe a different weapon/fleet composition (broadside-heavy for swarm, lance/torpedo for heavy, flak/fighter for carrier). The 38 % null fights let the player bring a generalist loadout without being punished for not specialising. Without the null bucket, every fight would demand a specific answer and the player's fleet-build choices would be over-determined. However, .38 is the plurality outcome, meaning the most common single experience is "no special rule." If the intent is to make archetypes feel like meaningful modifiers, the null share is slightly too high; .25-.30 would keep a control group while making archetypes feel more common.
Do the three archetypes change how a fight is flown, or only what the enemy fleet contains?
READ: The descriptions reference weapon types (broadsides, flak, lances, torpedoes, fighters) and positional advice ("a flank"). INFERRED: The archetypes change fleet composition, which indirectly changes how the fight is flown - a swarm of 8 frigates demands different target prioritisation than 2 battleships. But the pack does not show archetype-specific AI behaviour (e.g., swarm ships swarming, heavy ships holding a line, carrier ships keeping distance). Without behaviour changes, the archetypes are loadout modifiers: they change what the player brings more than how the enemy acts. The per-faction names (Wolfpack, Line of Battle, Brood cluster, etc.) are flavour text that reinforce the composition difference but do not add mechanical depth.

## Not Checked

This pack does not allow judgement of:
Actual combat resolution mechanics. The pack shows weapon slots, armour values, and ability keywords but not the hit/damage/penetration formulas. I cannot judge whether "broadsides shine against swarm" is mechanically true or merely stated.
AI behaviour and fleet tactics. No code for enemy ship activation, targeting priority, movement AI, or formation logic is included. I cannot verify whether a "swarm" fleet actually behaves differently from a "heavy" fleet in motion.
Boss ability implementation. The pack lists ability keywords (nova, regrow, surge, phase, reclaim, launch) but not their code. I cannot judge whether the Ninefold Maw's regen-20 creates a meaningfully different fight from the Unsetting's regen-8, or whether nova is a one-shot or a multi-phase mechanic.
Player-side fleet composition and Command system. The pack references "Command reaches full power a round later" (HEAT) but does not include the Command ability set. I cannot judge whether the player has enough tools to differentiate their approach across encounter types.
Actual shape layouts. The pack names shapes (open, lanes, ring, dense, etc.) but does not include hex-grid definitions. I cannot judge whether 'open' and 'dense' produce meaningfully different tactical situations.
Squadron/fighter mechanics. Carrier archetype and boss hangars reference fighters, but the pack does not include squadron rules. I cannot judge whether the carrier archetype is mechanically distinct.
Sector conditions' interaction with encounters. SECTOR_CONDS are listed but their interaction with specific encounter types (e.g., does Ion season affect Hold-the-station batteries?) is not shown.

## Questions for the Designer

Does Ambush use the same two-thirds flee threshold as Engagement? If yes, Ambush is a deployment variant of Engagement and should either gain a distinct win condition (e.g., the second wave doesn't flee and must be fully destroyed) or be folded into Engagement as a shape modifier. Stakes: the two most common encounter types in the game may be functionally identical.
What is the intended player experience when a boss rolls Decapitation? The escort becomes irrelevant by rule; the fight reduces to a single-target kill. Is this the desired climax, or should Decapitation bosses gain a mechanic that makes the escort matter (e.g., the escort must be suppressed before the boss becomes targetable, or killing the boss while escorts live triggers a second phase)? Stakes: one in four sector bosses may play as the least mechanically interesting version of a boss fight.
Should Intercept's preview telegraph transport count and speed? Currently the player sees the destination hexes but not the time budget. Adding "4 transports, 2 hexes per round" or a round counter to the preview text would let the player price the fight honestly. Stakes: Intercept is the most likely encounter to feel like a trap despite being previewed, which erodes trust in the map's information.
