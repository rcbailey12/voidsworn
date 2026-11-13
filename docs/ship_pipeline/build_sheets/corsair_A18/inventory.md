# corsair_A18 parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/hullbreakers/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing, and its job: what it does on the ship (R221: a part with no job is cut). Source:
`tools/blender/build_sheets/ships/corsair_A18_inv.py`.

| ID | Job | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---|---:|---|---|---|
| hull_form | the raider's hull: a chunky nose that cuts a small target head-on, room behind it for the crew and the core | hull | a chunky nose tapering forward to a wide grilled face over a cut-in chin, the body swelling behind it to its widest at midships, the aft taper | 1 | bow/top, bow/side, mid/side, stern/side | bevels, steps, an overhang (the face over the chin) | picture |
| face_plates | armour over the face and brow, where head-on fire lands | plate | brow and cheek plates round the face, a lip and straps | 1 | bow/side, bow/top | slabs with steps, bevels and rivets | picture |
| scoop | the wake-sniffer scoop: tastes the wake of ships ahead so the pack can follow them | vent | a wide intake grille of three louvre panels filling the bow face, in a steel frame (the picture's wide grilled face; designs.md puts the scoop under the chin) | 3 | bow/side, bow/top | frames, slats, a dark recess | picture |
| sponson | lifts the dish clear of the nose's plating so it hears round the bow | tier | the raised dish mount on the nose to starboard, a vision slit in its front (the picture's flush disc needs a seat; designs.md's swollen shoulder is the nose's own swell now) | 1 | bow/top, bow/side | a face, a roof, an opening | designed |
| sponson_plates | armour | plate | plates over the dish mount | 1 | bow/top, bow/side | slabs with steps, bevels, rivets | designed |
| ear | the one big ear: hears prey before anything else in the pack (the Sniffer's job) | dish | an oversized listening dish set nearly flush on the dish mount, starboard on the nose, more than two fifths of the beam across (the picture's big round disc on the foredeck) | 1 | bow/top, bow/side | ribbed bowl with a rim, a feed horn on struts, a yoke, a post, a base | picture |
| grabbers | boarding grabbers: pin a fleeing hull long enough for the pack to catch up | claw_arm | one pair of small grabber arms under the chin | 2 | bow/below, bow/side | shoulder hinges on brackets, box segments, knuckles, rams, forked pincers | picture |
| chin_pipes | hydraulics that drive the grabbers | pipe | a pipe run under the chin to the grabber rams | 1 | bow/below | a run with flange rings | designed |
| hull_plates | armour, salvaged and mismatched | plate | patch plating over the whole hull, a few plates in trophy colours | 1 | bow/top, bow/side, mid/top, mid/side, stern/top, stern/side | slabs with steps, bevels, rivets | picture |
| thrusters | attitude thrusters: the raider turns hard (evasion 28 in data.js) | thruster | attitude thruster quads at bow and stern | 4 | bow/side, stern/side | a block, splayed nozzles | designed |
| spine | the armoured spine over the crew space and the core; lifts the gun so it sees all round | tier | five stacked spine blocks with gaps, the gun and sensor blocks tallest, slits in the fore block | 1 | bow/top, mid/top, mid/side, stern/top | faces, roof lines with steps, openings | picture |
| autocannon | the raider's gun, data.js autocannon T: chews up escorts and fighters all round | gun | twin autocannon turret on the spine's gun block (the picture shows many guns; data.js gives one weapon) | 1 | mid/top, mid/side | turret ring, faceted housing, mantlet, breeches, barrels with sleeves and brakes | picture |
| spine_boxes | ready-use lockers and deck access | hatchbox | framed boxes on the spine | 2 | mid/top, stern/top | a framed box, an inset lid, side ribs | picture |
| spine_hatch | crew access to the spine | hatch | a hatch on the aft spine block flank | 1 | stern/side | a rim, a door, a seam, hinges | picture |
| antenna | comms: calls the pack in on what the dish heard | antenna | a small antenna array on the sensor block | 1 | mid/top, mid/side | a base, a mast, whips, a pod (never a crossbar mast) | picture |
| flank_bricks | armour bricks over the flank where the crew space is | tier | bolted armour bricks on both flanks, unmatched | 1 | mid/side, bow/side, stern/side | a face, a roof, an undercut | picture |
| trophy | armour, and the pack's boast: plate torn from a Hegemony hull and an Eclipse one | patch | a pale Hegemony trophy plate bolted flat on the port flank; a violet Eclipse patch on the nose | 2 | mid/side, mid/top, bow/top | crooked slabs, a lifted corner, rivets | picture |
| lamps | running lights: pack mates see where it is (sparse and dim, it runs dark) | lamp | dim red lamps at bow (port), midships and stern | 5 | bow/side, mid/side, stern/side | hooded housings, red lenses | picture |
| belly_plates | armour under the hull | plate | flat armoured belly with the band stepping in (the picture shows no underside) | 1 | bow/below, mid/below, stern/below | slabs with steps and rivets | designed |
| engines | main thrust: the overburn engines that make it the fastest Hullbreaker | engine | two engine drums at the stern quarters (port larger) and a small centre bell | 3 | stern/side, stern/top, stern/below | banded housings, bells with lips, throats, inner cones, cooling rings, struts, collars | picture |
| pylons | hold the engine drums out from the hull | pylon | short pylons from the stern quarters to the drums | 1 | stern/top, stern/side | a web with plates | picture |
| engine_block | the stern block the engines bolt to; houses the engine room | pylon | the low engine block at the stern | 1 | stern/top, stern/side | a web with plates | picture |
| vents | shed engine-room heat (overburn runs hot) | vent | a louvre panel on the engine block roof | 1 | stern/top | frames, slats | designed |

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
- thruster: block, nozzle
- tier: face, roof, opening
- vent: frame, slat

Left as surface, and why:

- Grime, rust streaks, scratches, worn edges and decals: surface texture, painted in the build (recipe stage 5), not modelled.
- The picture's rows of flank guns, designs.md's two bow casemates and its rocket rack: data.js c_raider has one weapon (autocannon T); a gun with no slot has no job (R221), so they are not built.
- The picture's three stacked centre bells: one small centre bell, with the two drums (designs.md gives two bells).

## Every built part has a job (R221)

Built kit parts: 44; parts whose inventory id names no line with a job: 0.

## Per cell: present, shaped, detailed (from the model, corsair_A18_model.json)

Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.

### bow/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| hull_form | a chunky nose tapering forward to a wide grilled face over a cut-in ch | 1 / 1 | Y | Y | Y |
| face_plates | brow and cheek plates round the face, a lip and straps | 4 / 1 | Y | Y | Y |
| scoop | a wide intake grille of three louvre panels filling the bow face, in a | 3 / 3 | Y | Y | Y |
| sponson | the raised dish mount on the nose to starboard, a vision slit in its f | 2 / 1 | Y | Y | Y |
| sponson_plates | plates over the dish mount | 1 / 1 | Y | Y | Y |
| ear | an oversized listening dish set nearly flush on the dish mount, starbo | 1 / 1 | Y | Y | Y |
| hull_plates | patch plating over the whole hull, a few plates in trophy colours | 1 / 1 | Y | Y | Y |
| spine | five stacked spine blocks with gaps, the gun and sensor blocks tallest | 2 / 1 | Y | Y | Y |
| trophy | a pale Hegemony trophy plate bolted flat on the port flank; a violet E | 3 / 2 | Y | Y | Y |

### bow/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| hull_form | a chunky nose tapering forward to a wide grilled face over a cut-in ch | 1 / 1 | Y | Y | Y |
| face_plates | brow and cheek plates round the face, a lip and straps | 4 / 1 | Y | Y | Y |
| scoop | a wide intake grille of three louvre panels filling the bow face, in a | 3 / 3 | Y | Y | Y |
| sponson | the raised dish mount on the nose to starboard, a vision slit in its f | 2 / 1 | Y | Y | Y |
| sponson_plates | plates over the dish mount | 1 / 1 | Y | Y | Y |
| ear | an oversized listening dish set nearly flush on the dish mount, starbo | 1 / 1 | Y | Y | Y |
| grabbers | one pair of small grabber arms under the chin | 2 / 2 | Y | Y | Y |
| hull_plates | patch plating over the whole hull, a few plates in trophy colours | 1 / 1 | Y | Y | Y |
| thrusters | attitude thruster quads at bow and stern | 4 / 4 | Y | Y | Y |
| flank_bricks | bolted armour bricks on both flanks, unmatched | 1 / 1 | Y | Y | Y |
| lamps | dim red lamps at bow (port), midships and stern | 5 / 5 | Y | Y | Y |

### bow/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| grabbers | one pair of small grabber arms under the chin | 2 / 2 | Y | Y | Y |
| chin_pipes | a pipe run under the chin to the grabber rams | 1 / 1 | Y | Y | Y |
| belly_plates | flat armoured belly with the band stepping in | 2 / 1 | Y | Y | Y |

### mid/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| hull_plates | patch plating over the whole hull, a few plates in trophy colours | 1 / 1 | Y | Y | Y |
| spine | five stacked spine blocks with gaps, the gun and sensor blocks tallest | 2 / 1 | Y | Y | Y |
| autocannon | twin autocannon turret on the spine's gun block | 1 / 1 | Y | Y | Y |
| spine_boxes | framed boxes on the spine | 2 / 2 | Y | Y | Y |
| antenna | a small antenna array on the sensor block | 1 / 1 | Y | Y | Y |
| trophy | a pale Hegemony trophy plate bolted flat on the port flank; a violet E | 3 / 2 | Y | Y | Y |

### mid/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| hull_form | a chunky nose tapering forward to a wide grilled face over a cut-in ch | 1 / 1 | Y | Y | Y |
| hull_plates | patch plating over the whole hull, a few plates in trophy colours | 1 / 1 | Y | Y | Y |
| spine | five stacked spine blocks with gaps, the gun and sensor blocks tallest | 2 / 1 | Y | Y | Y |
| autocannon | twin autocannon turret on the spine's gun block | 1 / 1 | Y | Y | Y |
| antenna | a small antenna array on the sensor block | 1 / 1 | Y | Y | Y |
| flank_bricks | bolted armour bricks on both flanks, unmatched | 1 / 1 | Y | Y | Y |
| trophy | a pale Hegemony trophy plate bolted flat on the port flank; a violet E | 3 / 2 | Y | Y | Y |
| lamps | dim red lamps at bow (port), midships and stern | 5 / 5 | Y | Y | Y |

### mid/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| belly_plates | flat armoured belly with the band stepping in | 2 / 1 | Y | Y | Y |

### stern/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| hull_plates | patch plating over the whole hull, a few plates in trophy colours | 1 / 1 | Y | Y | Y |
| spine | five stacked spine blocks with gaps, the gun and sensor blocks tallest | 2 / 1 | Y | Y | Y |
| spine_boxes | framed boxes on the spine | 2 / 2 | Y | Y | Y |
| engines | two engine drums at the stern quarters (port larger) and a small centr | 3 / 3 | Y | Y | Y |
| pylons | short pylons from the stern quarters to the drums | 1 / 1 | Y | Y | Y |
| engine_block | the low engine block at the stern | 1 / 1 | Y | Y | Y |
| vents | a louvre panel on the engine block roof | 1 / 1 | Y | Y | Y |

### stern/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| hull_form | a chunky nose tapering forward to a wide grilled face over a cut-in ch | 1 / 1 | Y | Y | Y |
| hull_plates | patch plating over the whole hull, a few plates in trophy colours | 1 / 1 | Y | Y | Y |
| thrusters | attitude thruster quads at bow and stern | 4 / 4 | Y | Y | Y |
| spine_hatch | a hatch on the aft spine block flank | 1 / 1 | Y | Y | Y |
| flank_bricks | bolted armour bricks on both flanks, unmatched | 1 / 1 | Y | Y | Y |
| lamps | dim red lamps at bow (port), midships and stern | 5 / 5 | Y | Y | Y |
| engines | two engine drums at the stern quarters (port larger) and a small centr | 3 / 3 | Y | Y | Y |
| pylons | short pylons from the stern quarters to the drums | 1 / 1 | Y | Y | Y |
| engine_block | the low engine block at the stern | 1 / 1 | Y | Y | Y |

### stern/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| belly_plates | flat armoured belly with the band stepping in | 2 / 1 | Y | Y | Y |
| engines | two engine drums at the stern quarters (port larger) and a small centr | 3 / 3 | Y | Y | Y |


## Structure per cell: distinct masses (blocks, tiers, belts), concept against build

Concept counts read off the concept sheet by eye (A18 sheet: bow, the tapering nose, the grilled face and chin, the flush disc, the spine's front block; midships, two spine blocks, the flank tier and two flank bricks; stern, the aft spine, the engine block, two engine drums and the centre bells); build counts are the model's registered masses whose station range overlaps the third (below: masses reaching within 0.8 of the belly).

| Cell | Concept | Build | Build masses |
|---|---:|---:|---|
| bow/top | 4 | 5 | Base hull (wedge bow, body, aft taper); Lower hull band; Dish mount (raised block on the nose, starboard); S1 fore spine block; Flank brick 1 port |
| bow/side | 4 | 4 | Base hull (wedge bow, body, aft taper); Lower hull band; S1 fore spine block; Flank brick 1 port |
| bow/below | no view | 4 | Base hull (wedge bow, body, aft taper); Lower hull band; Dish mount (raised block on the nose, starboard); Flank brick 1 port |
| mid/top | 5 | 10 | Base hull (wedge bow, body, aft taper); Lower hull band; S1 fore spine block; S2 gun block; S3 mid spine block; S4 sensor block; Flank brick 1 port; Flank brick 2 port; Flank brick 1 starboard; Flank brick 2 starboard |
| mid/side | 5 | 8 | Base hull (wedge bow, body, aft taper); Lower hull band; S1 fore spine block; S2 gun block; S3 mid spine block; S4 sensor block; Flank brick 1 port; Flank brick 2 port |
| mid/below | no view | 6 | Base hull (wedge bow, body, aft taper); Lower hull band; Flank brick 1 port; Flank brick 2 port; Flank brick 1 starboard; Flank brick 2 starboard |
| stern/top | 5 | 8 | Base hull (wedge bow, body, aft taper); Lower hull band; Engine pylon port; Engine pylon starboard; Engine block; S5 aft spine block; Flank brick 2 port; Flank brick 3 starboard |
| stern/side | 5 | 6 | Base hull (wedge bow, body, aft taper); Lower hull band; Engine pylon port; Engine block; S5 aft spine block; Flank brick 2 port |
| stern/below | no view | 7 | Base hull (wedge bow, body, aft taper); Lower hull band; Engine pylon port; Engine pylon starboard; Engine block; Flank brick 2 port; Flank brick 3 starboard |

## Proportions: length to beam and length to height, concept against build (the Board on round 3)

Measured the same way on both: the concept sheet's top and side views and the blockout's top and side renders, bow left. Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length (dishes, guns and antennas sticking out at a few stations do not count).

| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |
|---|---:|---:|---:|---:|
| concept | 3.09 | 6.89 | 4.28 | 13.03 |
| build | 1.98 | 2.88 | 2.86 | 4.07 |

Lines not present, shaped and detailed without a reason: 0.
