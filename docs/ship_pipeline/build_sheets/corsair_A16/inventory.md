# corsair_A16 parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/hullbreakers/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing. Source: `tools/blender/build_sheets/ships/corsair_A16_inv.py`.

| ID | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---:|---|---|---|
| prow | hull | blunt rounded prow: faceted cap stepping down over the tube cluster, a brow overhang, plate steps | 1 | bow/top, bow/side | bevels, a stepped brow, an overhang over the tubes | picture |
| ftubes | tube | front tubes (wake-sniffer scoops) side by side under the brow | 2 | bow/side, bow/top | deep dark bores, thick rolled lips hooded on top, a notch in the lower lip, segmented bodies with clamp bands | picture |
| ftube_spine | vent | ribbed housing between and above the tubes | 1 | bow/side | a frame with vertical ribs and a dark recess | picture |
| dishes | dish | listening dishes side by side on a plinth over the prow | 2 | bow/top, bow/side | ribbed shallow bowls with rolled rims, feed horns on struts, yokes, a base | picture |
| bow_guns | gun | deck-edge twin turrets in a row along the forward deck edges (picture: port edge only) (mirrored to starboard as a matched battery (R213)) | 4 | bow/top, bow/side | rings, faceted housings, mantlets, breeches, long barrels with sleeves and brakes | picture |
| bow_casemates | gun | bow casemates low on the flanks | 2 | bow/side | a sponson plate, a box housing, a ball mantlet, barrels with brakes | picture |
| bow_claws | claw | big hooked boarding claws under the chin | 2 | bow/below, bow/side | hinge drums with caps, armoured segments, joint drums, piston rams, hooked fingers | picture |
| bow_hatchboxes | hatchbox | raised framed deck boxes on the forward deck | 2 | bow/top | a framed box, an inset lid, side ribs | picture |
| bow_chain | chain | lashing chains across the bow deck and down the flank | 2 | bow/top, bow/side | real links, lugs at both ends; taut (nothing hangs in space, R185) | picture |
| bow_trophy | plate | violet Eclipse trophy plates (deck and port flank) | 2 | bow/top, bow/side | thick slabs with bevels and rivets in their old colour | picture |
| bow_plates | plate | armour plating of mixed size over the whole bow | 1 | bow/top, bow/side, bow/below | slabs with thickness steps, bevelled edges, rivets at the corners, a second slab stacked on some | picture |
| flank_vents | vent | louvre panels in a row along the lower flank | 6 | bow/side, mid/side | frames, slanted slats, dark recesses | picture |
| lamps | lamp | dim red running lights along both flanks and on the castle | 14 | bow/side, mid/side, stern/side | hooded housings with red lenses | picture |
| bow_thrusters | thruster | attitude thruster quads at the bow (a ship in space needs them to turn) | 2 | bow/side | a bevelled block, four splayed nozzles | designed |
| tier2 | tier | raised armoured deck (tier 2) with a sloped, stepped front | 1 | mid/top, mid/side | a sloped face, a roof line with a step, openings (vision slits) in the face | picture |
| rack | rack | heavy rocket rack, 2 by 5 cells, on the spine | 1 | mid/top | a framed box of cells, rocket noses set back in each cell, dividers, side cheeks, a yoke and a ring | picture |
| armour_vent | hatchbox | armoured vent housing forward of the rack: a raised box with two slanted blades | 1 | mid/top | a frame, an inset lid, ribs, two slanted armour fins | picture |
| mid_guns | gun | deck-edge twin turrets amidships | 2 | mid/top, mid/side | as the bow turrets | picture |
| mid_casemates | gun | flank twin casemates amidships | 2 | mid/side | a sponson plate, a box housing, a ball mantlet, twin barrels with brakes | picture |
| patches | patch | torn patch plates, crooked and overlapping, mid-flank and the tier 2 shoulder | 8 | mid/side, mid/top | crooked slabs, one corner lifted, rivets | picture |
| pale_plates | plate | pale Hegemony grey trophy plates on the port flank | 1 | mid/side | thick slabs with bevels and rivets | picture |
| flank_ribs | rib | vertical frame ribs dividing the flank into sections | 8 | mid/side, stern/side, bow/side | raised rib bars from the belt to the deck edge | picture |
| belt | plate | belt strake along each flank | 2 | bow/side, mid/side | a raised armour band | picture |
| mid_chain | chain | girdle chain over the tier 2 seam | 1 | mid/top, mid/side | links, lugs | picture |
| antennas | antenna | antenna arrays on the spine (the sheet top view shows tall sticks) | 2 | mid/top, stern/top | a base, a short mast, whips of uneven height, a sensor pod; never a crossbar mast (R185) | picture |
| grapples | claw | grapple arms under the belly (sheet side view: three grabbers) (a matched pair; the picture has three) | 2 | mid/below, stern/below | hinge drums, segments, joints, rams, three-finger grabbers | picture |
| bay | bay | ventral launch bay (data.js hangar 2) (the picture shows no underside) | 1 | mid/below | a raised rim, two door leaves, a centre seam, hinges | designed |
| belly_plates | plate | flat armoured belly with chines (the picture shows no underside) | 1 | bow/below, mid/below, stern/below | plates with steps and rivets, chine edges | designed |
| castle | tier | the castle (tier 3): sloped front with a dried-blood band, flank faces, window slits and hatches | 1 | stern/top, stern/side | sloped faces, a roof line, openings (slits and a hatch), edge bevels | picture |
| bridge | tier | bridge block on the castle roof with a vision slit | 1 | stern/top, stern/side | a face, a roof line, a vision slit | picture |
| top_turret | gun | castle-top turret with a long barrel (turned to face forward (R204: no gun aft)) | 1 | stern/top | ring, housing, mantlet, breeches, long barrels with brakes | picture |
| stern_casemates | gun | castle flank twin casemates in boxy housings | 4 | stern/side | a sponson plate, a box housing, a ball mantlet, twin barrels with brakes | picture |
| main_engine | engine | big main engine bells: the port pod the larger, a centre main | 3 | stern/side, stern/top | a bell with a thick lip, a throat, an inner cone, cooling rings, gimbal struts, a banded housing, a mount collar | picture |
| boosters | engine | small lower booster bells | 2 | stern/side, stern/below | as the main engines | picture |
| upper_pod | engine | upper pod engine on the stern deck | 1 | stern/top | as the main engines | picture |
| pylons | pylon | armoured engine housings and pylons around the pods | 2 | stern/side, stern/top | a stepped web with plates | picture |
| round_hatch | hatch | round hatch with a hand wheel on the stern deck | 1 | stern/top | a rim, a door, a seam, hinges, a hand wheel | picture |
| castle_hatches | hatch | flank hatches on the castle | 2 | stern/side | a rim, a door, a seam, hinges | picture |
| stern_pipes | pipe | pipe runs along the stern flanks to the pods | 2 | stern/side | runs with flange rings | picture |
| stern_thrusters | thruster | attitude thruster quads at the stern | 2 | stern/side | a bevelled block, four splayed nozzles | designed |
| stern_chain | chain | girdle chain over the castle seam | 1 | stern/top, stern/side | links, lugs | picture |

Kit sub-parts per type (what DETAILED checks):

- antenna: base, mast, whip, pod
- bay: rim, leaf, seam, hinge
- chain: link, lug
- claw: hinge, arm, joint, ram, finger
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
- tube: tube, bore, band
- vent: frame, slat

Left as surface, and why:

- Grime, rust streaks, scratches, worn edges and decals: surface texture, painted in the build (recipe stages 4 and 5), not modelled.
- The picture's slack hanging chains: made taut girdles (factions.md: nothing hangs off the ship, R185).
- The crystal shard: removed (R197).

## Per cell: present, shaped, detailed (from the model, corsair_A16_model.json)

Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.

### bow/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| prow | blunt rounded prow: faceted cap stepping down over the tube cluster, a | 1 / 1 | Y | Y | Y |
| ftubes | front tubes (wake-sniffer scoops) side by side under the brow | 2 / 2 | Y | Y | Y |
| dishes | listening dishes side by side on a plinth over the prow | 2 / 2 | Y | Y | Y |
| bow_guns | deck-edge twin turrets in a row along the forward deck edges (picture: | 4 / 4 | Y | Y | Y |
| bow_hatchboxes | raised framed deck boxes on the forward deck | 2 / 2 | Y | Y | Y |
| bow_chain | lashing chains across the bow deck and down the flank | 2 / 2 | Y | Y | Y |
| bow_trophy | violet Eclipse trophy plates (deck and port flank) | 1 / 2 | Y | Y | Y |
| bow_plates | armour plating of mixed size over the whole bow | 5 / 1 | Y | Y | Y |

### bow/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| prow | blunt rounded prow: faceted cap stepping down over the tube cluster, a | 1 / 1 | Y | Y | Y |
| ftubes | front tubes (wake-sniffer scoops) side by side under the brow | 2 / 2 | Y | Y | Y |
| ftube_spine | ribbed housing between and above the tubes | 1 / 1 | Y | Y | Y |
| dishes | listening dishes side by side on a plinth over the prow | 2 / 2 | Y | Y | Y |
| bow_guns | deck-edge twin turrets in a row along the forward deck edges (picture: | 4 / 4 | Y | Y | Y |
| bow_casemates | bow casemates low on the flanks | 2 / 2 | Y | Y | Y |
| bow_claws | big hooked boarding claws under the chin | 2 / 2 | Y | Y | Y |
| bow_chain | lashing chains across the bow deck and down the flank | 2 / 2 | Y | Y | Y |
| bow_trophy | violet Eclipse trophy plates (deck and port flank) | 1 / 2 | Y | Y | Y |
| bow_plates | armour plating of mixed size over the whole bow | 5 / 1 | Y | Y | Y |
| flank_vents | louvre panels in a row along the lower flank | 6 / 6 | Y | Y | Y |
| lamps | dim red running lights along both flanks and on the castle | 14 / 14 | Y | Y | Y |
| bow_thrusters | attitude thruster quads at the bow | 2 / 2 | Y | Y | Y |
| flank_ribs | vertical frame ribs dividing the flank into sections | 6 / 8 | Y | Y | Y |
| belt | belt strake along each flank | 1 / 2 | Y | Y | Y |

### bow/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| bow_claws | big hooked boarding claws under the chin | 2 / 2 | Y | Y | Y |
| bow_plates | armour plating of mixed size over the whole bow | 5 / 1 | Y | Y | Y |
| belly_plates | flat armoured belly with chines | 1 / 1 | Y | Y | Y |

### mid/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| tier2 | raised armoured deck (tier 2) with a sloped, stepped front | 3 / 1 | Y | Y | Y |
| rack | heavy rocket rack, 2 by 5 cells, on the spine | 1 / 1 | Y | Y | Y |
| armour_vent | armoured vent housing forward of the rack: a raised box with two slant | 1 / 1 | Y | Y | Y |
| mid_guns | deck-edge twin turrets amidships | 2 / 2 | Y | Y | Y |
| patches | torn patch plates, crooked and overlapping, mid-flank and the tier 2 s | 8 / 8 | Y | Y | Y |
| mid_chain | girdle chain over the tier 2 seam | 1 / 1 | Y | Y | Y |
| antennas | antenna arrays on the spine (the sheet top view shows tall sticks) | 2 / 2 | Y | Y | Y |

### mid/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| flank_vents | louvre panels in a row along the lower flank | 6 / 6 | Y | Y | Y |
| lamps | dim red running lights along both flanks and on the castle | 14 / 14 | Y | Y | Y |
| tier2 | raised armoured deck (tier 2) with a sloped, stepped front | 3 / 1 | Y | Y | Y |
| mid_guns | deck-edge twin turrets amidships | 2 / 2 | Y | Y | Y |
| mid_casemates | flank twin casemates amidships | 2 / 2 | Y | Y | Y |
| patches | torn patch plates, crooked and overlapping, mid-flank and the tier 2 s | 8 / 8 | Y | Y | Y |
| pale_plates | pale Hegemony grey trophy plates on the port flank | 1 / 1 | Y | Y | Y |
| flank_ribs | vertical frame ribs dividing the flank into sections | 6 / 8 | Y | Y | Y |
| belt | belt strake along each flank | 1 / 2 | Y | Y | Y |
| mid_chain | girdle chain over the tier 2 seam | 1 / 1 | Y | Y | Y |

### mid/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| grapples | grapple arms under the belly (sheet side view: three grabbers) | 2 / 2 | Y | Y | Y |
| bay | ventral launch bay (data.js hangar 2) | 1 / 1 | Y | Y | Y |
| belly_plates | flat armoured belly with chines | 1 / 1 | Y | Y | Y |

### stern/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| antennas | antenna arrays on the spine (the sheet top view shows tall sticks) | 2 / 2 | Y | Y | Y |
| castle | the castle (tier 3): sloped front with a dried-blood band, flank faces | 3 / 1 | Y | Y | Y |
| bridge | bridge block on the castle roof with a vision slit | 3 / 1 | Y | Y | Y |
| top_turret | castle-top turret with a long barrel | 2 / 1 | Y | Y | Y |
| main_engine | big main engine bells: the port pod the larger, a centre main | 3 / 3 | Y | Y | Y |
| upper_pod | upper pod engine on the stern deck | 1 / 1 | Y | Y | Y |
| pylons | armoured engine housings and pylons around the pods | 1 / 2 | Y | Y | Y |
| round_hatch | round hatch with a hand wheel on the stern deck | 1 / 1 | Y | Y | Y |
| stern_chain | girdle chain over the castle seam | 1 / 1 | Y | Y | Y |

### stern/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| lamps | dim red running lights along both flanks and on the castle | 14 / 14 | Y | Y | Y |
| flank_ribs | vertical frame ribs dividing the flank into sections | 6 / 8 | Y | Y | Y |
| castle | the castle (tier 3): sloped front with a dried-blood band, flank faces | 3 / 1 | Y | Y | Y |
| bridge | bridge block on the castle roof with a vision slit | 3 / 1 | Y | Y | Y |
| stern_casemates | castle flank twin casemates in boxy housings | 4 / 4 | Y | Y | Y |
| main_engine | big main engine bells: the port pod the larger, a centre main | 3 / 3 | Y | Y | Y |
| boosters | small lower booster bells | 2 / 2 | Y | Y | Y |
| pylons | armoured engine housings and pylons around the pods | 1 / 2 | Y | Y | Y |
| castle_hatches | flank hatches on the castle | 2 / 2 | Y | Y | Y |
| stern_pipes | pipe runs along the stern flanks to the pods | 2 / 2 | Y | Y | Y |
| stern_thrusters | attitude thruster quads at the stern | 2 / 2 | Y | Y | Y |
| stern_chain | girdle chain over the castle seam | 1 / 1 | Y | Y | Y |

### stern/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| grapples | grapple arms under the belly (sheet side view: three grabbers) | 2 / 2 | Y | Y | Y |
| belly_plates | flat armoured belly with chines | 1 / 1 | Y | Y | Y |
| boosters | small lower booster bells | 2 / 2 | Y | Y | Y |


## Structure per cell: distinct masses (blocks, tiers, belts), concept against build

Concept counts read off the round 8 sheet by eye (A16 sheet: bow, the prow cap, brow steps, tube housing, chin and layered flank belts; midships, tier 2, the rack plinth, the vent box, three flank bands and the sponson; stern, castle, bridge, stern deck, two pod housings and flank bands); build counts are the model's registered masses whose station range overlaps the third (below: masses reaching within 0.8 of the belly).

| Cell | Concept | Build | Build masses |
|---|---:|---:|---|
| bow/top | 5 | 7 | Hull slab (tier 1); Upper armour belt; Lower armour belt; Prow brow (two steps); Brow step; Chin; Raised armoured deck (tier 2) |
| bow/side | 6 | 7 | Hull slab (tier 1); Upper armour belt; Lower armour belt; Prow brow (two steps); Brow step; Chin; Raised armoured deck (tier 2) |
| bow/below | no view | 3 | Hull slab (tier 1); Lower armour belt; Chin |
| mid/top | 6 | 8 | Hull slab (tier 1); Upper armour belt; Lower armour belt; Raised armoured deck (tier 2); Rack plinth; Castle (tier 3); Sponson port; Sponson starboard |
| mid/side | 7 | 7 | Hull slab (tier 1); Upper armour belt; Lower armour belt; Raised armoured deck (tier 2); Rack plinth; Castle (tier 3); Sponson port |
| mid/below | no view | 2 | Hull slab (tier 1); Lower armour belt |
| stern/top | 7 | 10 | Hull slab (tier 1); Upper armour belt; Lower armour belt; Castle (tier 3); Bridge block; Stern deck; Sponson port; Sponson starboard; Pod pylon port; Pod pylon starboard |
| stern/side | 7 | 8 | Hull slab (tier 1); Upper armour belt; Lower armour belt; Castle (tier 3); Bridge block; Stern deck; Sponson port; Pod pylon port |
| stern/below | no view | 2 | Hull slab (tier 1); Lower armour belt |

## Proportions: length to beam and length to height, concept against build (the Board on round 3)

Measured the same way on both: the concept sheet's top and side views and the blockout's top and side renders, bow left. Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length (dishes, guns and antennas sticking out at a few stations do not count).

| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |
|---|---:|---:|---:|---:|
| concept | 2.46 | 3.17 | 3.04 | 4.45 |
| build | 2.13 | 2.80 | 3.02 | 4.18 |

Lines not present, shaped and detailed without a reason: 0.
