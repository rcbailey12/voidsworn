# Leg: DeepSeek (DeepThink on, Search off; verified before and after)
# Issue 1063 Glasswright and Eclipse economy brainstorm. Model's response, verbatim.

Embers of the Hollow Sun - Between-Battle Fleet Economies: Glasswrights and Eclipse

Assumptions used throughout. The owner's income correction is fixed: every faction's main income is a flat amount per win set by sector and fight kind, half on a partial win, with only a small extra tied to how the fight went. Free floors remain: drydock full repair, field 20% hull patch. These are design proposals only, not code or rule changes. Build size is in agent terms: Small = one action/table plus text; Medium = a new token/resource or node action, UI, and a few events; Large = a campaign subsystem, build/recovery queue or roster UI, multiple node hooks.

Glasswrights (ithar)

Identity pressure: frail, shield-led, cannot Brace, few and expensive hulls, hull damage and destroyed ships are the between-battle problem. Repair and replacement should feel like optical craft: annealing, panes, grown lenses, stored light. Keep credits as the main flat income; faction flavour comes from sinks and limits, not a kill-fed second currency.

1. Annealing Kilns and Pane Salvage

How it works: At shipyards and drydocks, spend credits to anneal hull damage per hull point. Destroyed Glasswright ships leave a capped, class-specific bundle of intact panes; at a shipyard those panes discount rebuilding the same class, with credits covering the rest. Pane bundles are fixed by class and capped per battle, not earned from kills. Field 20% patch and drydock full repair remain. Rebuilt ships return at the same Mark, or one Mark lower if rebuilt cheaply.

Other games / lessons: BattleTech repair-and-refit and FTL store repairs. Lesson: repair costs must be predictable and cheap enough that a losing fleet can recover; salvage from losses must not reward deliberately sacrificing ships.

Player decides: Repair now or save for a rebuild; which damaged hull to anneal first; whether to spend panes on a rebuild or hold them.

What it would break: Cheap annealing removes all attrition from a shield-led faction. Generous pane bundles encourage sacrifice loops. Expensive annealing creates a death spiral for a faction that already cannot Brace.

Build size: Medium.

2. Pattern Garden Commissions

How it works: New Glasswright hulls are not bought off a shelf. At a shipyard, commission a hull from a pattern; pay flat credits up front; it grows over one jump (larger hulls maybe two). It arrives at base Mark. A drydock can accelerate growth for extra credits, capped once per commission. Command-point cap still applies.

Other games / lessons: XCOM base build times and Empire at War ship production. Lesson: delayed replacement creates real risk; there must be an emergency acceleration path and a guaranteed floor so a just-lost fleet is not stranded.

Player decides: Which class to commission, when to start, and whether to pay to accelerate.

What it would break: Long delays can strand a loser. Acceleration costs can become a win-more trap. Too many simultaneous commissions make the few-expensive-hull identity vanish.

Build size: Medium to Large.

3. Lens Grafting for Mark Growth

How it works: Mark upgrades are grown lenses at a kiln, not shelf purchases. Each ship can take one graft per shipyard visit; cost is flat credits. A graft can be taken on a damaged ship, so the choice is upgrade versus repair, not upgrade versus being forced to sit out. Grafts do not repair hull by themselves.

Other games / lessons: Slay the Spire rest-site choice between healing and upgrading; BattleTech refits. Lesson: upgrade-versus-repair tension is good, but blocking upgrades on damaged ships punishes the faction that takes hull damage most.

Player decides: Which ship gets the next lens graft; whether to spend on growth or repair this stop.

What it would break: If grafts also repair, drydocks lose value. If grafts are too expensive, the few Glasswright hulls fall behind and the faction cannot grow.

Build size: Small to Medium.

4. Stored-Light Reservoir Overcharge

How it works: Between battles, spend credits to refill or overcharge a ship's stored-light reservoir. This gives a starting shield buffer or a faster first shield regen next battle. It does not repair hull. It is a keep/buffer sink, not a replacement system.

Other games / lessons: Pre-mission consumables in XCOM and BattleTech. Lesson: temporary buffs should compete with recovery spending, not crowd it out.

Player decides: Spend on a shield buffer before a hard node, or save for hull repair and rebuilds.

What it would break: Too strong a buffer covers the no-Brace weakness. Too costly makes it a trap for players who cannot afford both.

Build size: Small.

Recommended direction for Glasswrights: Make the core loop an annealing-kiln economy: flat credits per win, hull repair at kilns, capped class-specific pane salvage for rebuilding destroyed hulls, Pattern Garden commissions for new hulls, and Lens Grafting for Mark growth. Keep the reservoir overcharge as a small optional sink. Keep drydock full repair and field 20% patch as floors so a fleet that just lost can still recover. Do not make pane salvage scale with kills or with intentional losses.

Eclipse (deathless)

Identity pressure: no shields, armour and in-battle hull regen, layered shade plates, archive vaults, cores of trapped light. In-battle regen, reanimation and event healing stay separate. The between-battle system should be archive-and-plate: permanent restoration, plate replacement, and limited core recovery. Use flat credits as main income; any salvage token should be capped and not kill-fed.

1. Archive Backups and Restore

How it works: At a shipyard or archive node, pay flat credits to back up individual ships or the fleet. A backed-up ship destroyed in the next battle can be restored at a shipyard/drydock for a restore cost, at the same Mark or one Mark lower; unbacked ships are gone. The existing "Back up the fleet" dock action becomes one version of this. In-battle reanimate is temporary battlefield return; archive restore is permanent between-battle replacement.

Other games / lessons: EVE clone/insurance systems and XCOM soldier recovery. Lesson: insurance must be affordable for a losing fleet, capped, and not a rich-get-richer trap.

Player decides: Which ships to back up before a risky node; whether to pay for a restore or build new.

What it would break: Too generous and losses stop mattering. Too expensive and a fleet that just lost cannot recover. Poorly separated from reanimate and battles feel like they have two resurrection systems.

Build size: Medium.

2. Shade Plate Reclamation

How it works: After battle, a flat reclamation pool is awarded by sector and fight kind, half on partial win, with only a small performance extra. Spend it at shipyards/drydocks to replace peeled shade plates and repair hull per hull point. Field 20% patch and drydock full repair remain. Repair is cheaper than replacement.

Other games / lessons: BattleTech armour repair and Homeworld salvage. Lesson: flat income avoids kill snowball; repair must be cheaper than replacement or no-shield ships die permanently.

Player decides: How to spread plate repair across the fleet; repair now or save for a new hull.

What it would break: Cheap repair removes attrition from an armour faction. Expensive repair makes the no-shield faction collapse after one bad fight.

Build size: Small to Medium.

3. Core Recovery and Vault Decks

How it works: When an Eclipse ship is destroyed, one core can be recovered per battle at a shipyard for credits. The recovered ship returns at one Mark lower but keeps its name and veteran identity. Additional core recoveries in the same battle cost much more or are unavailable. In-battle reanimate remains a temporary return; core recovery is permanent but degraded.

Other games / lessons: XCOM wounded recovery and Darkest Dungeon roster recovery. Lesson: preserving identity softens loss, but recovery must be capped or losses become cosmetic.

Player decides: Recover the core or build a fresh hull; which lost ship matters most.

What it would break: Too generous and losses are soft. Random recovery is frustrating. Overlap with reanimate confuses the player.

Build size: Medium.

4. Dormant Hull Yards

How it works: An event/node with stored Eclipse hulls without minds. Pay flat credits to wake one; it starts blank at a lower Mark, or can take an archive copy if you have a backup. This is an event replacement/growth path, not the main loop.

Other games / lessons: BattleTech lostech caches and Stellaris abandoned shipyards. Lesson: event replacement is swingy; it must be a bonus, not the only way a losing fleet can recover.

Player decides: Wake a hull now or save credits; which hull type to wake.

What it would break: Too much variance; a run can starve or snowball on one event. It can bypass the archive-and-plate core loop.

Build size: Medium to Large.

5. Ripped Hull Conversion

How it works: Captured enemy hulls already flagged "ripped" can be stripped for shade plates or re-sleeved as a low-tier Eclipse hull at a shipyard, giving a capped discount on plate repair or a new hull. Cap conversions per battle; no kill-fed scaling.

Other games / lessons: Homeworld salvage and BattleTech mech salvage. Lesson: salvage economies snowball unless capped and converted at a bad rate.

Player decides: Sell the ripped hull, strip it for plates, or convert it.

What it would break: Encourages capture farming; can bypass the flat income loop if discounts are too high.

Build size: Medium.

Recommended direction for Eclipse: Make the core loop archive backup plus shade-plate reclamation. Flat credits per win pay for plate repair and backup/restore. Destroyed backed-up ships restore at a shipyard with a Mark penalty; one core recovery per battle is allowed; in-battle reanimate stays temporary and separate. Dormant hull yards and ripped-hull conversion are event/optional sinks, not the main recovery path. Keep drydock full repair and field 20% patch as floors so a fleet that just lost can recover.

Risks note

- Win-more: Any salvage, pane bundle, backup discount or plate stock tied to kills or battle performance will feed winners. Keep main income flat per win/partial win and cap all salvage.
- Loss spiral: A fleet that just lost must afford basic repair or one restore. Keep free drydock and field floors, and make the cheapest recovery path reliable.
- Overlap: Eclipse archive restore must be clearly different from in-battle reanimate and event healing. Glasswright kiln repair must be clearly different from free drydock repair.
- Complexity: Two faction economies can bloat the UI. Prefer credits plus one capped faction token at most; avoid a full second currency unless it earns its place.
- Event variance: Dormant hull yards and ripped-hull conversion should be bonuses, not the only replacement route.
- Command-point cap: All new hulls, restores and commissions must respect the existing cap; otherwise fleet growth becomes the real economy.
