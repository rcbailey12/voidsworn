## 1. Headline

The Eclipse totality is a line anchor: a slow, heavily armoured battleship that holds the centre of an Eclipse fleet, repairs the ships around it, and fires a paired Corona arc volley that can break a heavy target in one firing turn. Its defining strength is staying power with no shields: 260 hull, top line armour, regen, and Archive restore if it falls as a non flagship. Its defining cost is literal: command points 6 and 630 credits, the dearest non boss hull in the game.

## 2. Role in the fleet

The zenith cannot anchor a fleet: at 145 hull it cannot sit under concentrated fire, its single Corona arc threatens rather than kills, and its Repair swarm is usually spent saving itself. The totality does three things it cannot. It holds the middle: 260 hull, armour .35, and regen take fire that would push a zenith back. Its paired arcs fire together, removing one heavy ship or gutting a boss escort in one firing turn. And it is a repair hub that need not hide: Repair swarm restores 52 hull on itself, 29 on a zenith beside it.

A fleet with one has a hard centre and a folding edge: totality (6) in the middle, a zenith (4) beside it, a flare (2) and two motes (1 each) folding through rocks and wrecks for the flanks and the squadron screen, 14 command points. Few hulls, every loss felt, Archive restore returning the first non flagship loss.

It should never scout, chase, or raid alone: speed 2 and evasion 0 catch nothing and dodge nothing. It should never sit among enemy squadrons on the strength of one Null spire, self defence, not a specialism. And never the deliberate first fall: Archive restore on a mote is a bonus; on a 630 credit hull exposed on purpose, it is how a run ends.

Admiral styles: best for the pack's heavy starts, a zenith plus a flare, or a zenith plus two motes, and the restore minded style most of all. Least for the light fold heavy starts, two flares and two motes, which win by movement.

## 3. Stat block

d_totality: {n: 'Eclipse totality', cls: 'Battleship', fac: 'deathless', size: 1.05, cp: 6, hp: 260, sh: 0, rg: 0, ar: .35, sp: 2, tn: 1, ev: 0, w: [['gauss','T'],['gauss','T'],['doom','F'],['doom','F'],['gsentry','T']], ab: 'reclaim', regen: 5, reanimate: true, slots: 3, final price: 630 (computed, see below)}

- Size 1.05: above the zenith (.82), the Bastion (.95) and the Dominion (.98); below The Unsetting (1.3), so the flagship still owns the silhouette.
- CP 6: matches the Dominion, one above the Bastion (5), two above the zenith (4): R63 in command points, Eclipse paying more for the same class.
- HP 260: the key number. The Bastion's real pool is 220 hull plus 30 shields, 250; the Dominion's is 230 plus 32, 262. Eclipse has no shields, so 260 hull levels this ship's pool with theirs, far above the zenith's 145, far below The Unsetting at 480. The pool renews by regen, slower than shield regen: the intended weakness.
- Shields 0, shield regen 0: no Eclipse hull has shields; adding one is a ruling level change.
- Armour .35: matches The Unsetting, above the zenith and Bastion (.3) and the Dominion (.25). Eclipse holds K-1 Kharon, the armour core; armour plus hull is its whole defence.
- Speed 2, turn 1, evasion 0: identical to the zenith and both shipped battleships. The boss stays distinct at speed 1.
- Regen 5: one step above the zenith (4), well below The Unsetting (8). On rules15, where Eclipse regens dropped by 1, this reads 4 against the zenith's 3.
- Reanimate true: every non boss Eclipse hull carries it; Archive restore never applies to a flagship or boss.
- Slots 3: automatic at CP 5 or more.
- Cost: Eclipse hulls store no explicit cost (inference from the pack), so 630 is computed, not stored.

Price arithmetic in full. Base cost at CP 6 is 60 times 6 plus 10, 370. On main the battleship multiplier is 1.6: 370 times 1.6 is 592, rounded to the nearest 5, 590. On rules15 the multiplier is still 1.6, so again 590, but the cruiser multiplier there is 1.65, so the battleship multiplier sits below the cruiser's, breaking the FS-2 ladder in multiplier terms (R1 FS-2, data.js:540). Resolution: raise the battleship multiplier to 1.7 wherever the Job 3 v2 multipliers land. Then 370 times 1.7 is 629, rounded to 630, the price in the block. It clears the zenith on both branches (390 main, 415 rules15), satisfies FS-2 in price and multiplier order, and completes a rising ladder either way: 1.45, 1.5, 1.55, 1.7, or 1.55, 1.6, 1.65, 1.7. Against the Bastion's 340 and the Dominion's 370, it is much dearer, per R63. An explicit cost override was rejected: it breaks the CP formula link if the hull is retuned.

## 4. Weapons and ability

Loadout: two Null cannons on turrets, two Corona arcs on the forward hull, one Null spire on a turret. Turreted cannons mean the anchor never turns its hull to keep firing, which matters at turn 1. The paired arcs are the identity: two lance kind hits of 40 on one firing turn, a volley, not a drizzle. The spire is self defence against squadrons. No Null shredder: today only The Unsetting carries it.

Rough firepower: expected damage per turn against capital ships, accuracy applied, cooldowns averaged, crits, pierce and falloff left out, point defence excluded. One Null cannon: 3 shots times 6 damage times 74 percent, about 13.3. One Corona arc: 40 times 78 percent, divided by its 2 turn cooldown, about 15.6.

- Zenith: two Null cannons (26.6) plus one arc (15.6), about 42 per turn.
- Totality: two Null cannons (26.6) plus two arcs (31.2), about 58 per turn, near 37 percent above the zenith, in bursts: about 89 on an arc turn, about 27 between.
- The Unsetting: about 42 per turn from guns, like the zenith; its power sits in 480 hull, regen 8, and Spinal cannon. The totality outgunning it on guns alone is this design's one tension.

The pack supplies no weapon damage numbers for the Bastion or the Dominion, so no like for like figure exists and none is invented. On mounts: each brings two broadsides of which one side bears at a time, plus a forward heavy gun and point defence; the Dominion adds a hangar. The totality brings four anti capital mounts that all bear in one firing turn, no hangar, no shield ability: the hardest single volley of the three, the least flexible.

Ability: Repair swarm (reclaim), inherited from the zenith. It scales by itself, 20 percent of a bigger hull being more hull, 52 here, with no new numbers. The anchor stands within 3 hexes of its own line, so it is the natural repair hub, and the zenith becomes the mobile second repairer. Spinal cannon stays where the pack places it, on the flagship and the Crusade dreadnought; a purchasable hull carrying it blurs the flagship, and its friendly fire punishes a ship built to sit inside its own fleet. Fold skip is a small ship's tool. No new ability: one would cost design, code, and a balance pass, and the role needs none.

## 5. Name

Display name: Eclipse totality. The pattern is Eclipse plus one lowercase noun from light and its absence: a mote in a sunbeam, a flare, the zenith as the sun's highest point. Totality is the moment an eclipse is complete, the sun fully covered: the biggest, darkest word in the set, an eclipse's own word, carrying the lost sun motif without touching glass, reflection, or song.

Data id: d_totality. The existing ids do not match their display names, so a matching id breaks no rule.

Class label: Battleship. The Dominion's class label is Battleship despite its name, and R63 rules a battleship class hull; a new label costs pricing and display work for nothing.

Runner up: Eclipse nadir, the sun's lowest point, zenith's opposite. It lost twice over: Nadir is already the faction's top rank, so one word would name a ship and a rank in the same screens, and a ladder ending downward reads as a step back for the heaviest hull.

## 6. The look

Silhouette: a broad sunshade that happens to be a ship. The forward two thirds wear a wide fan of overlapping armour plates in three tiers, like a heat shield held in front of the hull. The hull shelters behind and under it: low, flat bellied, chined at the sides, wider than it is tall, nothing that reads as a sea ship. The fan is the .35 armour made visible; its leading edge carries a thin white-gold corona rim, the only bright line on the front, and violet-white glow sits in the seams between plates.

Guns sit on visible mounts, aimed forward or outward, never backward. The Null turrets form a matched pair on saddle mounts on the fan's shoulders. The Corona emitters form a matched pair low on the forward hull, short housings with white-gold rings, aimed straight forward. The Null spire stands alone on a ball mount on the spine behind the fan.

At the rear, two engine bells in a matched pair, each inside an eclipse ring, a dark disc with a white-gold rim: the drive reads as two small eclipses. No flaming bells: dark inside, lit by rim and glow. Thruster pods pair at the rear corners. Radiators are dark fins with faint violet-white edges, in recessed frames on the fan's rear face and sides. Sensors are an antenna array, not a mast: short housings and blunt rods behind the spire, plus paired pods under the forward hull. The Archive core shows once, under the fan's centre, a white-gold core through narrow slits in an armoured housing.

Palette and warning: dark violet-black plates, white-gold corona, violet-white inner glow, cold white repair swarms, per the bible and the package. The shipped palette line at data.js:126 still reads grey-green hull, green trim, green glow. It is stale, contradicts both sources, and this hull must not be built from it. No green anywhere.

## 7. Concept image prompts

Top view: "Top view concept art, orthographic, a large space warship against plain black. A broad fan of overlapping dark violet-black armour plates in three tiers shelters a low flat hull. Matched pairs: turreted guns on saddle mounts at the fan shoulders, forward projector housings with white-gold rings. One central spire, blunt antenna rods, two rear engine bells each inside a dark disc ringed with white-gold light. Palette: dark violet-black, white-gold trim, faint violet-white glow in the seams. Studio light from above. No naval features, no green, no text."

Side view: "Side view concept art, orthographic profile, a large space warship against plain black. A three tier fan of dark violet-black plates rises at the front like a heat shield, a low hull with an armoured flat belly behind it. One turreted gun aimed forward, one forward projector housing with a white-gold ring, dark radiator fins, one dark engine bell inside a ring of white-gold light, no flame. A white-gold core glows through slits under the fan. Palette: dark violet-black, white-gold, violet-white. Studio side light. No naval features, no green, no text."

Three quarter view: "Three quarter view concept art, front and above at 45 degrees, a large space warship against black space. A broad sunshade fan of layered dark violet-black plates fills the front, edged in white-gold light, violet-white glow in the seams. Matched pairs of turreted guns and forward projector housings, a central spire, blunt antenna rods, rear engine bells each inside a dark disc with a white-gold rim, one white-gold core under the fan. Palette: dark violet-black, white-gold, violet-white only. Eclipse rim lighting. No naval features, no green, no text."

## 8. Hand built parts list

Guns:
- Null cannon turrets, left and right: saddle mounts on the fan shoulders, a matched pair.
- Corona arc emitters, left and right: short housings on the forward hull, a matched pair.
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

## 9. Owner questions

Question 1. How heavy should it be in the fleet budget?
Option A (recommended): CP 6 and 630 credits, as designed. The strongest line hull in the game, its price felt in every fleet.
Option B: CP 5 and about 525 credits (base 310 times 1.7). Earlier and oftener, but hull or armour would need trimming to stay fair.
Recommended: A. R63 makes Eclipse pay more in command points as well as credits.

Question 2. Which ability should it carry?
Option A (recommended): Repair swarm, from the cruiser. Your biggest ship becomes the repair hub; the cruiser roams.
Option B: Spinal cannon, like the flagship. A huge area shot that can hit your own ships, and the flagship loses her unique weapon.
Recommended: A. The anchor sits inside its own fleet; friendly fire punishes that.

Question 3. How should the Corona arcs fire?
Option A (recommended): Both together. Every second turn, a volley that can break a heavy ship.
Option B: One arc plus a third Null turret. Steadier damage, no volley moment, plays like a bigger cruiser.
Recommended: A. The volley is the moment this ship exists for.

Question 4. What should lead in the look?
Option A (recommended): The sunshade fan. A wall of dark plates with a gold rim.
Option B: The eclipse ring engines. It reads from behind, all rings and glow, plainer in front.
Recommended: A. You spend most battles looking at its front.

Question 5. The name?
Option A (recommended): Eclipse totality, completing the ladder in the eclipse's darkest word.
Option B: Eclipse nadir, already the top admiral rank, so one word names a ship and a person.
Recommended: A, for the clean ladder.

## 10. Not checked

I did not read the code; every code claim rests on the pack's anchors (data.js:98 to 101, 126, 138, 145, 146, 539 to 547). The no explicit cost point is my inference from the pack's pricing section. No Bastion or Dominion weapon numbers or point defence multiplier are in the pack, so none are filled in. Job 3 v2 changes, Archive restore's fraction, starting fleets, name pools, motif ownership, and the package look are taken on trust. Extra work for fleet builders, shipyards, or variants is not established and not priced here.
