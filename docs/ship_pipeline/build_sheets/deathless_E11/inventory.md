# deathless_E11 parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/eclipse/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing, and its job: what it does on the ship (R221: a part with no job is cut). Source:
`tools/blender/build_sheets/ships/deathless_E11_inv.py`.

| ID | Job | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---|---:|---|---|---|
| crescent | the shield held forward (factions.md: the shade always faces the enemy); the ship shelters behind it, and it peels first when hit | shade | the crescent shade: a broad blade curving forward round the projector, thick at its inner wall and knife-thin at its outer rim, horns reaching past the muzzle, the plane drooping a little toward the horns | 1 | bow/top, bow/side, bow/below, mid/top, mid/side | a lower blade, an upper layer stepped in from the rim, a short third layer at the root, a green-white corona line on every rim, dense plates | picture |
| crescent_plates | armour over the shade: the plates that peel band by band (the Eclipse break) | plate | dense small plates over the crescent faces (upper, inner wall, belly) | 1 | bow/top, bow/side, bow/below | chamfered slabs with steps and flush fasteners | picture |
| projector | the corona arc (doom F): one heavy blow every other turn, and the nova (spinal shell) fires from it | corona_arc | the central barrel through the crescent: the corona arc projector (data.js doom F; the Tomb-ark spinal shell) | 1 | bow/top, bow/side, bow/below | stepped breech collars, a capacitor column (segments, stacked disc banks, feed conduits), an emitter head with a black shade disc in a thin corona ring, a small lens, a crown of six electrode horns (R221: an arc emitter, not a barrel) | picture |
| bow_thrusters | attitude control at the neck: turns the long hull (tn 1) | thruster | attitude thrusters on the neck flanks | 2 | mid/side | a block, slot nozzles | designed |
| body | carries everything: decks, archive vaults, magazines, the core | hull | the long oval body: widest behind the crescent, a gentle taper aft to a waist at the band collar | 1 | mid/top, mid/side, mid/below, stern/top, stern/side, stern/below | a rounded oval section (never a box), a neck stepping down into the crescent root, an overhang over the collars | picture |
| body_plates | armour over the body (ar 0.35, no shields: heavy armour is how Eclipse survive) | plate | the plate rows over the body: rows of small plates across the deck, ribbed rows down the flanks | 1 | mid/top, mid/side, mid/below, stern/top, stern/side, stern/below | chamfered slabs with steps and fasteners | picture |
| dorsal_tiers | armoured decks that carry and feed the two batteries; they peel off with them (B-3) | tier | layered dorsal plate tiers along the spine carrying the batteries (the concept's raised plate rows) | 1 | mid/top, mid/side | stepped faces, roof lines, openings (the core port and hatches) | picture |
| belts | side armour over the vaults and magazines | belt | the flank belt: a raised strake of armour boxes at mid height, both flanks | 2 | mid/side, mid/top, stern/side | a band following the hull curve, plates on it | picture |
| skirt | lower side armour, the belly's first layer | belt | the lower flank skirt: tall narrow plates hanging in a row below the belt | 2 | mid/side, mid/below, stern/side | a band following the hull curve, tall narrow plates | picture |
| main_guns | the two null cannons (gauss T, gauss T): armour-piercing rail guns, the ship's main fire all round | nullcannon | the two big twin turrets on the centreline (data.js gauss T, gauss T) | 2 | mid/top, mid/side | a thin hex foot, a low housing, a crescent shade of two curved plates with a corona rim, yoke cheeks, a ribbed capacitor stack, two rail pairs in stepped square accelerator frames, a shock plate at each muzzle (R221: rail guns, not barrels) | picture |
| core_port | shows the trapped core's light through the deck (the faction's green, never a pooled glow); the core vents through it | corewin | the green hexagonal port on the deck: the trapped core's light seen through a gap (factions.md) (README 8c called it a flak cluster; read as the core port) | 1 | mid/top | a hex rim, glowing glass set back, bars | picture |
| shade_gen | houses the shade generators that drive the plate layers | hatchbox | the raised deck housing between the core port and the aft turret | 1 | mid/top, mid/side | a framed block, an inset lid under a stacked plate, side ribs | picture |
| belly_flak | the second null shredder (flak T) covers below, where the deck shredder cannot see | shredder | belly twin turret covering below (data.js flak T, second mount) | 1 | mid/below | as the deck shredder | designed |
| hatches | crew and drone access to the decks and the belly (repair swarms come out here) | hatch | octagonal hatches on the deck tiers and the belly | 4 | mid/top, mid/below | a rim, a door, a seam, hinges | designed |
| lamps | corona strip lights: running lights and the Eclipse corona line along the belt | lamp | corona strip lights along the flank belt | 8 | mid/side, stern/side | a housing, a green-white bar lens | designed |
| flak | the null shredder (flak T): screens the stern and deck against craft | shredder | the small twin turret aft on the deck (data.js flak T) | 1 | stern/top, stern/side | a thin hex foot, a squat hex drum, a crescent shade with the firing slot, a two-fin capacitor pack, a fan of five needle rails with tip frames (R221) | picture |
| band_collar | the structural ring where the stern section joins the body (B-2 tears here) | belt | the heavy band collar round the body at about three quarters of the length | 1 | stern/top, stern/side, stern/below | a raised ring following the hull, segmented plates | picture |
| feathers | stern shade blades that shield the engine room and dump heat aft | feather | layered swept shade blades round the stern, row over row, flaring toward the engines | 24 | stern/top, stern/side, stern/below | tapered blades with a thickness step, overlapping rows | picture |
| engines | drive (sp 1): four eclipse-ring engines, no flame | engine | the engine cluster: three bells stacked in the side view, two side by side in plan (a diamond of four) | 4 | stern/side, stern/top, stern/below | faceted ribbed drums, mount collars, vanes, short bells, a corona ring round a black shade disc (no flame) | picture |
| vents | dump heat from the shade machinery and the core | vent | heat slot panels on the aft flanks over the belt | 2 | stern/side | a frame, slanted slats | designed |
| stern_thrusters | attitude control at the stern, paired with the neck thrusters to turn the hull | thruster | attitude thrusters on the stern flanks | 2 | stern/side | a block, slot nozzles | designed |

Kit sub-parts per type (what DETAILED checks):

- belt: band, plate
- corewin: rim, glass, bar
- corona_arc: breech, segment, capacitor, conduit, emitter, shade, corona, lens, horn
- engine: housing, collar, rib, vane, bell, corona, shade
- feather: blade, step
- hatch: rim, door, seam, hinge
- hatchbox: frame, lid, rib
- hull: bevel, step, overhang
- lamp: housing, lens
- nullcannon: ring|plate, housing, capacitor, yoke, shade, corona, rail, frame, muzzle
- plate: slab, step, bevel, fastener
- shade: band, layer, corona, plate
- shredder: ring|plate, housing, capacitor, shade, corona, needle, frame
- thruster: block, nozzle
- tier: face, roof, opening
- vent: frame, slat

Left as surface, and why:

- Grime, scuffs, the pale grey-green weathering patch on the inner crescent face (README 8c) and decals: surface texture, painted in the build (recipe stages 4 and 5), not modelled.
- The escort beside the flagship in every picture is its own ship (a later fleet brief), not part of this hull.

## Every built part has a job (R221)

Built kit parts: 80; parts whose inventory id names no line with a job: 0.

## Per cell: present, shaped, detailed (from the model, deathless_E11_model.json)

Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.

### bow/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| crescent | the crescent shade: a broad blade curving forward round the projector, | 1 / 1 | Y | Y | Y |
| crescent_plates | dense small plates over the crescent faces (upper, inner wall, belly) | 4 / 1 | Y | Y | Y |
| projector | the central barrel through the crescent: the corona arc projector (dat | 1 / 1 | Y | Y | Y |

### bow/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| crescent | the crescent shade: a broad blade curving forward round the projector, | 1 / 1 | Y | Y | Y |
| crescent_plates | dense small plates over the crescent faces (upper, inner wall, belly) | 4 / 1 | Y | Y | Y |
| projector | the central barrel through the crescent: the corona arc projector (dat | 1 / 1 | Y | Y | Y |

### bow/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| crescent | the crescent shade: a broad blade curving forward round the projector, | 1 / 1 | Y | Y | Y |
| crescent_plates | dense small plates over the crescent faces (upper, inner wall, belly) | 4 / 1 | Y | Y | Y |
| projector | the central barrel through the crescent: the corona arc projector (dat | 1 / 1 | Y | Y | Y |

### mid/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| crescent | the crescent shade: a broad blade curving forward round the projector, | 1 / 1 | Y | Y | Y |
| body | the long oval body: widest behind the crescent, a gentle taper aft to  | 1 / 1 | Y | Y | Y |
| body_plates | the plate rows over the body: rows of small plates across the deck, ri | 2 / 1 | Y | Y | Y |
| dorsal_tiers | layered dorsal plate tiers along the spine carrying the batteries (the | 1 / 1 | Y | Y | Y |
| belts | the flank belt: a raised strake of armour boxes at mid height, both fl | 2 / 2 | Y | Y | Y |
| main_guns | the two big twin turrets on the centreline (data.js gauss T, gauss T) | 2 / 2 | Y | Y | Y |
| core_port | the green hexagonal port on the deck: the trapped core's light seen th | 1 / 1 | Y | Y | Y |
| shade_gen | the raised deck housing between the core port and the aft turret | 1 / 1 | Y | Y | Y |
| hatches | octagonal hatches on the deck tiers and the belly | 4 / 4 | Y | Y | Y |

### mid/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| crescent | the crescent shade: a broad blade curving forward round the projector, | 1 / 1 | Y | Y | Y |
| bow_thrusters | attitude thrusters on the neck flanks | 2 / 2 | Y | Y | Y |
| body | the long oval body: widest behind the crescent, a gentle taper aft to  | 1 / 1 | Y | Y | Y |
| body_plates | the plate rows over the body: rows of small plates across the deck, ri | 2 / 1 | Y | Y | Y |
| dorsal_tiers | layered dorsal plate tiers along the spine carrying the batteries (the | 1 / 1 | Y | Y | Y |
| belts | the flank belt: a raised strake of armour boxes at mid height, both fl | 2 / 2 | Y | Y | Y |
| skirt | the lower flank skirt: tall narrow plates hanging in a row below the b | 2 / 2 | Y | Y | Y |
| main_guns | the two big twin turrets on the centreline (data.js gauss T, gauss T) | 2 / 2 | Y | Y | Y |
| shade_gen | the raised deck housing between the core port and the aft turret | 1 / 1 | Y | Y | Y |
| lamps | corona strip lights along the flank belt | 8 / 8 | Y | Y | Y |

### mid/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| body | the long oval body: widest behind the crescent, a gentle taper aft to  | 1 / 1 | Y | Y | Y |
| body_plates | the plate rows over the body: rows of small plates across the deck, ri | 2 / 1 | Y | Y | Y |
| skirt | the lower flank skirt: tall narrow plates hanging in a row below the b | 2 / 2 | Y | Y | Y |
| belly_flak | belly twin turret covering below (data.js flak T, second mount) | 1 / 1 | Y | Y | Y |
| hatches | octagonal hatches on the deck tiers and the belly | 4 / 4 | Y | Y | Y |

### stern/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| body | the long oval body: widest behind the crescent, a gentle taper aft to  | 1 / 1 | Y | Y | Y |
| body_plates | the plate rows over the body: rows of small plates across the deck, ri | 2 / 1 | Y | Y | Y |
| flak | the small twin turret aft on the deck (data.js flak T) | 1 / 1 | Y | Y | Y |
| band_collar | the heavy band collar round the body at about three quarters of the le | 2 / 1 | Y | Y | Y |
| feathers | layered swept shade blades round the stern, row over row, flaring towa | 36 / 24 | Y | Y | Y |
| engines | the engine cluster: three bells stacked in the side view, two side by  | 4 / 4 | Y | Y | Y |

### stern/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| body | the long oval body: widest behind the crescent, a gentle taper aft to  | 1 / 1 | Y | Y | Y |
| body_plates | the plate rows over the body: rows of small plates across the deck, ri | 2 / 1 | Y | Y | Y |
| belts | the flank belt: a raised strake of armour boxes at mid height, both fl | 2 / 2 | Y | Y | Y |
| skirt | the lower flank skirt: tall narrow plates hanging in a row below the b | 2 / 2 | Y | Y | Y |
| lamps | corona strip lights along the flank belt | 8 / 8 | Y | Y | Y |
| flak | the small twin turret aft on the deck (data.js flak T) | 1 / 1 | Y | Y | Y |
| band_collar | the heavy band collar round the body at about three quarters of the le | 2 / 1 | Y | Y | Y |
| feathers | layered swept shade blades round the stern, row over row, flaring towa | 36 / 24 | Y | Y | Y |
| engines | the engine cluster: three bells stacked in the side view, two side by  | 4 / 4 | Y | Y | Y |
| vents | heat slot panels on the aft flanks over the belt | 2 / 2 | Y | Y | Y |
| stern_thrusters | attitude thrusters on the stern flanks | 2 / 2 | Y | Y | Y |

### stern/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| body | the long oval body: widest behind the crescent, a gentle taper aft to  | 1 / 1 | Y | Y | Y |
| body_plates | the plate rows over the body: rows of small plates across the deck, ri | 2 / 1 | Y | Y | Y |
| band_collar | the heavy band collar round the body at about three quarters of the le | 2 / 1 | Y | Y | Y |
| feathers | layered swept shade blades round the stern, row over row, flaring towa | 36 / 24 | Y | Y | Y |
| engines | the engine cluster: three bells stacked in the side view, two side by  | 4 / 4 | Y | Y | Y |


## Structure per cell: distinct masses (blocks, tiers, belts), concept against build

Concept counts read off the concept sheet by eye (E11 sheet: bow, the crescent's lower blade, upper layer and inner rim layer, the collars, shaft and muzzle block; midships, the crescent root, the body, the deck plate rows, two turret plinths, the core port and housing, the flank rails; stern, the body, the band collar, three feather rows, the engine cluster, the small turret, the belt); build counts are the model's registered masses whose station range overlaps the third (below: masses reaching within 0.8 of the belly).

| Cell | Concept | Build | Build masses |
|---|---:|---:|---|
| bow/top | 6 | 7 | Hull: the oval body; Crescent lower blade; Crescent upper layer; Crescent root layer; Projector breech collars; Projector shaft; Projector muzzle block |
| bow/side | 5 | 7 | Hull: the oval body; Crescent lower blade; Crescent upper layer; Crescent root layer; Projector breech collars; Projector shaft; Projector muzzle block |
| bow/below | no view | 1 | Hull: the oval body |
| mid/top | 8 | 9 | Hull: the oval body; Crescent lower blade; Crescent upper layer; Projector breech collars; Dorsal tier; Barbette, fore battery; Barbette, aft battery; Flank belt; Lower skirt |
| mid/side | 8 | 9 | Hull: the oval body; Crescent lower blade; Crescent upper layer; Projector breech collars; Dorsal tier; Barbette, fore battery; Barbette, aft battery; Flank belt; Lower skirt |
| mid/below | no view | 2 | Hull: the oval body; Lower skirt |
| stern/top | 8 | 17 | Hull: the oval body; Dorsal tier; Flank belt; Lower skirt; Band collar; Feather row 1, blade 1; Feather row 1, blade 4; Feather row 1, blade 7; Feather row 1, blade 10; Feather row 2, blade 1; Feather row 2, blade 4; Feather row 2, blade 7; |
| stern/side | 8 | 12 | Hull: the oval body; Dorsal tier; Flank belt; Lower skirt; Band collar; Feather row 1, blade 1; Feather row 1, blade 4; Feather row 1, blade 10; Feather row 2, blade 1; Feather row 2, blade 10; Feather row 3, blade 1; Feather row 3, blade 1 |
| stern/below | no view | 7 | Hull: the oval body; Lower skirt; Band collar; Feather row 1, blade 10; Feather row 2, blade 7; Feather row 2, blade 10; Feather row 3, blade 10 |

## Proportions: length to beam and length to height, concept against build (the Board on round 3)

Measured the same way on both: the concept sheet's top and side views and the blockout's top and side renders, bow left. Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length (dishes, guns and antennas sticking out at a few stations do not count).

| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |
|---|---:|---:|---:|---:|
| concept | 2.49 | 4.49 | 5.72 | 7.00 |
| build | 2.59 | 4.14 | 5.59 | 6.54 |

Lines not present, shaped and detailed without a reason: 0.
