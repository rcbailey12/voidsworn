# corsair_A20 parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/hullbreakers/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing, and its job: what it does on the ship (R221: a part with no job is cut). Source:
`tools/blender/build_sheets/ships/corsair_A20_inv.py`.

| ID | Job | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---|---:|---|---|---|
| hull_form | the hulk-carrier's hull: a wide flat slab built round the hangar block | hull | the wide flat slab, its port side stepped in at the hangar block, chamfered at both ends | 1 | bow/top, bow/side, mid/top, mid/side, stern/top, stern/side | bevels, steps (the recess), an overhang (the lintel) | picture |
| bow_block | the armoured bow block: carries the intakes and the bow grabbers, takes the first hits | tier | the bow block in front of the body, as tall as the slab and about half its beam, housing the two intake tubes | 1 | bow/top, bow/side | a face, a roof, openings (the intakes) | picture |
| bow_plates | armour | plate | plates over the bow block | 1 | bow/top, bow/side | slabs with steps, bevels, rivets | picture |
| intakes | the family's face: scoop gas and dust for the reactor and the squadrons' fuel | tube | two huge intake tubes side by side filling the bow block's face, each three quarters of its height | 2 | bow/side, bow/top | tubes with depth, hooded lips, bands, bolts, stiffeners, dark bores | picture |
| scoop | the wake-sniffer scoop | tube | a small scoop with a grille under the chin (designs.md: one chin scoop) | 1 | bow/below, bow/side | ribbed drum, bands, rolled lip, a grille in a dark mouth | designed |
| grabbers | boarding grabbers: pin a prize at the bow | claw_arm | a pair of grabber arms under the bow block (designs.md: four bow arms; two here, so the jaw is not A17's) | 2 | bow/below, bow/side | shoulder hinges on brackets, box segments, knuckles, rams, forked pincers | designed |
| dishes | listening dishes: find prey and call the squadrons home | dish | two dishes of uneven size on the body's front shoulders | 2 | bow/top, bow/side | ribbed bowls with rims, feed horns on struts, yokes, posts, bases | picture |
| hull_plates | armour, salvaged and mismatched | plate | patch plating over the whole hull, many in trophy colours | 1 | bow/top, bow/side, mid/top, mid/side, stern/top, stern/side | slabs with steps, bevels, rivets | picture |
| thrusters | attitude thrusters: turn the slow hulk (turn 1 in data.js) | thruster | attitude thruster quads on the bow block and the stern | 4 | bow/side, stern/side | a block, splayed nozzles | designed |
| hangar_block | the hangar block: sill, lintel and the plate between the two mouths | tier | the port flank's hangar block round the two mouths | 1 | mid/side, bow/side, mid/top | a face, a roof, openings (the mouths) | picture |
| hangar_plates | armour | plate | plates over the sill, the lintel and the plate between the mouths | 1 | mid/side | slabs with steps, bevels, rivets | picture |
| hangars | data.js launch and hangar 2: the two mouths the squadrons launch from | hangar | two big open hangar mouths on the port flank, three quarters of its height, uneven, dark inside, framed in torn plate, doors slid clear (Ryan's ruling: both on the port flank) | 2 | mid/side, bow/side | a rim, torn plate teeth, door leaves with stiffeners, rails on brackets, launch rails, ceiling beams, lamps, an inner blast door, wall ribs | picture |
| craft | the squadrons the Den launches (data.js hangar 2), and the scale | craft | a cobbled fighter nosing out of the forward mouth, a second parked in the aft one | 2 | mid/side | a fuselage, a canopy, mismatched wings, nozzles with a glow, nose guns, skids, a patch | picture |
| turrets | data.js turret T, twice: the dorsal turrets that keep escorts off the hulk | gun | two twin dorsal turrets, one on the fore deck tier, one on the aft (the picture shows no turret; data.js gives two) | 2 | bow/top, stern/top, mid/side | turret rings, faceted housings, mantlets, breeches, barrels with sleeves and brakes | designed |
| deck_tiers | the salvage deck: stacked plate over the hangar decks | tier | three low tiers of stacked plate on the deck | 1 | bow/top, mid/top, stern/top | a face, a roof, an edge | picture |
| spare_bell | a spare engine bell for field repairs (designs.md) | engine | a spare engine bell lying across the deck in a cradle, cold | 1 | mid/top, mid/side | a banded housing, a bell with a lip, a throat, a cone, cooling rings, struts, a collar | picture |
| salvage | loot and stores stowed on deck, bolted down | hatchbox | salvage lockers bolted on the deck | 6 | bow/top, mid/top, stern/top | a framed box, an inset lid, side ribs | picture |
| deck_hatches | deck access to the hangar decks and the holds | hatch | a round and a square deck hatch | 2 | bow/top, mid/top | a rim, a door, a seam, hinges | picture |
| wall_bricks | armour bricks on the closed starboard wall | tier | four big bricks on the starboard flank | 1 | bow/side, mid/side, stern/side | a face, a roof, an undercut | picture |
| trophy | armour, and the pack's boast | patch | pale Hegemony and violet Eclipse trophy plates, a red patch, bolted flat | 6 | mid/side, mid/top, bow/top, stern/top, stern/side | crooked slabs, a lifted corner, rivets | picture |
| lamps | running lights: the squadrons find the mouths by them (sparse and dim) | lamp | dim red lamps on both flanks and the bow block | 8 | bow/side, mid/side, stern/side | hooded housings, red lenses | picture |
| belly_plates | armour under the hull | plate | flat armoured belly with chines (the picture shows no underside) | 1 | bow/below, mid/below, stern/below | slabs with steps and rivets | designed |
| engines | main thrust (a slow hulk: speed 2) | engine | five mismatched bells in a row along the top of the stern, one in a violet trophy housing | 5 | stern/side, stern/top, stern/below | banded housings, bells with lips, throats, inner cones, cooling rings, struts, collars | picture |
| stern_frame | the frame the bell row hangs from | pylon | the frame along the top of the stern, and the violet bell housing | 1 | stern/top, stern/side | a web with plates | picture |
| grapples | heavy grapple arms: drag prizes alongside to the hangar mouths | claw_arm | two heavy grapple arms folded flat under the stern quarters (designs.md) | 2 | stern/below, stern/side | shoulder hinges on brackets, box segments, knuckles, rams, forked pincers | designed |
| vents | shed engine-room heat | vent | louvre panels in the starboard wall aft | 2 | stern/side | frames, slats | designed |
| antenna | comms: calls the squadrons home | antenna | an antenna array on the aft deck (the picture's small dishes and masts on the aft deck) | 1 | stern/top, stern/side | a base, a mast, whips, a pod (never a crossbar mast) | picture |

Kit sub-parts per type (what DETAILED checks):

- antenna: base, mast, whip, pod
- claw_arm: bracket, hinge, plate, pin, arm, rivet, ram, joint, wrist, finger
- craft: fuselage, canopy, wing, nozzle, glow, barrel, skid, patch
- dish: bowl, rib, feed, strut, yoke, post, base
- engine: housing, collar, band, bell, lining, throat_glow, cone, cool, strut
- gun: ring|plate, housing, mantlet, breech, tube, clamp, bore, vent
- hangar: rim, tooth, door, stiff, rail, bracket, lrail, beam, lamp, inner, rib
- hatch: rim, door, seam, hinge
- hatchbox: frame, lid, rib
- hull: bevel, step, overhang
- lamp: housing, hood, lens
- patch: slab, lift, rivet
- plate: slab, step, bevel, rivet
- pylon: web, plate
- thruster: block, nozzle
- tier: face, roof, opening
- tube: tube, bore, band, ring, bolt, stiff
- vent: frame, slat

Left as surface, and why:

- Grime, rust streaks, scratches, worn edges and decals: surface texture, painted in the build (recipe stage 5), not modelled.
- designs.md's two bow casemates, two starboard flank guns and its rocket rack: data.js c_hulk carries two dorsal turrets only; a gun with no slot has no job (R221).
- The picture's loose junk on the deck: stacked into tiers and bolted-down lockers (Ryan R185: nothing hangs off the ship).

## Every built part has a job (R221)

Built kit parts: 68; parts whose inventory id names no line with a job: 0.

## Per cell: present, shaped, detailed (from the model, corsair_A20_model.json)

Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.

### bow/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| hull_form | the wide flat slab, its port side stepped in at the hangar block, cham | 1 / 1 | Y | Y | Y |
| bow_block | the bow block in front of the body, as tall as the slab and about half | 1 / 1 | Y | Y | Y |
| bow_plates | plates over the bow block | 7 / 1 | Y | Y | Y |
| intakes | two huge intake tubes side by side filling the bow block's face, each  | 2 / 2 | Y | Y | Y |
| dishes | two dishes of uneven size on the body's front shoulders | 2 / 2 | Y | Y | Y |
| hull_plates | patch plating over the whole hull, many in trophy colours | 1 / 1 | Y | Y | Y |
| turrets | two twin dorsal turrets, one on the fore deck tier, one on the aft | 2 / 2 | Y | Y | Y |
| deck_tiers | three low tiers of stacked plate on the deck | 1 / 1 | Y | Y | Y |
| salvage | salvage lockers bolted on the deck | 6 / 6 | Y | Y | Y |
| deck_hatches | a round and a square deck hatch | 2 / 2 | Y | Y | Y |
| trophy | pale Hegemony and violet Eclipse trophy plates, a red patch, bolted fl | 6 / 6 | Y | Y | Y |

### bow/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| hull_form | the wide flat slab, its port side stepped in at the hangar block, cham | 1 / 1 | Y | Y | Y |
| bow_block | the bow block in front of the body, as tall as the slab and about half | 1 / 1 | Y | Y | Y |
| bow_plates | plates over the bow block | 7 / 1 | Y | Y | Y |
| intakes | two huge intake tubes side by side filling the bow block's face, each  | 2 / 2 | Y | Y | Y |
| scoop | a small scoop with a grille under the chin | 1 / 1 | Y | Y | Y |
| grabbers | a pair of grabber arms under the bow block | 2 / 2 | Y | Y | Y |
| dishes | two dishes of uneven size on the body's front shoulders | 2 / 2 | Y | Y | Y |
| hull_plates | patch plating over the whole hull, many in trophy colours | 1 / 1 | Y | Y | Y |
| thrusters | attitude thruster quads on the bow block and the stern | 4 / 4 | Y | Y | Y |
| hangar_block | the port flank's hangar block round the two mouths | 1 / 1 | Y | Y | Y |
| hangars | two big open hangar mouths on the port flank, three quarters of its he | 2 / 2 | Y | Y | Y |
| wall_bricks | four big bricks on the starboard flank | 1 / 1 | Y | Y | Y |
| lamps | dim red lamps on both flanks and the bow block | 8 / 8 | Y | Y | Y |

### bow/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| scoop | a small scoop with a grille under the chin | 1 / 1 | Y | Y | Y |
| grabbers | a pair of grabber arms under the bow block | 2 / 2 | Y | Y | Y |
| belly_plates | flat armoured belly with chines | 1 / 1 | Y | Y | Y |

### mid/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| hull_form | the wide flat slab, its port side stepped in at the hangar block, cham | 1 / 1 | Y | Y | Y |
| hull_plates | patch plating over the whole hull, many in trophy colours | 1 / 1 | Y | Y | Y |
| hangar_block | the port flank's hangar block round the two mouths | 1 / 1 | Y | Y | Y |
| deck_tiers | three low tiers of stacked plate on the deck | 1 / 1 | Y | Y | Y |
| spare_bell | a spare engine bell lying across the deck in a cradle, cold | 1 / 1 | Y | Y | Y |
| salvage | salvage lockers bolted on the deck | 6 / 6 | Y | Y | Y |
| deck_hatches | a round and a square deck hatch | 2 / 2 | Y | Y | Y |
| trophy | pale Hegemony and violet Eclipse trophy plates, a red patch, bolted fl | 6 / 6 | Y | Y | Y |

### mid/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| hull_form | the wide flat slab, its port side stepped in at the hangar block, cham | 1 / 1 | Y | Y | Y |
| hull_plates | patch plating over the whole hull, many in trophy colours | 1 / 1 | Y | Y | Y |
| hangar_block | the port flank's hangar block round the two mouths | 1 / 1 | Y | Y | Y |
| hangar_plates | plates over the sill, the lintel and the plate between the mouths | 3 / 1 | Y | Y | Y |
| hangars | two big open hangar mouths on the port flank, three quarters of its he | 2 / 2 | Y | Y | Y |
| craft | a cobbled fighter nosing out of the forward mouth, a second parked in  | 2 / 2 | Y | Y | Y |
| turrets | two twin dorsal turrets, one on the fore deck tier, one on the aft | 2 / 2 | Y | Y | Y |
| spare_bell | a spare engine bell lying across the deck in a cradle, cold | 1 / 1 | Y | Y | Y |
| wall_bricks | four big bricks on the starboard flank | 1 / 1 | Y | Y | Y |
| trophy | pale Hegemony and violet Eclipse trophy plates, a red patch, bolted fl | 6 / 6 | Y | Y | Y |
| lamps | dim red lamps on both flanks and the bow block | 8 / 8 | Y | Y | Y |

### mid/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| belly_plates | flat armoured belly with chines | 1 / 1 | Y | Y | Y |

### stern/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| hull_form | the wide flat slab, its port side stepped in at the hangar block, cham | 1 / 1 | Y | Y | Y |
| hull_plates | patch plating over the whole hull, many in trophy colours | 1 / 1 | Y | Y | Y |
| turrets | two twin dorsal turrets, one on the fore deck tier, one on the aft | 2 / 2 | Y | Y | Y |
| deck_tiers | three low tiers of stacked plate on the deck | 1 / 1 | Y | Y | Y |
| salvage | salvage lockers bolted on the deck | 6 / 6 | Y | Y | Y |
| trophy | pale Hegemony and violet Eclipse trophy plates, a red patch, bolted fl | 6 / 6 | Y | Y | Y |
| engines | five mismatched bells in a row along the top of the stern, one in a vi | 5 / 5 | Y | Y | Y |
| stern_frame | the frame along the top of the stern, and the violet bell housing | 1 / 1 | Y | Y | Y |
| antenna | an antenna array on the aft deck | 1 / 1 | Y | Y | Y |

### stern/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| hull_form | the wide flat slab, its port side stepped in at the hangar block, cham | 1 / 1 | Y | Y | Y |
| hull_plates | patch plating over the whole hull, many in trophy colours | 1 / 1 | Y | Y | Y |
| thrusters | attitude thruster quads on the bow block and the stern | 4 / 4 | Y | Y | Y |
| wall_bricks | four big bricks on the starboard flank | 1 / 1 | Y | Y | Y |
| trophy | pale Hegemony and violet Eclipse trophy plates, a red patch, bolted fl | 6 / 6 | Y | Y | Y |
| lamps | dim red lamps on both flanks and the bow block | 8 / 8 | Y | Y | Y |
| engines | five mismatched bells in a row along the top of the stern, one in a vi | 5 / 5 | Y | Y | Y |
| stern_frame | the frame along the top of the stern, and the violet bell housing | 1 / 1 | Y | Y | Y |
| grapples | two heavy grapple arms folded flat under the stern quarters | 2 / 2 | Y | Y | Y |
| vents | louvre panels in the starboard wall aft | 2 / 2 | Y | Y | Y |
| antenna | an antenna array on the aft deck | 1 / 1 | Y | Y | Y |

### stern/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| belly_plates | flat armoured belly with chines | 1 / 1 | Y | Y | Y |
| engines | five mismatched bells in a row along the top of the stern, one in a vi | 5 / 5 | Y | Y | Y |
| grapples | two heavy grapple arms folded flat under the stern quarters | 2 / 2 | Y | Y | Y |


## Structure per cell: distinct masses (blocks, tiers, belts), concept against build

Concept counts read off the concept sheet by eye (A20 sheet: bow, the bow block, the body's front, a deck step and the first mouth's frame; midships, the deck, the sill, the lintel and the plate between the mouths; stern, the deck, the stern edge and the bell row); build counts are the model's registered masses whose station range overlaps the third (below: masses reaching within 0.8 of the belly).

| Cell | Concept | Build | Build masses |
|---|---:|---:|---|
| bow/top | 3 | 6 | Base hull (the slab, its port side stepped in at the hangar block); Bow block; Hangar sill; Hangar lintel; Starboard brick 1; D1 fore deck tier |
| bow/side | 4 | 5 | Base hull (the slab, its port side stepped in at the hangar block); Bow block; Hangar sill; Hangar lintel; D1 fore deck tier |
| bow/below | no view | 4 | Base hull (the slab, its port side stepped in at the hangar block); Bow block; Hangar sill; Starboard brick 1 |
| mid/top | 3 | 8 | Base hull (the slab, its port side stepped in at the hangar block); Hangar sill; Hangar lintel; Plate between the mouths; Starboard brick 2; Starboard brick 3; D1 fore deck tier; D2 mid deck tier |
| mid/side | 4 | 5 | Base hull (the slab, its port side stepped in at the hangar block); Hangar sill; Hangar lintel; Plate between the mouths; D1 fore deck tier |
| mid/below | no view | 5 | Base hull (the slab, its port side stepped in at the hangar block); Hangar sill; Plate between the mouths; Starboard brick 2; Starboard brick 3 |
| stern/top | 3 | 9 | Base hull (the slab, its port side stepped in at the hangar block); Hangar sill; Hangar lintel; Starboard brick 3; Starboard brick 4; D2 mid deck tier; D3 aft deck tier; Stern frame; Violet bell housing |
| stern/side | 3 | 6 | Base hull (the slab, its port side stepped in at the hangar block); Hangar sill; Hangar lintel; D3 aft deck tier; Stern frame; Violet bell housing |
| stern/below | no view | 4 | Base hull (the slab, its port side stepped in at the hangar block); Hangar sill; Starboard brick 3; Starboard brick 4 |

## Proportions: length to beam and length to height, concept against build (the Board on round 3)

Measured the same way on both: the concept sheet's top and side views and the blockout's top and side renders, bow left. Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length (dishes, guns and antennas sticking out at a few stations do not count).

| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |
|---|---:|---:|---:|---:|
| concept | 3.30 | 9.60 | 3.88 | 24.56 |
| build | 2.66 | 3.60 | 2.72 | 5.84 |

Lines not present, shaped and detailed without a reason: 0.
