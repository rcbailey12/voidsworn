# Torpedo and boarding rules proposals: DeepSeek leg

Provenance: generated in DeepSeek chat on Oct 24, 2026, DeepThink ON, Search OFF, signed in as rcbailey12@gmail.com. File upload was unavailable (no file chooser, no file-input element), so the brief and CONVERSATION_CONTEXT.md were pasted as verbatim text into the chat prompt, brief first. Thinking trace excluded; tables reconstructed from the response text. Em dashes in the model's text were normalized to hyphens for the no-em-dash rule; wording is otherwise verbatim. Screening and synthesis against the Qwen leg follow separately; nothing here is verified.

Grounding ledger for both proposals

All rules below are proposed new rules. Existing-design claims are marked inline. All numbers are first-pass tuning values unless marked OBSERVED.

- OBSERVED: "Ryan decided PC-only in Babylon." This proposal assumes desktop-only Babylon rendering and no phone-tier compromises.
- OBSERVED: "Target battle size stays near the current scale (around 20 ships)" and "The PC headroom goes to graphics and effects quality, not to much larger battles." Therefore both systems must stay legible with roughly 20 ships, not grow into ordnance-bookkeeping games.
- OBSERVED: "Smallish fleets, strictly turn based, and fun." The rules below are turn-based and use end-of-round ordnance phases, not real-time tracking.
- OBSERVED: "Treat Rogue Trader's voidship combat as the battle feel north star for Voidsworn." The borrowed verbs are torpedo travel with arrival-turn target choice and boarding as a real ship action; no officer posts are imported.
- OBSERVED: "torpedoes with travel time that herd movement" and "facing and firing arc discipline." Torpedoes below are ballistic, telegraphed, arc-limited, and do not chase.
- OBSERVED: "boarding as a real verb" and "critical hits on named ship systems that change what a ship can do." Boarding below causes fires, engine crippling, system damage, crew damage, or capture/salvage outcomes.
- OBSERVED: "fewer, heavier activations beat many light ones" and "so every activation carries weight." Launching and boarding each consume a meaningful weapon action and are capped so one activation does not become a subgame.
- OBSERVED: "Space ships, never naval ships." Terminology below uses voidship, hull, dorsal/ventral, void, and hex facing; no naval framing is intended.
- INFERRED: Because battles are around 20 ships and per-activation weight is the target, both systems need hard caps on active markers and no per-crew rosters. A torpedo or boarding action must be one marker or one opposed roll, not a chain of submenus.
- Brief constraint, not OBSERVED: no officer posts appear in these rules. Boarding is a ship-level action using abstract boarding parties, not crew posts.

Proposal 1 - Torpedoes on a Hex Grid

1. Design intent

Torpedoes are telegraphed area-denial weapons with travel time, not fire-and-forget damage. They are launched without a target, travel across turns, and choose their target on the arrival turn. They herd enemy movement because their future path is visible, not because they secretly track ships. This directly borrows the verb described as OBSERVED: "torpedoes with travel time that herd movement," while keeping hex tactics readable and deterministic.

2. Torpedo object and limits

A torpedo is one physical marker on the hex grid with:
- owner;
- heading, one of the six hex faces in its current altitude plane;
- current hex and altitude layer;
- speed, normally 3 hexes per turn;
- fuel, normally 5 turns;
- armor, normally 3;
- type: standard, proximity, or boarding-torpedo variant;
- no target at launch.

Active limit: no more than 4 active torpedoes per side. If a side would exceed this, the oldest torpedo is removed at the end of the round with a visible "fuel dump" icon. INFERRED: this cap is necessary because a 20-ship battle with uncapped ordnance markers would turn the end-of-round phase into bookkeeping, violating the per-activation weight target.

Launch limit: a ship may launch at most one torpedo per round. A ship may not launch and fire another weapon in the same activation.

3. Launch action cost, arc, and range

Action cost: launching costs one weapon action. The launching ship may move before or after the launch, but it may not fire another weapon or launch a second torpedo in that activation.

Arc: the torpedo's first hex must lie in the ship's forward 120° arc, defined on the hex grid as the three adjacent hex faces centered on the ship's bow. This is the hex expression of OBSERVED: "facing and firing arc discipline."

Range: there is no minimum range. Maximum practical range is the torpedo's fuel: 5 turns × 3 hexes = 15 hexes. There is no target lock at launch; the player chooses only a heading and starting hex. A launch is illegal if the first hex is occupied by a friendly ship or blocked by terrain.

3D hex note: altitude is part of the hex distance. A standard torpedo stays in its launch altitude plane unless a scenario or variant says otherwise. A torpedo may not change altitude in standard rules; this keeps the threat lane readable at battle zoom.

4. Travel speed and end-of-round movement

Torpedoes move in an ordnance phase at the end of the round, after all ships have activated. Each torpedo moves 3 hexes in a straight line along its current heading. It does not turn in standard rules.

Movement resolution:
1. Move the torpedo one hex at a time.
2. Friendly ships do not block torpedoes; they are transponder-tagged.
3. Enemy ships do not stop movement unless the torpedo enters their hex, which triggers arrival.
4. Asteroids, dense debris, and scenario blockers destroy the torpedo on entry.
5. If the torpedo exits the board or runs out of fuel, remove it.

INFERRED: end-of-round movement is chosen because it makes the threat lane a planning object for every activation in the round. Players move ships knowing where ordnance will be after the round, which creates herding without interrupting each activation.

5. Interception en route

Any ship may attempt interception by spending one reaction when a torpedo enters a hex within 2 hexes of that ship and inside that ship's forward arc. A ship may spend at most one reaction per round, and a torpedo may be intercepted at most once per round.

Use a new printed Point Defense (PD) rating. If the repo already has an anti-fighter or point-defense rating, map PD to it; if not, this proposal adds PD as a ship stat. Default PD for a ship with no listed defense is 1.

Resolve deterministically:
- PD ≥ 3: torpedo destroyed.
- PD = 2: torpedo loses 1 speed for the rest of its flight, to a minimum of 1.
- PD ≤ 1: no effect.

INFERRED: deterministic interception is preferred over an extra die roll because the turn already has movement, targeting, and damage; a single comparison keeps the activation weight on the launching and defending player's decision, not on resolution bookkeeping.

6. Arrival turn: target selection, evasion, damage, area effect

Arrival triggers when the torpedo enters a hex containing one or more enemy ships, or when it reaches its final fuel hex.

Target selection on arrival: the launching player selects one enemy ship in the arrival hex. This is the borrowed verb: target choice happens on the arrival turn, not at launch.

Evasion: after target selection, the target may spend one reaction to evade. It shifts one hex perpendicular to the torpedo's heading if it has not already moved this round and the destination is legal. If the shift leaves the arrival hex, the torpedo misses and is removed. If the shift is impossible, the target may brace instead.

Damage, standard torpedo:
- Full hit: 2 hull damage and 1 critical hit to a named system chosen by the attacker from the target's exposed systems: engines, fire control, shields, or boarding bays.
- Braced hit: 1 hull damage, no critical.
- Critical effects are concrete: engine critical reduces speed by 1 for 2 rounds; fire control critical disables one firing arc for 1 round; shield critical drops shield rating by 1 until repaired; boarding bay critical blocks boarding for 2 rounds.

Area effect: standard torpedoes have no area effect. A proximity variant may be used in scenarios: all ships in the arrival hex and adjacent hexes take 1 hull damage, but only the primary target can suffer a critical. The proximity variant costs one extra fuel turn or one extra weapon-action cost if the scenario wants it rarer.

INFERRED: named-system criticals are included because the benchmark verb is OBSERVED: "critical hits on named ship systems that change what a ship can do." They are kept to one critical per hit so a torpedo does not become a second damage phase.

7. Herding without breaking hex tactics

Torpedoes herd movement through visible threat lanes, not hidden tracking.

At all times, the UI shows:
- the torpedo marker;
- its heading arrow;
- its next two movement hexes;
- its arrival envelope: the hex it will enter next ordnance phase and the hex after that;
- fuel pips;
- speed pips.

Because the torpedo cannot turn and has no target at launch, an enemy can:
- move out of the projected lane;
- cluster to bait a proximity variant, accepting splash risk;
- spend a reaction to intercept;
- force the launcher to spend another weapon action on a second torpedo;
- approach from a facing outside the torpedo's arc.

The defender's counterplay is positional, not a hidden check. This preserves hex tactics: facing, altitude layer, and movement order matter, but no player has to track a secret target or a chasing missile.

8. What the player sees at battle zoom

Stage | Battle-zoom read
Launch | Short tube flash on the launching hull; a bright heading arrow leaves the bow; a translucent ghost lane extends 2-3 hexes. No target reticle appears.
Transit | One torpedo marker with speed pips and fuel pips; projected lane and arrival envelope drawn as dashed hex outlines. Color is owner-coded, not cyan unless shields are involved.
Interception | Point-defense tracers from the interceptor to the torpedo hex; a white flash on the marker; either removal icon or a "speed down" pip.
Arrival | Target ring snaps to the selected ship; evasion arrow shows one-hex slide; impact flash; critical icon over the named system; fire icon if a fire result occurs.
Expiry / fuel end | Small fizzle marker and removal; no hidden explosion unless the scenario uses proximity fuel-end detonation.

9. Bookkeeping controls

- One marker per torpedo.
- No torpedo crew, no officer posts, no submenus.
- Maximum 4 active torpedoes per side.
- One launch per ship per round.
- Interception is one comparison, not an opposed roll.
- End-of-round ordnance phase handles all movement at once.

INFERRED: these caps keep the system inside the per-activation weight target and prevent a 20-ship battle from becoming a torpedo spreadsheet.

Proposal 2 - Boarding

1. Design intent

Boarding is a real ship action that produces lasting consequences: fires, crippled engines, system damage, crew damage, and capture/salvage outcomes. It is not an officer post and not a crew-minigame. The borrowed verb is OBSERVED: "boarding as a real verb," with consequences in the same family as OBSERVED: "critical hits on named ship systems that change what a ship can do."

2. Initiation: range, delivery, action cost

Primary delivery method: assault shuttle. Boarding is initiated at range 1-2 hexes using 3D hex distance. The attacker spends one weapon action and expends one boarding party from the ship's abstract Boarding Rating. The shuttle crosses immediately as a visible boarding flash; it is not a tracked multi-turn marker in the standard rule.

Action cost: one weapon action. The boarding ship may move before or after, but may not fire another weapon or launch a torpedo in the same activation. A ship may initiate at most one boarding action per round.

Requirement: the attacker must have Boarding Rating 1 or higher and at least one boarding party remaining. Boarding Rating is an abstract ship stat, not a crew post. A ship with Boarding Rating 0 cannot board.

Long-range variant: boarding torpedo. A scenario may allow a boarding torpedo using the torpedo travel rules from Proposal 1, with speed 2, fuel 4, no area damage, and boarding resolution on arrival instead of hull damage. This variant is optional and counts against the same active-marker cap.

Shields: if the target's shields are up, the boarding action suffers -2 to its opposed check. This gives shields a concrete anti-boarding role without adding a separate shield-subgame.

3. Resolution: opposed check

Boarding resolves as one opposed check at the end of the attacker's activation:

2D6 + attacker Boarding Rating + modifiers vs. 2D6 + defender Crew Defense + modifiers

Modifiers are deliberately few:
- Target shields up: -2 attacker.
- Target already has a fire: -1 defender.
- Adjacent friendly ship spends a reaction to assist defense: +1 defender, maximum +2.
- Defender spends a Repel reaction: +2 defender.
- Target is crippled: +1 attacker.
- Boarding torpedo delivery: +1 attacker if the torpedo survived interception.

INFERRED: one opposed roll per boarding action is acceptable decision weight; a chain of crew checks would not be. The roll is the tension point, and the consequence table does the rest.

4. Consequences

Resolve by margin of success: attacker total minus defender total.

Margin | Result
≤ 0 | Repelled. Attacker loses the boarding party; no defender effect.
1-2 | Sabotage. Attacker chooses one system: fire control, engines, or shields. That system takes one damage. Place one fire marker in that system.
3-4 | Cripple. Target's engines are crippled: speed halved and no hard turn for 2 rounds. Place one fire marker. Target suffers -1 Crew Defense until repaired.
5 | Deep strike. Target suffers one critical system hit chosen by attacker and one fire. If target is already crippled, it may be captured instead.
6+ | Capture / salvage. If target is crippled, it is captured. In the current battle a captured ship becomes a derelict and cannot activate; in campaign it becomes salvage. If target is not crippled, treat as deep strike plus engine cripple.

Fires: a fire marker causes 1 hull damage at the end of each round until suppressed. Suppression costs one damage-control action from the burning ship or an adjacent friendly ship. Fires are visible at battle zoom and change movement/boarding decisions.

Engine crippling: crippled engines halve speed and forbid hard turns for 2 rounds. This is the concrete "crippled engines" verb, not a vague penalty.

Crew damage: represented as -1 Crew Defense until repaired, not as a roster of individual crew. INFERRED: this keeps boarding consequences meaningful without turning the turn into personnel bookkeeping.

Capture: kept rare and gated behind "already crippled" so a single boarding roll does not flip a healthy 20-ship battle. The campaign can treat captured hulls as salvage; the battle treats them as derelicts.

5. Counterplay for the defender

The defender has four concrete counters:
1. Repel reaction: before the opposed check, spend one reaction to add +2 to Crew Defense. One reaction per ship per round.
2. Point-defense interception: if the attacker uses a boarding torpedo variant, any ship with PD may intercept under the torpedo interception rules.
3. Escort assist: an adjacent friendly ship may spend a reaction to add +1 defender, maximum +2 total from escorts.
4. Damage control: after boarding, the defender can spend a damage-control action to suppress one fire or repair one crippled engine tick.

INFERRED: these counters keep boarding from being a pure attacker's choice. The defender's decision is whether to spend the reaction now or save it for torpedo interception or evasion.

6. Turn cost

- Attacker spends one weapon action and one boarding party.
- Defender may spend one reaction to repel or assist.
- Resolution is one opposed roll.
- Fires persist until suppressed.
- Engine crippling lasts 2 rounds.
- Crew Defense penalty lasts until repaired.
- Capture is resolved immediately but represented as derelict/salvage, not as a new controllable ship in the current battle.

Active cap: no more than 3 boarding actions per side per round. A ship may be the target of at most one boarding action per round. This cap is INFERRED from the 20-ship, per-activation-weight target: boarding should be a heavy verb, not a swarm of markers.

7. What the player sees at battle zoom

Stage | Battle-zoom read
Initiation | Boarding bay flashes on the attacker; a shuttle trail arcs to the target; a docking clamp icon appears. If shields are up, a shield-ripple icon shows the -2 modifier.
Repel reaction | Defender hull flashes a "repel" icon; a small shield/interior flash; no text wall.
Opposed check | One compact boarding flash at the target; two small dice icons or a single margin pip, not a full-screen panel.
Sabotage | Fire icon on the named system; system icon dims.
Cripple | Engine icon turns dark; smoke/vent plume at battle zoom; speed pips drop.
Deep strike | Critical icon on one system plus fire icon.
Capture / salvage | Target hull goes derelict gray; capture flag or salvage marker; no immediate control flip in battle.

8. Bookkeeping controls

- No officer posts.
- Boarding parties are an abstract ship rating, not a roster.
- One opposed roll per boarding action.
- Maximum 3 boarding actions per side per round.
- One boarding target per ship per round.
- Fires and engine cripples use the same marker language as torpedo criticals.

INFERRED: this keeps boarding readable at battle zoom and prevents the turn from turning into a personnel or damage-location audit.

Open questions I could not resolve from this brief

1. Action economy mapping: does the existing game already have "weapon actions" and "reactions," or must these labels be mapped onto a different activation budget?
2. Point Defense stat: does a PD or anti-fighter rating already exist? If not, should PD be a new printed stat or derived from ship class?
3. Boarding Rating and Crew Defense: do these stats already exist in any form, or are they entirely new proposal-side stats?
4. Turn order: is the game alternating activation, simultaneous planning, or initiative order? The end-of-round ordnance phase assumes all ships activate before torpedoes move.
5. Damage model: does the current design use hull/structure/system criticals, or a different damage language? The proposal's "2 hull + 1 critical" needs mapping.
6. Shield interaction: do shields already have a rating that can impose the proposed -2 boarding modifier, or is that a new shield rule?
7. Capture policy in a roguelite: should capture ever grant immediate control, or always become derelict/salvage as proposed? Immediate control risks snowballing at 20 ships.
8. 3D altitude: may torpedoes change altitude layer? Standard rules say no; if the hex grid expects vertical maneuvers, the threat-lane UI needs a vertical projection.
9. Fighter/interceptor craft: if the game has strike craft, should they intercept torpedoes instead of or in addition to ship PD?
10. Visual asset readiness: the design pack proves torpedo flight and boarding flash as visuals, but I could not verify from the granted context whether the current torpedo and boarding meshes support heading arrows, fuel pips, fire markers, and engine-cripple plumes at battle zoom.

What evidence would change my proposal

1. Playtest activation time: if a 20-ship turn exceeds the target decision time because of threat lanes or boarding rolls, I would remove the second projected torpedo hex, reduce active torpedo cap from 4 to 2, or make boarding resolution deterministic instead of opposed.
2. Analysis paralysis evidence: if players freeze over arrival envelopes, I would shorten fuel to 3 turns and increase speed to 4, making torpedoes faster but less persistent.
3. Torpedoes fail to herd: if playtests show players ignore lanes, I would add a small movement penalty for ending in a projected arrival hex or increase proximity-variant splash.
4. Torpedoes over-herd: if lanes make movement too constrained, I would add more interception opportunities or allow a hard turn of one hex face per turn at the cost of speed.
5. Boarding too swingy: if one opposed roll decides battles, I would replace the 2D6 opposed check with a deterministic Boarding Rating vs Crew Defense threshold and a smaller consequence table.
6. Boarding too weak: if players never spend a weapon action on it, I would let boarding ignore shields at a higher cost or allow escort assists to add boarding strength.
7. Capture snowball: if captured ships create runaway battles, I would remove immediate capture entirely and use only derelict/salvage outcomes.
8. Readability failure at battle zoom: if threat lanes, fire icons, and crippled-engine plumes are not readable at the default camera, I would collapse torpedo UI to one lane color and one arrival hex, and move boarding detail to a single icon.
9. Existing action economy conflict: if the repo's action system cannot support reactions without bookkeeping, I would make interception and repel once-per-round ship states tracked by one token, not per-system reactions.
10. Damage-model mismatch: if the current damage model has no named systems, I would replace criticals with "disable one weapon arc" and "reduce speed" tokens until system damage exists.
