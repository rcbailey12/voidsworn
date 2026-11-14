# corsair_A19 parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/hullbreakers/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing, and its job: what it does on the ship (R221: a part with no job is cut). Source:
`tools/blender/build_sheets/ships/corsair_A19_inv.py`.

| ID | Job | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---|---:|---|---|---|
| hull_form | the gutship's hull: a long lean slab that carries the guns to the fight | hull | an arrow-head wedge over the first third (a narrow bow face over a sloped chin, the flanks widening back to full beam), the long low body, the taper into the stern block | 1 | bow/top, bow/side, mid/side, stern/side | bevels, steps, an overhang (the foredeck plate over the face) | picture |
| spade | armour over the bow: the foredeck plate the casemates fire from under | tier | the broad flat bow plate, an arrow-head from above: a blunt point that widens over the first third, overhanging the bow face | 1 | bow/top, bow/side | a face, a roof, an overhang | picture |
| spade_plates | armour | plate | plates over the foredeck plate | 1 | bow/top | slabs with steps, bevels, rivets | picture |
| bow_launchers | data.js torp F: the rattle-rocket salvo, fired straight ahead from the bow face | bow_launcher | two mismatched rocket casemates IN the bow face: one long tube, one short fat cluster of three (Ryan's ruling: the casemates sit in the face) | 2 | bow/side, bow/top | an armour plate, a box housing with a brow, launch tubes with lips, bands, bores and rocket noses, bolts | picture |
| scoop | the wake-sniffer scoop: tastes the wake of ships ahead | tube | a scoop drum with a grille under the chin (designs.md: one chin scoop) | 1 | bow/side, bow/below | ribbed drum, bands, rolled lip, a grille in a dark mouth | designed |
| grabbers | boarding grabbers: pin a hull for the boarding gangs | claw_arm | four grabber arms: a pair under the chin, a pair under the forefoot | 4 | bow/below, bow/side | shoulder hinges on brackets, box segments, knuckles, rams, forked pincers | picture |
| belly_pipes | hydraulics for the grabber rams | pipe | a pipe run under the belly between the grabber pairs | 1 | bow/below | a run with flange rings | designed |
| dishes | listening dishes: hear targets ahead and astern | dish | a large dish on the foredeck plate to port, a small one on the stern block to starboard | 2 | bow/top, bow/side, stern/top | ribbed bowls with rims, feed horns on struts, yokes, posts, bases | picture |
| hull_plates | armour, salvaged and mismatched | plate | patch plating over the whole hull, a few plates in trophy colours | 1 | bow/top, bow/side, mid/top, mid/side, stern/top, stern/side | slabs with steps, bevels, rivets | picture |
| thrusters | attitude thrusters: turn the long hull | thruster | attitude thruster quads at bow and stern | 4 | bow/side, stern/side | a block, splayed nozzles | designed |
| spine | the armoured spine over the decks; lifts the turrets so they fire over the casemates | tier | three stacked spine blocks with gaps, a slit in the fore block | 1 | mid/top, mid/side, bow/top, stern/top | faces, roof lines with steps, openings | picture |
| casemates | data.js scatter S: the starboard broadside | gun | three starboard flank casemates of mixed calibre (the picture's flank pods, all on the starboard side (data.js scatter S)) | 3 | mid/side, mid/top, bow/side | a sponson plate, a box housing, a ball mantlet, barrels with sleeves and brakes | picture |
| deck_turrets | data.js scatter S: superfiring over the casemates to starboard | gun | two twin turrets on the spine, resting to starboard | 2 | mid/top, mid/side | turret rings, faceted housings, mantlets, breeches, barrels with sleeves and brakes | picture |
| spine_boxes | ready-use lockers for the gun crews | hatchbox | framed boxes on the spine | 2 | mid/top, stern/top | a framed box, an inset lid, side ribs | picture |
| side_block | armour over the port flank and the crew hatch; widens the hull for the decks | tier | the port side block amidships | 1 | mid/top, mid/side | a face, a roof, an undercut | picture |
| side_block_plates | armour | plate | plates over the side block | 1 | mid/side | slabs with steps, bevels, rivets | picture |
| bricks | armour bricks between the starboard casemates | tier | four bolted bricks on the starboard flank | 1 | mid/side, bow/side, stern/side | a face, a roof, an undercut | picture |
| trophy | armour, and the pack's boast | patch | the big pale Hegemony trophy plate on the port side block; violet and rust patches on the foredeck; a red patch on the spine | 4 | mid/side, bow/top, mid/top | crooked slabs, a lifted corner, rivets | picture |
| hatches | crew and engine-room access | hatch | a hatch in the port side block, one on the stern block | 2 | mid/side, stern/side | a rim, a door, a seam, hinges | picture |
| lamps | running lights: pack mates see where it is (sparse and dim) | lamp | dim red lamps low on both flanks | 7 | bow/side, mid/side, stern/side | hooded housings, red lenses | picture |
| belly_plates | armour under the hull | plate | flat armoured belly with the band stepping in (the picture shows little of the underside) | 1 | bow/below, mid/below, stern/below | slabs with steps and rivets | designed |
| stern_block | the raised stern block: carries the engines, houses the engine room | tier | the stern block, higher than the spine | 1 | stern/top, stern/side | a face, a roof, an opening | picture |
| stern_plates | armour | plate | plates over the stern block | 1 | stern/top, stern/side | slabs with steps, bevels, rivets | picture |
| engines | main thrust | engine | three bells in the stern block, the centre the largest | 3 | stern/side, stern/top, stern/below | banded housings, bells with lips, throats, inner cones, cooling rings, struts, collars | picture |
| vents | shed engine-room heat | vent | louvre panels on the stern block flanks | 2 | stern/side | frames, slats | designed |
| antenna | comms: hears the Sniffer's calls and the pack's orders | antenna | an antenna array on the stern block | 1 | stern/top, stern/side | a base, a mast, whips, a pod (never a crossbar mast) | designed |

Kit sub-parts per type (what DETAILED checks):

- antenna: base, mast, whip, pod
- bow_launcher: plate, housing, tube, bore, band, nose, bolt
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
- thruster: block, nozzle
- tier: face, roof, opening
- tube: tube, bore, band, ring, bolt, stiff
- vent: frame, slat

Left as surface, and why:

- Grime, rust streaks, scratches, worn edges and decals: surface texture, painted in the build (recipe stage 5), not modelled.
- The picture's guns on the port flank and on the foredeck plate: data.js c_reaver has one starboard battery (scatter S) and one forward launcher (torp F, the bow casemates); a gun with no slot has no job (R221).
- designs.md's rocket racks on the middle deck: the bow casemates fire the one torp slot.

## Every built part has a job (R221)

Built kit parts: 55; parts whose inventory id names no line with a job: 0.

## Per cell: present, shaped, detailed (from the model, corsair_A19_model.json)

Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.

### bow/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| hull_form | an arrow-head wedge over the first third (a narrow bow face over a slo | 1 / 1 | Y | Y | Y |
| spade | the broad flat bow plate, an arrow-head from above: a blunt point that | 1 / 1 | Y | Y | Y |
| spade_plates | plates over the foredeck plate | 1 / 1 | Y | Y | Y |
| bow_launchers | two mismatched rocket casemates IN the bow face: one long tube, one sh | 2 / 2 | Y | Y | Y |
| dishes | a large dish on the foredeck plate to port, a small one on the stern b | 2 / 2 | Y | Y | Y |
| hull_plates | patch plating over the whole hull, a few plates in trophy colours | 1 / 1 | Y | Y | Y |
| spine | three stacked spine blocks with gaps, a slit in the fore block | 2 / 1 | Y | Y | Y |
| trophy | the big pale Hegemony trophy plate on the port side block; violet and  | 6 / 4 | Y | Y | Y |

### bow/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| hull_form | an arrow-head wedge over the first third (a narrow bow face over a slo | 1 / 1 | Y | Y | Y |
| spade | the broad flat bow plate, an arrow-head from above: a blunt point that | 1 / 1 | Y | Y | Y |
| bow_launchers | two mismatched rocket casemates IN the bow face: one long tube, one sh | 2 / 2 | Y | Y | Y |
| scoop | a scoop drum with a grille under the chin | 1 / 1 | Y | Y | Y |
| grabbers | four grabber arms: a pair under the chin, a pair under the forefoot | 4 / 4 | Y | Y | Y |
| dishes | a large dish on the foredeck plate to port, a small one on the stern b | 2 / 2 | Y | Y | Y |
| hull_plates | patch plating over the whole hull, a few plates in trophy colours | 1 / 1 | Y | Y | Y |
| thrusters | attitude thruster quads at bow and stern | 4 / 4 | Y | Y | Y |
| casemates | three starboard flank casemates of mixed calibre | 3 / 3 | Y | Y | Y |
| bricks | four bolted bricks on the starboard flank | 1 / 1 | Y | Y | Y |
| lamps | dim red lamps low on both flanks | 7 / 7 | Y | Y | Y |

### bow/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| scoop | a scoop drum with a grille under the chin | 1 / 1 | Y | Y | Y |
| grabbers | four grabber arms: a pair under the chin, a pair under the forefoot | 4 / 4 | Y | Y | Y |
| belly_pipes | a pipe run under the belly between the grabber pairs | 1 / 1 | Y | Y | Y |
| belly_plates | flat armoured belly with the band stepping in | 2 / 1 | Y | Y | Y |

### mid/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| hull_plates | patch plating over the whole hull, a few plates in trophy colours | 1 / 1 | Y | Y | Y |
| spine | three stacked spine blocks with gaps, a slit in the fore block | 2 / 1 | Y | Y | Y |
| casemates | three starboard flank casemates of mixed calibre | 3 / 3 | Y | Y | Y |
| deck_turrets | two twin turrets on the spine, resting to starboard | 2 / 2 | Y | Y | Y |
| spine_boxes | framed boxes on the spine | 2 / 2 | Y | Y | Y |
| side_block | the port side block amidships | 1 / 1 | Y | Y | Y |
| trophy | the big pale Hegemony trophy plate on the port side block; violet and  | 6 / 4 | Y | Y | Y |

### mid/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| hull_form | an arrow-head wedge over the first third (a narrow bow face over a slo | 1 / 1 | Y | Y | Y |
| hull_plates | patch plating over the whole hull, a few plates in trophy colours | 1 / 1 | Y | Y | Y |
| spine | three stacked spine blocks with gaps, a slit in the fore block | 2 / 1 | Y | Y | Y |
| casemates | three starboard flank casemates of mixed calibre | 3 / 3 | Y | Y | Y |
| deck_turrets | two twin turrets on the spine, resting to starboard | 2 / 2 | Y | Y | Y |
| side_block | the port side block amidships | 1 / 1 | Y | Y | Y |
| side_block_plates | plates over the side block | 1 / 1 | Y | Y | Y |
| bricks | four bolted bricks on the starboard flank | 1 / 1 | Y | Y | Y |
| trophy | the big pale Hegemony trophy plate on the port side block; violet and  | 6 / 4 | Y | Y | Y |
| hatches | a hatch in the port side block, one on the stern block | 2 / 2 | Y | Y | Y |
| lamps | dim red lamps low on both flanks | 7 / 7 | Y | Y | Y |

### mid/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| belly_plates | flat armoured belly with the band stepping in | 2 / 1 | Y | Y | Y |

### stern/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| dishes | a large dish on the foredeck plate to port, a small one on the stern b | 2 / 2 | Y | Y | Y |
| hull_plates | patch plating over the whole hull, a few plates in trophy colours | 1 / 1 | Y | Y | Y |
| spine | three stacked spine blocks with gaps, a slit in the fore block | 2 / 1 | Y | Y | Y |
| spine_boxes | framed boxes on the spine | 2 / 2 | Y | Y | Y |
| stern_block | the stern block, higher than the spine | 1 / 1 | Y | Y | Y |
| stern_plates | plates over the stern block | 1 / 1 | Y | Y | Y |
| engines | three bells in the stern block, the centre the largest | 3 / 3 | Y | Y | Y |
| antenna | an antenna array on the stern block | 1 / 1 | Y | Y | Y |

### stern/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| hull_form | an arrow-head wedge over the first third (a narrow bow face over a slo | 1 / 1 | Y | Y | Y |
| hull_plates | patch plating over the whole hull, a few plates in trophy colours | 1 / 1 | Y | Y | Y |
| thrusters | attitude thruster quads at bow and stern | 4 / 4 | Y | Y | Y |
| bricks | four bolted bricks on the starboard flank | 1 / 1 | Y | Y | Y |
| hatches | a hatch in the port side block, one on the stern block | 2 / 2 | Y | Y | Y |
| lamps | dim red lamps low on both flanks | 7 / 7 | Y | Y | Y |
| stern_block | the stern block, higher than the spine | 1 / 1 | Y | Y | Y |
| stern_plates | plates over the stern block | 1 / 1 | Y | Y | Y |
| engines | three bells in the stern block, the centre the largest | 3 / 3 | Y | Y | Y |
| vents | louvre panels on the stern block flanks | 2 / 2 | Y | Y | Y |
| antenna | an antenna array on the stern block | 1 / 1 | Y | Y | Y |

### stern/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| belly_plates | flat armoured belly with the band stepping in | 2 / 1 | Y | Y | Y |
| engines | three bells in the stern block, the centre the largest | 3 / 3 | Y | Y | Y |


## Structure per cell: distinct masses (blocks, tiers, belts), concept against build

Concept counts read off the concept sheet by eye (A19 sheet: bow, the foredeck plate, the face, the chin and the belly; midships, two spine blocks, the main body and the side block with its pods; stern, the aft spine, the stern block, the engine housings and the belly); build counts are the model's registered masses whose station range overlaps the third (below: masses reaching within 0.8 of the belly).

| Cell | Concept | Build | Build masses |
|---|---:|---:|---|
| bow/top | 3 | 5 | Base hull (blunt bow, chin, long body); Lower hull band; Foredeck plate (the spade); M1 fore spine block; Starboard brick 1 |
| bow/side | 4 | 4 | Base hull (blunt bow, chin, long body); Lower hull band; Foredeck plate (the spade); M1 fore spine block |
| bow/below | no view | 4 | Base hull (blunt bow, chin, long body); Lower hull band; Foredeck plate (the spade); Starboard brick 1 |
| mid/top | 5 | 10 | Base hull (blunt bow, chin, long body); Lower hull band; Foredeck plate (the spade); M1 fore spine block; M2 battery block; M3 aft spine block; Port side block; Starboard brick 1; Starboard brick 2; Starboard brick 3 |
| mid/side | 5 | 7 | Base hull (blunt bow, chin, long body); Lower hull band; Foredeck plate (the spade); M1 fore spine block; M2 battery block; M3 aft spine block; Port side block |
| mid/below | no view | 7 | Base hull (blunt bow, chin, long body); Lower hull band; Foredeck plate (the spade); Port side block; Starboard brick 1; Starboard brick 2; Starboard brick 3 |
| stern/top | 4 | 6 | Base hull (blunt bow, chin, long body); Lower hull band; M3 aft spine block; Port side block; Starboard brick 4; Stern block |
| stern/side | 4 | 5 | Base hull (blunt bow, chin, long body); Lower hull band; M3 aft spine block; Port side block; Stern block |
| stern/below | no view | 5 | Base hull (blunt bow, chin, long body); Lower hull band; Port side block; Starboard brick 4; Stern block |

## Proportions: length to beam and length to height, concept against build (the Board on round 3)

Measured the same way on both: the concept sheet's top and side views and the blockout's top and side renders, bow left. Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length (dishes, guns and antennas sticking out at a few stations do not count).

| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |
|---|---:|---:|---:|---:|
| concept | 4.12 | 4.89 | 7.57 | 10.07 |
| build | 2.46 | 3.49 | 3.27 | 6.19 |

Lines not present, shaped and detailed without a reason: 0.
