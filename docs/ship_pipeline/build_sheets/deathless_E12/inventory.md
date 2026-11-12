# deathless_E12 parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/eclipse/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing. Source: `tools/blender/build_sheets/ships/deathless_E12_inv.py`.

| ID | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---:|---|---|---|
| arcs | arc | the broken shade ring: flat box-section arcs on an oval round the spine, open at the bow and stern, an outer armoured wall with plates, the inner bay open on frames and machinery, a green-white corona line on every outer rim (the picture draws seven (one stern arc, starboard); the build has the matching port one) | 8 | bow/top, bow/side, bow/below, mid/top, mid/side, mid/below, stern/top, stern/side, stern/below | a channel section, a corona line, frames across the bay, machinery and conduits in it, plates | picture |
| arc_plates | plate | plates over the arcs' upper faces and outer walls | 1 | bow/top, mid/top, stern/top | chamfered slabs with steps and fasteners | picture |
| struts | strut | truss struts from the spine to the arcs (four in the picture; every arc gets its own, R207) (the picture shows four struts; the arcs it leaves floating get theirs (R207)) | 8 | bow/top, mid/top, stern/top | two rails, a zigzag web, end lugs | picture |
| spine | hull | the spine: a long plated beam, stepped where it meets each fitting, overhanging the emitter housing | 1 | bow/top, bow/side, mid/top, mid/side, stern/top, stern/side | bevels, steps, an overhang | picture |
| spine_plates | plate | plate blocks along the spine | 1 | bow/top, mid/top, stern/top, bow/side, mid/side | chamfered slabs with steps and fasteners | picture |
| emitter | spinal | the bow emitter: a collared housing with a green lens (data.js doom F, the corona arc) | 1 | bow/top, bow/side | breech collars, segments, bands, rails, a muzzle block, a dark bore, a green lens | picture |
| main_guns | gun | two twin turrets on oval saddles on the spine, one either side of the core (data.js gauss T, gauss T) | 2 | bow/top, bow/side, mid/top, mid/side | hex plinths, faceted housings under stacked shade plates, mantlets, breeches, coiled barrels, ringed muzzles | picture |
| saddles | pylon | the oval saddles the turrets stand on | 2 | bow/side, mid/side | a stepped web, plates | picture |
| core | core | the caged green core at the centre of the ring | 1 | mid/top, mid/side, mid/below | hub collars, a bright sphere, gimbal rings, meridian bars | picture |
| stern_block | tier | the stern block: a broad faceted block tapering forward into the spine, the engines in its face | 1 | stern/top, stern/side, stern/below | faceted faces, a stepped roof, openings (lights, vents, hatches) | picture |
| engines | engine | three engines side by side in the stern block | 3 | stern/top, stern/side, stern/below | faceted ribbed drums, mount collars, vanes, short bells, a corona ring round a black shade disc (no flame) | picture |
| sentry | gun | the small turret on the stern block roof with green sights (data.js gsentry T, the null spire) | 1 | stern/top, stern/side | as the turrets, smaller | picture |
| block_lights | lamp | the green light panel on the stern block flanks (the picture shows three on the near flank; matched on the far one) | 6 | stern/side | a housing, a green-white bar lens | picture |
| block_vents | vent | heat slot panels on the stern block flanks | 2 | stern/side | a frame, slats | designed |
| block_hatches | hatch | hatches on the stern block roof | 2 | stern/top | a rim, a door, a seam, hinges | designed |
| thrusters | thruster | attitude thrusters on the stern block's roof and belly edges | 4 | stern/side | a block, slot nozzles | designed |

Kit sub-parts per type (what DETAILED checks):

- arc: channel, corona, frame, machinery, plate
- core: hub, sphere, gimbal, bar
- engine: housing, collar, rib, vane, bell, corona, shade
- gun: ring|plate, housing, cowl, mantlet, breech, tube, coil, muzzle, bore
- hatch: rim, door, seam, hinge
- hull: bevel, step, overhang
- lamp: housing, lens
- plate: slab, step, bevel, fastener
- pylon: web, plate
- spinal: breech, segment, band, rail, block, bore, lens
- strut: rail, web, lug
- thruster: block, nozzle
- tier: face, roof, opening
- vent: frame, slat

Left as surface, and why:

- Grime, scuffs and decals: surface texture, painted in the build (recipe stages 4 and 5), not modelled.
- The escort beside the cruiser in every picture is its own ship (a later fleet brief), not part of this hull.

## Per cell: present, shaped, detailed (from the model, deathless_E12_model.json)

Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.

### bow/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| arcs | the broken shade ring: flat box-section arcs on an oval round the spin | 8 / 8 | Y | Y | Y |
| arc_plates | plates over the arcs' upper faces and outer walls | 9 / 1 | Y | Y | Y |
| struts | truss struts from the spine to the arcs (four in the picture; every ar | 8 / 8 | Y | Y | Y |
| spine | the spine: a long plated beam, stepped where it meets each fitting, ov | 1 / 1 | Y | Y | Y |
| spine_plates | plate blocks along the spine | 3 / 1 | Y | Y | Y |
| emitter | the bow emitter: a collared housing with a green lens (data.js doom F, | 1 / 1 | Y | Y | Y |
| main_guns | two twin turrets on oval saddles on the spine, one either side of the  | 2 / 2 | Y | Y | Y |

### bow/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| arcs | the broken shade ring: flat box-section arcs on an oval round the spin | 8 / 8 | Y | Y | Y |
| spine | the spine: a long plated beam, stepped where it meets each fitting, ov | 1 / 1 | Y | Y | Y |
| spine_plates | plate blocks along the spine | 3 / 1 | Y | Y | Y |
| emitter | the bow emitter: a collared housing with a green lens (data.js doom F, | 1 / 1 | Y | Y | Y |
| main_guns | two twin turrets on oval saddles on the spine, one either side of the  | 2 / 2 | Y | Y | Y |
| saddles | the oval saddles the turrets stand on | 1 / 2 | Y | Y | Y |

### bow/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| arcs | the broken shade ring: flat box-section arcs on an oval round the spin | 8 / 8 | Y | Y | Y |

### mid/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| arcs | the broken shade ring: flat box-section arcs on an oval round the spin | 8 / 8 | Y | Y | Y |
| arc_plates | plates over the arcs' upper faces and outer walls | 9 / 1 | Y | Y | Y |
| struts | truss struts from the spine to the arcs (four in the picture; every ar | 8 / 8 | Y | Y | Y |
| spine | the spine: a long plated beam, stepped where it meets each fitting, ov | 1 / 1 | Y | Y | Y |
| spine_plates | plate blocks along the spine | 3 / 1 | Y | Y | Y |
| main_guns | two twin turrets on oval saddles on the spine, one either side of the  | 2 / 2 | Y | Y | Y |
| core | the caged green core at the centre of the ring | 1 / 1 | Y | Y | Y |

### mid/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| arcs | the broken shade ring: flat box-section arcs on an oval round the spin | 8 / 8 | Y | Y | Y |
| spine | the spine: a long plated beam, stepped where it meets each fitting, ov | 1 / 1 | Y | Y | Y |
| spine_plates | plate blocks along the spine | 3 / 1 | Y | Y | Y |
| main_guns | two twin turrets on oval saddles on the spine, one either side of the  | 2 / 2 | Y | Y | Y |
| saddles | the oval saddles the turrets stand on | 1 / 2 | Y | Y | Y |
| core | the caged green core at the centre of the ring | 1 / 1 | Y | Y | Y |

### mid/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| arcs | the broken shade ring: flat box-section arcs on an oval round the spin | 8 / 8 | Y | Y | Y |
| core | the caged green core at the centre of the ring | 1 / 1 | Y | Y | Y |

### stern/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| arcs | the broken shade ring: flat box-section arcs on an oval round the spin | 8 / 8 | Y | Y | Y |
| arc_plates | plates over the arcs' upper faces and outer walls | 9 / 1 | Y | Y | Y |
| struts | truss struts from the spine to the arcs (four in the picture; every ar | 8 / 8 | Y | Y | Y |
| spine | the spine: a long plated beam, stepped where it meets each fitting, ov | 1 / 1 | Y | Y | Y |
| spine_plates | plate blocks along the spine | 3 / 1 | Y | Y | Y |
| stern_block | the stern block: a broad faceted block tapering forward into the spine | 1 / 1 | Y | Y | Y |
| engines | three engines side by side in the stern block | 3 / 3 | Y | Y | Y |
| sentry | the small turret on the stern block roof with green sights (data.js gs | 1 / 1 | Y | Y | Y |
| block_hatches | hatches on the stern block roof | 2 / 2 | Y | Y | Y |

### stern/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| arcs | the broken shade ring: flat box-section arcs on an oval round the spin | 8 / 8 | Y | Y | Y |
| spine | the spine: a long plated beam, stepped where it meets each fitting, ov | 1 / 1 | Y | Y | Y |
| stern_block | the stern block: a broad faceted block tapering forward into the spine | 1 / 1 | Y | Y | Y |
| engines | three engines side by side in the stern block | 3 / 3 | Y | Y | Y |
| sentry | the small turret on the stern block roof with green sights (data.js gs | 1 / 1 | Y | Y | Y |
| block_lights | the green light panel on the stern block flanks | 6 / 6 | Y | Y | Y |
| block_vents | heat slot panels on the stern block flanks | 2 / 2 | Y | Y | Y |
| thrusters | attitude thrusters on the stern block's roof and belly edges | 4 / 4 | Y | Y | Y |

### stern/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| arcs | the broken shade ring: flat box-section arcs on an oval round the spin | 8 / 8 | Y | Y | Y |
| stern_block | the stern block: a broad faceted block tapering forward into the spine | 1 / 1 | Y | Y | Y |
| engines | three engines side by side in the stern block | 3 / 3 | Y | Y | Y |


## Structure per cell: distinct masses (blocks, tiers, belts), concept against build

Concept counts read off the concept sheet by eye (E12 sheet: bow, the two fore arcs, the emitter housing, the spine, the fore turret saddle; midships, the two centre arcs, the core cage, the spine, the aft turret saddle; stern, the aft arcs and the stern arc, the stern block and its forward taper, the sentry turret); build counts are the model's registered masses whose station range overlaps the third (below: masses reaching within 0.8 of the belly).

| Cell | Concept | Build | Build masses |
|---|---:|---:|---|
| bow/top | 5 | 9 | Spine, fore; Arc, fore port; Arc, centre port; Arc, fore starboard; Arc, centre starboard; Saddle, fore battery; Emitter collars; Emitter shaft; Emitter block |
| bow/side | 4 | 7 | Spine, fore; Arc, fore port; Arc, centre port; Saddle, fore battery; Emitter collars; Emitter shaft; Emitter block |
| bow/below | no view | 8 | Spine, fore; Arc, fore port; Arc, centre port; Arc, fore starboard; Arc, centre starboard; Emitter collars; Emitter shaft; Emitter block |
| mid/top | 5 | 8 | Hull: the stern block and the aft spine; Spine, fore; Arc, centre port; Arc, aft port; Arc, centre starboard; Arc, aft starboard; Saddle, fore battery; Saddle, aft battery |
| mid/side | 4 | 6 | Hull: the stern block and the aft spine; Spine, fore; Arc, centre port; Arc, aft port; Saddle, fore battery; Saddle, aft battery |
| mid/below | no view | 6 | Hull: the stern block and the aft spine; Spine, fore; Arc, centre port; Arc, aft port; Arc, centre starboard; Arc, aft starboard |
| stern/top | 6 | 7 | Hull: the stern block and the aft spine; Block roof step; Block flank cheeks; Arc, aft port; Arc, stern port; Arc, aft starboard; Arc, stern starboard |
| stern/side | 5 | 5 | Hull: the stern block and the aft spine; Block roof step; Block flank cheeks; Arc, aft port; Arc, stern port |
| stern/below | no view | 6 | Hull: the stern block and the aft spine; Block flank cheeks; Arc, aft port; Arc, stern port; Arc, aft starboard; Arc, stern starboard |

## Proportions: length to beam and length to height, concept against build (the Board on round 3)

Measured the same way on both: the concept sheet's top and side views and the blockout's top and side renders, bow left. Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length (dishes, guns and antennas sticking out at a few stations do not count).

| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |
|---|---:|---:|---:|---:|
| concept | 1.77 | 5.94 | 1.94 | 15.57 |
| build | 1.72 | 5.98 | 1.89 | 11.21 |

Lines not present, shaped and detailed without a reason: 0.
