# deathless_E14 parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/eclipse/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing, and its job: what it does on the ship (R221: a part with no job is cut). Source:
`tools/blender/build_sheets/ships/deathless_E14_inv.py`.

| ID | Job | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---|---:|---|---|---|
| ring | the shade held forward at the enemy and the lance's focusing ring: one closed ring of curved shade plates round the gun's muzzle; its plates peel first when hit | shade | the ring: twelve large curved shade plates on one closed hoop, narrow even gaps between them, standing upright across the bow, each plate a deep block with a dished front, a stepped second layer and green-white corona lines on its rim's front and back edges (the beauty and the sheet draw twelve; R233 closes the ring all the way round; R256 stands it upright) | 12 | bow/top, bow/side, bow/below | a broad curved band, a stepped layer, a corona line on the rim, even panels | picture |
| ring_plates | armour over the shade plates | plate | even, aligned panels over the shade plates' fronts, backs and rims (R243) | 1 | bow/top, bow/side | chamfered slabs with steps and flush fasteners | picture |
| hoop | the closed structural ring that carries the twelve plates (R233, R207) | belt | the hoop: one closed box-section ring under the plates' inner edges (the picture leaves the plates floating; R207: every shade has a structural connection) | 1 | bow/side, bow/top | a band, plates | designed |
| spokes | carry the hoop to the gun heart's focus collar (R207) | strut | truss spokes from the focus collar to the hoop, in an X | 4 | bow/side, bow/top | two rails, a zigzag web, end lugs | designed |
| gun_heart | the lance's breech casing: carries the lance through the ring's centre, its capacitors and magazine, and the focus collar the spokes land on | tier | the gun heart: a faceted drum from the core forward through the ring's centre, a capacitor band and the focus collar round it | 1 | bow/top, bow/side, mid/top, mid/side | faceted faces, a stepped roof, openings (the lance's seat) | picture |
| lance | the null lance (data.js nlance F, issue 784): the one big gun, firing forward through the ring's centre (the glass cannon, R256) | nullcannon | the null lance on the gun heart's face, its muzzle the ship's bow at the ring's centre (the beauty's big round muzzle at the ring's heart; designs.md: a fixed forward housing with a recessed aperture and a thin green focus ring, never a protruding tube) | 1 | bow/top, bow/side | a seat ring, an eight-sided armoured housing with a layer sleeve, capacitor discs, four accelerator rails on yokes with banded collars, a steel muzzle lip, a green focus ring, a recessed bore with a black shade disc and a glowing lens (R221, designs.md) | picture |
| nose_thrusters | attitude control forward | thruster | attitude thrusters under the spar behind the core (on the gun heart they would fire into the ring's lower plates) | 2 | mid/side | a block, slot nozzles | designed |
| core | the trapped light core: powers the ship and its phase and regeneration (data.js ab phase, regen 2) | core | the bright core just aft of the ring's centre, the spar and the gun heart entering its hub collars | 1 | mid/top, mid/side, mid/below | hub collars, a bright sphere, gimbal rings, meridian bars | picture |
| cage | the broken cage of small shade plates that shields the core (designs.md) | feather | small curved shade plates round the core's hub, broken by gaps the light shows through | 6 | mid/top, mid/side | a blade, a thickness step | picture |
| spar | the keel beam: carries the core, the capacitor housing and the stern block | hull | the layered spar: a slim chamfered beam from the core to the stern block | 1 | mid/top, mid/side, stern/top, stern/side | bevels, steps, an overhang | picture |
| spar_plates | armour over the spar | plate | even, aligned panels along the spar | 1 | mid/top, mid/side, stern/top | chamfered slabs with steps and flush fasteners | picture |
| drone_docks | dock the repair drones that mend the ring (data.js regen 2, reanimate) | hatchbox | repair drone cradles docked on the hoop's front face (the picture shows drones hovering in the gaps; built docked, so every part sits on the ship) | 4 | bow/top, bow/side | a frame, a lid, ribs | picture |
| drone_lights | the drones' green work lights | lamp | a green light on each drone cradle | 4 | bow/top, bow/side | a housing, a green-white bar lens | picture |
| capbank | store the core's charge for the lance's one big shot (the glass cannon) | pylon | the stepped capacitor housing on the spar's dorsal line aft of the core, three ribs across it (the beauty's low dorsal housing on the spar; the first sheet seated the aft gun there, gone with issue 784) | 1 | mid/top, mid/side, stern/side | a stepped web, plates | picture |
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
- The concept sheet's left view draws the ring face-on across the spar; it does not agree with the beauty or the sheet's other two views, which stand the ring upright (R256).

## Every built part has a job (R221)

Built kit parts: 65; parts whose inventory id names no line with a job: 0.

## Per cell: present, shaped, detailed (from the model, deathless_E14_model.json)

Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.

### bow/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| ring | the ring: twelve large curved shade plates on one closed hoop, narrow  | 12 / 12 | Y | Y | Y |
| ring_plates | even, aligned panels over the shade plates' fronts, backs and rims (R2 | 13 / 1 | Y | Y | Y |
| hoop | the hoop: one closed box-section ring under the plates' inner edges | 1 / 1 | Y | Y | Y |
| spokes | truss spokes from the focus collar to the hoop, in an X | 4 / 4 | Y | Y | Y |
| gun_heart | the gun heart: a faceted drum from the core forward through the ring's | 1 / 1 | Y | Y | Y |
| lance | the null lance on the gun heart's face, its muzzle the ship's bow at t | 1 / 1 | Y | Y | Y |
| drone_docks | repair drone cradles docked on the hoop's front face | 4 / 4 | Y | Y | Y |
| drone_lights | a green light on each drone cradle | 4 / 4 | Y | Y | Y |

### bow/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| ring | the ring: twelve large curved shade plates on one closed hoop, narrow  | 12 / 12 | Y | Y | Y |
| ring_plates | even, aligned panels over the shade plates' fronts, backs and rims (R2 | 13 / 1 | Y | Y | Y |
| hoop | the hoop: one closed box-section ring under the plates' inner edges | 1 / 1 | Y | Y | Y |
| spokes | truss spokes from the focus collar to the hoop, in an X | 4 / 4 | Y | Y | Y |
| gun_heart | the gun heart: a faceted drum from the core forward through the ring's | 1 / 1 | Y | Y | Y |
| lance | the null lance on the gun heart's face, its muzzle the ship's bow at t | 1 / 1 | Y | Y | Y |
| drone_docks | repair drone cradles docked on the hoop's front face | 4 / 4 | Y | Y | Y |
| drone_lights | a green light on each drone cradle | 4 / 4 | Y | Y | Y |

### bow/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| ring | the ring: twelve large curved shade plates on one closed hoop, narrow  | 12 / 12 | Y | Y | Y |

### mid/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| gun_heart | the gun heart: a faceted drum from the core forward through the ring's | 1 / 1 | Y | Y | Y |
| core | the bright core just aft of the ring's centre, the spar and the gun he | 1 / 1 | Y | Y | Y |
| cage | small curved shade plates round the core's hub, broken by gaps the lig | 6 / 6 | Y | Y | Y |
| spar | the layered spar: a slim chamfered beam from the core to the stern blo | 1 / 1 | Y | Y | Y |
| spar_plates | even, aligned panels along the spar | 2 / 1 | Y | Y | Y |
| capbank | the stepped capacitor housing on the spar's dorsal line aft of the cor | 1 / 1 | Y | Y | Y |

### mid/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| gun_heart | the gun heart: a faceted drum from the core forward through the ring's | 1 / 1 | Y | Y | Y |
| nose_thrusters | attitude thrusters under the spar behind the core | 2 / 2 | Y | Y | Y |
| core | the bright core just aft of the ring's centre, the spar and the gun he | 1 / 1 | Y | Y | Y |
| cage | small curved shade plates round the core's hub, broken by gaps the lig | 6 / 6 | Y | Y | Y |
| spar | the layered spar: a slim chamfered beam from the core to the stern blo | 1 / 1 | Y | Y | Y |
| spar_plates | even, aligned panels along the spar | 2 / 1 | Y | Y | Y |
| capbank | the stepped capacitor housing on the spar's dorsal line aft of the cor | 1 / 1 | Y | Y | Y |

### mid/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| core | the bright core just aft of the ring's centre, the spar and the gun he | 1 / 1 | Y | Y | Y |

### stern/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| spar | the layered spar: a slim chamfered beam from the core to the stern blo | 1 / 1 | Y | Y | Y |
| spar_plates | even, aligned panels along the spar | 2 / 1 | Y | Y | Y |
| stern_block | the stern block: a faceted chamfered block where the spar thickens bef | 1 / 1 | Y | Y | Y |
| engine | one engine at the stern: the broad eclipse ring of pale light | 1 / 1 | Y | Y | Y |

### stern/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| spar | the layered spar: a slim chamfered beam from the core to the stern blo | 1 / 1 | Y | Y | Y |
| capbank | the stepped capacitor housing on the spar's dorsal line aft of the cor | 1 / 1 | Y | Y | Y |
| stern_block | the stern block: a faceted chamfered block where the spar thickens bef | 1 / 1 | Y | Y | Y |
| engine | one engine at the stern: the broad eclipse ring of pale light | 1 / 1 | Y | Y | Y |
| stern_thrusters | attitude thrusters on the stern block's flanks | 2 / 2 | Y | Y | Y |
| lamps | corona strip lights on the stern block's flanks (the beauty's green li | 4 / 4 | Y | Y | Y |
| vents | heat slot panels on the stern block's flanks | 2 / 2 | Y | Y | Y |

### stern/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| stern_block | the stern block: a faceted chamfered block where the spar thickens bef | 1 / 1 | Y | Y | Y |
| engine | one engine at the stern: the broad eclipse ring of pale light | 1 / 1 | Y | Y | Y |
| hatches | hatches on the stern block's belly | 2 / 2 | Y | Y | Y |


## Structure per cell: distinct masses (blocks, tiers, belts), concept against build

Concept counts read off the concept sheet by eye (E14 concept: bow, the ring's plates, the hoop and spokes, the gun heart and its muzzle; midships, the core in its cage, the spar, the dorsal housing; stern, the spar, the stern block and the engine ring); build counts are the model's registered masses whose station range overlaps the third (below: masses reaching within 0.8 of the belly).

| Cell | Concept | Build | Build masses |
|---|---:|---:|---|
| bow/top | 3 | 7 | Gun heart; Focus collar; Hoop; Ring plate at 0 degrees; Ring plate at 90 degrees; Ring plate at 180 degrees; Ring plate at 270 degrees |
| bow/side | 3 | 6 | Gun heart; Focus collar; Hoop; Ring plate at 0 degrees; Ring plate at 90 degrees; Ring plate at 270 degrees |
| bow/below | no view | 1 | Ring plate at 270 degrees |
| mid/top | 3 | 2 | Hull: the spar and the stern block; Capacitor housing |
| mid/side | 3 | 2 | Hull: the spar and the stern block; Capacitor housing |
| mid/below | no view | 0 |  |
| stern/top | 3 | 2 | Hull: the spar and the stern block; Capacitor housing |
| stern/side | 3 | 2 | Hull: the spar and the stern block; Capacitor housing |
| stern/below | no view | 0 |  |

## Proportions: length to beam and length to height, concept against build (the Board on round 3)

Measured the same way on both: the concept sheet's top and side views and the blockout's top and side renders, bow left. Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length (dishes, guns and antennas sticking out at a few stations do not count).

| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |
|---|---:|---:|---:|---:|
| concept | 1.02 | 0.36 | 1.10 | 0.79 |
| build | 1.58 | 1.58 | 12.52 | 11.58 |

Lines not present, shaped and detailed without a reason: 0.
