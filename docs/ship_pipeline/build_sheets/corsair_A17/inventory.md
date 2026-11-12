# corsair_A17 parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/hullbreakers/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing, and its job: what it does on the ship (R221: a part with no job is cut). Source:
`tools/blender/build_sheets/ships/corsair_A17_inv.py`.

| ID | Job | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---|---:|---|---|---|
| head | the armoured ram head: takes the first hits and houses the sensors and jaw mouth | hull | the head: an octagonal block with heavy chamfers on every edge, a bevelled top edge, two roof steps, a face that overhangs the jaw mouth, a recessed jaw mouth under it | 1 | bow/top, bow/side | bevels, steps, an overhang, a cut-in mouth (never a flat block, R217) | picture |
| head_face | armour over the face, where head-on fire lands | plate | face panels on the head front: raised framed panels with vertical straps | 1 | bow/side | slabs with steps, bevels and rivets; straps | picture |
| head_hatchboxes | deck access and ready stores for the head | hatchbox | framed boxes on the head roof | 3 | bow/top | a framed box, an inset lid, side ribs | picture |
| scoops | wake-sniffer scoops: draw in the wake of ships ahead to track prey | tube | scoop drums at the lower corners of the head (port larger) | 2 | bow/side, bow/top | ribbed drums with bands, a rolled lip, a grille in a dark mouth | picture |
| ears | listening dishes: hear targets ahead and to the sides (the pack hunter's ears) | dish | listening dishes as ears on brackets at the upper sides of the head | 2 | bow/top, bow/side | ribbed bowls with rims, feed horns on struts, yokes, a base | picture |
| jaws | boarding grabbers: seize and pin a victim's hull for the boarding gangs (the Hullbreakers' trade) | claw_arm | four articulated grabber arms from under the jaw, a pair a side, upper and lower, closing like pincers (R229: the whole beauty, not the bow crop) | 4 | bow/below, bow/side, bow/top | shoulder hinges on brackets, two box segments, knuckles with hinge plates, rams, forked hooked pincers | picture |
| jaw_pipes | hydraulics that close the jaws | pipe | coiled hoses and pipes under the head between the jaws | 3 | bow/below | runs with flange rings | picture |
| brow_rack | rattle rockets, data.js slot F (torp) | rack | rattle-rocket pod on the brow (data.js torp F) (the picture shows no launcher; data.js gives a forward torpedo slot) | 1 | bow/top | a box of cells with noses, frame, dividers, cheeks, a yoke and a ring | designed |
| head_plates | armour | plate | armour plating over the head | 1 | bow/top, bow/side, bow/below | slabs with steps, bevels, rivets | picture |
| bow_thrusters | attitude thrusters: turn the head | thruster | attitude thruster quads at the head | 2 | bow/side | a block, splayed nozzles | designed |
| hump | armoured hump over the reactor and crew decks; raises the turrets | tier | the shoulder hump: stepped tiers with sloped faces, a crest, openings | 1 | mid/top, mid/side | sloped faces, roof lines with steps, slits and hatches in the faces | picture |
| hump_hatchboxes | deck access and ready stores for the deck guns | hatchbox | raised framed boxes on the hump and the neck deck | 3 | mid/top | a framed box, an inset lid, side ribs | picture |
| deck_guns | scatter guns, data.js slots P and S: the broadside battery | gun | deck-edge twin turrets | 4 | mid/top, mid/side | rings, faceted housings, mantlets, breeches, barrels with sleeves and brakes | picture |
| crest_gun | flak, data.js slot T: all-round cover from the aft block | gun | twin turret on the hump crest | 1 | mid/top | as above | picture |
| flank_casemates | scatter casemates, slots P and S: low cover over the flanks | gun | hump flank twin casemates | 2 | mid/side, stern/side | a sponson plate, a box housing, a ball mantlet, twin barrels | picture |
| patches | field repairs: plate welded over battle damage | patch | torn patch plates on the flanks and hump shoulder | 8 | mid/side, mid/top | crooked slabs, a lifted corner, rivets | picture |
| rust_plates | armour, salvaged and mismatched | plate | rust and dried-blood red plates (hump, deck edges) | 3 | mid/top, mid/side | slabs with steps, bevels, rivets | picture |
| flank_ribs | frame ribs: the hull's structure, showing through the plate | rib | vertical frame ribs on the flanks | 6 | mid/side, stern/side | raised rib bars | picture |
| lamps | running lights: pack mates see where it is | lamp | red lamps in rows along the lower flank | 12 | bow/side, mid/side, stern/side | hooded housings, red lenses | picture |
| belly_turret | flak, data.js slot T: covers below | gun | belly twin turret (covers below) | 1 | mid/below | as the deck turrets | designed |
| belly_plates | armour under the hull | plate | flat armoured belly with chines (the picture shows no underside) | 1 | bow/below, mid/below, stern/below | slabs with steps and rivets | designed |
| engines | main thrust: speed for the pack's chase | engine | the stacked engine cluster: three per side, port bells larger | 6 | stern/side, stern/top, stern/below | ribbed banded housings, bells with lips, throats, inner cones, cooling rings, struts, collars | picture |
| engine_block | holds the engine cluster to the hull | pylon | the engine block the cluster mounts on | 1 | stern/side, stern/top | a stepped web with plates | picture |
| antennas | comms: talk to the pack | antenna | twin antenna arrays on the aft hump (sheet top view) | 2 | stern/top | a base, a mast, uneven whips, a pod (never a crossbar mast) | picture |
| stern_hatch | crew access to the engine room | hatch | hatches on the aft hump faces | 2 | stern/side, stern/top | a rim, a door, a seam, hinges | picture |
| stern_vents | shed engine-room heat | vent | louvre panels on the aft flanks over the engine room | 2 | stern/side | frames, slats | picture |
| stern_thrusters | attitude thrusters: turn the stern | thruster | attitude thruster quads at the stern | 2 | stern/side | a block, splayed nozzles | designed |

Kit sub-parts per type (what DETAILED checks):

- antenna: base, mast, whip, pod
- claw_arm: bracket, hinge, plate, pin, arm, rivet, ram, joint, wrist, finger
- dish: bowl, rib, feed, strut, yoke, post, base
- engine: housing, collar, band, bell, lining, throat_glow, cone, cool, strut
- gun: ring|plate, housing, mantlet, breech, tube, clamp, bore, vent
- hatch: rim, door, seam, hinge
- hatchbox: frame, lid, rib
- hull: bevel, step, overhang
- lamp: housing, hood, lens
- patch: slab, lift, rivet
- pipe: run, flange
- plate: slab, step, bevel, rivet
- pylon: web, plate
- rack: box, frame, div, cell, nose, bore, cheek, yoke, ring
- rib: rib
- thruster: block, nozzle
- tier: face, roof, opening
- tube: tube, bore, band, ring, bolt, stiff
- vent: frame, slat

Left as surface, and why:

- Grime, rust streaks, scratches, worn edges and decals: surface texture, painted in the build (recipe stages 4 and 5), not modelled.
- The picture's chains: cut, they have no job on the ship (Ryan, R221: "There's no purpose").
- The crystal shard: removed (R197).

## Every built part has a job (R221)

Built kit parts: 88; parts whose inventory id names no line with a job: 0.

## Per cell: present, shaped, detailed (from the model, corsair_A17_model.json)

Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.

### bow/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| head | the head: an octagonal block with heavy chamfers on every edge, a beve | 1 / 1 | Y | Y | Y |
| head_hatchboxes | framed boxes on the head roof | 3 / 3 | Y | Y | Y |
| scoops | scoop drums at the lower corners of the head (port larger) | 2 / 2 | Y | Y | Y |
| ears | listening dishes as ears on brackets at the upper sides of the head | 2 / 2 | Y | Y | Y |
| jaws | four articulated grabber arms from under the jaw, a pair a side, upper | 4 / 4 | Y | Y | Y |
| brow_rack | rattle-rocket pod on the brow (data.js torp F) | 1 / 1 | Y | Y | Y |
| head_plates | armour plating over the head | 2 / 1 | Y | Y | Y |

### bow/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| head | the head: an octagonal block with heavy chamfers on every edge, a beve | 1 / 1 | Y | Y | Y |
| head_face | face panels on the head front: raised framed panels with vertical stra | 6 / 1 | Y | Y | Y |
| scoops | scoop drums at the lower corners of the head (port larger) | 2 / 2 | Y | Y | Y |
| ears | listening dishes as ears on brackets at the upper sides of the head | 2 / 2 | Y | Y | Y |
| jaws | four articulated grabber arms from under the jaw, a pair a side, upper | 4 / 4 | Y | Y | Y |
| head_plates | armour plating over the head | 2 / 1 | Y | Y | Y |
| bow_thrusters | attitude thruster quads at the head | 2 / 2 | Y | Y | Y |
| lamps | red lamps in rows along the lower flank | 12 / 12 | Y | Y | Y |

### bow/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| jaws | four articulated grabber arms from under the jaw, a pair a side, upper | 4 / 4 | Y | Y | Y |
| jaw_pipes | coiled hoses and pipes under the head between the jaws | 3 / 3 | Y | Y | Y |
| head_plates | armour plating over the head | 2 / 1 | Y | Y | Y |
| belly_plates | flat armoured belly with chines | 2 / 1 | Y | Y | Y |

### mid/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| hump | the shoulder hump: stepped tiers with sloped faces, a crest, openings | 3 / 1 | Y | Y | Y |
| hump_hatchboxes | raised framed boxes on the hump and the neck deck | 3 / 3 | Y | Y | Y |
| deck_guns | deck-edge twin turrets | 4 / 4 | Y | Y | Y |
| crest_gun | twin turret on the hump crest | 1 / 1 | Y | Y | Y |
| patches | torn patch plates on the flanks and hump shoulder | 8 / 8 | Y | Y | Y |
| rust_plates | rust and dried-blood red plates (hump, deck edges) | 5 / 3 | Y | Y | Y |

### mid/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| hump | the shoulder hump: stepped tiers with sloped faces, a crest, openings | 3 / 1 | Y | Y | Y |
| deck_guns | deck-edge twin turrets | 4 / 4 | Y | Y | Y |
| flank_casemates | hump flank twin casemates | 2 / 2 | Y | Y | Y |
| patches | torn patch plates on the flanks and hump shoulder | 8 / 8 | Y | Y | Y |
| rust_plates | rust and dried-blood red plates (hump, deck edges) | 5 / 3 | Y | Y | Y |
| flank_ribs | vertical frame ribs on the flanks | 6 / 6 | Y | Y | Y |
| lamps | red lamps in rows along the lower flank | 12 / 12 | Y | Y | Y |

### mid/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| belly_turret | belly twin turret (covers below) | 1 / 1 | Y | Y | Y |
| belly_plates | flat armoured belly with chines | 2 / 1 | Y | Y | Y |

### stern/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| engines | the stacked engine cluster: three per side, port bells larger | 6 / 6 | Y | Y | Y |
| engine_block | the engine block the cluster mounts on | 1 / 1 | Y | Y | Y |
| antennas | twin antenna arrays on the aft hump (sheet top view) | 2 / 2 | Y | Y | Y |
| stern_hatch | hatches on the aft hump faces | 2 / 2 | Y | Y | Y |

### stern/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| flank_casemates | hump flank twin casemates | 2 / 2 | Y | Y | Y |
| flank_ribs | vertical frame ribs on the flanks | 6 / 6 | Y | Y | Y |
| lamps | red lamps in rows along the lower flank | 12 / 12 | Y | Y | Y |
| engines | the stacked engine cluster: three per side, port bells larger | 6 / 6 | Y | Y | Y |
| engine_block | the engine block the cluster mounts on | 1 / 1 | Y | Y | Y |
| stern_hatch | hatches on the aft hump faces | 2 / 2 | Y | Y | Y |
| stern_vents | louvre panels on the aft flanks over the engine room | 2 / 2 | Y | Y | Y |
| stern_thrusters | attitude thruster quads at the stern | 2 / 2 | Y | Y | Y |

### stern/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| belly_plates | flat armoured belly with chines | 2 / 1 | Y | Y | Y |
| engines | the stacked engine cluster: three per side, port bells larger | 6 / 6 | Y | Y | Y |


## Structure per cell: distinct masses (blocks, tiers, belts), concept against build

Concept counts read off the concept sheet by eye (A17 sheet: bow, the head block, its roof step, the neck block, the flank tier and belly band; midships, three stepped top blocks over flank blocks; stern, two top blocks, the engine block and flank blocks); build counts are the model's registered masses whose station range overlaps the third (below: masses reaching within 0.8 of the belly).

| Cell | Concept | Build | Build masses |
|---|---:|---:|---|
| bow/top | 5 | 9 | Base hull (head and flank tier); Lower hull band; Head brow (step 1); Head crown (step 2); Flank block 1 port; Flank block 1 starboard; U1 neck block; Ear bracket port; Ear bracket starboard |
| bow/side | 5 | 7 | Base hull (head and flank tier); Lower hull band; Head brow (step 1); Head crown (step 2); Flank block 1 port; U1 neck block; Ear bracket port |
| bow/below | no view | 2 | Base hull (head and flank tier); Lower hull band |
| mid/top | 7 | 13 | Base hull (head and flank tier); Lower hull band; Flank block 2 port; Flank block 3 port; Flank block 4 port; Flank block 2 starboard; Flank block 3 starboard; Flank block 4 starboard; U2 fore block; U3 ramp block; U4 mid block; U5 saddle b |
| mid/side | 7 | 10 | Base hull (head and flank tier); Lower hull band; Flank block 2 port; Flank block 3 port; Flank block 4 port; U2 fore block; U3 ramp block; U4 mid block; U5 saddle block; Rack plinth |
| mid/below | no view | 2 | Base hull (head and flank tier); Lower hull band |
| stern/top | 5 | 9 | Base hull (head and flank tier); Lower hull band; Flank block 4 port; Flank block 5 port; Flank block 4 starboard; Flank block 5 starboard; U5 saddle block; U6 aft block; Engine block |
| stern/side | 6 | 7 | Base hull (head and flank tier); Lower hull band; Flank block 4 port; Flank block 5 port; U5 saddle block; U6 aft block; Engine block |
| stern/below | no view | 3 | Base hull (head and flank tier); Lower hull band; Engine block |

## Proportions: length to beam and length to height, concept against build (the Board on round 3)

Measured the same way on both: the concept sheet's top and side views and the blockout's top and side renders, bow left. Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length (dishes, guns and antennas sticking out at a few stations do not count).

| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |
|---|---:|---:|---:|---:|
| concept | 2.04 | 3.54 | 2.75 | 4.06 |
| build | 1.91 | 2.88 | 2.82 | 3.77 |

Lines not present, shaped and detailed without a reason: 0.
