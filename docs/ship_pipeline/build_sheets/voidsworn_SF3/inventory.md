# voidsworn_SF3 parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/voidsworn/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing, and its job: what it does on the ship (R221: a part with no job is cut). Source:
`tools/blender/build_sheets/ships/voidsworn_SF3_inv.py`.

| ID | Job | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---|---:|---|---|---|
| blade | the craft's one body: it carries the gun, the pilot, the reactor and the drives, and meets fire edge on | hull | one narrow forged blade: a low spine strip, the deck, upper facets sloping out to a thin knife edge, lower facets, a flat belly; widest at the stern third | 1 | bow/top, bow/side, bow/below, mid/top, mid/side, mid/below, stern/side, stern/below | angled facets meeting at the knife edge, the spine strip, a flat belly (no wing, no sweep, no aerofoil) | picture |
| blade_plates | armour over the blade: forged plates in rows, sleek triangles on the upper facets (R243) | plate | forged plates over the deck, the facets and the belly | 1 | bow/top, bow/side, bow/below, mid/top, mid/side, mid/below | slabs with bevels, reinforcing steps and rivet lines | picture |
| guns | the interceptor guns (data.js guns T, 3 shots): the wing's only weapon | gun | three barrels in one emitter cluster on a shallow traverse ring, in an armoured well on the blade's back near the bow (the concept's three muzzles in a dorsal bow recess) | 1 | bow/top, bow/side | a riveted well rim, a traverse ring, a low faceted housing, a block mantlet, a banded cluster jacket, three flared muzzles with dark bores (R221) | picture |
| stern_block | the armoured block the blade thickens into: it holds the pilot, the reactor and the drives | hull | a raised armoured block on the blade's stern, a sloping forward face, chamfered shoulders, upright flanks | 1 | mid/top, mid/side, stern/top, stern/side | the sloping face, the shoulder chamfers, the flanks | picture |
| block_plates | armour over the stern block | plate | forged plates over the block's top and flanks | 1 | mid/top, stern/top, stern/side | slabs with bevels, reinforcing steps and rivet lines | picture |
| sensor_slit | the pilot's view out: no canopy (Ryan, R254), an armoured slit at most | slit | one ember-lit armoured slit in the stern block's sloping face (replaces any canopy; the concept's dark slot near the bow is the gun well) | 1 | mid/top | a forged frame round a recessed ember pane, a brow | designed |
| spire | sheds the drive reactor's heat (a hot reactor in vacuum must shed it, lore 2.5): the flagship's spire row reduced to one | radiator | one short radiator spire on the stern block, square-topped, four ember fins a side | 1 | mid/top, mid/side, stern/top | a forged root socket with an ember glow at its foot, a column (iron posts round a dark core), the ember fins, a forged cap, gusset braces | picture |
| drives | drive (sp 6): two deep bells, nozzle clusters inside armoured blocks (the owner's rule for craft) | engine | two deep bells sunk in eight-sided armoured cowls in the stern face | 2 | stern/top, stern/side, stern/below | an eight-sided cowl with a riveted face, a band and a collar, the bell sunk in it with a lip and a stiffener ring, an ember lining, a hot throat, a glowing plug cone | picture |
| louvres | the drive room's heat louvres | vent | one heat louvre on each flank of the stern block (the concept's glowing flank slats) | 2 | stern/side | a forged frame, slanted slats over an ember-lit recess | picture |

Kit sub-parts per type (what DETAILED checks):

- engine: housing, band, collar, bell, lining, throat, plug, bellring
- gun: ring|port, mantlet, barrel, jacket, muzzle, bore
- hull: facet, step, chamfer
- plate: slab, step, bevel, rivet
- radiator: root, column, cap, fin, bar, brace
- slit: frame, glass
- vent: frame, slat

Left as surface, and why:

- The frost-white oath stripe along the blade edge, the trim lines and wear: paint, by the Sunward paint stack (issue 756, applied later), not modelled.
- The concept's glyph-like hull decals: generator noise, not markings (design_notes_757.md, production notes).
- Hatches, lamps and attitude thrusters: below what the battle camera shows on a 3.84 unit craft, and the drives turn it; not built.

## Every built part has a job (R221)

Built kit parts: 15; parts whose inventory id names no line with a job: 0.

## Per cell: present, shaped, detailed (from the model, voidsworn_SF3_model.json)

Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.

### bow/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| blade | one narrow forged blade: a low spine strip, the deck, upper facets slo | 1 / 1 | Y | Y | Y |
| blade_plates | forged plates over the deck, the facets and the belly | 5 / 1 | Y | Y | Y |
| guns | three barrels in one emitter cluster on a shallow traverse ring, in an | 1 / 1 | Y | Y | Y |

### bow/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| blade | one narrow forged blade: a low spine strip, the deck, upper facets slo | 1 / 1 | Y | Y | Y |
| blade_plates | forged plates over the deck, the facets and the belly | 5 / 1 | Y | Y | Y |
| guns | three barrels in one emitter cluster on a shallow traverse ring, in an | 1 / 1 | Y | Y | Y |

### bow/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| blade | one narrow forged blade: a low spine strip, the deck, upper facets slo | 1 / 1 | Y | Y | Y |
| blade_plates | forged plates over the deck, the facets and the belly | 5 / 1 | Y | Y | Y |

### mid/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| blade | one narrow forged blade: a low spine strip, the deck, upper facets slo | 1 / 1 | Y | Y | Y |
| blade_plates | forged plates over the deck, the facets and the belly | 5 / 1 | Y | Y | Y |
| stern_block | a raised armoured block on the blade's stern, a sloping forward face,  | 1 / 1 | Y | Y | Y |
| block_plates | forged plates over the block's top and flanks | 1 / 1 | Y | Y | Y |
| sensor_slit | one ember-lit armoured slit in the stern block's sloping face | 1 / 1 | Y | Y | Y |
| spire | one short radiator spire on the stern block, square-topped, four ember | 1 / 1 | Y | Y | Y |

### mid/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| blade | one narrow forged blade: a low spine strip, the deck, upper facets slo | 1 / 1 | Y | Y | Y |
| blade_plates | forged plates over the deck, the facets and the belly | 5 / 1 | Y | Y | Y |
| stern_block | a raised armoured block on the blade's stern, a sloping forward face,  | 1 / 1 | Y | Y | Y |
| spire | one short radiator spire on the stern block, square-topped, four ember | 1 / 1 | Y | Y | Y |

### mid/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| blade | one narrow forged blade: a low spine strip, the deck, upper facets slo | 1 / 1 | Y | Y | Y |
| blade_plates | forged plates over the deck, the facets and the belly | 5 / 1 | Y | Y | Y |

### stern/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| stern_block | a raised armoured block on the blade's stern, a sloping forward face,  | 1 / 1 | Y | Y | Y |
| block_plates | forged plates over the block's top and flanks | 1 / 1 | Y | Y | Y |
| spire | one short radiator spire on the stern block, square-topped, four ember | 1 / 1 | Y | Y | Y |
| drives | two deep bells sunk in eight-sided armoured cowls in the stern face | 2 / 2 | Y | Y | Y |

### stern/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| blade | one narrow forged blade: a low spine strip, the deck, upper facets slo | 1 / 1 | Y | Y | Y |
| stern_block | a raised armoured block on the blade's stern, a sloping forward face,  | 1 / 1 | Y | Y | Y |
| block_plates | forged plates over the block's top and flanks | 1 / 1 | Y | Y | Y |
| drives | two deep bells sunk in eight-sided armoured cowls in the stern face | 2 / 2 | Y | Y | Y |
| louvres | one heat louvre on each flank of the stern block | 2 / 2 | Y | Y | Y |

### stern/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| blade | one narrow forged blade: a low spine strip, the deck, upper facets slo | 1 / 1 | Y | Y | Y |
| drives | two deep bells sunk in eight-sided armoured cowls in the stern face | 2 / 2 | Y | Y | Y |


## Structure per cell: distinct masses (blocks, tiers, belts), concept against build

Concept counts read off the concept sheet by eye (SF3 beauty, by eye (no true views): bow, the blade and the gun recess; midships, the blade, the block's face, the spire and the flank panels; stern, the block, the two drive drums and the flank slats); build counts are the model's registered masses whose station range overlaps the third (below: masses reaching within 0.8 of the belly).

| Cell | Concept | Build | Build masses |
|---|---:|---:|---|
| bow/top | 2 | 1 | Hull: the forged blade |
| bow/side | 2 | 1 | Hull: the forged blade |
| bow/below | no view | 1 | Hull: the forged blade |
| mid/top | 4 | 1 | Hull: the forged blade |
| mid/side | 3 | 1 | Hull: the forged blade |
| mid/below | no view | 1 | Hull: the forged blade |
| stern/top | 4 | 2 | Hull: the forged blade; Radiator spire R1 |
| stern/side | 4 | 2 | Hull: the forged blade; Radiator spire R1 |
| stern/below | no view | 2 | Hull: the forged blade; Radiator spire R1 |

## Proportions: length to beam and length to height, concept against build (the Board on round 3)

Measured the same way on both: the concept sheet's top and side views and the blockout's top and side renders, bow left. Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length (dishes, guns and antennas sticking out at a few stations do not count).

| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |
|---|---:|---:|---:|---:|
| concept | 2.25 | 2.25 | 4.35 | 4.35 |
| build | 4.30 | 4.30 | 4.81 | 15.48 |

Lines not present, shaped and detailed without a reason: 0.
