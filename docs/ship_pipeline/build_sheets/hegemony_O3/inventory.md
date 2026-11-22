# hegemony_O3 parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/hegemony/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing, and its job: what it does on the ship (R221: a part with no job is cut). Source:
`tools/blender/build_sheets/ships/hegemony_O3_inv.py`.

| ID | Job | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---|---:|---|---|---|
| module | holds the relay core, the emitter and the cooling plant | hull | one square relay module with chamfered edges | 1 | mid/top, mid/side | flat faces, chamfered edges, a stepped rear edge | picture |
| lens | the relay itself: the objective the fleets fight over (designs.md: ONE oversized recessed blue lens) | relay_lens | a recessed lens in the forward face, stepped machined rings, a thin blue ring at the mouth | 1 | bow/top, bow/side | a square face block, stepped rings, a glowing lens, corner bolts | picture |
| module_bands | the relay-ring module joints: the relay breaks into modules here | band | two raised trim rings with a deep seam | 1 | mid/top, mid/side | two trim rings and a dark seam ring | picture |
| rails | the twin-rail cradle frame: tenders moor on it and it carries the relay's power and signal lines | rail | four rails, two either side at two heights, running along the module | 1 | bow/top, mid/top, stern/top, bow/side, mid/side, stern/side | a long chamfered beam, flush panels, end caps, blue light strips | picture |
| blue_line | implant-blue running lights along the rails (factions.md: a line of blue light) | band | short blue strips along each rail's outer face | 1 | bow/side, mid/side, stern/side | raised strips that glow | picture |
| cradle | clamps the rails to the module (designs.md: an open twin-rail cradle) | rail | a saddle on each side of the module's middle, an arm and a clamp round each rail | 1 | mid/top, mid/side | a saddle block, arms, clamp blocks with trim bands | picture |
| cradle_latches | lock each cradle clamp round its rail | latch | a latch pair on each rail clamp | 4 | mid/side | a base plate, machined clamp heads | designed |
| mooring | tugs and tenders make fast to the relay (designs.md: four mooring collars on the rails) | latch | a mooring collar with a latch on each rail | 4 | bow/side, stern/side | a trim sleeve round the rail, clamp heads | picture |
| mooring_collars | the collar sleeves the mooring latches sit on | band | a trim sleeve round each rail | 1 | bow/side, stern/side | a raised trim ring round the rail | picture |
| sensor_fin | the relay's own fleet link and station-keeping sensors | antenna | one low sensor fin aft on the module top | 1 | mid/top, mid/side | a root plinth, a raked fin, sensor windows, a lens strip | picture |
| thrusters | station keeping: the relay holds its place (designs.md: no propulsion) | thruster | eight small thruster pads on the module's chamfered edges | 8 | mid/side | a machined block, rectangular nozzle throats with depth | picture |
| module_panels | module armour: flush panels in the even grid | plate | flush panels on the module's flat faces | 1 | mid/top, mid/side | machined slabs with seams, two module sizes | picture |
| hatches | maintenance access to the relay core and the stores | hatch | a deck hatch and a belly hatch | 2 | mid/top | a rim, a flush door, a seam, a grip | designed |
| vents | the relay core's and the emitter's heat louvres | vent | louvres on the module top | 4 | mid/top | a machined frame, straight slats over a dark recess | designed |

Kit sub-parts per type (what DETAILED checks):

- antenna: root, fin, window, lens
- band: band, seam, strip
- hatch: rim, door, seam, grip
- hull: facet, step, chamfer
- latch: base, clamp
- plate: panel, seam, module
- rail: facet, step, strip
- relay_lens: face, ring, lens, glow
- thruster: block, nozzle
- vent: frame, slat

Left as surface, and why:

- Stencil marks and the steel-blue trim tone: paint (the Hegemony stack), not modelled.
- The lens ring's pulse: a game effect.

## Every built part has a job (R221)

Built kit parts: 31; parts whose inventory id names no line with a job: 0.

## Per cell: present, shaped, detailed (from the model, hegemony_O3_model.json)

Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.

### bow/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| lens | a recessed lens in the forward face, stepped machined rings, a thin bl | 1 / 1 | Y | Y | Y |
| rails | four rails, two either side at two heights, running along the module | 1 / 1 | Y | Y | Y |

### bow/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| lens | a recessed lens in the forward face, stepped machined rings, a thin bl | 1 / 1 | Y | Y | Y |
| rails | four rails, two either side at two heights, running along the module | 1 / 1 | Y | Y | Y |
| blue_line | short blue strips along each rail's outer face | 1 / 1 | Y | Y | Y |
| mooring | a mooring collar with a latch on each rail | 4 / 4 | Y | Y | Y |
| mooring_collars | a trim sleeve round each rail | 1 / 1 | Y | Y | Y |

### bow/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| - | nothing listed in this cell | | | | |

### mid/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| module | one square relay module with chamfered edges | 1 / 1 | Y | Y | Y |
| module_bands | two raised trim rings with a deep seam | 1 / 1 | Y | Y | Y |
| rails | four rails, two either side at two heights, running along the module | 1 / 1 | Y | Y | Y |
| cradle | a saddle on each side of the module's middle, an arm and a clamp round | 1 / 1 | Y | Y | Y |
| sensor_fin | one low sensor fin aft on the module top | 1 / 1 | Y | Y | Y |
| module_panels | flush panels on the module's flat faces | 1 / 1 | Y | Y | Y |
| hatches | a deck hatch and a belly hatch | 2 / 2 | Y | Y | Y |
| vents | louvres on the module top | 4 / 4 | Y | Y | Y |

### mid/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| module | one square relay module with chamfered edges | 1 / 1 | Y | Y | Y |
| module_bands | two raised trim rings with a deep seam | 1 / 1 | Y | Y | Y |
| rails | four rails, two either side at two heights, running along the module | 1 / 1 | Y | Y | Y |
| blue_line | short blue strips along each rail's outer face | 1 / 1 | Y | Y | Y |
| cradle | a saddle on each side of the module's middle, an arm and a clamp round | 1 / 1 | Y | Y | Y |
| cradle_latches | a latch pair on each rail clamp | 4 / 4 | Y | Y | Y |
| sensor_fin | one low sensor fin aft on the module top | 1 / 1 | Y | Y | Y |
| thrusters | eight small thruster pads on the module's chamfered edges | 8 / 8 | Y | Y | Y |
| module_panels | flush panels on the module's flat faces | 1 / 1 | Y | Y | Y |

### mid/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| - | nothing listed in this cell | | | | |

### stern/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| rails | four rails, two either side at two heights, running along the module | 1 / 1 | Y | Y | Y |

### stern/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| rails | four rails, two either side at two heights, running along the module | 1 / 1 | Y | Y | Y |
| blue_line | short blue strips along each rail's outer face | 1 / 1 | Y | Y | Y |
| mooring | a mooring collar with a latch on each rail | 4 / 4 | Y | Y | Y |
| mooring_collars | a trim sleeve round each rail | 1 / 1 | Y | Y | Y |

### stern/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| - | nothing listed in this cell | | | | |


## Structure per cell: distinct masses (blocks, tiers, belts), concept against build

Concept counts read off the concept sheet by eye (Relay sheet: forward, the lens face and the rail ends; midships, the module, the cradle and the fin; aft, the rail ends (the top view shows two rails, the upper over the lower)); build counts are the model's registered masses whose station range overlaps the third (below: masses reaching within 0.8 of the belly).

| Cell | Concept | Build | Build masses |
|---|---:|---:|---|
| bow/top | 2 | 4 | Rail, port upper; Rail, port lower; Rail, starboard upper; Rail, starboard lower |
| bow/side | 2 | 2 | Rail, port upper; Rail, port lower |
| bow/below | no view | 2 | Rail, port lower; Rail, starboard lower |
| mid/top | 5 | 7 | Relay module; Rail, port upper; Rail, port lower; Rail, starboard upper; Rail, starboard lower; Cradle, port; Cradle, starboard |
| mid/side | 4 | 4 | Relay module; Rail, port upper; Rail, port lower; Cradle, port |
| mid/below | no view | 5 | Relay module; Rail, port lower; Rail, starboard lower; Cradle, port; Cradle, starboard |
| stern/top | 2 | 5 | Relay module; Rail, port upper; Rail, port lower; Rail, starboard upper; Rail, starboard lower |
| stern/side | 2 | 3 | Relay module; Rail, port upper; Rail, port lower |
| stern/below | no view | 3 | Relay module; Rail, port lower; Rail, starboard lower |

## Proportions: length to beam and length to height, concept against build (the Board on round 3)

Measured the same way on both: the concept sheet's top and side views and the blockout's top and side renders, bow left. Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length (dishes, guns and antennas sticking out at a few stations do not count).

| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |
|---|---:|---:|---:|---:|
| concept | 2.28 | 3.63 | 2.68 | 4.52 |
| build | 1.70 | 2.78 | 1.82 | 3.40 |

Lines not present, shaped and detailed without a reason: 0.
