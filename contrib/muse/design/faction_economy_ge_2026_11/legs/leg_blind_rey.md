# Blind leg: Rey (written before any other leg was seen)
# Issue 1063: Glasswrights and Eclipse without shipyards.

## Ground I am standing on

The shared frame is settled by the Chorus job and Ryan's correction, and I am not reopening it: income pays flat per win by sector and fight kind, half on a partial win, with only a small extra tied to how the fight went. Each faction's economy is a flavour of that reliable loop, not a win-more trap. Free floors stay (the drydock's free full repair and the field node's free 20 percent need faction equivalents). Credits remain the non-hull economy (refits, events) or convert into the faction resource at a bad rate.

The two factions are opposites in what a ship IS. A Glasswright ship is a work of art: hulls of 30 to 140 HP behind shields of 12 to 28 that regen 6 to 10 a turn, no armour, no Brace, blink for survival. In battle the shield is the real health bar and it already refills itself; what a Glasswright fleet cannot fix by waiting is a cracked hull and a shattered ship. An Eclipse ship is a backed-up mind in a machine body: no shields at all, armour .2 to .35, hull regen 2 to 8, reanimate already on the line hulls, an Archive restore the dock action can strengthen, and a dormant-hull yard event already in the game. What an Eclipse fleet cannot fix by waiting is a mind whose copy is gone.

So the design question splits cleanly. Glasswright: how does art get mended and remade? Eclipse: how does a backed-up fleet lose and recover its dead?

## Glasswrights

### G1. Annealing Halls: repair is re-blowing, and it is all or nothing

How it works: shipyard nodes become Annealing Halls. A damaged glass ship is not patched; it goes back into the kiln and is re-blown whole. Repair restores the ship fully (hull and optics) for credits priced on the damage, like today's repair, but with two glass rules. First, no partial repairs: a pane is either re-blown or it is not, so the per-ship choice is binary where other factions buy hull points by the unit. Second, kiln time: a re-blown ship misses the next jump (it is cooling), so a fleet that re-blows everything arrives at the next fight a ship short unless it routes through a quiet sector. Replacement: new ships are commissioned, not bought off a shelf. You pay at the hall and the ship is blown over the next two jumps, arriving finished; the roster's price ladder shape stays (slivers cheap, the aperture dear), the delay is the flavour. Marks become Refocusing: the same tier bonuses, described as optics ground finer at each tier, fitted during a kiln visit.

Other games: Darkest Dungeon's treatment buildings (healing takes the character out of the next expedition; time and absence are the cost, not just gold). FTL's repair (all-or-nothing per purchase decision at a store) in spirit.

What the player decides: which cracked ships earn kiln time before a hard sector; whether to fight the next node a ship down or route around; commission a replacement now and plan around its arrival, or bank the credits.

What it breaks: the cooling absence interacts with every forced-fight node on the route; if the map offers no quiet path, the rule is a tax, not a choice, so it stands or falls on route choice being real (the same dependency the Chorus gestation approach had). All-or-nothing repair makes small damage feel unfixable between halls, which is intended pressure but will read as unfair if halls are rare.

Build size: medium. Node variant reusing the shipyard screen, a per-ship unavailable flag on the jump tick, a commission queue. No battle changes.

### G2. Cullet: your own shattered ships are the material

How it works: glass is the one ship material in the game that is literally recyclable. When a Glasswright ship is destroyed it leaves a cullet field (the panes shear off whole; the lore already breaks them that way). If the fleet holds the field after the battle, it recovers cullet worth a fraction of the ship's price. Cullet is spent at Annealing Halls: re-blowing a damaged ship costs cullet before credits, and a commissioned replacement blown from a dead ship's cullet is discounted and keeps the dead ship's name and Refocusing tier (the pattern survives in the material). Enemy glass (a destroyed Glasswright opponent, a derelict Starwright site) yields cullet too, at event sites.

Other games: Homeworld's resource collectors harvesting your own wrecks; Into the Breach's grid defence making your losses positional; any crafting game where the high-tier material only comes from the high-tier thing itself.

What the player decides: after a loss, is the cullet worth the recovery stop; re-blow the cracked cruiser or commission the replacement from its dead sister's glass; spend cullet on repairs or hold it for the capital you cannot afford in credits.

What it breaks: losing ships refunding part of their cost softens the elite faction's core tension (every ship precious). The discount must stay a fraction, and a ship lost in a rout or a lost battle leaves its cullet on a field you do not hold, so retreats cost double. If cullet becomes a second full currency with its own income, the economy bloats; it should only ever come from glass.

Build size: small to medium. A wreck-yield line in the battle result, one stock number, price hooks at the hall.

### G3. The flaw: quick anneals are cheaper and worse

How it works: at a hall, each re-blow is offered two ways. A slow anneal costs full price and kiln time (G1) and returns the ship perfect. A quick anneal costs less and no time, but the ship carries a flaw until its next slow anneal: a visible crack in one optic, priced as a small shield-max or aim penalty the player can see in the fleet screen. Flaws do not stack; a second quick anneal on a flawed ship risks the pane (a chance the repair fails and the damage stays).

Other games: Battle Brothers' injuries (fight hurt now or rest), Darkest Dungeon's stress treatment tiers, Wildermyth's maiming (the scar is permanent character).

What the player decides: tempo versus perfection, per ship, every hall visit. The flagship gets the slow anneal; the sliver screen gets quick ones.

What it breaks: a random failure chance on repair will feel bad if it lands on the flagship before a boss; the risk version may need to be deterministic (flaw deepens) rather than rolled. It also adds a per-ship state the UI must carry honestly.

Build size: small. One flag per ship, two price rows, a fleet-screen marker. My favourite small idea in this leg; it gives the faction a texture no other faction has (quality as a resource) at almost no system cost.

### Glasswright recommendation

G1 as the spine, G2 as its supply line, G3 as the texture. Together: you mend art in kilns, you remake it from its own shards, and you always know which of your ships is flawed. The one thing I would not do is give Glasswrights a standing second currency with its own income; their difference is time, wholeness and quality, not a new coin.

## Eclipse

### E1. The Archive: backup slots are the scarce resource

How it works: every Eclipse ship's mind is a copy in the Archive, but the Archive's between-battle reach is limited. The fleet has a number of restoration slots (grows with sector, or bought with credits at Archive nodes, the faction's shipyard analogue). After a battle, a destroyed ship whose mind was slotted returns at the next Archive node, rebuilt on a standard hull of its class at full health, keeping its Marks (the mind remembers) but losing fitted refits to the wreck (they are physical). A destroyed ship with no slot is gone unless its core is reclaimed (E2). The existing dock action "Back up the fleet" becomes literal: it buys or refreshes slots. In-battle reanimate stays exactly as it is; this is what reanimate means at campaign scale, and the design should say so in one line so the two are not confused.

Other games: XCOM 2's memorial wall inverted (the named return); FTL's clone bay (the crew returns, skills taxed); EVE Online's clones and implants (the copy is cheap, the fitted body is the loss); Battletech's salvaged chassis with the pilot surviving.

What the player decides: who gets a slot. Three motes or the zenith? Slot the ship you expect to lose (the screen) or the ship you cannot afford to lose (the lance)? Buy slots or hulls with the same credits?

What it breaks: if slots are cheap, death stops mattering and Eclipse becomes the forgiving faction, which inverts its dread. Slots must be scarce enough that a bad sector still costs hulls. The refit loss on return is the real sting and needs the UI to say it before the battle, not after.

Build size: medium. A slot count, a return step at Archive nodes, a fleet-screen marker for slotted ships. Reuses the Archive restore's existing fiction and the tombhome event's dormant hulls as the rebuild bodies.

### E2. Core reclamation: hold the field or lose your dead

How it works: a destroyed Eclipse ship leaves its core (the trapped light, the mind's physical seat) on the battlefield. Win the battle and the cores of your dead are recovered automatically; rout, retreat or lose, and they stay on the field. A recovered core does two jobs: it restores an un-slotted ship at an Archive node for a rebuild price in credits (the body is the cost, the mind is saved), or it is archived as a spare (a slot, in E1's terms, for a ship not yet built: growth). Enemy Eclipse cores and derelict machine cores from events feed the same stock at a worse rate. This is also where replacement hulls come from between Archive nodes: dormant hulls (the tombhome yard is the tutorial for it) woken with a spare core.

Other games: Homeworld salvage; Necromunda and Mordheim's post-battle sequences (who you can drag off the field decides who lives); Total War's post-battle recovery of your own casualties.

What the player decides: the end-of-battle calculus changes: a losing fight you can still win ugly is worth finishing for the cores; a rout is a strategic disaster beyond the hulls. Spend a core now on the destroyer or bank it toward waking a cruiser from a dormant yard.

What it breaks: it rewards winning, which Ryan's correction warns against; the flat income rule must carry the economy and cores must stay a recovery mechanism, not income. It also double-counts with reanimate if a ship reanimates in battle and then also leaves a core; the rule needs one line (a reanimated ship's core is spent, no core drops).

Build size: small to medium. A core count in the battle result (win versus rout matters, which the result already knows), an Archive-node spend screen shared with E1.

### E3. Dormancy: the fleet that can wait

How it works: Eclipse repairs run on jumps, not stops. Repair drones (already the faction's damcon name) mend a fixed amount per jump while the fleet travels; a ship can be put dormant at a node to mend fully over two jumps, unavailable if a battle interrupts the route. Credits rush the work at Archive nodes (wake the yards, full repair now, today's price). Growth is E1/E2's; this is purely the heal leg, the Eclipse form of the Chorus gestation idea with machine patience instead of flesh growth.

Other games: Stellaris fleets repairing at anchor over time; Darkest Dungeon's stagecoach time; FTL's repair drones per jump in spirit.

What the player decides: route length as medicine, again, but with a machine flavour: a dormant flagship is a bet that the next two nodes are quiet.

What it breaks: same map dependency as G1 and Chorus gestation (free backtracking makes it farmable); per-jump repair can also just be slow enough to be invisible, which wastes the idea. It is the weakest of my three Eclipse ideas and I rank it third.

Build size: medium. Jump tick, dormancy state, rush prices.

### Eclipse recommendation

E1 as the spine, E2 as its supply line, E3 optional. The Archive turns Eclipse's existing fiction (reanimate, restore, dormant hulls, the backup dock action) into one campaign system with one scarce resource (slots and cores are two faces of it) and one real decision (who is backed up, and what did we leave on the field). No new currency: credits still buy bodies and slots; cores only ever come from the dead.

## Touch points, stated once for both factions

In-battle regen (Glasswright shields, Eclipse hulls), Eclipse reanimate, and event healing (the tombhome wake, the Chorus feed option) stay in battle and events. The between-battle systems above should name them where they meet: E1 is reanimate's campaign meaning; G1's kiln is where the Glasswright damcon name (annealing kilns) already points; the Archive node is where the tombhome event stops being an event and becomes infrastructure.
