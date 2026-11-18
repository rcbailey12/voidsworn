# Chorus without shipyards: how a living fleet sustains itself between battles

Issue 1047. Type: brainstorm and recommendation (proposals only, no code, no rule changes). Chair: Rey. Legs: blind Rey (written first), DeepSeek, Qwen, Flash. Grok seat empty: grok.com returned "Your request was blocked" on the probe and on a fresh route; recorded, not substituted. Evidence: data.js and campaign code on main, contrib/muse/reviews/asymmetry_decision.md, contrib/muse/reviews/price_ladder_synthesis.md, docs/playbooks/factions.md.

## The problem in one paragraph

Every faction currently heals, replaces and grows its fleet the same way: credits at shipyard nodes, 1 credit per 2 hull repaired, hulls and Marks bought off a shelf. The Chorus is grown, not built: engineered flesh that lives on starlight, eats anything and breeds without end, with no shields at all, so hull sustainment is its whole defence economy. A record correction before anything else: the old "no shipyard repair" item (KIT-1) was never Ryan's ruling; it came from summaries. This page treats yard-free Chorus sustainment as an open design direction to explore, not a settled prohibition looking for a patch.

What already exists to build on: in-battle regen on every Chorus hull (3 to 20 per turn, no shields), the Gorge admiral power (eat a refit, fleet regrows 20%, 30% if fed), the spawning field event (Chorus-only feed option, healAll 30%), and the martyr relic (a death heals the rest). The prior council consensus (asymmetry decision page) named Chorus "the swarm that eats" and recommended a feed mechanic whose decision was left open. This job is that idea's between-battles form: the whole campaign loop, not one mechanic.

## Where the council landed

Four of five seats independently built the same centre: a biomass resource earned mainly by killing and wreck salvage, spent at a Chorus replacement stop for healing, growth and Marks, with credits demoted to a secondary role. All five seats named the same biggest risk, in nearly the same words: variance. An eat-to-heal economy makes winning fleets healthier and losing fleets hungrier, so the floors and caps are not tuning details, they are the design. The approaches below are the distinct loops the council produced, consolidated where legs overlapped.

## Approach A: Biomass at Feeding Grounds (the consensus centre)

How it works: Chorus runs earn biomass from kills, wrecks, events and dissolved ships. Shipyard nodes become Feeding Grounds where biomass buys the whole shipyard job: regrow hull (priced per missing hull), grow new hulls from a stock of 2 to 3 (the existing price ladder shape drops in: small hulls cheap, capitals dear), and Evolution tiers in place of Marks (same +20% hull, +15% damage, no shield component). Credits survive as the non-hull economy: refits, events, prizes, and a deliberately bad digestion rate into biomass (Qwen's 3 to 1) for emergencies. Drydock and field equivalents stay as free floors (full regrow, free 20%). Rey's blind leg adds a starlight trickle, a small per-jump biomass income justified by the lore line "lives on starlight", as the anti-starvation floor.

Other games: FTL's scrap (one combat-earned currency for repair, purchase and upgrade is legible and makes every battle pay), Stellaris hive minds and Devouring Swarm (food as the growth input), the Zerg (production and repair live in the organism).

What the player decides: heal now or bank for a hull; evolve one ship or spawn two small ones; digest credits at a loss or push on; which ship gets triaged when biomass is short.

What it breaks: the win-more problem in its purest form (see the risk section); credit rewards from non-combat routes need a Chorus conversion story or those routes pay less; captured Cinder hulls have no Chorus answer except eating them, which deletes the prize fantasy for this faction; if biomass is just credits renamed and earned the same way, the asymmetry test fails and this is a reskin.

Build size: medium. One resource, one node variant reusing the shipyard screen's structure, reward-source conversion, the faction economy hook the earlier syntheses already flagged.

## Approach B: The Carrion Allocation (kill-feed, spent after each battle)

How it works: no standing second currency. After each battle the fleet harvests Feed (DeepSeek's Carrion Trail) or Harvest points (Qwen's Tithe of Wrecks) from what it killed, and the player allocates it immediately: heal hull, bank brood stock for replacements, or molt a Mark. Qwen's version resets the pool at sector boundaries (use it or lose it) and caps spawns at frigates and destroyers, with capitals only from spawning field events. Credits stay primary for refits and events.

Other games: the Cravers in Endless Space 2 (aggression pays, eating is capped), Slay the Spire's combat rewards (fights are the income), Risk of Rain 2 (per-stage accumulation pressure).

What the player decides: fight or skip becomes an economic decision, not just a tactical one; allocate to the capital's hull or to two cheap bodies; spend down before the sector gate or lose the pool.

What it breaks: skipping fights, a normal roguelite tool, becomes self-harm; boss sectors have few kills to harvest, so the fleet arrives with what it banked; capital replacement is the weak joint (Qwen drops on-demand capital replacement entirely, which is honest and may still be a step too far); feed hoarding before a boss needs a cap.

Build size: small to medium. Post-battle allocation screen and result hooks; the kill and wreck counts are a battle-layer touch, not a redesign. DeepSeek ranked this first of its four; it is the strongest challenger to A and the natural earning moment inside A if the Board wants one resource with a face.

## Approach C: Molt Sites (one choice per stop)

How it works: Chorus stops offer exactly one of: regrow the fleet (about 40% of missing hull), evolve one ship one tier, or spawn one new hull for credits. Never two. Qwen pairs it with a 5% per-jump passive regrow drip. DeepSeek's field-charge version (feed or spend the charge on a spawn discount) is the same discipline in softer form; Flash's chrysalis node (full heal paid in run time) is its extreme form.

Other games: Slay the Spire rest sites, the canonical heal-or-upgrade fork; Hades rest stops; Into the Breach's scarce between-island repairs.

What the player decides: the fork itself, every stop, plus whether a healthy fleet skips the node entirely.

What it breaks: least new economy of any approach, so it may read as a restriction rather than an identity; players coming from full-service yards may feel punished; it does not by itself give Chorus an economy no other faction shares, which was the asymmetry audits' test.

Build size: small to medium. A three-button node, a faction routing hook, a jump tick. The cheapest complete answer on the table.

## Approach D: Gestation (time is the currency)

How it works: healing and replacement run on jumps, not stops. Ships regrow a percentage of missing hull per jump (Qwen 8%, Rey's version scales by the hull's own regen stat). Lost ships enter a gestation queue and return after a number of jumps equal to their CP cost; new hulls bought at spawning fields also mature over jumps; Evolution is seeded and grows over two jumps with a vulnerability window (Qwen: -10% hull while the flesh is soft). DeepSeek's Brood Cycle adds a per-jump focus choice (heal, spawn or molt) and larvae from brood-sacs.

Other games: Zerg build timers and larvae (production delay is the cost), Stellaris organic build times, Darkest Dungeon's between-expedition recovery (waiting is a decision).

What the player decides: route length becomes the healing decision (long way round mends, short way arrives sooner); queue management around the CP cap; when to seed an Evolution's soft window.

What it breaks: free automatic healing can bore or, tuned slow, strand a fleet before the boss with no purchasable recovery; lost capitals leave multi-jump holes; if the map permits free backtracking, per-jump healing is farmable and the loop collapses, so this approach stands or falls on the map's movement constraints being real.

Build size: medium to large. Jump tick, gestation queue UI, maturation state. No battle-layer changes.

## Approach E: Eat the Map (devour and infest nodes)

How it works: the map itself is the larder. Wreck fields, derelict stations, husks and asteroid clusters are edible objects with per-type payouts (heal, credits, a free drone, spawn tokens, rare Evolution catalysts). Flash's Parasitic Swarm variant: infest a shipyard or drydock to consume it permanently for a full heal plus genetic material. Growth comes from found tokens, not purchases.

Other games: the Cravers eating systems, Devouring Swarm eating planets, Slay the Spire pathing toward the nodes your build needs.

What the player decides: routing for food over routing for safety; bank spawn tokens or spend them; eat the station now at half damage or save it for when things are worse (Flash's version).

What it breaks: the sector generator becomes a balance dependency (a food-poor sector starves the run through no fault of the player); edible objects must also serve other factions or they are Chorus-only clutter, a real content cost; on-demand agency is lowest here, healing happens when the map allows it.

Build size: large. Object tagging across node types, devour actions, token inventory, generator guarantees, non-Chorus interactions for the same objects.

## Also on the table: Metamorphosis (Rey's blind leg only)

Ships are never bought; fed ships pupate up the roster (drone to spitter to bladeback to brood-sac), pupation is the heal, Marks fold into growth stages, new frigates bud from brood-sacs. It is the best long-term fantasy and the only approach needing a new progression system rather than a new economy; the class unlock structure does not map onto it. Recorded as the ceiling, not a candidate for the next step.

## Recommended direction

Adopt Approach A as the spine, with B's post-battle allocation as the moment biomass is earned and counted, and keep C in reserve as the fallback if a second resource proves too much sprawl. Concretely, the direction to prototype:

1. Biomass earned from kills, wrecks and dissolved ships, counted on the post-battle screen (B's allocation moment, A's standing pool, capped).
2. Feeding Grounds replace shipyards for Chorus: heal, grow and evolve there in biomass, at the price ladder's agreed shape (cheap smalls, dear capitals).
3. Credits demoted, not deleted: refits, events and prizes stay credit-priced; digestion converts credits to biomass at a bad rate.
4. Floors stay floors: drydock and field equivalents keep their free heals, and a small starlight trickle per jump guarantees a crippled fleet can always mend a frigate eventually. The floor sizes are the first numbers to tune, before any price.
5. Gorge, the spawning field feed and the martyr relic are untouched; they get stronger by context, which is free value.

Why A over B alone: B is the better fantasy moment and the worse economy (sector resets, capital gap, fight-frequency dependence). A covers the full shipyard job with no drops, which only A and C manage, and A passes the asymmetry test C fails. Four of five seats put A or its components first; the fifth (DeepSeek) put B first and A second and third in its two halves.

## The risk every seat named

Variance amplification. Every approach here feeds winners and starves losers; the Chorus has no shields, so hull is health and health is the economy. Judged on average runs, all five approaches look fine; judged on the distribution, the bad tail is a run decided by one sector-two fight. Any prototype should be measured on run-outcome spread (how often a Chorus run is dead by sector three versus other factions), not on mean performance, and the floor knobs (trickle size, free-heal frequency, heal price against kill income) should be tuned before the flavour is polished.

## Touches and non-goals

In-battle regen, Gorge's numbers, the spawning field event and event healing generally are untouched by every approach above; where an approach reads battle results (kill and wreck counts), that is a reporting touch, not a battle redesign. Captured hulls, the Cinder Line and class unlock pacing need a Chorus ruling under A (eat prizes at a premium rate is the council's lean, not a decision). Nothing here is a ruling; the price ladder's open choices (exact multipliers, the capital gate) stay open and slot into A unchanged.

## Provenance

Legs delivered in full under legs/: leg_blind_rey.md (chair, written before any council leg ran), leg_deepseek.md (DeepThink on, Search off, verified both ends), leg_qwen.md (Qwen3.8-Max, selector verified before submit, header after; the leg's "per-junk" is the model's own typo for per-jump), leg_flash.md (Gemini Flash-Lite picker, signed in, verified before and after). Grok seat empty (bot wall). Dashes in leg files were normalised to plain hyphens in the pushed copies only; local originals are untouched. Chair checked the legs' factual claims against the pack before synthesis; Flash's leg mentions credit sinks (relics, mercenary hires) that the pack does not evidence, treated there as its own suggestion, not game fact.
