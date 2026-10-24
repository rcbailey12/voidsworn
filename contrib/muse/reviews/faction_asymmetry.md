# Faction asymmetry audit: one skeleton, six costumes

Type: external POV audit and proposal (Rey). Basis: repo main at 51337c2, the Run 3 content census (contrib/muse/compute/), the council reports, and the Oct 23 sim matrix. This is a suggestion document for the owner and Opus; feasibility and code truth are Opus's call.

## The owner's charge

The six factions play as one faction in six costumes. Every roster is the same ladder (a frigate, a destroyer, a cruiser, a carrier, a boss), squadrons work the same way everywhere, and the differences are weapon names and stat nudges. The benchmark the owner named is StarCraft and Warhammer: factions whose rules differ, not just their numbers. Zerg are not Protoss with a green palette. This audit measures how true the charge is, names the asymmetry the game already half-owns, and proposes a distinct playstyle per faction that the current engine can mostly express.

## Part 1: the sameness, measured

All figures from the content census at 51337c2.

1. The price ladder is identical everywhere. Every faction's frigate costs exactly 70, every destroyer exactly 130, cruisers cluster at 190 to 250, carriers at 250 to 310, bosses at 470 to 650. A player who has priced one faction has priced all six.
2. The class ladder is identical. Five of six factions field frigate, destroyer, cruiser, carrier, boss in that order. Deathless stops at cruiser plus boss. Nobody lacks a class another has (except Deathless's missing carrier), and nobody has a class the others lack.
3. Twelve of the 45 hulls are variant hulls whose stats are identical to a base hull with a weapon swap (Harrow vs Harrow torpedo-destroyer: same hp, shields, speed, cost; Penitent vs Penitent gun-cruiser: identical line). A third of the roster's apparent variety is loadout, not hulls.
4. The signature weapons are statistical siblings. Expected damage per volley from each faction's basic gun: Voidsworn autocannon 15, Hegemony laser 14, Ithar shard cannon 18, Hegemony turbolaser 18, Deathless gauss 18. Range 4 or 5, accuracy 74 to 80 in all of them. The names promise five weapons; the numbers deliver one weapon with five skins. (This is the same disease as the 13 dead reskins the check pack found in the name tables.)
5. Squadrons are one system with three paint jobs. Fighter, bomber and spore wings share the same frame (18 to 28 hp, speed 5 to 6, one weapon slot, range 1 weapons). The spore wing's stat line is within noise of the bomber's.
6. Admirals are structurally identical: four per faction on the same 0/30/45/80 cost curve, drawing Commands from a shared pool of six ids (barrage, hunt, scramble and the rest appear in multiple factions' lists), with doctrines that are almost all percentage nudges to shared systems.
7. The sim agrees. In the Oct 23 matrices, faction rows differed mainly by fleet source (starting fleets vs fleet lists) rather than by any per-faction mechanic a player could feel, and the council's gamer lens found the dominant strategy (focus fire to the 65% CP rout threshold, torpedo alpha) is faction-independent.

## Part 2: the asymmetry the game already half-owns

Buried in the data are real, functional differences. They are just too small, too quiet, or too isolated to define a playstyle.

- Chorus has zero shields on every hull and a regrow ability: a genuine structural difference (no shield layer at all, health as the only pool). Deathless also has zero shields fleet-wide, which dilutes it: two of six factions share the "no shields" identity.
- Deathless has the phase ability and the reclaim ability (the harvester's identity is built on wrecks), plus the highest armor band (0.2 to 0.35) and the highest frigate hp (56). The bones of an attrition faction exist.
- Ithar is the speed faction on paper (frigate speed 7, destroyer 6, blink on both) with the highest shields and the lowest hull hp: a glass-fleet profile that is real but expressed only as numbers.
- Corsair weapons are genuinely shorter ranged (scatter cannons range 3, the shortest gun band in the game) and its speeds are high, but its hulls cost and scale like everyone else's, so the raider identity reads as "standard fleet, slightly closer."
- MOVE_FEEL already gives each faction a different movement character (Chorus sways and squashes, Deathless phases, Ithar arcs and bobs, Hegemony moves linearly). The presentation layer is more asymmetric than the rules layer, which is the wrong way round.

Verdict: the game has asymmetry of flavour and of a few numbers, but not of decisions. A player makes the same decisions in the same order with every faction: form a line, focus fire, alpha with torpedoes, play for the rout threshold. That is what has to change.

## Part 3: proposal, one playstyle per faction

Design rule used throughout: a faction is asymmetric when it changes the decisions, not the decimals. Each proposal below uses mechanics already present in the data (marked HAVE) or names the smallest engine change it needs (marked NEED). StarCraft mapping is shown because the owner asked for that bar.

**Chorus, the swarm (Zerg / Tyranids).** Identity: volume and regrowth. HAVE: zero shields, regrow, spore squadrons, the cheapest-feeling hull names. Proposal: drop Chorus hull costs by roughly a third and let it field more, smaller bodies; make regrow scale with adjacent Chorus ships (a swarm that heals in a pack); give the brood-mother a true spawner role (produces drone wings during battle, not just at launch). NEED: mid-battle spawning exists in the launch code path only, per the census ability list; extending it is the one engine ask. Win condition: drown the rout math in bodies. Lose condition: area damage and focus fire thin the pack faster than it regrows.

**Ithar, the elite (Protoss / Eldar).** Identity: few, precious, long-ranged, shield-dominant. HAVE: highest shields, lowest hp, blink, speed, pulsar lances at range 6. Proposal: raise Ithar costs by roughly a third and cut its roster size in a fleet (fewer, stronger hulls); make its shields recharge mid-battle (the only faction that does); its frigate should out-range every other frigate by 2. NEED: shield recharge is a new rule but a small one, and it makes "get through the shields before they come back" the tactical problem Ithar poses. Win condition: kiting and shield cycling. Lose condition: once a shield drops, the hull under it is the frailest in the game.

**Hegemony, the standard (Terran / Imperial Guard).** Identity: the baseline everyone else bends around, and proud of it. Combined arms, ion shield-stripping, fighter screens, honest mid-range guns. Proposal: change the least. Hegemony is the control group that makes the other five legible, and its asymmetry is that it has no gimmick and the best toolkit breadth (the only faction that should keep all five classes at standard prices). Every game needs its Terran.

**Corsairs, the raiders (Orks / Drukhari).** Identity: close, fast, violent, and paid in salvage. HAVE: shortest-range guns, high speed, overburn, torpedo access, boarding in the game already (tendrils are Chorus's, but boarding as a system exists). Proposal: lean the whole faction into range 1 to 3; make its economy different (bonus salvage and capture value, its ships are worth less when lost); give its cruiser the boarding role the tendril weapon prototypes. NEED: faction-level economy modifiers (salvage multiplier) rather than new combat systems. Win condition: get inside the enemy's range band and trade up. Lose condition: kited by anyone with range 5+.

**Voidsworn, the fortress (Imperial Fists / a siege list).** Identity: slow, armored, broadside weight, area denial. HAVE: the heaviest armor band among shielded factions, broadside weapon arcs (P/S batteries are already in its loadouts), the slowest speeds. Proposal: make Voidsworn the only faction whose broadsides out-damage its forward guns by a wide margin (arc asymmetry as a faction rule, so positioning IS the faction), drop its speed further, raise armor; its carrier is a gun platform that happens to launch wings, not a true carrier. NEED: none structural; this is data and arc values. Win condition: form the line and dare them to close. Lose condition: flanked or out-ranged by Ithar.

**Deathless, the attrition engine (Necrons).** Identity: wrecks are a resource, the fleet does not stay dead, and time is on its side. HAVE: reclaim, phase, highest armor, zero shields, the harvester (the single hardest-hitting hull in the sims). Proposal: reclaim becomes the faction economy (salvage from any wreck on the field, friend or foe, at a rate no one else gets); a limited return-from-wreck rule for its small hulls (the Dynasty's signature terror); remove its carrier gap by giving it a tomb-ark that raises sentries instead of launching wings (the gsentry weapon already exists). NEED: the return rule is the second real engine ask; the rest is data. Win condition: long battles and wreck fields. Lose condition: short, decisive alpha strikes that end the battle before attrition speaks.

Cross-cutting, cheap and high-yield:
- Break the shared price ladder. Let frigates cost 50 (Chorus) to 95 (Ithar). The ladder being identical is the single most legible sameness in the game, and it is one data pass to fix.
- Give each faction one thing it cannot do. Chorus: no long-range weapon above range 4. Ithar: no torpedoes. Corsairs: nothing above range 3 except torpedoes. Voidsworn: no speed above 3. Deathless: no shields, ever (already true, make it law and take Chorus's identity back to shields-off-plus-regrow versus shields-off-plus-armor, or differentiate further). Prohibitions create identity faster than bonuses.
- Admirals: keep the shared cost curve but make each faction's 80-cost admiral break its own faction's rule (the Chorus admiral who grants shields, the Ithar admiral who fields a swarm). Exceptions prove identities.

## Part 4: how to prove it worked

1. Re-run the faction matrices after any data pass. The signature of success is not balance (50% everywhere) but different shapes: Chorus fleets fielding visibly more hulls per CP, Ithar fewer; faction win rates that move when the map or range bands change, instead of one dominant line for all six.
2. Add one harness table: average fleet hull count, average engagement range, and damage taken by range band, per faction. If those three numbers are near-identical across factions, the factions still are too, whatever the text says.
3. The human test stays the owner's: play one battle as Chorus and one as Ithar. If the same opening moves feel right in both, it is not done.

## Not covered

No new-faction proposals (six is enough until the six differ). No campaign or event asymmetry (factions on the map layer) beyond the economy notes. Balance numbers in Part 3 are directional starting points for the sim to judge, not tuned values.
