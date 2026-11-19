# Leg: Qwen (Qwen3.8-Max, selector verified before submit and header after; no A/B comparison appeared)
# Chorus without shipyards, issue 1047. Model's response, verbatim.

Council Leg: Chorus Between-Battle Sustainment - Five Proposals

Approach 1 - The Long Feast (Biomass Economy)

How it works

Every Chorus kill in battle, every wreck left drifting, every consumed event node deposits biomass into a fleet-level pool (the "crop"). Credits still drop from battles, but the Chorus cannot spend them at shipyards; instead, credits convert to biomass at a poor fixed rate (say 3 credits → 1 biomass) at any node, representing the swarm converting dead matter into living fuel. Biomass is the Chorus's true currency.

On the campaign map, shipyard nodes are replaced by Feeding Grounds - organic nodes where the swarm docks on a half-living asteroid or gas-cloud membrane. At a Feeding Ground the player spends biomass to:

Heal: 1 biomass per 4 missing hull, applied fleet-wide or per ship. No cap on how much you can regrow if you can pay.
Spawn a new ship: the Feeding Ground stocks 2-3 Chorus hulls (scaled to sector tier), priced in biomass. Small hulls cost roughly 60-70% of what the equivalent credit price would be; capitals cost 130-160%. CP cap still enforced.
Evolve (replaces Marks): spend biomass to push a ship to the next Evolution tier (Mk I → II → III). Each tier adds +20% hull and +15% damage, same numbers as Marks, but flavoured as the ship growing denser bone-plates and larger weapon-organs. No shield component because there are no shields.
Decommission: dissolve a ship back into the crop for a small biomass refund (about 30% of its spawn cost).

Drydock nodes become Deep Feeding Grounds: full heal, no biomass cost, but they appear rarely (same frequency as drydocks today). Field-repair nodes become Drift-Kill: every ship regrows 20% hull for free, flavoured as the swarm stripping a debris field.

The existing Gorge admiral power and Spawning Field event remain unchanged; they already heal and already set the fed flag. They simply become relatively more valuable because they are free healing in a system where healing otherwise costs biomass.

Reference games and lessons

Stellaris - Devouring Swarm / Necrophage origin. Food is the single strategic resource; you eat planets to grow fleets. Lesson: a single "stuff you ate" currency can replace credits entirely for one faction without breaking the shared economy, as long as conversion rates are visible and predictable. The Chorus crop works the same way: everything the swarm touches becomes fuel.
Endless Space 2 - Cravers. The Cravers deplete a system's population and must keep moving to find more. Lesson: tying the resource to combat kills and wrecks (rather than passive income) keeps the Chorus aggressive and forward-moving, which matches the faction bible ("one appetite"). It also creates natural scarcity in quiet sectors, preventing infinite healing.
FTL - scrap economy. Scrap is earned in combat, spent at stores for repairs and hulls. Lesson: a single earned-in-combat currency covering heal + buy + upgrade is legible and keeps every battle economically meaningful. The Chorus biomass should follow this: you feel the crop grow after every fight.

Player decisions

Spend now vs. bank: do you heal the spitter's 30 missing hull at this Feeding Ground, or save biomass for a brood-sac in the next sector?
Evolve one vs. spawn many: 12 biomass could push a razor to Evolution II or spawn two drones. Depth vs. width.
Convert credits? The 3:1 credit-to-biomass rate is deliberately bad. A player sitting on 40 credits from a Corsair-sector prize must decide whether the conversion is worth it or whether to just push on.
Which ships to heal: no shields means every hull point is real. Triaging a half-dead drone-spawn vs. a bruised brood-sac is a genuine choice.

Failure modes

Snowball: a player who wins every fight accumulates biomass faster than they spend it, arriving at the boss with a full-strength max-CP fleet. Mitigation: cap the crop (e.g., max 40 biomass carried between nodes) or make Feeding Grounds heal at diminishing returns above 80% hull.
Death spiral: lose a fight badly → few kills → little biomass → can't heal → lose worse. Mitigation: Deep Feeding Grounds (drydock equivalents) and Drift-Kill nodes provide free floors. The existing Spawning Field event also helps.
Dead map nodes: if a sector has no Feeding Ground and the player is hurt, they must push through on hull alone. This is actually fine for a roguelite, but the sector generator must guarantee at least one Feeding Ground per sector.
Boss fight distortion: The Ninefold Maw (cp 12, 650 hp) is expensive in biomass. If the player has been spending on small hulls, they may never afford it. The price ladder must be tuned so the boss is reachable by mid-run if the player saves.
Other factions' relative value: Corsairs and Ithar still use credits at shipyards. If biomass is strictly better, those factions feel worse. Mitigation: the conversion rate is bad, Feeding Grounds appear at the same frequency as shipyards, and the Chorus still can't buy captured enemy hulls (no "eating" a Corsair frigate into a Chorus shape).

Shipyard job coverage

Shipyard function | Covered? | How
Heal damage | Yes | Biomass at Feeding Grounds
Replace losses | Yes | Spawn hulls at Feeding Grounds
Grow fleet | Yes | Spawn hulls, CP cap enforced
Mark upgrade | Yes | Evolution tiers, same stat deltas

Nothing dropped.

Build size

Medium. Needs a biomass resource tracked per run, a faction hook that swaps shipyard UI for Feeding Ground UI, a credit-to-biomass conversion button, and Evolution-tier stat application. No battle-layer changes. The spawning field event and Gorge already exist and need no modification.

Approach 2 - Molt and Evolve (Rest-Site Binary Choice)

How it works

The Chorus does not repair at nodes. Instead, the map contains Molt Sites (replacing shipyard nodes for Chorus runs). At a Molt Site the player must choose one action for the whole fleet stop:
Regrow: every ship heals 40% of its missing hull. No cost.
Evolve one ship: pick a single ship; it gains one Evolution tier (+20% hull, +15% damage). No cost.
Spawn: a single new ship appears at the Molt Site, chosen from 2 options the game rolls. Costs credits (normal hull price × 0.7 for frigates/destroyers, × 1.3 for cruisers+). CP cap enforced.
You cannot do two of these at the same stop. The choice is the mechanic.

Additionally, between every jump the Chorus passively regrows 5% of each ship's missing hull (a slow campaign-layer regen representing the swarm's biology). This is not battle regen; it is a small drip between nodes. Over four jumps a ship recovers 20% without stopping, which is meaningful but not full.

Drydock nodes become Deep Molt: full heal for the fleet, no choice required. Field-repair nodes unchanged (20% heal, free).

Marks are replaced by Evolution tiers as above. There is no way to heal and evolve at the same node. Period.

Reference games and lessons

Slay the Spire - Rest Sites. At a rest site you heal or smith (upgrade a card). You cannot do both. The scarcity of rest sites and the binary choice create the most consequential decisions in the run. Lesson: forcing heal-vs-upgrade at a single node makes every stop feel weighty and prevents the "full heal + full upgrade" power creep that shipyards allow. For the Chorus, whose entire defence is hull, choosing not to heal is genuinely scary.
Hades - Rest Stops. You can heal, upgrade a boon, or fish. The choice is low-stakes per stop but compounds. Lesson: even small binary choices feel good when the run is short and every stop counts.
Into the Breach - limited repair between islands. You get a few hull points back, maybe. You choose which mech to patch. Lesson: partial healing that doesn't top you off keeps tension alive into the next fight.

Player decisions

Heal or evolve? The core question. A fleet at 60% hull facing a sector boss probably heals. A fleet at 85% might gamble on evolving the razor.
Which ship to evolve? Only one per stop. The brood-sac's extra hull matters more than a drone's, but the drone's +15% damage might swing the next fight.
Spawn now or later? Spending credits on a new hull means you used the Molt Site for spawning instead of healing. The fleet is bigger but more damaged.
Do I skip the Molt Site? If the fleet is healthy and no evolution is tempting, the player can skip the node entirely and keep moving. This should be a valid choice.

Failure modes

Feels restrictive: players used to shipyards (heal + buy + upgrade in one stop) may feel punished. Mitigation: the 5% per-jump passive regrow softens the edges, and Deep Molt nodes give full heals.
Death spiral: if the player keeps choosing Evolve and skips healing, they enter fights at low hull and lose ships, which makes future fights harder. This is player-caused, but the UI should warn when fleet average hull is below 50%.
Boss fight: arriving at the Ninefold Maw with a fleet that skipped two Molt Sites to evolve is a high-risk, high-reward strategy. The boss's 650 hp and regen 20 mean the fight is long; unhealed hull is brutal. This is fine - it should be.
CP distortion: spawning is the only way to grow, and it costs credits. If the player is credit-poor (Chorus gets fewer credits because they can't sell at shipyards?), they can't spawn. Mitigation: keep credit drops from battles normal; only the spending changes.
Other factions: Corsairs and Ithar still get full shipyard service. The Chorus player may feel they're playing a harder game. That's intentional asymmetry, but the 5% passive regrow and free Deep Molts should keep the floor close.

Shipyard job coverage

Shipyard function | Covered? | How
Heal damage | Yes | Regrow option at Molt Sites, 5% per jump, Deep Molt
Replace losses | Yes | Spawn option at Molt Sites (credits)
Grow fleet | Yes | Spawn option, CP cap enforced
Mark upgrade | Yes | Evolve option, one ship per stop

Nothing dropped, but healing and upgrading are mutually exclusive per stop, which is the point.

Build size

Small-Medium. Needs a Molt Site node type with three-button UI, a faction hook to route Chorus runs to Molt Sites instead of shipyards, and a 5%-per-jump passive regrow tick on the campaign map. Evolution tiers reuse the Mark stat logic. No battle-layer changes.

Approach 3 - Gestation Tide (Growth Over Jumps)

How it works

The Chorus does not heal at nodes. It heals between nodes. After every jump (every transition between map nodes), each Chorus ship regrows 8% of its missing hull. Over five jumps, a ship at 40% hull returns to full. This is the swarm's biology: it is always growing, always knitting flesh. The player never pays to heal. Healing is time.

Replacing losses: when a Chorus ship is destroyed in battle, its biomass is not lost. It enters a Gestation Queue visible on the campaign screen. The dead ship's hull type begins regrowing. It takes a number of jumps equal to its CP cost (drone = 1 jump, spitter = 2, razor = 3, brood-sac = 5). When the timer hits zero, the ship reappears in the fleet at full hull, no cost, as long as the CP cap is not exceeded. If the cap is full, the gestating ship waits in queue until a slot opens (the player must decommission something or the cap must rise).

Growing the fleet: new ships that were never in the fleet (expanding beyond the starting roster) are acquired at Spawning Fields (replacing shipyard nodes). A Spawning Field offers 2-3 hulls for purchase with credits at the standard Chorus price ladder (cheap smalls, expensive capitals). Once bought, the new hull enters the Gestation Queue and takes its CP-cost in jumps to mature. You cannot buy a ship and deploy it instantly.

Marks / Evolution: at a Spawning Field, the player may also pay credits to "seed" an Evolution upgrade on a living ship. The upgrade takes 2 jumps to grow. During those 2 jumps the ship is at -10% hull (the flesh is soft while it restructures). After 2 jumps, the Evolution tier applies. This creates a vulnerability window.

Drydock nodes become Catalyst Pools: all Gestation timers halve (a ship 3 jumps from spawning is now 1.5, rounds to 2), and every ship instantly heals 15% of missing hull. Field-repair nodes unchanged.

Reference games and lessons

StarCraft - Zerg larvae and build timers. Zerg production is queue-based: you inject larvae, then units emerge over time. You can't instantly replace a lost mutalisk. Lesson: time-delayed replacement creates strategic foresight. The Chorus player who loses two spitters in sector 1 must plan for them to return by sector 2, and fights in between are genuinely weaker. This is the Zerg feeling of "I'm behind on production."
Stellaris - organic ship build times. Ships take months to grow in a spawning pool. Lesson: production time is a real cost even when the resource cost is low. The Chorus gets cheap hulls but slow ones.
Darkest Dungeon - recovery between expeditions. Heroes heal over time in town, not instantly. You choose whether to wait or push on understrength. Lesson: the decision to wait (take more jumps, heal more) vs. push on (arrive at the boss sooner but weaker) is a strong roguelite lever. In a jump-based map, "waiting" means taking a longer route with more nodes.

Player decisions

Route planning: do I take the longer path (more jumps, more healing, more gestation time) or the shorter path (less healing, but I hit the Spawning Field sooner)? The map's branching paths become healing decisions.
Gestation queue management: I lost a brood-sac. It takes 5 jumps to regrow. Do I decommission a drone to make CP room, or wait? The queue is visible, so the player plans around it.
Evolution vulnerability: seeding an Evolution means 2 jumps at -10% hull. Do I time it during a safe stretch of easy nodes, or risk it before a tough fight?
Buy now, deploy later: purchasing a razor at a Spawning Field means 3 jumps before it fights. The player must anticipate need.

Failure modes

Passive snowball avoidance, but also passive boredom: if healing is free and automatic, the player may feel there's no resource management. Mitigation: the 8% is slow enough that heavy damage from a bad fight still hurts for 3-4 nodes. Gestation timers for lost ships are long enough to matter.
Death spiral is soft: lost ships come back for free, so the floor is high. The risk is that the Chorus feels unkillable over a long run. Mitigation: Gestation timers scale with CP cost, so losing a brood-sac is a 5-jump hole. The Ninefold Maw, if lost (boss only, so probably not applicable mid-run), would be catastrophic.
Map node devaluation: if healing is passive, Feeding Grounds / shipyards feel unnecessary. Spawning Fields still matter for new hulls and Evolution, but the "repair" function is gone. Drydock equivalents (Catalyst Pools) still matter for burst healing and timer reduction.
Boss fight: the boss is preceded by a fixed number of jumps. If the fleet is badly damaged two nodes before the boss, 8% per jump is not enough to recover. This is intentional and creates tension, but it must be tuned so the boss isn't a wall.
Other factions: Corsairs heal instantly at shipyards. The Chorus heals slowly but for free. Over a long run the Chorus may actually be more efficient (no credit cost for healing), but in a short, brutal run the Corsair can top off and push. The asymmetry is real but should feel like a trade, not a punishment.
CP cap interaction: gestating ships don't count toward CP until they deploy, but they occupy a "pending" slot. If the player buys three new hulls at a Spawning Field, three gestation timers run simultaneously, and the fleet will balloon. The CP cap must be enforced at deployment, not at purchase.

Shipyard job coverage

Shipyard function | Covered? | How
Heal damage | Yes | 8% per jump, Catalyst Pools
Replace losses | Yes | Gestation Queue, free, time-cost
Grow fleet | Yes | Spawning Fields (credits) + Gestation timer
Mark upgrade | Yes | Seed Evolution at Spawning Field, 2-jump grow, vulnerability window

Nothing dropped. The cost of everything is time and route planning rather than credits-at-a-node.

Build size

Medium-Large. Needs a per-junk heal tick, a Gestation Queue UI with timers, Spawning Field node type, Evolution seeding with a delay and temporary debuff, and Catalyst Pool node logic. The Gestation Queue is new UI. No battle-layer changes, but the campaign map must track jump counts and fire Gestation completions. The faction hook must redirect Chorus runs away from shipyards.

Approach 4 - Devour the Void (Consume Map Objects)

How it works

The Chorus does not visit shipyards. It eats the map. Certain map objects - wreck fields, derelict stations, asteroid clusters, dead Leviathan husks, even some event nodes - are flagged as edible. When the Chorus fleet enters a node containing an edible object, the player may choose to Devour it.

Devouring is a one-time action per object. It yields a benefit based on the object type:
Wreck field: heal 25% of missing hull fleet-wide. (Equivalent to a field-repair node but tied to a specific object.)
Derelict station: heal 40% fleet-wide AND gain 15 credits. (The station has salvageable tech the swarm converts.)
Dead Leviathan / large husk: heal full for one ship (player picks which) AND spawn one drone-spawn for free.
Asteroid cluster: gain 20 credits (mineral consumption).
Spawning Field (existing event node): unchanged - 30% heal, sets fed flag.

Edible objects are scattered by the sector generator at roughly the same frequency as shipyard + drydock + field-repair nodes combined. The Chorus player's map is dotted with food. Other factions see the same objects but interact with them differently (salvage for credits, scan for XP, etc.), so the objects are not Chorus-exclusive - the Chorus just gets a unique Devour option.

Replacing losses and growing the fleet: the Chorus cannot buy hulls at any node. Instead, certain large edible objects (Leviathan husks, ancient bio-ships) yield a spawn token when devoured. The player can bank up to 3 spawn tokens. At any point on the map (not just at a node), the player may spend a token to instantly grow a ship, chosen from 2 options rolled at the time of spending. CP cap enforced. This means fleet growth is tied to finding and eating the right things, not to credits.

Marks / Evolution: devouring a Derelict Station or a Leviathan husk also yields an Evolution catalyst (a small item, like a refit). The player can apply a catalyst to a ship to push it one Evolution tier. Catalysts are rare (maybe 2-3 per run from specific objects), so Evolution is precious.

Credits: the Chorus still earns credits from battles and some edible objects. Credits are spent on refits (modules) at event nodes and on the occasional captured-hull prize that a non-shipyard merchant event offers. Credits are not the primary sustainment currency; they are the secondary one for modules and situational purchases.

Reference games and lessons

Endless Space 2 - Cravers. The Cravers literally eat populations and deplete systems. They must keep moving because each system runs out of food. Lesson: making the map itself the resource creates a powerful exploration incentive. The Chorus player wants to deviate from the shortest path to find a Leviathan husk. This makes the map feel alive and the Chorus feel hungry.
Stellaris - Devouring Swarm. You eat planets. The galaxy is your larder. Lesson: the fantasy of consuming everything is potent. Letting the Chorus eat a derelict station and get a free drone out of it is a strong identity moment.
FTL - store nodes and scrap. You can only buy things at stores. Between stores, you accumulate scrap and hope. Lesson: making growth objects (spawn tokens) found rather than bought creates a different pacing. The player doesn't choose when to buy a new ship; they choose when to spend the token they found.
Slay the Spire - map branching. The player chooses paths partly to hit rest sites or shops. Lesson: if edible objects are visible on the map before you commit to a path, the player routes toward food. This is good: it makes the Chorus play the map differently from other factions.

Player decisions

Route for food: do I take the longer path through the wreck field and the asteroid cluster, or the shorter path with a tough combat node? The Chorus player is always asking "where's the next meal?"
Which ship to full-heal from a Leviathan? The brood-sac at 30% hull, or the razor at 50%?
Bank tokens or spend them? Three tokens in the bank means flexibility. Spending one now means a bigger fleet for the next fight but one fewer option later.
Evolution catalyst allocation: only 2-3 per run. Do I evolve the razor for damage or the brood-sac for hull?
Devour or interact normally? At a derelict station, the Chorus can Devour (heal + credits) or use the normal event interaction (which might give a refit or XP). The Devour option is always available but might not always be optimal.

Failure modes

Snowball: a lucky run with many Leviathan husks and spawn tokens could produce an oversized, fully-healed fleet. Mitigation: cap spawn tokens at 3, make Leviathans rare (1-2 per run), and keep CP cap hard.
Death spiral is mild: if the player misses edible objects (takes a different path), they don't heal. But the objects are frequent enough that a reasonable route always hits some. The floor is: you can always fight, you just might be at 70% hull.
Dead map nodes for other factions: the edible objects must be interesting for non-Chorus factions too (salvage, scan, etc.), or they become Chorus-exclusive clutter. This is a content cost.
Boss fight: the boss node is probably not edible. The player must arrive with enough hull from the preceding nodes. If the last two nodes before the boss are combat nodes with no edible objects, the fleet arrives as-is. This is fine but must be tuned.
Credit distortion: if the Chorus gets most of its sustainment from eating and credits are secondary, credits feel less meaningful. Mitigation: refits and modules still cost credits, and some event choices require credits. The Chorus just doesn't spend credits on repair or hulls.
Other factions' relative value: Corsairs and Ithar get predictable, on-demand healing at shipyards. The Chorus gets situational healing from map objects. The Chorus player may feel at the mercy of the map generator. Mitigation: ensure the generator places edible objects reliably (at least 2 per sector).

Shipyard job coverage

Shipyard function | Covered? | How
Heal damage | Yes | Devour edible objects
Replace losses | Partially | Spawn tokens from large objects; no on-demand purchase
Grow fleet | Yes | Spawn tokens, CP cap enforced
Mark upgrade | Yes, but scarce | Evolution catalysts from rare objects

Dropped: on-demand healing at a shop (you can't choose to heal whenever you want; you heal when you find food). On-demand hull purchase is replaced by token-based spawning. The cost of this drop is player agency: the Chorus player has less control over when and how they heal, which is thematic (the swarm eats what it finds) but may frustrate.

Build size

Large. Needs edible-object tagging on multiple existing node types, a Devour action with per-object-type outcomes, a spawn-token inventory and spend UI, Evolution catalyst items, sector-generator changes to place edible objects at the right frequency, and non-Chorus interaction options for the same objects so they aren't dead content for other factions. No battle-layer changes, but the campaign map work is substantial.

Approach 5 - The Tithe of Wrecks (Kill-Feed Healing, Between-Battle Layer)

How it works

This is the between-battle counterpart of the "feed mechanic" sketched in the asymmetry decision page. The core idea: the Chorus heals by killing, and the healing carries over between battles as a stored resource.

After every battle, the Chorus fleet collects a Harvest proportional to what it killed. Specifically: for every enemy ship destroyed in the battle, the fleet gains a Harvest point. For every enemy ship destroyed by a Chorus ship's regrow-triggered attack (i.e., the Chorus ship was healing and still fighting), bonus Harvest. Harvest is a small integer (a 3-ship enemy fleet yields 3 points; a 6-ship fleet yields 6).

Harvest is spent at any node (not just special nodes) via a "Feed the Swarm" button:
1 Harvest: heal one ship for 15% of its missing hull.
3 Harvest: heal the whole fleet for 10% of missing hull.
5 Harvest: spawn a drone-spawn (cp 1) for free. CP cap enforced.
8 Harvest: spawn a spitter (cp 2) for free. CP cap enforced.
12 Harvest: evolve one ship by one tier.

Harvest does not persist between sectors (it resets at the sector boundary), preventing hoarding. Within a sector, it accumulates across battles.

Shipyard nodes for the Chorus become Resting Grounds: the fleet heals 20% for free (the swarm rests and knits flesh), and the player may spend credits to buy refits (modules). No hull purchase, no Evolution, no repair beyond the free 20%.

Drydock nodes become Deep Rest: full heal, no cost, as today.
Field-repair nodes unchanged.

Replacing losses: only through Harvest spending (5 or 8 points for a drone or spitter) or through the existing Spawning Field event. Larger hulls (cruiser, carrier) cannot be spawned via Harvest; they must be found at a Spawning Field event or received as a rare event reward. This keeps capitals special.

Marks / Evolution: only via Harvest (12 points) or rare events. No credit purchase.

Reference games and lessons

Slay the Spire - combat as resource generation. You earn gold and card rewards from fights. The more you fight, the richer you get. Lesson: tying healing currency to combat performance means the player is rewarded for engaging, not avoiding fights. The Chorus should want to fight.
Risk of Rain 2 - difficulty scales with time, but kills give items. The longer you fight, the more you accumulate. Lesson: a kill-counter resource that resets per sector creates a "use it or lose it" pressure within each sector, preventing infinite hoarding.
The avenge relic (already in the game). When a Chorus ship dies, others heal 15%. Lesson: the fantasy of "death and killing feeds the swarm" is already in the game's DNA. The Tithe of Wrecks extends that fantasy to the campaign layer: your kills between battles feed the next battle.
Zerg - creep and regeneration. Zerg units heal on creep. The creep is generated by the Zerg themselves. Lesson: the healing source should feel like it comes from the faction's own actions, not from an external shop. The Chorus heals because it killed.

Player decisions

Spend Harvest now or save for a bigger spawn? After a fight that yielded 4 Harvest, do you heal one ship (1) and bank 3, or save all 4 toward a fleet-wide heal (3) or a drone (5, need one more)?
Which ship to heal? With no shields, every hull point matters. Healing the brood-sac's 40 missing hull is different from healing a drone's 10.
Engage or avoid? If the next node is a tough fight that you might lose ships in, do you skip it to preserve the fleet, knowing you'll miss the Harvest? The Chorus is incentivised to fight everything, which is on-fantasy but risky.
Sector boundary pressure: Harvest resets at the sector end. If you're sitting on 11 Harvest at the last node before the boss, you spend or lose it. This creates a natural "spend down" moment.

Failure modes

Snowball: win every fight → lots of Harvest → full heal + free spawns → win the next fight easily. Mitigation: Harvest resets per sector, and the CP cap limits fleet size. The boss fight is a fixed encounter where you can't farm Harvest before it.
Death spiral: lose a fight badly → fewer kills → less Harvest → can't heal → lose worse. Mitigation: Resting Grounds give free 20% heal, Deep Rest gives full heal, and the Spawning Field event is unchanged. The floor exists.
Avoiding fights becomes suboptimal: if the best strategy is to fight every node for Harvest, the player never skips a combat node. This reduces map agency. Mitigation: some combat nodes are genuinely too hard, and the player must weigh Harvest gain against ship losses. Losing a ship costs more than the Harvest gained from the kill.
Boss fight: no Harvest generation during the boss (it's one fight). The player arrives with whatever they saved. This is fine.
Other factions: Corsairs and Ithar heal with credits at shipyards, which is reliable and on-demand. The Chorus heals by fighting, which is variable. In a bad run with few fights, the Chorus starves. In a good run, it thrives. The variance is higher for the Chorus. This is thematic but must be tuned so the floor isn't too low.
Capital ship replacement: the Chorus cannot replace a lost cruiser or carrier via Harvest. If the brood-sac dies, it's gone unless a Spawning Field event appears. This is a real loss and may feel bad. Mitigation: make the brood-sac's loss rare (it's a cp-5 ship, usually protected), and ensure at least one Spawning Field per sector.

Shipyard job coverage

Shipyard function | Covered? | How
Heal damage | Yes | Harvest spending, Resting Grounds, Deep Rest
Replace losses | Partially | Harvest spawns drones/spitters only; capitals via events
Grow fleet | Yes | Harvest spawns, CP cap enforced
Mark upgrade | Yes, but rare | 12 Harvest for one Evolution tier

Dropped: on-demand capital ship replacement. If you lose a brood-sac, you can't just buy another at a shop. You need a Spawning Field event or a specific reward. The cost is fleet composition rigidity: the Chorus player who loses a carrier must adapt to a carrier-less fleet or wait for an event. This is thematic (the swarm can regrow drones but a brood-sac is a rare organ) but may frustrate.

Build size

Medium. Needs a Harvest counter per sector, a "Feed the Swarm" UI accessible at any node, a Harvest-to-effect resolution system, Resting Ground and Deep Rest node types, and a sector-boundary reset. The faction hook routes Chorus away from shipyards. No battle-layer changes, but the post-battle reward screen must tally kills and award Harvest. The existing avenge relic and Spawning Field event are untouched.

Coverage Check Across the Four Required Axes

Axis | Approach 1 | Approach 2 | Approach 3 | Approach 4 | Approach 5
(a) Replacement map stop / node | Feeding Grounds | Molt Sites | Spawning Fields + Catalyst Pools | Edible objects | Resting Grounds + Deep Rest
(b) Second resource / credit change | Biomass replaces credits for sustainment | Credits for spawning only; heal/evolve free | Credits for purchase; healing free | Credits secondary; spawn tokens primary | Harvest replaces credits for sustainment
(c) Healing earned through play | Kills → biomass → heal | No (heal is a node choice) | No (heal is passive per jump) | Devour objects found on map | Kills → Harvest → heal
(d) Growth over time / jumps | No | 5% per jump passive | 8% per jump + Gestation timers | No | Harvest resets per sector (time pressure)

All four axes are covered across the set. Approach 2 and 3 lean on (d); 1 and 5 lean on (b) and (c); 4 leans on (a) and (c).

Ranked Top Pick and Biggest Risk

Top pick: Approach 1 - The Long Feast

It covers the full shipyard job without dropping anything. The biomass economy is legible (kill → earn → spend), it maps cleanly onto the existing credit infrastructure with a faction hook, and it gives the Chorus a resource no other faction uses, which is the asymmetry the council agreed on. The price ladder (cheap smalls, expensive capitals) is already synthesised and drops straight in. The Gorge power and Spawning Field event slot into this framework without modification. Build size is medium, the failure modes are well-understood and mitigable, and the player's moment-to-moment decisions (spend biomass now vs. bank, evolve vs. spawn, heal which ship) are rich.

Approach 5 (Tithe of Wrecks) is my second pick because it is the most on-fantasy ("the swarm eats what it kills") and the most mechanically novel, but its capital-ship replacement gap and its dependence on fight frequency make it harder to balance in a roguelite where the player might need to skip combats. Approach 3 (Gestation Tide) is elegant but the large build size and the risk of passive-play boredom push it to third.

Single biggest risk across all approaches

The death spiral in a bad run. Every approach above has some free-healing floor (Deep Molt, Deep Rest, Drift-Kill, Spawning Field event), but the Chorus has zero shields. A bad fight that drops three ships to 20% hull means the swarm is one more bad fight from a cascade. In a shipyard economy, the player can dump all their credits into an instant full repair and reset. In every approach above, healing is slower, conditional, or resource-gated. If the free-healing floor is too low, a Chorus run that hits one bad sector becomes unrecoverable, and the player feels punished for the faction's identity rather than challenged by it. The tuning of those free floors - Deep Rest frequency, passive regrow percentage, Spawning Field placement - is the single most important number in all five proposals, and getting it wrong breaks the faction regardless of which approach is chosen.

---
