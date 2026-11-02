# Job 8 synthesis: the Eclipse battleship

Verdict: GO. The design below is complete and buildable from shipped content only: no new weapon, ability, or code path. Four legs ran (DeepSeek, Qwen, Argon, and a blind Rey leg), and they converged harder than any job so far: CP 6 unanimous, the FS-2 price fix unanimous, hull 260 from three of four, armour .35 from three of four, twin Corona arcs from three of four, Repair swarm from three of four. The chair's work was settling the splits, correcting the firepower math against the code, and picking the name.

## The final design

d_totality: {n: 'Eclipse totality', cls: 'Battleship', fac: 'deathless', size: 1.0, cp: 6, hp: 260, sh: 0, rg: 0, ar: .35, sp: 2, tn: 1, ev: 0, w: [['gauss','T'],['gauss','T'],['doom','F'],['doom','F'],['gsentry','T']], ab: 'reclaim', regen: 5, reanimate: true}

- Refit slots 3, automatic at CP 5 or more. Cost is computed, never stored: base 370 at CP 6, times the battleship multiplier. On main as shipped that is 590. Once the FS-2 fix below lands it is 630.
- Regen is 5 on main. Built on the Job 3 package v2 numbers (branch rules15), it is 4, one above the v2 zenith at 3, well below The Unsetting at 8.
- Role: the fleet anchor the zenith cannot be. It holds the centre under fire that pushes a 145 hull cruiser back, its paired Corona arcs fire as one volley (the identity shot), and Repair swarm restores 52 hull on itself or 29 on a zenith beside it, so the cruiser becomes the mobile second repairer. It never scouts, chases, or sits alone among squadrons: speed 2, evasion 0, one spire for self defence only.

## Chair firepower (settles the leg dispute)

The legs split on how to average the Corona arc's cooldown 2, and the code settles it. Firing sets the weapon's counter to its cooldown value (battle.js:763), and the counter ticks down once at round start (battle.js:382). A cooldown 2 weapon therefore fires every third turn, and a cooldown 3 ability every fourth. Qwen used this divisor; DeepSeek and the Rey leg used two. All figures below are the chair's, recomputed from data.js on one convention: accuracy applied, cooldowns averaged on the code's cadence, point defence counted against capital targets at its vsCap multiplier of .6, armour, pierce, crits and range falloff left out. Labelled rough throughout.

- One Null cannon: 13.3 per turn. One Corona arc: 31.2 on a firing turn, 10.4 averaged. Null spire against a capital target: 3.8. Null shredder against a capital target: 4.3.
- Eclipse zenith (cruiser): 40.9 per turn averaged.
- Eclipse totality: 51.3 per turn averaged, and about 92.9 expected on an arc turn (cannons 26.6, arcs 62.4, spire 3.8).
- Bastion (Crusade battleship): 45.9 per turn against one target. Only one of its two broadsides bears at a time; split across two targets it totals 71.1.
- Dominion (Hegemony battleship): 33.4 per turn against one target, about 38.3 counting its fighter wing.
- The Unsetting (boss): 41.4 per turn from guns, about 51.4 counting the Spinal cannon averaged over its cooldown.

Reading: the totality outshoots both player battleships per turn and matches the boss's total output rate. That is the R63 premium (stronger but dearer) made visible, and it is bought with CP 6 and the highest price in the game. The boss keeps its real edges: 480 hull, regen 8, and the Spinal cannon stays exclusive. One watch item for the playtest: if a totality and a zenith repairing each other proves too sticky, the first lever is regen 5 down to 4 on main, not hull.

## Where the chair broke the splits

1. Name: Eclipse totality, id d_totality. Qwen and Argon both proposed penumbra, and it is the runner-up. Penumbra is the partial shadow, the lighter region where the sun is only partly covered; totality is the eclipse complete, the darkest word in the set, and the right top of the mote, flare, zenith ladder. Nadir and umbra are already Eclipse admiral ranks, so they are out. Wane (DeepSeek) is a dimming, which reads as a step down for the heaviest hull.
2. Point defence: the Null spire, not the Null shredder (legs split two and two). The shredder stays The Unsetting's signature for now, the spire's range 3 covers the lighter hulls sheltering behind the fan (the anchor's actual job), and the mount carries up from the cruiser unchanged.
3. Ability: Repair swarm, three of four legs. It scales on its own (20 percent of 260 is 52), needs no new code, and the anchor sits inside its own fleet, where the Spinal cannon's friendly fire punishes exactly this ship. Spinal cannon on a purchasable hull also blurs the flagship. It stays an owner question below because Qwen argued it well.
4. Size 1.0. Above both shipped player battleships (.95 Bastion, .98 Dominion), far below The Unsetting (1.3), so the flagship keeps the silhouette.

## FS-2 resolution (unanimous, adopted)

On rules15 the Job 3 v2 rises took the deathless multipliers to Frigate 1.55, Destroyer 1.6, Cruiser 1.65, but Battleship stayed 1.6, so the battleship multiplier sits below the cruiser's and the R1 FS-2 ladder (data.js:540) breaks in multiplier terms. All four legs found it independently. Fix: raise the deathless Battleship multiplier to 1.7 in the same change that lands package v2. The ladder reads 1.55, 1.6, 1.65, 1.7, and this hull computes to 630, clearing the zenith on both branches (390 main, 415 rules15). An explicit cost override was rejected by every leg: it breaks the link between CP and price if the hull is retuned.

## The look (adopted)

A broad sunshade that happens to be a ship. The forward two thirds wear a wide fan of overlapping dark violet-black armour plates in three tiers, like a heat shield held in front of a low, flat bellied hull that shelters behind and under it. Two firing notches are cut into the fan's inner petals so the Corona emitters fire straight ahead without clipping the shield. The fan is the .35 armour made visible; its leading edge carries a thin white-gold corona rim, the only bright line on the front, with violet-white glow in the seams between plates. Behind the fan: a low command blister, an armoured Archive core housing showing a white-gold core through narrow slits, blunt antenna rods, dark radiator fins with faint violet-white edges. At the rear, two engine bells in a matched pair, each inside an eclipse ring, a dark disc with a white-gold rim, dark inside with no flame. Palette: dark violet-black plates, white-gold corona, violet-white inner glow, cold white repair swarms.

Warning, flagged by all four legs: the shipped FAC3D palette line at data.js:126 still reads grey-green hull, green trim, green glow. It is stale, contradicts the lore bible and the Job 2 Eclipse package, and this hull must not be built from it. No green anywhere near Eclipse.

## Concept image prompts (adopted set)

Top view: "Top view concept art, orthographic, a large space warship against plain black. A broad fan of overlapping dark violet-black armour plates in three tiers shelters a low flat hull. Matched pairs: turreted guns on saddle mounts at the fan shoulders, forward projector housings with white-gold rings. One central spire, blunt antenna rods, two rear engine bells each inside a dark disc ringed with white-gold light. Palette: dark violet-black, white-gold trim, faint violet-white glow in the seams. Studio light from above. No naval features, no green, no text."

Side view: "Side view concept art, orthographic profile, a large space warship against plain black. A three tier fan of dark violet-black plates rises at the front like a heat shield, a low hull with an armoured flat belly behind it. One turreted gun aimed forward, one forward projector housing with a white-gold ring, dark radiator fins, one dark engine bell inside a ring of white-gold light, no flame. A white-gold core glows through slits under the fan. Palette: dark violet-black, white-gold, violet-white. Studio side light. No naval features, no green, no text."

Three quarter view: "Three quarter view concept art, front and above at 45 degrees, a large space warship against black space. A broad sunshade fan of layered dark violet-black plates fills the front, edged in white-gold light, violet-white glow in the seams. Matched pairs of turreted guns and forward projector housings, a central spire, blunt antenna rods, rear engine bells each inside a dark disc with a white-gold rim, one white-gold core under the fan. Palette: dark violet-black, white-gold, violet-white only. Eclipse rim lighting. No naval features, no green, no text."

## Hand built parts list (adopted)

Guns:
- Null cannon turrets, left and right: saddle mounts on the fan shoulders, a matched pair.
- Corona arc emitters, left and right: short housings on the forward hull behind the fan's firing notches, a matched pair.
- Null spire: ball mount, centreline spine; single part.

Bridge and superstructure tiers:
- Command blister: low tier, column mount behind the fan, visor slit.
- Fan tier steps: three plate tiers, each seated on the last.

Masts and funnels, as space parts:
- Antenna array: blunt rods on a low housing behind the spire.
- Radiator panels: finned pair, recessed frames, fan rear face.

Tanks, drums and cylinders:
- Archive core housing: armoured cylinder, saddle cradle under the fan centre.
- Coolant pods: smooth pair, plate mounts, forward hull.

Forward hull shape:
- Fan leading edge: clean chined rim, corona trim line.
- Flat belly and chines: underside flat, angled chine panels each side.

Engine nozzles:
- Main engine bells, left and right: dark bells in eclipse ring mounts.
- Thruster pods: pair on plate mounts at the rear corners.

Armour stacks:
- Sunshade plate leaves: fan stack, rebuilt leaf by leaf.
- Side armour sponsons: solid pair carrying the turret saddles.

Sponson blocks:
- Turret sponsons, left and right: solid blocks faired into the fan.

Thin spiky debris:
- Generator spikes on fan edge and spine: removed, or replaced with blunt rods.

## Leg screening

DeepSeek (Eclipse wane, d_wane): sound, and closest to the final design on loadout and price. Errors: averaged the Corona arc on a two turn cycle, counted the Null spire at full value against capital ships, called the shipped starting fleets "admiral styles", and justified Repair swarm as healing more than "on a frigate or destroyer" when only the cruiser carries it today. Its armour .32 and size .96 were not adopted.

Qwen (Eclipse penumbra, d_occult): the durability parity argument is genuinely good (250 raw hull against the Bastion's 250 and the Dominion's 262 effective pools), and the chair's 260 sits inside its logic. Its cooldown divisor of three is the one the code supports. Not adopted: the Spinal cannon as the main ability, and a Null shredder mounted on a ventral aft ball as a single unpaired rear part, which sits badly with the matched pair and never aimed backward ship rules. This leg is filed from a chair transcription of the browser return, tables flattened into prose lines; the wording is substantively the model's.

Blind Rey leg (Eclipse totality, d_totality): adopted as the spine, including the name. It alone caught the nadir rank collision unprompted. Its firepower used the same two turn cycle as DeepSeek and excluded point defence entirely; both corrected in the chair figures above.

Argon (Eclipse penumbra, d_sepulcher): filed as a record, never a source for numbers, per the standing rule for Jobs 7 to 9. To its credit it flagged its own Bastion and Dominion figures as inferences from assumed values; the chair replaces them (its Dominion guess lands near the real figure by luck, its Bastion figure is well low). Its invented Corona shroud ability carries an unverified code cost estimate and was not considered. It repeats the "admiral styles" mislabel.

## Owner questions

1. The name. Chair pick: Eclipse totality. Alternative: Eclipse penumbra (two legs). Totality completes the ladder in the eclipse's darkest word; penumbra is the partial shadow and reads lighter.
2. The ability. Chair pick: Repair swarm, the repair hub. Alternative: Spinal cannon, the flagship's gun, with friendly fire, on a purchasable hull (Qwen's main design).
3. The weight. Chair pick: CP 6 and 630 credits, the strongest line hull in the game, priced like it. Alternative: CP 5 at about 525, earlier and oftener, with hull or armour trimmed to stay fair.
4. Point defence. Chair pick: Null spire (range 3, covers the fleet). Alternative: Null shredder, shared with The Unsetting.

## Build notes for Opus

- Hull line goes with the Eclipse roster in data.js (the pack's anchors: data.js:98 to 101). Every weapon, ability and trait on it is shipped content recombined.
- FAC_PRICE: raise deathless Battleship from 1.6 to 1.7 in the same change that lands Job 3 package v2, so this hull computes to 630 and the FS-2 ladder holds.
- Do not copy the FAC3D palette at data.js:126; the bible palette governs (see the look section).
- No simulator run was done on the new hull in this job; matrix validation belongs with the v2 landing and the playtest.

## Not checked

- The exact hull fraction Archive restore returns at was not in the pack and was not traced in code here.
- The ability cooldown cadence is inferred from the same counter pattern the weapons use (abilityCd at battle.js:1057 was read; its decrement site was not separately traced). The weapon cadence is code verified.
- Whether twin Corona arcs unbalance boss escort fights is a playtest question, flagged as the watch item above, not settled here.
