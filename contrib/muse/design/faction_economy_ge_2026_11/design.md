# Glasswrights and Eclipse without shipyards: how each fleet heals and grows

Corrections (Nov 18, 2026): the drydock floor now reads as a free repair of 60 percent of missing hull, not a full repair (only the paid shipyard repair restores all missing hull), and Glasswright armour now reads as almost no armour with the per ship values from data.js; no proposal in this doc relied on a full free repair as today's floor, and the legs keep their original wording.

Issue 1063. Type: brainstorm and recommendation (proposals only, no code, no rule changes). Chair: Rey. Legs: blind Rey (written first), DeepSeek, Qwen, Flash. Grok seat empty: grok.com returned "Your request was blocked" on the probe; recorded, not substituted. Evidence: data.js and campaign code on main, docs/playbooks/factions.md, contrib/muse/reviews/asymmetry_decision.md, contrib/muse/reviews/price_ladder_synthesis.md, and the Chorus answer at contrib/muse/design/chorus_economy_2026_11/design.md. Ryan's income correction governs throughout: income pays flat per win by sector and fight kind, half on a partial win, only a small extra tied to how the fight went. Each economy below is a flavour of that reliable loop, not a win-more trap, and the free floors (a drydock-equivalent free repair of 60 percent of missing hull, a field-equivalent 20 percent patch) stay in faction dress.

## The two problems are opposites

A Glasswright ship is a work of art: 30 to 140 hull behind shields of 12 to 28 that regen 6 to 10 a turn, almost no armour (none on the sliver and lancet, .05 on the prism and aperture, .2 on the flagship), no Brace, blink for survival. In battle the shield is the real health bar and it refills itself; what the campaign must answer is a cracked hull and a shattered ship, in a fleet where every hull is the dearest of its class. An Eclipse ship is a backed-up mind in a machine body: no shields at all, armour .2 to .35, hull regen 2 to 8, reanimate already on the line hulls, an Archive restore the dock action can strengthen, and a dormant-hull yard event already in the game. What the campaign must answer there is a mind whose body is gone. Glasswright asks how art is mended and remade; Eclipse asks how the backed-up dead come back, and at what fidelity.

## Glasswrights

The council converged hard. All four seats put kilns at the centre, all four recover the fleet's own shattered glass as material, and all four replace the shelf with commissions that take jumps. The approaches below consolidate the legs.

### G-A. Annealing Halls, with damage tiers (the centre)

How it works: shipyard nodes become Annealing Halls. Repair is re-blowing, priced in credits on the flat income, and sorted by damage (Qwen's tiers): hairline damage anneals cheaply anywhere, and free at a hall (the faction's floor); deep cracks need the hall and cost full price; a shattered ship (very low hull) cannot be annealed at all and goes to regrowth (G-B) or replacement (G-C). Rey's blind leg adds the kiln's time cost: a re-blown ship cools for a jump and misses the next fight if the fleet jumps straight into one, so repair is also a routing decision. Marks become Refocusing, optics ground finer per tier, fitted at a hall; DeepSeek's lens grafting adds the rest-site tension (one graft per visit, so a stop is repair or growth, not both free).

Other games: Darkest Dungeon's treatment buildings (healing costs absence, not just gold), Slay the Spire rest sites (heal or upgrade), FTL store repairs (availability is the pressure).

What the player decides: triage after every fight (which cracks are hairline, which ship earns the kiln); fight the next node a ship down or route quiet; graft a lens or anneal the hull this stop.

What it breaks: the cooling absence is a tax, not a choice, if the map offers no quiet path; the same map dependency the Chorus gestation approach carried. Tier thresholds need honest UI or triage feels arbitrary.

Build size: medium. Node variant reusing the shipyard screen, tier logic on hull percentage, a per-ship cooling flag on the jump tick.

### G-B. Cullet: your own wrecks are the material

How it works: glass is the one ship material in the game that is literally recyclable, and the lore already breaks these ships into whole panes. When a Glasswright ship is destroyed and the fleet holds the field, it recovers cullet, a capped fraction of the ship's value (DeepSeek: fixed by class, capped per battle, never scaled by kills). At a hall, cullet discounts re-blowing and commissions; spent on regrowth, it rebuilds the lost ship imperfectly (Qwen: back at Mark 0 with a visible seam and a small hull penalty, so regrowth is a recovery path, never an upgrade path). A ship lost in a rout leaves its cullet on a field the fleet no longer holds.

Other games: Homeworld's collectors harvesting wrecks, Kerbal's recovered parts coming back degraded, XCOM's salvage making even a loss leave something in your lap.

What the player decides: recover or push on after a loss; spend cullet on the cracked cruiser's anneal or bank it toward the replacement; accept an imperfect regrown destroyer now or fight a ship short.

What it breaks: refunds on losses soften the elite faction's core tension (every ship precious), so the fraction must stay small and the imperfection real. If cullet ever earns from kills it becomes the Chorus variance problem in a second costume; it only ever comes from glass, mostly your own.

Build size: small to medium. A wreck-yield line in the battle result, one stock number, price hooks at the hall, a permanent scar flag per regrown ship.

### G-C. Commissions: new ships are blown, not bought

How it works: no shelf. At a hall the player commissions a hull, pays up front on the price ladder's shape, and the ship is blown over the next one to two jumps (class-scaled), arriving finished at base Mark. DeepSeek's Pattern Garden version lets a drydock-equivalent accelerate one commission for extra credits, capped. The commission survives a lost battle (Qwen), so a rebuilding fleet has something coming.

Other games: Stellaris and Homeworld build queues (a purchase becomes a plan), XCOM build times, BattleTech contract manufacturing.

What the player decides: commission the cheap sliver that arrives soon or the prism that arrives late; start the clock before a hard sector or bank the credits; pay to accelerate or accept the gap.

What it breaks: a fleet that just lost two ships is short for jumps, not minutes; without the free floors and cullet regrowth beside it, commissions alone would strand losers. One commission at a time (the legs suggest a bench limit) is what keeps the few-and-precious identity intact.

Build size: medium. A commission queue on the jump tick, a countdown in the fleet screen, node placement guarantees for halls.

### G-D. The flaw: quick anneals are cheaper and worse (blind Rey only)

How it works: each re-blow is offered two ways. Slow anneal: full price, kiln time, the ship returns perfect. Quick anneal: cheaper, no time, and the ship carries a flaw until its next slow anneal, a visible crack priced as a small shield or aim penalty shown in the fleet screen. Flaws do not stack; a second quick anneal deepens the flaw deterministically rather than rolling a failure chance.

Other games: Battle Brothers' injuries, Darkest Dungeon's treatment tiers, Wildermyth's scars.

What the player decides: tempo versus perfection, per ship, every hall visit. The flagship gets slow anneals; the sliver screen gets quick ones.

What it breaks: almost nothing structurally, which is its virtue; the risk is feel (a flaw on the flagship before a boss must read as the player's own earlier choice, which the deterministic version ensures).

Build size: small. One flag per ship, two price rows, a fleet-screen marker. The cheapest identity texture in this whole document.

### G-E. Stored light as a component (Flash and Qwen; optional layer)

How it works: a small light stock, earned as a flat per-jump trickle plus the win payment, spent as a component cost on deep-crack anneals (Qwen's single-sink version) and optionally on reservoir overcharge before a hard node (DeepSeek, Flash's Luminance in fuller form). Rey's and DeepSeek's caution stands: this is the only proposed second resource for the faction, and it earns its place only if the single sink feels thin without it.

Build size: small to medium as scoped here; large in Flash's full three-sink form, which the chair does not recommend.

### Recommended direction, Glasswrights

G-A as the spine, G-B as its supply line, G-C for growth, G-D as the texture. Together: you mend art in kilns, remake it from its own shards at a visible discount in quality, commission replacements on a clock, and always know which of your ships is flawed. No standing second currency; light (G-E) only if playtests say the kiln needs a second dial.

## Eclipse

Convergence again: all four seats built the economy on the Archive, all four made the fleet's own dead its supply line, and three of four grew the fleet by waking dormant hulls rather than buying off a shelf.

### E-A. The Archive: backup slots and restore fidelity (the centre)

How it works: the existing "Back up the fleet" dock action becomes a standing system. The fleet holds a limited number of Archive slots (bought with credits at Archive nodes, the faction shipyard analogue; scarcity is the design). A destroyed ship that held a slot returns at the next Archive node, rebuilt on a standard hull of its class: the mind (name, and per the fidelity price, its Marks) survives; fitted refits are physical and are lost with the wreck. Fidelity is the price dial the legs split on: DeepSeek restores at the same Mark, or one lower if restored cheaply; Qwen prices it as depth (Shallow restore: cheap, back at Mark 0 and partial hull; Deep: dear, back whole). The chair's read: slots answer who is backed up, fidelity answers how well, and both decisions are the same screen. One separation line, stated in every leg: in-battle reanimate is untouched and temporary in effect; the Archive is between battles and permanent. A ship that reanimated does not also consume a restore.

Other games: EVE's clones and implants (the copy is cheap, the fitted body is the loss), FTL's clone bay (returns with a tax), XCOM's gear outliving the soldier.

What the player decides: who gets a slot, the screen that expects to die or the lance that must not; fidelity per restore; slots versus hulls on the same credits.

What it breaks: if slots are cheap, death stops mattering and the dread inverts; the faction becomes the forgiving one. Slot scarcity and refit loss are the sting, and the fleet screen must show both before the battle, not after.

Build size: medium. A slot count, a restore step at Archive nodes, slot and fidelity UI. Reuses the Archive restore's fiction and the dormant yard's hulls as rebuild bodies.

### E-B. Core recovery: hold the field or lose your dead

How it works: a destroyed Eclipse ship leaves its core (the trapped light, the mind's physical seat) on the field. Win and your dead's cores come home; rout or lose and they stay. A recovered core restores an un-slotted ship at an Archive node for a rebuild price in credits, or is banked as a spare mind for growth (E-C). DeepSeek caps it at one core recovery per battle with later ones dear or unavailable, which keeps a massacre from refunding itself. Enemy machine cores from events feed the same stock at a worse rate.

Other games: Mordheim and Necromunda post-battle recovery (who you can drag off the field lives), Homeworld salvage, Total War casualty recovery.

What the player decides: the end-of-battle calculus changes; a winnable ugly fight is worth finishing for the cores, and a rout costs more than hulls. Spend a core on the destroyer now or bank it toward waking a cruiser.

What it breaks: it pays winners, which Ryan's correction warns against; cores must stay a recovery mechanism under the flat income, never income themselves. The reanimate interaction needs its one line (a reanimated ship's core is spent; no core drops).

Build size: small to medium. A core count in the battle result (win versus rout is already known), a spend screen shared with E-A.

### E-C. Dormant yards: growth is waking, not buying

How it works: the tombhome event (a dormant Eclipse yard, hulls stored without minds, "a copy from the Archive would wake one") becomes infrastructure: yard nodes at a guaranteed density where the fleet wakes a dormant hull with a banked core or an Archive copy (Qwen makes copies a flat win-earned stock; DeepSeek keeps it a credits-and-backup transaction). The woken hull starts blank at low Mark. This replaces the shelf for Eclipse growth: the fleet grows by finding sleeping bodies in the dark.

Other games: Homeworld derelicts, Stellaris precursor hulks, BattleTech lostech caches.

What the player decides: wake the frigate now or hold the copy for a better yard; detour to a yard or push the sector; which class to wake when the yard offers a choice.

What it breaks: event-driven growth is swingy; yards must be a bonus path beside E-A's restore, never the only way back from a loss, and placement must be guaranteed or a sector can starve growth entirely.

Build size: medium. The existing event generalised into a node, placement rules, a wake interaction shared with E-A/E-B.

### E-D. Plate reclamation: repair in the faction's own shape

How it works, in its shippable form (DeepSeek): a flat reclamation pool paid like income (per win by sector and fight kind, half on partial, small performance extra) is spent at nodes replacing peeled shade plates and repairing hull, cheaper than replacement. Flash's version strips plates from ripped captured hulls as patch material, giving the code's ripped flag a mechanical payoff at a capped, bad rate. Qwen's full layer model (hull as a stack of plate layers, regen conditional on layers rebuilt) is the most flavourful idea in the Eclipse legs and the most invasive thing in this document: it changes the hull model itself. The chair records it as the ceiling for a later pass, not a candidate for the first build.

Other games: BattleTech per-location armour repair, Armored Core part swapping, Darkest Dungeon's good-enough patching.

What the player decides: spread plate repair across the fleet or concentrate it; strip a ripped capture for plates or sell it for credits; good enough versus full strength, per ship.

What it breaks: in the flat-pool form, little; priced wrong, cheap plate repair erases attrition for an armour faction. In the layer form, everything downstream of the hull number (battle regen, UI, saves) is touched, which is why it waits.

Build size: small to medium (flat pool and stripping); large (layer model).

### E-E. Drone allocation: the machines tend themselves (Qwen; Rey's dormancy is its cousin)

How it works: the fleet carries a drone pool (the Repair drones module and Reclamation swarm doctrine made literal). At any node the player allocates pool units to damaged ships; each unit repairs a fixed amount per jump while the fleet travels. Free and guaranteed, but slow and capped by the pool; credits at nodes remain the fast lane. Rey's dormancy variant (a ship sleeps two jumps to mend fully, unavailable if a fight interrupts) is the same patience priced in availability instead of allocation.

Other games: FTL repair drones, Rimworld work queues, Stellaris construction ships.

What the player decides: concentrate the pool on the cruiser or spread it thin; let the drones work or pay for instant repair; route length as medicine.

What it breaks: free healing can bore if it is fast and strand if it is slow; per-jump anything is farmable if the map allows free backtracking, the standing caveat for every time-based system in this document.

Build size: medium. Pool resource, allocation UI, a per-jump repair tick.

### Recommended direction, Eclipse

E-A as the spine, E-B as its supply line, E-C for growth, E-D in its flat-pool form for repair. The Archive turns fiction the game already has (reanimate, the restore, the backup dock action, the dormant yard) into one campaign system with one scarce thing, backed-up minds, and one recurring decision: who is backed up, at what fidelity, and what did we leave on the field. The layer model (E-D full form) and drone allocation (E-E) are the recorded next layer, in that order.

## Shared risks, stated once

1. Variance is still the enemy, in both directions. Every salvage, cullet, core and plate flow above is capped, floored, and sourced from the fleet's own losses or the flat win payment, never scaled by kills. If a prototype's run outcomes spread wider than the credit loop's, the faction token is paying too much, whatever its name.
2. Death must keep a price. Glasswright pays it in time, quality and imperfection; Eclipse pays it in slots, fidelity and lost refits. If either faction's recovery reads as free, the roguelite tension is gone and no flavour saves it.
3. Time-based systems (kiln cooling, commissions, drone repair, dormancy) all stand or fall on the map's movement being a real constraint. That was true for the Chorus gestation approach and it is the single biggest shared dependency in this document.
4. One token per faction at most. Glasswright's candidate token (cullet) comes only from glass; Eclipse's (cores) only from its own dead. The moment either faction tracks two standing resources, the economy stops being legible.
5. Judge prototypes on run-outcome distributions, not means, as with Chorus: completion rate, hull state at the boss, and recovery time after a lost battle, per faction, against the credit loop as control.
