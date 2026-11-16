# hegemony_HF1D parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/hegemony/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing, and its job: what it does on the ship (R221: a part with no job is cut). Source:
`tools/blender/build_sheets/ships/hegemony_HF1D_inv.py`.

| ID | Job | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---|---:|---|---|---|
| wedge | the craft's one body: it carries the guns, the pilot, the reactor and the drive, and meets fire point first | hull | one sleek machined wedge: a flat deck, a stepped flank, a flat belly; a slim prow point widening to the stern third, the stern corners cut | 1 | bow/top, bow/side, bow/below, mid/top, mid/side, mid/below, stern/top, stern/side, stern/below | the deck chamfer, the three flank layers, the belly chamfer (no wing: the hull keeps HF1C's depth) | picture |
| wedge_panels | the hull's armour: flush machined panels in an even grid (two module sizes) | plate | flush panels over the deck and the flank layers | 1 | bow/top, bow/side, mid/top, mid/side, stern/top, stern/side | flush slabs with machined chamfers and seam gaps, every third row split in four | picture |
| belly_panels | the belly's armour | plate | flush panels over the flat belly (the concept shows no underside) | 1 | bow/below, mid/below, stern/below | flush slabs with machined chamfers and seam gaps | designed |
| guns | the interceptor guns (data.js guns T, 3 shots): the wing's only weapon | gun | three barrels grouped tight in one cassette on a flush ring, sunk in a framed recess at the prow (the concept's cassette of three grouped muzzles in one framed recess) | 1 | bow/top, bow/side | the framed recess, a flush ring, a low flat housing, a mantlet, the cassette box with coil bands and a trim mouth, three barrels with coil rings, muzzles, dark bores and blue lenses (R221) | picture |
| sensor_slit | the pilot's view out: no canopy (Ryan, R254), a slit in its own slot above the recess | slit | one dark sensor slit in the ridge's sloped front face (the render lights it blue; the sheet keeps it dark (round 3 notes)) | 1 | bow/top | a machined trim frame round a recessed pane | picture |
| ridge | the spine: the armoured run that carries power and the pilot's cell from the bow block to the reactor | spine | a low broad flat-topped ridge, squared in section, no taller than the stern block | 1 | bow/top, mid/top, mid/side, stern/top | the flat top and its chamfers, the sloped front face, the side walls | picture |
| ridge_panels | the ridge's armour | plate | flush panels over the ridge's top and sides | 1 | mid/top, stern/top | flush slabs with machined chamfers and seam gaps | picture |
| edging | the stepped plate edging (HF1B): the flank armour laid in three stepped layers, each over the one above it | rail | three stepped flank layers along the whole hull, flush and shallow | 1 | bow/side, mid/side, stern/side | the steps between layers, each layer's face, the blue line on the upper step | picture |
| blue_line | the faction's running light: the implant-blue line that pulses in time across the fleet (factions.md) | band | implant-blue strips along the upper edging step and the ridge's foot (the concept's blue glow along the edging and the ridge) | 1 | bow/side, mid/side, mid/top, stern/side | thin raised light strips | picture |
| module_bands | the joints between the craft's modules, where it gives way (factions.md: in modules) | band | three trim bands round the hull: at the bow block, midships and the stern block (the concept's cross seams in the panel grid) | 1 | bow/top, mid/top, stern/top, mid/side | a raised trim band, its seam | designed |
| stern_block | the armoured block across the stern: it holds the reactor and the drive | tier | a raised block across the stern, a sloped front face, chamfered top edges | 1 | stern/top, stern/side | its sloped front face, its flat roof, the drive pod standing out of its aft face | picture |
| block_panels | the stern block's armour | plate | flush panels over the block's roof and sides | 1 | stern/top | flush slabs with machined chamfers and seam gaps | picture |
| drive | drive (sp 6): the one recessed ion-blue slit, a row of three cells inside an armoured pod (the owner's rule for craft) | engine | one rectangular slit across the stern, three cells behind upright guide vanes, in an armoured pod | 1 | stern/top, stern/side | a machined lip, the tapering blue lining, the blue-white throat plate, the vanes, the pod's walls and trim band | picture |

Kit sub-parts per type (what DETAILED checks):

- band: band, seam, strip
- engine: housing, lip, lining, throat, vane, band
- gun: ring, housing, mantlet, barrel, coil, muzzle, bore
- hull: facet, step, chamfer
- plate: panel, seam, module
- rail: facet, step, strip
- slit: frame, glass
- spine: (hull shaping, checked by eye on the side-by-side)
- tier: face, roof, opening

Left as surface, and why:

- The panel grid's small seams and stencils: the Hegemony paint stack (issue 780, applied later) draws the fine seams; the sheet models the panels.
- Hatches, thrusters and lamps: below what the battle camera shows on a 3.84 unit craft, and the drive turns it; not built.

## Every built part has a job (R221)

Built kit parts: 14; parts whose inventory id names no line with a job: 0.

## Per cell: present, shaped, detailed (from the model, hegemony_HF1D_model.json)

Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.

### bow/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| wedge | one sleek machined wedge: a flat deck, a stepped flank, a flat belly;  | 1 / 1 | Y | Y | Y |
| wedge_panels | flush panels over the deck and the flank layers | 2 / 1 | Y | Y | Y |
| guns | three barrels grouped tight in one cassette on a flush ring, sunk in a | 1 / 1 | Y | Y | Y |
| sensor_slit | one dark sensor slit in the ridge's sloped front face | 1 / 1 | Y | Y | Y |
| ridge | a low broad flat-topped ridge, squared in section, no taller than the  | 1 / 1 | Y | Y | Y |
| module_bands | three trim bands round the hull: at the bow block, midships and the st | 1 / 1 | Y | Y | Y |

### bow/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| wedge | one sleek machined wedge: a flat deck, a stepped flank, a flat belly;  | 1 / 1 | Y | Y | Y |
| wedge_panels | flush panels over the deck and the flank layers | 2 / 1 | Y | Y | Y |
| guns | three barrels grouped tight in one cassette on a flush ring, sunk in a | 1 / 1 | Y | Y | Y |
| edging | three stepped flank layers along the whole hull, flush and shallow | 1 / 1 | Y | Y | Y |
| blue_line | implant-blue strips along the upper edging step and the ridge's foot | 1 / 1 | Y | Y | Y |

### bow/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| wedge | one sleek machined wedge: a flat deck, a stepped flank, a flat belly;  | 1 / 1 | Y | Y | Y |
| belly_panels | flush panels over the flat belly | 1 / 1 | Y | Y | Y |

### mid/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| wedge | one sleek machined wedge: a flat deck, a stepped flank, a flat belly;  | 1 / 1 | Y | Y | Y |
| wedge_panels | flush panels over the deck and the flank layers | 2 / 1 | Y | Y | Y |
| ridge | a low broad flat-topped ridge, squared in section, no taller than the  | 1 / 1 | Y | Y | Y |
| ridge_panels | flush panels over the ridge's top and sides | 1 / 1 | Y | Y | Y |
| blue_line | implant-blue strips along the upper edging step and the ridge's foot | 1 / 1 | Y | Y | Y |
| module_bands | three trim bands round the hull: at the bow block, midships and the st | 1 / 1 | Y | Y | Y |

### mid/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| wedge | one sleek machined wedge: a flat deck, a stepped flank, a flat belly;  | 1 / 1 | Y | Y | Y |
| wedge_panels | flush panels over the deck and the flank layers | 2 / 1 | Y | Y | Y |
| ridge | a low broad flat-topped ridge, squared in section, no taller than the  | 1 / 1 | Y | Y | Y |
| edging | three stepped flank layers along the whole hull, flush and shallow | 1 / 1 | Y | Y | Y |
| blue_line | implant-blue strips along the upper edging step and the ridge's foot | 1 / 1 | Y | Y | Y |
| module_bands | three trim bands round the hull: at the bow block, midships and the st | 1 / 1 | Y | Y | Y |

### mid/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| wedge | one sleek machined wedge: a flat deck, a stepped flank, a flat belly;  | 1 / 1 | Y | Y | Y |
| belly_panels | flush panels over the flat belly | 1 / 1 | Y | Y | Y |

### stern/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| wedge | one sleek machined wedge: a flat deck, a stepped flank, a flat belly;  | 1 / 1 | Y | Y | Y |
| wedge_panels | flush panels over the deck and the flank layers | 2 / 1 | Y | Y | Y |
| ridge | a low broad flat-topped ridge, squared in section, no taller than the  | 1 / 1 | Y | Y | Y |
| ridge_panels | flush panels over the ridge's top and sides | 1 / 1 | Y | Y | Y |
| module_bands | three trim bands round the hull: at the bow block, midships and the st | 1 / 1 | Y | Y | Y |
| stern_block | a raised block across the stern, a sloped front face, chamfered top ed | 1 / 1 | Y | Y | Y |
| block_panels | flush panels over the block's roof and sides | 1 / 1 | Y | Y | Y |
| drive | one rectangular slit across the stern, three cells behind upright guid | 1 / 1 | Y | Y | Y |

### stern/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| wedge | one sleek machined wedge: a flat deck, a stepped flank, a flat belly;  | 1 / 1 | Y | Y | Y |
| wedge_panels | flush panels over the deck and the flank layers | 2 / 1 | Y | Y | Y |
| edging | three stepped flank layers along the whole hull, flush and shallow | 1 / 1 | Y | Y | Y |
| blue_line | implant-blue strips along the upper edging step and the ridge's foot | 1 / 1 | Y | Y | Y |
| stern_block | a raised block across the stern, a sloped front face, chamfered top ed | 1 / 1 | Y | Y | Y |
| drive | one rectangular slit across the stern, three cells behind upright guid | 1 / 1 | Y | Y | Y |

### stern/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| wedge | one sleek machined wedge: a flat deck, a stepped flank, a flat belly;  | 1 / 1 | Y | Y | Y |
| belly_panels | flush panels over the flat belly | 1 / 1 | Y | Y | Y |


## Structure per cell: distinct masses (blocks, tiers, belts), concept against build

Concept counts read off the concept sheet by eye (HF1D slim render, by eye (no true views): bow, the slim point, the framed recess and the ridge's front; midships, the deck, the ridge and the stepped edging; stern, the deck, the ridge, the stern block and the drive slit); build counts are the model's registered masses whose station range overlaps the third (below: masses reaching within 0.8 of the belly).

| Cell | Concept | Build | Build masses |
|---|---:|---:|---|
| bow/top | 3 | 2 | Hull: the machined wedge; The spine ridge |
| bow/side | 2 | 2 | Hull: the machined wedge; The spine ridge |
| bow/below | no view | 2 | Hull: the machined wedge; The spine ridge |
| mid/top | 3 | 2 | Hull: the machined wedge; The spine ridge |
| mid/side | 3 | 2 | Hull: the machined wedge; The spine ridge |
| mid/below | no view | 2 | Hull: the machined wedge; The spine ridge |
| stern/top | 4 | 3 | Hull: the machined wedge; The spine ridge; The stern block |
| stern/side | 4 | 3 | Hull: the machined wedge; The spine ridge; The stern block |
| stern/below | no view | 3 | Hull: the machined wedge; The spine ridge; The stern block |

## Proportions: length to beam and length to height, concept against build (the Board on round 3)

Measured the same way on both: the concept sheet's top and side views and the blockout's top and side renders, bow left. Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length (dishes, guns and antennas sticking out at a few stations do not count).

| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |
|---|---:|---:|---:|---:|
| concept | 1.68 | 1.68 | 2.94 | 2.94 |
| build | 2.43 | 8.99 | 3.60 | 10.50 |

Lines not present, shaped and detailed without a reason: 0.
