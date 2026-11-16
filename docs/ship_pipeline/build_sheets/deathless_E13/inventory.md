# deathless_E13 parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/eclipse/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing, and its job: what it does on the ship (R221: a part with no job is cut). Source:
`tools/blender/build_sheets/ships/deathless_E13_inv.py`.

| ID | Job | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---|---:|---|---|---|
| fan | the shade: five layered plates held forward over the body, the faction's sunshade toward the enemy; they peel first when hit | shade | the fan: five long overlapping shade plates (a crest plate on the spine, two a side), gathered at the stern by the engine collar and fanning forward over the body, their tips reaching past the nose's flanks; each a separate slab with a stepped second layer on its root half and a thin green-white corona line along its outer rim (designs.md says five; the beauty and the sheet show more blade edges, which here are the plates' stepped layers) | 5 | bow/top, bow/side, bow/below, mid/top, mid/side, mid/below, stern/top, stern/side | a broad curved band, a stepped layer, a corona line on the rim, even panels | picture |
| fan_plates | armour over the shade plates | plate | even, aligned panels over the plates' upper faces (R243) | 1 | bow/top, mid/top, stern/top | chamfered slabs with steps and flush fasteners | picture |
| body | the dart: carries the core, the crew decks and the archive vault under the fan | hull | the short dart body under the fan: a chamfered faceted section, a pointed nose ahead of the plate tips | 1 | bow/top, bow/side, bow/below, mid/side, mid/below | bevels, steps, an overhang | picture |
| body_plates | armour over the dart | plate | even, aligned panels along the dart | 1 | bow/side, bow/below, mid/below | chamfered slabs with steps and flush fasteners | picture |
| nose_thrusters | attitude control at the bow: turn the frigate quickly (speed 4, evasion 14) | thruster | attitude thrusters on the dart's nose flanks | 2 | bow/side | a block, slot nozzles | designed |
| core | the trapped light core: powers the ship and its phase and regeneration (data.js ab phase, regen 2) | core | the bright core in the gap between the crest plate and the inner plates, partly covered | 1 | mid/top, mid/side | hub collars, a bright sphere, gimbal rings, meridian bars | picture |
| lamps | the corona strip lights along the dart: the faction's only lights besides the corona, the core and the engine ring | lamp | corona strip lights low on the dart's flanks | 4 | mid/side, bow/side | a housing, a green-white bar lens | designed |
| stern_block | holds the engine, the engine room, the gun's magazine and the fan's roots | tier | the stern block: a faceted chamfered block behind the core, a stepped roof under the gun | 1 | stern/top, stern/side, stern/below | faceted faces, a stepped roof, openings (vents, hatches) | picture |
| root_collar | gathers and carries the five plates' roots on the stern block | pylon | the root collar: a stepped band round the stern block where the plates gather | 1 | stern/top, stern/side | a stepped web, plates | picture |
| main_gun | the null cannon (gauss T): the frigate's one weapon, an armour-piercing rail gun that turns all round | nullcannon | the one gun: a low housing on the spine at the fan's root, firing forward over the plates (data.js gauss T) (the beauty underplays it (designs.md); the sheet draws it on the spine at the fan's root) | 1 | stern/top, stern/side | a thin round foot, a small oval shell, an arched crescent shade of seamed bevelled plates with a second layer and a corona crest, rod yokes, crescent capacitor fins, two slim round rail pairs with banded collars and shock rings (R221) | picture |
| engine | drive (sp 4, the fastest Eclipse hull): one eclipse-ring engine, no flame | engine | one engine at the stern: the small thin eclipse ring of pale light | 1 | stern/top, stern/side, stern/below | a faceted ribbed drum, a mount collar, vanes, a short bell, a corona ring round a black shade disc (no flame) | picture |
| stern_thrusters | attitude control at the stern | thruster | attitude thrusters on the stern block's flanks | 2 | stern/side | a block, slot nozzles | designed |
| vents | dump heat from the engine room | vent | heat slot panels on the stern block's flanks | 2 | stern/side | a frame, slats | designed |
| hatches | crew and drone access to the stern block | hatch | hatches on the stern block's belly | 2 | stern/below | a rim, a door, a seam, hinges | designed |

Kit sub-parts per type (what DETAILED checks):

- core: hub, sphere, gimbal, bar
- engine: housing, collar, rib, vane, bell, corona, shade
- hatch: rim, door, seam, hinge
- hull: bevel, step, overhang
- lamp: housing, lens
- nullcannon: ring|plate, housing, capacitor, yoke, shade, layer, corona, rail, collar, muzzle
- plate: slab, step, bevel, fastener
- pylon: web, plate
- shade: band, layer, corona, plate
- thruster: block, nozzle
- tier: face, roof, opening
- vent: frame, slat

Left as surface, and why:

- Grime, scuffs and decals: surface texture, painted in the build (recipe stages 4 and 5), not modelled.
- The concept sheet's front view (a tall pinwheel of blades) does not agree with its own plan and side view; the build follows the plan, the side view and the beauty.

## Every built part has a job (R221)

Built kit parts: 30; parts whose inventory id names no line with a job: 0.

## Per cell: present, shaped, detailed (from the model, deathless_E13_model.json)

Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.

### bow/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| fan | the fan: five long overlapping shade plates (a crest plate on the spin | 5 / 5 | Y | Y | Y |
| fan_plates | even, aligned panels over the plates' upper faces (R243) | 5 / 1 | Y | Y | Y |
| body | the short dart body under the fan: a chamfered faceted section, a poin | 1 / 1 | Y | Y | Y |

### bow/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| fan | the fan: five long overlapping shade plates (a crest plate on the spin | 5 / 5 | Y | Y | Y |
| body | the short dart body under the fan: a chamfered faceted section, a poin | 1 / 1 | Y | Y | Y |
| body_plates | even, aligned panels along the dart | 2 / 1 | Y | Y | Y |
| nose_thrusters | attitude thrusters on the dart's nose flanks | 2 / 2 | Y | Y | Y |
| lamps | corona strip lights low on the dart's flanks | 4 / 4 | Y | Y | Y |

### bow/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| fan | the fan: five long overlapping shade plates (a crest plate on the spin | 5 / 5 | Y | Y | Y |
| body | the short dart body under the fan: a chamfered faceted section, a poin | 1 / 1 | Y | Y | Y |
| body_plates | even, aligned panels along the dart | 2 / 1 | Y | Y | Y |

### mid/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| fan | the fan: five long overlapping shade plates (a crest plate on the spin | 5 / 5 | Y | Y | Y |
| fan_plates | even, aligned panels over the plates' upper faces (R243) | 5 / 1 | Y | Y | Y |
| core | the bright core in the gap between the crest plate and the inner plate | 1 / 1 | Y | Y | Y |

### mid/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| fan | the fan: five long overlapping shade plates (a crest plate on the spin | 5 / 5 | Y | Y | Y |
| body | the short dart body under the fan: a chamfered faceted section, a poin | 1 / 1 | Y | Y | Y |
| core | the bright core in the gap between the crest plate and the inner plate | 1 / 1 | Y | Y | Y |
| lamps | corona strip lights low on the dart's flanks | 4 / 4 | Y | Y | Y |

### mid/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| fan | the fan: five long overlapping shade plates (a crest plate on the spin | 5 / 5 | Y | Y | Y |
| body | the short dart body under the fan: a chamfered faceted section, a poin | 1 / 1 | Y | Y | Y |
| body_plates | even, aligned panels along the dart | 2 / 1 | Y | Y | Y |

### stern/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| fan | the fan: five long overlapping shade plates (a crest plate on the spin | 5 / 5 | Y | Y | Y |
| fan_plates | even, aligned panels over the plates' upper faces (R243) | 5 / 1 | Y | Y | Y |
| stern_block | the stern block: a faceted chamfered block behind the core, a stepped  | 1 / 1 | Y | Y | Y |
| root_collar | the root collar: a stepped band round the stern block where the plates | 1 / 1 | Y | Y | Y |
| main_gun | the one gun: a low housing on the spine at the fan's root, firing forw | 1 / 1 | Y | Y | Y |
| engine | one engine at the stern: the small thin eclipse ring of pale light | 1 / 1 | Y | Y | Y |

### stern/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| fan | the fan: five long overlapping shade plates (a crest plate on the spin | 5 / 5 | Y | Y | Y |
| stern_block | the stern block: a faceted chamfered block behind the core, a stepped  | 1 / 1 | Y | Y | Y |
| root_collar | the root collar: a stepped band round the stern block where the plates | 1 / 1 | Y | Y | Y |
| main_gun | the one gun: a low housing on the spine at the fan's root, firing forw | 1 / 1 | Y | Y | Y |
| engine | one engine at the stern: the small thin eclipse ring of pale light | 1 / 1 | Y | Y | Y |
| stern_thrusters | attitude thrusters on the stern block's flanks | 2 / 2 | Y | Y | Y |
| vents | heat slot panels on the stern block's flanks | 2 / 2 | Y | Y | Y |

### stern/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| stern_block | the stern block: a faceted chamfered block behind the core, a stepped  | 1 / 1 | Y | Y | Y |
| engine | one engine at the stern: the small thin eclipse ring of pale light | 1 / 1 | Y | Y | Y |
| hatches | hatches on the stern block's belly | 2 / 2 | Y | Y | Y |


## Structure per cell: distinct masses (blocks, tiers, belts), concept against build

Concept counts read off the concept sheet by eye (E13 concept: bow, the plate tips (two a side) and the nose; midships, the crest plate, two plates a side and the core gap, the dart; stern, the stern block, the plates' roots gathering, the gun housing and the engine ring); build counts are the model's registered masses whose station range overlaps the third (below: masses reaching within 0.8 of the belly).

| Cell | Concept | Build | Build masses |
|---|---:|---:|---|
| bow/top | 4 | 6 | Hull: the dart; Shade plate, crest; Shade plate, inner port; Shade plate, inner starboard; Shade plate, outer port; Shade plate, outer starboard |
| bow/side | 3 | 4 | Hull: the dart; Shade plate, crest; Shade plate, inner port; Shade plate, outer port |
| bow/below | no view | 6 | Hull: the dart; Shade plate, crest; Shade plate, inner port; Shade plate, inner starboard; Shade plate, outer port; Shade plate, outer starboard |
| mid/top | 5 | 6 | Hull: the dart; Shade plate, crest; Shade plate, inner port; Shade plate, inner starboard; Shade plate, outer port; Shade plate, outer starboard |
| mid/side | 4 | 4 | Hull: the dart; Shade plate, crest; Shade plate, inner port; Shade plate, outer port |
| mid/below | no view | 6 | Hull: the dart; Shade plate, crest; Shade plate, inner port; Shade plate, inner starboard; Shade plate, outer port; Shade plate, outer starboard |
| stern/top | 4 | 7 | Stern block; Root collar; Shade plate, crest; Shade plate, inner port; Shade plate, inner starboard; Shade plate, outer port; Shade plate, outer starboard |
| stern/side | 4 | 5 | Stern block; Root collar; Shade plate, crest; Shade plate, inner port; Shade plate, outer port |
| stern/below | no view | 7 | Stern block; Root collar; Shade plate, crest; Shade plate, inner port; Shade plate, inner starboard; Shade plate, outer port; Shade plate, outer starboard |

## Proportions: length to beam and length to height, concept against build (the Board on round 3)

Measured the same way on both: the concept sheet's top and side views and the blockout's top and side renders, bow left. Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length (dishes, guns and antennas sticking out at a few stations do not count).

| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |
|---|---:|---:|---:|---:|
| concept | 1.87 | 9.57 | 3.32 | 12.61 |
| build | 1.79 | 5.12 | 2.42 | 9.49 |

Lines not present, shaped and detailed without a reason: 0.
