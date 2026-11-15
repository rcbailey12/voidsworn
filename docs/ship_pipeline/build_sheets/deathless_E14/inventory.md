# deathless_E14 parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/eclipse/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing, and its job: what it does on the ship (R221: a part with no job is cut). Source:
`tools/blender/build_sheets/ships/deathless_E14_inv.py`.

| ID | Job | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---|---:|---|---|---|
| ring | the shade: one closed ring of curved shade plates round the gun heart, the faction's sunshade; its plates peel first when hit | shade | the ring: twelve large curved shade plates on one closed hoop, narrow even gaps between them, flat in plan round the spar, each plate a slab with a stepped second layer and a thin green-white corona line along its outer rim (the beauty and the plan draw twelve; R233 closes the ring all the way round) | 12 | bow/top, bow/side, bow/below, mid/top, mid/side, mid/below, stern/top, stern/side, stern/below | a broad curved band, a stepped layer, a corona line on the rim, even panels | picture |
| ring_plates | armour over the shade plates | plate | even, aligned panels over the shade plates (R243) | 1 | bow/top, mid/top, stern/top | chamfered slabs with steps and flush fasteners | picture |
| hoop | the closed structural ring that carries the twelve plates and joins the spar at the bow and stern (R233, R207) | belt | the hoop: one closed box-section ring under the plates' inner edges (the picture leaves the plates floating; R207: every shade has a structural connection) | 1 | bow/top, bow/below, mid/top, mid/below, stern/top, stern/below | a band, plates | designed |
| spokes | carry the hoop to the gun heart at the beams (R207) | strut | truss spokes from the heart's hub collars to the hoop | 4 | mid/top, mid/below | two rails, a zigzag web, end lugs | designed |
| gun_heart | the heart at the ring's centre: carries the forward gun, the core and the capacitor bank | tier | the gun heart: a faceted drum on the spar at the ring's centre, stepped down to the spar at both ends | 1 | bow/top, bow/side, mid/top, mid/side | faceted faces, a stepped roof, openings (core gaps) | picture |
| fwd_gun | the forward null cannon (gauss F): an armour-piercing rail gun over the ring's bow plates, turning only through the data arc F | nullcannon | the forward gun on the gun heart's roof (data.js gauss F) (designs.md: a recessed housing; the game's gauss is the null cannon on a turret (weapon_match.FITS), limited here to the F arc) | 1 | bow/top, bow/side | a thin round foot, a small oval shell, an arched crescent shade of seamed bevelled plates with a second layer and a corona crest, rod yokes, crescent capacitor fins, two slim round rail pairs with banded collars and shock rings (R221) | picture |
| nose_thrusters | attitude control at the bow | thruster | attitude thrusters on the spar's nose flanks | 2 | bow/side | a block, slot nozzles | designed |
| core | the trapped light core: powers the ship and its phase and regeneration (data.js ab phase, regen 2) | core | the bright core at the ring's centre, the spar entering its hub collars | 1 | mid/top, mid/side, mid/below | hub collars, a bright sphere, gimbal rings, meridian bars | picture |
| cage | the broken cage of small shade plates that shields the core (designs.md) | feather | small curved shade plates round the core's hub, broken by gaps the light shows through | 6 | mid/top, mid/side | a blade, a thickness step | picture |
| spar | the keel beam: carries the heart, the gun saddle and the stern block | hull | the layered spar: a slim chamfered beam from the nose to the stern block | 1 | bow/side, mid/top, mid/side, stern/top, stern/side | bevels, steps, an overhang | picture |
| spar_plates | armour over the spar | plate | even, aligned panels along the spar | 1 | mid/top, mid/side, stern/top | chamfered slabs with steps and flush fasteners | picture |
| drone_docks | dock the repair drones that mend the ring (data.js regen 2, reanimate) | hatchbox | repair drone cradles docked on the hoop's inner face (the picture shows drones hovering in the gaps; built docked, so every part sits on the ship) | 4 | mid/top, bow/top, stern/top | a frame, a lid, ribs | picture |
| drone_lights | the drones' green work lights | lamp | a green light on each drone cradle | 4 | mid/top, bow/top, stern/top | a housing, a green-white bar lens | picture |
| aft_gun | the aft null cannon (gauss T): an armour-piercing rail gun that turns all round, firing over the ring | nullcannon | the low gun housing on the spar's dorsal line aft of the ring (data.js gauss T) | 1 | stern/top, stern/side | a thin round foot, a small oval shell, an arched crescent shade of seamed bevelled plates with a second layer and a corona crest, rod yokes, crescent capacitor fins, two slim round rail pairs with banded collars and shock rings (R221) | picture |
| saddle | seat the aft gun on the slim spar and carry its feed | pylon | the stepped saddle under the aft gun | 1 | stern/side | a stepped web, plates | designed |
| stern_block | holds the engine, the engine room and the archive vault | tier | the stern block: a faceted chamfered block where the spar thickens before the engine | 1 | stern/top, stern/side, stern/below | faceted faces, a stepped roof, openings (vents, hatches, lights) | picture |
| engine | drive (sp 3): one eclipse-ring engine, larger than the frigate's, no flame | engine | one engine at the stern: the broad eclipse ring of pale light | 1 | stern/top, stern/side, stern/below | a faceted ribbed drum, a mount collar, vanes, a short bell, a corona ring round a black shade disc (no flame) | picture |
| stern_thrusters | attitude control at the stern | thruster | attitude thrusters on the stern block's flanks | 2 | stern/side | a block, slot nozzles | designed |
| lamps | the corona strip lights along the spar: the faction's only lights besides the corona, the core and the engine ring | lamp | corona strip lights on the stern block's flanks (the beauty's green lights along the spar) | 4 | stern/side | a housing, a green-white bar lens | picture |
| vents | dump heat from the engine room | vent | heat slot panels on the stern block's flanks | 2 | stern/side | a frame, slats | designed |
| hatches | crew access to the stern block | hatch | hatches on the stern block's belly | 2 | stern/below | a rim, a door, a seam, hinges | designed |

Kit sub-parts per type (what DETAILED checks):

- belt: band, plate
- core: hub, sphere, gimbal, bar
- engine: housing, collar, rib, vane, bell, corona, shade
- feather: blade, step
- hatch: rim, door, seam, hinge
- hatchbox: frame, lid, rib
- hull: bevel, step, overhang
- lamp: housing, lens
- nullcannon: ring|plate, housing, capacitor, yoke, shade, layer, corona, rail, collar, muzzle
- plate: slab, step, bevel, fastener
- pylon: web, plate
- shade: band, layer, corona, plate
- strut: rail, web, lug
- thruster: block, nozzle
- tier: face, roof, opening
- vent: frame, slat

Left as surface, and why:

- Grime, scuffs and decals: surface texture, painted in the build (recipe stages 4 and 5), not modelled.
- The concept sheet's middle and right views (the ring edge-on and upright) do not agree with its plan or the beauty; the ring's plane is the study's pick.

## Every built part has a job (R221)

Built kit parts: 66; parts whose inventory id names no line with a job: 0.

## Per cell: present, shaped, detailed (from the model, deathless_E14_model.json)

Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.

### bow/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| ring | the ring: twelve large curved shade plates on one closed hoop, narrow  | 12 / 12 | Y | Y | Y |
| ring_plates | even, aligned panels over the shade plates (R243) | 13 / 1 | Y | Y | Y |
| hoop | the hoop: one closed box-section ring under the plates' inner edges | 1 / 1 | Y | Y | Y |
| gun_heart | the gun heart: a faceted drum on the spar at the ring's centre, steppe | 1 / 1 | Y | Y | Y |
| fwd_gun | the forward gun on the gun heart's roof (data.js gauss F) | 1 / 1 | Y | Y | Y |
| drone_docks | repair drone cradles docked on the hoop's inner face | 4 / 4 | Y | Y | Y |
| drone_lights | a green light on each drone cradle | 4 / 4 | Y | Y | Y |

### bow/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| ring | the ring: twelve large curved shade plates on one closed hoop, narrow  | 12 / 12 | Y | Y | Y |
| gun_heart | the gun heart: a faceted drum on the spar at the ring's centre, steppe | 1 / 1 | Y | Y | Y |
| fwd_gun | the forward gun on the gun heart's roof (data.js gauss F) | 1 / 1 | Y | Y | Y |
| nose_thrusters | attitude thrusters on the spar's nose flanks | 2 / 2 | Y | Y | Y |
| spar | the layered spar: a slim chamfered beam from the nose to the stern blo | 1 / 1 | Y | Y | Y |

### bow/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| ring | the ring: twelve large curved shade plates on one closed hoop, narrow  | 12 / 12 | Y | Y | Y |
| hoop | the hoop: one closed box-section ring under the plates' inner edges | 1 / 1 | Y | Y | Y |

### mid/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| ring | the ring: twelve large curved shade plates on one closed hoop, narrow  | 12 / 12 | Y | Y | Y |
| ring_plates | even, aligned panels over the shade plates (R243) | 13 / 1 | Y | Y | Y |
| hoop | the hoop: one closed box-section ring under the plates' inner edges | 1 / 1 | Y | Y | Y |
| spokes | truss spokes from the heart's hub collars to the hoop | 4 / 4 | Y | Y | Y |
| gun_heart | the gun heart: a faceted drum on the spar at the ring's centre, steppe | 1 / 1 | Y | Y | Y |
| core | the bright core at the ring's centre, the spar entering its hub collar | 1 / 1 | Y | Y | Y |
| cage | small curved shade plates round the core's hub, broken by gaps the lig | 6 / 6 | Y | Y | Y |
| spar | the layered spar: a slim chamfered beam from the nose to the stern blo | 1 / 1 | Y | Y | Y |
| spar_plates | even, aligned panels along the spar | 2 / 1 | Y | Y | Y |
| drone_docks | repair drone cradles docked on the hoop's inner face | 4 / 4 | Y | Y | Y |
| drone_lights | a green light on each drone cradle | 4 / 4 | Y | Y | Y |

### mid/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| ring | the ring: twelve large curved shade plates on one closed hoop, narrow  | 12 / 12 | Y | Y | Y |
| gun_heart | the gun heart: a faceted drum on the spar at the ring's centre, steppe | 1 / 1 | Y | Y | Y |
| core | the bright core at the ring's centre, the spar entering its hub collar | 1 / 1 | Y | Y | Y |
| cage | small curved shade plates round the core's hub, broken by gaps the lig | 6 / 6 | Y | Y | Y |
| spar | the layered spar: a slim chamfered beam from the nose to the stern blo | 1 / 1 | Y | Y | Y |
| spar_plates | even, aligned panels along the spar | 2 / 1 | Y | Y | Y |

### mid/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| ring | the ring: twelve large curved shade plates on one closed hoop, narrow  | 12 / 12 | Y | Y | Y |
| hoop | the hoop: one closed box-section ring under the plates' inner edges | 1 / 1 | Y | Y | Y |
| spokes | truss spokes from the heart's hub collars to the hoop | 4 / 4 | Y | Y | Y |
| core | the bright core at the ring's centre, the spar entering its hub collar | 1 / 1 | Y | Y | Y |

### stern/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| ring | the ring: twelve large curved shade plates on one closed hoop, narrow  | 12 / 12 | Y | Y | Y |
| ring_plates | even, aligned panels over the shade plates (R243) | 13 / 1 | Y | Y | Y |
| hoop | the hoop: one closed box-section ring under the plates' inner edges | 1 / 1 | Y | Y | Y |
| spar | the layered spar: a slim chamfered beam from the nose to the stern blo | 1 / 1 | Y | Y | Y |
| spar_plates | even, aligned panels along the spar | 2 / 1 | Y | Y | Y |
| drone_docks | repair drone cradles docked on the hoop's inner face | 4 / 4 | Y | Y | Y |
| drone_lights | a green light on each drone cradle | 4 / 4 | Y | Y | Y |
| aft_gun | the low gun housing on the spar's dorsal line aft of the ring (data.js | 1 / 1 | Y | Y | Y |
| stern_block | the stern block: a faceted chamfered block where the spar thickens bef | 1 / 1 | Y | Y | Y |
| engine | one engine at the stern: the broad eclipse ring of pale light | 1 / 1 | Y | Y | Y |

### stern/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| ring | the ring: twelve large curved shade plates on one closed hoop, narrow  | 12 / 12 | Y | Y | Y |
| spar | the layered spar: a slim chamfered beam from the nose to the stern blo | 1 / 1 | Y | Y | Y |
| aft_gun | the low gun housing on the spar's dorsal line aft of the ring (data.js | 1 / 1 | Y | Y | Y |
| saddle | the stepped saddle under the aft gun | 1 / 1 | Y | Y | Y |
| stern_block | the stern block: a faceted chamfered block where the spar thickens bef | 1 / 1 | Y | Y | Y |
| engine | one engine at the stern: the broad eclipse ring of pale light | 1 / 1 | Y | Y | Y |
| stern_thrusters | attitude thrusters on the stern block's flanks | 2 / 2 | Y | Y | Y |
| lamps | corona strip lights on the stern block's flanks (the beauty's green li | 4 / 4 | Y | Y | Y |
| vents | heat slot panels on the stern block's flanks | 2 / 2 | Y | Y | Y |

### stern/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| ring | the ring: twelve large curved shade plates on one closed hoop, narrow  | 12 / 12 | Y | Y | Y |
| hoop | the hoop: one closed box-section ring under the plates' inner edges | 1 / 1 | Y | Y | Y |
| stern_block | the stern block: a faceted chamfered block where the spar thickens bef | 1 / 1 | Y | Y | Y |
| engine | one engine at the stern: the broad eclipse ring of pale light | 1 / 1 | Y | Y | Y |
| hatches | hatches on the stern block's belly | 2 / 2 | Y | Y | Y |


## Structure per cell: distinct masses (blocks, tiers, belts), concept against build

Concept counts read off the concept sheet by eye (E14 concept: bow, the ring's bow plates, the gun heart and its gun, the nose; midships, the ring's side plates, the core in its cage, the spar; stern, the ring's stern plates, the spar, the dorsal gun housing, the stern block and the engine ring); build counts are the model's registered masses whose station range overlaps the third (below: masses reaching within 0.8 of the belly).

| Cell | Concept | Build | Build masses |
|---|---:|---:|---|
| bow/top | 4 | 5 | Gun heart; Hoop; Ring plate at 0 degrees; Ring plate at 90 degrees; Ring plate at 270 degrees |
| bow/side | 3 | 4 | Gun heart; Hoop; Ring plate at 0 degrees; Ring plate at 90 degrees |
| bow/below | no view | 5 | Gun heart; Hoop; Ring plate at 0 degrees; Ring plate at 90 degrees; Ring plate at 270 degrees |
| mid/top | 5 | 6 | Hull: the spar and the stern block; Hoop; Ring plate at 90 degrees; Ring plate at 180 degrees; Ring plate at 270 degrees; Saddle, aft gun |
| mid/side | 4 | 5 | Hull: the spar and the stern block; Hoop; Ring plate at 90 degrees; Ring plate at 180 degrees; Saddle, aft gun |
| mid/below | no view | 6 | Hull: the spar and the stern block; Hoop; Ring plate at 90 degrees; Ring plate at 180 degrees; Ring plate at 270 degrees; Saddle, aft gun |
| stern/top | 4 | 2 | Hull: the spar and the stern block; Saddle, aft gun |
| stern/side | 4 | 2 | Hull: the spar and the stern block; Saddle, aft gun |
| stern/below | no view | 2 | Hull: the spar and the stern block; Saddle, aft gun |

## Proportions: length to beam and length to height, concept against build (the Board on round 3)

Measured the same way on both: the concept sheet's top and side views and the blockout's top and side renders, bow left. Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length (dishes, guns and antennas sticking out at a few stations do not count).

| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |
|---|---:|---:|---:|---:|
| concept | 1.02 | 0.36 | 1.10 | 0.79 |
| build | 1.59 | 5.05 | 1.96 | 8.67 |

Lines not present, shaped and detailed without a reason: 0.
