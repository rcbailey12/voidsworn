# hegemony_H10 parts inventory (R218)

Written from the concept before modelling, region by region (bow, midships, stern; top, side, below). Each line names the
kit part type (tools/blender/kits/hegemony/parts.py), how many, the blob-sweep cells it shows in, and the sub-parts that
make it read as that thing, and its job: what it does on the ship (R221: a part with no job is cut). Source:
`tools/blender/build_sheets/ships/hegemony_H10_inv.py`.

| ID | Job | Type | What | Count | Cells | Reads as (sub-parts) | Source |
|---|---|---|---|---:|---|---|---|
| wedge | carries the bow, the shoulder turrets, the command deck, the reactor and the lance rooms (factions.md: a heavy thick wedge) | hull | the wedge: a flat deck, chamfered deck edges, upper facets out to the knuckle, the flank band, lower facets, a chine, a flat belly; the shoulder terraces | 1 | bow/top, bow/side, bow/below, mid/top, mid/side, mid/below | facets and chamfers round a vertical band (never a flat wall, R244), the terrace steps | picture |
| bow_face | the blunt armoured bow round the ion trench: it meets fire head on (R183 (1)) | hull | the blunt bow face, chamfered corners, armour plates and a trim frame round the trench mouth | 1 | bow/top, bow/side, bow/below | the wedge's facets running to an upright face, plates round the mouth | picture |
| rails | the twin rails: they carry the crew decks, the plant rooms and the drives (factions.md: a wedge on twin rails) | rail | two chamfered rail blocks in two module tiers (a recessed band at mid height), a gap between them | 1 | mid/top, mid/side, mid/below, stern/top, stern/side, stern/below | chamfered edges, the mid-height recess, the blue strip in it | picture |
| bay_block | the drone hangar between the rails (data.js hangar 1) | tier | the hangar block between the rails' roots, its roof a trough below the rail decks | 1 | mid/top | a face, a roof with the doors, the trough opening | picture |
| module_bands | the joints between hull modules: the hull gives way here (factions.md "How it breaks"); the breach anchors sit on them | band | raised trim rings round the wedge and the rails with a deep double seam between their halves | 1 | bow/top, mid/top, stern/top, bow/side, mid/side, stern/side | two trim rings and a dark seam ring between them | picture |
| blue_line | the implant-blue light strips: the fleet's running lights, pulsing in time (factions.md: a line of blue light) | band | a blue strip along each flank band and in each rail's recess, broken at the module bands | 1 | bow/side, mid/side, stern/side | a raised strip that glows | picture |
| deck_panels | deck armour: flush panels in the even grid of two module sizes (paint direction hegemony.md) | plate | flush deck panels on the wedge and the terraces | 1 | bow/top, mid/top | machined slabs with seams round them, the small-module cells | picture |
| flank_panels | side armour on the wedge's facets | plate | flush panels on the upper and lower facets | 1 | bow/side, mid/side | machined slabs with seams, two module sizes | picture |
| belly_panels | belly armour | plate | flush panels on the belly and the belly armour step | 1 | bow/below, mid/below | machined slabs with seams | designed |
| rail_panels | the rails' armour | plate | flush panels on the rails' decks, flanks and bellies | 1 | mid/top, mid/side, mid/below, stern/top, stern/side, stern/below | machined slabs with seams, two module sizes | picture |
| lances | the heavy plasma lances (hturbo P and hturbo S, 3 shots each): the main broadside fire, one turret a side | gun | two low wide lance turrets sunk in the shoulder terraces, two short thick barrels each | 2 | mid/top, mid/side | a flush ring, a faceted housing with a sloped glacis, armoured cheeks, a capacitor bustle, a mantlet, breeches, barrels with coil rings, vented muzzle shrouds, blue-lit bores (R221) | picture |
| ion_trench | the ion cannon (ion F, 1 shot): strips shields head on (lore 3.4) | ion_trench | the emitter trench recessed in the blunt bow face (R183 (1)) | 1 | bow/top, bow/side | lined walls, stacked field coil plates, an emitter block, a blue lens, feed conduits | picture |
| pickets | the picket lasers (flak T, 3 shots): point defence against craft from below | gun | two small twin turrets on the belly armour step | 2 | bow/below | a flush ring, an eight-sided housing, a sensor eye, two short emitters with coil collars and lens tips (R221) | designed |
| sensor_fin | the ship's sensors: the one low sensor fin (factions.md), over the command deck | antenna | a low swept fin on the centreline between the turrets | 1 | mid/top, mid/side | a root plinth, the fin, sensor windows, a lens strip, a trim band | picture |
| bay | launches the drone escorts (data.js hangar 1, ability launch) | bay | flush armoured drone doors in the trough between the rails (R232) | 1 | mid/top | a trim frame, two door leaves with ribs, the centre seam, blue guide lamps | picture |
| engines | the main drives: a flat row of four rectangular blue-white nozzles (factions.md) | engine | four nozzle pods, two a rail | 4 | stern/top, stern/side | a thick lip, inner walls tapering to a blue-white throat, guide vanes, a sleeve with trim bands and panels (R244: an opening with depth) | picture |
| thrusters | retro thrusters on the bow face (lore 3.4: backing off is cheap) and attitude thrusters on the facets and rails | thruster | rectangular nozzle blocks | 6 | bow/side, stern/side | a block, rectangular nozzles with depth | designed |
| latches | lock the hull modules together across each module band (H10's rows of four blocks) | latch | rows of four clamp heads beside the bands | 20 | bow/top, mid/top, stern/top | a base plate, four machined clamps | picture |
| vents | heat louvres over the lance capacitor rooms, the reactor, the crew decks and the engine rooms (H10's long slots) | vent | long louvres on the decks and the rails' upper tiers | 16 | bow/top, mid/top, stern/top, mid/side, stern/side | a machined frame, straight slats over a dark recess | picture |
| windows | blue-white windows of the crew decks (lore 3.3) | slit | window slits on the flank band and the rails' lower tier | 10 | bow/side, mid/side, stern/side | a trim frame round a recessed pane | picture |
| hatches | crew and stores access: deck, belly and flank hatches | hatch | flush rectangular armoured hatches | 16 | bow/top, mid/top, mid/below, stern/below, mid/side, stern/side | a trim rim, a flush door, a seam, a recessed grip | picture |
| lift_heads | the bow lift head: stores up to the forward decks | hatchbox | a low module housing on the deck | 1 | bow/top | a chamfered frame, an inset lid with a seam, a blue strip | designed |

Kit sub-parts per type (what DETAILED checks):

- antenna: root, fin, window, lens
- band: band, seam, strip
- bay: frame, door, seam
- engine: housing, lip, lining, throat, vane, band
- gun: ring, housing, mantlet, barrel, coil, muzzle, bore
- hatch: rim, door, seam, grip
- hatchbox: frame, lid, seam
- hull: facet, step, chamfer
- ion_trench: liner, coil, emitter, lens
- latch: base, clamp
- plate: panel, seam, module
- rail: facet, step, strip
- slit: frame, glass
- thruster: block, nozzle
- tier: face, roof, opening
- vent: frame, slat

Left as surface, and why:

- The flank band carries only the blue line, the windows and the breach anchors: H10 draws it as a plain band under the light strip.
- Stencil marks (H10's "HD-14", "SECTION") are paint, not modelled (the Hegemony stack, a later job).

## Every built part has a job (R221)

Built kit parts: 92; parts whose inventory id names no line with a job: 0.

## Per cell: present, shaped, detailed (from the model, hegemony_H10_model.json)

Y = yes, n = no. Counts are parts built with this inventory id against the count the concept shows.

### bow/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| wedge | the wedge: a flat deck, chamfered deck edges, upper facets out to the  | 1 / 1 | Y | Y | Y |
| bow_face | the blunt bow face, chamfered corners, armour plates and a trim frame  | 1 / 1 | Y | Y | Y |
| module_bands | raised trim rings round the wedge and the rails with a deep double sea | 1 / 1 | Y | Y | Y |
| deck_panels | flush deck panels on the wedge and the terraces | 1 / 1 | Y | Y | Y |
| ion_trench | the emitter trench recessed in the blunt bow face (R183 (1)) | 1 / 1 | Y | Y | Y |
| latches | rows of four clamp heads beside the bands | 20 / 20 | Y | Y | Y |
| vents | long louvres on the decks and the rails' upper tiers | 16 / 16 | Y | Y | Y |
| hatches | flush rectangular armoured hatches | 16 / 16 | Y | Y | Y |
| lift_heads | a low module housing on the deck | 1 / 1 | Y | Y | Y |

### bow/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| wedge | the wedge: a flat deck, chamfered deck edges, upper facets out to the  | 1 / 1 | Y | Y | Y |
| bow_face | the blunt bow face, chamfered corners, armour plates and a trim frame  | 1 / 1 | Y | Y | Y |
| module_bands | raised trim rings round the wedge and the rails with a deep double sea | 1 / 1 | Y | Y | Y |
| blue_line | a blue strip along each flank band and in each rail's recess, broken a | 1 / 1 | Y | Y | Y |
| flank_panels | flush panels on the upper and lower facets | 1 / 1 | Y | Y | Y |
| ion_trench | the emitter trench recessed in the blunt bow face (R183 (1)) | 1 / 1 | Y | Y | Y |
| thrusters | rectangular nozzle blocks | 6 / 6 | Y | Y | Y |
| windows | window slits on the flank band and the rails' lower tier | 10 / 10 | Y | Y | Y |

### bow/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| wedge | the wedge: a flat deck, chamfered deck edges, upper facets out to the  | 1 / 1 | Y | Y | Y |
| bow_face | the blunt bow face, chamfered corners, armour plates and a trim frame  | 1 / 1 | Y | Y | Y |
| belly_panels | flush panels on the belly and the belly armour step | 2 / 1 | Y | Y | Y |
| pickets | two small twin turrets on the belly armour step | 2 / 2 | Y | Y | Y |

### mid/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| wedge | the wedge: a flat deck, chamfered deck edges, upper facets out to the  | 1 / 1 | Y | Y | Y |
| rails | two chamfered rail blocks in two module tiers (a recessed band at mid  | 1 / 1 | Y | Y | Y |
| bay_block | the hangar block between the rails' roots, its roof a trough below the | 1 / 1 | Y | Y | Y |
| module_bands | raised trim rings round the wedge and the rails with a deep double sea | 1 / 1 | Y | Y | Y |
| deck_panels | flush deck panels on the wedge and the terraces | 1 / 1 | Y | Y | Y |
| rail_panels | flush panels on the rails' decks, flanks and bellies | 2 / 1 | Y | Y | Y |
| lances | two low wide lance turrets sunk in the shoulder terraces, two short th | 2 / 2 | Y | Y | Y |
| sensor_fin | a low swept fin on the centreline between the turrets | 1 / 1 | Y | Y | Y |
| bay | flush armoured drone doors in the trough between the rails (R232) | 1 / 1 | Y | Y | Y |
| latches | rows of four clamp heads beside the bands | 20 / 20 | Y | Y | Y |
| vents | long louvres on the decks and the rails' upper tiers | 16 / 16 | Y | Y | Y |
| hatches | flush rectangular armoured hatches | 16 / 16 | Y | Y | Y |

### mid/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| wedge | the wedge: a flat deck, chamfered deck edges, upper facets out to the  | 1 / 1 | Y | Y | Y |
| rails | two chamfered rail blocks in two module tiers (a recessed band at mid  | 1 / 1 | Y | Y | Y |
| module_bands | raised trim rings round the wedge and the rails with a deep double sea | 1 / 1 | Y | Y | Y |
| blue_line | a blue strip along each flank band and in each rail's recess, broken a | 1 / 1 | Y | Y | Y |
| flank_panels | flush panels on the upper and lower facets | 1 / 1 | Y | Y | Y |
| rail_panels | flush panels on the rails' decks, flanks and bellies | 2 / 1 | Y | Y | Y |
| lances | two low wide lance turrets sunk in the shoulder terraces, two short th | 2 / 2 | Y | Y | Y |
| sensor_fin | a low swept fin on the centreline between the turrets | 1 / 1 | Y | Y | Y |
| vents | long louvres on the decks and the rails' upper tiers | 16 / 16 | Y | Y | Y |
| windows | window slits on the flank band and the rails' lower tier | 10 / 10 | Y | Y | Y |
| hatches | flush rectangular armoured hatches | 16 / 16 | Y | Y | Y |

### mid/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| wedge | the wedge: a flat deck, chamfered deck edges, upper facets out to the  | 1 / 1 | Y | Y | Y |
| rails | two chamfered rail blocks in two module tiers (a recessed band at mid  | 1 / 1 | Y | Y | Y |
| belly_panels | flush panels on the belly and the belly armour step | 2 / 1 | Y | Y | Y |
| rail_panels | flush panels on the rails' decks, flanks and bellies | 2 / 1 | Y | Y | Y |
| hatches | flush rectangular armoured hatches | 16 / 16 | Y | Y | Y |

### stern/top

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| rails | two chamfered rail blocks in two module tiers (a recessed band at mid  | 1 / 1 | Y | Y | Y |
| module_bands | raised trim rings round the wedge and the rails with a deep double sea | 1 / 1 | Y | Y | Y |
| rail_panels | flush panels on the rails' decks, flanks and bellies | 2 / 1 | Y | Y | Y |
| engines | four nozzle pods, two a rail | 4 / 4 | Y | Y | Y |
| latches | rows of four clamp heads beside the bands | 20 / 20 | Y | Y | Y |
| vents | long louvres on the decks and the rails' upper tiers | 16 / 16 | Y | Y | Y |

### stern/side

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| rails | two chamfered rail blocks in two module tiers (a recessed band at mid  | 1 / 1 | Y | Y | Y |
| module_bands | raised trim rings round the wedge and the rails with a deep double sea | 1 / 1 | Y | Y | Y |
| blue_line | a blue strip along each flank band and in each rail's recess, broken a | 1 / 1 | Y | Y | Y |
| rail_panels | flush panels on the rails' decks, flanks and bellies | 2 / 1 | Y | Y | Y |
| engines | four nozzle pods, two a rail | 4 / 4 | Y | Y | Y |
| thrusters | rectangular nozzle blocks | 6 / 6 | Y | Y | Y |
| vents | long louvres on the decks and the rails' upper tiers | 16 / 16 | Y | Y | Y |
| windows | window slits on the flank band and the rails' lower tier | 10 / 10 | Y | Y | Y |
| hatches | flush rectangular armoured hatches | 16 / 16 | Y | Y | Y |

### stern/below

| ID | What | Built / listed | Present | Shaped | Detailed |
|---|---|---|---|---|---|
| rails | two chamfered rail blocks in two module tiers (a recessed band at mid  | 1 / 1 | Y | Y | Y |
| rail_panels | flush panels on the rails' decks, flanks and bellies | 2 / 1 | Y | Y | Y |
| hatches | flush rectangular armoured hatches | 16 / 16 | Y | Y | Y |


## Structure per cell: distinct masses (blocks, tiers, belts), concept against build

Concept counts read off the concept sheet by eye (H10 sheet: bow, the wedge and its bow face; midships, the wedge, the two turret bays, the rails' roots and the bay with its two boxes; stern, the two rails and the nozzle pods; no underside view); build counts are the model's registered masses whose station range overlaps the third (below: masses reaching within 0.8 of the belly).

| Cell | Concept | Build | Build masses |
|---|---:|---:|---|
| bow/top | 2 | 3 | Hull: the wedge; Bow face round the ion trench; Belly armour step |
| bow/side | 2 | 3 | Hull: the wedge; Bow face round the ion trench; Belly armour step |
| bow/below | no view | 3 | Hull: the wedge; Bow face round the ion trench; Belly armour step |
| mid/top | 5 | 5 | Hull: the wedge; Rail, port; Rail, starboard; Drone bay block between the rails; Belly armour step |
| mid/side | 4 | 4 | Hull: the wedge; Rail, port; Drone bay block between the rails; Belly armour step |
| mid/below | no view | 5 | Hull: the wedge; Rail, port; Rail, starboard; Drone bay block between the rails; Belly armour step |
| stern/top | 3 | 3 | Rail, port; Rail, starboard; Drone bay block between the rails |
| stern/side | 3 | 2 | Rail, port; Drone bay block between the rails |
| stern/below | no view | 3 | Rail, port; Rail, starboard; Drone bay block between the rails |

## Proportions: length to beam and length to height, concept against build (the Board on round 3)

Measured the same way on both: the concept sheet's top and side views and the blockout's top and side renders, bow left. Envelope: the whole outline. Hull: length over the median beam or height across the middle 60 percent of the length (dishes, guns and antennas sticking out at a few stations do not count).

| | Envelope L:B | Envelope L:H | Hull L:B | Hull L:H |
|---|---:|---:|---:|---:|
| concept | 2.64 | 5.43 | 3.09 | 7.02 |
| build | 2.34 | 5.69 | 3.15 | 7.19 |

Lines not present, shaped and detailed without a reason: 0.
