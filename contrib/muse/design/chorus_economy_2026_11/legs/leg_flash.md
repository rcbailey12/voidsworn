# Leg: Flash (Gemini, "Quick answers 3.5 Flash-Lite", signed in; picker verified before and after)
# Chorus without shipyards, issue 1047. Model's response, verbatim.

As one leg of the design council, I have evaluated the evidence pack and synthesized four distinct, systemic approaches for the Chorus campaign layer that completely bypass conventional shipyards while keeping the run structure, CP cap, and strategic tension intact.

1. Biomass & Spore-Sacks (The Zerg Hive Economy)
How it works

The Chorus discards standard credit-based repairs and shipyard purchases entirely. Instead, every battle yields Biomass (harvested from enemy wrecks) alongside a small trickle of standard Credits (retained only for non-ship run purchases like relics or mercenary hires).

On the campaign map, Shipyard nodes are replaced by Spawning Grounds (or can be infested by spending Biomass). At a Spawning Ground, the player spends Biomass to:

Mend: Instantly stitch hull back onto damaged ships (cost scaling with hull mass).

Bud: Grow entirely new hulls from the swarm's genetic template library (unlocked progressively by sector depth rather than shipyard tier).

Evolve (Marks): Feed dense biomass packages into existing ships to mutate them to Mk II / Mk III, adding hull and damage.

Reference games & lessons

StarCraft (Zerg): Lesson: Separating growth and repair from generic currency into a dedicated biological resource (Larvae/Minerals vs. Biomass) makes a faction feel structurally alien while naturally restricting hoarding.

Stellaris (Devouring Swarm): Lesson: Consuming the vanquished turns combat momentum directly into long-term strategic compounding.

The player decides

The Growth-vs-Repair Dilemma: Do I spend my harvested Biomass patching up my core b_razor cruiser right now, or save it to bud a fresh b_spitter to fill my vacant CP slot before the next sector boundary?

Node Routing: Prioritizing hazardous combat nodes to harvest high-yield wreckage versus safe nodes that offer utility.

Failure modes & trade-offs

Death Spirals: If a player loses a major battle and lacks the biomass to heal survivors, they cannot fight effectively to earn more, accelerating a collapse.

Credits Irrelevance: If credits are completely useless for the Chorus, finding credits in events or chests feels hollow. (Mitigation: Credits can still buy generic relics/consumables, or be "digested" into a fraction of Biomass at specialized nodes).

Rough build size

Medium. Requires a new campaign resource (biomass), replacement map node logic for shipyards, and modified reward tables for combat encounters.

2. Devouring Tides (The Consumption Loop & Feast-Famine Cycle)
How it works

The Chorus never repairs or builds ships passively. Shipyard and Drydock nodes are replaced by Consumption Pockets or Feeding Grounds (map nodes where the player can choose to "Digest").

No Passive Healing: Ships do not repair between jumps. Instead, healing and growth happen exclusively through aggressive consumption actions on the map layer: sacrificing captured enemy hulls, converting surplus minor ships into raw organic paste (decommissioning with a multiplier), or spending a "Refit" item charge (leveraging the existing Gorge mechanic).

Replacement: New ships are grown by "splitting" a high-tier ship (e.g., a brood-sac or heavy cruiser) into smaller spawn, or consuming stored wreck-mass to hatch new units at rest nodes.

Marks: Upgrading Marks requires "Absorbing" elite traits from captured high-tier enemy data/wrecks found at specific anomaly nodes.

Reference games & lessons

Endless Space 2 (The Cravers): Lesson: Forced depletion and relentless forward momentum. The faction must feed constantly; if it stops moving and eating, it starves.

FTL: Lesson: Strict scarcity of resources forces players to make agonizing trade-offs between hull integrity and progression.

The player decides

Aggressive Momentum: The player is incentivized to take high-risk, high-frequency combat nodes because every victory feeds the swarm's sustainment loop, while resting on empty nodes offers zero recovery.

Cannibalization: Do I scrap my damaged frigate to feed the bio-titan, or nurse it through the next fight?

Failure modes & trade-offs

Map Starvation: If RNG starves the player of combat or wreck nodes for 2-3 jumps, the fleet degrades beyond recovery.

Boss Fights: Designing a run-ending boss encounter requires ensuring the player has a pre-boss feeding opportunity, otherwise a worn-down swarm hits a brick wall.

Rough build size

Small-to-Medium. Reuses existing inventory items (Gorge, refits) and campaign event flags, tweaking node interaction scripts to remove standard credit repairs and replace them with consumption mechanics.

3. Cellular Regeneration & Metamorphosis (Rest-Site Evolution)
How it works

The Chorus relies entirely on internal biological regeneration over time and rest. Shipyards, Drydocks, and Repair nodes are replaced by Chrysalis / Incubation Nodes.

The Stasis Jump: When visiting an Incubation node, the player enters a deep-rest state. The entire fleet automatically regenerates 100% of its hull over a "metamorphosis cycle," but doing so costs run-time (e.g., advancing an internal sector doom-clock, or consuming temporal/energy resources equivalent to fuel).

Replacement & Growth: New ships cannot be bought; instead, existing ships undergo cellular division (budding). A frigate can split into two smaller drones over two rest cycles, or a brood-sac can gestate a new capital hull at the cost of temporarily lowering fleet CP while it matures.

Marks: Upgrades are treated as physical growth spurts (shedding old skin/armor plates for thicker chitin) triggered at major sector checkpoints using accumulated battle experience.

Reference games & lessons

Slay the Spire (Rest Sites): Lesson: Forcing a binary, highly consequential choice at rest stops (Rest to heal vs. Upgrade/Smith) creates deep tactical depth per sector.

Sins of a Solar Empire: Lesson: Factions with asymmetric economic models that do not rely on standard planet-build queues maintain distinct operational tempos.

The player decides

Tempo Control: Do I rush the sector exit to outrun escalating threat meters while my fleet is half-dead, or do I pause at multiple Chrysalis nodes to fully regenerate and gestate new units at the cost of letting enemy forces consolidate?

Gestational Vulnerability: Deciding when to tie up fleet capacity in growing new biological units versus maintaining maximum combat strength.

Failure modes & trade-offs

Pacing Disconnect: If the game's core sector timer is too tight, players will never choose to rest/regenerate, leading to inevitable death spirals. If too loose, players abuse the rest loop to enter every fight at full health.

Dead Nodes: Standard map variety suffers if all replacement nodes feel like passive waiting rooms.

Rough build size

Medium. Requires a campaign-layer rest/incubation state machine, sector-pacing adjustments, and a growth-queue mechanism for budding ships.

4. Parasitic Swarm (Infestation & Assimilation)
How it works

The Chorus interacts with existing map nodes by parasitizing them rather than using them as a customer. Shipyards and Drydocks are treated as prey.

Infestation: When visiting a Shipyard or Drydock node, the Chorus player chooses to Infest it instead of trading. This consumes the node permanently, converting it into a Spawning Maw.

Repair & Growth via Infestation: Infesting a node instantly restores the fleet to full hull integrity (ripping raw metals and biological components from the facility) and yields "Genetic Material" used to hatch new hulls or evolve Marks. Once infested, the node is consumed and disappears from future pathing options in that sector.

Econ Loop: Credits are entirely abandoned for the Chorus; instead, "Infestation Points" or structural debris gathered from consumed stations govern their entire non-combat progression.

Reference games & lessons

Stellaris / 4X Parasitic Mechanics: Lesson: Subverting standard infrastructure of civilized factions makes an alien swarm feel truly predatory and disruptive to the game world.

Roguelite Resource Conversion: Lesson: Turning map utility structures into consumable resources creates high-stakes pathing puzzles (do I eat this shipyard now for a massive heal, or save it for later when I'm more damaged?).

The player decides

Pathing & Infrastructure Denial: Choosing which map nodes to consume permanently versus preserving them (though since they can't use normal shipyards anyway, consuming them is pure upside).

Over-extension: Venturing deeper into hostile territory to find rich station nodes to infest to sustain an oversized fleet.

Failure modes & trade-offs

Map Design Dependency: Relies heavily on nodes being pre-populated with shipyards/drydocks. If a sector layout generates few or no shipyards, the Chorus starves.

UI/UX Clarity: Clear distinction needed so players understand that standard facilities are now feeding troughs.

Rough build size

Medium-to-Large. Requires a new node interaction mode ("Infest"), node-consumption state tracking, and a modified reward/sustenance payout for converted stations.

Ranked Top Pick & Strategic Risk
Top Pick: Approach #1 (Biomass & Spore-Sacks)

Why: It fits the faction's lore ("engineered flesh that lives on starlight, eats anything") perfectly without breaking the roguelite rhythm. Replacing credits/shipyards with a dedicated biological harvest loop (Biomass) gives the Chorus a distinct economic identity (akin to the Zerg) while cleanly separating hull repair, ship budding, and Mark evolution into intuitive, strategic choices. It preserves the fast-paced flow of jumps and battles while making every enemy ship destroyed feel immediately rewarding to a living swarm.

Single Biggest Risk Across All Approaches

The "Death Spiral vs. Snowball" Balancing Tightrope: Because the Chorus relies on organic sustainment (feeding, biomass, or consumption) rather than flat credit purchases, successful players who manage early fights will snowball into an unstoppable, self-healing swarm that never needs to visit a shop. Conversely, a single devastating early-game loss will starve the player of the resource needed to recover, creating an inescapable, miserable death spiral. Careful tuning of floor-bound resource drops and baseline regeneration safety nets will be essential to prevent runs from being decided in the first two sectors.
