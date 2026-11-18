# Leg: DeepSeek (DeepThink on, Search off; verified before and after)
# Chorus without shipyards, issue 1047. Model's response, verbatim.

Here are four distinct Chorus sustainment loops. Each is a different core loop, not a variation on the same idea. Together they cover the four required design spaces: replacement map stops, a second resource, healing earned through play, and growth over time or jumps. In each case, the CP cap stays meaningful: growth and replacement consume CP, and a fleet at the cap must reabsorb or lose a ship before it can grow. Marks are hull and damage only for the Chorus, since they have no shields.

## 1. Spawning Fields, Not Shipyards

**How it works.** For the Chorus, yard/drydock nodes become spawning fields. On arrival the fleet can feed once: heal roughly 25-30% of every ship's hull and set the existing "fed" flag, or spend that field's brood charge to discount a spawn. The field also stocks 2-3 Chorus hulls; the player spends credits to grow them, subject to the CP cap. Marks are bought as "molts" at the field: hull and damage only, no shields. Refits/modules are bought as mutations with credits. Damaged ships can also be reabsorbed for scrap. There is no per-credit instant repair to full; the Chorus heals by feeding, Gorge, and limited field charges. Existing spawning-field events and Gorge keep working; event healing is not redesigned.

**Reference lesson.** *Slay the Spire* rest sites make a stop a triage choice: heal, upgrade, or route. *StarCraft* Zerg hatcheries make production a fixed brood location, not a shop. Lesson: limit the stop's charges so the player chooses between healing and growing.

**Player decisions.** Route toward fields versus fights/events; use the field's feed charge to heal now or save the fed flag for Gorge; buy a cheap drone now or save credits for a Mark/mutation; grow under the CP cap or reabsorb something first.

**Failure modes.** Fields become dead nodes when the fleet is healthy; routes become mandatory field-chasing; cheap hulls plus credit income can snowball; CP cap can make field stock useless; a damaged Chorus fleet can still be burst down by a boss. Other factions may feel their yards are worse or better depending on field density.

**Build size.** Medium: one node variant, stock/UI, Chorus gate, and molt/mutation hooks; no battle-layer changes.

**Shipyard job coverage.** Healing: partial free feed plus Gorge. Replacement: credit-grown hulls at fields. Growth: credit plus CP. Marks: credit molts, hull/damage only. Refits: credit mutations. Decommission: reabsorb for scrap. Drops unlimited instant full repair; the cost is that the Chorus must enter some fights damaged or spend a field charge.

## 2. Biomass, Not Credits

**How it works.** The Chorus earns Biomass from battle results-enemy ships destroyed, wrecks, events, and reabsorbed ships. Between battles, a Hive panel lets the player spend Biomass to heal hull, spawn replacement hulls, and grow the fleet up to the CP cap. Credits remain meaningful as the "outside" economy: refits, Mark upgrades, event purchases, and a poor-rate conversion into Biomass at digestion nodes. Healing and hull replacement are priced in Biomass, not credits; the player can spend anywhere between battles, but only after a jump or at a digestion node if testing shows free spending erases routing.

**Reference lesson.** *Endless Space 2* Cravers and Vodyani make eating/essence a distinct economy; *Stellaris* hive minds make food a growth input. Lesson: a second resource expresses appetite, but it needs caps, conversion, and a reason credits still exist.

**Player decisions.** Heal now or bank Biomass for a replacement; reabsorb a damaged ship rather than heal it; take a fight to earn Biomass or skip to preserve hull; convert credits at a loss or save them for refits/Marks; spend on many cheap bodies or one capital.

**Failure modes.** Strong snowball: winning gives Biomass, which gives more wins. Death spiral: losing ships reduces future Biomass income. Hoarding before a boss can trivialize the fight; CP cap can leave Biomass surplus. Credits can become a secondary currency unless refits/Marks/events stay credit-priced. Battle results need kill/wreck counts-a battle-layer touch, not a regen redesign.

**Build size.** Medium-large: new resource, reward hooks, Hive panel, conversion, and UI; battle-layer touch only for result counting.

**Shipyard job coverage.** Healing: Biomass. Replacement: Biomass. Growth: Biomass plus CP. Marks: credits. Refits: credits. Decommission: reabsorb into Biomass. Drops yard repair; credits are retained as the non-hull economy.

## 3. Carrion Trail

**How it works.** After each battle the fleet feeds on the field. Feed is generated from enemy ships destroyed, with a smaller bonus from own wrecks; wreck-field nodes add more. The player allocates Feed between healing hull now, storing brood stock for replacements, and molting a Mark. Replacements consume brood stock and CP; larger hulls require a brood-sac or spawning field, so cheap drones/spitters are the reliable fallback. Credits buy refits/events and can buy Marks if Feed is scarce. No shipyard repair; no instant full heal. In-battle regen and event healing are untouched.

**Reference lesson.** The prior feed sketch and *Endless Space 2* Cravers: aggression should pay, but eating must be capped. *StarCraft* Zerg larvae show replacement as a brood decision, not a shop transaction. Lesson: reward fighting, but give a safety valve so a bad fight does not starve the run.

**Player decisions.** Fight or skip to preserve hull; allocate Feed to heal a capital or spawn cheap bodies; bank Feed for the boss or spend now; detour to a wreck field; risk a longer fight to eat more.

**Failure modes.** Snowballing when wins feed the next win; death spiral after a bad loss; boss fights with few wrecks can starve the Chorus; Feed hoarding can trivialize later nodes; wreck-field nodes are dead if the player avoids battles. CP cap still limits growth, but Feed income can distort credit value if it also buys Marks/refits.

**Build size.** Small-medium: post-battle allocation UI and result hooks; battle-layer touch to count kills/wrecks, not to change regen.

**Shipyard job coverage.** Healing: Feed allocation. Replacement: brood stock plus CP. Growth: CP plus brood stock. Marks: Feed molt or credits. Refits: credits/events; the yard refit shelf is dropped, narrowing build variety. Decommission: reabsorb into Feed/brood stock. Drops instant full repair.

## 4. Brood Cycle

**How it works.** Each jump, the fleet regrows a small percentage of hull and brood-sacs generate larvae. The player sets a brood focus before the jump: heal, spawn, or molt. New hulls do not appear instantly; they mature after one or two jumps and consume CP when mature. Larvae replace losses; larger hulls need a brood-sac or nursery node. Credits accelerate gestation, buy mutations, and pay event costs; Feed can also speed a queue. No shipyard repair; damaged ships recover over jumps, not instantly.

**Reference lesson.** *StarCraft* Zerg larvae and hatcheries make production a timed brood queue; *Stellaris* growth makes time a cost. Roguelite incubator timers teach that delayed growth is good only if the player can plan around it. Lesson: time creates anticipation and route planning, but waiting must not be boring.

**Player decisions.** Set heal/spawn/molt focus each jump; bring a brood-sac and accept a weaker combat carrier, or rely on spawning fields; rush a hull with credits/Feed or save; accept an understrength fleet now for a stronger one after the boss gate.

**Failure modes.** Too slow: losses take jumps to replace, causing a death spiral. Too safe: if jumps are plentiful, the fleet snowballs without spending. Boss timing can punish a queue that matures one jump too late. Losing the brood-sac can cripple replacement; CP cap can strand mature larvae. Other factions' instant repairs may feel strictly better.

**Build size.** Medium-large: jump tick, gestation queue, focus UI, larvae/maturation state; no battle-layer changes.

**Shipyard job coverage.** Healing: automatic per-jump hull regrowth, capped. Replacement: delayed larvae queue plus CP. Growth: larvae plus CP. Marks: molt timer or credits. Refits: mutations at brood-sac/nursery. Decommission: reabsorb. Drops instant repair and instant refit convenience; the cost is tempo and boss-timing risk.

## Considered but not proposed

Simply banning Chorus shipyard repair while letting them buy hulls at normal yards. It is not a distinct loop; it makes the Chorus a faction with a penalty rather than an economy, and leaves credits as the only real answer.

## Ranked top pick

**Carrion Trail.** Strongest expression of "the swarm that eats," no reskinned shipyard, and it uses the existing Gorge/Martyr/regeneration identity. It is small-medium to prototype and creates real fight-versus-feed choices. It needs a hard Feed cap and a spawning-field safety valve so replacement starvation does not end runs.

**Spawning Fields, Not Shipyards.** The safest complete replacement for the shipyard job: keeps credits and CP meaningful, covers healing/replacement/growth/Marks, and needs no battle-layer work. It is less distinctive and risks feeling like a reskinned yard.

**Biomass, Not Credits.** Strong faction flavour, but the highest currency-sprawl risk; credits need deliberate secondary sinks or they become noise.

**Brood Cycle.** Good planning texture, but slowest and most vulnerable to boss-timing and death-spiral problems.

**Single biggest risk across all approaches:** the Chorus becomes a win-more faction. Every victory feeds the swarm and every loss starves it, so without a capped, partly bankable feed supply and a guaranteed replacement floor, a bad boss attempt can end the run while a good start snowballs out of control.
