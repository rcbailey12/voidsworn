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
