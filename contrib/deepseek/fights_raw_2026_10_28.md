# DeepSeek blind leg: encounter and boss fight audit (Oct 28, 2026)

Chair note: filed verbatim from the model's reply (DeepSeek, DeepThink and Search on; chat https://chat.deepseek.com/a/chat/s/449e2f2a-c4cc-4623-b2ee-57d1e0215077). Em dashes and en dashes normalized to hyphens per house rule; wording otherwise unchanged. Evidence pack: the Oct 28 battle program fights pack (code slices pinned to main 264f441d). Method notes and screening live outside this file.

1. Proof of reading

Read: EVIDENCE PACK title line; THE COMMISSIONER'S QUESTION; CHAIR CENSUS; WHAT TO JUDGE; code slices for ENCOUNTERS and boss encounter roll (battle.js 55-70), boss hulls and faction rosters (data.js 76-135), archetype assignment and node modifiers (core.js 285-300), and ARCHETYPES (data.js 593-640, including adjacent NODE_MODS/SECTOR_CONDS/HEAT in the supplied pack).

Overall verdict: DISTINCT ON PAPER - the eight objectives are genuinely different in the census, but Ambush is a deployment variant of Engagement and the boss Decapitation roll collapses the escort into irrelevance, so execution is weaker than the text.

2. Findings

1. [BLOCKER] Boss Decapitation makes the fixed escort strategically irrelevant. READ: bossEncounter() can pick 'flagship'; ENCOUNTERS.flagship says "Destroy their flagship and the rest of their fleet scatters"; bosses "keep their own escort." INFERRED: on that boss roll the escort is a speed bump, not a designed part of the climax, and the boss hull becomes a single HP target.

2. [FIX] Breakthrough's preview does not state the escape threshold. READ: "Get ships off the far edge: a ship that ends its move on a green hex jumps clear." INFERRED: the player cannot price how many ships must escape, so the text undersells the actual win condition and can feel like a trap.

3. [FIX] Ambush is Engagement with a different deployment. READ: both use "Break their fleet"; Ambush only adds "Two enemy groups close in from both sides." INFERRED: it is a tactical variant, not a distinct game objective, making it one of the two weakest designs.

4. [FIX] The boss roll is half plain Engagement. READ: pick(['rout','rout','ambush','flagship']). INFERRED: 50% of sector climaxes are the baseline fleet-break; the roll buys variety but costs a reliably special climax and does not tie boss hull identity to a unique objective.

5. [FIX] Hold the station's preview omits the station's starting integrity and destruction threshold. READ: "knocks out 1 integrity" is stated, but no starting value or fail point is in the text. INFERRED: the player cannot judge how many leaks are fatal, so the preview underprices the defense burden.

6. [NOTE] Distribution protection is per-column, not per-run. READ: the pool guarantees "at least one non-Engagement encounter per map column after the first" and forbids adjacent same-type fights in a column. INFERRED: it does not prevent repetition across columns or sectors; over three sectors the eight-type pool necessarily repeats.

7. [NOTE] Boss arenas are heavily restricted. READ: bossEncounter() filters to ['ring','open','hourglass']; Ambush does not include hourglass, so an Ambush boss is only ring or open. INFERRED: boss shape repetition is structural, not incidental.

8. [NOTE] .38 no-archetype is a control group, but it is the modal ordinary fight. READ: archetype assignment is x<.25?'swarm':x<.47?'heavy':x<.62?'carrier':null. INFERRED: 38% of ordinary fights have no announced composition twist; that is not automatically a variety failure, but it weakens the map preview's loadout signal.

9. [NOTE] The three archetypes are composition/loadout hints, not objective changes. READ: swarm is "Many light hulls," heavy is "Few, big hulls," carrier is "Built around a carrier and its wings." INFERRED: they change target priority and weapon choice - flak/broadsides vs lances/torpedoes vs fighters/flak - but not how the encounter is won.

10. [NOTE] Within this pack, boss identity is hull data + ability + escort, not a demonstrated phase script. READ: boss hulls carry boss:true and abilities such as nova, launch, surge, and regen values. INFERRED: the evidence does not show phase mechanics, so a boss hull plus escort is sufficient only if the objective forces interaction with both; Decapitation does not.

3. Explicit checks

1. DISTINCTNESS

Ranked most to least distinct as games:

1. Hold the station - defense, integrity loss, timer, station batteries; distinct fail condition.
2. Breakthrough - exit/escape objective with pursuit and reinforcements; win by leaving, not killing.
3. Intercept - moving transports crossing to an edge; target priority and leak failure.
4. Relay - area control at the start of three rounds; contest a point over time.
5. Hunt - flagship assassination under a round-6 deadline.
6. Decapitation - flagship assassination with morale collapse; kill one ship and the fleet scatters.
7. Ambush - fleet-break with two-sided deployment; same win condition as Engagement but forces split attention.
8. Engagement - baseline fleet-break with morale flee at about two-thirds losses; least distinct.

Bottom two: Ambush and Engagement.

Single change for Ambush: change the win condition from "Break their fleet" to "destroy one of the two pincers before the groups link," so the two-sided deployment becomes the objective rather than only the opening geometry.

Single change for Engagement: make the morale flee mechanical - once the enemy breaks, surviving ships flee to a map edge and the player must pursue/block them - so it is a pursuit game rather than plain fleet annihilation.

2. TELEGRAPHING

The preview shows encounter name, description, archetype, modifier, and shape before commitment. That is the right information in principle, but not all text honestly prices difficulty.

Engagement: honest enough; "flees once it has lost about two thirds of its strength" gives a rough duration.

Ambush: honest about two groups, but not honest about being the same win condition as Engagement; that is a distinctness problem more than a difficulty trap.

Hold the station: undersells/obscures the real burden. It says "knocks out 1 integrity," but the preview does not state starting integrity or the destruction threshold.

Hunt: honest; "jumps out at the end of round 6" is a clear deadline.

Intercept: under-specified; "before they get through" does not state transport count, speed, or whether any leak is allowed.

Breakthrough: the clearest undersell. "Get ships off the far edge" does not state how many ships must escape, so the player cannot price commitment.

Relay: mostly honest, but "at the start of 3 rounds" is ambiguous about whether the three rounds must be consecutive.

Decapitation: honest in an ordinary fight, but in a boss fight it silently bypasses the fixed escort because "the rest of their fleet scatters."

The encounters whose text most clearly undersells their mechanics are Breakthrough and Hold the station; Intercept is next.

3. THE BOSS ROLL

The roll buys variety: a sector boss can be a fleet-break, an ambush, or a decapitation, so not every climax is the same objective. It costs predictability and focus: 50% of bosses are still Engagement, and the boss's fixed escort is not selected by archetype, so boss replay variety is narrower than the roll suggests. When the objective is Decapitation, the boss hull's identity collapses toward "high-HP single target": the hull may still have nova/launch/regen/surge data, but the win condition does not force the player to deal with the escort, so the boss is closer to a stat block with a name than a designed fleet climax. A boss hull plus escort is sufficient only when the objective forces the player to fight both; the current roll permits the opposite.

4. DISTRIBUTION

Assumption: the map has multiple columns and ordinary battle/elite nodes appear across them; the pack does not give exact COLS or node-type weights. INFERRED from that: sector column 0 is forced Engagement; later columns each contain at least one non-Engagement and no adjacent same-type fight within the column. Across three sectors, the same eight-type pool is reused, so every type can recur and Engagement is overrepresented because column 0 is forced and bosses are 50% Engagement. Boss nodes are 50% Engagement, 25% Ambush, 25% Decapitation. Ordinary fights are 25% swarm, 22% heavy, 15% carrier, 38% none. Repetition sets in most at shapes and boss objectives, and at the 38% no-archetype modal ordinary fleet; the encounter-type labels themselves are protected within a column, but not across a three-sector run.

5. ARCHETYPES

.38 no-archetype is best read as a control group: a baseline enemy fleet with no announced composition twist. It is not a variety failure by definition, but at 38% it is the single most common ordinary-fight state, so the map preview often has no archetype signal. The three archetypes do change how a fight is flown, but through composition and target priority rather than objective: swarm rewards flak/broadsides and punishes lances; heavy rewards lances/torpedoes/flanking; carrier rewards fighters/flak and prioritizes the carrier. They are real tactical prompts, not pure reskins, but the pack's code slice only shows label assignment, not spawn composition, so the strength of that change is INFERRED.

4. Not checked

Exact map column counts and node-type weights; therefore the exact "typical" three-sector menu cannot be reconstructed.

Actual station integrity values, transport counts/speeds, Breakthrough escape quota, Relay consecutiveness, and whether partial leaks are allowed.

Full boss phase scripts, AI, and moment-to-moment behavior; only hull data and encounter rolls are in the pack.

Player fleet composition, upgrades, boons, admiral effects, and how they interact with these objectives.

Whether shape names and hex layouts make the objectives play as differently as their descriptions imply.

Spawn logic for archetypes beyond label assignment.

Godot port parity beyond the pack's statement that it mirrors this design.

5. Questions for the designer

1. What are the exact win/loss thresholds for Breakthrough and Hold the station, and why are they omitted from the preview? Stakes: players cannot price commitment and may feel trapped by hidden fail conditions.

2. When a sector boss rolls Decapitation, is the fixed escort intended to be irrelevant, or should boss objectives be constrained so the escort remains part of the climax? Stakes: the sector finale either becomes a DPS check or the escort design is wasted.

3. What is the intended modal ordinary fight: the 38% no-archetype baseline or one of the three archetypes? Stakes: if the baseline is modal, the map preview's archetype line is often empty and loadout planning is less meaningful.
