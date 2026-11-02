Eclipse Penumbra – Battleship Design Report (Job 8)
Headline
The Eclipse penumbra is the faction's fleet anchor: a heavy gun platform that holds the line while smaller Eclipse hulls fold and harass around it. Its defining strength is the Spinal cannon, a burst-damage ability no smaller Eclipse hull can carry, letting it crack a hex open at range and punish anything clustered nearby. Its defining cost is that same cannon's friendly-fire splash and the ship's total lack of shields, meaning it must be positioned with care or it will eat its own escort and dissolve under focused fire.
Role in the Fleet
The zenith cruiser supports: it repairs, it holds a flank, it trades hits with its regen. The penumbra does what the cruiser cannot—it deletes a priority target at range with the Spinal cannon and it soaks sustained fire with 250 hull and .35 armour instead of dodging or patching. It anchors a mid-to-late-run fleet built around two or three destroyers and frigates that fold-skip into flanking positions while the penumbra draws fire and cracks the enemy's centre.
A fleet with one penumbra looks like this: the battleship sits at the back of a hex cluster, corona ring glowing, null cannons ticking away at whatever enters range 5. The jackals and motes screen forward, using fold-skip to reposition. The penumbra fires the Spinal cannon into the enemy's densest hex on cooldown, accepting the splash risk because its own escorts are fast enough to stay clear.
It should never be used as a lone raider or a chaser. Speed 2, turn 1, evasion 0: it cannot catch anything and cannot dodge. It should never lead a fold-skip assault. It is the anvil, not the hammer.
Admiral styles it serves best: the "harvester plus jackal" admiral gains a heavy centre to pair with the cruiser's repair swarm, letting the cruiser keep the penumbra patched while it fires. The "two jackals plus two motes" admiral gains the anchor those light hulls desperately lack. The "three jackals" admiral can add the penumbra as a mid-run purchase to convert a raiding fleet into a holding fleet.
Stat Block
d_occult  "Eclipse penumbra"  Battleship
size .96 | cp 6 | hp 250 | sh 0 | rg 0 | armor .35
speed 2 | turn 1 | evasion 0
weapons: Null cannon (turret) x2, Corona arc (prow), Null shredder (turret)
ability: Spinal cannon
refit slots: 3
regen 5 (main) / 4 (rules15) | reanimate: true
cost: see below
Justification per number:
Size .96: Between the Bastion (.95) and the Dominion (.98). Larger than the zenith (.82), smaller than The Unsetting (1.3). It reads as a capital hull without approaching the boss silhouette.
CP 6: Matches the Dominion. Eclipse is stronger but dearer (R63). CP 6 also triggers the automatic 3 refit slots. CP 5 would match the Bastion but underprices the Eclipse premium.
HP 250: The Bastion has 220 + 30 shields = 250 effective. The Dominion has 230 + 32 = 262 effective. Eclipse gets no shields (faction rule, shipped), so 250 raw hull puts it level with the Bastion's effective pool. Regen and reanimate add durability over time that shields do not.
SH 0, RG 0: Faction rule. Every Eclipse hull ships with sh 0, rg 0. Giving shields here would be a ruling-level change, not a stat choice.
Armor .35: Matches The Unsetting. The zenith is .3; the battleship is the next step up. The Bastion is .3, the Dominion .25—Eclipse's "stronger but dearer" identity justifies the higher plate.
Speed 2, Turn 1, Evasion 0: Identical to every other battleship and to the zenith. Capital hulls do not dodge.
Weapons: See next section.
Ability – Spinal cannon: See next section.
Refit slots 3: Automatic at CP 5+ per pricing mechanics.
Regen 5 (main) / 4 (rules15): Main ladder is 3, 3, 4, so the next step is 5. Rules15 trimmed each by 1, giving 2, 2, 3, so the battleship is 4. Boss sits at 8; this stays well below.
Reanimate: true: All non-boss Eclipse hulls carry this. The penumbra is not a boss.
Price arithmetic:
Base cost = 60 × CP + 10 = 60 × 6 + 10 = 370.
Main: multiplier 1.6, 370 × 1.6 = 592, rounded to 590.
Rules15 as-is: multiplier 1.6, 370 × 1.6 = 592, rounded to 590.
Rules15 corrected: multiplier 1.7, 370 × 1.7 = 629, rounded to 630.
Zenith on rules15: 250 × 1.65 = 412.5 → 415. Both 590 and 630 clear 415, satisfying R1 FS-2 in final price.
FS-2 multiplier resolution: On rules15 the ladder reads Frigate 1.55, Destroyer 1.6, Cruiser 1.65, Battleship 1.6. The battleship breaks the ascending order. I recommend raising the battleship multiplier to 1.7, restoring the ladder (1.55 → 1.6 → 1.65 → 1.7). Final price becomes 630. Setting an explicit cost (as the Bastion uses 340) is the alternative, but the computed path keeps Eclipse's pricing formula intact and is simpler for the builder. I flag that the 1.6 figure currently in the code must be changed to 1.7 on rules15.
Weapons and Ability
Loadout: Null cannon (turret) × 2, Corona arc (prow), Null shredder (turret).
This mirrors The Unsetting's battery, making the penumbra read as a junior flagship. Compared to the zenith (Null cannon × 2, Corona arc, Null spire), the penumbra swaps the Null spire for the Null shredder: more shots, more total damage, but still a point-defence-class weapon. The swap signals that the battleship's point defence is heavier, befitting a hull that will be surrounded by escorts it must protect.
Rough expected damage per firing turn (accuracy applied, cooldowns averaged):
Zenith: Null cannon x2 = 2×(3×6×.74)=26.6; Corona arc = 40×.78/3=10.4; 4th weapon Spire: 2×4×.80=6.4; ability Repair (no dmg); rough total ~43.
Penumbra: Null cannon x2 = 26.6; Corona arc = 10.4; 4th weapon Shredder: 3×3×.80=7.2; ability Spinal: 40/4=10.0; rough total ~54.
Bastion: weapon stats not in pack; Shield surge (no dmg); cannot compute.
Dominion: weapon stats not in pack; Launch squadron; cannot compute.
Labelled rough. The Bastion and Dominion weapon stats are not in this pack; I can only note they each carry four weapons of comparable class. The penumbra's ~54 is about 25 % above the zenith's ~43, and the Spinal cannon adds a 40-damage burst every fourth turn that no smaller Eclipse hull can replicate.
Ability – Spinal cannon: The cruiser's Repair swarm is the right ability for a support hull. The battleship needs to threaten, not patch. Spinal cannon is currently boss-and-Crusade-dreadnought only; giving it to the penumbra follows the precedent of a player-accessible hull carrying it. The friendly-fire splash is the built-in cost: it punishes careless positioning and rewards the slow, deliberate play a speed-2 capital demands. No smaller Eclipse hull should carry this—the motes and jackals are too fragile to risk the splash, and the cruiser's role is repair, not burst.
Name
Display name: "Eclipse penumbra." The pattern is Eclipse + one lowercase noun drawn from light and its absence. The penumbra is the partial shadow cast during an eclipse—the region between full light and full dark. It sits between the zenith (the sun's peak) and The Unsetting (the sun gone), which is exactly where a battleship sits in the roster.
Runner-up: "Eclipse corona." Lost because "Corona arc" is already a shipped Eclipse weapon name; stacking "corona" on both a weapon and a hull risks confusion in tooltips and patch notes.
Data id: d_occult. The d_ family is established. None of the existing ids matches its display name (scythe → mote, jackal → flare, harvester → zenith), so d_occult follows that tradition. "Occult" from occultation, the blocking of one body's light by another.
Class label: Battleship.
The Look
The penumbra is a broad, layered sunshade fan seen from above: three concentric arcs of dark violet-black armour plate sweeping forward from a compact central hull, each layer slightly wider than the last, like a heat shield stacking. The ship shelters behind the fan. At the rear, a full eclipse ring—a torus of white-gold corona light—encircles the engine section. No flaming bells; the engines glow with a cold violet-white inner light visible through the ring's gap.
Two Null cannon turrets sit on symmetric saddle mounts atop the fan's second layer, one port, one starboard, barrels aiming forward and slightly out. The Corona arc is a recessed prow emitter set into the fan's leading edge, centre-line. The Null shredder sits in a ball mount on the hull's flat belly, aft of centre, covering the rear quarter.
Sensor housings and a short antenna array rise from the dorsal centreline just behind the fan. Heat radiators are flat panels angled off the hull's flanks, paired symmetrically. The Archive core shows as a faintly glowing violet-white cylinder recessed into the ventral hull, visible only as light leaking between armour plates. No green glow anywhere. The stale code line (data.js:126, hull dark grey-green, trim green, glow green) must not be followed; the bible and the faction package both specify dark violet-black with white-gold corona.
Concept Image Prompts
Top view:
Top-down view of a battleship-shaped spacecraft, broad layered sunshade fan of three concentric dark violet-black armour arcs sweeping forward from a compact central hull, two turret-mounted guns on the second fan layer aiming forward, a recessed prow emitter on the leading edge, a glowing white-gold eclipse ring encircling the engine section at the rear, flat heat-radiator panels angled symmetrically off the flanks, short antenna array on the dorsal centreline, armoured flat belly visible at the edges, cold violet-white inner glow between plates. Palette: dark violet-black hull, white-gold corona accents, violet-white engine glow. Lighting: soft top-down key with white-gold rim light from the engine ring. No keel, no raked bow, no mast, no funnel, no deck, no portholes in rows, no green glow, no text, no watermark. Space ship, not naval ship.
Side view:
Side-profile view of a battleship spacecraft, layered sunshade fan visible as stacked forward-sweeping armour shelves in dark violet-black, compact hull sheltering behind the fan, two turret guns on top of the second shelf aiming forward, a single forward hull emitter recessed into the leading edge, a full eclipse ring of white-gold corona light around the rear engine section with cold violet-white glow inside, flat heat-radiator panels angling off the flank, sensor housing and short antenna array on the dorsal line, armoured flat belly below, docking hatch visible on the lower hull. Palette: dark violet-black plates, white-gold corona trim, violet-white glow. Lighting: soft side key, white-gold rim from the engine ring. No keel, no bow stem, no mast, no funnel, no deck, no portholes in rows, no green glow, no text, no watermark. Space ship, not naval ship.
Three-quarter view:
Three-quarter view of a battleship spacecraft from slightly above and to port, showing the broad layered sunshade fan of dark violet-black armour arcs, two symmetric turret guns on the fan's second layer, a recessed prow emitter, a white-gold eclipse corona ring around the rear engines with violet-white inner glow, flat belly with a faintly glowing Archive-core cylinder, heat-radiator panels on both flanks, antenna array on the dorsal centreline, equipment pods on visible mounts. Palette: dark violet-black hull, white-gold corona accents, violet-white glow. Lighting: warm white-gold key from the engine ring, cool violet fill. No keel, no raked bow, no mast, no funnel, no deck, no portholes in rows, no green glow, no text, no watermark. Space ship, not naval ship.
Hand-Built Parts List
Guns: Two Null cannon turrets, saddle mounts, second fan layer, port and starboard pair, barrels forward-out.
Guns: Corona arc emitter, recessed prow housing, centre-line, forward-facing.
Guns: Null shredder, ball mount, ventral aft, single (no pair needed, rear arc).
Bridge / superstructure → sensor housing and antenna array: One dorsal sensor block and one short antenna column, centre-line behind the fan, hand-shaped.
Masts / funnels → heat radiators: Four flat radiator panels, two port, two starboard, angled off the hull flanks, symmetric pairs on plate mounts.
Tanks / cylinders → Archive core: One recessed violet-white cylinder, ventral centre, between armour plates, column mount.
Engine nozzles: Eclipse ring torus, rear of hull, white-gold corona material, encircling the engine section; inner glow violet-white, no flame bells.
Armour stacks: Three-layer sunshade fan plates, forward hull, layered and overlapping, hand-shaped for clean silhouette.
Bow shape → forward hull: Fan leading edge with recessed Corona arc housing, no raked stem, blunt and armoured.
Owner Questions
Spinal cannon on a player hull. The penumbra's ability is the Spinal cannon, which today is boss-only for Eclipse. The Crusade dreadnought already has it, so there is precedent. (a) Yes, give it to the penumbra – the battleship needs a burst the cruiser can't match. (b) No, keep it boss-only; give the penumbra Repair swarm instead – simpler, but the battleship plays like a bigger cruiser. (c) Flag it for a new ability and I'll spec one. My pick: (a). It creates the clearest role split between cruiser and battleship.
Battleship multiplier fix. The rules15 ladder has the battleship at 1.6, below the cruiser's 1.65. (a) Raise it to 1.7, final price 630 – the ladder is clean and the ship feels premium. (b) Leave it at 1.6, final price 590 – cheaper, but the multiplier order is visibly wrong. (c) Set an explicit cost of 620, skip the formula. My pick: (a). One number change, formula stays intact.
Null shredder vs Null spire. I gave the penumbra the Null shredder (boss's point-defence gun) instead of the zenith's Null spire. (a) Keep the shredder – mirrors the boss, heavier feel. (b) Swap to the spire – matches the cruiser, less to explain. My pick: (a). The battleship should echo the flagship, not the cruiser.
Hull points: 250 or 260. At 250 the penumbra matches the Bastion's effective HP exactly. At 260 it edges past the Dominion's 262. (a) 250 – clean parity. (b) 260 – Eclipse's "stronger" identity shows in raw numbers. My pick: (a). Regen and reanimate already push Eclipse durability above the shield factions over a long fight; 250 is enough.
Not Checked
Bastion and Dominion weapon stats are not in this pack; the firepower comparison against them is structural only, not numerical.
I inferred the Spinal cannon has no accuracy roll (it is an ability, not a listed weapon with an accuracy value). If the code applies one, the averaged damage shifts.
I assumed "cooldown 2" on the Corona arc means fire-wait-wait-fire (one shot every three turns). If the code reads it as fire-wait-fire (every two turns), the averaged damage is higher.
The stale green palette line at data.js:126 is flagged but I could not confirm whether any runtime still reads it.
I did not read the reanimate reassembly code; I took the pack's description (fraction of hull, cannot fire that round) on trust.
Whether the Null shredder being "boss only today" is a hard code gate or simply the current roster state is my inference from the pack's wording.
