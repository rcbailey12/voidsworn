# corsair_A17 parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/hullbreakers/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing. Source: `tools/blender/build_sheets/ships/corsair_A17_inv.py`.

| ID | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---:|---|---|---|
| head | hull | the head: an octagonal block with heavy chamfers on every edge, a bevelled top edge, two roof steps, a face that overhangs the jaw mouth, a recessed jaw mouth under it | 1 | bow/top, bow/side | bevels, steps, an overhang, a cut-in mouth (never a flat block, R217) | picture |
| head_face | plate | face panels on the head front: raised framed panels with vertical straps | 1 | bow/side | slabs with steps, bevels and rivets; straps | picture |
| head_hatchboxes | hatchbox | framed boxes on the head roof | 3 | bow/top | a framed box, an inset lid, side ribs | picture |
| scoops | tube | scoop drums at the lower corners of the head (port larger) | 2 | bow/side, bow/top | ribbed drums with bands, a rolled lip, a grille in a dark mouth | picture |
| ears | dish | listening dishes as ears on brackets at the upper sides of the head | 2 | bow/top, bow/side | ribbed bowls with rims, feed horns on struts, yokes, a base | picture |
| jaws | claw | jaws: articulated claws under and beside the head | 4 | bow/below, bow/side | hinge drums, armoured segments, joints, rams, hooked fingers | picture |
| jaw_pipes | pipe | coiled hoses and pipes under the head between the jaws | 3 | bow/below | runs with flange rings | picture |
| brow_rack | rack | rattle-rocket pod on the brow (data.js torp F) (the picture shows no launcher; data.js gives a forward torpedo slot) | 1 | bow/top | a box of cells with noses, frame, dividers, cheeks, a yoke and a ring | designed |
| head_plates | plate | armour plating over the head | 1 | bow/top, bow/side, bow/below | slabs with steps, bevels, rivets | picture |
| neck_chain | chain | chains over the neck | 1 | bow/top, mid/top | links, lugs | picture |
| bow_thrusters | thruster | attitude thruster quads at the head | 2 | bow/side | a block, splayed nozzles | designed |
| hump | tier | the shoulder hump: stepped tiers with sloped faces, a crest, openings | 1 | mid/top, mid/side | sloped faces, roof lines with steps, slits and hatches in the faces | picture |
| hump_hatchboxes | hatchbox | raised framed boxes on the hump and the neck deck | 3 | mid/top | a framed box, an inset lid, side ribs | picture |
| deck_guns | gun | deck-edge twin turrets | 4 | mid/top, mid/side | rings, faceted housings, mantlets, breeches, barrels with sleeves and brakes | picture |
| crest_gun | gun | twin turret on the hump crest | 1 | mid/top | as above | picture |
| flank_casemates | gun | hump flank twin casemates | 2 | mid/side, stern/side | a sponson plate, a box housing, a ball mantlet, twin barrels | picture |
| patches | patch | torn patch plates on the flanks and hump shoulder | 8 | mid/side, mid/top | crooked slabs, a lifted corner, rivets | picture |
| rust_plates | plate | rust and dried-blood red plates (hump, deck edges) | 3 | mid/top, mid/side | slabs with steps, bevels, rivets | picture |
| flank_ribs | rib | vertical frame ribs on the flanks | 6 | mid/side, stern/side | raised rib bars | picture |
| lamps | lamp | red lamps in rows along the lower flank | 12 | bow/side, mid/side, stern/side | hooded housings, red lenses | picture |
| hump_chain | chain | girdle chain over the hump front | 1 | mid/top, mid/side | links, lugs | picture |
| belly_turret | gun | belly twin turret (covers below) | 1 | mid/below | as the deck turrets | designed |
| belly_plates | plate | flat armoured belly with chines (the picture shows no underside) | 1 | bow/below, mid/below, stern/below | slabs with steps and rivets | designed |
| engines | engine | the stacked engine cluster: three per side, port bells larger | 6 | stern/side, stern/top, stern/below | ribbed banded housings, bells with lips, throats, inner cones, cooling rings, struts, collars | picture |
| engine_block | pylon | the engine block the cluster mounts on | 1 | stern/side, stern/top | a stepped web with plates | picture |
| antennas | antenna | twin antenna arrays on the aft hump (sheet top view) | 2 | stern/top | a base, a mast, uneven whips, a pod (never a crossbar mast) | picture |
| stern_hatch | hatch | hatches on the aft hump faces | 2 | stern/side, stern/top | a rim, a door, a seam, hinges | picture |
| stern_vents | vent | louvre panels on the aft flanks over the engine room | 2 | stern/side | frames, slats | picture |
| stern_thrusters | thruster | attitude thruster quads at the stern | 2 | stern/side | a block, splayed nozzles | designed |

Kit sub-parts per type (what DETAILED checks):

- antenna: base, mast, whip, pod
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
- The picture's slack chains: made taut girdles (R185).
- The crystal shard: removed (R197).
